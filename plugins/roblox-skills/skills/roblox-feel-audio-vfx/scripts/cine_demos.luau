--!nonstrict
-- cine_demos: one short showcase per element on the two stage dummies, each seen from the cutscene camera
-- (cine_camera shots, never a free camera), plus the beat times used for its capture strip
-- (roblox-feel-audio-vfx section 3e, assets/cutscene-examples). Client only.
-- Demos.LIST[key] = { name, play = function() -> root clock, times = { capture beats } }; keys "1".."9" are the
-- elements (1 camera reel, 2 impact frames, 3 overlays, 4 lightning, 5 energy sphere, 6 ground burst, 7 ink
-- shapes, 8 lettering, 9 pose beats) and "0" is the cutscene (skill_cutscene.luau).
--
-- Running the example (a LocalScript, the modules in ReplicatedStorage.Fx, a server Script that calls
-- require(ReplicatedStorage.Fx.cine_stage).buildRigs()):
--   local Fx = game:GetService("ReplicatedStorage"):WaitForChild("Fx")
--   require(Fx.cine_stage).setup()
--   task.spawn(require(Fx.fx_textures).resolve)
--   local Demos = require(Fx.cine_demos)
--   Demos.LIST["0"].play()                                   -- or bind keys 1-9 and 0 to LIST[key].play()
-- Freeze-frame capture of one: require(Fx.fx_capture).run(d.name, d.play, d.times, { hold = 1.8, scale = 0.25 }).

local FxClock = require(script.Parent.fx_clock)
local Stage = require(script.Parent.cine_stage)
local CineCamera = require(script.Parent.cine_camera)
local ImpactFrames = require(script.Parent.impact_frames)
local ScreenOverlays = require(script.Parent.screen_overlays)
local Lightning = require(script.Parent.lightning)
local EnergySphere = require(script.Parent.energy_sphere)
local GroundBurst = require(script.Parent.ground_burst)
local InkShapes = require(script.Parent.ink_shapes)
local Lettering = require(script.Parent.lettering)
local PoseBeats = require(script.Parent.pose_beats)
local Cutscene = require(script.Parent.skill_cutscene)

local Demos = {}

local V = Vector3.new
local H = Stage.HUE

local function rig()
	local hero, target = Stage.hero(), Stage.target()
	local hr = hero:FindFirstChild("HumanoidRootPart")
	local tr = target:FindFirstChild("HumanoidRootPart")
	local heroSpace = function()
		return CFrame.new(hr.Position) * hr.CFrame.Rotation
	end
	return hero, target, hr, tr, heroSpace
end

-- A static shot of both dummies from the side, low (the comparison frame for screen-wide states).
local function sideShot(t, len, heroSpace, extra)
	local s = { t = t, len = len, subject = heroSpace, from = { offset = V(12, -1.6, -3.5), look = V(0, 0.6, -3.5) }, fov = 50, roll = 0, name = "side" }
	for k, v in extra or {} do
		s[k] = v
	end
	return s
end

local function withCamera(name, dur, shots, body)
	local root = FxClock.new(name, dur + 0.65)
	local c = root:sub(name, 0, dur + 0.65)
	CineCamera.play(shots, { clock = c, at = 0 })
	body(c)
	return root:play()
end

Demos.LIST = {}

-- 1 camera reel
Demos.LIST["1"] = {
	name = "CameraReel",
	times = { 0.05, 0.6, 1.02, 1.1, 1.2, 1.5, 1.62, 1.75, 2.1, 2.3, 2.8, 3.3, 3.45, 3.5, 3.55, 3.6, 3.65, 4.0, 4.5, 4.9 },
	play = function()
		local hero, target, hr, tr, hs = rig()
		local head, hand = hero:FindFirstChild("Head"), hero:FindFirstChild("RightHand")
		local shots = {
			{ t = 0, len = 1.0, name = "low wide", subject = hs, from = { offset = V(12, -2.6, -1), look = V(0, 1.2, -3.5) }, to = { offset = V(10.5, -2.6, -1.6), look = V(0, 1.2, -3.5) }, fov = 55, move = { ease = "inOutSine" } },
			{ t = 1.0, len = 0.6, name = "ECU face push-in 12 f", subject = CineCamera.anchor(head, hr), from = { offset = V(0.5, -0.6, -3.0), look = V(0, 0.1, 0) }, to = { offset = V(0.35, -0.45, -1.7), look = V(0, 0.1, 0) }, fov = 40, move = { t0 = 0, t1 = 0.2, ease = "outCubic" } },
			{ t = 1.6, len = 0.6, name = "ECU hand dutch 20, pull-out 10 f", subject = CineCamera.anchor(hand, hr), from = { offset = V(1.0, -1.0, -1.4), look = V(0, 0, 0) }, to = { offset = V(2.0, -1.8, -2.8), look = V(0, 0, 0) }, fov = 40, roll = 20, move = { t0 = 0.05, t1 = 0.217, ease = "outCubic" } },
			{ t = 2.2, len = 1.2, name = "orbit 80 deg, roll 14 -> 0", subject = hs, from = { offset = V(0, 0.5, -6.5), look = V(0, 0.6, 0) }, orbit = 80, fov = { 50, 58 }, roll = { 14, 0 }, move = { ease = "inOutSine" } },
			{ t = 3.4, len = 1.2, name = "low wide + shake", subject = hs, from = { offset = V(-12, -2.6, -6), look = V(0, 1.4, -3.5) }, fov = 60, roll = -6, shake = { amp = 4, roll = 12, len = 0.9, at = 0.05, step = 0.05, freq = 9 } },
		}
		-- r1: in the rest pose the hand hung at the hip and its ECU showed only a dark arm; r2: the charge pose
		-- pulls the fist back to the hip (legs filled the frame); the finish pose raises it against the sky, snapped
		-- in across the cut so the face close-up before it keeps the rest pose
		return withCamera("CameraReel", 4.6, shots, function(c)
			PoseBeats.play(hero, { { t = 0, pose = "idle" }, { t = 1.58, pose = "idle", ease = "linear" }, { t = 1.63, pose = "finish", ease = "out" }, { t = 2.3, pose = "finish", ease = "linear" }, { t = 2.7, pose = "idle", ease = "inout" }, { t = 4.6, pose = "idle" } }, { clock = c, at = 0, lib = PoseBeats.HERO })
		end)
	end,
}

-- 2 impact frames: dark beat, block A, block B, white-out with decay
Demos.LIST["2"] = {
	name = "ImpactFrames",
	times = { 0.2, 0.45, 0.467, 0.483, 0.5, 0.517, 0.533, 0.55, 0.567, 0.583, 0.6, 0.617, 0.633, 0.65, 0.7, 1.7, 1.717, 1.75, 1.767, 1.8, 1.817, 1.85, 1.867, 1.9, 2.95, 3.0, 3.05, 3.1, 3.15, 3.2, 3.3 },
	play = function()
		local hero, target, hr, tr, hs = rig()
		return withCamera("ImpactFrames", 3.6, { sideShot(0, 3.6, hs) }, function(c)
			ImpactFrames.dark({ clock = c, at = 0, dur = 0.45, silhouette = { hero, target } })
			ImpactFrames.block(ImpactFrames.DEFAULT, { clock = c, at = 0.45 })
			ImpactFrames.block({
				{ kind = "black", dur = 0.05 },
				{ kind = "mono", dur = 0.05 },
				{ kind = "field", dur = 0.05, color = H.white, sil = H.ink },
				{ kind = "field", dur = 0.05, color = H.blue, sil = H.white },
			}, { clock = c, at = 1.7, keep = { hero } })
			ImpactFrames.whiteout({ clock = c, at = 2.95 }) -- more than 1 s after block B (the cap refused it at 2.6)
		end)
	end,
}

-- 3 overlays
Demos.LIST["3"] = {
	name = "Overlays",
	times = { 0.1, 0.3, 0.6, 0.617, 0.633, 0.65, 0.667, 0.75, 0.85, 1.3, 1.317, 1.333, 1.35, 1.7, 2.1, 2.25 },
	play = function()
		local hero, target, hr, tr, hs = rig()
		local head = hero:FindFirstChild("Head")
		local shots = {
			{ t = 0, len = 1.1, name = "ECU face from below", subject = CineCamera.anchor(head, hr), from = { offset = V(0.5, -1.2, -2.2), look = V(0, 0.15, 0) }, to = { offset = V(0.4, -1.0, -1.8), look = V(0, 0.15, 0) }, fov = 45, roll = -10 },
			{ t = 1.1, len = 1.2, name = "low wide", subject = hs, from = { offset = V(10, -2.6, -1), look = V(0, 1.2, -3.5) }, fov = 55, roll = 6 },
		}
		return withCamera("Overlays", 2.3, shots, function(c)
			ScreenOverlays.demo(hero, { clock = c, at = 0 })
		end)
	end,
}

-- 4 lightning
Demos.LIST["4"] = {
	name = "Lightning",
	times = Lightning.CAPTURE_TIMES,
	play = function()
		local hero, target, hr, tr, hs = rig()
		local shots = {
			{ t = 0, len = 1.6, name = "low wide", subject = hs, from = { offset = V(13, -2.6, 1), look = V(0, 3.5, -6) }, fov = 60, roll = -5 },
		}
		return withCamera("Lightning", 1.6, shots, function(c)
			Lightning.play(hero, { clock = c, at = 0 })
		end)
	end,
}

-- 5 energy sphere
Demos.LIST["5"] = {
	name = "EnergySphere",
	times = EnergySphere.CAPTURE_TIMES,
	play = function()
		local hero, target, hr, tr, hs = rig()
		local hand = hero:FindFirstChild("RightHand")
		local shots = {
			{ t = 0, len = 0.6, name = "close on the fist", subject = CineCamera.anchor(hand, hr), from = { offset = V(2.4, 0.4, -2.2), look = V(0, 0, 0) }, fov = 45, roll = 12 },
			{ t = 0.6, len = 1.6, name = "low wide", subject = hs, from = { offset = V(16, -2.6, -4), look = V(0, 2.5, -9) }, to = { offset = V(18, -2.6, -4), look = V(0, 2.5, -9) }, fov = 60 },
		}
		return withCamera("EnergySphere", 2.2, shots, function(c)
			EnergySphere.demo(hero, { clock = c, at = 0 })
		end)
	end,
}

-- 6 ground ring, debris, dust
Demos.LIST["6"] = {
	name = "GroundBurst",
	times = GroundBurst.CAPTURE_TIMES,
	play = function()
		local hero, target, hr, tr, hs = rig()
		local shots = {
			{ t = 0, len = 2.1, name = "ground-level wide", subject = hs, from = { offset = V(15, -2.6, -2), look = V(0, 2, -8) }, fov = 60, roll = 4 },
		}
		return withCamera("GroundBurst", 2.1, shots, function(c)
			local p = tr.Position - Vector3.new(0, 2.5, 0) + (tr.Position - hr.Position).Unit * 2
			GroundBurst.play(p, { clock = c, at = 0, dir = (tr.Position - hr.Position) * Vector3.new(1, 0, 1) })
		end)
	end,
}

-- 7 flat graphic shapes
Demos.LIST["7"] = {
	name = "InkShapes",
	times = { 0.0, 0.017, 0.033, 0.05, 0.067, 0.3, 0.317, 0.333, 0.6, 0.617, 0.633, 0.65, 0.9 },
	play = function()
		local hero, target, hr, tr, hs = rig()
		local focus = target:FindFirstChild("UpperTorso").Position
		return withCamera("InkShapes", 1.0, { sideShot(0, 1.0, hs, { fov = 55 }) }, function(c)
			InkShapes.play({ clock = c, at = 0, kind = "spikes", focus = focus, frames = 5, depth = "behind" })
			InkShapes.play({ clock = c, at = 0.3, kind = "smear", frames = 3, depth = "front" })
			InkShapes.play({ clock = c, at = 0.6, kind = "shards", focus = focus, frames = 4, depth = "front" }) -- r2: behind, the floor cut the low shards
		end)
	end,
}

-- 8 lettering
Demos.LIST["8"] = {
	name = "Lettering",
	times = Lettering.CAPTURE_TIMES,
	play = function()
		local hero, target, hr, tr, hs = rig()
		return withCamera("Lettering", 1.6, { sideShot(0, 1.6, hs) }, function(c)
			Lettering.demo({ clock = c, at = 0 })
		end)
	end,
}

-- 9 pose beats
Demos.LIST["9"] = {
	name = "PoseBeats",
	times = PoseBeats.CAPTURE_TIMES,
	play = function()
		local hero, target, hr, tr, hs = rig()
		return withCamera("PoseBeats", 3.1, { sideShot(0, 3.1, hs, { from = { offset = V(14, 0.5, -4.5), look = V(0, 0, -4.5) }, fov = 50 }) }, function(c)
			PoseBeats.demo(hero, target, { clock = c, at = 0 })
		end)
	end,
}

Demos.LIST["0"] = {
	name = "Cutscene",
	times = Cutscene.CAPTURE_TIMES,
	play = function()
		return Cutscene.play()
	end,
}

return Demos
