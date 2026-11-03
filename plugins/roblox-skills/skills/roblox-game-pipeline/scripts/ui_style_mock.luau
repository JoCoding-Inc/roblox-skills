--!nocheck
-- UI style mockup built as a real ScreenGui in the game's own place, so fonts, strokes,
-- corners and the world behind it are what the game will show.
-- Use: edit CONFIG, run in Edit mode (Studio MCP execute_luau), screen_capture, show the user.
-- Remove after: StarterGui.UiStyleMock and Lighting.UiStyleMockBlur (rerunning replaces both).
-- Items: set `model` to a Model or Part from the game (cloned into a ViewportFrame);
-- without it a placeholder (gem, sword, egg, potion) is built from parts.

local CONFIG = {
	preset = "soft-dark", -- soft-dark | stud-chunky | bright-cards | dark-flat
	override = {}, -- any STYLE key, for example { accent = Color3.fromRGB(255, 120, 40) }
	title = "SHOP",
	currency = "8,423",
	items = {
		{ price = "150", shape = "gem" },
		{ price = "300", shape = "sword" },
		{ price = "500", shape = "egg" },
		{ price = "750", shape = "potion" },
		-- { price = "990", model = game.ReplicatedStorage.Pets.Dog },
	},
	blur = 10, -- world blur behind the open panel, 0 for none
}

local rgb = Color3.fromRGB
local fredoka = Font.fromName("FredokaOne")

local PRESETS = {
	["soft-dark"] = {
		font = fredoka, text = rgb(255, 255, 255), stroke = rgb(25, 28, 36), strokeW = 2,
		panel = rgb(45, 50, 60), panelT = 0.12, panelStroke = rgb(255, 255, 255), panelStrokeW = 2, panelStrokeT = 0.84, radius = 12, lip = nil,
		header = nil, card = rgb(255, 255, 255), cardT = 0.93, cardStroke = rgb(255, 255, 255), cardStrokeW = 1, cardStrokeT = 0.82, cardRadius = 10,
		chip = rgb(67, 194, 58), chipLip = rgb(43, 138, 36), close = rgb(224, 48, 42),
		btn = rgb(35, 40, 48), btnT = 0.18, btnGrad = nil, btnStroke = rgb(255, 255, 255), btnStrokeW = 2, btnStrokeT = 0.86, btnRadius = 12,
		barTrack = rgb(29, 74, 26), barFill = rgb(79, 224, 60), chipText = nil,
	},
	["stud-chunky"] = {
		font = fredoka, text = rgb(255, 255, 255), stroke = rgb(13, 15, 24), strokeW = 3,
		panel = rgb(32, 36, 58), panelT = 0, panelStroke = rgb(13, 15, 24), panelStrokeW = 4, panelStrokeT = 0, radius = 22, lip = rgb(13, 15, 24),
		header = { rgb(255, 179, 64), rgb(240, 124, 18) }, card = rgb(46, 52, 84), cardT = 0, cardStroke = rgb(13, 15, 24), cardStrokeW = 3, cardStrokeT = 0, cardRadius = 16,
		chip = rgb(67, 194, 58), chipLip = rgb(43, 138, 36), close = rgb(224, 48, 42),
		btn = rgb(140, 90, 230), btnT = 0, btnGrad = { rgb(170, 120, 245), rgb(118, 62, 208) }, btnStroke = rgb(13, 15, 24), btnStrokeW = 4, btnStrokeT = 0, btnRadius = 16,
		barTrack = rgb(29, 74, 26), barFill = rgb(79, 224, 60), chipText = nil,
	},
	["bright-cards"] = {
		font = fredoka, text = rgb(43, 47, 69), stroke = rgb(43, 47, 69), strokeW = 0,
		panel = rgb(255, 250, 240), panelT = 0, panelStroke = rgb(43, 47, 69), panelStrokeW = 3, panelStrokeT = 0, radius = 18, lip = nil,
		header = { rgb(255, 166, 74), rgb(255, 127, 31) }, card = rgb(217, 244, 239), cardT = 0, cardStroke = rgb(43, 47, 69), cardStrokeW = 2, cardStrokeT = 0, cardRadius = 14,
		chip = rgb(67, 194, 58), chipLip = rgb(43, 138, 36), close = rgb(224, 48, 42),
		btn = rgb(47, 156, 232), btnT = 0, btnGrad = { rgb(92, 200, 255), rgb(47, 156, 232) }, btnStroke = rgb(43, 47, 69), btnStrokeW = 3, btnStrokeT = 0, btnRadius = 14,
		barTrack = rgb(200, 210, 220), barFill = rgb(79, 200, 60), chipText = rgb(255, 255, 255),
	},
	["dark-flat"] = {
		font = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold), text = rgb(235, 238, 245), stroke = rgb(0, 0, 0), strokeW = 0,
		panel = rgb(20, 22, 28), panelT = 0.08, panelStroke = rgb(58, 63, 75), panelStrokeW = 1, panelStrokeT = 0, radius = 6, lip = nil,
		header = nil, card = rgb(35, 38, 46), cardT = 0, cardStroke = rgb(58, 63, 75), cardStrokeW = 1, cardStrokeT = 0, cardRadius = 4,
		chip = nil, chipLip = nil, close = nil, accent = rgb(155, 92, 255),
		btn = rgb(20, 22, 28), btnT = 0.12, btnGrad = nil, btnStroke = rgb(58, 63, 75), btnStrokeW = 1, btnStrokeT = 0, btnRadius = 6,
		barTrack = rgb(42, 45, 54), barFill = rgb(155, 92, 255), chipText = rgb(201, 167, 255),
	},
}

local S = table.clone(PRESETS[CONFIG.preset])
for k, v in CONFIG.override do
	S[k] = v
end
local INK = rgb(28, 31, 38) -- icon outlines

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do
		o[k] = v
	end
	o.Parent = parent
	return o
end
local function px(x, y)
	return UDim2.fromOffset(x, y)
end
local function corner(p, r)
	new("UICorner", { CornerRadius = UDim.new(0, r) }, p)
end
local function stroke(p, color, w, t)
	if w and w > 0 then
		new("UIStroke", { Color = color, Thickness = w, Transparency = t or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
	end
end
local function grad(p, pair)
	if pair then
		new("UIGradient", { Color = ColorSequence.new(pair[1], pair[2]), Rotation = 90 }, p)
	end
end
local function box(props, parent)
	props.BorderSizePixel = 0
	return new("Frame", props, parent)
end
local function label(text, size, parent, props)
	local t = new("TextLabel", {
		Text = text, FontFace = S.font, TextSize = size, TextColor3 = props and props.color or S.text,
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = px(0, 0),
	}, parent)
	local w = props and props.strokeW or S.strokeW
	if w > 0 then
		new("UIStroke", { Color = S.stroke, Thickness = w, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	end
	return t
end
local function row(parent, gap)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
end

-- icons drawn with frames, 40 px box
local function coin(parent, d)
	local c = box({ Size = px(d, d), BackgroundColor3 = rgb(255, 194, 26) }, parent)
	corner(c, d)
	stroke(c, INK, math.max(2, d / 14))
	local i = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = px(d * 0.55, d * 0.55), BackgroundTransparency = 1 }, c)
	corner(i, d)
	stroke(i, rgb(230, 154, 0), math.max(1.5, d / 16))
	return c
end
local ICONS = {
	bag = function(f)
		local h = box({ Position = px(13, 4), Size = px(14, 14), BackgroundTransparency = 1 }, f)
		corner(h, 7)
		stroke(h, INK, 3)
		local b = box({ Position = px(6, 13), Size = px(28, 23), BackgroundColor3 = rgb(255, 210, 63) }, f)
		corner(b, 5)
		stroke(b, INK, 3)
	end,
	pack = function(f)
		local b = box({ Position = px(8, 8), Size = px(24, 28), BackgroundColor3 = rgb(47, 156, 232) }, f)
		corner(b, 7)
		stroke(b, INK, 3)
		local p = box({ Position = px(5, 13), Size = px(14, 9), BackgroundColor3 = rgb(127, 208, 255) }, b)
		corner(p, 2)
		stroke(p, INK, 2)
	end,
	gift = function(f)
		local b = box({ Position = px(7, 16), Size = px(26, 20), BackgroundColor3 = rgb(224, 48, 42) }, f)
		corner(b, 3)
		stroke(b, INK, 3)
		local l = box({ Position = px(4, 10), Size = px(32, 8), BackgroundColor3 = rgb(255, 90, 79), ZIndex = 2 }, f)
		corner(l, 2)
		stroke(l, INK, 3)
		box({ Position = px(18, 10), Size = px(4, 26), BackgroundColor3 = rgb(255, 210, 63), ZIndex = 3 }, f)
	end,
	gear = function(f)
		for _, a in { 0, 45, 90, 135 } do
			local t = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = px(20, 20), Size = px(34, 8), Rotation = a, BackgroundColor3 = rgb(255, 255, 255) }, f)
			corner(t, 2)
		end
		local r = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = px(20, 20), Size = px(26, 26), BackgroundColor3 = rgb(255, 255, 255) }, f)
		corner(r, 13)
		local d = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = px(20, 20), Size = px(11, 11), BackgroundColor3 = S.btn }, f)
		corner(d, 6)
	end,
}
local function icon(name, parent, size)
	local f = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = px(40, 40), BackgroundTransparency = 1 }, parent)
	new("UIScale", { Scale = size / 40 }, f)
	ICONS[name](f)
	return f
end

-- placeholder item models
local function part(model, props)
	props.Anchored = true
	props.TopSurface = Enum.SurfaceType.Smooth
	props.BottomSurface = Enum.SurfaceType.Smooth
	if not props.Material then
		props.Material = Enum.Material.SmoothPlastic
	end
	return new("Part", props, model)
end
local SHAPES = {
	gem = function(m)
		part(m, { Size = Vector3.new(2, 2, 2), Color = rgb(58, 184, 255), Reflectance = 0.15, CFrame = CFrame.Angles(math.rad(45), 0, math.rad(35.26)) })
	end,
	sword = function(m)
		local tilt = CFrame.Angles(0, 0, math.rad(-45))
		part(m, { Size = Vector3.new(0.6, 3.4, 0.25), Color = rgb(215, 227, 240), Reflectance = 0.2, CFrame = tilt * CFrame.new(0, 1.2, 0) })
		part(m, { Size = Vector3.new(1.8, 0.35, 0.4), Color = rgb(232, 162, 58), CFrame = tilt * CFrame.new(0, -0.6, 0) })
		part(m, { Size = Vector3.new(0.35, 1.1, 0.35), Color = rgb(138, 90, 43), CFrame = tilt * CFrame.new(0, -1.3, 0) })
	end,
	egg = function(m)
		local e = part(m, { Size = Vector3.new(2, 2.6, 2), Color = rgb(244, 238, 252), CFrame = CFrame.new() })
		new("SpecialMesh", { MeshType = Enum.MeshType.Sphere }, e)
		for _, p in { Vector3.new(-0.45, 0.4, -0.85), Vector3.new(0.5, -0.2, -0.85), Vector3.new(-0.2, -0.75, -0.8) } do
			part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Color = rgb(154, 107, 224), CFrame = CFrame.new(p) })
		end
	end,
	potion = function(m)
		part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), Color = rgb(226, 70, 160), Reflectance = 0.1, CFrame = CFrame.new(0, -0.3, 0) })
		part(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 0.6, 0.6), Color = rgb(200, 230, 240), CFrame = CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)) })
		part(m, { Size = Vector3.new(0.5, 0.35, 0.5), Color = rgb(150, 100, 60), CFrame = CFrame.new(0, 1.4, 0) })
	end,
}
local function viewport(item, parent, size)
	local vf = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = px(size, size), BackgroundTransparency = 1,
		Ambient = rgb(120, 120, 130), LightColor = rgb(255, 255, 255), LightDirection = Vector3.new(0.7, -1, 0.6),
	}, parent)
	local m
	if item.model then
		m = item.model:Clone()
		if m:IsA("BasePart") then
			local w = Instance.new("Model")
			m.Parent = w
			m = w
		end
	else
		m = Instance.new("Model")
		SHAPES[item.shape or "gem"](m)
	end
	m.Parent = vf
	local cf, sz = m:GetBoundingBox()
	local r = sz.Magnitude / 2
	local cam = new("Camera", { FieldOfView = 40 }, vf)
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, r * 0.35, -r * 2.9), cf.Position)
	vf.CurrentCamera = cam
end

-- build
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
for _, o in { StarterGui:FindFirstChild("UiStyleMock"), Lighting:FindFirstChild("UiStyleMockBlur") } do
	o:Destroy()
end
if CONFIG.blur > 0 then
	new("BlurEffect", { Name = "UiStyleMockBlur", Size = CONFIG.blur }, Lighting)
end

local vp = workspace.CurrentCamera.ViewportSize
local k = vp.Y / 576 -- layout is drawn for a 576 px tall screen and scaled
local gui = Instance.new("ScreenGui")
gui.Name = "UiStyleMock"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
local root = box({ Size = px(vp.X / k, 576), BackgroundTransparency = 1 }, gui)
new("UIScale", { Scale = k }, root)

local function button(parent, props, d, round)
	local b = box(props, parent)
	b.Size = px(d, d)
	b.BackgroundColor3 = S.btn
	b.BackgroundTransparency = S.btnT
	corner(b, round and d or S.btnRadius)
	stroke(b, S.btnStroke, S.btnStrokeW, S.btnStrokeT)
	grad(b, S.btnGrad)
	return b
end

-- left menu
local menu = box({ Position = px(14, 120), Size = px(78, 258), BackgroundTransparency = 1 }, root)
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, menu)
for i, n in { "bag", "pack", "gift" } do
	icon(n, button(menu, { LayoutOrder = i }, 78), 48)
end
-- settings
icon("gear", button(root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 14) }, 54, true), 36)
-- currency and bar
local cash = box({ Position = UDim2.new(0, 16, 1, -50), AnchorPoint = Vector2.new(0, 1), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1 }, root)
row(cash, 8)
coin(cash, 40).LayoutOrder = 1
label(CONFIG.currency, 38, cash, { color = rgb(255, 255, 255), strokeW = math.max(S.strokeW, 2) }).LayoutOrder = 2 -- over the world: always light with a stroke
local bar = box({ Position = UDim2.new(0, 16, 1, -20), AnchorPoint = Vector2.new(0, 1), Size = px(220, 14), BackgroundColor3 = S.barTrack }, root)
corner(bar, 7)
corner(box({ Size = UDim2.fromScale(0.62, 1), BackgroundColor3 = S.barFill }, bar), 7)

-- shop panel
local W, H, HEAD = 470, 420, 66
local panelPos = UDim2.new(0.5, 0, 0.52, 0)
if S.lip then
	local lip = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = panelPos + px(0, 6), Size = px(W, H), BackgroundColor3 = S.lip }, root)
	corner(lip, S.radius)
end
local panel = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = panelPos, Size = px(W, H), BackgroundColor3 = S.panel, BackgroundTransparency = S.panelT }, root)
corner(panel, S.radius)
stroke(panel, S.panelStroke, S.panelStrokeW, S.panelStrokeT)
if S.header then
	local hd = box({ Size = px(W, HEAD), BackgroundColor3 = rgb(255, 255, 255) }, panel)
	corner(hd, S.radius)
	grad(hd, S.header)
	local sq = box({ Position = px(0, HEAD / 2), Size = px(W, HEAD / 2), BackgroundColor3 = rgb(255, 255, 255) }, panel)
	grad(sq, { S.header[1]:Lerp(S.header[2], 0.5), S.header[2] })
end
if S.accent then
	box({ Position = px(0, HEAD - 2), Size = px(W, 2), BackgroundColor3 = S.accent }, panel)
end
local title = box({ Position = px(14, HEAD / 2), AnchorPoint = Vector2.new(0, 0.5), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1 }, panel)
row(title, 10)
local ti = box({ Size = px(40, 40), BackgroundTransparency = 1, LayoutOrder = 1 }, title)
icon("bag", ti, 40)
label(CONFIG.title, 30, title, { color = S.header and rgb(255, 255, 255) or S.text, strokeW = S.header and math.max(S.strokeW, 2) or S.strokeW }).LayoutOrder = 2
local close = box({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, HEAD / 2), Size = px(46, 46), BackgroundColor3 = S.close or S.panel, BackgroundTransparency = S.close and 0 or 1 }, panel)
corner(close, 10)
stroke(close, S.close and S.stroke or S.panelStroke, S.close and 2 or 1)
local x = label("X", 30, close, { color = rgb(255, 255, 255), strokeW = S.close and 2 or 0 })
x.AnchorPoint = Vector2.new(0.5, 0.5)
x.Position = UDim2.fromScale(0.5, 0.5)

local grid = box({ Position = px(14, HEAD + 14), Size = px(W - 28, H - HEAD - 28), BackgroundTransparency = 1 }, panel)
new("UIGridLayout", { CellSize = UDim2.new(0.5, -7, 0.5, -7), CellPadding = px(14, 14), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
for i, item in CONFIG.items do
	if i > 4 then
		break
	end
	local card = box({ LayoutOrder = i, BackgroundColor3 = S.card, BackgroundTransparency = S.cardT }, grid)
	corner(card, S.cardRadius)
	stroke(card, S.cardStroke, S.cardStrokeW, S.cardStrokeT)
	viewport(item, card, 92)
	local chip = box({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = S.chip or S.card, BackgroundTransparency = S.chip and 0 or 1 }, card)
	corner(chip, 10)
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 4) }, chip)
	row(chip, 6)
	if S.chipLip then
		new("UIStroke", { Color = S.chipLip, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, chip)
	end
	coin(chip, 26).LayoutOrder = 1
	label(item.price, 28, chip, { color = S.chipText or rgb(255, 255, 255), strokeW = S.chipText and 0 or math.max(S.strokeW, 2) }).LayoutOrder = 2
end

StarterGui.ShowDevelopmentGui = true
gui.Parent = StarterGui
return ("UiStyleMock built: %s, viewport %dx%d"):format(CONFIG.preset, vp.X, vp.Y)
