--!nonstrict
-- void_pillar: a sky-high energy pillar that slams down on a point and holds (ultimate, boss beam, objective strike).
-- Built from a frame-by-frame reading of a reference clip of a similar effect (roblox-feel-audio-vfx section 3f):
-- timing and layer structure only; every shape is made here from Beams, particles and public textures (fx_textures).
-- Needs fx_clock, fx_textures and fx_kit.
-- VoidPillar.play(cframe, { hue, width, height, hold, timeScale, reducedMotion, seed }?) -> clock. Client only.
-- Ran in Studio 0.748 Play on 2026-11-18 (desktop view and the Samsung Galaxy A06 Device Simulator preset); not
-- checked in a published game or on a real phone; frame cost not measured. Peak live beams 113-118 (two runs).
-- The strike is one screen-wide flash (a ColorCorrection brightness of 0.7 for one frame; 0.12 with reducedMotion).
--
-- Beats (clock seconds at timeScale 1, hold 4.5):
--   0.00  gather: a floor glow grows, a hair-thin line flickers where the pillar will be, sparks rise
--   0.30  strike: 2-frame white-out, the pillar drops from the sky to the floor in 0.05 s at 1.7x width
--   0.36  sustain: dark core, hot edge band, sheath with a rising scroll, electric skin; floor disc, shock rings
--         every 0.42 s, flickering rays, floor mist and shards; dark and bright sashes spiral up around the base;
--         lightning re-rolls every 0.08 s; a horizontal lens streak flickers; grey smoke climbs behind
--   tRel  collapse: the pillar thins to a line in 0.3 s, one last ring, the grade and the smoke clear
local Lighting = game:GetService("Lighting")
local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)
local Kit = require(script.Parent.fx_kit)

local VoidPillar = {}
VoidPillar.CAPTURE_TIMES = { 0.26, 0.31, 0.34, 0.5, 0.7, 1.0, 1.5, 3.0, 4.0, 4.9, 5.1, 5.4 }

local TAU = math.pi * 2
local UP = Vector3.yAxis
local smooth, keys = FxClock.smooth, Kit.keys

function VoidPillar.play(cf: CFrame, opts)
	opts = opts or {}
	local W: number = opts.width or 3.2 -- half-width of the pillar core
	local H: number = opts.height or 80
	local hold: number = opts.hold or 4.5
	local speed: number = opts.timeScale or 1
	local calm: boolean = opts.reducedMotion == true
	local P = Kit.palette(opts.hue or 0.76)
	local VOID = P.dark:Lerp(Color3.new(0, 0, 0), 0.55)
	local tHit = 0.30
	local tRel = tHit + hold
	local tEnd = tRel + 0.9
	local rng = Random.new(opts.seed or 7)

	local c = FxClock.new("VoidPillar", (tEnd + 0.05) / speed)
	local function every(fn)
		c:every(function(t, dt)
			fn(t * speed, dt * speed)
		end)
	end
	local C = cf.Position
	local cam = workspace.CurrentCamera
	local function right(): Vector3
		local r = cam.CFrame.RightVector * Vector3.new(1, 0, 1)
		return if r.Magnitude < 1e-3 then Vector3.xAxis else r.Unit
	end
	local function toCam(): Vector3
		local v = (cam.CFrame.Position - C) * Vector3.new(1, 0, 1)
		return if v.Magnitude < 1e-3 then Vector3.zAxis else v.Unit
	end

	-- on(t): 0 before the strike, 1 through the sustain, 0 after the collapse
	local function on(t: number): number
		return smooth(tHit, tHit + 0.04, t) * (1 - smooth(tRel + 0.25, tRel + 0.5, t))
	end
	local widthK = keys({ { tHit, 0 }, { tHit + 0.04, 1.7 }, { tHit + 0.22, 1 }, { tRel, 1 }, { tRel + 0.3, 0.1 }, { tRel + 0.5, 0 } })

	------------------------------------------------------------------------------------------------------
	-- Screen grade: white-out on the strike, then a violet tint while the pillar holds
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "VoidPillarGrade"
	grade.Parent = Lighting
	c:onCleanup(function()
		grade:Destroy()
	end)
	local flashK = keys({ { tHit - 0.01, 0 }, { tHit + 0.01, if calm then 0.12 else 0.7 }, { tHit + 0.07, if calm then 0.1 else 0.4 }, { tHit + 0.2, 0.06 }, { tHit + 0.5, 0 } })
	every(function(t)
		local g = on(t)
		grade.Brightness = flashK(t)
		grade.Contrast = 0.14 * g
		grade.Saturation = 0.1 * g
		grade.TintColor = Color3.new(1, 1, 1):Lerp(P.light:Lerp(P.body, 0.25), 0.55 * g)
	end)

	------------------------------------------------------------------------------------------------------
	-- Pillar: camera-facing vertical beams. offset: sideways shift in core widths (camera right).
	local pillar = {}
	local function layer(name: string, offset: number, width: number, props, slot: string?, texLen: number?)
		local a0, a1 = c:attachment(CFrame.new(C)), c:attachment(CFrame.new(C + UP * H))
		props.FaceCamera = true
		props.Segments = 1
		props.Enabled = false
		if slot then
			props.TextureMode = Enum.TextureMode.Wrap
			props.TextureLength = texLen or 0.3
		end
		local b = c:beam(a0, a1, props)
		if slot then
			FxTextures.apply(b, slot)
		end
		pillar[name] = { a0 = a0, a1 = a1, beam = b, offset = offset, width = width }
		return pillar[name]
	end
	layer("sheath", 0, 5.2, { LightEmission = 0.7, Color = ColorSequence.new(P.body, P.deep), TextureSpeed = 1.4, ZOffset = -0.6 }, "smoke", 14)
	layer("glow", 0, 3.3, { LightEmission = 1, Color = ColorSequence.new(P.light, P.body), ZOffset = -0.4 }, "band", 0.07)
	layer("core", -0.12, 1.9, { LightEmission = 0, Color = ColorSequence.new(VOID), ZOffset = -0.2 }, "band", 0.07)
	layer("scroll", -0.12, 1.5, { LightEmission = 0.4, Color = ColorSequence.new(P.deep, VOID), TextureSpeed = 3.2, ZOffset = -0.1 }, "smoke", 9)
	layer("hot", 0.78, 0.62, { LightEmission = 1, Color = ColorSequence.new(P.white), ZOffset = 0 }, "band", 0.07)
	layer("hotThin", -1.02, 0.16, { LightEmission = 1, Color = ColorSequence.new(P.light), ZOffset = 0 })
	layer("void", -0.12, 1.05, { LightEmission = 0, Color = ColorSequence.new(VOID), ZOffset = -0.15 })
	layer("skin", 0.25, 3.4, { LightEmission = 1, Color = ColorSequence.new(P.light), TextureSpeed = 2.6, ZOffset = 0.1 }, "electric", 27)
	layer("skin2", -0.35, 2.6, { LightEmission = 1, Color = ColorSequence.new(P.body), TextureSpeed = 4.1, ZOffset = 0.1 }, "electric", 17)
	local alphaOf = { sheath = 0.6, glow = 0.2, core = 0.04, void = 0.08, scroll = 0.3, hot = 0, hotThin = 0.15, skin = 0.68, skin2 = 0.72 }
	-- gather line
	local lineA, lineB = c:attachment(CFrame.new(C)), c:attachment(CFrame.new(C + UP * H))
	local line = c:beam(lineA, lineB, { FaceCamera = true, LightEmission = 1, Segments = 1, Width0 = 0.07, Width1 = 0.07, Color = ColorSequence.new(P.light), Enabled = false })
	every(function(t)
		local g = on(t)
		local wk = widthK(t) * (1 + (if calm then 0.02 else 0.06) * Kit.noise(1, t * 7))
		local r = right()
		-- the strike: the bottom end travels from the sky to the floor
		local drop = 1 - smooth(tHit, tHit + 0.05, t)
		for name, L in pillar do
			L.beam.Enabled = g > 0.01 and wk > 0.01
			if L.beam.Enabled then
				local base = C + r * (L.offset * W * wk)
				L.a0.WorldPosition = base + UP * (H * drop)
				L.a1.WorldPosition = base + UP * H
				local w = L.width * W * wk
				L.beam.Width0 = w
				L.beam.Width1 = w
				local a = alphaOf[name]
				if (name == "skin" or name == "skin2") and not calm then
					a = math.clamp(a + 0.25 * Kit.noise(if name == "skin" then 5 else 15, t * 16), 0.3, 1)
				elseif name == "hot" then
					a = math.clamp(0.1 + 0.12 * Kit.noise(6, t * 13), 0, 1)
				end
				L.beam.Transparency = NumberSequence.new(1 - (1 - a) * g)
			end
		end
		local pre = smooth(0.03, 0.12, t) * (1 - smooth(tHit - 0.01, tHit + 0.02, t))
		local post = smooth(tRel + 0.25, tRel + 0.35, t) * (1 - smooth(tRel + 0.5, tRel + 0.75, t))
		local lv = math.max(pre * (0.55 + 0.45 * Kit.noise(2, t * 30)), post)
		line.Enabled = lv > 0.05
		if line.Enabled then
			line.Transparency = NumberSequence.new(1 - lv * 0.9)
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Floor: hot disc, wide glow, shock rings, rays
	local disc = Kit.floorBlob(c, { ZOffset = 0.05 })
	local wide = Kit.floorBlob(c)
	local discR = keys({ { 0, 0 }, { 0.28, W * 1.6 }, { tHit + 0.05, W * 5.5 }, { tHit + 0.3, W * 3.6 }, { tRel, W * 3.6 }, { tRel + 0.5, W * 0.6 }, { tRel + 0.7, 0 } })
	every(function(t)
		local g = math.max(on(t), smooth(0, 0.25, t) * (1 - smooth(tRel, tRel + 0.7, t)) * 0.6)
		local pulse = 1 + 0.08 * math.sin(t * TAU * 2.4)
		disc.set(C + UP * 0.12, discR(t) * pulse, 1 - 0.95 * g, P.white:Lerp(P.light, 0.4))
		wide.set(C + UP * 0.08, discR(t) * 2.6, 1 - 0.24 * g, P.body)
	end)

	local RSEG = 14
	local rings = {}
	for k = 1, 3 do
		rings[k] = { rib = c:ribbon(RSEG, { LightEmission = 1, Segments = 4 }), t0 = -10 }
	end
	local ringPeriod = if calm then 0.84 else 0.42
	local nextRing, ringIdx = tHit, 0
	every(function(t)
		if t >= nextRing and t < tRel + 0.1 then
			ringIdx += 1
			local rg = rings[(ringIdx - 1) % 3 + 1]
			rg.t0 = t
			rg.big = ringIdx == 1 or t > tRel - 0.05
			nextRing = if t > tRel - ringPeriod and t < tRel then tRel else t + ringPeriod
		end
		for _, rg in rings do
			local life = if rg.big then 0.75 else 0.62
			local u = (t - rg.t0) / life
			if u >= 0 and u <= 1 then
				local e = 1 - (1 - u) ^ 2.6
				local rad = W * (1.2 + (if rg.big then 11 else 7.5) * e)
				local wd = W * (if rg.big then 1.5 else 0.9) * (1 - u * 0.75)
				local al = 0.15 + 0.85 * u * u
				rg.rib.update(function(j: number)
					local a = (j - 1) / RSEG * TAU
					local radial = Vector3.new(math.cos(a), 0, math.sin(a))
					local tan = Vector3.new(-math.sin(a), 0, math.cos(a))
					return { cf = CFrame.fromMatrix(C + radial * rad + UP * 0.16, tan, radial), width = wd, alpha = al, color = P.light:Lerp(P.white, 1 - u) }
				end)
			else
				rg.rib.hide()
			end
		end
	end)

	local RAYS = 11
	local rays = {}
	for i = 1, RAYS do
		local a = (i + rng:NextNumber(-0.3, 0.3)) / RAYS * TAU
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local tan = Vector3.new(-math.sin(a), 0, math.cos(a))
		local a0 = c:attachment(Kit.oriented(C + dir * W * 0.8 + UP * 0.14, dir, tan))
		local a1 = c:attachment(Kit.oriented(C + dir * W * 5 + UP * 0.14, dir, tan))
		local b = c:beam(a0, a1, { LightEmission = 1, Segments = 5, Width0 = W * 0.42, Width1 = 0.04, Color = ColorSequence.new(P.white, P.body), Enabled = false })
		rays[i] = { a1 = a1, beam = b, dir = dir, tan = tan }
	end
	every(function(t)
		local g = on(t)
		for i, ry in rays do
			local n = Kit.noise(30 + i, t * (if calm then 2 else 9))
			local len = W * (5.5 + 3.5 * n) * (1 + 1.2 * (1 - smooth(tHit, tHit + 0.3, t)))
			local v = g * math.clamp(0.55 + 0.6 * n, 0, 1)
			ry.beam.Enabled = v > 0.05
			if ry.beam.Enabled then
				ry.a1.WorldCFrame = Kit.oriented(C + ry.dir * len + UP * 0.14, ry.dir, ry.tan)
				ry.beam.Transparency = Kit.fadeSeq({ { 0, 0.1 }, { 0.6, 0.6 }, { 1, 1 } }, v)
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Sashes: broad ribbons that spiral up around the base, re-forming all the time. Dark, bright and striped.
	local SLOTS = if calm then 4 else 7
	local SSEG = 8
	local sashes = {}
	for s = 1, SLOTS do
		local kind = if s % 3 == 0 then "bright" elseif s % 3 == 1 then "dark" else "striped" -- bright = glowing violet
		local props = { LightEmission = if kind == "bright" then 1 else 0, Segments = 5 }
		if kind == "striped" then
			props.TextureMode = Enum.TextureMode.Wrap
			props.TextureLength = W * 5
			props.LightEmission = 0.3
		end
		local rib = c:ribbon(SSEG, props)
		if kind == "striped" then
			for _, b in rib.beams do
				FxTextures.apply(b, "smoke")
			end
		end
		sashes[s] = { rib = rib, kind = kind, t0 = -10, life = 0 }
	end
	local function respawn(sh, t: number, first: boolean)
		sh.t0 = t
		sh.life = rng:NextNumber(0.55, 1.05) * (if calm then 1.6 else 1)
		sh.r = W * rng:NextNumber(1.9, 4.6)
		sh.y0 = rng:NextNumber(0.4, 5) * W * 0.6
		sh.rise = rng:NextNumber(2, 9) * W * 0.4
		sh.tilt = CFrame.Angles(math.rad(rng:NextNumber(-40, 40)), rng:NextNumber(0, TAU), math.rad(rng:NextNumber(-40, 40)))
		sh.a0 = rng:NextNumber(0, TAU)
		sh.w = rng:NextNumber(4.5, 8) * (if rng:NextNumber() < 0.5 then -1 else 1) * (if calm then 0.5 else 1)
		sh.arc = math.rad(rng:NextNumber(140, 250))
		sh.width = W * rng:NextNumber(0.8, 1.7) * (if first then 1.3 else 1) * (if sh.kind == "dark" then 0.75 else 1)
		sh.twist = rng:NextNumber(-0.6, 0.6)
	end
	every(function(t)
		local live = t >= tHit and t < tRel
		for s, sh in sashes do
			local u = (t - sh.t0) / math.max(sh.life, 1e-3)
			if (u > 1 or sh.t0 < 0) and live then
				respawn(sh, t + (if sh.t0 < 0 then (s - 1) * 0.05 else 0), sh.t0 < 0)
				u = (t - sh.t0) / sh.life
			end
			if u >= 0 and u <= 1 then
				local env = math.sin(math.pi * u) ^ 0.6
				local sign = if sh.w < 0 then -1 else 1
				local head = sh.a0 + sh.w * (t - sh.t0)
				local col0 = if sh.kind == "bright" then P.body elseif sh.kind == "dark" then VOID else P.deep
				local col1 = if sh.kind == "bright" then P.deep else if sh.kind == "dark" then P.dark else VOID
				sh.rib.update(function(j: number)
					local q = (j - 1) / SSEG
					local a = head - sign * q * sh.arc
					local rad = sh.r * (1 + 0.3 * q)
					local radial = sh.tilt:VectorToWorldSpace(Vector3.new(math.cos(a), 0, math.sin(a)))
					-- joints run head -> tail, so the X axis points against the travel
					local tan = sh.tilt:VectorToWorldSpace(Vector3.new(-math.sin(a), 0, math.cos(a))) * -sign
					local tw = sh.twist + q * 0.8
					local wa = sh.tilt.UpVector * math.cos(tw) + radial * math.sin(tw)
					local pos = C + radial * rad + UP * (sh.y0 + sh.rise * (u - q * 0.35))
					return {
						cf = CFrame.fromMatrix(pos, tan, wa),
						width = sh.width * math.sin(math.pi * (0.06 + 0.94 * q)) ^ 0.7,
						alpha = 1 - env * (if sh.kind == "bright" then 0.6 else 0.95) * (1 - 0.5 * q),
						color = col0:Lerp(col1, q),
					}
				end)
			else
				sh.rib.hide()
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Lightning: short electric arcs around the base, re-rolled every 0.08 s
	local arcs = {}
	for i = 1, (if calm then 2 else 5) do
		local a0, a1 = c:attachment(), c:attachment()
		local b = c:beam(a0, a1, {
			FaceCamera = true, LightEmission = 1, Segments = 6, Width0 = W * 0.7, Width1 = W * 0.7,
			Color = ColorSequence.new(P.white, P.light), TextureMode = Enum.TextureMode.Stretch, TextureLength = 1, Enabled = false,
		})
		FxTextures.apply(b, "electric")
		arcs[i] = { a0 = a0, a1 = a1, beam = b }
	end
	local arcTick = -1
	every(function(t)
		local tick = math.floor(t / (if calm then 0.3 else 0.08))
		if tick == arcTick then
			return
		end
		arcTick = tick
		local g = on(t)
		for _, ar in arcs do
			local show = g > 0.5 and rng:NextNumber() < 0.6
			ar.beam.Enabled = show
			if show then
				local a = rng:NextNumber(0, TAU)
				local p0 = C + Vector3.new(math.cos(a), 0, math.sin(a)) * W * rng:NextNumber(0.6, 1.6) + UP * rng:NextNumber(0.3, 9)
				local p1 = p0 + Vector3.new(math.cos(a), 0, math.sin(a)) * W * rng:NextNumber(1.2, 3.4) + UP * rng:NextNumber(-3, 4)
				ar.a0.WorldCFrame = CFrame.lookAt(p0, p1) * CFrame.Angles(0, math.rad(90), 0)
				ar.a1.WorldCFrame = CFrame.lookAt(p1, p0) * CFrame.Angles(0, math.rad(-90), 0)
				ar.beam.CurveSize0 = rng:NextNumber(-2, 2)
				ar.beam.CurveSize1 = rng:NextNumber(-2, 2)
				ar.beam.Width0 = W * rng:NextNumber(0.4, 0.9)
				ar.beam.Width1 = ar.beam.Width0
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Lens streak: a thin horizontal flare across the pillar, with a soft core
	local fA, fB = c:attachment(), c:attachment()
	local flare = c:beam(fA, fB, {
		FaceCamera = true, LightEmission = 1, Segments = 10, Color = ColorSequence.new(P.light), Enabled = false,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.5), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.6, 0.5), NumberSequenceKeypoint.new(1, 1) }),
	})
	local flareCore = Kit.blob(c)
	local flareK = keys({ { tHit, 0 }, { tHit + 0.03, 2.4 }, { tHit + 0.3, 1 }, { tRel, 1 }, { tRel + 0.3, 0 } })
	every(function(t)
		local k = flareK(t) * (if calm then 1 else (0.75 + 0.35 * Kit.noise(9, t * 12)))
		flare.Enabled = k > 0.05
		if flare.Enabled then
			local p = C + UP * W * 3.1 + toCam() * W
			local r = cam.CFrame.RightVector
			local half = W * 6.5 * k
			fA.WorldPosition = p - r * half
			fB.WorldPosition = p + r * half
			flare.Width0 = 0.16 * W * math.min(k, 1.5)
			flare.Width1 = flare.Width0
			flareCore.set(p, W * 1.3 * math.min(k, 1.6), 0.45, P.white)
		else
			flareCore.hide()
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Particles: floor mist (radial), dark shards, rising sparks, grey smoke climbing behind the pillar
	local mistHost = c:part({ Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.new(C + UP * 0.6) })
	local mist = c:emitter(mistHost, {
		Color = ColorSequence.new(P.body, P.deep),
		LightEmission = 0.35,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, W * 0.8), NumberSequenceKeypoint.new(1, W * 2.6) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.7, 1.2),
		Speed = NumberRange.new(W * 5, W * 9),
		EmissionDirection = Enum.NormalId.Front,
		SpreadAngle = Vector2.new(6, 3),
		Drag = 2.2,
		RotSpeed = NumberRange.new(-40, 40),
	})
	FxTextures.apply(mist, "smoke")
	c:stream(mist, tHit / speed, tRel / speed, function(tc)
		return (if tc * speed < tHit + 0.25 then 70 else 22) * speed
	end, function()
		mistHost.CFrame = CFrame.new(C + UP * 0.6) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0)
	end)

	local shardHost = c:part({ Size = Vector3.new(W * 3, 0.2, W * 3), CFrame = CFrame.new(C + UP * 0.3) })
	local shards = c:emitter(shardHost, {
		Color = ColorSequence.new(VOID),
		LightEmission = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.34), NumberSequenceKeypoint.new(1, 0.1) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(14, 30),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(55, 55),
		Acceleration = Vector3.new(0, -46, 0),
		Squash = NumberSequence.new(0.6),
	})
	FxTextures.apply(shards, "glow")
	c:stream(shards, tHit / speed, tRel / speed, function(tc)
		return (if tc * speed < tHit + 0.2 then 160 else 26) * speed
	end)

	local sparkHost = c:part({ Size = Vector3.new(W * 5, 0.2, W * 5), CFrame = CFrame.new(C + UP * 0.4) })
	local sparks = c:emitter(sparkHost, {
		Color = ColorSequence.new(P.white, P.body),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new(0),
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(10, 26),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(10, 10),
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Squash = NumberSequence.new(1.6),
	})
	FxTextures.apply(sparks, "streak")
	c:stream(sparks, 0.05 / speed, tRel / speed, function(tc)
		local t = tc * speed
		return (if t < tHit then 14 else 34) * speed
	end)

	local back = toCam() * -W * 2.6
	local smokeHost = c:part({ Size = Vector3.new(W * 9, W * 3, 1), CFrame = CFrame.lookAt(C + back + UP * W * 4.5, C + back + UP * W * 4.5 + toCam()) })
	local smoke = c:emitter(smokeHost, {
		Color = ColorSequence.new(Color3.fromRGB(205, 202, 214), Color3.fromRGB(128, 122, 146)),
		LightEmission = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, W * 1.6), NumberSequenceKeypoint.new(1, W * 4.2) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.62), NumberSequenceKeypoint.new(0.7, 0.82), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(1.4, 2.2),
		Speed = NumberRange.new(W * 3, W * 7),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(24, 6),
		RotSpeed = NumberRange.new(-30, 30),
		Drag = 0.6,
		ZOffset = -4,
	})
	FxTextures.apply(smoke, "smoke")
	c:stream(smoke, (tHit + 0.03) / speed, tRel / speed, function(tc)
		return (if tc * speed < tHit + 0.3 then 40 else 11) * speed
	end)

	------------------------------------------------------------------------------------------------------
	-- Light
	local lightHost = c:part({ Size = Vector3.one * 0.2, CFrame = CFrame.new(C + UP * W * 2) })
	local light = c:light(lightHost, { Color = P.body, Range = math.min(W * 22, 60) })
	local lightK = keys({ { 0, 0 }, { 0.28, 1.2 }, { tHit + 0.02, 9 }, { tHit + 0.3, 3.4 }, { tRel, 3.4 }, { tRel + 0.5, 0 } })
	every(function(t)
		light.Brightness = lightK(t) * (1 + (if calm then 0 else 0.12 * Kit.noise(12, t * 10)))
	end)

	c:play()
	return c
end

return VoidPillar
