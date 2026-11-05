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

-- Each preset follows its card in assets/ui-styles. rarity: one color per item card, drawn as
-- "fill" (card color, diagonal shade), "line" (thin bar over the price) or "tag" (small pill top-left).
local PRESETS = {
	["soft-dark"] = {
		font = fredoka, text = rgb(255, 255, 255), stroke = rgb(25, 28, 36), strokeW = 2,
		panel = rgb(32, 34, 40), panelT = 0.1, panelStroke = rgb(255, 255, 255), panelStrokeW = 2, panelStrokeT = 0.8, radius = 10, lip = nil,
		header = nil, pills = { rgb(250, 200, 40), rgb(160, 90, 240), rgb(60, 210, 220) },
		card = rgb(60, 64, 74), cardT = 0, cardStroke = rgb(255, 255, 255), cardStrokeW = 1, cardStrokeT = 0.7, cardRadius = 6,
		rarity = { rgb(250, 190, 30), rgb(150, 80, 235), rgb(30, 195, 200), rgb(240, 70, 160) }, rarityMode = "fill",
		chip = rgb(30, 32, 40), chipLip = nil, chipWide = false, close = rgb(224, 48, 42), closeRadius = 4,
		btn = rgb(35, 40, 48), btnT = 0.15, btnGrad = nil, btnStroke = rgb(255, 255, 255), btnStrokeW = 2, btnStrokeT = 0.8, btnRadius = 12, chipText = nil,
	},
	["stud-chunky"] = {
		font = fredoka, text = rgb(255, 255, 255), stroke = rgb(13, 15, 24), strokeW = 3,
		panel = rgb(28, 32, 62), panelT = 0, panelStroke = rgb(13, 15, 24), panelStrokeW = 4, panelStrokeT = 0, radius = 16, lip = rgb(13, 15, 24),
		header = { rgb(150, 95, 250), rgb(75, 70, 220) }, sheen = true,
		card = rgb(46, 52, 84), cardT = 0, cardStroke = rgb(13, 15, 24), cardStrokeW = 3, cardStrokeT = 0, cardRadius = 10,
		rarity = { rgb(60, 200, 60), rgb(40, 130, 240), rgb(150, 70, 230), rgb(225, 50, 60) }, rarityMode = "fill",
		chip = rgb(120, 220, 40), chipLip = rgb(60, 140, 20), chipWide = true, close = rgb(224, 48, 42),
		btn = rgb(140, 90, 230), btnT = 0, btnGrad = { rgb(170, 120, 245), rgb(118, 62, 208) }, btnStroke = rgb(13, 15, 24), btnStrokeW = 4, btnStrokeT = 0, btnRadius = 16, chipText = nil,
	},
	["bright-cards"] = {
		font = fredoka, text = rgb(43, 47, 69), stroke = rgb(25, 60, 110), strokeW = 0,
		panel = rgb(255, 255, 255), panelT = 0, panelStroke = rgb(120, 200, 245), panelStrokeW = 4, panelStrokeT = 0, radius = 18, lip = nil,
		header = { rgb(90, 190, 255), rgb(40, 140, 230) }, headerTab = true, pills = { rgb(240, 90, 160), rgb(250, 200, 40), rgb(80, 200, 90), rgb(160, 110, 240) },
		card = rgb(215, 238, 252), cardT = 0, cardStroke = rgb(255, 255, 255), cardStrokeW = 3, cardStrokeT = 0, cardRadius = 14,
		rarity = { rgb(190, 90, 240), rgb(70, 140, 240), rgb(250, 190, 40), rgb(170, 110, 240) }, rarityMode = "tag",
		chip = rgb(90, 200, 60), chipLip = rgb(40, 140, 30), chipWide = true, close = rgb(235, 60, 70),
		btn = rgb(150, 215, 250), btnT = 0, btnGrad = { rgb(190, 235, 255), rgb(110, 190, 245) }, btnStroke = rgb(60, 150, 230), btnStrokeW = 3, btnStrokeT = 0, btnRadius = 14, chipText = nil,
	},
	["dark-flat"] = {
		font = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold), text = rgb(235, 238, 245), stroke = rgb(0, 0, 0), strokeW = 0,
		panel = rgb(22, 24, 28), panelT = 0.05, panelStroke = rgb(55, 58, 66), panelStrokeW = 1, panelStrokeT = 0, radius = 8, lip = nil,
		header = nil, accent = rgb(55, 58, 66),
		card = rgb(34, 36, 42), cardT = 0, cardStroke = rgb(48, 50, 58), cardStrokeW = 1, cardStrokeT = 0, cardRadius = 4,
		rarity = { rgb(40, 130, 240), rgb(150, 80, 235), rgb(240, 160, 30), rgb(150, 80, 235) }, rarityMode = "line",
		chip = rgb(60, 200, 70), chipLip = nil, chipWide = true, close = rgb(200, 40, 40), closeRadius = 4,
		btn = rgb(30, 32, 38), btnT = 0.1, btnGrad = nil, btnStroke = rgb(55, 58, 66), btnStrokeW = 1, btnStrokeT = 0, btnRadius = 6, chipText = rgb(255, 255, 255),
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
	local needHttp = false
	for _, v in wanted do
		needHttp = needHttp or not v:find("^rbxassetid://")
	end
	if needHttp then
		-- since the 2026-11-04 Studio update, HTTP from execute_luau needs MCP Permissions >
		-- Connect to the internet with 127.0.0.1 allowed, which a local .rbxl cannot have
		local readOk, was = pcall(function()
			return HttpService.HttpEnabled
		end)
		assert(readOk, "local icons need HTTP: open a place saved to Roblox with MCP Permissions > "
			.. "Connect to the internet and 127.0.0.1 allowed, or use rbxassetid:// icons. " .. tostring(was))
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
	return new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
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
local cash = box({ Position = UDim2.new(0, 16, 1, -16), AnchorPoint = Vector2.new(0, 1), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = S.btn, BackgroundTransparency = S.btnT }, root)
corner(cash, S.btnRadius * 2)
stroke(cash, S.btnStroke, S.btnStrokeW, S.btnStrokeT)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 18), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, cash)
row(cash, 8)
img(CONFIG.icons.coin, cash, 44, { LayoutOrder = 1 })
label(CONFIG.currency, 34, cash, { color = rgb(255, 255, 255), strokeW = math.max(S.strokeW, 2) }).LayoutOrder = 2 -- always light with a stroke

-- shop panel
local W, H, HEAD = 470, 420, 66
local panelPos = UDim2.new(0.5, 0, 0.52, 0)
if S.lip then
	corner(box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = panelPos + px(0, 6), Size = px(W, H), BackgroundColor3 = S.lip }, root), S.radius)
end
local panel = box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = panelPos, Size = px(W, H), BackgroundColor3 = S.panel, BackgroundTransparency = S.panelT }, root)
corner(panel, S.radius)
stroke(panel, S.panelStroke, S.panelStrokeW, S.panelStrokeT)
if S.header and not S.headerTab then
	local hd = box({ Size = px(W, HEAD), BackgroundColor3 = rgb(255, 255, 255) }, panel)
	corner(hd, S.radius)
	grad(hd, S.header)
	local sq = box({ Position = px(0, HEAD / 2), Size = px(W, HEAD / 2), BackgroundColor3 = rgb(255, 255, 255) }, panel)
	grad(sq, { S.header[1]:Lerp(S.header[2], 0.5), S.header[2] })
	if S.sheen then -- two light diagonal stripes across the band
		local clip = box({ Size = px(W, HEAD), BackgroundTransparency = 1, ClipsDescendants = true }, panel)
		for i, x in { 0.56, 0.68 } do
			box({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 0.5, 0), Size = px(i == 1 and 34 or 16, HEAD * 2), Rotation = 28, BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.82 }, clip)
		end
	end
end
if S.accent then
	box({ Position = px(0, HEAD - 2), Size = px(W, 2), BackgroundColor3 = S.accent }, panel)
end
-- title row: icon and title (inside a colored tab that sticks out of the corner when headerTab), then pill chips
local head = box({ Position = px(S.headerTab and -10 or 14, S.headerTab and 6 or HEAD / 2), AnchorPoint = Vector2.new(0, 0.5), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1 }, panel)
row(head, 12)
local title = head
if S.headerTab then
	title = box({ LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = rgb(255, 255, 255) }, head)
	corner(title, 16)
	grad(title, S.header)
	stroke(title, S.panelStroke:Lerp(rgb(255, 255, 255), 0.4), 3)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, title)
	row(title, 8)
end
img(CONFIG.icons.title, title, 44, { LayoutOrder = 1 })
label(CONFIG.title, 30, title, { color = S.header and rgb(255, 255, 255) or S.text, strokeW = S.header and math.max(S.strokeW, 2) or S.strokeW }).LayoutOrder = 2
for i, c in S.pills or {} do
	corner(box({ LayoutOrder = 2 + i, Size = px(34, 14), BackgroundColor3 = c }, head), 7)
end
local close = box({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, HEAD / 2), Size = px(46, 46), BackgroundColor3 = S.close or S.panel, BackgroundTransparency = S.close and 0 or 1 }, panel)
corner(close, S.closeRadius or 10)
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
	local rc = S.rarity and S.rarity[i]
	local card = box({ LayoutOrder = i, BackgroundColor3 = (S.rarityMode == "fill" and rc) or S.card, BackgroundTransparency = S.cardT }, grid)
	corner(card, S.cardRadius)
	stroke(card, S.cardStroke, S.cardStrokeW, S.cardStrokeT)
	if rc and S.rarityMode == "fill" then -- diagonal shade, light top-left
		new("UIGradient", { Color = ColorSequence.new(rgb(255, 255, 255), rgb(170, 170, 170)), Rotation = 45 }, card)
	elseif rc and S.rarityMode == "line" then
		box({ Position = UDim2.new(0, 0, 1, -58), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = rc }, card)
	elseif rc and S.rarityMode == "tag" then
		corner(box({ Position = px(10, 8), Size = px(40, 14), BackgroundColor3 = rc }, card), 7)
	end
	local iconSize = S.chipWide and 90 or 100
	if item.model then
		viewport(item.model, card, iconSize)
	else
		img(item.icon, card, iconSize, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8) })
	end
	local chip = box({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), AutomaticSize = S.chipWide and Enum.AutomaticSize.None or Enum.AutomaticSize.XY, Size = S.chipWide and UDim2.new(1, -20, 0, 42) or px(0, 0), BackgroundColor3 = S.chip or S.card, BackgroundTransparency = S.chip and 0 or 1 }, card)
	corner(chip, 10)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 4) }, chip)
	row(chip, 6).HorizontalAlignment = Enum.HorizontalAlignment.Center
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
