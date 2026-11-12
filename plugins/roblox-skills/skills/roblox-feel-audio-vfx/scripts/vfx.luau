--!strict
-- vfx.luau: world-space effect recipes built from layers (roblox-feel-audio-vfx section 3b).
-- Client only. Every recipe cleans up after itself.
--
--   Vfx.impact(pos, tier 1..4, color)          -- flash ball + light + streaks + stars (+ ring, + smoke)
--   Vfx.groundRing(pos, color, radius)   Vfx.dome(pos, color, radius)
--   Vfx.pillar(pos, color, height, seconds)    -- light pillar: level up, rare drop
--   Vfx.slash(rootCFrame, color)   Vfx.trail(part, color, seconds)
--   Vfx.highlightFlash(model, color)   Vfx.afterimage(character, color)   Vfx.aura(character, color, seconds)
--   Vfx.dust(pos)   Vfx.fireworks(center, shots)
--   Vfx.loot(pos, { count, color, coin, target, onPickup })  -- pop out, bounce, fly to the player
--
-- Vfx.TEX holds placeholder textures; replace them with the game's own before release.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Vfx = {}

Vfx.enabled = true
Vfx.scale = 1 -- particle count multiplier (0.5 on low-end phones)

-- Prototype placeholders from the Studio install. They run in Studio; the live client was not checked,
-- and the built-in particle textures look thin next to real art. Upload the game's own star, soft glow,
-- smoke, ring and soft-edged band textures and set them here before release.
Vfx.TEX = {
	star = "rbxasset://textures/particles/sparkles_main.dds",
	soft = "rbxasset://textures/particles/explosion01_implosion_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	ring = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	band = "rbxasset://textures/gradient.png", -- soft-edged strip for beams
}

local WHITE = Color3.new(1, 1, 1)

local function new(class: string, props: { [string]: any }): any
	local o = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(o :: any)[k] = v
		end
	end
	if props.Parent then
		o.Parent = props.Parent
	end
	return o
end

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function count(n: number): number
	return math.max(1, math.floor(n * Vfx.scale + 0.5))
end

local folder: Folder? = nil
local function root(): Folder
	if not folder or not folder.Parent then
		folder = new("Folder", { Name = "Vfx", Parent = workspace })
	end
	return folder :: Folder
end

local function host(pos: Vector3, life: number): (Part, Attachment)
	local p = new("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos), Parent = root(),
	})
	local a = new("Attachment", { Parent = p })
	Debris:AddItem(p, life)
	return p, a
end

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function neon(shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, transparency: number): Part
	return new("Part", {
		Shape = shape, Size = size, CFrame = cf, Color = color, Material = Enum.Material.Neon, Transparency = transparency,
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = root(),
	})
end

-- ---------------------------------------------------------------- impact

-- Layered hit: flash ball + light + streak sparks + stars, ring from tier 2, smoke from tier 3.
function Vfx.impact(pos: Vector3, tier: number, color: Color3)
	if not Vfx.enabled then
		return
	end
	local p, a = host(pos, 1.2)
	local hot = color:Lerp(WHITE, 0.6)

	local ball = neon(Enum.PartType.Ball, Vector3.one * (0.6 + 0.4 * tier), CFrame.new(pos), hot, 0.15)
	tween(ball, 0.12, { Size = Vector3.one * (1.6 + 1.5 * tier), Transparency = 1 })
	Debris:AddItem(ball, 0.2)

	local light = new("PointLight", { Color = color, Brightness = 2 + 2 * tier, Range = 8 + 4 * tier, Shadows = false, Parent = p })
	tween(light, 0.25, { Brightness = 0 })

	-- streaks: stretched along their velocity, they read as speed lines
	new("ParticleEmitter", {
		Texture = Vfx.TEX.soft, Color = ColorSequence.new(hot, color), LightEmission = 1, Enabled = false,
		Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = NumberSequence.new(2.2),
		Lifetime = NumberRange.new(0.14, 0.3), Speed = NumberRange.new(30 + 12 * tier, 55 + 20 * tier), SpreadAngle = Vector2.new(180, 180),
		Drag = 6, Size = seq(0.35 + 0.12 * tier, 0), Parent = a,
	}):Emit(count(5 + 5 * tier))
	new("ParticleEmitter", {
		Texture = Vfx.TEX.star, Color = ColorSequence.new(hot), LightEmission = 1, Enabled = false,
		Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(10, 24 + 6 * tier), SpreadAngle = Vector2.new(180, 180),
		Drag = 3, Acceleration = Vector3.new(0, -40, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200),
		Size = seq(0.7 + 0.2 * tier, 0), Parent = a,
	}):Emit(count(3 + 3 * tier))
	if tier >= 2 then
		new("ParticleEmitter", {
			Texture = Vfx.TEX.ring, Color = ColorSequence.new(hot), LightEmission = 1, Enabled = false,
			Lifetime = NumberRange.new(0.28), Speed = NumberRange.new(0), Size = seq(1, 4 + 3 * tier), Transparency = seq(0.1, 1), Parent = a,
		}):Emit(1)
	end
	if tier >= 3 then
		new("ParticleEmitter", {
			Texture = Vfx.TEX.smoke, Color = ColorSequence.new(color:Lerp(Color3.fromRGB(200, 200, 200), 0.7)), LightEmission = 0.1, Enabled = false,
			Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(180, 180), Drag = 4,
			Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60), Size = seq(1.5, 3 + tier), Transparency = seq(0.45, 1), Parent = a,
		}):Emit(count(3 + 2 * tier))
	end
end

-- A ring that spreads flat on the ground, with a faint disc under it.
function Vfx.groundRing(pos: Vector3, color: Color3, radius: number, seconds: number?)
	if not Vfx.enabled then
		return
	end
	local t = seconds or 0.45
	local _, a = host(pos + Vector3.new(0, 0.15, 0), t + 0.3)
	new("ParticleEmitter", {
		Texture = Vfx.TEX.ring, Color = ColorSequence.new(color:Lerp(WHITE, 0.4)), LightEmission = 1, Enabled = false,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Lifetime = NumberRange.new(t), Size = seq(0.5, radius * 2.6), Transparency = seq(0, 1), Parent = a,
	}):Emit(1)
	local disc = neon(Enum.PartType.Cylinder, Vector3.new(0.1, 1, 1), CFrame.new(pos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, 0.55)
	tween(disc, t, { Size = Vector3.new(0.1, radius * 2, radius * 2), Transparency = 1 })
	Debris:AddItem(disc, t + 0.05)
end

-- A shell that swells and fades: boss deaths, ultimates.
function Vfx.dome(pos: Vector3, color: Color3, radius: number, seconds: number?)
	if not Vfx.enabled then
		return
	end
	local t = seconds or 0.5
	local shell = neon(Enum.PartType.Ball, Vector3.one * 2, CFrame.new(pos), color, 0.2)
	shell.Material = Enum.Material.ForceField
	tween(shell, t, { Size = Vector3.one * radius * 2, Transparency = 1 })
	Debris:AddItem(shell, t + 0.05)
	local glow = neon(Enum.PartType.Ball, Vector3.one * 2, CFrame.new(pos), color:Lerp(WHITE, 0.5), 0.5)
	tween(glow, t * 0.6, { Size = Vector3.one * radius * 1.2, Transparency = 1 })
	Debris:AddItem(glow, t)
end

-- ---------------------------------------------------------------- beams

-- Light pillar: level up, rare drop, respawn. Rises fast, holds, thins out.
function Vfx.pillar(pos: Vector3, color: Color3, height: number, seconds: number?, width: number?)
	if not Vfx.enabled then
		return
	end
	local t = seconds or 1.2
	local w = width or 5
	local p, a0 = host(pos, t + 0.6)
	local a1 = new("Attachment", { Position = Vector3.new(0, height, 0), Parent = p })
	local function beam(c: Color3, share: number, alpha: number): Beam
		return new("Beam", {
			Attachment0 = a0, Attachment1 = a1, FaceCamera = true, Color = ColorSequence.new(c), LightEmission = 0.7, LightInfluence = 0,
			Texture = Vfx.TEX.band, TextureMode = Enum.TextureMode.Stretch, TextureLength = 1,
			Width0 = 0, Width1 = 0, Transparency = seq(alpha, 1), Segments = 1, Parent = p,
		})
	end
	local outer, inner = beam(color, 1, 0.45), beam(color:Lerp(WHITE, 0.8), 0.35, 0.2)
	tween(outer, 0.18, { Width0 = w, Width1 = w * 0.7 }, Enum.EasingStyle.Back)
	tween(inner, 0.18, { Width0 = w * 0.35, Width1 = w * 0.2 }, Enum.EasingStyle.Back)
	local rise = new("ParticleEmitter", {
		Texture = Vfx.TEX.star, Color = ColorSequence.new(color:Lerp(WHITE, 0.5)), LightEmission = 1, Rate = 50 * Vfx.scale,
		Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(14, 26), SpreadAngle = Vector2.new(12, 12), EmissionDirection = Enum.NormalId.Top,
		Size = seq(0.8, 0), Rotation = NumberRange.new(0, 360), Parent = a0,
	})
	task.delay(t, function()
		rise.Enabled = false
		tween(outer, 0.3, { Width0 = 0, Width1 = 0 })
		tween(inner, 0.3, { Width0 = 0, Width1 = 0 })
	end)
end

-- Swing arc in front of a character: a wedge that sweeps out and fades in about 0.15 s.
function Vfx.slash(rootCFrame: CFrame, color: Color3, reach: number?)
	if not Vfx.enabled then
		return
	end
	local r = reach or 5
	local p = new("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one,
		CFrame = rootCFrame * CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(math.random(-25, 25))), Parent = root(),
	})
	-- the attachments' X axis points forward, so the curve bulges ahead of the character
	local a0 = new("Attachment", { Position = Vector3.new(r * 0.8, 0, 0.5), Axis = Vector3.new(0, 0, -1), SecondaryAxis = Vector3.yAxis, Parent = p })
	local a1 = new("Attachment", { Position = Vector3.new(-r * 0.8, 0, 0.5), Axis = Vector3.new(0, 0, -1), SecondaryAxis = Vector3.yAxis, Parent = p })
	local beam = new("Beam", {
		Attachment0 = a0, Attachment1 = a1, CurveSize0 = r * 1.1, CurveSize1 = -r * 1.1, Segments = 16, FaceCamera = false,
		Color = ColorSequence.new(WHITE, color), LightEmission = 1, LightInfluence = 0, Width0 = 0.2, Width1 = 2.6,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.15), NumberSequenceKeypoint.new(1, 0.6) }), Parent = p,
	})
	tween(beam, 0.16, { Width0 = 0, Width1 = 0.4 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(p, 0.18)
end

-- Motion trail on a limb or a thrown object for `seconds`.
function Vfx.trail(part: BasePart, color: Color3, seconds: number, width: number?)
	if not Vfx.enabled then
		return
	end
	local w = (width or part.Size.Y) / 2
	local a0 = new("Attachment", { Position = Vector3.new(0, w, 0), Parent = part })
	local a1 = new("Attachment", { Position = Vector3.new(0, -w, 0), Parent = part })
	local tr = new("Trail", {
		Attachment0 = a0, Attachment1 = a1, Lifetime = 0.2, Color = ColorSequence.new(WHITE, color), LightEmission = 1,
		Transparency = seq(0.25, 1), WidthScale = seq(1, 0), FaceCamera = true, Parent = part,
	})
	task.delay(seconds, function()
		tr.Enabled = false
		Debris:AddItem(tr, 0.3)
		Debris:AddItem(a0, 0.3)
		Debris:AddItem(a1, 0.3)
	end)
end

-- ---------------------------------------------------------------- characters

-- One-frame-style flash over a whole model without touching its colours.
function Vfx.highlightFlash(model: Instance, color: Color3, seconds: number?)
	if not Vfx.enabled then
		return
	end
	local h = new("Highlight", {
		FillColor = color, FillTransparency = 0, OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded, Parent = model,
	})
	tween(h, seconds or 0.12, { FillTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(h, (seconds or 0.12) + 0.03)
end

-- Ghost copies of a character left behind during a dash.
function Vfx.afterimage(character: Model, color: Color3, seconds: number?)
	if not Vfx.enabled then
		return
	end
	local t = seconds or 0.3
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 and part.Name ~= "HumanoidRootPart" then
			local g = part:Clone()
			for _, c in g:GetChildren() do
				if not c:IsA("SpecialMesh") then
					c:Destroy()
				end
			end
			g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow = true, false, false, false, false
			g.Material, g.Color, g.Transparency = Enum.Material.Neon, color, 0.45
			if g:IsA("MeshPart") then
				g.TextureID = ""
			end
			g.Parent = root()
			tween(g, t, { Transparency = 1 })
			Debris:AddItem(g, t + 0.05)
		end
	end
end

-- Standing aura for `seconds`: rising stars, a pulsing ground ring and an outline.
function Vfx.aura(character: Model, color: Color3, seconds: number)
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not Vfx.enabled or not rootPart then
		return
	end
	local a = new("Attachment", { Position = Vector3.new(0, -2.8, 0), Parent = rootPart })
	local stars = new("ParticleEmitter", {
		Texture = Vfx.TEX.star, Color = ColorSequence.new(color:Lerp(WHITE, 0.4)), LightEmission = 1, Rate = 40 * Vfx.scale,
		Shape = Enum.ParticleEmitterShape.Disc, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Lifetime = NumberRange.new(0.8, 1.3), Speed = NumberRange.new(5, 9), SpreadAngle = Vector2.new(8, 8), EmissionDirection = Enum.NormalId.Top,
		Size = seq(1.4, 0), Rotation = NumberRange.new(0, 360), LockedToPart = false, Parent = a,
	})
	local rings = new("ParticleEmitter", {
		Texture = Vfx.TEX.ring, Color = ColorSequence.new(color), LightEmission = 1, Rate = 2.5,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Lifetime = NumberRange.new(0.8), Size = seq(1, 11), Transparency = seq(0, 1), LockedToPart = true, Parent = a,
	})
	local glowLight = new("PointLight", { Color = color, Brightness = 2.5, Range = 14, Shadows = false, Parent = a })
	Debris:AddItem(glowLight, seconds)
	local outline = new("Highlight", { FillTransparency = 1, OutlineColor = color, OutlineTransparency = 0.1, DepthMode = Enum.HighlightDepthMode.Occluded, Parent = character })
	task.delay(seconds, function()
		stars.Enabled, rings.Enabled = false, false
		tween(outline, 0.4, { OutlineTransparency = 1 })
		Debris:AddItem(a, 1.3)
		Debris:AddItem(outline, 0.45)
	end)
end

-- Landing or dash dust: low puffs pushed outward.
function Vfx.dust(pos: Vector3, amount: number?)
	if not Vfx.enabled then
		return
	end
	local _, a = host(pos + Vector3.new(0, 0.3, 0), 1.2)
	a.CFrame = CFrame.Angles(math.rad(90), 0, 0)
	new("ParticleEmitter", {
		Texture = Vfx.TEX.smoke, Color = ColorSequence.new(Color3.fromRGB(225, 225, 215)), LightEmission = 0, Enabled = false,
		Shape = Enum.ParticleEmitterShape.Disc, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
		Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(7, 12), Drag = 5, Rotation = NumberRange.new(0, 360),
		Size = seq(1, 2.6), Transparency = seq(0.5, 1), Parent = a,
	}):Emit(count(amount or 8))
end

-- Bursts in the sky, one after another.
function Vfx.fireworks(center: Vector3, shots: number, onPop: (() -> ())?)
	local palette = { Color3.fromRGB(255, 90, 110), Color3.fromRGB(255, 205, 60), Color3.fromRGB(90, 200, 255), Color3.fromRGB(150, 255, 130), Color3.fromRGB(200, 120, 255) }
	for i = 1, shots do
		task.delay((i - 1) * 0.22 + math.random() * 0.1, function()
			local pos = center + Vector3.new((math.random() - 0.5) * 50, 22 + math.random() * 16, (math.random() - 0.5) * 30 - 20)
			Vfx.impact(pos, 4, palette[(i % #palette) + 1])
			if onPop then
				onPop()
			end
		end)
	end
end

-- ---------------------------------------------------------------- loot

export type LootOptions = {
	count: number,
	color: Color3,
	coin: boolean?, -- true: spinning coins; false: glowing orbs
	target: () -> Vector3?, -- where the pieces fly to (the player); nil skips the magnet
	onPickup: ((index: number) -> ())?,
	floor: number?, -- ground height
}

type Piece = { part: BasePart, vel: Vector3, t: number, wait: number, index: number, spin: number, done: boolean }

-- Pieces pop out in arcs, bounce, hang for a moment, then get pulled to the player.
function Vfx.loot(pos: Vector3, o: LootOptions)
	local pieces: { Piece } = {}
	local floor = (o.floor or 0) + 0.7
	for i = 1, o.count do
		local part: Part
		if o.coin then
			part = new("Part", {
				Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.5, 1.5), Color = o.color, Material = Enum.Material.Neon,
				Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, CFrame = CFrame.new(pos), Parent = root(),
			})
		else
			part = neon(Enum.PartType.Ball, Vector3.one * 0.9, CFrame.new(pos), o.color, 0)
		end
		local angle = math.random() * math.pi * 2
		local out = 9 + math.random() * 12
		table.insert(pieces, {
			part = part, vel = Vector3.new(math.cos(angle) * out, 26 + math.random() * 16, math.sin(angle) * out),
			t = 0, wait = 0.55 + i * 0.035, index = i, spin = math.random() * 6, done = false,
		})
	end
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local left = 0
		for _, c in pieces do
			if c.done then
				continue
			end
			left += 1
			c.t += dt
			if c.t > 6 then
				c.done = true
				c.part:Destroy()
				continue
			end
			local p = c.part.Position
			local target = if c.t > c.wait then o.target() else nil
			if target then
				-- magnet: speed grows the longer it flies, so the pull feels eager
				local to = target - p
				local speed = 40 + (c.t - c.wait) * 220
				if to.Magnitude < math.max(2, speed * dt) then
					c.done = true
					c.part:Destroy()
					if o.onPickup then
						o.onPickup(c.index)
					end
					continue
				end
				p += to.Unit * speed * dt
				if c.t - dt <= c.wait then
					Vfx.trail(c.part, o.color, 1, 1)
				end
			else
				c.vel += Vector3.new(0, -130, 0) * dt
				p += c.vel * dt
				if p.Y < floor then
					p = Vector3.new(p.X, floor, p.Z)
					c.vel = Vector3.new(c.vel.X * 0.6, -c.vel.Y * 0.45, c.vel.Z * 0.6)
				end
			end
			c.spin += dt * 9
			c.part.CFrame = CFrame.new(p) * CFrame.Angles(0, c.spin, 0) * (if o.coin then CFrame.Angles(0, 0, 0) else CFrame.new())
		end
		if left == 0 then
			conn:Disconnect()
		end
	end)
end

return Vfx
