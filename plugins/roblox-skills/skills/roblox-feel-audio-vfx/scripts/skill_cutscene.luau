--!nonstrict
-- skill_cutscene: one charged-punch sequence (about 7.2 s with the camera's return) built from a single timeline
-- table: every row is (time, what fires, its options). Camera shots are rows too ("shot"); the rest fire the
-- element modules on one shared fx clock, so the whole scene freezes on any beat for a capture.
-- Cutscene.play() -> root clock. Client only. Needs every module of roblox-feel-audio-vfx section 3e in one
-- folder and the two dummies of cine_stage (Stage.buildRigs on the server, Stage.setup on the client); to use it
-- on a player and an NPC, replace Stage.hero() / Stage.target() in play() and re-frame every shot on a capture.
-- Ran in Studio 0.747 and 0.748 Play, 2026-11-18 (desktop, and the Samsung Galaxy A06 Device Simulator preset);
-- the owner judged the captures well made (2026-11-18). Not run on a real phone or in a published game.
--
-- Structure (clock s; 60 fps frames in brackets):
--   0.00-2.62  build-up: low wide (1.05 s), then 3 close-ups of 30-33 f: the fist (dutch 18), the target's
--              face from below (black speed lines), over the shoulder at the target (dutch 22); the charge ball and the
--              crackle grow on the fist; letterbox and vignette in
--   2.62-3.12  dark beat (0.5 s): the world goes near black, silhouettes, only the energy glows; a glint grows
--   3.12-3.33  impact block (0.21 s): white -> cyan field with black silhouettes -> grey negative -> blue field
--              with white silhouettes; the strike happens inside it (the move is never shown)
--   3.33-4.00  peak: 6 shots of 4-8 f (9 cuts/s), 5-7 layers at once: sphere at full size, ground ring, debris,
--              dust, ground strikes and an arc, white speed lines, ink spikes / smears / shards, lettering, shake
--   4.00-6.60  hold (2.6 s): one low wide, the finishing pose, debris falling and shrinking, dust; the sphere
--              blinks out at 4.64 into smoke and a second, smaller ground burst; lettering fades by 5.4
--   6.60-7.20  the camera eases back to the player and is handed back; letterbox out
-- Peak (impact block start) at 3.12 / 7.2 s = 43 %, the burst frames 3.33-4.0 at 46-56 %.
-- Screen-wide flashes: dark -> white (3.12), white -> cyan field (3.17), peak dim -> hold (4.00): 3 inside one
-- second (logged by flash_safety: "FLASH|..." lines, and one "CUTSCENE|flashes=3 maxPerSecond=3 | ..." line at the
-- end; no other screen-wide state runs within 1 s of them).
-- The touch controls (thumbstick, jump button) sat over every shot in the phone pass: GuiService
-- TouchControlsEnabled is false while the scene plays and restored at cleanup. Roblox's own top-bar buttons stay.
-- Peak live counts (every frame, max): 10 emitters, 399 beams, 5 lights, 152 parts, 4 Highlights, 68 GuiObjects;
-- most beams are hidden pool beams of the lightning and the sphere rim. Frame cost not measured on a phone.
-- Limits: no skip input, no death or respawn exit and no movement lock here (add them as roblox-cinematics
-- section 3a does); comments marked r1-r4 / final-1 name the capture round that found the problem.

local FxClock = require(script.Parent.fx_clock)
local Stage = require(script.Parent.cine_stage)
local Safety = require(script.Parent.flash_safety)
local CineCamera = require(script.Parent.cine_camera)
local ImpactFrames = require(script.Parent.impact_frames)
local ScreenOverlays = require(script.Parent.screen_overlays)
local Lightning = require(script.Parent.lightning)
local EnergySphere = require(script.Parent.energy_sphere)
local GroundBurst = require(script.Parent.ground_burst)
local InkShapes = require(script.Parent.ink_shapes)
local Lettering = require(script.Parent.lettering)
local PoseBeats = require(script.Parent.pose_beats)
local FxTextures = require(script.Parent.fx_textures)

local Cutscene = {}

local V = Vector3.new
local H = Stage.HUE

Cutscene.LENGTH = 6.6 -- the camera's return adds 0.6 s
-- shot boundaries plus the block and the peak frame by frame
Cutscene.CAPTURE_TIMES = {
	0.02, 0.6, 1.07, 1.3, 1.57, 1.7, 2.12, 2.4, 2.64, 2.9, 3.05, 3.1,
	3.12, 3.137, 3.153, 3.17, 3.187, 3.203, 3.22, 3.237, 3.253, 3.27, 3.287, 3.303, 3.32,
	3.333, 3.35, 3.367, 3.383, 3.4, 3.417, 3.433, 3.45, 3.467, 3.483, 3.5, 3.517, 3.533, 3.55, 3.583, 3.617, 3.65,
	3.667, 3.683, 3.7, 3.733, 3.767, 3.8, 3.833, 3.867, 3.9, 3.95, 4.0,
	4.05, 4.2, 4.5, 4.8, 5.1, 5.5, 6.0, 6.5, 6.8, 7.1,
}

-- The timeline. Shots: subject is "hero" (hero space), "head", "hand", "thead" (target head in target space);
-- offsets in that space (hero: -Z toward the target, the hero root about 3 studs above the floor).
Cutscene.TIMELINE = {
	-- camera -------------------------------------------------------------------------------------------
	{ t = 0.00, fire = "shot", len = 1.05, name = "A low wide", subject = "hero", from = { offset = V(12, -2.6, -1.5), look = V(0, 1.0, -3.5) }, to = { offset = V(10.5, -2.6, -2), look = V(0, 1.0, -3.5) }, fov = 55, move = { ease = "inOutSine" } },
	{ t = 1.05, fire = "shot", len = 0.5, name = "B ECU fist, dutch 18, push 12 f", subject = "hand", from = { offset = V(2.6, 0.9, -1.0), look = V(0, 0, 0) }, to = { offset = V(1.7, 0.6, -0.6), look = V(0, 0, 0) }, fov = 42, roll = 18, move = { t0 = 0, t1 = 0.2 } },
	-- r1: 2.1 studs from the head put the camera inside the wound-up body; from the front-left, further out
	-- r3/r4/final-1: on the hero the charge pose's guard arm or a shoulder hid the face from every side tried;
	-- the face close-up is now the target's, waiting for the hit (its idle face is clear)
	{ t = 1.55, fire = "shot", len = 0.55, name = "C ECU target face from below", subject = "thead", from = { offset = V(0.45, -0.7, -2.6), look = V(0, 0.15, 0) }, to = { offset = V(0.35, -0.55, -2.0), look = V(0, 0.15, 0) }, fov = 40, roll = -12 },
	{ t = 2.10, fire = "shot", len = 0.52, name = "D over the shoulder, dutch 22, push 10 f", subject = "hero", from = { offset = V(2.4, 1.9, 4.6), look = V(0, 0.4, -7) }, to = { offset = V(2.0, 1.6, 3.4), look = V(0, 0.4, -7) }, fov = 48, roll = 22, move = { t0 = 0, t1 = 0.167 } },
	-- r1: from the left the target filled the frame and the body hid the glowing fist; now from the fist side
	{ t = 2.62, fire = "shot", len = 0.5, name = "E dark, low", subject = "hero", from = { offset = V(10, -2.2, -2.0), look = V(0, 0.8, -3.5) }, to = { offset = V(8.8, -2.2, -2.2), look = V(0, 0.8, -3.5) }, fov = 50, roll = -8, move = { ease = "inOutSine" } },
	{ t = 3.12, fire = "shot", len = 0.21, name = "F block frame", subject = "hero", from = { offset = V(9, -1.8, -8), look = V(0, 1.0, -4) }, fov = 55, roll = 10 },
	{ t = 3.33, fire = "shot", len = 0.133, name = "P1 wide low", subject = "hero", from = { offset = V(15, -2.6, -4), look = V(0, 2, -8) }, fov = 62, roll = -6, shake = { amp = 3, roll = 12, len = 0.133, step = 0.05 } },
	-- r1: the target is inside the sphere at this time, an ECU on it showed a flat cyan wash: the hero's face instead
	{ t = 3.463, fire = "shot", len = 0.067, name = "P2 ECU hero face", subject = "head", from = { offset = V(1.4, -0.5, -2.6), look = V(0, 0.1, 0) }, fov = 40, roll = -20 },
	{ t = 3.53, fire = "shot", len = 0.133, name = "P3 medium side", subject = "hero", from = { offset = V(7, 0, -3.5), look = V(0, 0.5, -6) }, fov = 55, roll = 14, shake = { amp = 2.5, roll = 10, len = 0.133, step = 0.05 } },
	-- r1: behind the fist the camera sat inside the lunging body; r2: beside it, it sat inside the sphere (cyan wash)
	-- r4: the worm's-eye from the front went black in the peak dim; now from behind, the hero backlit by the sphere
	{ t = 3.663, fire = "shot", len = 0.067, name = "P4 low behind the hero, backlit", subject = "hero", from = { offset = V(1.5, -2.3, 4.5), look = V(0, 1.5, -3) }, fov = 50, roll = 25 },
	{ t = 3.73, fire = "shot", len = 0.133, name = "P5 wide, other side", subject = "hero", from = { offset = V(-15, -2.6, -11), look = V(0, 2.5, -9) }, fov = 62, roll = 8, shake = { amp = 2.5, roll = 10, len = 0.133, step = 0.05 } },
	-- r2: behind the hero a debris block filled the lens; now a reverse wide from past the target
	{ t = 3.863, fire = "shot", len = 0.137, name = "P6 reverse wide, low", subject = "hero", from = { offset = V(-6, -1.2, -28), look = V(0, 1.5, -3) }, fov = 50, roll = -10 }, -- r3: rim slabs filled the lens at -21
	{ t = 4.00, fire = "shot", len = 2.6, name = "H hold, pull-out 18 f", subject = "hero", from = { offset = V(12, -2.6, -3.5), look = V(0, 1.6, -7.5) }, to = { offset = V(15.5, -2.6, -3), look = V(0, 1.6, -7.5) }, fov = 55, roll = 4, move = { t0 = 0, t1 = 0.3 }, shake = { amp = 1.2, roll = 3, len = 0.6, step = 0.033 } },

	-- screen ---------------------------------------------------------------------------------------------
	{ t = 0.00, fire = "letterbox", dur = 6.9 },
	{ t = 0.00, fire = "vignette", dur = 6.9, strength = 0.4 },
	{ t = 1.58, fire = "speedlines", dur = 0.27, focus = "thead", color = H.ink },
	{ t = 2.62, fire = "dark", dur = 0.5 },
	-- r3: a bug held the dark lighting through 3.57 and the black world behind the burst read best, so it is
	-- now a planned peak dim (3.33-4.00, no silhouettes, the sphere light paints the floor); the block hands
	-- over at L 0.15, so the peak adds no flash and its end at the cut to the hold is flash 3
	{ t = 3.12, fire = "block", endL = 0.15 },
	{ t = 3.33, fire = "dark", dur = 0.67, fadeIn = 0, endL = 0.5, silhouette = false },
	{ t = 3.33, fire = "speedlines", dur = 0.27, focus = "impact", color = H.white, clear = 0.34, seed = 4 },
	{ t = 3.36, fire = "lettering", words = {
		{ text = "KRAK!", pos = Vector2.new(0.3, 0.32), rot = -12, at = 0, hold = 2.06, size = 0.23 },
		{ text = "VMM", pos = Vector2.new(0.76, 0.68), rot = 9, at = 0.27, hold = 1.6, size = 0.14 },
	} },
	{ t = 3.463, fire = "ink", kind = "shards", frames = 3, depth = "front", focus = "impact" }, -- r4: behind, the floor cut the low shards
	{ t = 3.53, fire = "ink", kind = "spikes", frames = 4, depth = "behind", focus = "impact", seed = 3 },
	{ t = 3.663, fire = "ink", kind = "smear", frames = 3, depth = "front", seed = 8 },
	{ t = 3.863, fire = "ink", kind = "spikes", frames = 2, depth = "behind", focus = "impact", seed = 12, count = 9 },

	-- characters -----------------------------------------------------------------------------------------
	{ t = 0.00, fire = "pose", who = "hero", keys = {
		{ t = 0, pose = "idle" },
		{ t = 0.5, pose = "idle", ease = "linear" },
		{ t = 0.85, pose = "windup", ease = "inout" },
		{ t = 1.7, pose = "charge", ease = "inout" },
		{ t = 3.12, pose = "strike", ease = "snap" },
		{ t = 3.9, pose = "strike", ease = "linear" },
		{ t = 4.25, pose = "finish", ease = "out" },
		{ t = 6.6, pose = "finish", ease = "linear" },
	} },
	{ t = 0.00, fire = "pose", who = "target", keys = {
		{ t = 0, pose = "idle" },
		{ t = 2.2, pose = "idle", ease = "linear" },
		{ t = 2.45, pose = "brace", ease = "inout" },
		{ t = 3.2, pose = "recoil", ease = "snap" },
		{ t = 3.65, pose = "knock", ease = "out" },
		{ t = 4.1, pose = "down", ease = "inout" },
		{ t = 6.6, pose = "down", ease = "linear" },
	} },

	-- energy ---------------------------------------------------------------------------------------------
	{ t = 0.60, fire = "crackle", dur = 2.5, radius = 1.1, scale = 0.8, every = 0.05 },
	{ t = 1.05, fire = "sphere", charge = 2.07, rCharge = 0.5, R = 5.5, burst = 0.22, hold = 1.3 },
	{ t = 2.30, fire = "strike", at = "bg", seed = 201 },
	{ t = 3.00, fire = "glint", dur = 0.12 },
	{ t = 3.33, fire = "arc", seed = 77 },
	{ t = 3.33, fire = "strike", at = "left", seed = 202 },
	{ t = 3.55, fire = "strike", at = "right", seed = 203 },
	{ t = 3.80, fire = "strike", at = "back", seed = 204 },
	{ t = 4.60, fire = "strike", at = "far", seed = 205 },
	{ t = 5.40, fire = "strike", at = "far2", seed = 206 },
	{ t = 4.00, fire = "crackle", dur = 2.4, radius = 0.9, scale = 0.6, every = 0.16, seed = 99 },
	{ t = 3.33, fire = "burst" },
	-- r1: debris and dust were gone by 5.4 s and the second half of the hold was empty: a second, smaller burst
	-- where the sphere pops (3.12 + 0.22 + 1.3 = 4.64 s) carries it to the end
	{ t = 4.64, fire = "burst", at = "sphere", scale = 0.75, seed = 43 },
}

function Cutscene.play(opts)
	opts = opts or {}
	local hero, target = Stage.hero(), Stage.target()
	local hr = hero:FindFirstChild("HumanoidRootPart")
	local tr = target:FindFirstChild("HumanoidRootPart")
	local head, hand = hero:FindFirstChild("Head"), hero:FindFirstChild("RightHand")
	local thead = target:FindFirstChild("Head")
	local heroSpace = function()
		return CFrame.new(hr.Position) * hr.CFrame.Rotation
	end
	local subjects = {
		hero = heroSpace,
		head = CineCamera.anchor(head, hr),
		hand = CineCamera.anchor(hand, hr),
		thead = CineCamera.anchor(thead, tr),
	}
	local dir = ((tr.Position - hr.Position) * Vector3.new(1, 0, 1)).Unit
	local side = dir:Cross(Vector3.yAxis).Unit
	local chest0 = target:FindFirstChild("UpperTorso").Position
	local impact = chest0 + dir * 3.5 + Vector3.new(0, 0.6, 0)
	local floorAt = function(p)
		return Vector3.new(p.X, 0, p.Z)
	end
	local strikeAt = {
		bg = floorAt(chest0 + dir * 9 - side * 6),
		left = floorAt(chest0 + dir * 2 + side * 6),
		right = floorAt(chest0 + dir * 5 - side * 7),
		back = floorAt(chest0 + dir * 10 + side * 2),
		far = floorAt(chest0 + dir * 16 - side * 10),
		far2 = floorAt(chest0 + dir * 18 + side * 12),
	}

	local root = FxClock.new("Cutscene", Cutscene.LENGTH + 0.65)
	local c = root:sub("Cutscene", 0, Cutscene.LENGTH + 0.65)

	-- camera first: every later layer reads the camera of the same frame
	local shots = {}
	for _, row in Cutscene.TIMELINE do
		if row.fire == "shot" then
			local s = table.clone(row)
			s.subject = subjects[row.subject]
			table.insert(shots, s)
		end
	end
	CineCamera.play(shots, { clock = c, at = 0 })

	local function focusOf(name)
		if name == "head" then
			return head.Position
		elseif name == "thead" then
			return thead.Position
		elseif name == "impact" then
			return chest0 + dir * 1.5
		end
		return nil
	end

	local fire = {
		letterbox = function(row)
			ScreenOverlays.letterbox({ clock = c, at = row.t, dur = row.dur })
		end,
		vignette = function(row)
			ScreenOverlays.vignette({ clock = c, at = row.t, dur = row.dur, strength = row.strength })
		end,
		speedlines = function(row)
			ScreenOverlays.speedLines({ clock = c, at = row.t, dur = row.dur, focus = focusOf(row.focus), color = row.color, clear = row.clear, seed = row.seed })
		end,
		dark = function(row)
			ImpactFrames.dark({ clock = c, at = row.t, dur = row.dur, fadeIn = row.fadeIn, endL = row.endL, silhouette = if row.silhouette == false then nil else { hero, target } })
		end,
		block = function(row)
			ImpactFrames.block(row.states or ImpactFrames.DEFAULT, { clock = c, at = row.t, endL = row.endL })
		end,
		lettering = function(row)
			Lettering.play(row.words, { clock = c, at = row.t })
		end,
		ink = function(row)
			InkShapes.play({ clock = c, at = row.t, kind = row.kind, frames = row.frames, depth = row.depth, focus = focusOf(row.focus), seed = row.seed, count = row.count })
		end,
		pose = function(row)
			local m = if row.who == "hero" then hero else target
			PoseBeats.play(m, row.keys, { clock = c, at = row.t, lib = if row.who == "hero" then PoseBeats.HERO else PoseBeats.TARGET })
		end,
		crackle = function(row)
			Lightning.ambient(hand, { clock = c, at = row.t, dur = row.dur, radius = row.radius, scale = row.scale, every = row.every, seed = row.seed })
		end,
		sphere = function(row)
			EnergySphere.play(hand, { clock = c, at = row.t, charge = row.charge, rCharge = row.rCharge, R = row.R, burst = row.burst, hold = row.hold, whiteout = false, burstAt = impact, smoke = true })
		end,
		strike = function(row)
			Lightning.ground(strikeAt[row.at], { clock = c, at = row.t, seed = row.seed })
		end,
		arc = function(row)
			c:at(row.t, function()
				local tgt = target:FindFirstChild("UpperTorso").Position
				Lightning.strike(hand.Position, tgt, { clock = c, at = row.t, seed = row.seed, width = 0.12, depth = 4, branches = 2, life = 0.12 })
			end)
		end,
		burst = function(row)
			local p = if row.at == "sphere" then floorAt(impact) else floorAt(chest0 + dir * 2)
			GroundBurst.play(p, { clock = c, at = row.t, dir = dir, seed = row.seed or 41, scale = row.scale })
		end,
		glint = function(row)
			-- a 4-point flare that grows on the fist over 7 frames into the block
			local w = c:sub("Glint", row.t, row.dur + 0.02)
			w:at(0, function()
				local att = w:attachment(nil)
				local e = w:emitter(att, {
					Name = "Glint",
					Lifetime = NumberRange.new(row.dur + 0.05),
					Size = FxClock.ns({ { 0, 0.5 }, { 1, 9 } }),
					Transparency = NumberSequence.new(0),
					Color = ColorSequence.new(H.hot),
					LightEmission = 1,
					Brightness = 5,
					ZOffset = 3,
					Rotation = NumberRange.new(0),
				})
				FxTextures.apply(e, "flare")
				w:every(function()
					att.WorldPosition = hand.Position
				end)
				e:Emit(1)
			end)
		end,
	}

	for _, row in Cutscene.TIMELINE do
		local f = fire[row.fire]
		if f then
			f(row)
		end
	end
	-- phone pass: the thumbstick and jump button sat over every shot; hidden while the scene plays
	local GuiService = game:GetService("GuiService")
	local touchWas = GuiService.TouchControlsEnabled
	GuiService.TouchControlsEnabled = false
	c:onCleanup(function()
		GuiService.TouchControlsEnabled = touchWas
		print("CUTSCENE|" .. Safety.report(root):gsub("\n", " | "))
	end)
	return root:play()
end

return Cutscene
