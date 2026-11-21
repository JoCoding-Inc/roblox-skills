--!nonstrict
-- pose_beats: code-posed key poses for R15 rigs on the fx clock (the character side of the cutscene). A list of
-- keys (time, pose, ease) is sampled every frame and written to each joint's Motor6D.Transform; mostly holds,
-- fast moves of a few frames. Joints are reset to identity at the end; opts.keep = true holds the last pose
-- (still, no sway) until the next play, PoseBeats.reset or the restore of prepare.
-- Client only: Motor6D.Transform is local. On a rig with an Animator it is cleared every frame even with no track
-- playing (measured on a live avatar, 2026-11-21), so every pose is written again each PreSimulation.
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
-- PoseBeats.POSES: general cutscene poses (stand, gaze, rise, fly, coil, burst, hover, reach, hero, cheer, fall).
-- PoseBeats.prepare(character) -> restore(): makes a live avatar posable (AnimationConstraint joints get
--   Motor6D twins, the Animate script and playing tracks stop) and undoes it afterwards.
-- opts.sway = degrees (2-3): a held pose keeps breathing instead of freezing.
-- PoseBeats.face(character, name?) -> { has, set(name | weights, seconds?), stop() }: an expression on a head
--   with FaceControls (PoseBeats.FACES: neutral, smile, joy, awe, grim, shut). Measured in Studio 0.748 Play,
--   2026-11-21, on a live avatar after prepare(): a weight written once read back 0 on the next frame and the
--   face did not change; the same weights written every PreSimulation drew the face, and stopping the writes
--   gave the avatar's own face back. smile, joy, awe and grim were read on close captures of one blocky head
--   (no brows: grim reads as a frown with narrowed eyes); shut was not captured. A classic head with a face
--   decal has no FaceControls: has is false and set does nothing.
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

-- General poses for a cutscene character (a reveal, a power-up, a flight): each one read on a capture from the
-- front and the side. Use them as keys ({ t = 2.0, pose = "burst", ease = "outExpo" } with opts.lib =
-- PoseBeats.POSES) so no held shot shows the default stance. Root rotations tilt the whole body: fly lies
-- forward, fall lies back.
PoseBeats.POSES = {
	stand = {},
	-- still and looking up at something: chin lifted, chest open and turned a little, one arm back and one hand
	-- half raised, the weight on one leg. The pose for a quiet start and for a face shot (coil drops the chin and hides the face)
	gaze = {
		Waist = A(7, 7, 0),
		Neck = A(19, -5, 3),
		RightShoulder = A(-18, 0, 9),
		RightElbow = A(10, 0, 0),
		LeftShoulder = A(-4, 0, -17),
		LeftElbow = A(24, 0, 0),
		RightHip = A(2, 0, 3),
		LeftHip = A(9, 0, -4),
		LeftKnee = A(-16, 0, 0),
	},
	-- lifted off the ground: chest up, arms a little back and out, legs trailing
	rise = {
		Root = A(8, 0, 0),
		Waist = A(12, 0, 0),
		Neck = A(22, 0, 0),
		RightShoulder = A(-28, 0, 26),
		RightElbow = A(18, 0, 0),
		LeftShoulder = A(-28, 0, -26),
		LeftElbow = A(18, 0, 0),
		RightHip = A(-6, 0, 5),
		RightKnee = A(-14, 0, 0),
		RightAnkle = A(-20, 0, 0),
		LeftHip = A(14, 0, -5),
		LeftKnee = A(-34, 0, 0),
		LeftAnkle = A(-20, 0, 0),
	},
	-- flying forward: the body lies forward, one arm leads, the other trails, head up
	fly = {
		Root = A(-78, 0, 0),
		Waist = A(8, 0, 0),
		Neck = A(48, 0, 0),
		RightShoulder = A(172, 0, 6),
		RightElbow = A(6, 0, 0),
		LeftShoulder = A(-14, 0, -14),
		LeftElbow = A(22, 0, 0),
		RightHip = A(-6, 0, 4),
		RightKnee = A(-10, 0, 0),
		RightAnkle = A(-28, 0, 0),
		LeftHip = A(8, 0, -4),
		LeftKnee = A(-30, 0, 0),
		LeftAnkle = A(-28, 0, 0),
	},
	-- gathered in before a burst: knees up, arms crossed over the chest, head down
	coil = {
		Root = A(-14, 0, 0),
		Waist = A(-18, 0, 0),
		Neck = A(-24, 0, 0),
		RightShoulder = A(58, 0, -38),
		RightElbow = A(112, 0, 0),
		LeftShoulder = A(58, 0, 38),
		LeftElbow = A(112, 0, 0),
		RightHip = A(72, 0, 4),
		RightKnee = A(-96, 0, 0),
		LeftHip = A(56, 0, -4),
		LeftKnee = A(-104, 0, 0),
	},
	-- thrown open: back arched, arms up and out, legs apart, head back
	burst = {
		Root = A(10, 0, 0),
		Waist = A(20, 0, 0),
		Neck = A(26, 0, 0),
		RightShoulder = A(128, 0, 44),
		RightElbow = A(10, 0, 0),
		LeftShoulder = A(128, 0, -44),
		LeftElbow = A(10, 0, 0),
		RightHip = A(-12, 0, 24),
		RightKnee = A(-10, 0, 0),
		RightAnkle = A(-18, 0, 0),
		LeftHip = A(-4, 0, -24),
		LeftKnee = A(-26, 0, 0),
		LeftAnkle = A(-18, 0, 0),
	},
	-- a calm float: arms low and open, one knee bent, toes down
	hover = {
		Waist = A(4, 0, 0),
		Neck = A(6, 0, 0),
		RightShoulder = A(-6, 0, 22),
		RightElbow = A(16, 0, 0),
		LeftShoulder = A(-6, 0, -22),
		LeftElbow = A(16, 0, 0),
		RightHip = A(4, 0, 4),
		RightKnee = A(-8, 0, 0),
		RightAnkle = A(-24, 0, 0),
		LeftHip = A(22, 0, -4),
		LeftKnee = A(-44, 0, 0),
		LeftAnkle = A(-24, 0, 0),
	},
	-- one hand reaching up at something, eyes on it
	reach = {
		Waist = A(10, -8, 0),
		Neck = A(30, 10, 0),
		RightShoulder = A(158, 0, 12),
		RightElbow = A(8, 0, 0),
		LeftShoulder = A(-18, 0, -30),
		LeftElbow = A(24, 0, 0),
		RightHip = A(-4, 0, 6),
		RightKnee = A(-8, 0, 0),
		LeftHip = A(12, 0, -6),
		LeftKnee = A(-28, 0, 0),
	},
	-- the payoff: a fist in the air, the other at the hip, feet apart, chin up
	hero = {
		Root = A(0, -14, 0),
		Waist = A(8, 12, 0),
		Neck = A(12, 4, 0),
		RightShoulder = A(168, 0, 18),
		RightElbow = A(24, 0, 0),
		LeftShoulder = A(-12, 0, -34),
		LeftElbow = A(96, 0, 0),
		RightHip = A(-4, 0, 16),
		RightKnee = A(-4, 0, 0),
		LeftHip = A(6, 0, -18),
		LeftKnee = A(-12, 0, 0),
	},
	-- both arms up in a V, small jump bend
	cheer = {
		Waist = A(10, 0, 0),
		Neck = A(18, 0, 0),
		RightShoulder = A(150, 0, 30),
		RightElbow = A(14, 0, 0),
		LeftShoulder = A(150, 0, -30),
		LeftElbow = A(14, 0, 0),
		RightHip = A(10, 0, 8),
		RightKnee = A(-30, 0, 0),
		LeftHip = A(18, 0, -8),
		LeftKnee = A(-48, 0, 0),
	},
	-- falling on the back: limbs trail upward
	fall = {
		Root = A(64, 0, 0),
		Waist = A(-10, 0, 0),
		Neck = A(-16, 0, 0),
		RightShoulder = A(96, 0, 30),
		RightElbow = A(26, 0, 0),
		LeftShoulder = A(112, 0, -30),
		LeftElbow = A(20, 0, 0),
		RightHip = A(48, 0, 8),
		RightKnee = A(-34, 0, 0),
		LeftHip = A(30, 0, -8),
		LeftKnee = A(-52, 0, 0),
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

-- share of opts.sway (degrees) per joint: { about X, phase, about Z }
local SWAY = {
	Waist = { 0.6, 0, 0.2 },
	Neck = { 0.5, 0.9, 0.3 },
	RightShoulder = { 1, 0.4, 0.8 },
	LeftShoulder = { 1, 1.7, 0.8 },
	RightHip = { 0.5, 2.2, 0.2 },
	LeftHip = { 0.5, 0.6, 0.2 },
}

-- Make a live character posable and give it back afterwards. An avatar whose joints are AnimationConstraints
-- ignores Transform writes (measured, section 3e), and its Animate script keeps playing the idle or fall
-- animation over any pose. prepare() stops the playing tracks and the Animate script, and gives every
-- AnimationConstraint joint a Motor6D twin for as long as the cutscene runs; the function it returns undoes all
-- of it (call it when the cutscene ends or is skipped). Client side, on the local player's own character.
-- local restore = PoseBeats.prepare(character) ... PoseBeats.play(character, keys, { lib = PoseBeats.POSES }) ... restore()
function PoseBeats.prepare(model)
	local undo = {}
	local animate = model:FindFirstChild("Animate")
	if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) and animate.Enabled then
		animate.Enabled = false
		table.insert(undo, function()
			animate.Enabled = true
		end)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") and d.Attachment0 and d.Attachment1 then
			local name, enabled = d.Name, d.Enabled
			local mo = Instance.new("Motor6D")
			mo.Name = name
			mo.Part0 = d.Attachment0.Parent
			mo.Part1 = d.Attachment1.Parent
			mo.C0 = d.Attachment0.CFrame
			mo.C1 = d.Attachment1.CFrame
			d.Enabled = false
			d.Name = name .. "_Constraint" -- PoseBeats.motors finds joints by name: the Motor6D takes it
			mo.Parent = d.Parent
			table.insert(undo, function()
				PoseBeats.held[mo] = nil
				mo:Destroy()
				d.Name = name
				d.Enabled = enabled
			end)
		end
	end
	return function()
		for i = #undo, 1, -1 do
			undo[i]()
		end
		table.clear(undo)
		PoseBeats.reset(model)
	end
end

-- FaceControls weights (0-1) per expression; a control with a Left and a Right side is named once and written to both
PoseBeats.FACES = {
	neutral = {},
	smile = { LipCornerPuller = 1, CheekRaiser = 0.7 },
	joy = { LipCornerPuller = 1, CheekRaiser = 0.7, JawDrop = 1, UpperLipRaiser = 0.4 },
	awe = { JawDrop = 0.8, Funneler = 0.4, OuterBrowRaiser = 1, InnerBrowRaiser = 1, EyeUpperLidRaiser = 1 },
	grim = { BrowLowerer = 1, Corrugator = 1, LipCornerDown = 0.7, LipPresser = 0.6, EyeClosed = 0.35, NoseWrinkler = 0.5 },
	shut = { EyeClosed = 1, LipPresser = 0.4 },
}

local SIDED = {}
for _, name in
	{ "BrowLowerer", "CheekPuff", "CheekRaiser", "Dimpler", "EyeClosed", "EyeUpperLidRaiser", "InnerBrowRaiser", "LipCornerDown", "LipCornerPuller", "LipStretcher", "LowerLipDepressor", "NoseWrinkler", "OuterBrowRaiser", "UpperLipRaiser" }
do
	SIDED[name] = true
end

local function faceWeights(face)
	local out = {}
	for key, value in (if type(face) == "table" then face else PoseBeats.FACES[face]) do
		if SIDED[key] then
			out["Left" .. key], out["Right" .. key] = value, value
		else
			out[key] = value
		end
	end
	return out
end

function PoseBeats.face(model, name)
	local head = model:FindFirstChild("Head")
	local controls = head and head:FindFirstChildOfClass("FaceControls")
	local from, to, now = {}, faceWeights(name or "neutral"), {}
	local t0, dur = 0, 0
	local conn = controls
		and game:GetService("RunService").PreSimulation:Connect(function()
			local u = if dur > 0 then math.clamp((os.clock() - t0) / dur, 0, 1) else 1
			u = 1 - (1 - u) ^ 2
			table.clear(now)
			for key, value in from do
				now[key] = value * (1 - u)
			end
			for key, value in to do
				now[key] = (now[key] or 0) + value * u
			end
			for key, value in now do
				(controls :: any)[key] = value
			end
		end)
	return {
		has = controls ~= nil,
		set = function(face, seconds)
			from, to, now = table.clone(now), faceWeights(face), {}
			t0, dur = os.clock(), seconds or 0.12
		end,
		stop = function()
			if conn then
				conn:Disconnect()
				conn = nil
			end
		end,
	}
end

function PoseBeats.reset(model)
	for _, mo in PoseBeats.motors(model) do
		PoseBeats.held[mo] = nil
		mo.Transform = CFrame.identity
	end
end

function PoseBeats.play(model, keys, opts)
	opts = opts or {}
	local lib = opts.lib or {}
	local last = keys[#keys].t
	local c, root, own = FxClock.attach("Pose_" .. model.Name, last + (opts.tail or 0.05), opts)
	local motors = PoseBeats.motors(model)
	local sway = opts.sway or 0
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
			local sw = sway > 0 and SWAY[joint]
			if sw then -- a held pose keeps breathing: a few degrees on the chest, the head and the arms
				cf *= CFrame.Angles(math.rad(sway * sw[1] * math.sin(t * 2.6 + sw[2])), 0, math.rad(sway * sw[3] * math.sin(t * 2.1 + sw[2])))
			end
			mo.Transform = cf
			PoseBeats.held[mo] = cf
		end
	end)
	-- keep: the last pose stays written every frame after the clock ends (until the next play, reset or the
	-- restore of prepare). Measured on a live avatar: a Transform written once was identity again 0.3 s later.
	c:onCleanup(function()
		if opts.keep then
			return
		end
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
