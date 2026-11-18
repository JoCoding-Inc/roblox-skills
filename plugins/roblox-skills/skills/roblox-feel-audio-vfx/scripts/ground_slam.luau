--!nonstrict
-- ground_slam: a ground slam in white, grey and black (roblox-feel-audio-vfx section 3h): the floor breaks into
-- polygon slabs that pop up, hold and flatten back to hairline cracks; smoke puffs stop in place and erode into
-- curls; pale haze, thin wind arcs, a pillar flash, white spikes, a two-frame black-and-white impact frame and a
-- short camera shake.
-- Timing and layer order follow a reference clip of a similar move, read frame by frame next to captures of this
-- one; every texture and the slab kit are made for it (ground_slam_textures.py, ground_slam_crater_kit.py).
-- Needs fx_clock and fx_textures. GroundSlam.play(cframe, { radius, timeScale, seed, ignore, layers,
-- reducedMotion }?) -> clock. Client only. Call GroundSlam.preload() once before the first cast.
--
-- Textures: run ground_slam_textures.py, upload the five PNG files as Images to your own account or group and put
-- the ids into the ModuleScript fx_own_textures next to this one (names slam_puff_a, slam_puff_b, slam_plume,
-- slam_wisp_a, slam_wisp_b), or call GroundSlam.setTextures({ slam_puff_a = 123, ... }). While an id is missing
-- the smoke and haze layers cannot be drawn: play() raises an error that lists the names, unless both layers are
-- switched off.
-- Crater kit: run ground_slam_crater_kit.py, upload the FBX as a Model and build the template its header describes
-- (a Model named CraterKit in a folder FxMeshTemplates in ReplicatedStorage). Without it play() raises an error
-- unless the crater layer is switched off.
--
-- How the two main layers work:
--   * smoke: flipbook particles (Grid4x4, OneShot) whose frames carry the erosion: holes open inside the puff and
--     curls and rings are left. A ParticleEmitter can only fade a sprite, so the dissolve has to be in the frames.
--     Each puff is ONE particle on its own attachment, thrown a short way and stopped by Drag within about 0.2 s.
--   * crater: nothing is cut out of the floor. Slabs cloned from the kit sit 0.03 studs above it in its colour and
--     material (a flat slab cannot be told from the floor), a dark disc under their tops shows through the gaps as
--     crack lines, and a tilted slab rests on its low edge. A floor Part's tiled Texture is carried across the tops.
-- layers (all on unless set to false): crater, smoke, haze, wind, flash, spikes, frame, shake.
--   frame is a full-screen ColorCorrectionEffect for 0.05 s and shake moves workspace.CurrentCamera for 0.2 s:
--   both are skipped with reducedMotion = true; keep them for the player's own cast only (section 3b).
-- Ran in Studio 0.748 Play on 2026-11-18 (desktop view, a grey checker floor under a day sky); not checked in a
-- published game, on a phone preset or on a real phone; frame cost not measured; flat floors only.
-- One cast: 76 slab MeshParts for 2.25 s (PivotTo on each for about 0.3 s twice), 22 emitters with 25 particles,
-- 15 beams, 1 ColorCorrectionEffect.
--
-- Beats (clock seconds at timeScale 1; the impact is at 0.10):
--   0.10  impact frame: black and white for two frames, a white pillar and a white line across the floor; the
--         slabs are already up (overshoot 1.3 in 0.04 s, settled by 0.34)
--   0.15  white spikes for three frames; haze, puffs and the plume leave; wind arcs start
--   0.30  the smoke has stopped moving; from here only its flipbook changes it
--   0.60  holes open in the puffs; curls and rings by 0.9; gone by 1.15
--   1.80  the slabs flatten over 0.3 s; hairline cracks for 0.15 s; clean at 2.25
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local GroundSlam = {}
GroundSlam.T0 = 0.10 -- the impact frame, clock seconds
-- the beats of the example strip
GroundSlam.CAPTURE_TIMES = { 0.10, 0.13, 0.17, 0.23, 0.30, 0.43, 0.60, 0.73, 0.83, 0.98, 1.13, 1.50, 1.95, 2.07, 2.15, 2.22 }
GroundSlam.DURATION = 2.4

local UP = Vector3.yAxis
local ns, cs = FxClock.ns, FxClock.cs

-- Own textures: slot "own_<name>". There is no stand-in (section 3: a layer whose texture is missing is left out
-- or refused, never drawn with a stretched public texture).
local OWN = { "slam_puff_a", "slam_puff_b", "slam_plume", "slam_wisp_a", "slam_wisp_b" }
GroundSlam.usesOwnTextures = false
GroundSlam.missingTextures = {} :: { string }
-- ids: { name = asset id number }, the names of the files ground_slam_textures.py writes.
function GroundSlam.setTextures(ids: { [string]: number })
	local missing = {}
	for _, name in OWN do
		local id = ids[name]
		if id and id ~= 0 then
			FxTextures.slots["own_" .. name] = { { id = "rbxassetid://" .. tostring(id), note = "own art: " .. name, flipbook = "Grid4x4" } }
		else
			FxTextures.slots["own_" .. name] = nil
			table.insert(missing, name)
		end
	end
	GroundSlam.missingTextures = missing
	GroundSlam.usesOwnTextures = #missing == 0
end
local ownModule = script.Parent:FindFirstChild("fx_own_textures")
GroundSlam.setTextures(if ownModule then require(ownModule) else {})

local function craterKit(): Instance?
	local folder = ReplicatedStorage:FindFirstChild("FxMeshTemplates")
	return folder and folder:FindFirstChild("CraterKit")
end

-- Loads the five textures and the kit's meshes. Without it the first cast shows the dark underlay before the slabs.
function GroundSlam.preload()
	local list = {}
	for _, name in OWN do
		local slot = FxTextures.slots["own_" .. name]
		if slot then
			table.insert(list, slot[1].id)
		end
	end
	local kit = craterKit()
	if kit then
		table.insert(list, kit)
	end
	game:GetService("ContentProvider"):PreloadAsync(list)
end

-- Smoke: every number here can be changed between casts (GroundSlam.SMOKE.puffs = 6).
GroundSlam.SMOKE = {
	blend = true, -- FlipbookBlendFrames
	-- dark puffs: a ring of single particles, thrown out a little, stopped by drag, eroded by their flipbook
	puffs = 9, puffRing = { 0.35, 0.95 }, puffY = { 1.2, 3.0 }, puffUp = { 0.15, 0.7 },
	puffSpeed = { 9, 20 }, puffDrag = 5.5, puffLife = { 0.8, 1.05 }, puffSize = { 4.2, 6.2, 6.9 }, puffVary = 0.3,
	puffColors = {
		{ Color3.fromRGB(150, 152, 160), Color3.fromRGB(126, 128, 136) },
		{ Color3.fromRGB(178, 180, 188), Color3.fromRGB(150, 152, 160) },
		{ Color3.fromRGB(122, 124, 132), Color3.fromRGB(100, 102, 110) },
	},
	puffAlpha = { 0.2, 0.3, 0.5 },
	-- the plume: a few taller puffs that climb out of the middle
	plume = 4, plumeSpeed = { 14, 30 }, plumeDrag = 3.4, plumeLife = { 0.75, 1.0 }, plumeSize = { 7, 11, 12.5 },
	plumeColor0 = Color3.fromRGB(118, 120, 128), plumeColor1 = Color3.fromRGB(94, 96, 104), plumeAlpha = { 0.22, 0.34, 0.55 },
	-- pale haze: big soft swirls, mostly see-through
	haze = 12, hazeRing = { 0.1, 1.05 }, hazeY = { 1.0, 4.5 }, hazeSpeed = { 10, 26 }, hazeDrag = 4.5,
	hazeLife = { 0.55, 0.9 }, hazeSize = { 7, 12, 14 }, hazeVary = 0.35,
	hazeColor = Color3.fromRGB(238, 240, 245), hazeAlpha = { 0.5, 0.66, 0.9 },
}

-- Crater: the kit of polygon slabs (unit radius 1) is cloned over the floor and scaled.
GroundSlam.CRATER = {
	scale = 1.25, -- kit radius 1 in units of R (the kit's cells reach 1.68)
	thick = 0.85, -- slab thickness against the kit's (0.1 of the kit radius)
	underlay = Color3.fromRGB(36, 41, 56),
	bowl = 0.34, ring = 0.95, -- zone limits in kit radius
	bowlTilt = { 10, 26 }, bowlLift = { 0.0, 0.15 }, bowlHinge = 0.55,
	ringTilt = { 10, 24 }, ringLift = { 0.05, 0.3 }, ringHinge = 1.0,
	outerTilt = { 0, 1.5 }, outerLift = { 0.0, 0.03 }, outerLoose = 0.35, outerLooseTilt = { 3, 7 },
	ripple = 0.04, rise = 0.04, settle = 0.2, overshoot = 1.3,
	hold = 1.7, flatten = 0.3, cracksFade = 0.15,
}

local function perp(v: Vector3): Vector3
	local a = if math.abs(v.Y) < 0.9 then UP else Vector3.xAxis
	return v:Cross(a).Unit
end

function GroundSlam.play(cf: CFrame, opts)
	opts = opts or {}
	local R: number = opts.radius or 8
	local speed: number = opts.timeScale or 1
	local layers = {}
	for _, name in { "crater", "smoke", "haze", "wind", "flash", "spikes", "frame", "shake" } do
		layers[name] = not (opts.layers and opts.layers[name] == false)
	end
	if opts.reducedMotion then
		layers.frame, layers.shake = false, false
	end
	local kit = craterKit()
	if (layers.smoke or layers.haze) and not GroundSlam.usesOwnTextures then
		error("ground_slam needs its smoke textures: run ground_slam_textures.py, upload the files and fill fx_own_textures (missing: " .. table.concat(GroundSlam.missingTextures, ", ") .. "), or switch the smoke and haze layers off", 2)
	end
	if layers.crater and not kit then
		error("ground_slam needs ReplicatedStorage.FxMeshTemplates.CraterKit (ground_slam_crater_kit.py), or switch the crater layer off", 2)
	end
	local k = R / 8
	local rng = Random.new(opts.seed or 5)
	local T0 = GroundSlam.T0
	local S, K = GroundSlam.SMOKE, GroundSlam.CRATER
	local c = FxClock.new("GroundSlam", (GroundSlam.DURATION + 0.05) / speed)
	local C = cf.Position
	local events = {}
	local steps = {}
	local function at(t0: number, fn)
		table.insert(events, { t = t0, fn = fn })
	end
	local function emitter(parent: Instance, props)
		props = table.clone(props)
		local lt: NumberRange = props.Lifetime
		props.Lifetime = NumberRange.new(lt.Min / speed, lt.Max / speed)
		if props.Speed then
			props.Speed = NumberRange.new(props.Speed.Min * speed, props.Speed.Max * speed)
		end
		if props.Drag then
			props.Drag = props.Drag * speed
		end
		local slot = props.slot
		props.slot = nil
		local e = c:emitter(parent, props)
		FxTextures.apply(e, slot)
		e.FlipbookBlendFrames = S.blend
		return e
	end
	local function rr(range): number
		return rng:NextNumber(range[1], range[2])
	end

	------------------------------------------------------------------------------------------------------
	-- The floor under the centre: its top, colour and material (the slabs take them).
	local floorY, floorColor, floorMaterial, floorVariant = C.Y, Color3.fromRGB(110, 114, 124), Enum.Material.SmoothPlastic, ""
	local floorPart, floorTexture = nil, nil
	do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip = { workspace:FindFirstChild("FxRuntime") }
		for _, inst in opts.ignore or {} do
			table.insert(skip, inst)
		end
		for _, pl in game:GetService("Players"):GetPlayers() do
			if pl.Character then
				table.insert(skip, pl.Character)
			end
		end
		params.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(C + UP * 6, -UP * 40, params)
		if hit then
			floorY = hit.Position.Y
			local inst = hit.Instance
			if inst:IsA("Terrain") then
				floorMaterial = hit.Material
				floorColor = workspace.Terrain:GetMaterialColor(hit.Material)
			else
				floorColor, floorMaterial, floorVariant = inst.Color, inst.Material, inst.MaterialVariant
				for _, ch in inst:GetChildren() do
					if ch:IsA("Texture") and ch.Face == Enum.NormalId.Top then
						floorPart, floorTexture = inst, ch
					end
				end
			end
		end
	end
	local F = Vector3.new(C.X, floorY, C.Z)

	------------------------------------------------------------------------------------------------------
	-- Crater. Nothing is cut out of the floor: the slabs sit on it (tops 0.03 above, in its colour, so a flat slab
	-- cannot be told from the floor) and a dark disc lies just under their tops: it shows through the gaps as
	-- crack lines and under a lifted edge as shadow.
	if layers.crater and kit then
		local Rc = R * K.scale
		local slabs = {}
		local holder = Instance.new("Model")
		holder.Name = "Crater"
		for _, m in kit:GetChildren() do
			if not m:IsA("MeshPart") then
				continue
			end
			local p0 = m:GetPivot().Position
			local flat = Vector3.new(p0.X, 0, p0.Z)
			local rho = flat.Magnitude
			local d = if rho > 1e-3 then flat.Unit else Vector3.xAxis
			local s = m:Clone()
			local scale = Vector3.new(Rc, Rc * K.thick, Rc)
			s.Size = m.Size * scale
			s.PivotOffset = CFrame.new(m.PivotOffset.Position * scale) * m.PivotOffset.Rotation
			s.Color, s.Material, s.MaterialVariant = floorColor, floorMaterial, floorVariant
			s.CastShadow = true -- (the flat outer slabs switch it off below)
			s.Locked = true
			local tilt, lift, axis, hinge
			local tangent = UP:Cross(d)
			if rho < K.bowl then
				-- the bowl: faces lean toward the centre, the tilt axis turned up to 45 degrees off the tangent
				local yaw = math.rad(rng:NextNumber(-45, 45))
				axis = CFrame.fromAxisAngle(UP, yaw):VectorToWorldSpace(tangent)
				tilt, lift, hinge = -math.rad(rr(K.bowlTilt)), rr(K.bowlLift) * k, K.bowlHinge
			elseif rho < K.ring then
				-- the rim: the inner edge comes up, so the wall facing the centre shows
				local yaw = math.rad(rng:NextNumber(-25, 25))
				axis = CFrame.fromAxisAngle(UP, yaw):VectorToWorldSpace(tangent)
				tilt, lift, hinge = math.rad(rr(K.ringTilt)) * (1 - 0.5 * (rho - K.bowl) / (K.ring - K.bowl)), rr(K.ringLift) * k, K.ringHinge
			else
				-- outside: flat, cracks only; a few loose slabs tip a little
				axis = CFrame.fromAxisAngle(UP, rng:NextNumber(0, 6.28)):VectorToWorldSpace(tangent)
				local loose = rho < 1.25 and rng:NextNumber() < K.outerLoose
				tilt, lift, hinge = math.rad(rr(if loose then K.outerLooseTilt else K.outerTilt)), rr(K.outerLift) * k, 1
				if loose then
					tilt *= math.min(1, 4 * k / math.max(s.Size.X, s.Size.Z)) -- a wide slab tips less: its wall would be one long dark band
				else
					s.CastShadow = false
				end
			end
			-- a tilted slab rests on its low edge instead of sinking through the floor: lift by the drop of that edge
			lift += hinge * 0.5 * 0.8 * math.max(s.Size.X, s.Size.Z) * math.sin(math.abs(tilt))
			if floorTexture then
				-- carry the floor's tiled Texture: on a MeshPart it is laid from the part's centre in studs (measured:
				-- the mesh UVs are not used), so the offsets move its origin onto the floor's grid, which starts at the
				-- floor part's +X +Z top corner. Checked with a symmetric checker on an unrotated floor only.
				local t = floorTexture:Clone()
				local centre = Vector3.new(F.X + p0.X * Rc, 0, F.Z + p0.Z * Rc) - (CFrame.new(m.PivotOffset.Position * Rc)).Position
				local lp = floorPart.CFrame:PointToObjectSpace(Vector3.new(centre.X, floorPart.Position.Y, centre.Z))
				t.OffsetStudsU = floorTexture.OffsetStudsU + (floorPart.Size.X / 2 - lp.X) % t.StudsPerTileU
				t.OffsetStudsV = floorTexture.OffsetStudsV + (floorPart.Size.Z / 2 - lp.Z) % t.StudsPerTileV
				t.Parent = s
			end
			local rest = Vector3.new(F.X + p0.X * Rc, F.Y + 0.03, F.Z + p0.Z * Rc)
			s:PivotTo(CFrame.new(rest))
			s.Parent = holder
			table.insert(slabs, { part = s, rest = rest, axis = axis, tilt = tilt, lift = lift, roll = math.rad(rng:NextNumber(-7, 7)), d = d, delay = rho * K.ripple })
		end
		local under = c:part({
			Name = "CraterUnderlay", Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic, Color = K.underlay,
			Size = Vector3.new(0.03, 2 * 1.6 * Rc, 2 * 1.6 * Rc), CFrame = CFrame.new(F + UP * 0.0) * CFrame.Angles(0, 0, math.pi / 2),
			Transparency = 1,
		})
		local function pose(f: number, tLocal: number)
			for _, s in slabs do
				local g = f
				if tLocal < s.delay + K.rise + K.settle then
					local tau = tLocal - s.delay
					if tau <= 0 then
						g = 0
					elseif tau < K.rise then
						g = K.overshoot * FxClock.outCubic(tau / K.rise)
					else
						g = FxClock.lerp(K.overshoot, 1, FxClock.inOutSine(math.min((tau - K.rise) / K.settle, 1)))
					end
				end
				s.part:PivotTo(CFrame.new(s.rest + UP * (s.lift * g)) * CFrame.fromAxisAngle(s.axis, s.tilt * g) * CFrame.fromAxisAngle(s.d, s.roll * g))
			end
		end
		local tPop = K.ripple * 1.7 + K.rise + K.settle
		local tFlat0, tFlat1 = K.hold, K.hold + K.flatten
		local state = "wait"
		at(T0, function()
			under.Transparency = 0
			holder.Parent = c.model
			state = "pop"
		end)
		table.insert(steps, function(t)
			local tl = t - T0
			if state == "pop" then
				pose(1, tl)
				if tl >= tPop then
					state = "hold"
				end
			elseif state == "hold" and tl >= tFlat0 then
				state = "flatten"
			end
			if state == "flatten" then
				local u = math.clamp((tl - tFlat0) / K.flatten, 0, 1)
				pose(1 - FxClock.inOutSine(u), 1e3)
				if u >= 1 then
					state = "cracks"
				end
			elseif state == "cracks" then
				local u = math.clamp((tl - tFlat1) / K.cracksFade, 0, 1)
				under.Transparency = u
				if u >= 1 then
					holder:Destroy()
					state = "done"
				end
			end
		end)
	end

	------------------------------------------------------------------------------------------------------
	-- Smoke. Each puff is ONE particle on its own attachment (a random emitter shape put all of them on one side
	-- in a test), thrown a short way and stopped by drag; from then on only its flipbook changes it.
	local function ringBurst(n: number, ring, yRange, upRange, phase: number, make)
		for i = 1, n do
			local ang = ((i - 1 + rng:NextNumber(-0.35, 0.35)) / n) * math.pi * 2 + phase
			local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local pos = F + dir * (R * rr(ring)) + UP * (rr(yRange) * k)
			local vel = (dir + UP * rr(upRange)).Unit
			local a = c:attachment(CFrame.lookAt(pos, pos + perp(vel), vel))
			make(a, i)
		end
	end
	if layers.smoke then
		ringBurst(S.puffs, S.puffRing, S.puffY, S.puffUp, rng:NextNumber(0, 6.28), function(a, i)
			local col = S.puffColors[(i - 1) % #S.puffColors + 1]
			local m = 1 + rng:NextNumber(-S.puffVary, S.puffVary)
			local e = emitter(a, {
				slot = if i % 2 == 0 then "own_slam_puff_a" else "own_slam_puff_b", LightEmission = 0, LightInfluence = 0,
				EmissionDirection = Enum.NormalId.Top, Lifetime = NumberRange.new(S.puffLife[1], S.puffLife[2]),
				Speed = NumberRange.new(S.puffSpeed[1] * k, S.puffSpeed[2] * k), Drag = S.puffDrag,
				Rotation = NumberRange.new(-30, 30), RotSpeed = NumberRange.new(-10, 10),
				Size = ns({ { 0, S.puffSize[1] * k * m }, { 0.15, S.puffSize[2] * k * m }, { 1, S.puffSize[3] * k * m } }),
				Color = cs({ { 0, col[1] }, { 1, col[2] } }),
				Transparency = ns({ { 0, S.puffAlpha[1] }, { 0.6, S.puffAlpha[2] }, { 1, S.puffAlpha[3] } }),
			})
			at(T0 + 0.05 + rng:NextNumber(0, 0.05), function()
				e:Emit(1)
			end)
		end)
		local stem = c:part({ Size = Vector3.new(R * 0.22, 0.4, R * 0.22), CFrame = CFrame.new(F + UP * 2.4 * k) })
		local plume = emitter(stem, {
			slot = "own_slam_plume", LightEmission = 0, LightInfluence = 0,
			Lifetime = NumberRange.new(S.plumeLife[1], S.plumeLife[2]), Speed = NumberRange.new(S.plumeSpeed[1] * k, S.plumeSpeed[2] * k), Drag = S.plumeDrag,
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(9, 9), Rotation = NumberRange.new(-16, 16),
			Size = ns({ { 0, S.plumeSize[1] * k, 0.8 * k }, { 0.2, S.plumeSize[2] * k, 1.2 * k }, { 1, S.plumeSize[3] * k, 1.2 * k } }),
			Color = cs({ { 0, S.plumeColor0 }, { 1, S.plumeColor1 } }),
			Transparency = ns({ { 0, S.plumeAlpha[1] }, { 0.6, S.plumeAlpha[2] }, { 1, S.plumeAlpha[3] } }),
			ZOffset = -0.5,
		})
		at(T0 + 0.07, function()
			plume:Emit(S.plume)
		end)
	end
	if layers.haze then
		ringBurst(S.haze, S.hazeRing, S.hazeY, { 0.1, 0.9 }, rng:NextNumber(0, 6.28), function(a, i)
			local m = 1 + rng:NextNumber(-S.hazeVary, S.hazeVary)
			local e = emitter(a, {
				slot = if i % 2 == 0 then "own_slam_wisp_a" else "own_slam_wisp_b", LightEmission = 0, LightInfluence = 0,
				EmissionDirection = Enum.NormalId.Top, Lifetime = NumberRange.new(S.hazeLife[1], S.hazeLife[2]),
				Speed = NumberRange.new(S.hazeSpeed[1] * k, S.hazeSpeed[2] * k), Drag = S.hazeDrag,
				Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40),
				Size = ns({ { 0, S.hazeSize[1] * k * m }, { 0.2, S.hazeSize[2] * k * m }, { 1, S.hazeSize[3] * k * m } }),
				Color = ColorSequence.new(S.hazeColor),
				Transparency = ns({ { 0, S.hazeAlpha[1] }, { 0.5, S.hazeAlpha[2] }, { 1, S.hazeAlpha[3] } }),
				ZOffset = 0.3,
			})
			at(T0 + 0.02 + rng:NextNumber(0, 0.06), function()
				e:Emit(1)
			end)
		end)
	end

	------------------------------------------------------------------------------------------------------
	-- Wind arcs: thin white crescents that turn round the centre (a curved beam whose ends ride a circle).
	if layers.wind then
		for i = 1, 5 do
			local r = R * rng:NextNumber(0.55, 1.25)
			local y = rng:NextNumber(0.8, 4.2) * k
			local arc = math.rad(rng:NextNumber(70, 130))
			local w = rng:NextNumber(7, 12) * (if i % 2 == 0 then 1 else -1)
			local th0 = rng:NextNumber(0, 6.28)
			local tilt = CFrame.new(F + UP * y) * CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), 0, math.rad(rng:NextNumber(-12, 12)))
			local t0 = T0 + 0.04 + rng:NextNumber(0, 0.18)
			local len = rng:NextNumber(0.3, 0.55)
			local a0, a1 = c:attachment(), c:attachment()
			local handle = (4 / 3) * math.tan(arc / 4) * r
			local beam = c:beam(a0, a1, {
				FaceCamera = true, LightEmission = 0.6, Color = ColorSequence.new(Color3.new(1, 1, 1)),
				Width0 = 0.02, Width1 = 0.34 * k, CurveSize0 = handle, CurveSize1 = handle, Segments = 14,
				Transparency = NumberSequence.new(1), ZOffset = 0.2,
			})
			table.insert(steps, function(t)
				local u = (t - t0) / len
				if u < 0 or u > 1 then
					beam.Transparency = NumberSequence.new(1)
					return
				end
				local sgn = if w > 0 then 1 else -1
				local th = th0 + w * (t - t0) * (1 - 0.45 * u)
				local grow = 1 + 0.25 * u
				local function place(a: Attachment, ang: number)
					local p = Vector3.new(math.cos(ang), 0, math.sin(ang)) * r * grow
					local tan = Vector3.new(-math.sin(ang), 0, math.cos(ang)) * sgn
					a.WorldCFrame = tilt * CFrame.fromMatrix(p, tan, UP)
				end
				place(a0, th - sgn * arc)
				place(a1, th)
				local vis = math.sin(math.pi * math.clamp(u, 0, 1)) ^ 0.7
				local a = 1 - 0.75 * vis
				beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, a + (1 - a) * 0.4), NumberSequenceKeypoint.new(0.9, a), NumberSequenceKeypoint.new(1, 1),
				})
			end)
		end
	end

	------------------------------------------------------------------------------------------------------
	-- Pillar flash: a thin white line straight up for 0.1 s, a second thinner one at +0.10.
	if layers.flash then
		for i, def in { { 0, 0.11, 0.9 }, { 0.10, 0.07, 0.35 } } do
			local a0, a1 = c:attachment(CFrame.new(F)), c:attachment(CFrame.new(F + UP * 46 * k))
			local beam = c:beam(a0, a1, {
				FaceCamera = true, LightEmission = 1, Color = ColorSequence.new(Color3.new(1, 1, 1)), Width0 = def[3] * k, Width1 = 0.05,
				Transparency = NumberSequence.new(1), Segments = 1, ZOffset = 0.5,
			})
			table.insert(steps, function(t)
				local u = (t - T0 - def[1]) / def[2]
				beam.Transparency = NumberSequence.new(if u < 0 or u > 1 then 1 else u * u)
				beam.Width0 = def[3] * k * (1 - 0.7 * math.clamp(u, 0, 1))
			end)
		end
	end

	------------------------------------------------------------------------------------------------------
	-- Spike cone: a few tapered white blades out of the centre for three frames, and a white line across the floor.
	if layers.spikes then
		local cam = workspace.CurrentCamera
		local right = cam.CFrame.RightVector
		right = Vector3.new(right.X, 0, right.Z).Unit
		local l0, l1 = c:attachment(CFrame.new(F - right * R * 1.7 + UP * 0.15)), c:attachment(CFrame.new(F + right * R * 1.7 + UP * 0.15))
		local line = c:beam(l0, l1, {
			FaceCamera = true, LightEmission = 1, Color = ColorSequence.new(Color3.new(1, 1, 1)), Width0 = 0.5 * k, Width1 = 0.5 * k, Segments = 1,
			Transparency = NumberSequence.new(1), ZOffset = 0.4,
		})
		table.insert(steps, function(t)
			local u = (t - T0) / 0.07
			if u < 0 or u > 1 then
				line.Transparency = NumberSequence.new(1)
			else
				line.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, u), NumberSequenceKeypoint.new(1, 1) })
				line.Width0, line.Width1 = 0.5 * k * (1 - u), 0.5 * k * (1 - u)
			end
		end)
		for i = 1, 7 do
			local ang = (i + rng:NextNumber(-0.3, 0.3)) / 7 * math.pi * 2
			local dir = (Vector3.new(math.cos(ang), 0, math.sin(ang)) * rng:NextNumber(0.25, 0.75) + UP).Unit
			local len = rng:NextNumber(8, 15) * k
			local base = F + Vector3.new(math.cos(ang), 0, math.sin(ang)) * R * rng:NextNumber(0.05, 0.3)
			local a0, a1 = c:attachment(CFrame.new(base)), c:attachment(CFrame.new(base + dir * len))
			local w = rng:NextNumber(0.7, 1.3) * k
			local beam = c:beam(a0, a1, {
				FaceCamera = true, LightEmission = 0.9, Width0 = w, Width1 = 0, Segments = 1, ZOffset = 0.6,
				Color = ColorSequence.new(Color3.fromRGB(205, 210, 222), Color3.new(1, 1, 1)), Transparency = NumberSequence.new(1),
			})
			local t0, dur = T0 + 0.05 + rng:NextNumber(0, 0.02), 0.09
			table.insert(steps, function(t)
				local u = (t - t0) / dur
				if u < 0 or u > 1 then
					beam.Transparency = NumberSequence.new(1)
					return
				end
				a1.WorldPosition = base + dir * len * (0.55 + 0.45 * FxClock.outCubic(u))
				beam.Width0 = w * (1 - 0.6 * u)
				beam.Transparency = NumberSequence.new(0.05 + 0.95 * u * u)
			end)
		end
	end

	------------------------------------------------------------------------------------------------------
	-- Impact frame: two frames of hard black and white (a ColorCorrectionEffect), then back over 0.06 s. A
	-- full-screen flash: at most two a second (section 3b), and off with reducedMotion.
	if layers.frame then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "SlamImpactFrame"
		cc.Enabled = false
		cc.Parent = game:GetService("Lighting")
		c:onCleanup(function()
			cc:Destroy()
		end)
		table.insert(steps, function(t)
			local tl = t - T0
			if tl < 0 or tl > 0.11 then
				cc.Enabled = false
				return
			end
			local g = if tl < 0.05 then 1 else 1 - (tl - 0.05) / 0.06
			cc.Enabled = true
			cc.Saturation, cc.Contrast, cc.Brightness = -g, 0.85 * g, 0.1 * g
		end)
	end

	------------------------------------------------------------------------------------------------------
	-- Camera shake: 0.2 s, at most 0.3 studs and half a degree, falling off. The offset is taken back out on the
	-- next step when nothing else has moved the camera (a fixed camera would drift otherwise).
	if layers.shake then
		local cam = workspace.CurrentCamera
		local last, lastSet = CFrame.new(), nil
		local function undo()
			if lastSet and cam.CFrame:FuzzyEq(lastSet, 1e-4) then
				cam.CFrame = cam.CFrame * last:Inverse()
			end
			last, lastSet = CFrame.new(), nil
		end
		c:onCleanup(undo)
		table.insert(steps, function(t)
			local tl = t - T0
			undo()
			if tl < 0 or tl > 0.2 then
				return
			end
			local g = (1 - tl / 0.2) ^ 2
			last = CFrame.new(rng:NextNumber(-0.3, 0.3) * g * k, rng:NextNumber(-0.3, 0.3) * g * k, 0) * CFrame.Angles(math.rad(rng:NextNumber(-0.5, 0.5)) * g, 0, math.rad(rng:NextNumber(-0.5, 0.5)) * g)
			cam.CFrame = cam.CFrame * last
			lastSet = cam.CFrame
		end)
	end

	------------------------------------------------------------------------------------------------------
	table.sort(events, function(a, b)
		return a.t < b.t
	end)
	local nextEvent = 1
	c:every(function(t)
		t *= speed
		while events[nextEvent] and t >= events[nextEvent].t do
			events[nextEvent].fn()
			nextEvent += 1
		end
		for _, fn in steps do
			fn(t)
		end
	end)
	c:play()
	return c
end

return GroundSlam
