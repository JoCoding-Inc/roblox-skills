--!nonstrict
-- cine_camera: a shot-list player for cutscenes, on the fx clock (one frame = one sample of clock time, so a
-- frozen clock freezes the camera for a capture). Hard cuts between shots; inside a shot a move (push-in,
-- pull-out, pan, orbit) with easing, FOV and dutch roll ramps and a rotation-only shake. The camera is
-- Scriptable while the list plays and is handed back cleanly at the end: a short ease to a view behind the local
-- character, then CameraType, CameraSubject and FieldOfView are restored to the values saved at the start.
--
-- CineCamera.play(shots, opts?) -> clock     (opts.clock / opts.at embed it in a cutscene clock)
-- A shot (times in clock seconds, from the start of the list):
--   t, len           start and length; the next shot starts with a hard cut
--   subject          BasePart | Model (its PrimaryPart or HumanoidRootPart) | CFrame | function() -> CFrame
--   from, to         { offset = Vector3, look = Vector3 } in subject space (to = end framing of the move)
--   orbit            degrees the offset turns around the subject's up axis during the move
--   fov, roll        number or { a, b } (degrees; roll = horizon tilt, + = clockwise)
--   move             { t0, t1, ease } inside the shot (default whole shot, ease "outCubic")
--   shake            { amp = deg, roll = deg, len = s, at = s into the shot, step = s (0 = smooth noise) }
--   name             label printed with the cut ("CUT|t|name|len")
-- opts.returnTime    seconds of the ease back to the player (default 0.6; 0 = instant)
-- opts.noReturn      leave the camera Scriptable at the end (the caller restores with CineCamera.restore())
-- CineCamera.fit(height, fov, share) -> studs: how far away something that tall fills that share of the frame.
-- CineCamera.audit(shots, height?) -> { string }: shots where the subject is a dot (under 15% of the frame
--   height), the camera is inside it, the head is larger than 45% of the frame height (an avatar's face is a flat
--   shape at that size), or the subject stays under 25% of the frame for more than 1.2 s in a row; run it on
--   every shot list before the first capture.
-- CineCamera.anchor(part, rotRef?) -> function: subject at the part's position with rotRef's rotation (a head
--   that turns with a pose does not swing the camera).
-- Reduced motion (flash_safety reduced()): shake is skipped; cuts, moves and roll stay.
-- The camera is driven every frame (CameraType is set to Scriptable on each frame too): a single write is undone
-- by the default camera scripts and by Studio MCP execute_luau, which resets a Scriptable camera (measured).
--
-- Ran in Studio 0.747 and 0.748 Play, 2026-11-18 (roblox-feel-audio-vfx section 3e). Shake: a stepped shake (a new
-- uniform random pose every `step` s) used the whole amplitude, while smooth math.noise sampled at 0.05 s steps
-- stayed within about +-0.3 of its range (a 12 deg roll moved 3-4 deg; measured).
-- Numbers it was built to, read from four public showcase clips (2026-11-17; frame counts at each clip's own rate,
-- 30 or 60 fps): roll 8-25 deg, pushes and pull-outs of 4-18 frames, build-up close-ups of 10-36 frames, shake of
-- about 5-10 % of the frame with roll swings every 2-4 frames, a very low camera for the wides.
-- Limits: no collision test (a shot can sit inside a body or a slab: frame each shot on a capture); the hand-back
-- view sits 12 studs behind the local character's root; not checked in a server with several players.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FxClock = require(script.Parent.fx_clock)
local Safety = require(script.Parent.flash_safety)

local CineCamera = {}

local EASE = {
	linear = function(u)
		return u
	end,
	outCubic = FxClock.outCubic,
	outQuart = FxClock.outQuart,
	inOutSine = FxClock.inOutSine,
	inCubic = function(u)
		return u * u * u
	end,
	outExpo = function(u)
		return if u >= 1 then 1 else 1 - 2 ^ (-10 * u)
	end,
}
CineCamera.EASE = EASE

local saved = nil -- { type, subject, fov }
CineCamera.cutLog = {}

function CineCamera.anchor(part: BasePart, rotRef: BasePart?)
	return function()
		local r = rotRef or part
		return CFrame.new(part.Position) * r.CFrame.Rotation
	end
end

local function subjectCF(s): CFrame
	local ts = typeof(s)
	if ts == "CFrame" then
		return s
	elseif ts == "function" then
		return s()
	elseif ts == "Instance" then
		if s:IsA("BasePart") then
			return s.CFrame
		end
		local root = s:FindFirstChild("HumanoidRootPart") or s.PrimaryPart
		return root.CFrame
	end
	return CFrame.new()
end

local function ab(v, u)
	if type(v) == "table" then
		return v[1] + (v[2] - v[1]) * u
	end
	return v or 0
end

-- Smooth 1D noise in -1..1 from math.noise.
local function n1(x, seed)
	return math.clamp(math.noise(x, seed, 0.37) * 2, -1, 1)
end

function CineCamera.frame(shot, lt: number): (CFrame, number)
	local mv = shot.move or {}
	local t0, t1 = mv.t0 or 0, mv.t1 or shot.len
	local ease = EASE[mv.ease or "outCubic"]
	local u = ease(math.clamp((lt - t0) / math.max(t1 - t0, 1e-6), 0, 1))
	local S = subjectCF(shot.subject)
	local from = shot.from
	local to = shot.to or from
	local off = from.offset:Lerp(to.offset, u)
	local look = from.look:Lerp(to.look, u)
	if shot.orbit then
		off = CFrame.Angles(0, math.rad(shot.orbit * u), 0) * off
	end
	local pos = S * off
	local at = S * look
	local cf = CFrame.lookAt(pos, at)
	local roll = ab(shot.roll, u)
	local fov = ab(shot.fov or 70, u)
	local sh = shot.shake
	if sh and not Safety.reduced() then
		local age = lt - (sh.at or 0)
		if age >= 0 and age <= sh.len then
			local k = (1 - age / sh.len) ^ 2 -- trauma squared, linear decay
			local f = sh.freq or 9
			local ny, np, nr
			if sh.step and sh.step > 0 then
				-- stepped: a new random pose every `step` seconds. Measured (final-1): smooth noise sampled at
				-- steps stayed within about +-0.3 of its range, so a 12 deg roll moved only 3-4 deg; uniform
				-- random per step uses the whole range
				local r = Random.new(math.floor(age / sh.step) + 7919)
				ny, np, nr = r:NextNumber(-1, 1), r:NextNumber(-1, 1), r:NextNumber(-1, 1)
			else
				ny, np, nr = n1(age * f, 11.3), n1(age * f, 47.9), n1(age * f, 83.1)
			end
			local yaw = (sh.amp or 2) * k * ny
			local pitch = (sh.amp or 2) * k * np
			roll += (sh.roll or 0) * k * nr
			cf = cf * CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)
		end
	end
	cf = cf * CFrame.Angles(0, 0, math.rad(-roll))
	return cf, fov
end

function CineCamera.save()
	if saved then
		return
	end
	local cam = workspace.CurrentCamera
	saved = { type = cam.CameraType, subject = cam.CameraSubject, fov = cam.FieldOfView }
end

function CineCamera.restore()
	local cam = workspace.CurrentCamera
	if not saved then
		return
	end
	cam.CameraType = if saved.type == Enum.CameraType.Scriptable then Enum.CameraType.Custom else saved.type
	local subj = saved.subject
	local plr = Players.LocalPlayer
	if (not subj or not subj.Parent) and plr and plr.Character then
		subj = plr.Character:FindFirstChildOfClass("Humanoid")
	end
	cam.CameraSubject = subj
	cam.FieldOfView = saved.fov
	saved = nil
end

-- A view behind the local character (where the default camera will pick up after the hand-back).
local function playerView(): CFrame?
	local plr = Players.LocalPlayer
	local ch = plr and plr.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local head = root.Position + Vector3.new(0, 1.5, 0)
	local back = -root.CFrame.LookVector
	return CFrame.lookAt(head + back * 12 + Vector3.new(0, 3.2, 0), head)
end

function CineCamera.length(shots): number
	local e = 0
	for _, s in shots do
		e = math.max(e, s.t + s.len)
	end
	return e
end

-- The distance at which something `height` studs tall fills `share` of the frame height at `fov` (vertical
-- degrees). A character is about 5.5 studs: CineCamera.fit(5.5, 50, 0.4) = 14.7 studs.
function CineCamera.fit(height: number, fov: number, share: number): number
	return height / share / (2 * math.tan(math.rad(fov) / 2))
end

-- Read a shot list before playing it: returns (and warns about) the shots whose subject would fill under 15% of
-- the frame height at either end of the move (a dot in an empty frame), or whose camera comes within 1.6 studs of
-- the subject's origin (inside the hair or the body). height: the subject's height in studs (default 5.5).
-- Two blind judges marked down exactly these frames in a cutscene whose shots were set by offsets alone.
function CineCamera.audit(shots, height: number?): { string }
	local h = height or 5.5
	local head = h * 0.22 -- 1.2 studs on a 5.5 stud avatar
	local out = {}
	local small, told = 0, false
	for i, shot in shots do
		local fov = shot.fov
		for k, framing in { shot.from, shot.to } do -- a shot without a move is read once
			local f = if type(fov) == "table" then fov[k] or fov[1] else fov or 70
			local dist = (framing.offset :: Vector3).Magnitude
			local share = h / (2 * dist * math.tan(math.rad(f) / 2))
			local label = string.format("shot %d %s (%s)", i, tostring(shot.name or ""), k == 1 and "start" or "end")
			if share < 0.15 then
				table.insert(out, string.format("%s: the subject fills %d%% of the frame height; at fov %d come within %.0f studs or narrow the fov", label, share * 100, f, CineCamera.fit(h, f, 0.2)))
			elseif dist < 1.6 then
				table.insert(out, string.format("%s: the camera is %.1f studs from the subject's origin, inside the hair or the body", label, dist))
			elseif head / (2 * dist * math.tan(math.rad(f) / 2)) > 0.45 then
				-- an avatar's head is a smooth shape with a decal: at frame size it is a flat oval (named in two sittings)
				table.insert(out, string.format("%s: the head fills %d%% of the frame height; an avatar's face is a flat shape at that size: stay at %.1f studs or more at fov %d (head under 40%%), or make the shot a close-up of the effect", label, head / (2 * dist * math.tan(math.rad(f) / 2)) * 100, CineCamera.fit(head, f, 0.4), f))
			end
		end
		-- a stretch where the subject is small: a wide is a beat, not a place to stay
		local f = if type(fov) == "table" then math.max(fov[1], fov[2] or fov[1]) else fov or 70
		local far = math.max((shot.from.offset :: Vector3).Magnitude, (shot.to.offset :: Vector3).Magnitude)
		if h / (2 * far * math.tan(math.rad(f) / 2)) < 0.25 then
			small += shot.len or 0
			if small > 1.2 and not told then
				told = true
				table.insert(out, string.format("shot %d %s: the subject has been under 25%% of the frame height for %.1f s in a row; keep a wide to 1 s or less, or bring effects and movement into it", i, tostring(shot.name or ""), small))
			end
		else
			small, told = 0, false
		end
	end
	for _, line in out do
		warn("CineCamera.audit: " .. line)
	end
	return out
end

function CineCamera.play(shots, opts)
	opts = opts or {}
	table.sort(shots, function(a, b)
		return a.t < b.t
	end)
	local listEnd = CineCamera.length(shots)
	local ret = if opts.noReturn then 0 else (opts.returnTime or 0.6)
	local c, root, own = FxClock.attach("CineCamera", listEnd + ret + 0.02, opts)
	local cam = workspace.CurrentCamera
	local current = 0
	local lastCF, lastFov = cam.CFrame, cam.FieldOfView
	local released = false
	CineCamera.cutLog = {}

	local function release()
		if released then
			return
		end
		released = true
		if not opts.noReturn then
			CineCamera.restore()
		end
	end

	c:at(0, function()
		CineCamera.save()
		cam.CameraType = Enum.CameraType.Scriptable
	end)
	c:every(function(t)
		if released then
			return
		end
		if t < listEnd then
			local idx = 0
			for i, s in shots do
				if t >= s.t and t < s.t + s.len then
					idx = i
				end
			end
			if idx == 0 then
				return
			end
			if idx ~= current then
				current = idx
				local s = shots[idx]
				table.insert(CineCamera.cutLog, { t = s.t, len = s.len, name = s.name or tostring(idx) })
				print(string.format("CUT|%.3f|%s|%.3f", s.t, s.name or tostring(idx), s.len))
			end
			local s = shots[idx]
			cam.CameraType = Enum.CameraType.Scriptable
			local cf, fov = CineCamera.frame(s, t - s.t)
			cam.CFrame = cf
			-- Focus on the subject, not a point ahead of the camera: after a jump to a far stage the only local lights
			-- that draw at once are those on a subject within about 3 studs of Focus and 8 studs of the camera (measured)
			cam.Focus = CFrame.new(subjectCF(s.subject).Position)
			cam.FieldOfView = fov
			lastCF, lastFov = cf, fov
		elseif ret > 0 and t < listEnd + ret then
			local goal = playerView()
			local u = FxClock.inOutSine(math.clamp((t - listEnd) / ret, 0, 1))
			if goal then
				cam.CFrame = lastCF:Lerp(goal, u)
			end
			cam.FieldOfView = lastFov + ((saved and saved.fov or 70) - lastFov) * u
		elseif t >= listEnd + ret then
			release()
		end
	end)
	c:onCleanup(release)
	if own then
		root:play()
	end
	return root
end

return CineCamera
