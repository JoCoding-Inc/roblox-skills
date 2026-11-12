--!strict
-- uifx.luau: screen-space effect recipes that need no image assets (roblox-feel-audio-vfx section 3b).
-- Client only. `UiFx.layer` is a ScreenGui above the HUD; `UiFx.full` covers the whole screen (ScreenInsets None).
-- Positions are AbsolutePosition px; pass `parent` to draw inside another ScreenGui or frame.
--
--   UiFx.breathe(button)  UiFx.shine(button, every)        -- idle life on a call to action
--   UiFx.ring(pos, color, size)  UiFx.spray(pos, color, pieces, reach)  UiFx.confetti(pos, pieces)  UiFx.coinRain(pieces, color)
--   UiFx.glow(parent, color, size)  UiFx.rays(parent, color, size)   -- behind a reward; destroy the result to stop
--   UiFx.floatText(pos, "+25", color)  UiFx.slam(label, onLand)  UiFx.rainbow(label)  UiFx.toast(text, color)
--   UiFx.letterbox(on)  UiFx.speedLines(on)  UiFx.flip(card, swapFace)
--
-- Set UiFx.motion to the game's reduced-motion check (Juice.motionOn).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UiFx = {}

UiFx.enabled = true
UiFx.motion = function(): boolean -- the game points this at its reduced-motion check
	return true
end
UiFx.font = Enum.Font.FredokaOne

local WHITE = Color3.new(1, 1, 1)
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function new(class: string, props: { [string]: any }, children: { Instance }?): any
	local o = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(o :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	if props.Parent then
		o.Parent = props.Parent
	end
	return o
end

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

UiFx.layer = new("ScreenGui", { Name = "UiFx", ResetOnSpawn = false, DisplayOrder = 45, ClipToDeviceSafeArea = false, Parent = playerGui })
UiFx.full = new("ScreenGui", { Name = "UiFxFull", ResetOnSpawn = false, DisplayOrder = 44, ScreenInsets = Enum.ScreenInsets.None, Parent = playerGui })

local function scaleOf(o: GuiObject, name: string): UIScale
	local s = o:FindFirstChild(name) :: UIScale?
	if not s then
		s = new("UIScale", { Name = name, Parent = o })
	end
	return s :: UIScale
end

-- effect positions are given in AbsolutePosition px; this turns one into an offset inside `parent`
local function at(parent: Instance, pos: Vector2): UDim2
	local origin = (parent :: any).AbsolutePosition :: Vector2
	return UDim2.fromOffset(pos.X - origin.X, pos.Y - origin.Y)
end

-- centre of a GuiObject in the px space of UiFx.layer
function UiFx.centre(o: GuiObject): Vector2
	return o.AbsolutePosition + o.AbsoluteSize / 2
end

-- ---------------------------------------------------------------- idle life

-- Slow breathing on a call-to-action so it reads as tappable. Returns a stop function.
function UiFx.breathe(o: GuiObject, amount: number?, period: number?): () -> ()
	local s = scaleOf(o, "Breathe")
	local tw = TweenService:Create(s, TweenInfo.new((period or 1.6) / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1 + (amount or 0.06) })
	if UiFx.motion() then
		tw:Play()
	end
	return function()
		tw:Cancel()
		s.Scale = 1
	end
end

-- A light band that sweeps across a button or card. `every` repeats it.
function UiFx.shine(o: GuiObject, every: number?)
	local function once()
		if not UiFx.enabled or not UiFx.motion() or not o.Parent then
			return
		end
		local clip = new("Frame", { Name = "Shine", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = o.ZIndex + 5, Parent = o })
		local c = o:FindFirstChildOfClass("UICorner")
		if c then
			c:Clone().Parent = clip
		end
		local band = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.4, 0.5), Size = UDim2.fromScale(0.45, 2.4), Rotation = 20,
			BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = clip,
		}, { new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1) }) }) })
		tween(band, 0.55, { Position = UDim2.fromScale(1.4, 0.5) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		Debris:AddItem(clip, 0.6)
	end
	once()
	if every then
		task.spawn(function()
			while o.Parent do
				task.wait(every)
				once()
			end
		end)
	end
end

-- ---------------------------------------------------------------- bursts

-- Expanding ring made of a stroked circle.
function UiFx.ring(pos: Vector2, color: Color3, size: number, seconds: number?, parent: Instance?)
	if not UiFx.enabled or not UiFx.motion() then
		return
	end
	local t = seconds or 0.4
	local r = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = at(parent or UiFx.layer, pos), Size = UDim2.fromOffset(size * 0.2, size * 0.2),
		BackgroundTransparency = 1, Parent = parent or UiFx.layer,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), new("UIStroke", { Color = color, Thickness = math.max(3, size * 0.06) }) })
	tween(r, t, { Size = UDim2.fromOffset(size, size) })
	tween(r.UIStroke, t, { Transparency = 1, Thickness = 1 })
	Debris:AddItem(r, t + 0.05)
end

-- Soft glow from stacked circles (no image). Returns the holder so it can be faded or destroyed.
function UiFx.glow(parent: Instance, color: Color3, size: number, strength: number?): Frame
	local holder = new("Frame", { Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent })
	local layers = 7
	for i = 1, layers do
		local k = i / layers
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(k, k),
			BackgroundColor3 = color, BackgroundTransparency = 1 - (strength or 0.16) * (1.15 - k), BorderSizePixel = 0, Parent = holder,
		}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	end
	return holder
end

-- Rotating ray bars behind a reward. Returns the holder; destroy it to stop.
function UiFx.rays(parent: Instance, color: Color3, size: number, bars: number?): Frame
	local holder = new("Frame", { Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Parent = parent })
	local n = bars or 8
	for i = 1, n do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, if i % 2 == 0 then size * 0.075 else size * 0.04),
			Rotation = i * 180 / n, BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder,
		}, { new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 1) }) }) })
	end
	if UiFx.motion() then
		TweenService:Create(holder, TweenInfo.new(9, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
	end
	return holder
end

-- Small pieces thrown out from a point: stars for rewards, shards for breaks.
function UiFx.spray(pos: Vector2, color: Color3, pieces: number, reach: number, parent: Instance?)
	if not UiFx.enabled or not UiFx.motion() then
		return
	end
	for i = 1, pieces do
		local a = (i / pieces) * math.pi * 2 + math.random() * 0.5
		local d = reach * (0.5 + math.random() * 0.5)
		local s = 6 + math.random() * 8
		local from = at(parent or UiFx.layer, pos)
		local dot = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = from, Size = UDim2.fromOffset(s, s), Rotation = 45,
			BackgroundColor3 = if i % 3 == 0 then WHITE else color, BorderSizePixel = 0, Parent = parent or UiFx.layer,
		})
		tween(dot, 0.4 + math.random() * 0.2, { Position = from + UDim2.fromOffset(math.cos(a) * d, math.sin(a) * d), Size = UDim2.fromOffset(0, 0), Rotation = 225 })
		Debris:AddItem(dot, 0.65)
	end
end

type Falling = { f: Frame, p: Vector2, v: Vector2, spin: number }

local function fall(pieces: { Falling }, seconds: number, gravity: number)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local e = os.clock() - t0
		for _, c in pieces do
			c.v = Vector2.new(c.v.X * (1 - 1.5 * dt), c.v.Y + gravity * dt)
			c.p += c.v * dt
			c.f.Position = UDim2.fromOffset(c.p.X, c.p.Y)
			c.f.Rotation += c.spin * dt
			c.f.BackgroundTransparency = math.clamp((e - (seconds - 0.4)) / 0.4, 0, 1)
		end
		if e > seconds then
			conn:Disconnect()
			for _, c in pieces do
				c.f:Destroy()
			end
		end
	end)
end

-- Paper confetti thrown up from a point.
function UiFx.confetti(pos: Vector2, pieces: number, parent: Instance?)
	if not UiFx.enabled or not UiFx.motion() then
		return
	end
	local colors = { Color3.fromRGB(255, 205, 60), Color3.fromRGB(90, 220, 120), Color3.fromRGB(70, 150, 255), Color3.fromRGB(255, 90, 110), WHITE }
	local list: { Falling } = {}
	local origin = at(parent or UiFx.layer, pos)
	pos = Vector2.new(origin.X.Offset, origin.Y.Offset)
	for i = 1, pieces do
		local a = -math.pi / 2 + (math.random() - 0.5) * 2.4
		local speed = 240 + math.random() * 300
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pos.X, pos.Y), Size = UDim2.fromOffset(7, 12),
			BackgroundColor3 = colors[(i % #colors) + 1], BorderSizePixel = 0, Rotation = math.random(0, 360), ZIndex = 5, Parent = parent or UiFx.layer,
		})
		table.insert(list, { f = f, p = pos, v = Vector2.new(math.cos(a), math.sin(a)) * speed, spin = (math.random() - 0.5) * 900 })
	end
	fall(list, 1.7, 640)
end

-- Coins raining down the whole screen: jackpots and boss payouts.
function UiFx.coinRain(pieces: number, color: Color3)
	if not UiFx.enabled or not UiFx.motion() then
		return
	end
	local width = UiFx.full.AbsoluteSize.X
	local list: { Falling } = {}
	for _ = 1, pieces do
		local s = 14 + math.random() * 12
		local x = math.random() * width
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, -20), Size = UDim2.fromOffset(s, s), BackgroundColor3 = color, BorderSizePixel = 0, Parent = UiFx.full,
		}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), new("UIStroke", { Thickness = 2, Color = Color3.fromRGB(150, 95, 0) }) })
		table.insert(list, { f = f, p = Vector2.new(x, -20 - math.random() * 260), v = Vector2.new((math.random() - 0.5) * 60, 180 + math.random() * 200), spin = 0 })
	end
	fall(list, 1.9, 520)
end

-- ---------------------------------------------------------------- text

-- Rising "+25" next to a counter.
function UiFx.floatText(pos: Vector2, text: string, color: Color3, size: number?, parent: Instance?)
	if not UiFx.enabled then
		return
	end
	local from = at(parent or UiFx.layer, pos)
	local l = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = from, Size = UDim2.fromOffset(160, 30), BackgroundTransparency = 1,
		Font = UiFx.font, TextSize = size or 20, TextColor3 = color, Text = text, Parent = parent or UiFx.layer,
	}, { new("UIStroke", { Thickness = 2.5 }), new("UIScale", { Scale = 0.5 }) })
	tween(l.UIScale, 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
	if UiFx.motion() then
		tween(l, 0.7, { Position = from - UDim2.fromOffset(0, 34) })
	end
	task.delay(0.45, function()
		tween(l, 0.25, { TextTransparency = 1 })
		tween(l.UIStroke, 0.25, { Transparency = 1 })
	end)
	Debris:AddItem(l, 0.75)
end

-- Stamp: the text drops in oversized, lands hard, throws a ring and shards. `onLand` is the place for shake and sound.
function UiFx.slam(label: TextLabel, onLand: (() -> ())?)
	local s = scaleOf(label, "Slam")
	label.Visible = true
	label.TextTransparency = 0
	local st = label:FindFirstChildOfClass("UIStroke")
	if st then
		st.Transparency = 0
	end
	if not UiFx.motion() then
		s.Scale = 1
		if onLand then
			onLand()
		end
		return
	end
	s.Scale = 3.2
	label.Rotation = -8
	tween(label, 0.14, { Rotation = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tw = tween(s, 0.14, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw.Completed:Once(function()
		s.Scale = 0.88
		tween(s, 0.25, { Scale = 1 }, Enum.EasingStyle.Elastic)
		local c = UiFx.centre(label)
		UiFx.ring(c, label.TextColor3, label.AbsoluteSize.X * 1.3, 0.35, label:FindFirstAncestorOfClass("ScreenGui"))
		UiFx.spray(c, label.TextColor3, 12, label.AbsoluteSize.X * 0.6, label:FindFirstAncestorOfClass("ScreenGui"))
		if onLand then
			onLand()
		end
	end)
end

-- Colours that run through the text: top-tier names.
function UiFx.rainbow(label: TextLabel): UIGradient
	label.TextColor3 = WHITE
	local keys = {}
	local hues = { 0, 0.1, 0.17, 0.4, 0.55, 0.75, 0.9, 1 }
	for i, h in hues do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#hues - 1), Color3.fromHSV(h % 1, 0.75, 1)))
	end
	local g = new("UIGradient", { Name = "Rainbow", Color = ColorSequence.new(keys), Parent = label })
	if UiFx.motion() then
		g.Offset = Vector2.new(-0.5, 0)
		TweenService:Create(g, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true), { Offset = Vector2.new(0.5, 0) }):Play()
	end
	return g
end

local toastSlot = 0

-- Announcement that slides in under the top bar and leaves after `hold` seconds.
function UiFx.toast(text: string, color: Color3, hold: number?)
	toastSlot += 1
	local mine = toastSlot
	local pill = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -50), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(24, 27, 38), BackgroundTransparency = 0.1, Parent = UiFx.layer,
	}, {
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), new("UIStroke", { Color = color, Thickness = 2.5 }),
		new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
		new("TextLabel", { Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = UiFx.font, TextSize = 17, TextColor3 = color, Text = text }, { new("UIStroke", { Thickness = 2 }) }),
	})
	pill:SetAttribute("KitTransient", true)
	tween(pill, if UiFx.motion() then 0.3 else 0, { Position = UDim2.new(0.5, 0, 0, 6) }, Enum.EasingStyle.Back)
	UiFx.shine(pill)
	task.delay(hold or 2.5, function()
		tween(pill, 0.25, { Position = UDim2.new(0.5, 0, 0, -50) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(pill, 0.3)
	end)
	return mine
end

-- ---------------------------------------------------------------- screen states

local bars: { Frame } = {}

-- Cinema bars for a big moment. They live in the full-screen layer so they reach the screen edge.
function UiFx.letterbox(on: boolean, share: number?)
	if #bars == 0 then
		for i = 1, 2 do
			bars[i] = new("Frame", {
				AnchorPoint = Vector2.new(0, i - 1), Position = UDim2.fromScale(0, i - 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = UiFx.full,
			})
			bars[i]:SetAttribute("KitTransient", true)
		end
	end
	for _, b in bars do
		tween(b, if UiFx.motion() then 0.25 else 0, { Size = UDim2.fromScale(1, if on then (share or 0.11) else 0) })
	end
end

local lines: Frame? = nil
local linesOn = false

-- Speed lines at the screen edges while dashing or boosted.
function UiFx.speedLines(on: boolean)
	if on == linesOn then
		return
	end
	linesOn = on
	if not on then
		if lines then
			lines:Destroy()
			lines = nil
		end
		return
	end
	if not UiFx.enabled or not UiFx.motion() then
		return
	end
	local holder = new("Frame", { Name = "SpeedLines", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = UiFx.full })
	holder:SetAttribute("KitTransient", true)
	lines = holder
	local size = UiFx.full.AbsoluteSize
	local centre = size / 2
	local reach = size.Magnitude / 2
	task.spawn(function()
		while lines == holder do
			for _ = 1, 5 do
				local a = math.random() * math.pi * 2
				local dir = Vector2.new(math.cos(a), math.sin(a))
				local len = 60 + math.random() * 120
				local from = centre + dir * reach * (0.62 + math.random() * 0.2)
				local l = new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(from.X, from.Y), Size = UDim2.fromOffset(len, 2 + math.random() * 2),
					Rotation = math.deg(a), BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = holder,
				}, { new("UIGradient", { Transparency = NumberSequence.new(1, 0) }) })
				tween(l, 0.16, { Position = UDim2.fromOffset(from.X + dir.X * 70, from.Y + dir.Y * 70), BackgroundTransparency = 1 }, Enum.EasingStyle.Linear)
				Debris:AddItem(l, 0.18)
			end
			task.wait(0.03)
		end
	end)
end

-- Card flip: squeeze to an edge, swap the face, open again.
function UiFx.flip(card: GuiObject, swap: () -> ())
	if not UiFx.motion() then
		swap()
		return
	end
	local w = card.Size
	local thin = UDim2.new(0, 0, w.Y.Scale, w.Y.Offset)
	local tw = tween(card, 0.12, { Size = thin }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw.Completed:Once(function()
		swap()
		tween(card, 0.2, { Size = w }, Enum.EasingStyle.Back)
	end)
end

return UiFx
