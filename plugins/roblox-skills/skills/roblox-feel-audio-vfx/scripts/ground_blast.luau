--!nonstrict
-- ground_blast: an area explosion on the floor that leaves a cracked, glowing patch and small fires behind
-- (roblox-feel-audio-vfx section 3g). Every layer is built from small short-lived pieces: no sprite is a picture
-- of a whole flame or a whole explosion.
-- Timing and layer order follow a reference clip of a similar effect, read frame by frame next to captures of this
-- one at the same beats; every texture and the swirl mesh are made for it (ground_blast_textures.py,
-- ground_blast_swirl.py).
-- Needs fx_clock, fx_textures and fx_kit. GroundBlast.play(cframe, { hue, radius, timeScale, reducedMotion, seed }?)
-- -> clock. Client only. Call GroundBlast.preload() once before the first cast.
--
-- Textures: run ground_blast_textures.py, upload the PNG files as Images to your own account or group and put
-- the ids into a ModuleScript named fx_own_textures next to this one (template: fx_own_textures.luau), or call
-- GroundBlast.setTextures({ hot_fire_a = 123, ... }) before the first cast. Without ids the effect runs on public
-- stand-in textures and looks rough: GroundBlast.usesOwnTextures tells which.
-- Swirl mesh (optional): a MeshPart named Swirl in a folder FxMeshTemplates in ReplicatedStorage, with a
-- SurfaceAppearance (AlphaMode Transparency) whose ColorMap and EmissiveMask are the swirl_streaks texture; set the
-- maps in Studio Edit mode, a game script cannot write them. Without it streak sheets (beams) draw the swirl.
--
-- How the fire gets its look:
--   * colour bands from one sprite: a greyscale sheet with a wide luminance range, one deep red-orange tint and
--     ParticleEmitter.Brightness 3-6. The bright texels clip to yellow, the middle stays orange, the rim is red.
--   * the mass is layers, back to front: red smoke, banded fire lumps and tongues, thin hot crack lines, chips,
--     embers; small black smoke bits round it.
--   * low and wide (about 1.9 R wide, 0.8 R tall), cut straight by the floor.
--   * every piece lives 0.05-0.3 s and is replaced.
-- Ran in Studio 0.748 Play on 2026-11-18 (desktop view, a dark floor under a dim sky); not checked in a published
-- game, on a phone preset or on a real phone; frame cost not measured. One cast: 19 beams, 21 emitters, 18 helper
-- parts, 3 mesh parts, 1 light; at most 15 beams and 21 emitters live at once at the capture beats.
--
-- Beats (clock seconds at timeScale 1, R = radius):
--   0.00  a red crown and a short lift for two frames
--   0.02  vortex: a disc of thin streaks spins on the floor, the swirl sweeps round and up, a thin grey ring
--   0.12  flash: a low fan of white blades for three frames, a glow behind it
--   0.20  fire: banded lumps and tongues, low and wide; ejecta leave on arcs
--   0.32  the mass reddens: red smoke behind, thin hot crack lines over it; a column of embers
--   0.55  break-up: chips, black smoke bits, low dust; ejecta land as small fires
--   0.80  aftermath: thin lava cracks on a scorch, small fires built from tongues, embers
--   2.80  the fires die, the cracks cool from orange to dark red; clean at 4.1
local Lighting = game:GetService("Lighting")
local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)
local Kit = require(script.Parent.fx_kit)

local GroundBlast = {}
-- the beats of the example strip
GroundBlast.CAPTURE_TIMES = { 0.02, 0.07, 0.12, 0.17, 0.22, 0.32, 0.42, 0.57, 0.67, 0.82, 1.02, 1.32, 1.82, 2.42, 3.02, 3.6 }
GroundBlast.DURATION = 4.1

local TAU = math.pi * 2
local SWIRL_SPIN = 1 -- the turn that makes the swirl mesh's head lead (ground_blast_swirl.py winds one way)
local UP = Vector3.yAxis
local smooth, keys = FxClock.smooth, Kit.keys
local ns, cs = FxClock.ns, FxClock.cs

-- Own textures: slot "own_<name>", with a public stand-in while the id is missing.
local OWN = {
	hot_fire_a = { flipbook = "Grid4x4", standIn = "smoke" },
	hot_fire_b = { flipbook = "Grid4x4", standIn = "smoke" },
	lick = { flipbook = "Grid4x4", standIn = "flare" },
	crackle = { flipbook = "Grid2x2", standIn = "electric" },
	flecks = { flipbook = "Grid2x2", standIn = "streak" },
	sim_smoke = { flipbook = "Grid4x4", standIn = "smoke" },
	streaks = { standIn = "streak" },
	blades = { standIn = "flare" },
	cracks = { standIn = "glow" },
	trail = { standIn = "streak" },
	swirl_disc = { standIn = "flare" },
	scorch = { standIn = "glow" },
	shock_ring = { standIn = "flare" },
	spark = { standIn = "streak" },
}
GroundBlast.usesOwnTextures = false
-- ids: { name = asset id number }, the names of the files ground_blast_textures.py writes (swirl_streaks is for the
-- mesh template, not for this table). A name that is missing keeps its stand-in.
function GroundBlast.setTextures(ids: { [string]: number })
	local all = true
	for name, def in OWN do
		local id = ids[name]
		if id and id ~= 0 then
			FxTextures.slots["own_" .. name] = { { id = "rbxassetid://" .. tostring(id), note = "own art: " .. name, flipbook = def.flipbook } }
		else
			FxTextures.slots["own_" .. name] = FxTextures.slots[def.standIn]
			all = false
		end
	end
	GroundBlast.usesOwnTextures = all
end
local ownModule = script.Parent:FindFirstChild("fx_own_textures")
GroundBlast.setTextures(if ownModule then require(ownModule) else {})

-- Fire palette from one hue: the hot colours lean one way round the wheel, the deep ones the other
-- (orange: yellow inside, red rim; violet: pink inside, blue-violet rim).
local function palette(hue: number)
	local function hsv(h, s, v)
		return Color3.fromHSV(h % 1, s, v)
	end
	return {
		white = hsv(hue + 0.08, 0.22, 1),
		hot = hsv(hue + 0.07, 0.68, 1),
		body = hsv(hue + 0.01, 0.9, 1),
		red = hsv(hue - 0.06, 0.95, 1),
		deep = hsv(hue - 0.07, 1, 0.7),
		dark = hsv(hue - 0.07, 0.9, 0.22),
		smoke = hsv(hue, 0.25, 0.09),
		dust = Color3.fromRGB(120, 124, 136),
		-- the one tint of every Brightness-banded sprite: a step past the body colour, away from the hot side
		-- (orange fire: red-orange; with Brightness 4 its bright texels clip to yellow)
		tint = hsv(hue - 0.037, 0.97, 1),
		soot = hsv(hue, 0.3, 0.035),
	}
end

-- Call once before the first cast (it yields): a texture that is not in memory yet draws as a flat square.
function GroundBlast.preload()
	local list = {}
	for name in OWN do
		for _, cand in FxTextures.slots["own_" .. name] do
			table.insert(list, cand.id)
		end
	end
	game:GetService("ContentProvider"):PreloadAsync(list)
end

function GroundBlast.play(cf: CFrame, opts)
	opts = opts or {}
	local R: number = opts.radius or 8
	local speed: number = opts.timeScale or 1
	local calm: boolean = opts.reducedMotion == true
	local P = palette(opts.hue or 0.07)
	local rng = Random.new(opts.seed or 11)
	local k = R / 8
	local tEnd = GroundBlast.DURATION

	local c = FxClock.new("GroundBlast", (tEnd + 0.05) / speed)
	local function every(fn)
		c:every(function(t, dt)
			fn(t * speed, dt * speed)
		end)
	end
	local events = {}
	local function at(t0: number, fn)
		table.insert(events, { t = t0, fn = fn })
	end
	local C = cf.Position
	local cam = workspace.CurrentCamera
	local function right(): Vector3
		local r = cam.CFrame.RightVector * Vector3.new(1, 0, 1)
		return if r.Magnitude < 1e-3 then Vector3.xAxis else r.Unit
	end
	local function dirAt(a: number): Vector3
		return cf:VectorToWorldSpace(Vector3.new(math.cos(a), 0, math.sin(a)))
	end
	local function tanAt(a: number): Vector3
		return cf:VectorToWorldSpace(Vector3.new(-math.sin(a), 0, math.cos(a)))
	end
	local function count(n: number): number
		return if calm then math.max(1, math.floor(n / 2)) else n
	end
	-- particle properties follow timeScale: slower clock, longer lives, lower speeds
	local function emitter(parent: Instance, props)
		local lt: NumberRange = props.Lifetime
		props.Lifetime = NumberRange.new(lt.Min / speed, lt.Max / speed)
		if props.Speed then
			props.Speed = NumberRange.new(props.Speed.Min * speed, props.Speed.Max * speed)
		end
		if props.Acceleration then
			props.Acceleration = props.Acceleration * speed * speed
		end
		if props.Drag then
			props.Drag = props.Drag * speed
		end
		if props.RotSpeed then
			props.RotSpeed = NumberRange.new(props.RotSpeed.Min * speed, props.RotSpeed.Max * speed)
		end
		local slot = props.slot
		props.slot = nil
		local e = c:emitter(parent, props)
		FxTextures.apply(e, slot)
		return e
	end
	-- a joint frame for a camera-facing ribbon: X along the travel
	local function alongCF(pos: Vector3, x: Vector3): CFrame
		local y = x:Cross(UP)
		return CFrame.fromMatrix(pos, x, if y.Magnitude < 1e-3 then Vector3.xAxis else y.Unit)
	end
	-- a beam that carries one texture once along its length (the image's vertical axis runs along the beam, its
	-- top at Attachment0)
	local function texBeam(a0, a1, slot: string, props)
		props.TextureMode = Enum.TextureMode.Stretch
		props.TextureLength = 1
		props.Enabled = false
		local b = c:beam(a0, a1, props)
		FxTextures.apply(b, slot)
		return b
	end
	-- a textured square lying on the floor that can turn
	local function floorQuad(slot: string, props)
		local a0, a1 = c:attachment(), c:attachment()
		props.FaceCamera = false
		props.Segments = 1
		local b = texBeam(a0, a1, slot, props)
		local q = { beam = b }
		function q.set(pos: Vector3, radius: number, alpha: number, color: Color3?, yaw: number?)
			if alpha >= 0.995 or radius <= 0.001 then
				b.Enabled = false
				return
			end
			local along, across = dirAt(yaw or 0), tanAt(yaw or 0)
			a0.WorldCFrame = Kit.oriented(pos - along * radius, along, across)
			a1.WorldCFrame = Kit.oriented(pos + along * radius, along, across)
			b.Width0 = radius * 2
			b.Width1 = radius * 2
			b.Transparency = NumberSequence.new(math.clamp(alpha, 0, 1))
			if color then
				b.Color = ColorSequence.new(color)
			end
			b.Enabled = true
		end
		return q
	end
	-- particles per second from a curve of the clock (Emit from an accumulator: Rate cannot follow timeScale)
	local streams = {}
	local function stream(e: ParticleEmitter, rate)
		table.insert(streams, { e = e, rate = rate, acc = 0 })
	end
	every(function(t, dt)
		local m = if calm then 0.5 else 1
		for _, st in streams do
			st.acc += math.max(st.rate(t), 0) * dt * m
			local n = math.floor(st.acc)
			if n > 0 then
				st.acc -= n
				st.e:Emit(n)
			end
		end
	end)
	-- a sheet of different pieces, not an animation: each particle shows one random cell
	local function randomCell(e: ParticleEmitter)
		e.FlipbookMode = Enum.ParticleFlipbookMode.Loop
		e.FlipbookStartRandom = true
		e.FlipbookFramerate = NumberRange.new(0)
		return e
	end
	local SURFACE, OUTWARD = Enum.ParticleEmitterShapeStyle.Surface, Enum.ParticleEmitterShapeInOut.Outward

	------------------------------------------------------------------------------------------------------
	-- Grade and light: a short lift, no white-out
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "GroundBlastGrade"
	grade.Parent = Lighting
	c:onCleanup(function()
		grade:Destroy()
	end)
	local flashK = keys({ { 0, if calm then 0.03 else 0.1 }, { 0.06, 0 }, { 0.11, 0 }, { 0.14, if calm then 0.02 else 0.06 }, { 0.24, 0.02 }, { 0.4, 0 } })
	local lightHost = c:part({ Size = Vector3.one * 0.2, CFrame = CFrame.new(C + UP * R * 0.4) })
	local light = c:light(lightHost, { Range = math.min(R * 2.6 + 4, 60), Color = P.body })
	local lightK = keys({ { 0, 0.5 }, { 0.1, 1.6 }, { 0.3, 1.1 }, { 0.8, 0.35 }, { 2.6, 0.2 }, { 3.6, 0 } })
	every(function(t)
		grade.Brightness = flashK(t)
		light.Brightness = lightK(t) * (1 + 0.12 * Kit.noise(3, t * 9))
	end)

	------------------------------------------------------------------------------------------------------
	-- Vortex: two discs of thin streaks spin on the floor while streak sheets sweep round and up
	local swirl = if rng:NextNumber() < 0.5 then 1 else -1
	local discA = floorQuad("own_swirl_disc", { LightEmission = 0.75, ZOffset = 0.05 })
	local discB = floorQuad("own_swirl_disc", { LightEmission = 1, ZOffset = 0.1 })
	local discR = keys({ { 0, 0.9 }, { 0.1, 1.6 }, { 0.3, 2.0 } })
	local discA_a = keys({ { 0, 1 }, { 0.015, 0.1 }, { 0.12, 0.15 }, { 0.3, 1 } })
	local discB_a = keys({ { 0, 1 }, { 0.03, 0.25 }, { 0.1, 0.3 }, { 0.2, 1 } })
	every(function(t)
		discA.set(C + UP * 0.1, discR(t) * R, discA_a(t), P.red, swirl * t * 9)
		discB.set(C + UP * 0.16, discR(t) * R * 0.62, discB_a(t), P.body, 1.7 + swirl * t * 14)
	end)
	-- The swirl itself is a mesh when the place has the template (FxMeshTemplates.Swirl in ReplicatedStorage: a band
	-- that winds round the centre, UV along the flow, with a SurfaceAppearance whose ColorMap and emissive mask are
	-- the swirl_streaks texture, whose RGB carries the pattern: the mask reads the colour channels, not alpha). A
	-- textured mesh is drawn with the scene's light, so its glow is the emissive mask; EmissiveStrength bands it
	-- the way Brightness bands a particle. A game script can set Color, EmissiveStrength and EmissiveTint but not
	-- the maps (measured), so the maps live in the template. Without the template the streak sheets below (beams)
	-- stand in.
	local templates = game:GetService("ReplicatedStorage"):FindFirstChild("FxMeshTemplates")
	local swirlTemplate = templates and templates:FindFirstChild("Swirl")
	local swirls = {}
	if swirlTemplate then
		swirl = 1 -- the mesh winds one way
		for i = 1, (if calm then 2 else 3) do
			local m = swirlTemplate:Clone()
			local sa = m:FindFirstChildOfClass("SurfaceAppearance")
			sa.Color = P.tint
			m.Transparency = 1
			m.Parent = workspace
			c:onCleanup(function()
				m:Destroy()
			end)
			swirls[i] = {
				m = m, sa = sa, base = swirlTemplate.Size, pivot = swirlTemplate.PivotOffset.Position,
				yaw = (i - 1) * 2.2 + rng:NextNumber(0, 0.5), s = ({ 1.0, 0.7, 1.3 })[i], hy = ({ 1.0, 1.6, 0.75 })[i],
				t0 = 0.012 + 0.02 * (i - 1), life = rng:NextNumber(0.12, 0.15), om = rng:NextNumber(8, 12),
				tilt = CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), 0, math.rad(rng:NextNumber(-20, 20))),
			}
		end
	end
	every(function(t)
		for _, sw in swirls do
			local u = (t - sw.t0) / sw.life
			if u < 0 or u > 1 then
				sw.m.Transparency = 1
				continue
			end
			local sc = R * 0.95 * sw.s * (0.7 + 0.65 * FxClock.outCubic(u))
			local scale = Vector3.new(sc, sc * sw.hy, sc)
			sw.m.Size = sw.base * scale
			-- the part's CFrame is its bounding box centre; the swirl's axis is the template's pivot
			sw.m.CFrame = cf * CFrame.new(0, 0.1 + 0.12 * sc, 0) * sw.tilt * CFrame.Angles(0, sw.yaw + SWIRL_SPIN * sw.om * (t - sw.t0), 0) * CFrame.new(-sw.pivot * scale)
			sw.m.Transparency = 0.02 + 0.98 * smooth(0.6, 1, u)
			sw.sa.EmissiveStrength = 6 - 4 * u
		end
	end)
	local sheets = {}
	for i = 1, (if swirlTemplate then 2 elseif calm then 7 else 13) do
		local floorLine = i > 11 or swirlTemplate ~= nil -- the last ones stay flat on the floor as thin lines after the burst
		local rib = c:ribbon(1, { LightEmission = if floorLine then 0.6 else 0.7, Segments = 18, TextureMode = Enum.TextureMode.Stretch, TextureLength = 1 })
		FxTextures.apply(rib.beams[1], "own_streaks")
		sheets[i] = {
			rib = rib, flat = floorLine,
			a0 = (i + rng:NextNumber(-0.3, 0.3)) / 5.5 * TAU,
			rad = R * (if floorLine then rng:NextNumber(1.2, 1.7) else rng:NextNumber(0.65, 1.45)),
			arc = math.rad(rng:NextNumber(78, 104)),
			t0 = if floorLine then 0.26 + rng:NextNumber(0, 0.1) else rng:NextNumber(0, 0.035),
			life = if floorLine then rng:NextNumber(0.22, 0.32) else rng:NextNumber(0.1, 0.16),
			w = R * (if floorLine then rng:NextNumber(0.35, 0.5) else rng:NextNumber(0.8, 1.45)),
			y0 = R * (if floorLine then 0.02 else rng:NextNumber(0.04, 0.45)),
			rise = R * (if floorLine then 0 else rng:NextNumber(0.15, 0.6)),
			tilt = math.rad(if floorLine then 90 else rng:NextNumber(18, 58)),
			om = if floorLine then rng:NextNumber(1.5, 2.5) else rng:NextNumber(7, 11),
			grow = if floorLine then 0.1 else rng:NextNumber(0.2, 0.5),
		}
	end
	every(function(t)
		for _, sh in sheets do
			local u = (t - sh.t0) / sh.life
			if u >= 0 and u <= 1 then
				-- the first frames of a beam that was just switched on drew flat and untextured in captures: keep it clear
				local env = if t - sh.t0 < 0.025 then 0 else math.sin(math.pi * math.sqrt(u)) ^ 0.7
				local ah = sh.a0 + swirl * sh.om * (t - sh.t0)
				local rad = sh.rad * (1 + sh.grow * u)
				sh.rib.update(function(j: number)
					local a = if j == 1 then ah - swirl * sh.arc else ah -- tail first: X runs tail -> head
					local radial, tan = dirAt(a), tanAt(a) * swirl
					local y = if j == 1 then sh.y0 else sh.y0 + sh.rise
					local wa = (UP * math.cos(sh.tilt) + radial * math.sin(sh.tilt)).Unit
					return {
						cf = CFrame.fromMatrix(C + radial * rad + UP * (y + 0.1), tan, wa), width = sh.w,
						alpha = 1 - env * (if sh.flat then 0.7 else 0.95),
						color = if j == 1 then P.deep else (if sh.flat then P.red else P.red:Lerp(P.body, 0.35)),
					}
				end)
			else
				sh.rib.hide()
			end
		end
	end)
	-- the thin grey ring on the floor
	local ring = floorQuad("own_shock_ring", { LightEmission = 0.4, ZOffset = 0.02 })
	local ringR = keys({ { 0, 1.7 }, { 0.12, 2.2 }, { 0.4, 2.6 } })
	local ringA = keys({ { 0, 1 }, { 0.02, 0.55 }, { 0.14, 0.6 }, { 0.4, 1 } })
	local ringColor = Color3.fromRGB(190, 196, 210)
	every(function(t)
		ring.set(C + UP * 0.08, ringR(t) * R, ringA(t), ringColor, 0.6)
	end)

	------------------------------------------------------------------------------------------------------
	-- Crown: for the first two frames a wide low fan of red blades stands on the floor
	local crA0, crA1 = c:attachment(), c:attachment()
	local crown = texBeam(crA0, crA1, "own_blades", { FaceCamera = true, LightEmission = 0.8, Brightness = 2.2, Segments = 1 })
	every(function(t)
		crown.Enabled = t >= 0.025 and t < 0.075
		if crown.Enabled then
			local h = R * (0.75 + 3 * t)
			crA0.WorldPosition = C + UP * h
			crA1.WorldPosition = C
			crown.Width0, crown.Width1 = h * 2.6, h * 2.6
			crown.Color = ColorSequence.new(P.tint)
			crown.Transparency = NumberSequence.new(0.1 + 0.5 * smooth(0.04, 0.075, t))
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Flash: a low fan of white shards for three frames over a glow
	local shA0, shA1 = c:attachment(), c:attachment()
	local shards = texBeam(shA0, shA1, "own_blades", { FaceCamera = true, LightEmission = 1, Brightness = 1.6, Segments = 1, ZOffset = 0.3 })
	local shB0, shB1 = c:attachment(), c:attachment()
	local shardsWide = texBeam(shB0, shB1, "own_blades", { FaceCamera = true, LightEmission = 1, Brightness = 6, Segments = 1 })
	local flashGlow, flashCore = Kit.blob(c, { ZOffset = -0.5 }), Kit.blob(c, { ZOffset = 0.6 })
	local shardH = keys({ { 0.11, 0.7 }, { 0.15, 1.35 }, { 0.26, 1.6 } })
	local shardA = keys({ { 0.11, 1 }, { 0.125, 0 }, { 0.2, 0.05 }, { 0.27, 1 } })
	every(function(t)
		local a = shardA(t)
		shards.Enabled = a < 0.99
		shardsWide.Enabled = a < 0.99
		if a < 0.99 then
			local h = shardH(t) * R
			local root = C + UP * (0.02 * R)
			shA0.WorldPosition = root + UP * h * 0.8 -- image top at Attachment0: the fan's root is at the bottom
			shA1.WorldPosition = root
			shards.Width0, shards.Width1 = h * 0.8, h * 0.8
			shards.Color = ColorSequence.new(P.white)
			shards.Transparency = NumberSequence.new(a)
			local r = right()
			shB0.WorldPosition = root + UP * h * 1.1 - r * (0.1 * R)
			shB1.WorldPosition = root - r * (0.1 * R)
			shardsWide.Width0, shardsWide.Width1 = h * 1.5, h * 1.5 -- wider than tall: not the same fan twice
			shardsWide.Color = ColorSequence.new(P.tint)
			shardsWide.Transparency = NumberSequence.new(a)
		end
		local g = 1 - smooth(0.11, 0.14, t) * (1 - smooth(0.2, 0.34, t))
		flashGlow.set(C + UP * R * 0.35, R * 1.5, 1 - (1 - g) * 0.4, P.body)
		flashCore.set(C + UP * R * 0.22, R * 0.34, 1 - (1 - g) * 0.5, P.hot)
	end)

	------------------------------------------------------------------------------------------------------
	-- Fire mass: a low, wide volume. Back to front: red smoke, banded fire lumps, tongues, hot crack lines, chips.
	-- Every piece lives 0.05-0.3 s and new ones replace it, so the mass changes shape every frame.
	local mass = c:part({ Size = Vector3.new(R * 1.9, R * 0.34, R * 1.5), CFrame = CFrame.new(C + UP * R * 0.25) })
	local crest = c:part({ Size = Vector3.new(R * 1.1, R * 0.36, R * 0.9), CFrame = CFrame.new(C + UP * R * 0.56) })
	local slab = c:part({ Size = Vector3.new(R * 1.6, R * 0.3, R * 1.3), CFrame = CFrame.new(C + UP * R * 0.4) })
	local fireRate = keys({ { 0.19, 0 }, { 0.22, 60 }, { 0.36, 48 }, { 0.5, 20 }, { 0.6, 5 }, { 0.66, 0 } })
	local fireBright = keys({ { 0.2, 6 }, { 0.34, 4 }, { 0.5, 2.7 }, { 0.8, 2 } })
	local fires = {}
	for i, slot in { "own_hot_fire_a", "own_hot_fire_b" } do
		fires[i] = emitter(if i == 1 then mass else crest, {
			slot = slot, LightEmission = 0.7, Brightness = 4,
			Lifetime = NumberRange.new(0.14, 0.26), Speed = NumberRange.new(2 * k, 8 * k), SpreadAngle = Vector2.new(70, 70), Drag = 2,
			EmissionDirection = Enum.NormalId.Top,
			Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40),
			Size = ns({ { 0, 3.4 * k, 0.6 * k }, { 0.35, 5.4 * k, 0.9 * k }, { 1, 6 * k, 1 * k } }),
			Color = cs({ { 0, P.tint }, { 0.6, P.tint }, { 1, P.deep } }),
			Transparency = ns({ { 0, 0 }, { 0.8, 0 }, { 1, 0.5 } }),
		})
		stream(fires[i], function(t)
			return fireRate(t) * (if i == 1 then 1.5 else 0.8)
		end)
	end
	local tongues = randomCell(emitter(slab, {
		slot = "own_lick", LightEmission = 0.8, Brightness = 4,
		Lifetime = NumberRange.new(0.1, 0.18), Speed = NumberRange.new(8 * k, 18 * k), SpreadAngle = Vector2.new(22, 22),
		EmissionDirection = Enum.NormalId.Top, Drag = 1.5, Rotation = NumberRange.new(-28, 28),
		Size = ns({ { 0, 3.2 * k, 0.8 * k }, { 1, 4.6 * k, 1 * k } }),
		Color = cs({ { 0, P.tint }, { 1, P.tint } }),
		Transparency = ns({ { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }),
		ZOffset = 0.4,
	}))
	stream(tongues, keys({ { 0.19, 0 }, { 0.22, 46 }, { 0.4, 34 }, { 0.55, 10 }, { 0.62, 0 } }))
	every(function(t)
		local b = fireBright(t)
		fires[1].Brightness, fires[2].Brightness, tongues.Brightness = b, b, b
	end)
	-- red smoke behind: what makes the mass read red, not orange, once the fire thins
	local redSmoke = emitter(slab, {
		slot = "own_sim_smoke", LightEmission = 0.3, Brightness = 1.6,
		Lifetime = NumberRange.new(0.22, 0.4), Speed = NumberRange.new(2 * k, 7 * k), SpreadAngle = Vector2.new(50, 50),
		EmissionDirection = Enum.NormalId.Top, Drag = 1.5, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20),
		Size = ns({ { 0, 2.6 * k, 0.6 * k }, { 1, 4.4 * k, 0.9 * k } }),
		Color = cs({ { 0, P.red }, { 0.6, P.red }, { 1, P.deep } }),
		Transparency = ns({ { 0, 0.45 }, { 0.6, 0.55 }, { 1, 1 } }),
		ZOffset = -1,
	})
	stream(redSmoke, keys({ { 0.24, 0 }, { 0.32, 50 }, { 0.6, 60 }, { 0.85, 30 }, { 1.05, 0 } }))
	-- thin hot crack lines over the reddening mass
	local inner = c:part({ Size = Vector3.new(R * 1.1, R * 0.4, R * 0.9), CFrame = CFrame.new(C + UP * R * 0.38) })
	local crackle = randomCell(emitter(inner, {
		slot = "own_crackle", LightEmission = 1, Brightness = 3,
		Lifetime = NumberRange.new(0.05, 0.1), Speed = NumberRange.new(0), Rotation = NumberRange.new(0, 360),
		Size = ns({ { 0, 4.6 * k, 1.2 * k }, { 1, 6.2 * k, 1.4 * k } }),
		Color = cs({ { 0, P.body }, { 1, P.body } }),
		Transparency = ns({ { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } }),
		ZOffset = 1,
	}))
	stream(crackle, keys({ { 0.3, 0 }, { 0.38, 50 }, { 0.62, 60 }, { 0.85, 22 }, { 1.0, 0 } }))
	-- chips: what is left as it breaks up
	local flecks = randomCell(emitter(mass, {
		slot = "own_flecks", LightEmission = 1, Brightness = 3.5,
		Lifetime = NumberRange.new(0.06, 0.13), Speed = NumberRange.new(2 * k, 9 * k), SpreadAngle = Vector2.new(80, 80),
		EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(0, 360),
		Size = ns({ { 0, 5.5 * k, 1.5 * k }, { 1, 8 * k, 2 * k } }),
		Color = cs({ { 0, P.body }, { 1, P.tint } }),
		Transparency = ns({ { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } }),
		ZOffset = 1.2,
	}))
	stream(flecks, keys({ { 0.48, 0 }, { 0.6, 70 }, { 0.9, 60 }, { 1.2, 0 } }))
	-- a soft glow behind the mass, kept weak: a strong one turns the fire into fog
	local body = Kit.blob(c, { ZOffset = -1.6 })
	local bodyR = keys({ { 0.14, 0.5 }, { 0.24, 1.3 }, { 0.4, 1.5 }, { 0.7, 1.3 }, { 1.2, 1.0 } })
	local bodyA = keys({ { 0.14, 1 }, { 0.22, 0.72 }, { 0.4, 0.76 }, { 0.7, 0.88 }, { 1.2, 1 } })
	every(function(t)
		body.set(C + UP * R * 0.4, bodyR(t) * R, bodyA(t), P.body:Lerp(P.red, smooth(0.25, 0.6, t)))
	end)

	------------------------------------------------------------------------------------------------------
	-- A thin streak climbs out of the top
	local stemA, stemB = c:attachment(), c:attachment()
	local stem = texBeam(stemA, stemB, "own_trail", { FaceCamera = true, LightEmission = 1, Brightness = 3, Segments = 1 })
	every(function(t)
		local u = (t - 0.2) / 0.3
		stem.Enabled = u >= 0 and u <= 1
		if stem.Enabled then
			local top = C - right() * (R * 0.2) + UP * R * (0.5 + 1.0 * FxClock.outCubic(u))
			stemA.WorldPosition = C - right() * (R * 0.2) + UP * R * (0.1 + 0.5 * u * u)
			stemB.WorldPosition = top
			stem.Width0 = R * 0.26
			stem.Width1 = R * 0.26
			stem.Color = ColorSequence.new(P.tint)
			stem.Transparency = NumberSequence.new(0.2 + 0.8 * smooth(0.4, 1, u))
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Fires: a spot burns as a stream of flame tongues (one random tongue per particle, 0.1-0.2 s each, five to
	-- eight alive at once, their hot roots overlapping). No sprite is a picture of a whole flame: one sprite that
	-- shows a complete flame reads as a pasted image, and seen alone it is a flat cut-out. The tongues keep the
	-- banded tint to the end of their life: they leave by shrinking, never by turning dark.
	local spots = {}
	local function fireSpot(pos: Vector3, t0: number, t1: number, size: number)
		local sz = size * k
		local box = c:part({ Size = Vector3.new(1.0 * sz, 0.35 * sz, 0.4 * sz), CFrame = CFrame.new(pos + UP * (0.72 * sz)) })
		local licks = randomCell(emitter(box, {
			slot = "own_lick", LightEmission = 0.9, Brightness = 3.6,
			Lifetime = NumberRange.new(0.1, 0.2), Speed = NumberRange.new(1.5 * sz, 4.5 * sz), SpreadAngle = Vector2.new(8, 8),
			EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(-16, 16),
			Size = ns({ { 0, 1.3 * sz, 0.45 * sz }, { 0.6, 1.2 * sz, 0.4 * sz }, { 1, 0.7 * sz, 0.2 * sz } }),
			Color = cs({ { 0, P.tint }, { 1, P.tint } }),
			Transparency = ns({ { 0, 0.05 }, { 0.75, 0.15 }, { 1, 1 } }),
			ZOffset = 0.5,
		}))
		table.insert(spots, { t0 = t0, t1 = t1, licks = licks, sz = sz, seed = rng:NextNumber(0, 100), acc = 0, last = -1 })
	end
	every(function(t, dt)
		for _, sp in spots do
			-- a dying spot shrinks and then stops: thinning the stream instead would leave one tongue alone on
			-- the floor, which is the single pasted sprite again
			local g = smooth(sp.t0 - 0.01, sp.t0 + 0.03, t) * (1 - smooth(sp.t1 - 0.7, sp.t1, t))
			if g < 0.3 then
				continue
			end
			local q = math.floor(g * 8) / 8
			if q ~= sp.last then
				sp.last = q
				local z = sp.sz * (0.45 + 0.55 * q)
				sp.licks.Size = ns({ { 0, 1.3 * z, 0.45 * z }, { 0.6, 1.2 * z, 0.4 * z }, { 1, 0.7 * z, 0.2 * z } })
			end
			sp.acc += 55 * (0.75 + 0.25 * Kit.noise(sp.seed, t * 7)) * dt
			local n = math.floor(sp.acc)
			if n > 0 then
				sp.acc -= n
				sp.licks:Emit(n)
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Sparks and embers
	local sparkHost = c:attachment(CFrame.new(C + UP * R * 0.3))
	local sparks = emitter(sparkHost, {
		slot = "own_spark", LightEmission = 1, Brightness = 2.5, Orientation = Enum.ParticleOrientation.VelocityParallel, Rotation = NumberRange.new(0),
		Lifetime = NumberRange.new(0.1, 0.28), Speed = NumberRange.new(26 * k, 80 * k), SpreadAngle = Vector2.new(80, 80),
		EmissionDirection = Enum.NormalId.Top, Drag = 2.6, Acceleration = Vector3.new(0, -52 * k, 0),
		Size = ns({ { 0, 1.4 * k }, { 0.5, 1.1 * k }, { 1, 0.3 * k } }),
		Color = cs({ { 0, P.tint }, { 1, P.tint } }),
		Transparency = ns({ { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }),
		ZOffset = 2.5,
	})
	for _, ev in { { 0.14, 14 }, { 0.22, 22 }, { 0.3, 28 }, { 0.38, 24 }, { 0.48, 18 }, { 0.6, 10 } } do
		at(ev[1], function()
			sparks:Emit(count(ev[2]))
		end)
	end
	-- embers are specks: small, red-orange, never white
	local function emberProps(lifeMin: number, lifeMax: number)
		return {
			slot = "glow", LightEmission = 1, Brightness = 2.2,
			Lifetime = NumberRange.new(lifeMin, lifeMax), Drag = 1.2,
			Size = ns({ { 0, 0.2 * k, 0.08 * k }, { 0.6, 0.15 * k, 0.06 * k }, { 1, 0.04 * k } }),
			Color = cs({ { 0, P.tint }, { 1, P.red } }),
			Transparency = ns({ { 0, 0 }, { 0.3, 0.35 }, { 0.5, 0 }, { 0.75, 0.4 }, { 1, 1 } }),
			ZOffset = 2,
		}
	end
	-- a loose column of embers above the blast
	local colHost = c:attachment(CFrame.new(C + UP * R * 0.7))
	local colProps = emberProps(0.35, 0.9)
	colProps.Speed = NumberRange.new(6 * k, 30 * k)
	colProps.SpreadAngle = Vector2.new(24, 24)
	colProps.EmissionDirection = Enum.NormalId.Top
	colProps.Acceleration = Vector3.new(0, -5 * k, 0)
	stream(emitter(colHost, colProps), keys({ { 0.2, 0 }, { 0.26, 110 }, { 0.55, 80 }, { 0.85, 24 }, { 1.05, 0 } }))
	-- embers that hop up from the patch for seconds
	local emberBox = c:part({ Size = Vector3.new(R * 1.9, 0.4, R * 1.9), CFrame = CFrame.new(C + UP * 0.6) })
	local driftProps = emberProps(0.7, 1.7)
	driftProps.Speed = NumberRange.new(1.5 * k, 8 * k)
	driftProps.SpreadAngle = Vector2.new(55, 55)
	driftProps.EmissionDirection = Enum.NormalId.Top
	driftProps.Acceleration = Vector3.new(0, 1.2 * k, 0)
	stream(emitter(emberBox, driftProps), keys({ { 0.3, 0 }, { 0.45, 80 }, { 0.9, 46 }, { 2.0, 18 }, { 2.9, 0 } }))

	------------------------------------------------------------------------------------------------------
	-- Ejecta: glowing pieces on arcs. One curved beam per trail with the banded tint (hot core, red edge); each
	-- lands with a cluster of specks and leaves a fire
	local landHost = c:attachment(CFrame.new(C))
	local landProps = emberProps(0.25, 0.6)
	landProps.Speed = NumberRange.new(2 * k, 12 * k)
	landProps.SpreadAngle = Vector2.new(75, 75)
	landProps.EmissionDirection = Enum.NormalId.Top
	landProps.Acceleration = Vector3.new(0, -22 * k, 0)
	local landSparks = emitter(landHost, landProps)
	local ejecta = {}
	for i = 1, (if calm then 2 else 4) do
		local a = (i + rng:NextNumber(-0.25, 0.25)) / 4 * TAU + 0.5
		local T = rng:NextNumber(0.48, 0.58)
		local range = R * rng:NextNumber(1.4, 2.1)
		local apex = R * rng:NextNumber(0.9, 1.35)
		local vy = 4 * apex / T
		-- one curved beam per trail: a chain of additive beams shows a seam at every joint
		local rib = c:ribbon(1, { FaceCamera = true, LightEmission = 0.55, Segments = 18, TextureMode = Enum.TextureMode.Stretch, TextureLength = 1, ZOffset = 0.2 })
		FxTextures.apply(rib.beams[1], "own_trail")
		rib.beams[1].Brightness = 2.2
		local ej = {
			rib = rib,
			dir = dirAt(a), t0 = 0.13 + rng:NextNumber(0, 0.08), T = T, vh = range / T, vy = vy, g = 2 * vy / T,
			w = R * rng:NextNumber(0.24, 0.32), landed = false,
		}
		ej.land = C + ej.dir * (R * 0.3 + range) + UP * 0.1
		ejecta[i] = ej
		fireSpot(ej.land, ej.t0 + T, ej.t0 + T + rng:NextNumber(1.0, 1.5), 1.25)
	end
	every(function(t)
		for _, ej in ejecta do
			local tau = t - ej.t0
			if tau < 0 or tau > ej.T + 0.28 then
				ej.rib.hide()
				continue
			end
			local function at2(x: number): (Vector3, Vector3)
				x = math.clamp(x, 0, ej.T)
				local pos = C + ej.dir * (R * 0.3 + ej.vh * x) + UP * (R * 0.2 + ej.vy * x - 0.5 * ej.g * x * x)
				local vel = ej.dir * ej.vh + UP * (ej.vy - ej.g * x)
				return pos, vel.Unit
			end
			local headT, tailT = math.min(tau, ej.T), math.clamp(tau - 0.28, 0, ej.T)
			if headT - tailT > 0.01 then
				ej.rib.update(function(j: number)
					local pos, x = at2(if j == 1 then tailT else headT)
					return { cf = alongCF(pos, x), width = ej.w * (if j == 1 then 0.5 else 1), alpha = 0.02, color = P.tint }
				end)
			else
				ej.rib.hide()
			end
			if tau > ej.T and not ej.landed then
				ej.landed = true
				landHost.WorldPosition = ej.land + UP * 0.4
				landSparks:Emit(count(16))
			end
		end
	end)

	------------------------------------------------------------------------------------------------------
	-- Smoke: small black bits thrown off the mass, each gone in half a second; pale dust low on the floor
	local shell = c:part({ Size = Vector3.new(R * 2.3, R * 0.3, R * 1.7), CFrame = CFrame.new(C + UP * R * 0.3) })
	local smoke = emitter(shell, {
		slot = "own_sim_smoke", LightEmission = 0,
		Lifetime = NumberRange.new(0.28, 0.5), Speed = NumberRange.new(2 * k, 7 * k), SpreadAngle = Vector2.new(75, 75), Drag = 1.8,
		EmissionDirection = Enum.NormalId.Top,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-25, 25),
		Size = ns({ { 0, 1.1 * k, 0.4 * k }, { 1, 2.1 * k, 0.6 * k } }),
		Color = ColorSequence.new(P.soot),
		Transparency = ns({ { 0, 0.35 }, { 0.5, 0.5 }, { 1, 1 } }),
		ZOffset = -1.8,
	})
	stream(smoke, keys({ { 0.36, 0 }, { 0.46, 26 }, { 0.9, 22 }, { 1.3, 7 }, { 1.6, 0 } }))
	local dustDisc = c:part({ Size = Vector3.new(R * 1.2, 0.3, R * 1.2), CFrame = CFrame.new(C + UP * 0.5) })
	local dust = emitter(dustDisc, {
		slot = "smoke", LightEmission = 0,
		Lifetime = NumberRange.new(0.7, 1.1), Speed = NumberRange.new(8 * k, 15 * k), Drag = 2.6, RotSpeed = NumberRange.new(-30, 30),
		Shape = Enum.ParticleEmitterShape.Disc, ShapeInOut = OUTWARD, ShapeStyle = SURFACE,
		Size = ns({ { 0, 1.6 * k }, { 1, 4.4 * k } }),
		Color = ColorSequence.new(P.dust),
		Transparency = ns({ { 0, 1 }, { 0.2, 0.84 }, { 1, 1 } }),
		ZOffset = -1,
	})
	at(0.3, function()
		dust:Emit(count(12))
	end)
	at(0.6, function()
		dust:Emit(count(10))
	end)

	------------------------------------------------------------------------------------------------------
	-- Aftermath on the floor: a scorch and thin lava cracks (a deep layer under a hot one), small fires. Kept
	-- modest: a bright plate of lava outshines the fires that sit on it.
	local patchYaw = rng:NextNumber(0, TAU)
	local scorch = floorQuad("own_scorch", { LightEmission = 0, ZOffset = -0.2 })
	local lavaDeep = floorQuad("own_cracks", { LightEmission = 0.5, ZOffset = 0 })
	local lavaHot = floorQuad("own_cracks", { LightEmission = 1, Brightness = 3, ZOffset = 0.05 })
	local scorchA = keys({ { 0.2, 1 }, { 0.34, 0.2 }, { 3.2, 0.3 }, { 4.05, 1 } })
	local scorchColor = Color3.new(0, 0, 0)
	local heatK = keys({ { 0.2, 0 }, { 0.36, 1 }, { 1.0, 0.9 }, { 2.4, 0.7 }, { 3.2, 0.36 }, { 3.75, 0.12 }, { 4.05, 0 } })
	every(function(t)
		scorch.set(C + UP * 0.04, R * 1.5, scorchA(t), scorchColor, patchYaw + 1.3)
		local heat = heatK(t) * (1 + 0.08 * Kit.noise(21, t * 3))
		local cool = 1 - math.clamp(heat, 0, 1)
		local grow = 0.75 + 0.25 * smooth(0.2, 0.45, t)
		lavaDeep.set(C + UP * 0.07, R * 1.5 * grow, 1 - math.clamp(heat * 1.4, 0, 1) * 0.85, P.red:Lerp(P.dark, cool), patchYaw)
		lavaHot.beam.Brightness = 0.6 + 2.6 * math.clamp(heat, 0, 1) ^ 2 -- cooling: yellow core to orange to red
		lavaHot.set(C + UP * 0.1, R * 1.5 * grow, 1 - math.clamp(heat, 0, 1) ^ 0.8 * 0.9, P.tint, patchYaw)
	end)
	for i = 1, (if calm then 3 else 5) do
		local a = (i + rng:NextNumber(-0.3, 0.3)) / 5 * TAU
		fireSpot(C + dirAt(a) * R * rng:NextNumber(0.15, 0.85), 0.7 + rng:NextNumber(0, 0.3), 2.3 + rng:NextNumber(0, 1.0), rng:NextNumber(0.8, 1.2))
	end

	------------------------------------------------------------------------------------------------------
	-- one-shot events
	table.sort(events, function(a, b)
		return a.t < b.t
	end)
	local nextEvent = 1
	every(function(t)
		while events[nextEvent] and t >= events[nextEvent].t do
			events[nextEvent].fn()
			nextEvent += 1
		end
	end)

	c:play()
	return c
end

return GroundBlast
