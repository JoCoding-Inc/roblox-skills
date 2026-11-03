--!nocheck
-- UI style mockup built as a real ScreenGui in the game's own place, so fonts, strokes,
-- corners, icons and the world behind it are what the game will show.
-- Use: start `python3 -I serve_icons.py <png dir>` (local icons, nothing is uploaded), edit CONFIG,
-- run in Edit mode (Studio MCP execute_luau), screen_capture, show the user.
-- Local icons load over 127.0.0.1 into EditableImages; HttpService.HttpEnabled is switched on
-- only while loading and restored. Remove after: StarterGui.UiStyleMock, Lighting.UiStyleMockBlur.

local CONFIG = {
	preset = "soft-dark", -- soft-dark | stud-chunky | bright-cards | dark-flat
	override = {}, -- any STYLE key, for example { chip = Color3.fromRGB(150, 230, 40) }
	title = "SHOP",
	currency = "8,423",
	-- an image is a name served by serve_icons.py or an uploaded "rbxassetid://" id
	-- bundled names (assets/ui-styles/icons): gem sword egg star coin bag pack gift gear
	iconServer = "http://127.0.0.1:18765/",
	iconSize = 192, -- serve_icons.py output size
	icons = { menu = { "bag", "pack", "gift" }, settings = "gear", coin = "coin", title = "bag" },
	items = {
		{ price = "150", icon = "gem" },
		{ price = "300", icon = "sword" },
		{ price = "500", icon = "egg" },
		{ price = "750", icon = "star" },
		-- { price = "990", model = game.ReplicatedStorage.Pets.Dog }, -- a 3D item from the game
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

-- images: load every local icon once, with HTTP on only for the fetch
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")
local images = {}
do
	local wanted = { CONFIG.icons.settings, CONFIG.icons.coin, CONFIG.icons.title }
	for _, v in CONFIG.icons.menu do
		table.insert(wanted, v)
	end
	for _, it in CONFIG.items do
		if it.icon then
			table.insert(wanted, it.icon)
		end
	end
	local was = HttpService.HttpEnabled
	HttpService.HttpEnabled = true
	local ok, err = pcall(function()
		local n = CONFIG.iconSize
		for _, v in wanted do
			if images[v] == nil and not v:find("^rbxassetid://") then
				local body = HttpService:GetAsync(CONFIG.iconServer .. v .. ".rgba")
				local ei = AssetService:CreateEditableImage({ Size = Vector2.new(n, n) })
				ei:WritePixelsBuffer(Vector2.zero, Vector2.new(n, n), buffer.fromstring(body))
				images[v] = Content.fromObject(ei)
			end
		end
	end)
	HttpService.HttpEnabled = was
	assert(ok, "icon load failed (is serve_icons.py running?): " .. tostring(err))
end

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
local function img(v, parent, size, props)
	local i = new("ImageLabel", { Size = px(size, size), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit }, parent)
	if v:find("^rbxassetid://") then
		i.Image = v
	else
		i.ImageContent = images[v]
	end
	for k, x in props or {} do
		i[k] = x
	end
	return i
end
local function centered(v, parent, size)
	return img(v, parent, size, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
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
local function viewport(model, parent, size)
	local vf = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = px(size, size), BackgroundTransparency = 1,
		Ambient = rgb(120, 120, 130), LightColor = rgb(255, 255, 255), LightDirection = Vector3.new(0.7, -1, 0.6),
	}, parent)
	local m = model:Clone()
	if m:IsA("BasePart") then
		local w = Instance.new("Model")
		m.Parent = w
		m = w
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

-- left menu, settings, currency
local menu = box({ Position = px(14, 120), Size = px(78, 258), BackgroundTransparency = 1 }, root)
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, menu)
for i, v in CONFIG.icons.menu do
	centered(v, button(menu, { LayoutOrder = i }, 78), 58)
end
centered(CONFIG.icons.settings, button(root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 14) }, 56, true), 40)
local cash = box({ Position = UDim2.new(0, 16, 1, -50), AnchorPoint = Vector2.new(0, 1), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1 }, root)
row(cash, 8)
img(CONFIG.icons.coin, cash, 44, { LayoutOrder = 1 })
label(CONFIG.currency, 38, cash, { color = rgb(255, 255, 255), strokeW = math.max(S.strokeW, 2) }).LayoutOrder = 2 -- over the world: always light with a stroke
local bar = box({ Position = UDim2.new(0, 16, 1, -20), AnchorPoint = Vector2.new(0, 1), Size = px(220, 14), BackgroundColor3 = S.barTrack }, root)
corner(bar, 7)
corner(box({ Size = UDim2.fromScale(0.62, 1), BackgroundColor3 = S.barFill }, bar), 7)

-- shop panel
local W, H, HEAD = 470, 420, 66
local panelPos = UDim2.new(0.5, 0, 0.52, 0)
if S.lip then
	corner(box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = panelPos + px(0, 6), Size = px(W, H), BackgroundColor3 = S.lip }, root), S.radius)
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
img(CONFIG.icons.title, title, 44, { LayoutOrder = 1 })
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
	if item.model then
		viewport(item.model, card, 100)
	else
		img(item.icon, card, 100, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8) })
	end
	local chip = box({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = S.chip or S.card, BackgroundTransparency = S.chip and 0 or 1 }, card)
	corner(chip, 10)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 4) }, chip)
	row(chip, 6)
	if S.chipLip then
		new("UIStroke", { Color = S.chipLip, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, chip)
		grad(chip, { rgb(255, 255, 255), rgb(215, 215, 215) }) -- gloss: lighter top
	end
	img(CONFIG.icons.coin, chip, 30, { LayoutOrder = 1 })
	label(item.price, 28, chip, { color = S.chipText or rgb(255, 255, 255), strokeW = S.chipText and 0 or math.max(S.strokeW, 2) }).LayoutOrder = 2
end

StarterGui.ShowDevelopmentGui = true
gui.Parent = StarterGui
return ("UiStyleMock built: %s, viewport %dx%d"):format(CONFIG.preset, vp.X, vp.Y)
