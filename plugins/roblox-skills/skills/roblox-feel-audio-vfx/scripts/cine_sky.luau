--!nonstrict
-- cine_sky: a sky to stage a cutscene in (a flight, a reveal, a power-up above the map), and the way back.
-- It lifts the scene to a stage high over the map, where the camera sees real cloud shapes, a horizon and a low
-- sun instead of the map or one colour of fog, sets Lighting, Atmosphere, Clouds and a grade from a measured
-- preset, and restores everything it touched when the cutscene ends or is skipped.
-- Client only (Lighting changes made on a client stay on that client). roblox-feel-audio-vfx section 3e.
--
-- local Sky = require(script.Parent.cine_sky)
-- local sky = Sky.enter("sunset", { focus = rootPart.Position })   -- saves the game's look, applies the preset
-- character:PivotTo(sky.origin)            -- the stage: 1,200 studs over the focus; anchor the root there
-- sky:to("gold", 0.5)                      -- cross to another preset (a tier colour step at the peak)
-- local wind = sky:wind({ dir = Vector3.new(-1, 0, 0), speed = 150 })   -- wind streaks past a travel shot
-- wind.stop()
-- sky:leave()                              -- everything back as it was
--
-- Presets (Sky.PRESETS; copy one and change it for your own):
--   void    black, no sky: the dark start of a reveal. Light the character with your own rim lights.
--   sunset  low sun, peach clouds over a blue sky, warm light on the character (ClockTime 17.5)
--   gold    the same sky pushed warmer and brighter: the peak
--   day     noon, white clouds
--   night   moon and stars, blue ambient
-- Sky.sunDirection() is the unit vector to the sun (to frame it, or to rim-light against it).
--
-- Measured in Studio 0.748 Play, 2026-11-21, a blank place, camera 1,200 studs up:
-- - With the game's Sky object taken out the engine draws its default sky; a Clouds object under Terrain (Cover
--   0.62, Density 0.8) drew a broken cloud deck with a lit and a shaded side, and the baseplate under the camera
--   was hidden by the haze of an Atmosphere of Density 0.3.
-- - Atmosphere Density 0.42 with Haze 2.2 and a warm Color turned the same view into flat pink with teal
--   patches (the haze replaced the sky). Keep Density at 0.3 or under and Haze near 1.2-1.4.
-- - At ClockTime 17.5 the sun sits 5-7 degrees over the horizon; at 17.8 it is 3 degrees up and the cloud deck
--   goes dull.
-- - night: with saturated blue ambient colours the clouds and the skin went pure blue; the values here are the
--   second try (greyer ambient, saturation -0.1). sunset and night were read on captures with an avatar on the
--   stage; gold, day and void were not captured on their own.
-- - gold: with ExposureCompensation 0.25 and bloom 0.55 over a threshold of 1.1, a builder's hero shot under it was
--   judged blown out (face and outfit washed out); the values here are the second try, not captured in a cutscene.
-- - Higher is not better: at 3,000 studs the deck is still overhead with empty haze below, and at 9,000 the deck is
--   gone (a bare sun and thin wisps). The engine gives no cloud sea to look down on.
-- Limits: the cloud deck is the engine's (no control over single clouds); the stage does not hide a map taller
-- than about 800 studs (pass opts.height); not measured on a phone.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FxTextures = require(script.Parent.fx_textures)

local Sky = {}

local C = Color3.fromRGB

-- every value a preset sets; a cross-fade tweens the numbers and colours and sets the rest at its start
Sky.PRESETS = {
	void = {
		lighting = { ClockTime = 0, Brightness = 0, Ambient = C(0, 0, 0), OutdoorAmbient = C(0, 0, 0), ColorShift_Top = C(0, 0, 0), ExposureCompensation = 0 },
		atmosphere = { Density = 1, Offset = 1, Color = C(0, 0, 0), Decay = C(0, 0, 0), Glare = 0, Haze = 0 },
		clouds = { Enabled = false, Cover = 0, Density = 0, Color = C(0, 0, 0) },
		grade = { Brightness = 0, Contrast = 0.1, Saturation = 0, TintColor = C(255, 255, 255) },
		bloom = { Intensity = 0.7, Size = 24, Threshold = 0.9 },
	},
	sunset = {
		lighting = { ClockTime = 17.5, Brightness = 2.4, Ambient = C(96, 78, 110), OutdoorAmbient = C(150, 122, 140), ColorShift_Top = C(255, 196, 140), ExposureCompensation = 0.1 },
		atmosphere = { Density = 0.3, Offset = 0.2, Color = C(255, 190, 140), Decay = C(160, 96, 150), Glare = 0.45, Haze = 1.2 },
		clouds = { Enabled = true, Cover = 0.62, Density = 0.8, Color = C(255, 220, 198) },
		grade = { Brightness = 0, Contrast = 0.12, Saturation = 0.2, TintColor = C(255, 248, 242) },
		bloom = { Intensity = 0.45, Size = 24, Threshold = 1.2 },
	},
	gold = {
		lighting = { ClockTime = 17.5, Brightness = 2.9, Ambient = C(120, 92, 96), OutdoorAmbient = C(176, 138, 120), ColorShift_Top = C(255, 206, 120), ExposureCompensation = 0.1 },
		atmosphere = { Density = 0.28, Offset = 0.25, Color = C(255, 204, 128), Decay = C(180, 110, 120), Glare = 0.6, Haze = 1.3 },
		clouds = { Enabled = true, Cover = 0.58, Density = 0.8, Color = C(255, 226, 180) },
		grade = { Brightness = 0.02, Contrast = 0.16, Saturation = 0.3, TintColor = C(255, 244, 226) },
		bloom = { Intensity = 0.4, Size = 28, Threshold = 1.5 },
	},
	day = {
		lighting = { ClockTime = 13.5, Brightness = 2.6, Ambient = C(110, 118, 132), OutdoorAmbient = C(150, 158, 170), ColorShift_Top = C(255, 250, 240), ExposureCompensation = 0 },
		atmosphere = { Density = 0.26, Offset = 0.15, Color = C(205, 226, 255), Decay = C(120, 150, 200), Glare = 0.2, Haze = 1 },
		clouds = { Enabled = true, Cover = 0.55, Density = 0.75, Color = C(255, 255, 255) },
		grade = { Brightness = 0, Contrast = 0.08, Saturation = 0.12, TintColor = C(255, 255, 255) },
		bloom = { Intensity = 0.35, Size = 24, Threshold = 1.3 },
	},
	night = {
		lighting = { ClockTime = 0.5, Brightness = 1.8, Ambient = C(74, 80, 112), OutdoorAmbient = C(104, 112, 156), ColorShift_Top = C(150, 170, 255), ExposureCompensation = 0.5 },
		atmosphere = { Density = 0.24, Offset = 0.1, Color = C(84, 96, 140), Decay = C(30, 34, 70), Glare = 0.1, Haze = 0.8 },
		clouds = { Enabled = true, Cover = 0.5, Density = 0.7, Color = C(170, 178, 214) },
		grade = { Brightness = 0, Contrast = 0.14, Saturation = -0.1, TintColor = C(226, 232, 255) },
		bloom = { Intensity = 0.6, Size = 26, Threshold = 1 },
	},
}

function Sky.sunDirection(): Vector3
	return Lighting:GetSunDirection()
end

local function lerp(a, b, k)
	if typeof(a) == "number" then
		return a + (b - a) * k
	elseif typeof(a) == "Color3" then
		return a:Lerp(b, k)
	end
	return k < 1 and a or b
end

local current = nil

-- opts: focus (Vector3: the stage is straight above it; default the camera's focus), height (studs above the
-- focus, default 1200), hide ({ Instance }: models to make invisible on this client while the cutscene runs)
function Sky.enter(preset: string, opts)
	if current then
		current:leave()
	end
	opts = opts or {}
	local self = { alive = true }
	local saved = { props = {}, parents = {}, enabled = {}, hidden = {} }

	-- the game's own look: remembered, then taken out of the way
	for name in Sky.PRESETS.sunset.lighting do
		saved.props[name] = (Lighting :: any)[name]
	end
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("Sky") then
			saved.parents[child] = child.Parent
			child.Parent = nil
		elseif child:IsA("PostEffect") then
			saved.enabled[child] = child.Enabled
			child.Enabled = false
		end
	end
	local terrain = workspace.Terrain
	local oldClouds = terrain:FindFirstChildOfClass("Clouds")
	if oldClouds then
		saved.parents[oldClouds] = oldClouds.Parent
		oldClouds.Parent = nil
	end
	for _, model in opts.hide or {} do
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
				saved.hidden[d] = d.LocalTransparencyModifier
				d.LocalTransparencyModifier = 1
			end
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "CineSkyAtmosphere"
	atmosphere.Parent = Lighting
	local clouds = Instance.new("Clouds")
	clouds.Name = "CineSkyClouds"
	clouds.Parent = terrain
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "CineSkyGrade"
	grade.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "CineSkyBloom"
	bloom.Parent = Lighting
	self.atmosphere, self.clouds, self.grade, self.bloom = atmosphere, clouds, grade, bloom
	local targets = { lighting = Lighting, atmosphere = atmosphere, clouds = clouds, grade = grade, bloom = bloom }

	local function apply(from, to, k)
		for group, inst in targets do
			for name, value in to[group] do
				local a = from and from[group][name]
				;(inst :: any)[name] = a ~= nil and lerp(a, value, k) or value
			end
		end
	end

	local focus = opts.focus or (workspace.CurrentCamera and workspace.CurrentCamera.Focus.Position) or Vector3.zero
	self.origin = CFrame.new(focus.X, focus.Y + (opts.height or 1200), focus.Z)
	self.preset = Sky.PRESETS[preset] or Sky.PRESETS.sunset
	apply(nil, self.preset, 1)

	local fadeConn: RBXScriptConnection? = nil
	-- cross to another preset over `seconds` (0 or nil: at once, a cut)
	function self:to(name: string, seconds: number?)
		local from, to = self.preset, Sky.PRESETS[name]
		if not (self.alive and to) then
			return
		end
		self.preset = to
		if fadeConn then
			fadeConn:Disconnect()
			fadeConn = nil
		end
		if not seconds or seconds <= 0 then
			apply(nil, to, 1)
			return
		end
		local t0 = os.clock()
		fadeConn = RunService.PreRender:Connect(function()
			local k = math.clamp((os.clock() - t0) / seconds, 0, 1)
			apply(from, to, TweenService:GetValue(k, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
			if k >= 1 and fadeConn then
				fadeConn:Disconnect()
				fadeConn = nil
			end
		end)
	end

	-- Wind streaks that stream past the stage: the speed of a travel shot and the near layer of the sky's depth
	-- (the cloud deck is the far layer). Thin bright streaks, a few on screen at a time: soft cloud puffs here
	-- read as blobs on a capture, and many of them as fog.
	-- opts: dir (unit vector the streaks move along: against the flight), speed (studs/s, default 150), rate
	-- (per second, default 14), color, reach (how far from the stage they pass, default 22 studs)
	local windParts = {}
	function self:wind(o)
		o = o or {}
		local dir = (o.dir or Vector3.new(-1, 0, 0)).Unit
		local speed, reach = o.speed or 150, o.reach or 22
		local part = Instance.new("Part")
		part.Name = "CineSkyWind"
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.Transparency = 1
		part.Size = Vector3.new(reach * 2, reach * 1.3, 1)
		-- a sheet upwind of the stage that faces along dir; particles leave its front face
		part.CFrame = CFrame.lookAt(self.origin.Position - dir * speed * 0.35, self.origin.Position)
		part.Parent = workspace
		local e = Instance.new("ParticleEmitter")
		FxTextures.apply(e, "streak")
		e.Rate = o.rate or 40
		e.Lifetime = NumberRange.new(0.7)
		e.Speed = NumberRange.new(speed * 0.85, speed * 1.15)
		e.EmissionDirection = Enum.NormalId.Front
		e.SpreadAngle = Vector2.new(0.5, 0.5)
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		-- VelocityParallel: Rotation 90 with a positive Squash runs the streak along its path. Measured: Rotation 0, or
		-- no Squash at size 3.5-5, drew soft blobs standing across the flight.
		e.Rotation = NumberRange.new(90)
		e.Squash = NumberSequence.new(2.2)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1, 0.4), NumberSequenceKeypoint.new(1, 1.5, 0.5) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(0.8, 0.45), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(o.color or Color3.new(1, 1, 1))
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Brightness = 2
		e.Parent = part
		table.insert(windParts, part)
		return {
			part = part,
			emitter = e,
			stop = function()
				e.Enabled = false
				task.delay(1, function()
					part:Destroy()
				end)
			end,
		}
	end

	function self:leave()
		if not self.alive then
			return
		end
		self.alive = false
		if fadeConn then
			fadeConn:Disconnect()
		end
		for _, part in windParts do
			part:Destroy()
		end
		atmosphere:Destroy()
		clouds:Destroy()
		grade:Destroy()
		bloom:Destroy()
		for name, value in saved.props do
			(Lighting :: any)[name] = value
		end
		for inst, parent in saved.parents do
			inst.Parent = parent
		end
		for effect, on in saved.enabled do
			effect.Enabled = on
		end
		for inst, value in saved.hidden do
			inst.LocalTransparencyModifier = value
		end
		if current == self then
			current = nil
		end
	end

	current = self
	return self
end

return Sky
