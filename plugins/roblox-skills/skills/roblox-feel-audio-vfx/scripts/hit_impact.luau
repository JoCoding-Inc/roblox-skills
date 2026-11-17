--!nonstrict
-- hit_impact: an electric-blue melee hit on a target: flash, dark underlayer, core stars, bolts, a blue body,
-- streak sparks, a camera-facing shock ring with a dark ring under it, a smoke puff, star pops, a short light,
-- a recoil lean (roblox-feel-audio-vfx section 3d, recipe card "Hit impact"). Needs fx_clock and fx_textures.
-- HitImpact.play(targetModel | impactCFrame, opts?) -> clock. Client only. impactCFrame.LookVector = direction
-- the hit travels. opts.direction (Vector3) overrides the hit direction for a model target (default: into the
-- target's front); opts.noPlay = true returns the clock unstarted.
-- Ran in Studio 0.747 Play on 2026-11-17 on an R15 dummy (desktop view and the Samsung Galaxy A06 Device
-- Simulator preset); not checked in a published game or on a real phone; frame cost not measured.
--
-- Beat table (clock seconds, 60 fps frames in brackets, read from the code below):
-- 0.000 [0]  flash: white soft glow 1.5 -> 3 studs, life 0.05 s; light pulse starts at its peak
-- 0.017 [1]  core: 2 white-cyan-blue stars 1 -> 2.6 -> 0 studs over 0.12-0.15 s; 3 bolts 0.06-0.1 s;
--            blue body 2 -> 5.5 and dark navy underlayer 3.5 -> 6 studs, both 0.16 s
-- 0.033 [2]  sparks: 22 streaks back toward the attacker, 25-45 studs/s, drag 8, 0.12-0.32 s
-- 0.050 [3]  ring: radius 0.5 -> 3.4 over 0.21 s (out-quart), width 0.9 -> 0.12, fades from 35%; dark ring lags
-- 0.067 [4]  smoke: 6 cool grey puffs 1.4 -> 4 studs, 0.5-0.8 s, behind (ZOffset -2)
-- 0.000-0.20 light: cyan-white PointLight 4 -> 0, range 10
-- 0.000-0.40 recoil: target leans 9 deg away (peak at 0.05) and springs back
-- 0.180      star pops: 4 small stars around the hit, 0.25-0.35 s (aftermath)
-- 1.000      cleanup

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local HitImpact = {}

local C = Color3.fromRGB
HitImpact.DURATION = 1.0
HitImpact.CAPTURE_TIMES = { 0.0, 0.017, 0.033, 0.05, 0.075, 0.1, 0.14, 0.2, 0.28, 0.4, 0.6, 0.85 }

HitImpact.P = {
	flashSize = 3,
	coreSize = 2.6,
	sparks = 22,
	sparkSpeed = NumberRange.new(25, 45),
	ringR0 = 0.5,
	ringR1 = 3.4,
	ringW0 = 0.9,
	ringSegments = 12,
	smokeCount = 6,
	light = { range = 10, peak = 4 },
	recoilDeg = 9,
}

local PAL = {
	white = C(255, 255, 255),
	cyan = C(110, 200, 255),
	blue = C(40, 105, 255),
	navy = C(10, 28, 70),
	smoke0 = C(55, 65, 85),
	smoke1 = C(100, 108, 120),
}

local function resolve(target, opts)
	if typeof(target) == "CFrame" then
		return target.Position, target.LookVector, nil
	end
	local root = target:FindFirstChild("HumanoidRootPart")
	local torso = target:FindFirstChild("UpperTorso") or root
	local d = opts.direction or -root.CFrame.LookVector
	-- impact point: the front surface of the torso, on the side the hit comes from
	return torso.Position - d.Unit * 0.6, d.Unit, target
end

function HitImpact.play(target, opts)
	opts = opts or {}
	local P = HitImpact.P
	local p, d, model = resolve(target, opts)
	local clock = FxClock.new("HitImpact", HitImpact.DURATION)
	local smooth, lerp = FxClock.smooth, FxClock.lerp
	local spray = -d -- sparks fly back toward the attacker
	local side = (math.abs(spray.Y) < 0.9 and spray:Cross(Vector3.yAxis) or spray:Cross(Vector3.xAxis)).Unit

	local hitAtt = clock:attachment(CFrame.fromMatrix(p, side, spray))
	local frontAtt = clock:attachment(CFrame.new(p + spray * 0.4)) -- glow layers sit a little toward the camera side

	-- 1 flash
	local flash = clock:emitter(frontAtt, {
		Name = "Flash",
		Lifetime = NumberRange.new(0.05),
		Size = FxClock.ns({ { 0, 1.5 }, { 0.25, P.flashSize }, { 1, P.flashSize * 0.65 } }),
		Transparency = FxClock.ns({ { 0, 0 }, { 0.4, 0.35 }, { 1, 1 } }),
		Color = ColorSequence.new(PAL.white),
		LightEmission = 1,
		Brightness = 5,
		ZOffset = 1.5,
	})
	FxTextures.apply(flash, "glow")
	clock:at(0, function()
		flash:Emit(1)
	end)

	-- 2 dark underlayer (normal blend, under the bright core)
	local under = clock:emitter(hitAtt, {
		Name = "Under",
		Lifetime = NumberRange.new(0.16),
		Size = FxClock.ns({ { 0, 3.5 }, { 1, 6 } }),
		Transparency = FxClock.ns({ { 0, 0.45 }, { 1, 1 } }),
		Color = ColorSequence.new(PAL.navy),
		LightEmission = 0,
		ZOffset = -0.5,
	})
	FxTextures.apply(under, "glow")

	-- 3 core stars
	local core = clock:emitter(frontAtt, {
		Name = "Core",
		Lifetime = NumberRange.new(0.12, 0.15),
		Size = FxClock.ns({ { 0, 1 }, { 0.25, P.coreSize }, { 1, 0 } }),
		Transparency = FxClock.ns({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
		Color = FxClock.cs({ { 0, PAL.white }, { 0.5, PAL.cyan }, { 1, PAL.blue } }),
		LightEmission = 1,
		Brightness = 4,
		ZOffset = 1,
	})
	FxTextures.apply(core, "star")

	-- 3b electric bolts (accent, 3-6 frames)
	local bolts = clock:emitter(frontAtt, {
		Name = "Bolts",
		Lifetime = NumberRange.new(0.06, 0.1),
		Size = FxClock.ns({ { 0, 2.2, 0.6 }, { 1, 3.4, 0.6 } }),
		Transparency = FxClock.ns({ { 0, 0 }, { 1, 0.6 } }),
		Color = FxClock.cs({ { 0, PAL.white }, { 1, PAL.cyan } }),
		LightEmission = 1,
		Brightness = 4,
		ZOffset = 1.2,
	})
	FxTextures.apply(bolts, "electric")
	-- 3c saturated blue body (without it everything else read white on the daylight floor)
	local body = clock:emitter(frontAtt, {
		Name = "BlueBody",
		Lifetime = NumberRange.new(0.16),
		Size = FxClock.ns({ { 0, 2 }, { 1, 5.5 } }),
		Transparency = FxClock.ns({ { 0, 0.25 }, { 1, 1 } }),
		Color = ColorSequence.new(PAL.blue),
		LightEmission = 0.5,
		Brightness = 1.5,
		ZOffset = 0.2,
	})
	FxTextures.apply(body, "glow")
	clock:at(0.017, function()
		under:Emit(1)
		body:Emit(1)
		core:Emit(2)
		bolts:Emit(3)
	end)

	-- 4 streak sparks
	local sparks = clock:emitter(hitAtt, {
		Name = "Sparks",
		EmissionDirection = Enum.NormalId.Top,
		Lifetime = NumberRange.new(0.12, 0.32),
		Speed = P.sparkSpeed,
		SpreadAngle = Vector2.new(65, 65),
		Drag = 8,
		Acceleration = Vector3.new(0, -25, 0),
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Rotation = NumberRange.new(90), -- texture long axis is X; 0 laid every spark across its path (measured)
		Squash = FxClock.ns({ { 0, 1 }, { 1, 0.5 } }),
		Size = FxClock.ns({ { 0, 0.9, 0.15 }, { 1, 0.2 } }),
		Transparency = FxClock.ns({ { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }),
		Color = FxClock.cs({ { 0, PAL.white }, { 0.3, PAL.cyan }, { 1, PAL.blue } }),
		LightEmission = 1, -- black-backed texture needs 1 (measured)
		Brightness = 4,
		ZOffset = 0.8,
	})
	FxTextures.apply(sparks, "streak")
	clock:at(0.033, function()
		sparks:Emit(P.sparks)
	end)

	-- 5 shock ring: in a plane that faces between the attacker and the camera, so it never goes edge-on
	local cam = workspace.CurrentCamera
	local toCam = if cam then (cam.CFrame.Position - p).Unit else spray
	local ringN = (spray + toCam).Unit
	local b1 = (math.abs(ringN.Y) < 0.9 and ringN:Cross(Vector3.yAxis) or ringN:Cross(Vector3.xAxis)).Unit
	local b2 = ringN:Cross(b1).Unit
	local segs = P.ringSegments
	local function ringJoint(j, r, w, a, col)
		local ang = (j - 1) / segs * math.pi * 2
		local radial = b1 * math.cos(ang) + b2 * math.sin(ang)
		local tan = -b1 * math.sin(ang) + b2 * math.cos(ang)
		return { cf = CFrame.fromMatrix(p + radial * r, tan, radial), width = w, alpha = a, color = col }
	end
	local ring = clock:ribbon(segs, { LightEmission = 0.8, Brightness = 2.5, ZOffset = 0.5 })
	local darkRing = clock:ribbon(segs, { LightEmission = 0, Brightness = 1, ZOffset = -0.3 })
	clock:span(0.05, 0.26, function(u)
		local e = FxClock.outQuart(u)
		local r = lerp(P.ringR0, P.ringR1, e)
		local w = lerp(P.ringW0, 0.12, e)
		local a = smooth(0.35, 1, u)
		local col = PAL.white:Lerp(PAL.cyan, smooth(0, 0.25, u))
		ring.update(function(j)
			return ringJoint(j, r, w, a, col)
		end)
		local u2 = math.max(u - 0.08, 0)
		local e2 = FxClock.outQuart(u2)
		darkRing.update(function(j)
			return ringJoint(j, lerp(P.ringR0, P.ringR1 * 0.92, e2), lerp(P.ringW0 * 1.6, 0.2, e2), 0.5 + 0.5 * smooth(0.3, 1, u2), PAL.navy)
		end)
		if u >= 1 then
			ring.hide()
			darkRing.hide()
		end
	end)

	-- 6 smoke puff
	local smoke = clock:emitter(hitAtt, {
		Name = "Smoke",
		EmissionDirection = Enum.NormalId.Top,
		Lifetime = NumberRange.new(0.5, 0.8),
		Speed = NumberRange.new(3, 7),
		SpreadAngle = Vector2.new(80, 80),
		Drag = 4,
		Acceleration = Vector3.new(0, 1.5, 0),
		RotSpeed = NumberRange.new(-40, 40),
		Size = FxClock.ns({ { 0, 1.4, 0.2 }, { 1, 4, 0.4 } }),
		Transparency = FxClock.ns({ { 0, 1 }, { 0.1, 0.35 }, { 1, 1 } }),
		Color = FxClock.cs({ { 0, PAL.smoke0 }, { 1, PAL.smoke1 } }),
		LightEmission = 0,
		ZOffset = -2,
	})
	FxTextures.apply(smoke, "smoke")
	clock:at(0.067, function()
		smoke:Emit(P.smokeCount)
	end)

	-- 7 star pops (aftermath)
	local pops = clock:emitter(hitAtt, {
		Name = "Pops",
		EmissionDirection = Enum.NormalId.Top,
		Lifetime = NumberRange.new(0.25, 0.35),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(90, 90),
		Size = FxClock.ns({ { 0, 0 }, { 0.3, 0.9 }, { 1, 0 } }),
		Transparency = FxClock.ns({ { 0, 0 }, { 1, 0.3 } }),
		Color = FxClock.cs({ { 0, PAL.white }, { 1, PAL.cyan } }),
		LightEmission = 1,
		Brightness = 3,
		ZOffset = 0.6,
	})
	FxTextures.apply(pops, "star")
	clock:at(0.18, function()
		pops:Emit(4)
	end)

	-- 8 light
	local light = clock:light(frontAtt, { Range = P.light.range, Color = C(160, 220, 255) })
	clock:span(0, 0.2, function(u)
		light.Brightness = P.light.peak * (1 - u) ^ 2
	end)

	-- recoil lean (client-side, visual only)
	if model and P.recoilDeg > 0 then
		local lower = model:FindFirstChild("LowerTorso")
		local joint = lower and lower:FindFirstChild("Root")
		if joint and joint:IsA("Motor6D") then
			local c0 = joint.C0
			local rootCF = model.HumanoidRootPart.CFrame
			local axis = rootCF:VectorToObjectSpace(d:Cross(Vector3.yAxis)).Unit
			clock:span(0, 0.4, function(_, t)
				local k = if t < 0.05 then math.sin(t / 0.05 * math.pi / 2) else 1 - smooth(0.05, 0.4, t)
				joint.C0 = c0 * CFrame.fromAxisAngle(axis, -math.rad(P.recoilDeg) * k)
			end)
			clock:onCleanup(function()
				joint.C0 = c0
			end)
		end
	end

	if opts.noPlay then
		return clock
	end
	return clock:play()
end

return HitImpact
