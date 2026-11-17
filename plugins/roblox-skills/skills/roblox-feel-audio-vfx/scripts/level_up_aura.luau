--!nonstrict
-- level_up_aura: a gold level-up: ground burst ring over a dark ring, white core flash, a rising light pillar
-- with a white core, a burst of stars, then a sustain to about 2.85 s (rising streaks, soft glows, a pulsing
-- ground circle with a dark ring under it, a warm light) and a clean fade. Follows the character while it plays
-- (roblox-feel-audio-vfx section 3d, recipe card "Level-up aura"). Needs fx_clock and fx_textures.
-- LevelUpAura.play(character | rootCFrame, opts?) -> clock. Client only. opts.noPlay = true returns the clock unstarted.
-- Ran in Studio 0.747 Play on 2026-11-17 on an R15 dummy (desktop view and the Samsung Galaxy A06 Device
-- Simulator preset); not checked in a published game or on a real phone; frame cost not measured.
--
-- Beat table (clock seconds, read from the code below):
-- 0.00-0.40  ground ring: radius 0.8 -> 6.5 (out-quart), width 1.4 -> 0.15, fades from 30%; dark ring under it
-- 0.00-0.06  light: 0 -> 5, then down to 1.8 by 0.5; sustain 1.8 with a 1.1 Hz pulse; 0 at 3.3
-- 0.03       core flash: pale glow at the chest 1.2 -> 3.5 -> 2.5 studs, life 0.1 s
-- 0.05-0.75  pillar: from 0.9 studs under the feet to 13 above, width 0 -> 5 at 0.15, narrows to 1.5 and fades
--            by 0.75; a white core beam inside it, gone by 0.45
-- 0.08       burst stars: 32 up a 22 deg cone, 18-32 studs/s, fall back, 0.7-1.1 s
-- 0.25-2.85  risers: streaks off a 4.6-stud box at the feet, rate ramps 0 -> 26/s -> 0, each 0.9-1.3 s
-- 0.25-2.85  glow column: soft gold glows rising around the body, up to 7/s, each 0.9-1.2 s, faint
-- 0.20-3.30  ground circle: radius 2.2 -> 3.0 (0.20-0.45), pulse 1.1 Hz, widens to 3.6 and fades 2.8-3.3
-- 4.20       last particles gone, cleanup

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local LevelUpAura = {}

local C = Color3.fromRGB
LevelUpAura.DURATION = 4.2
LevelUpAura.CAPTURE_TIMES = { 0.02, 0.05, 0.1, 0.18, 0.3, 0.5, 0.9, 1.5, 2.2, 2.9, 3.2, 3.7 }

LevelUpAura.P = {
	ringR1 = 6.5,
	pillarHeight = 13,
	pillarWidth = 5,
	burstCount = 32,
	riserRate = 26,
	glowRate = 7,
	circleR = 3.0,
	segments = 16,
	light = { range = 12, peak = 5, sustain = 1.8 },
}

local PAL = {
	white = C(255, 253, 240),
	pale = C(255, 235, 150),
	gold = C(255, 190, 50),
	amber = C(220, 120, 20),
	dark = C(90, 50, 10),
}

local function resolve(target)
	if typeof(target) == "CFrame" then
		return function()
			return target.Position - Vector3.new(0, 3, 0)
		end, 5
	end
	local root = target:FindFirstChild("HumanoidRootPart")
	local hum = target:FindFirstChildOfClass("Humanoid")
	local hip = if hum then hum.HipHeight else 2
	return function()
		return root.Position - Vector3.new(0, root.Size.Y / 2 + hip, 0)
	end, root.Size.Y / 2 + hip + 2.2
end

function LevelUpAura.play(target, opts)
	opts = opts or {}
	local P = LevelUpAura.P
	local feetFn, chestH = resolve(target)
	local clock = FxClock.new("LevelUpAura", LevelUpAura.DURATION)
	local smooth, lerp = FxClock.smooth, FxClock.lerp

	local up = CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, Vector3.yAxis)
	local feetAtt = clock:attachment(nil)
	local chestAtt = clock:attachment(nil)
	local topAtt = clock:attachment(nil)
	local disc = clock:part({ Name = "Disc", Size = Vector3.new(4.6, 0.2, 4.6) })
	local feet = feetFn()
	local function follow()
		feet = feetFn()
		feetAtt.WorldCFrame = up + feet + Vector3.new(0, 0.1, 0)
		chestAtt.WorldCFrame = up + feet + Vector3.new(0, chestH, 0)
		topAtt.WorldCFrame = up + feet + Vector3.new(0, P.pillarHeight, 0)
		disc.CFrame = CFrame.new(feet + Vector3.new(0, 0.2, 0))
	end
	follow()
	clock:every(function()
		follow()
	end)

	-- flat rings on the ground (beam ribbons lying in the XZ plane)
	local segs = P.segments
	local function flatJoint(j, r, w, a, col, y)
		local ang = (j - 1) / segs * math.pi * 2
		local radial = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local tan = Vector3.new(-math.sin(ang), 0, math.cos(ang))
		return { cf = CFrame.fromMatrix(feet + Vector3.new(0, y or 0.08, 0) + radial * r, tan, radial), width = w, alpha = a, color = col }
	end
	local function bandify(ribbon, speed)
		for _, b in ribbon.beams do
			FxTextures.apply(b, "band")
			b.TextureMode = Enum.TextureMode.Wrap
			b.TextureLength = 0.05
		end
	end

	-- 1 ground burst ring
	local burstRing = clock:ribbon(segs, { LightEmission = 0.8, Brightness = 2.5, ZOffset = 0.3 })
	local burstDark = clock:ribbon(segs, { LightEmission = 0, Brightness = 1, ZOffset = -0.2 })
	clock:span(0, 0.4, function(u)
		local e = FxClock.outQuart(u)
		local r, w, a = lerp(0.8, P.ringR1, e), lerp(1.4, 0.15, e), smooth(0.3, 1, u)
		local col = PAL.white:Lerp(PAL.gold, smooth(0, 0.4, u))
		burstRing.update(function(j)
			return flatJoint(j, r, w, a, col, 0.1)
		end)
		burstDark.update(function(j)
			return flatJoint(j, r * 0.97, w * 1.7, 0.5 + 0.5 * a, PAL.dark, 0.09)
		end)
		if u >= 1 then
			burstRing.hide()
			burstDark.hide()
		end
	end)

	-- 2 core flash
	local flash = clock:emitter(chestAtt, {
		Name = "CoreFlash",
		Lifetime = NumberRange.new(0.1),
		Size = FxClock.ns({ { 0, 1.2 }, { 0.25, 3.5 }, { 1, 2.5 } }), -- a 6-stud peak swallowed the character
		Transparency = FxClock.ns({ { 0, 0 }, { 0.4, 0.2 }, { 1, 1 } }),
		Color = ColorSequence.new(PAL.pale),
		LightEmission = 1,
		Brightness = 5,
		ZOffset = 1,
	})
	FxTextures.apply(flash, "glow")
	clock:at(0.03, function()
		flash:Emit(1)
	end)

	-- 3 pillar: two camera-facing beams, each textured once along its length with the soft circle
	-- (Stretch, TextureLength 1) so it reads as a soft vertical glow, not a slab. Gold outside, white core inside.
	local baseAtt = clock:attachment(nil)
	clock:every(function()
		baseAtt.WorldCFrame = feetAtt.WorldCFrame - Vector3.new(0, 1, 0)
	end)
	local function pillarBeam(props)
		local b = clock:beam(baseAtt, topAtt, props)
		FxTextures.apply(b, "band")
		b.TextureMode = Enum.TextureMode.Stretch
		b.TextureLength = 1
		return b
	end
	local pillar = pillarBeam({ FaceCamera = true, LightEmission = 0.55, Brightness = 2, Color = ColorSequence.new(PAL.gold), ZOffset = 0.3, Width0 = 0, Width1 = 0 })
	local core = pillarBeam({ FaceCamera = true, LightEmission = 1, Brightness = 3, Color = ColorSequence.new(PAL.white), ZOffset = 0.6, Width0 = 0, Width1 = 0 })
	clock:span(0.05, 0.75, function(_, t)
		local w = if t < 0.15 then P.pillarWidth * FxClock.outCubic((t - 0.05) / 0.1) else lerp(P.pillarWidth, 1.5, smooth(0.15, 0.75, t))
		local fade = smooth(0.3, 0.75, t)
		pillar.Width0, pillar.Width1 = w, w * 0.7
		pillar.Transparency = NumberSequence.new(0.15 + 0.85 * fade)
		local wc = w * 0.35 * (1 - smooth(0.15, 0.45, t))
		core.Width0, core.Width1 = wc, wc * 0.7
		core.Transparency = NumberSequence.new(0.1 + 0.9 * smooth(0.12, 0.45, t))
		if t >= 0.75 then
			pillar.Enabled = false
			core.Enabled = false
		end
	end)

	-- 4 burst stars
	local stars = clock:emitter(feetAtt, {
		Name = "BurstStars",
		EmissionDirection = Enum.NormalId.Top,
		Lifetime = NumberRange.new(0.7, 1.1),
		Speed = NumberRange.new(18, 32),
		SpreadAngle = Vector2.new(22, 22),
		Drag = 2.2,
		Acceleration = Vector3.new(0, -10, 0),
		RotSpeed = NumberRange.new(-200, 200),
		Size = FxClock.ns({ { 0, 0.9, 0.2 }, { 0.5, 0.7 }, { 1, 0 } }),
		Transparency = FxClock.ns({ { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }),
		Color = FxClock.cs({ { 0, PAL.pale }, { 0.3, PAL.gold }, { 1, PAL.amber } }),
		LightEmission = 0.7, -- at 1 / Brightness 3 the stars read white on the daylight floor
		Brightness = 1.5,
		ZOffset = 0.8,
	})
	FxTextures.apply(stars, "star")
	clock:at(0.08, function()
		stars:Emit(P.burstCount)
	end)

	-- 5 risers off a ring at the feet
	local function sustainRate(t)
		return smooth(0.25, 0.45, t) * (1 - smooth(2.55, 2.85, t))
	end
	local risers = clock:emitter(disc, {
		Name = "Risers",
		EmissionDirection = Enum.NormalId.Top,
		Shape = Enum.ParticleEmitterShape.Box, -- Disc emitted outward, so streaks flew sideways
		Lifetime = NumberRange.new(0.9, 1.3),
		Speed = NumberRange.new(5, 9),
		Drag = 0.5,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Rotation = NumberRange.new(90), -- texture 17581858560 is long on X; at 0 every riser lay flat (measured), 90 stands it on the velocity
		Squash = FxClock.ns({ { 0, 1.5 }, { 1, 1.5 } }),
		Size = FxClock.ns({ { 0, 0.3 }, { 0.2, 0.7 }, { 1, 0 } }),
		Transparency = FxClock.ns({ { 0, 1 }, { 0.15, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
		Color = FxClock.cs({ { 0, PAL.pale }, { 0.4, PAL.gold }, { 1, PAL.amber } }),
		LightEmission = 1, -- black-backed texture, below 1 its black shows as grey bars (measured)
		Brightness = 1.5,
		ZOffset = 0.4,
	})
	FxTextures.apply(risers, "streak")
	clock:stream(risers, 0.25, 2.85, function(t)
		return P.riserRate * sustainRate(t)
	end)

	-- 6 glow column
	local glowDisc = clock:part({ Name = "GlowDisc", Size = Vector3.new(3.4, 0.2, 3.4) })
	clock:every(function()
		glowDisc.CFrame = CFrame.new(feet + Vector3.new(0, 1.8, 0)) -- above the floor so the soft glows are not cut by it
	end)
	local glows = clock:emitter(glowDisc, {
		Name = "GlowColumn",
		EmissionDirection = Enum.NormalId.Top,
		Shape = Enum.ParticleEmitterShape.Box,
		Lifetime = NumberRange.new(0.9, 1.2),
		Speed = NumberRange.new(2, 3),
		Size = FxClock.ns({ { 0, 2.4 }, { 1, 3.6 } }),
		Transparency = FxClock.ns({ { 0, 1 }, { 0.3, 0.75 }, { 1, 1 } }),
		Color = ColorSequence.new(PAL.gold),
		LightEmission = 0.6,
		Brightness = 1.5,
		ZOffset = -1,
	})
	FxTextures.apply(glows, "glow")
	clock:stream(glows, 0.25, 2.85, function(t)
		return P.glowRate * sustainRate(t)
	end)

	-- 7 ground circle with a dark ring under it
	local circle = clock:ribbon(segs, { LightEmission = 0.8, Brightness = 2.5, ZOffset = 0.2 })
	local darkCircle = clock:ribbon(segs, { LightEmission = 0, Brightness = 1, ZOffset = -0.2 })
	clock:span(0.2, 3.3, function(_, t)
		local r = if t < 2.8 then lerp(2.2, P.circleR, FxClock.outCubic(math.clamp((t - 0.2) / 0.25, 0, 1))) else lerp(P.circleR, P.circleR * 1.2, smooth(2.8, 3.3, t))
		local fadeIn, fadeOut = smooth(0.2, 0.4, t), smooth(2.8, 3.3, t)
		local pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2 * 1.1)
		local a = 1 - fadeIn * (1 - fadeOut) * (0.75 - 0.2 * pulse)
		local aDark = 1 - fadeIn * (1 - fadeOut) * 0.5
		circle.update(function(j)
			return flatJoint(j, r, 0.45, a, PAL.gold, 0.06)
		end)
		darkCircle.update(function(j)
			return flatJoint(j, r, 0.95, aDark, PAL.dark, 0.05)
		end)
		if t >= 3.3 then
			circle.hide()
			darkCircle.hide()
		end
	end)

	-- 8 light
	local light = clock:light(chestAtt, { Range = P.light.range, Color = C(255, 205, 110) })
	clock:span(0, 3.3, function(_, t)
		local b
		if t < 0.06 then
			b = P.light.peak * t / 0.06
		elseif t < 0.5 then
			b = lerp(P.light.peak, P.light.sustain, smooth(0.06, 0.5, t))
		else
			b = P.light.sustain * (1 + 0.15 * math.sin(t * math.pi * 2 * 1.1)) * (1 - smooth(2.8, 3.3, t))
		end
		light.Brightness = b
	end)

	if opts.noPlay then
		return clock
	end
	return clock:play()
end

return LevelUpAura
