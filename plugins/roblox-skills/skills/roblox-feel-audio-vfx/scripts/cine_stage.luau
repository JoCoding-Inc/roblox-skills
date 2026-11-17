--!nonstrict
-- cine_stage: the neutral set and the colour palette of the cutscene examples (roblox-feel-audio-vfx section 3e).
-- Large grey floor tiles with dark grout (the low wides read their perspective from the tile lines), an overcast
-- grey sky made by grey walls and a ceiling at 380 studs plus legacy fog (an Atmosphere tinted the distance with
-- the sky's blue, measured), soft daylight with weak shadows and a bloom that only catches layers brighter than 1.
-- Near-zero saturation everywhere so the one effect hue (electric cyan) carries all the colour (the four public
-- showcase clips the numbers of section 3e were read from had stages of mean saturation 0.05-0.10).
--
-- Stage.setup()      client, idempotent: floor, sky box, Lighting, bloom and grade (it changes Lighting and
--                    removes the Atmosphere: a test place only, or replace it with your game's own stage)
-- Stage.buildRigs()  server Script or Studio Edit (Players:CreateHumanoidModelFromDescription): two R15 dummies in
--                    workspace.CineStage, Hero at (0, 3.19, 0) facing -Z and Target 7 studs ahead facing it, root
--                    anchored, every AnimationConstraint replaced by a Motor6D so pose_beats can pose them
--                    (added in the port: the demo did the same joint swap in its place file; ran from a server
--                    Script in Studio 0.748 Play, 2026-11-18: 15 Motor6Ds on the hero, pose_beats posed both)
-- Stage.hero(), Stage.target() return the two dummies. Stage.HUE is the palette every element reads: change it
-- here to recolour the whole cutscene.
-- A player's own character usually has Motor6D joints already; a rig with AnimationConstraint joints ignores
-- Motor6D.Transform writes (measured, section 3e) until its joints are converted as in buildRigs.

local Lighting = game:GetService("Lighting")

local Stage = {}

local C = Color3.fromRGB
Stage.HUE = {
	white = C(255, 255, 255),
	hot = C(220, 250, 255), -- white-cyan core
	cyan = C(70, 215, 255), -- body
	blue = C(30, 110, 255), -- deep edge
	navy = C(8, 22, 60), -- dark underlayer
	ink = C(0, 0, 0),
	smoke0 = C(92, 94, 100),
	smoke1 = C(150, 152, 156),
}

Stage.TILE = 16
Stage.N = 14

function Stage.hero()
	return workspace:WaitForChild("CineStage"):WaitForChild("Hero")
end

function Stage.target()
	return workspace:WaitForChild("CineStage"):WaitForChild("Target")
end

-- Two R15 dummies with Motor6D joints (server or Edit). The examples were captured on these.
function Stage.buildRigs()
	local old = workspace:FindFirstChild("CineStage")
	if old then
		return old
	end
	local Players = game:GetService("Players")
	local folder = Instance.new("Folder")
	folder.Name = "CineStage"
	local spec = {
		{ name = "Hero", cf = CFrame.new(0, 3.192, 0), color = C(88, 91, 101), head = C(108, 111, 122) },
		{ name = "Target", cf = CFrame.new(0, 3.192, -7) * CFrame.Angles(0, math.pi, 0), color = C(196, 193, 188) },
	}
	for _, s in spec do
		local m = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
		m.Name = s.name
		-- AnimationConstraint joints (physics-driven) ignore Motor6D.Transform: replace each by a Motor6D with
		-- Part0/Part1 = the attachments' parents and C0/C1 = their CFrames; drop the ball sockets
		local list = m:GetDescendants()
		for _, d in list do
			if d:IsA("AnimationConstraint") then
				local a0, a1 = d.Attachment0, d.Attachment1
				local mo = Instance.new("Motor6D")
				mo.Name = d.Name
				mo.Part0 = a0.Parent
				mo.Part1 = a1.Parent
				mo.C0 = a0.CFrame
				mo.C1 = a1.CFrame
				mo.Parent = a1.Parent
				d:Destroy()
			elseif d:IsA("BallSocketConstraint") then
				d:Destroy()
			end
		end
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				d.Color = if d.Name == "Head" and s.head then s.head else s.color
			elseif d:IsA("BodyColors") then
				d:Destroy()
			end
		end
		local root = m:FindFirstChild("HumanoidRootPart")
		root.Anchored = true
		m.PrimaryPart = root
		m:PivotTo(s.cf)
		m.Parent = folder
	end
	folder.Parent = workspace
	return folder
end

local function setProps(inst, props)
	for k, v in props do
		inst[k] = v
	end
	return inst
end

local function ensure(className, parent, name)
	local i = parent:FindFirstChild(name)
	if not i then
		i = Instance.new(className)
		i.Name = name
		i.Parent = parent
	end
	return i
end

function Stage.setup()
	-- Floor: N x N tiles of TILE studs with 0.5-stud dark grout (thinner lines vanished in the low wides), top at
	-- y = 0.02 (over the baseplate).
	if not workspace:FindFirstChild("CineFloor") then
		local floor = Instance.new("Model")
		floor.Name = "CineFloor"
		local half = Stage.N * Stage.TILE / 2
		for i = 0, Stage.N - 1 do
			for j = 0, Stage.N - 1 do
				local p = Instance.new("Part")
				p.Anchored = true
				p.Locked = true
				p.CastShadow = false
				p.Material = Enum.Material.SmoothPlastic
				p.Size = Vector3.new(Stage.TILE - 0.5, 1, Stage.TILE - 0.5)
				p.Position = Vector3.new(-half + (i + 0.5) * Stage.TILE, -0.48, -half + (j + 0.5) * Stage.TILE)
				local v = ((i + j) % 2 == 0) and 0 or 7
				p.Color = C(122 + v, 124 + v, 128 + v)
				p.Name = "Tile"
				p.Parent = floor
			end
		end
		local grout = Instance.new("Part")
		grout.Name = "Grout"
		grout.Anchored = true
		grout.Locked = true
		grout.CastShadow = false
		grout.Material = Enum.Material.SmoothPlastic
		grout.Color = C(40, 41, 44)
		grout.Size = Vector3.new(Stage.N * Stage.TILE, 1, Stage.N * Stage.TILE)
		grout.Position = Vector3.new(0, -0.53, 0)
		grout.Parent = floor
		floor.Parent = workspace
	end

	-- Sky: a dense Atmosphere fades distant geometry into the sky texture's colour (blue: measured), so the
	-- Atmosphere is removed, a grey box of walls and a ceiling (CastShadow off) closes the set at 380 studs and
	-- the legacy fog (active only without an Atmosphere) fades floor and walls into one flat grey.
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		atm:Destroy()
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky.CelestialBodiesShown = false
		sky.StarCount = 0
	end
	if not workspace:FindFirstChild("CineSkyBox") then
		local m = Instance.new("Model")
		m.Name = "CineSkyBox"
		local R = 380
		for _, d in {
			{ Vector3.new(R, 0, 0), Vector3.new(4, 1200, 1200) },
			{ Vector3.new(-R, 0, 0), Vector3.new(4, 1200, 1200) },
			{ Vector3.new(0, 0, R), Vector3.new(1200, 1200, 4) },
			{ Vector3.new(0, 0, -R), Vector3.new(1200, 1200, 4) },
			{ Vector3.new(0, R, 0), Vector3.new(1200, 4, 1200) },
		} do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CastShadow = false
			p.Locked = true
			p.Material = Enum.Material.SmoothPlastic
			p.Color = C(166, 168, 172)
			p.Size = d[2]
			p.Position = d[1]
			p.Parent = m
		end
		m.Parent = workspace
	end
	setProps(Lighting, {
		ClockTime = 13.2,
		Brightness = 1.4,
		-- r2 (ground burst): debris sides lit only by ambient came out near black against the floor they were cut
		-- from; brighter ambient keeps them reading as the same grey stone
		Ambient = C(135, 135, 139),
		OutdoorAmbient = C(148, 148, 152),
		EnvironmentDiffuseScale = 0, -- the sky texture tinted the dummies blue (measured)
		EnvironmentSpecularScale = 0,
		GlobalShadows = true,
		ShadowSoftness = 0.6,
		ExposureCompensation = 0,
		FogColor = C(166, 168, 172),
		FogStart = 40,
		FogEnd = 400,
	})
	local bloom = ensure("BloomEffect", Lighting, "CineBloom")
	setProps(bloom, { Intensity = 0.9, Size = 28, Threshold = 1.05, Enabled = true })
	-- The base grade: slight contrast and a small saturation cut (the effect hue stays vivid).
	local grade = ensure("ColorCorrectionEffect", Lighting, "CineGrade")
	setProps(grade, { Contrast = 0.08, Saturation = -0.15, Brightness = 0, TintColor = C(255, 255, 255), Enabled = true })
	for _, d in workspace:WaitForChild("CineStage"):GetDescendants() do
		if d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
end

return Stage
