--!nonstrict
-- formation_seal: a glowing polygon seal on the floor with a floating orb (spell cast, objective marker, summon).
-- Built from a frame-by-frame reading of a reference clip of a similar effect (roblox-feel-audio-vfx section 3f):
-- timing and layer structure only; every shape is made here from Beams, two Parts and public textures (fx_textures).
-- Needs fx_clock, fx_textures and fx_kit.
-- Formation.play(cframe, { sides = 3..6, hue, radius, hold, timeScale, reducedMotion, seed }?) -> clock. Client only.
-- Ran in Studio 0.748 Play on 2026-11-18 (desktop view and the Samsung Galaxy A06 Device Simulator preset); not
-- checked in a published game or on a real phone; frame cost not measured. Peak live beams 63 / 79 / 95 / 111 for
-- 3 / 4 / 5 / 6 sides.
--
-- Beats (clock seconds at timeScale 1, hold 1.2):
--   0.00  seeds: a small 4-point glint with a thin vertical ray pops at each runner's start (inner circle)
--   0.25  orbit: one crescent per corner circles the centre on the inner circle, thin threads with dots trail them
--   0.70  converge: the crescents spiral in and climb into one spike; a flare opens at its top (0.92)
--   1.02  birth: a wide soft flash, the orb grows out of it (overshoot, settle by 1.30)
--   1.22  descent: one blade per corner falls from the orb to its corner and lands with a glint (1.50)
--   1.52  wind-up: the crescents run one full turn on the outer circle and stop on their corners (2.00)
--   2.00  stars: the corner glints swell (the anticipation frame)
--   2.10  snap: the edges draw corner to corner in about 4 frames, corner pillars and the walls shoot up
--   2.30  sustain (hold): outline, deep fill with drifting cloud, flame walls on the edges, sparkles, orb bobbing
--   tRel  release: the orb sinks and shrinks, the walls fall, the outline dims
--   +0.9  afterglow: a faint outline fades; clean at tRel + 1.7
local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)
local Kit = require(script.Parent.fx_kit)

local Formation = {}
Formation.CAPTURE_TIMES = { 0.05, 0.5, 0.95, 1.08, 1.2, 1.4, 1.8, 2.05, 2.16, 2.8, 3.8, 4.7 }

local TAU = math.pi * 2
local UP = Vector3.yAxis
local smooth, keys = FxClock.smooth, Kit.keys

function Formation.play(cf: CFrame, opts)
	opts = opts or {}
	local n: number = opts.sides or 3
	local R: number = opts.radius or 6
	local hold: number = opts.hold or 1.2
	local speed: number = opts.timeScale or 1
	local calm: boolean = opts.reducedMotion == true
	local P = Kit.palette(opts.hue or 0.6)
	local k = R / 6 -- size scale for widths
	local tRel = 2.3 + hold
	local tEnd = tRel + 1.7

	local c = FxClock.new("Formation", (tEnd + 0.05) / speed)
	local function every(fn)
		c:every(function(t, dt)
			fn(t * speed, dt * speed)
		end)
	end
	local C = cf.Position
	local a0 = -math.pi / 2 -- the first corner points away from a camera on +Z
	local function dirAt(a: number): Vector3
		return cf:VectorToWorldSpace(Vector3.new(math.cos(a), 0, math.sin(a)))
	end
	local corner: { Vector3 } = {}
	for i = 1, n do
		corner[i] = C + dirAt(a0 + (i - 1) * TAU / n) * R
	end
	local H = R * 1.5 -- orb height
	local D = R * 0.74 -- orb diameter
	local r1 = R * 0.42 -- inner circle of the first orbit
	local FLOOR = 0.28 * k

	-- Orb position (bob, then the sink at release)
	local function orbAt(t: number): Vector3
		local sink = smooth(tRel, tRel + 0.8, t)
		local y = H + (R * 0.55 - H) * sink + math.sin(t * TAU * 0.55) * R * 0.035 * (1 - sink)
		return C + UP * y
	end

	-- Runner paths: one per corner. tau is clock time.
	local function path(i: number, tau: number): Vector3
		local base = a0 + (i - 1) * TAU / n
		if tau < 0.70 then
			local a = base + math.rad(60) + (math.max(tau, 0.22) - 0.25) * TAU * 1.5
			return C + dirAt(a) * r1 + UP * FLOOR
		elseif tau < 1.02 then
			local u = (tau - 0.70) / 0.32
			local a = base + math.rad(60) + 0.45 * TAU * 1.5 + u * TAU * 0.5
			return C + dirAt(a) * (r1 * (1 - u) ^ 1.6) + UP * (FLOOR + (H - FLOOR) * u ^ 1.25)
		elseif tau < 1.22 then
			return C + UP * H
		elseif tau < 1.52 then
			local u = (tau - 1.22) / 0.30
			local e = u * u * (3 - 2 * u)
			local p = (C + UP * H):Lerp(corner[i] + UP * FLOOR, e)
			return p + dirAt(base) * math.sin(math.pi * u) * R * 0.2
		elseif tau < 2.02 then
			local u = (tau - 1.52) / 0.50
			local e = 1 - (1 - u) ^ 2.4
			return C + dirAt(base + e * TAU) * R + UP * FLOOR
		end
		return corner[i] + UP * FLOOR
	end
	local function frameAt(i: number, tau: number): CFrame
		local p = path(i, tau)
		local tan = path(i, tau + 0.004) - p
		tan = if tan.Magnitude < 1e-4 then UP else tan.Unit
		local out = (p - C) * Vector3.new(1, 0, 1)
		out = if out.Magnitude < 1e-3 then dirAt(a0 + (i - 1) * TAU / n) else out.Unit
		local y = out - tan * out:Dot(tan)
		y = if y.Magnitude < 1e-3 then UP else y.Unit
		return CFrame.fromMatrix(p, tan, y)
	end

	------------------------------------------------------------------------------------------------------
	-- Runners: a crescent ribbon (white core over a wider body-colour glow), a head glint, threads with dots
	local runnerVis = function(t: number): number
		if calm then
			return 0
		end
		return smooth(0.25, 0.32, t) * (1 - smooth(0.97, 1.03, t)) + smooth(1.22, 1.26, t) * (1 - smooth(1.97, 2.05, t))
	end
	local runnerW = keys({ { 0.25, 0.95 }, { 0.70, 0.95 }, { 0.95, 0.6 }, { 1.22, 0.75 }, { 1.52, 0.9 }, { 1.7, 1.25 }, { 2.0, 0.9 } })
	-- lag: how far behind the head the tail is (seconds of travel); kept so that one arc stays under about 100 degrees
	local runnerLag = keys({ { 0.25, 0.0 }, { 0.36, 0.17 }, { 0.70, 0.17 }, { 0.95, 0.2 }, { 1.22, 0.0 }, { 1.34, 0.14 }, { 1.52, 0.06 }, { 1.9, 0.095 }, { 2.02, 0.03 } })
	local runners = {}
	for i = 1, n do
		local function crescent(textured: boolean, z: number)
			local rib = c:ribbon(1, { FaceCamera = true, LightEmission = 1, Segments = 16, ZOffset = z, TextureMode = Enum.TextureMode.Stretch, TextureLength = 1 })
			if textured then
				FxTextures.apply(rib.beams[1], "glow")
			end
			return rib
		end
		local threadAtt = {}
		local threadBeams = {}
		local dots = {}
		for j = 1, 4 do
			threadAtt[j] = c:attachment()
			dots[j] = Kit.blob(c)
		end
		for j = 1, 3 do
			threadBeams[j] = c:beam(threadAtt[j], threadAtt[j + 1], {
				FaceCamera = true,
				LightEmission = 1,
				Segments = 1,
				Width0 = 0.05 * k,
				Width1 = 0.05 * k,
				Color = ColorSequence.new(P.light),
				Transparency = NumberSequence.new(0.45),
				Enabled = false,
			})
		end
		runners[i] = { glow = crescent(true, -0.05), core = crescent(true, 0), blade = crescent(false, 0.05), glint = Kit.glint(c, P.body), att = threadAtt, beams = threadBeams, dots = dots, off = {}, tick = -1 }
	end
	local rng = Random.new(opts.seed or 11)
	local glintSize = keys({
		{ 0.0, 0 }, { 0.05, 1.7 }, { 0.2, 1.3 }, { 0.3, 0.5 }, { 0.95, 0.5 }, { 1.0, 0 }, { 1.22, 0 }, { 1.26, 0.5 },
		{ 1.48, 0.5 }, { 1.52, 1.1 }, { 1.6, 0.65 }, { 1.97, 0.7 }, { 2.06, 2.5 }, { 2.13, 1.9 }, { 2.3, 0.75 },
		{ tRel, 0.6 }, { tRel + 0.9, 0.25 }, { tEnd - 0.2, 0 },
	})
	every(function(t)
		local vis = runnerVis(t)
		local w = runnerW(t) * k
		local lag = runnerLag(t)
		for i = 1, n do
			local rn = runners[i]
			if vis > 0.01 and lag > 0.005 then
				-- joint 1 = tail, joint 2 = head; the X axis of both is the direction of travel
				local tail, head = frameAt(i, t - lag), frameAt(i, t)
				local function draw(rib, w0: number, w1: number, alpha: number, c0: Color3, c1: Color3)
					rib.update(function(j: number)
						return { cf = if j == 1 then tail else head, width = if j == 1 then w0 else w1, alpha = 1 - (1 - alpha) * vis, color = if j == 1 then c0 else c1 }
					end)
				end
				draw(rn.glow, w * 2.8, w * 2.8, 0.25, P.body, P.body)
				draw(rn.core, w, w, 0, P.light, P.white)
				draw(rn.blade, 0, w * 0.2, 0, P.light, P.white)
			else
				rn.core.hide()
				rn.glow.hide()
				rn.blade.hide()
			end
			-- head glint: the seed, the runner's head, the landing, the anticipation star, the corner mark
			local gp = if calm and t < 2.0 then corner[i] + UP * FLOOR else path(i, t)
			local gs = glintSize(t) * k
			if calm and t > 0.3 and t < 1.97 then
				gs = 0.4 * k
			end
			local flick = 1 + 0.12 * Kit.noise(i, t * 9)
			rn.glint.set(gp, gs * flick, 0, if t < 0.3 or (t > 1.97 and t < 2.3) then 2.8 else 1.8)
			-- threads: a short jagged line with dots behind the head, re-rolled every 0.09 s
			local tick = math.floor(t / 0.09)
			if tick ~= rn.tick then
				rn.tick = tick
				for j = 1, 4 do
					rn.off[j] = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.2, 1.3), rng:NextNumber(-1, 1)) * R * 0.11
				end
			end
			local tv = vis * (if t < 1.0 then 1 else 0.8)
			for j = 1, 4 do
				local p = path(i, t - 0.03 - (j - 1) * 0.045) + rn.off[j]
				rn.att[j].WorldPosition = p
				rn.dots[j].set(p, 0.1 * k, 1 - tv * 0.9, P.white)
			end
			for j = 1, 3 do
				rn.beams[j].Enabled = tv > 0.05
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Apex flare, birth flash and halo
	local apex = Kit.glint(c, P.light)
	local apexSize = keys({ { 0.86, 0 }, { 0.94, 1.8 }, { 1.02, 3.2 }, { 1.1, 0 } })
	local flash = Kit.blob(c, { ZOffset = -0.3 })
	local flashR = keys({ { 1.0, 0 }, { 1.06, R * 2.3 }, { 1.14, R * 1.6 }, { 1.3, D * 0.95 }, { tRel, D * 0.95 }, { tRel + 0.8, D * 0.3 }, { tRel + 0.9, 0 } })
	local flashA = keys({ { 1.0, 1 }, { 1.04, 0.08 }, { 1.1, 0.25 }, { 1.3, 0.6 }, { tRel + 0.5, 0.6 }, { tRel + 0.9, 1 } })
	every(function(t)
		if not calm then
			apex.set(C + UP * H, apexSize(t) * k, 0, 2.2)
		end
		local op = orbAt(t)
		flash.set(op, flashR(t) * (1 + 0.03 * Kit.noise(3, t * 6)), flashA(t), if t < 1.16 then P.light else P.body)
	end)

	------------------------------------------------------------------------------------------------------
	-- Orb: three concentric balls (one centre from any angle) and three thin rings around it
	local Ball = Enum.PartType.Ball
	-- the centre is a soft camera-facing disc at the balls' centre (a hard white Neon ball read as a pasted-on dot)
	local orbCore = c:part({ Size = Vector3.one * 0.1, Transparency = 1 })
	local orbHot = Kit.blob(c, { ZOffset = 0.3 })
	local orbHotWide = Kit.blob(c, { ZOffset = 0.2 })
	local orbBody = c:part({ Shape = Ball, Material = Enum.Material.Neon, Color = P.body, Size = Vector3.one * 0.1, Transparency = 1 })
	local orbShell = c:part({ Shape = Ball, Material = Enum.Material.ForceField, Color = P.light, Size = Vector3.one * 0.1, Transparency = 1 })
	local orbScale = keys({ { 1.04, 0 }, { 1.16, 1.2 }, { 1.3, 1 }, { tRel, 1 }, { tRel + 0.7, 0.4 }, { tRel + 0.9, 0 } })
	local light = c:light(orbCore, { Color = P.body, Range = math.min(R * 3.4, 60) })
	local lightB = keys({ { 1.0, 0 }, { 1.06, 7 }, { 1.3, 1.8 }, { 2.1, 1.8 }, { 2.15, 5.5 }, { 2.5, 2.2 }, { tRel, 2.2 }, { tRel + 0.9, 0 } })
	local floorHost = c:part({ Size = Vector3.one * 0.2, CFrame = CFrame.new(C + UP * (R * 0.2)) })
	local floorLight = c:light(floorHost, { Color = P.body, Range = math.min(R * 2.6, 60) })
	local floorB = keys({ { 2.08, 0 }, { 2.15, 3.2 }, { 2.6, 1.3 }, { tRel + 0.8, 0.6 }, { tEnd, 0 } })
	local rings = {}
	local ringCol = { P.light, P.accentA, P.accentB }
	local ringRad = { 0.63, 0.7, 0.77, 0.2, 0.29 } -- of D; the last two are the swirl inside the orb
	for r = 1, 5 do
		ringCol[r] = ringCol[r] or P.white
		rings[r] = {
			rib = c:ribbon(2, { FaceCamera = true, LightEmission = 1, Segments = 10, ZOffset = if r > 3 then 0.25 else 0 }),
			normal = CFrame.fromOrientation(math.rad(25 + 30 * r), math.rad(70 * r), 0),
			w = (0.9 + 0.35 * r) * TAU * (if r % 2 == 0 then -1 else 1) * (if r > 3 then 1.8 else 1),
		}
	end
	every(function(t)
		local s = orbScale(t)
		local op = orbAt(t)
		for _, p in { orbCore, orbBody, orbShell } do
			p.Position = op
		end
		if s <= 0.01 then
			orbBody.Transparency, orbShell.Transparency = 1, 1
			orbHot.hide()
			orbHotWide.hide()
		else
			orbBody.Size = Vector3.one * D * 0.78 * s
			orbShell.Size = Vector3.one * D * s
			orbBody.Transparency, orbShell.Transparency = 0.6, 0
			local pulse = 1 + 0.06 * math.sin(t * TAU * 1.3)
			orbHot.set(op, D * 0.2 * s * pulse, 0, P.white)
			orbHotWide.set(op, D * 0.42 * s * pulse, 0.35, P.light)
		end
		light.Brightness = lightB(t)
		floorLight.Brightness = floorB(t)
		local flourish = 1 + 0.9 * smooth(1.55, 1.75, t) * (1 - smooth(1.8, 2.05, t))
		for r = 1, 5 do
			local ring = rings[r]
			if s > 0.05 and not calm then
				local rad = D * ringRad[r] * s * (if r > 3 then 1 else flourish)
				ring.rib.update(function(j: number)
					local q = (j - 1) / 2
					local a = t * ring.w - q * math.rad(if r > 3 then 200 else 160)
					local local0 = Vector3.new(math.cos(a), 0, math.sin(a))
					local localT = Vector3.new(math.sin(a), 0, -math.cos(a)) -- towards the next joint (the angle falls with j)
					local pos = op + ring.normal:VectorToWorldSpace(local0) * rad
					local tan = ring.normal:VectorToWorldSpace(localT)
					return {
						cf = CFrame.fromMatrix(pos, tan, ring.normal.UpVector),
						width = (if r > 3 then 0.16 else 0.09) * k * s * (1 - 0.8 * q),
						alpha = (if r > 3 then 0.1 else 0.2) + 0.8 * q,
						color = ringCol[r],
					}
				end)
			else
				ring.rib.hide()
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Outline (edges draw corner to corner), corner pillars, tether
	local edges = {}
	for i = 1, n do
		local p0, p1 = corner[i], corner[i % n + 1]
		local dir = (p1 - p0).Unit
		local inward = (C - (p0 + p1) / 2)
		inward = (inward - UP * inward:Dot(UP)).Unit
		local function pair(y: number, off: number, props)
			local s0 = p0 + UP * y - inward * off
			local a = c:attachment(Kit.oriented(s0, dir, inward))
			local b = c:attachment(Kit.oriented(s0, dir, inward))
			props.Enabled = false
			props.Segments = 1
			return { a = a, b = b, s0 = s0, s1 = p1 + UP * y - inward * off, beam = c:beam(a, b, props) }
		end
		local under = pair(0.05, 0, { LightEmission = 0, Color = ColorSequence.new(P.dark), Width0 = 1.25 * k, Width1 = 1.25 * k })
		local glow = pair(0.08, 0, { LightEmission = 1, Color = ColorSequence.new(P.body), Width0 = 0.95 * k, Width1 = 0.95 * k })
		local outer = pair(0.1, 0.36 * k, { LightEmission = 1, Color = ColorSequence.new(P.body), Width0 = 0.07 * k, Width1 = 0.07 * k })
		local core = pair(0.12, 0, { LightEmission = 1, Color = ColorSequence.new(P.white), Width0 = 0.17 * k, Width1 = 0.17 * k })
		FxTextures.apply(under.beam, "band")
		FxTextures.apply(glow.beam, "band")
		for _, e in { under, glow } do
			e.beam.TextureMode = Enum.TextureMode.Wrap
			e.beam.TextureLength = 0.05 * k -- fine enough to average into an even soft band
		end
		edges[i] = { under = under, glow = glow, outer = outer, core = core, dir = dir, inward = inward, len = (p1 - p0).Magnitude, mid = (p0 + p1) / 2 }
	end
	local outlineA = keys({ { 2.1, 0 }, { tRel, 0 }, { tRel + 0.9, 0.55 }, { tEnd, 1 } })
	local outlineHeat = keys({ { 2.1, 1 }, { 2.4, 0.85 }, { tRel, 0.8 }, { tRel + 0.9, 0 } })
	local pillars = {}
	for i = 1, n do
		local a, b = c:attachment(CFrame.new(corner[i])), c:attachment(CFrame.new(corner[i] + UP * R * 1.9))
		pillars[i] = c:beam(a, b, { FaceCamera = true, LightEmission = 1, Segments = 8, Width0 = 0.2 * k, Width1 = 0.05 * k, Color = ColorSequence.new(P.light), Enabled = false })
	end
	local pillarG = keys({ { 2.1, 0 }, { 2.14, 1 }, { 2.4, 0.75 }, { 2.9, 0.45 }, { tRel, 0.4 }, { tRel + 0.7, 0 } })
	local tetherA, tetherB = c:attachment(CFrame.new(C + UP * 0.15)), c:attachment(CFrame.new(C + UP * H))
	local tether = c:beam(tetherA, tetherB, { FaceCamera = true, LightEmission = 1, Segments = 1, Width0 = 0.08 * k, Width1 = 0.08 * k, Color = ColorSequence.new(P.light), Enabled = false })
	local tetherG = keys({ { 2.1, 0 }, { 2.16, 0.9 }, { 2.5, 0.65 }, { tRel + 0.5, 0.6 }, { tRel + 0.85, 0 } })
	every(function(t)
		local oa = outlineA(t)
		local heat = outlineHeat(t)
		for i = 1, n do
			local e = edges[i]
			local u = if calm then smooth(2.1, 2.3, t) else FxClock.clamp01((t - 2.10 - 0.015 * (i - 1)) / 0.05)
			local on = u > 0.001 and oa < 0.99
			for name, part in { under = e.under, glow = e.glow, outer = e.outer, core = e.core } do
				part.beam.Enabled = on
				if on then
					part.b.WorldCFrame = Kit.oriented(part.s0:Lerp(part.s1, u), e.dir, e.inward)
					local base = if name == "under" then 0.45 elseif name == "glow" then 0.3 elseif name == "outer" then 0.25 else 0
					part.beam.Transparency = NumberSequence.new(1 - (1 - base) * (1 - oa))
				end
			end
			if on then
				e.core.beam.Color = ColorSequence.new(P.body:Lerp(P.white, heat))
			end
			local g = pillarG(t) * (1 + 0.1 * Kit.noise(20 + i, t * 11))
			pillars[i].Enabled = g > 0.02
			if g > 0.02 then
				pillars[i].Transparency = Kit.fadeSeq({ { 0, 0.05 }, { 0.35, 0.45 }, { 1, 1 } }, g)
			end
		end
		local tg = tetherG(t)
		tether.Enabled = tg > 0.02
		if tg > 0.02 then
			tetherB.WorldPosition = orbAt(t) - UP * D * 0.4
			tether.Transparency = Kit.fadeSeq({ { 0, 0.3 }, { 1, 0.55 } }, tg)
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Fill: a fan of triangle ribbons from the centre to each edge, dark underlayer plus drifting cloud
	local fills = {}
	for i = 1, n do
		local e = edges[i]
		local toMid = (e.mid - C).Unit
		local function fan(y: number, props)
			local a = c:attachment(Kit.oriented(C + UP * y, toMid, e.dir))
			local b = c:attachment(Kit.oriented(e.mid + UP * y, toMid, e.dir))
			props.Width0 = 0.02
			props.Width1 = e.len
			props.Segments = 1
			props.Enabled = false
			return c:beam(a, b, props)
		end
		local dark = fan(0.03, { LightEmission = 0, Color = ColorSequence.new(P.dark) })
		local cloud = fan(0.06, { LightEmission = 1, Color = ColorSequence.new(P.light, P.body), TextureMode = Enum.TextureMode.Wrap, TextureLength = R * 0.9, TextureSpeed = 0.1 })
		FxTextures.apply(cloud, "smoke")
		fills[i] = { dark = dark, cloud = cloud }
	end
	local fillGlow = Kit.floorBlob(c)
	local fillG = keys({ { 2.12, 0 }, { 2.3, 1 }, { tRel, 1 }, { tRel + 0.9, 0.35 }, { tEnd - 0.1, 0 } })
	every(function(t)
		local g = fillG(t)
		fillGlow.set(C + UP * 0.09, R * 0.85, 1 - 0.55 * g, P.body)
		for i = 1, n do
			fills[i].dark.Enabled = g > 0.02
			fills[i].cloud.Enabled = g > 0.02
			if g > 0.02 then
				fills[i].dark.Transparency = NumberSequence.new(1 - 0.75 * g)
				fills[i].cloud.Transparency = NumberSequence.new(1 - 0.24 * g * (0.9 + 0.1 * Kit.noise(40 + i, t * 2)))
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Walls: upright strips on every edge carrying a slow rising cloud, plus flame licks (particles) from the edge
	local STRIPS = 5
	local walls = {}
	local wallH = keys({ { 2.14, 0 }, { 2.24, R * 1.45 }, { 2.4, R * 1.3 }, { 2.75, R * 0.85 }, { tRel, R * 0.8 }, { tRel + 0.8, R * 0.3 }, { tEnd - 0.1, R * 0.15 } })
	local wallG = keys({ { 2.14, 0 }, { 2.2, 1 }, { 2.75, 0.8 }, { tRel, 0.75 }, { tRel + 0.9, 0.3 }, { tEnd - 0.1, 0 } })
	for i = 1, n do
		local e = edges[i]
		for j = 1, STRIPS do
			local base = corner[i]:Lerp(corner[i % n + 1], (j - 0.5) / STRIPS) + UP * 0.05
			local a = c:attachment(Kit.oriented(base, UP, e.dir))
			local b = c:attachment(Kit.oriented(base + UP, UP, e.dir))
			local w = e.len / STRIPS * 1.35
			local beam = c:beam(a, b, {
				LightEmission = 1,
				Segments = 6,
				Width0 = w,
				Width1 = w * 1.1,
				Color = ColorSequence.new(P.light, P.body),
				TextureMode = Enum.TextureMode.Wrap,
				TextureLength = R * (0.9 + 0.5 * rng:NextNumber()),
				TextureSpeed = -(0.55 + 0.5 * rng:NextNumber()),
				Enabled = false,
			})
			FxTextures.apply(beam, "smoke")
			table.insert(walls, { beam = beam, b = b, base = base, dir = e.dir, seed = i * 10 + j, mid = 1 - math.abs((j - 0.5) / STRIPS - 0.5) * 0.5 })
		end
		local host = c:part({ Size = Vector3.new(e.len * 0.92, 0.2, 0.2), CFrame = CFrame.fromMatrix(e.mid + UP * 0.2, e.dir, UP) })
		local licks = c:emitter(host, {
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, P.light), ColorSequenceKeypoint.new(0.3, P.body), ColorSequenceKeypoint.new(1, P.deep) }),
			LightEmission = 1,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * k), NumberSequenceKeypoint.new(0.35, 1.3 * k), NumberSequenceKeypoint.new(1, 0.3 * k) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.45), NumberSequenceKeypoint.new(0.7, 0.7), NumberSequenceKeypoint.new(1, 1) }),
			Squash = NumberSequence.new(1.4),
			Lifetime = NumberRange.new(0.45, 0.8),
			Speed = NumberRange.new(4.5 * k, 8.5 * k),
			EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(9, 9),
			Rotation = NumberRange.new(-20, 20),
			Drag = 1.2,
		})
		FxTextures.apply(licks, "smoke")
		c:stream(licks, 2.16 / speed, (tRel + 0.35) / speed, function(tc)
			local t = tc * speed
			return (if t < 2.5 then 46 else 22) * speed
		end)
	end
	every(function(t)
		local h, g = wallH(t), wallG(t)
		for _, w in walls do
			w.beam.Enabled = g > 0.02
			if g > 0.02 then
				local hh = h * w.mid * (0.85 + 0.22 * Kit.noise(w.seed, t * 1.7))
				w.b.WorldCFrame = Kit.oriented(w.base + UP * math.max(hh, 0.1), UP, w.dir)
				w.beam.Transparency = Kit.fadeSeq({ { 0, 0.3 }, { 0.5, 0.62 }, { 1, 1 } }, g)
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Sparkles: upright 4-point stars popping around the formation, and small ones on the fill
	local sparkHost = c:part({ Size = Vector3.new(R * 2.3, R * 1.3, R * 2.3), CFrame = CFrame.new(C + UP * R * 0.75) })
	local sparkles = c:emitter(sparkHost, {
		Color = ColorSequence.new(P.white, P.light),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.95 * k), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new(0),
		Lifetime = NumberRange.new(0.35, 0.6),
		Rotation = NumberRange.new(0),
	})
	FxTextures.apply(sparkles, "star")
	c:stream(sparkles, 2.2 / speed, (tRel + 0.6) / speed, function()
		return 12 * speed
	end)
	local dustHost = c:part({ Size = Vector3.new(R * 1.1, 0.1, R * 1.1), CFrame = CFrame.new(C + UP * 0.3) })
	local dust = c:emitter(dustHost, {
		Color = ColorSequence.new(P.light),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.32 * k), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new(0.1),
		Lifetime = NumberRange.new(0.5, 0.9),
		Rotation = NumberRange.new(0),
	})
	FxTextures.apply(dust, "star")
	c:stream(dust, 2.3 / speed, (tRel + 0.8) / speed, function()
		return 9 * speed
	end)

	c:play()
	return c
end

return Formation
