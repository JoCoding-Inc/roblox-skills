--!nonstrict
-- pose_beats: code-posed key poses for R15 rigs on the fx clock (the character side of the cutscene). A list of
-- keys (time, pose, ease) is sampled every frame and written to each joint's Motor6D.Transform; mostly holds,
-- fast moves of a few frames. Joints are reset to identity at the end (opts.keep = true leaves the last pose).
-- Client only: Motor6D.Transform is local and is not overwritten while no AnimationTrack plays on the rig.
-- roblox-feel-audio-vfx section 3e; ran in Studio 0.747 and 0.748 Play, 2026-11-18, on R15 dummies whose
-- AnimationConstraint joints were replaced by Motor6Ds (cine_stage.buildRigs): on AnimationConstraint joints
-- Transform writes did nothing and C0 errored ("Unable to assign property C0. Property is read only"; measured).
--
-- PoseBeats.play(model, keys, opts?) -> clock. keys = { { t = s, pose = table | name, ease = "snap" |
--   "out" | "in" | "inout" | "linear" } }: the pose is reached AT t; ease shapes the move from the previous key
--   ("snap" holds the previous pose until t, then jumps: a move hidden by a cut).
-- A pose: { [jointName] = CFrame } with jointName one of Root, Waist, Neck, RightShoulder, RightElbow,
--   RightWrist, LeftShoulder, LeftElbow, LeftWrist, RightHip, RightKnee, RightAnkle, LeftHip, LeftKnee, LeftAnkle.
--   Root carries the translation (studs, in the root's own space: -Z forward, +Y up).
-- PoseBeats.HERO and PoseBeats.TARGET: the named poses of the demo (idle, windup, charge, strike, finish;
--   brace, recoil, knock, down). PoseBeats.demo() plays both rigs through one exchange.
--
-- Beat table of the demo (clock s): hero 0-0.30 into wind-up (in-out), hold the charge to 0.80, strike in
-- 4 frames (0.80-0.867, out-expo), hold the strike to 1.50, finishing pose 1.50-1.70 (out-cubic), held to 3.0;
-- target braces 0.6, recoil in 2 frames at 0.867, knock-back 0.90-1.25 (out-cubic) and down by 1.6, held.
-- Built to what four public showcase clips showed (read 2026-11-17; frame counts at each clip's own rate, 30 or 60
-- fps): mostly holds of 18-92 frames; fast moves of a few frames, often across a cut; the camera sells the motion;
-- the release itself may never be shown as motion.
-- What failed while building: no posing at all on AnimationConstraint joints (above); the target's down pose
-- sank through the floor at root y -2.0 (-1.25 now).
-- Limits: rigid limb rotations with no follow-through, overlap or smear pose; a game should use keyframed
-- animations (roblox-character-motion) and keep only the timing of this table.

local FxClock = require(script.Parent.fx_clock)

local PoseBeats = {}

local function A(x, y, z)
	return CFrame.Angles(math.rad(x or 0), math.rad(y or 0), math.rad(z or 0))
end
local function T(x, y, z)
	return CFrame.new(x or 0, y or 0, z or 0)
end
PoseBeats.A, PoseBeats.T = A, T

PoseBeats.JOINTS = {
	Root = "LowerTorso",
	Waist = "UpperTorso",
	Neck = "Head",
	RightShoulder = "RightUpperArm",
	RightElbow = "RightLowerArm",
	RightWrist = "RightHand",
	LeftShoulder = "LeftUpperArm",
	LeftElbow = "LeftLowerArm",
	LeftWrist = "LeftHand",
	RightHip = "RightUpperLeg",
	RightKnee = "RightLowerLeg",
	RightAnkle = "RightFoot",
	LeftHip = "LeftUpperLeg",
	LeftKnee = "LeftLowerLeg",
	LeftAnkle = "LeftFoot",
}

-- Angles: +X on a shoulder or hip swings the limb forward, -X on a knee bends it, +X on the waist leans back,
-- +Y on the waist twists to the character's left, +X on the neck looks up.
PoseBeats.HERO = {
	idle = {},
	windup = {
		Root = T(0, -0.55, 0.35) * A(0, -12, 0),
		Waist = A(-6, -38, 0),
		Neck = A(-10, 30, 0),
		RightShoulder = A(-35, 0, 12),
		RightElbow = A(105, 0, 0),
		RightWrist = A(0, 0, 0),
		LeftShoulder = A(75, 0, 18),
		LeftElbow = A(55, 0, 0),
		RightHip = A(-18, 0, 6),
		RightKnee = A(-28, 0, 0),
		LeftHip = A(34, 0, -6),
		LeftKnee = A(-42, 0, 0),
		LeftAnkle = A(10, 0, 0),
	},
	charge = {
		Root = T(0, -0.75, 0.45) * A(0, -15, 0),
		Waist = A(-12, -42, 0),
		Neck = A(-18, 34, 0),
		RightShoulder = A(-42, 0, 16),
		RightElbow = A(115, 0, 0),
		LeftShoulder = A(82, 0, 22),
		LeftElbow = A(48, 0, 0),
		RightHip = A(-22, 0, 8),
		RightKnee = A(-34, 0, 0),
		LeftHip = A(40, 0, -8),
		LeftKnee = A(-50, 0, 0),
		LeftAnkle = A(12, 0, 0),
	},
	strike = {
		Root = T(0, -0.85, -2.4) * A(0, 14, 0),
		Waist = A(-10, 34, 0),
		Neck = A(4, -32, 0),
		RightShoulder = A(92, 0, 4),
		RightElbow = A(4, 0, 0),
		RightWrist = A(0, 0, 0),
		LeftShoulder = A(-38, 0, 24),
		LeftElbow = A(95, 0, 0),
		RightHip = A(-32, 0, 4),
		RightKnee = A(-8, 0, 0),
		RightAnkle = A(-14, 0, 0),
		LeftHip = A(52, 0, -6),
		LeftKnee = A(-58, 0, 0),
		LeftAnkle = A(8, 0, 0),
	},
	finish = {
		Root = T(0, -0.35, -2.4) * A(0, 10, 0),
		Waist = A(8, 22, 0),
		Neck = A(18, -12, 0),
		RightShoulder = A(162, 0, -14),
		RightElbow = A(12, 0, 0),
		LeftShoulder = A(-14, 0, 22),
		LeftElbow = A(80, 0, 0),
		RightHip = A(-16, 0, 10),
		RightKnee = A(-6, 0, 0),
		LeftHip = A(18, 0, -10),
		LeftKnee = A(-22, 0, 0),
	},
}

PoseBeats.TARGET = {
	idle = {},
	brace = {
		Root = T(0, -0.3, 0) ,
		Waist = A(-8, 0, 0),
		Neck = A(-6, 0, 0),
		RightShoulder = A(60, 0, -28),
		RightElbow = A(80, 0, 0),
		LeftShoulder = A(60, 0, 28),
		LeftElbow = A(80, 0, 0),
		RightHip = A(10, 0, 4),
		RightKnee = A(-18, 0, 0),
		LeftHip = A(10, 0, -4),
		LeftKnee = A(-18, 0, 0),
	},
	recoil = {
		Root = T(0, -0.2, 1.3) * A(16, 0, 0),
		Waist = A(28, 8, 0),
		Neck = A(38, 0, 0),
		RightShoulder = A(78, 0, -40),
		RightElbow = A(20, 0, 0),
		LeftShoulder = A(84, 0, 44),
		LeftElbow = A(18, 0, 0),
		RightHip = A(28, 0, 6),
		RightKnee = A(-10, 0, 0),
		LeftHip = A(-10, 0, -6),
		LeftKnee = A(-24, 0, 0),
	},
	knock = {
		Root = T(0, 0.3, 6) * A(48, 10, 0),
		Waist = A(22, 0, 0),
		Neck = A(30, 0, 0),
		RightShoulder = A(120, 0, -60),
		RightElbow = A(30, 0, 0),
		LeftShoulder = A(130, 0, 60),
		LeftElbow = A(26, 0, 0),
		RightHip = A(55, 0, 10),
		RightKnee = A(-30, 0, 0),
		LeftHip = A(30, 0, -10),
		LeftKnee = A(-50, 0, 0),
	},
	down = {
		-- r2: y -2.0 sank the body through the floor; lying on the back the root sits about 1.3 lower
		Root = T(0, -1.25, 9.5) * A(82, 14, 0),
		Waist = A(4, 0, 0),
		Neck = A(10, 20, 0),
		RightShoulder = A(150, 0, -50),
		RightElbow = A(20, 0, 0),
		LeftShoulder = A(40, 0, 40),
		LeftElbow = A(60, 0, 0),
		RightHip = A(20, 0, 10),
		RightKnee = A(-40, 0, 0),
		LeftHip = A(-5, 0, -8),
		LeftKnee = A(-10, 0, 0),
	},
}

local EASE = {
	linear = function(u)
		return u
	end,
	out = FxClock.outCubic,
	outExpo = function(u)
		return if u >= 1 then 1 else 1 - 2 ^ (-10 * u)
	end,
	["in"] = function(u)
		return u * u * u
	end,
	inout = FxClock.inOutSine,
	snap = function(u)
		return if u >= 1 then 1 else 0
	end,
}

-- Re-applied after the animation step every frame (an Animator may write Transform between our PreRender
-- write and the next render), and while the clock is frozen for a capture.
PoseBeats.held = {} :: { [Instance]: CFrame }
game:GetService("RunService").PreSimulation:Connect(function()
	for mo, cf in PoseBeats.held do
		if mo.Parent then
			mo.Transform = cf
		else
			PoseBeats.held[mo] = nil
		end
	end
end)

function PoseBeats.motors(model)
	local m = {}
	for joint, partName in PoseBeats.JOINTS do
		local p = model:FindFirstChild(partName)
		local mo = p and p:FindFirstChild(joint)
		if mo and (mo:IsA("Motor6D") or mo:IsA("AnimationConstraint")) then
			m[joint] = mo
		end
	end
	return m
end

function PoseBeats.reset(model)
	for _, mo in PoseBeats.motors(model) do
		mo.Transform = CFrame.identity
	end
end

function PoseBeats.play(model, keys, opts)
	opts = opts or {}
	local lib = opts.lib or {}
	local last = keys[#keys].t
	local c, root, own = FxClock.attach("Pose_" .. model.Name, last + (opts.tail or 0.05), opts)
	local motors = PoseBeats.motors(model)
	local function poseOf(k)
		local p = k.pose
		if type(p) == "string" then
			p = lib[p] or {}
		end
		return p
	end
	c:every(function(t)
		local i = 1
		while i < #keys and keys[i + 1].t <= t do
			i += 1
		end
		local a, b = keys[i], keys[i + 1]
		local pa = poseOf(a)
		local u, pb = 0, pa
		if b and t >= a.t then
			pb = poseOf(b)
			u = (EASE[b.ease or "inout"])(math.clamp((t - a.t) / math.max(b.t - a.t, 1e-6), 0, 1))
		elseif t < a.t then
			pb = pa
		end
		for joint, mo in motors do
			local ca = pa[joint] or CFrame.identity
			local cb = pb[joint] or CFrame.identity
			local cf = ca:Lerp(cb, u)
			mo.Transform = cf
			PoseBeats.held[mo] = cf
		end
	end)
	c:onCleanup(function()
		for _, mo in motors do
			PoseBeats.held[mo] = nil
		end
	end)
	if not opts.keep then
		c:onCleanup(function()
			PoseBeats.reset(model)
		end)
	end
	if own then
		root:play()
	end
	return root
end

PoseBeats.DURATION = 3.1
PoseBeats.CAPTURE_TIMES = { 0.0, 0.3, 0.8, 0.817, 0.833, 0.85, 0.867, 0.95, 1.1, 1.3, 1.6, 2.4 }

function PoseBeats.demo(hero, target, opts)
	opts = opts or {}
	local c, root, own = FxClock.attach("PoseDemo", PoseBeats.DURATION, opts)
	PoseBeats.play(hero, {
		{ t = 0, pose = "idle" },
		{ t = 0.3, pose = "windup", ease = "inout" },
		{ t = 0.8, pose = "charge", ease = "inout" },
		{ t = 0.867, pose = "strike", ease = "outExpo" },
		{ t = 1.5, pose = "strike", ease = "linear" },
		{ t = 1.7, pose = "finish", ease = "out" },
		{ t = 3.0, pose = "finish", ease = "linear" },
	}, { clock = c, at = 0, lib = PoseBeats.HERO })
	PoseBeats.play(target, {
		{ t = 0, pose = "idle" },
		{ t = 0.6, pose = "brace", ease = "inout" },
		{ t = 0.867, pose = "brace", ease = "linear" },
		{ t = 0.9, pose = "recoil", ease = "outExpo" },
		{ t = 1.25, pose = "knock", ease = "out" },
		{ t = 1.6, pose = "down", ease = "inout" },
		{ t = 3.0, pose = "down", ease = "linear" },
	}, { clock = c, at = 0, lib = PoseBeats.TARGET })
	if own then
		root:play()
	end
	return root
end

return PoseBeats
