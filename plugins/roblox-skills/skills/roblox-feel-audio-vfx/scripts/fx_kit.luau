--!nonstrict
-- fx_kit: small builders shared by formation_seal and void_pillar (roblox-feel-audio-vfx section 3f). Everything is
-- a Beam driven by the effect clock, so a frame can be frozen and captured: blob (a camera-facing soft disc),
-- floorBlob, glint (a screen-space 4-point star), keyed curves, one palette from one hue, a texture warm-up.
-- Needs fx_clock and fx_textures. Client only (blob and glint read the current camera).
local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local Kit = {}

-- One hue gives the whole palette.
function Kit.palette(hue: number)
	local function hsv(h, s, v)
		return Color3.fromHSV(h % 1, s, v)
	end
	return {
		white = Color3.new(1, 1, 1),
		light = hsv(hue, 0.28, 1),
		body = hsv(hue, 0.8, 1),
		deep = hsv(hue + 0.04, 0.92, 0.6),
		dark = hsv(hue + 0.05, 0.9, 0.13),
		accentA = hsv(hue - 0.13, 0.65, 1),
		accentB = hsv(hue + 0.2, 0.55, 1),
	}
end

-- keys({ { t, v }, ... }) -> f(t): linear between keys, clamped at the ends.
function Kit.keys(points: { { number } })
	return function(t: number): number
		if t <= points[1][1] then
			return points[1][2]
		end
		for i = 2, #points do
			local a, b = points[i - 1], points[i]
			if t <= b[1] then
				return a[2] + (b[2] - a[2]) * (t - a[1]) / math.max(b[1] - a[1], 1e-6)
			end
		end
		return points[#points][2]
	end
end

-- Beam orientation (measured in Studio, see NOTES): the ribbon's width runs along the attachment's Y axis and the
-- beam leaves along its X axis. flat: a ribbon lying on the floor. upright: a ribbon standing on its edge.
function Kit.oriented(pos: Vector3, along: Vector3, widthAxis: Vector3): CFrame
	return CFrame.fromMatrix(pos, along, widthAxis)
end

local function camera(): Camera
	return workspace.CurrentCamera
end

-- A camera-facing soft disc: one short beam that carries the soft-circle texture once.
function Kit.blob(c, props: { [string]: any }?)
	local a0, a1 = c:attachment(), c:attachment()
	local b = c:beam(a0, a1, {
		FaceCamera = true,
		LightEmission = 1,
		Segments = 1,
		TextureMode = Enum.TextureMode.Stretch,
		TextureLength = 1,
		Enabled = false,
	})
	FxTextures.apply(b, "glow")
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	local o = { beam = b }
	function o.set(pos: Vector3, radius: number, alpha: number, color: Color3?)
		if alpha >= 0.995 or radius <= 0.001 then
			b.Enabled = false
			return
		end
		local up = camera().CFrame.UpVector
		a0.WorldPosition = pos - up * radius
		a1.WorldPosition = pos + up * radius
		b.Width0 = radius * 2
		b.Width1 = radius * 2
		b.Transparency = NumberSequence.new(math.clamp(alpha, 0, 1))
		if color then
			b.Color = ColorSequence.new(color)
		end
		b.Enabled = true
	end
	function o.hide()
		b.Enabled = false
	end
	return o
end

-- A soft disc lying on the floor (normal = up).
function Kit.floorBlob(c, props: { [string]: any }?)
	local a0, a1 = c:attachment(), c:attachment()
	local b = c:beam(a0, a1, {
		FaceCamera = false,
		LightEmission = 1,
		Segments = 1,
		TextureMode = Enum.TextureMode.Stretch,
		TextureLength = 1,
		Enabled = false,
	})
	FxTextures.apply(b, "glow")
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	local o = { beam = b }
	function o.set(pos: Vector3, radius: number, alpha: number, color: Color3?)
		if alpha >= 0.995 or radius <= 0.001 then
			b.Enabled = false
			return
		end
		a0.WorldCFrame = Kit.oriented(pos - Vector3.xAxis * radius, Vector3.xAxis, Vector3.zAxis)
		a1.WorldCFrame = Kit.oriented(pos + Vector3.xAxis * radius, Vector3.xAxis, Vector3.zAxis)
		b.Width0 = radius * 2
		b.Width1 = radius * 2
		b.Transparency = NumberSequence.new(math.clamp(alpha, 0, 1))
		if color then
			b.Color = ColorSequence.new(color)
		end
		b.Enabled = true
	end
	function o.hide()
		b.Enabled = false
	end
	return o
end

local RAY = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.42, 0.25),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.58, 0.25),
	NumberSequenceKeypoint.new(1, 1),
})

-- A 4-point star in screen space: a long ray along the camera's up, a shorter one along its right, a soft core.
-- (World up leaned outwards at the sides of a wide view and the stars stopped reading as stars.)
function Kit.glint(c, color: Color3, coreColor: Color3?)
	local core = Kit.blob(c)
	local halo = Kit.blob(c)
	local v0, v1, h0, h1 = c:attachment(), c:attachment(), c:attachment(), c:attachment()
	local props = { FaceCamera = true, LightEmission = 1, Segments = 10, Enabled = false, Color = ColorSequence.new(coreColor or Color3.new(1, 1, 1)) }
	local vb, hb = c:beam(v0, v1, props), c:beam(h0, h1, props)
	local o = {}
	-- size: half-length of the horizontal ray in studs. vertical: how much longer the vertical ray is.
	function o.set(pos: Vector3, size: number, alpha: number, vertical: number?)
		if size <= 0.01 or alpha >= 0.995 then
			o.hide()
			return
		end
		local right = camera().CFrame.RightVector
		local up = camera().CFrame.UpVector
		local vl = size * (vertical or 1.7)
		v0.WorldPosition = pos - up * vl
		v1.WorldPosition = pos + up * vl
		h0.WorldPosition = pos - right * size
		h1.WorldPosition = pos + right * size
		local w = math.max(size * 0.11, 0.035)
		for _, b in { vb, hb } do
			b.Width0 = w
			b.Width1 = w
			b.Transparency = if alpha <= 0.001
				then RAY
				else NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.42, 0.25 + 0.75 * alpha),
					NumberSequenceKeypoint.new(0.5, alpha),
					NumberSequenceKeypoint.new(0.58, 0.25 + 0.75 * alpha),
					NumberSequenceKeypoint.new(1, 1),
				})
			b.Enabled = true
		end
		core.set(pos, size * 0.3, alpha, coreColor or Color3.new(1, 1, 1))
		halo.set(pos, size * 0.75, 0.55 + 0.45 * alpha, color)
	end
	function o.hide()
		vb.Enabled = false
		hb.Enabled = false
		core.hide()
		halo.hide()
	end
	return o
end

-- Textures load on first use: the first cast of a session showed squares for a few frames. warm() puts every slot's
-- texture on a 1 px ImageLabel once so they are in memory before the first cast.
function Kit.warm()
	local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	if pg:FindFirstChild("FxWarm") then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FxWarm"
	gui.ResetOnSpawn = false
	local seen = {}
	for _, list in FxTextures.slots do
		for _, cand in list do
			if cand.id ~= "" and not seen[cand.id] then
				seen[cand.id] = true
				local img = Instance.new("ImageLabel")
				img.Size = UDim2.fromOffset(1, 1)
				img.BackgroundTransparency = 1
				img.ImageTransparency = 0.98
				img.Image = cand.id
				img.Parent = gui
				-- a Beam of its own too: the first cast still drew squares after the ImageLabel alone
				local host = Instance.new("Part")
				host.Anchored, host.CanCollide, host.CanQuery, host.Transparency = true, false, false, 1
				host.Size = Vector3.one * 0.2
				host.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -30)
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a1.Position = Vector3.new(0, 0.3, 0)
				a0.Parent, a1.Parent = host, host
				local beam = Instance.new("Beam")
				beam.Attachment0, beam.Attachment1 = a0, a1
				beam.FaceCamera = true
				beam.Width0, beam.Width1 = 0.3, 0.3
				beam.Transparency = NumberSequence.new(0.97)
				beam.Texture = cand.id
				beam.Parent = host
				host.Parent = workspace
				game:GetService("Debris"):AddItem(host, 8)
			end
		end
	end
	gui.Parent = pg
end

-- Cheap repeatable noise in -1..1.
function Kit.noise(seed: number, t: number): number
	return math.noise(seed * 12.9898, t, seed * 0.37) * 2
end

function Kit.fadeSeq(points: { { number } }, gain: number): NumberSequence
	local kp = {}
	for _, p in points do
		table.insert(kp, NumberSequenceKeypoint.new(p[1], 1 - (1 - p[2]) * math.clamp(gain, 0, 1)))
	end
	return NumberSequence.new(kp)
end

Kit.lerp = FxClock.lerp
Kit.smooth = FxClock.smooth

return Kit
