-- WindowKit demo: a missions window over a HUD, built with WindowKit, and a tour that plays every
-- motion: the HUD gives way and the window opens in order, select, change tab, a routine claim
-- (rewards burst, fly to the counters, the row leaves and comes back at the bottom), a special claim
-- (a stamped title over rays, then the re-sort), close with the HUD sliding back.
-- Setup: WindowKit and this file as ModuleScripts in one folder (ReplicatedStorage.Ui), then from a
-- LocalScript: require(ReplicatedStorage.Ui.WindowKitDemo).run()   -- loops the tour until the gui is destroyed
-- It lays out twice: a phone layout in device px (window 532 x 236, text 14 px and up, 44 px tap
-- areas, HUD clear of the thumbstick and the jump button) and a larger layout for tablet and desktop
-- that Kit.stage sizes by its share of the screen. Read it for the structure and the calls.
-- The look is a skin, not the kit: Demo.SKINS holds three (arcade, grim, tech), each one table of
-- colours, two fonts, a Kit.look and a Kit.tone (and `glow` for a dark matte one). The same build runs under all three:
-- Demo.run(nil, { skin = "grim" }). Write your game's skin first, from its own palette and font
-- pair; do not ship one of these.
-- Icons: image ids of a free Creator Store icon pack (the simulator pack the icon guide names). Use
-- your game's pack: Demo.build(playerGui, { icons = { coin = "rbxassetid://...", ... } }).
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Kit = require(script.Parent.WindowKit)

local Demo = {}

local ICONS = {
	coin = "rbxassetid://17368060122",
	gem = "rbxassetid://17368064384",
	shop = "rbxassetid://17368217589",
	pets = "rbxassetid://16697439085",
	missions = "rbxassetid://17368118782",
	play = "rbxassetid://16670799841",
	close = "rbxassetid://17368208554",
	timer = "rbxassetid://15937828418",
	egg = "rbxassetid://17368104272",
	race = "rbxassetid://17368052918",
	feed = "rbxassetid://84364030718064",
	boss = "rbxassetid://17368210998",
	trade = "rbxassetid://15403064919",
	chest = "rbxassetid://15402967660",
	wins = "rbxassetid://12129301834",
}

local rgb = Color3.fromRGB
local function face(family: string, weight: Enum.FontWeight)
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight)
end
-- A skin. Colours keep three levels of value under every look: a dark well, a mid window, one
-- light card. The eye goes to the card first.
-- Optional: number = a heavier face for prices and amounts on a coloured button, when the display face is light.
local SKINS = {
	-- bright arcade: round, glossy, outlined, bouncy
	arcade = {
		colors = {
			window = rgb(46, 52, 148),
			header = rgb(98, 92, 255),
			well = rgb(24, 26, 88),
			row = rgb(54, 84, 196),
			rowSelected = rgb(84, 124, 246),
			rowDone = rgb(44, 48, 122),
			select = rgb(255, 255, 255),
			card = rgb(244, 246, 255),
			cardHead = rgb(212, 218, 255),
			coinTile = rgb(255, 238, 184),
			gemTile = rgb(244, 224, 255),
			tileDone = rgb(222, 225, 240),
			dailyTile = rgb(24, 70, 124),
			weeklyTile = rgb(70, 40, 128),
			ink = rgb(26, 28, 74),
			inkMuted = rgb(74, 80, 134),
			text = rgb(255, 255, 255),
			muted = rgb(190, 198, 255),
			accent = rgb(255, 196, 60),
			gold = rgb(255, 196, 60),
			warn = rgb(236, 64, 82),
			ready = rgb(92, 224, 110),
			go = rgb(58, 196, 92),
			idle = rgb(100, 108, 176),
			done = rgb(142, 146, 172),
			ribbon = rgb(126, 84, 255),
			daily = rgb(64, 190, 255),
			weekly = rgb(190, 136, 255),
			dark = rgb(16, 18, 56),
			hud = rgb(36, 40, 112),
			empty = rgb(196, 203, 236),
		},
		-- one family, two weights
		black = face("Nunito", Enum.FontWeight.Heavy),
		bold = face("Nunito", Enum.FontWeight.ExtraBold),
		look = { radius = 1, outline = 1, depth = 1, shine = true, textOutline = 1 },
		tone = "playful",
	},
	-- horror, survival: charcoal and aged paper, tight corners, matte, no bounce, slower
	grim = {
		colors = {
			window = rgb(40, 37, 34),
			header = rgb(96, 24, 22),
			well = rgb(20, 19, 18),
			row = rgb(60, 55, 50),
			rowSelected = rgb(98, 86, 70),
			rowDone = rgb(34, 32, 30),
			select = rgb(222, 208, 180),
			card = rgb(216, 204, 180),
			cardHead = rgb(190, 176, 150),
			coinTile = rgb(230, 212, 164),
			gemTile = rgb(204, 196, 188),
			tileDone = rgb(172, 164, 150),
			dailyTile = rgb(44, 52, 46),
			weeklyTile = rgb(70, 30, 26),
			ink = rgb(34, 26, 22),
			inkMuted = rgb(92, 78, 66),
			text = rgb(234, 226, 210),
			muted = rgb(164, 154, 140),
			accent = rgb(222, 64, 48),
			gold = rgb(218, 186, 112),
			warn = rgb(222, 64, 48),
			ready = rgb(176, 196, 104),
			go = rgb(86, 110, 46),
			idle = rgb(86, 80, 74),
			done = rgb(112, 106, 98),
			ribbon = rgb(26, 22, 20),
			daily = rgb(156, 176, 156),
			weekly = rgb(200, 132, 88),
			dark = rgb(12, 11, 10),
			hud = rgb(30, 28, 26),
			empty = rgb(162, 152, 132),
		},
		black = face("SpecialElite", Enum.FontWeight.Regular),
		bold = face("SourceSansPro", Enum.FontWeight.Bold),
		number = face("SourceSansPro", Enum.FontWeight.Bold), -- prices and amounts on a coloured button: a typewriter face is too light there
		look = { radius = 0.25, outline = 1, depth = 0.5, shine = false, textOutline = 0, lift = 0.06 },
		tone = "heavy",
	},
	-- sci-fi, racing: near-black blue, one thin cyan line on every surface, flat, quick
	tech = {
		colors = {
			window = rgb(14, 22, 34),
			header = rgb(18, 46, 68),
			well = rgb(8, 13, 22),
			row = rgb(20, 34, 52),
			rowSelected = rgb(26, 66, 94),
			rowDone = rgb(14, 22, 32),
			select = rgb(120, 240, 255),
			card = rgb(202, 228, 238),
			cardHead = rgb(164, 202, 218),
			coinTile = rgb(238, 224, 172),
			gemTile = rgb(192, 216, 250),
			tileDone = rgb(152, 174, 186),
			dailyTile = rgb(12, 52, 72),
			weeklyTile = rgb(58, 28, 76),
			ink = rgb(10, 26, 40),
			inkMuted = rgb(50, 82, 104),
			text = rgb(222, 244, 255),
			muted = rgb(124, 172, 198),
			accent = rgb(64, 230, 255),
			gold = rgb(255, 214, 110),
			warn = rgb(255, 86, 110),
			ready = rgb(90, 255, 190),
			go = rgb(30, 200, 150),
			idle = rgb(50, 76, 100),
			done = rgb(80, 100, 116),
			ribbon = rgb(0, 130, 170),
			daily = rgb(64, 200, 255),
			weekly = rgb(255, 120, 220),
			dark = rgb(4, 8, 14),
			hud = rgb(12, 20, 32),
			empty = rgb(132, 162, 178),
		},
		black = face("TitilliumWeb", Enum.FontWeight.Bold),
		bold = face("TitilliumWeb", Enum.FontWeight.SemiBold),
		-- matte is not flat: the panels keep a faint top-to-bottom fall and a 1 px light line inside the top edge,
		-- and the selected row glows. TitilliumWeb draws small (capitals 0.45 of TextSize): Kit.textSize makes up for it
		look = { radius = 0.3, outline = 0.75, depth = 0, shine = false, textOutline = 0, lift = 0.1, topLight = true, stroke = rgb(44, 128, 164) },
		glow = true,
		tone = "crisp",
	},
}
Demo.SKINS = SKINS
local C = table.clone(SKINS.arcade.colors)
local BLACK, BOLD = SKINS.arcade.black, SKINS.arcade.bold
local NUMBER = BLACK -- prices, amounts on a coloured button, badge counts: the skin's `number` face, else the display face
local GLOW = false -- the skin's `glow`: the selected row carries a halo (a dark matte skin, where gloss is off)

Demo.ICONS = ICONS

local MISSIONS = {
	{ id = "d1", tab = "Daily", icon = "egg", title = "Hatch 5 eggs", info = "Any egg counts. Golden eggs count twice.", have = 5, need = 5, coins = 250, gems = 5 },
	{ id = "d2", tab = "Daily", icon = "race", title = "Win 3 races", info = "Finish first on any track.", have = 2, need = 3, coins = 400, gems = 5 },
	{ id = "d3", tab = "Daily", icon = "feed", title = "Feed your pet", info = "Give any pet a treat from the shop.", have = 0, need = 1, coins = 120, gems = 0 },
	{ id = "d4", tab = "Daily", icon = "chest", title = "Open 3 gifts", info = "Gifts drop from every tenth enemy.", have = 1, need = 3, coins = 300, gems = 0 },
	{ id = "w1", tab = "Weekly", icon = "boss", title = "Beat the island boss", info = "Clear the last gate of any island.", have = 4, need = 4, coins = 2000, gems = 25, special = true },
	{ id = "w2", tab = "Weekly", icon = "trade", title = "Trade with 4 friends", info = "Complete a trade in the plaza.", have = 1, need = 4, coins = 900, gems = 10 },
	{ id = "w3", tab = "Weekly", icon = "wins", title = "Reach 10 wins", info = "Any mode counts, solo or with friends.", have = 7, need = 10, coins = 1500, gems = 15 },
}
local TABS = { "All", "Daily", "Weekly" }

local function text(parent: Instance, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = BOLD
	label.TextColor3 = C.text
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in props do
		(label :: any)[k] = v
	end
	label.TextSize = Kit.textSize(label.TextSize, label.FontFace) -- a face that draws small gets a larger size
	label.Parent = parent
	return label
end

local function outline(label: TextLabel, color: Color3?, width: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or C.dark
	s.Thickness = (width or 2) * math.max(Kit.LOOK.textOutline, 0.01)
	s.Enabled = Kit.LOOK.textOutline > 0
	s.Parent = label
	return label
end

local function short(n: number): string -- 2000 -> "2K": a reward tile is narrow on a phone
	if n >= 1000 then
		return (string.format("%.1fK", n / 1000):gsub("%.0K", "K"))
	end
	return tostring(n)
end

local function timeLeft(tab: string): string
	local now = os.time()
	local left = 86400 - now % 86400
	if tab == "Weekly" then
		left += (6 - (math.floor(now / 86400) + 3) % 7) * 86400 -- to the end of Sunday (UTC)
		return string.format("%dd %02d:%02d", left // 86400, left % 86400 // 3600, left % 3600 // 60)
	end
	return string.format("%02d:%02d:%02d", left // 3600, left % 3600 // 60, left % 60)
end

-- Put a skin on: a name of Demo.SKINS or your own table { colors, black, bold, look, tone } (what it
-- leaves out comes from arcade). Returns (colours, display font, body font). Other windows built on
-- the kit (window_kit_layouts.luau) call this, so one game has one skin.
function Demo.skin(skin: (string | { [string]: any })?)
	local chosen = (type(skin) == "string" and SKINS[skin] or skin or SKINS.arcade) :: any
	assert(type(chosen) == "table", "Demo.skin: a name of Demo.SKINS or a skin table")
	for k, v in SKINS.arcade.colors do
		(C :: any)[k] = (chosen.colors and chosen.colors[k]) or v
	end
	BLACK, BOLD = chosen.black or SKINS.arcade.black, chosen.bold or SKINS.arcade.bold
	NUMBER = chosen.number or BLACK
	GLOW = chosen.glow == true
	Kit.look({ radius = 1, outline = 1, depth = 1, shine = true, textOutline = 1, topLight = false, fontFace = BLACK })
	Kit.LOOK.stroke, Kit.LOOK.lift = nil, nil
	Kit.look(chosen.look or {})
	Kit.tone(chosen.tone or "playful")
	return C, BLACK, BOLD, NUMBER
end

function Demo.build(playerGui: Instance, options: { icons: { [string]: string }?, skin: (string | { [string]: any })? }?)
	-- the skin first: every colour, both fonts, the finish and the motion character come from it
	Demo.skin(options and options.skin)
	local icons = table.clone(ICONS)
	for k, v in (options and options.icons) or {} do
		icons[k] = v
	end
	local _, phone = Kit.screen()
	local function pick(small, large)
		if phone then
			return small
		end
		return large
	end

	-- Three layers: the HUD that dims, the dim, and on top the window with the counters that stay bright.
	local hudGui = Instance.new("ScreenGui")
	hudGui.Name = "WindowKitDemoHud"
	hudGui.ResetOnSpawn = false
	hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hudGui.DisplayOrder = 1
	hudGui.Parent = playerGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "WindowKitDemo"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 3
	gui.Parent = playerGui
	gui.Destroying:Once(function()
		hudGui:Destroy()
		GuiService.TouchControlsEnabled = true
	end)
	local dim = Kit.scrim(gui, { transparency = 0.45 })

	local W, H = pick(532, 760), pick(236, 440)
	local hudLayer = Kit.stage(hudGui, Vector2.new(1100, 620), { share = Vector2.one, max = 1.6, name = "Hud" })
	-- a large screen: the window takes up to 86% of the width or 80% of the height, whichever comes first
	local share = Vector2.new(0.86, 0.8)
	local layer = Kit.stage(gui, Vector2.new(W, H), { share = share, max = pick(1, 1.6), name = "Root" })
	local top = Kit.stage(gui, Vector2.new(W, H), { share = share, max = pick(1, 1.6), name = "Top", z = 1500 })
	local windowPosition = pick(UDim2.new(0.5, 0, 0, 38), UDim2.fromScale(0.5, 0.54))
	local windowAnchor = pick(Vector2.new(0.5, 0), Vector2.new(0.5, 0.5))

	-- HUD: two counters at the top right. They stay over the dim.
	local wallet = { coins = 1200, gems = 30 }
	local counters = {}
	local cw, ch = pick(100, 118), pick(26, 40) -- as wide as the largest amount needs: a half-empty pill reads unfinished
	for i, kind in { "coins", "gems" } do
		local pill, content = Kit.card(layer, {
			name = kind,
			role = "currency",
			size = UDim2.fromOffset(cw, ch),
			position = UDim2.new(1, -(3 - i) * (cw + pick(6, 12)) - pick(2, 6), 0, pick(4, 12)),
			fill = C.hud,
			stroke = C.dark,
			radius = ch / 2,
			depth = pick(2, 3),
			z = 3,
		})
		local icon = Kit.icon(content, icons[kind == "gems" and "gem" or "coin"], {
			size = pick(20, 30),
			position = UDim2.new(0, pick(5, 6), 0.5, 0),
			anchor = Vector2.new(0, 0.5),
		})
		local amount = outline(
			text(content, {
				Name = "Amount",
				Size = UDim2.new(1, -pick(38, 50), 1, 0),
				Position = UDim2.fromOffset(pick(29, 42), 0),
				Text = Kit.comma(wallet[kind]),
				TextSize = pick(14, 19),
				FontFace = BLACK,
			}),
			C.dark,
			pick(1.5, 2)
		)
		counters[kind] = { pill = pill, icon = icon, amount = amount }
	end

	-- HUD: a rail of menu buttons and one action button. On touch the rail sits above the thumbstick's
	-- corner and the action button above the jump button; each has a 44 px tap area.
	local hud = {} -- { item, the side it leaves by }
	local badge, missionsButton
	local bs = pick(36, 58)
	for i, item in { { "Shop", icons.shop }, { "Pets", icons.pets }, { "Missions", icons.missions } } do
		local position = pick(UDim2.fromOffset(12, 10 + (i - 1) * 50), UDim2.new(0, 22, 0.5, (i - 2) * 92 - 48))
		local button, _, content = Kit.button(hudLayer, {
			name = item[1],
			role = "menu",
			hit = 44,
			fill = C.hud,
			stroke = C.dark,
			size = UDim2.fromOffset(bs, bs),
			position = position,
			radius = pick(12, 16),
			strokeWidth = pick(2, 3),
			depth = pick(3, 5),
		})
		Kit.icon(content, item[2], { size = pick(26, 42), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
		table.insert(hud, { button, "left" })
		if item[1] == "Missions" then -- how many rewards wait; it opens the window (below)
			badge = Kit.badge(button, 0, { size = pick(18, 24), textSize = pick(13, 15), fontFace = NUMBER })
			missionsButton = button
		else
			Kit.press(button)
		end
		if not phone then
			local labelPosition = position + UDim2.fromOffset(-16, bs + 7)
			local label = outline(
				text(hudLayer, {
					Name = item[1] .. "Label",
					Size = UDim2.fromOffset(90, 18),
					Position = labelPosition,
					Text = item[1],
					FontFace = BLACK,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
				C.dark,
				1.5
			)
			table.insert(hud, { label, "left" })
		end
	end
	local actionPosition = pick(UDim2.new(1, -12, 1, -98), UDim2.new(1, -24, 1, -28))
	local action, actionLabel, actionContent = Kit.button(hudLayer, {
		name = "Action",
		role = "action",
		text = "PLAY",
		textSize = pick(18, 26),
		textColor = C.text,
		fontFace = BLACK,
		fill = C.go,
		size = pick(UDim2.fromOffset(128, 54), UDim2.fromOffset(170, 64)),
		position = actionPosition,
		anchor = Vector2.new(1, 1),
		radius = pick(16, 20),
		strokeWidth = pick(3, 4),
		depth = pick(4, 6),
		sheen = true,
	})
	Kit.icon(actionContent, icons.play, { size = pick(32, 40), position = UDim2.new(0, pick(10, 14), 0.5, 0), anchor = Vector2.new(0, 0.5) })
	actionLabel.Size = UDim2.new(1, -pick(48, 60), 1, 0)
	actionLabel.Position = UDim2.fromOffset(pick(42, 54), 0)
	Kit.press(action)
	Kit.sheen(action, { period = 3.4 })
	table.insert(hud, { action, "right" })
	-- the HUD leaves by its own side as the window opens and slides back while it closes
	local dock = Kit.dock(hud)

	-- the window
	local pad = pick(6, 10)
	local window, body = Kit.card(layer, {
		name = "Window",
		role = "panel",
		size = UDim2.fromOffset(W, H),
		position = windowPosition,
		anchor = windowAnchor,
		fill = C.window,
		stroke = C.dark,
		radius = pick(14, 20),
		strokeWidth = 3,
		depth = pick(5, 9),
		rim = true,
		glass = 0.9,
		z = 4,
	})
	window.Visible = false

	-- the header band: emblem, title, tabs, close. It comes with the window; only the emblem and the close button are staged.
	local headH = pick(36, 54)
	local header, head = Kit.card(body, {
		name = "Header",
		size = UDim2.new(1, -2 * pad, 0, headH),
		position = UDim2.fromOffset(pad, pad),
		fill = C.header,
		stroke = C.dark,
		radius = pick(10, 14),
		lift = 0.22,
		gloss = 0.5,
		glass = 0.86,
		sheen = true,
	})
	Kit.sheen(header, { period = 4.2 })
	-- desktop: the emblem breaks the top-left corner of the frame, the one piece that does
	local emblem = Kit.icon(pick(head, body), icons.missions, {
		name = "Emblem",
		size = pick(26, 70),
		position = pick(UDim2.new(0, 8, 0.5, 0), UDim2.fromOffset(pad + 26, pad + 18)),
		anchor = pick(Vector2.new(0, 0.5), Vector2.new(0.5, 0.5)),
		tile = pick(nil, C.accent),
		radius = 35,
		depth = pick(nil, 4),
		z = 5,
	})
	if not phone then
		emblem:SetAttribute("KitBreakout", "ornament")
		emblem.Rotation = -8
	end
	outline(
		text(head, {
			Name = "Title",
			Size = UDim2.fromOffset(pick(96, 160), headH),
			Position = UDim2.fromOffset(pick(40, 74), 0),
			Text = "MISSIONS",
			TextSize = pick(18, 30),
			FontFace = BLACK,
		}),
		C.dark,
		pick(2, 2.5)
	)
	local tabItems = {}
	for _, name in TABS do
		local n = 0
		for _, m in MISSIONS do
			n += (name == "All" or m.tab == name) and 1 or 0
		end
		table.insert(tabItems, { key = name, text = name, count = n })
	end
	local setTab -- defined below
	local tabs = Kit.tabs(head, tabItems, {
		size = UDim2.fromOffset(pick(228, 318), pick(24, 36)),
		position = UDim2.new(0, pick(140, 246), 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		fill = C.well,
		pill = C.accent,
		textSize = pick(14, 16),
		fontFace = BLACK,
		hit = 44,
		onPick = function(key)
			setTab(key)
		end,
	})
	local closeSize = pick(24, 38)
	local close, _, closeContent = Kit.button(head, {
		name = "Close",
		hit = 44,
		fill = C.well,
		stroke = C.dark,
		size = UDim2.fromOffset(closeSize, closeSize),
		position = UDim2.new(1, -pick(6, 8) - closeSize / 2, 0.5, 0),
		anchor = Vector2.new(0.5, 0.5),
		radius = closeSize / 2,
		depth = 0,
		topLight = false,
	})
	Kit.icon(closeContent, icons.close, { size = pick(14, 22), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })

	-- the list: a dark well with keyed rows, no UIListLayout
	local bodyTop = pad + headH + pick(6, 10)
	local bodyH = H - bodyTop - pad
	local listW = pick(228, 350)
	local _, well = Kit.card(body, {
		name = "ListWell",
		size = UDim2.fromOffset(listW, bodyH),
		position = UDim2.fromOffset(pad, bodyTop),
		fill = C.well,
		stroke = C.dark,
		radius = pick(10, 14),
		lift = 0.04,
		topLight = false,
		glass = 0.92,
		clip = true,
	})
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, -4, 1, -4)
	scroll.Position = UDim2.fromOffset(2, 2)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = C.muted
	scroll.Parent = well
	local rowH = pick(46, 70)
	-- the row cut by the frame fades into the well: there is more below
	local list = Kit.list(scroll, { gap = pick(6, 8), pad = pick(5, 7), fade = C.well, fadeSize = pick(20, 30) })
	local tileOf = { Daily = C.dailyTile, Weekly = C.weeklyTile }
	local rows = {}
	for _, m in MISSIONS do
		local ready = m.have >= m.need
		local row, content = Kit.card(nil :: any, {
			name = m.id,
			button = true,
			size = UDim2.new(1, -pick(18, 22), 0, rowH),
			position = UDim2.fromOffset(pick(6, 8), 0),
			fill = C.row,
			stroke = C.dark,
			radius = pick(10, 12),
			depth = pick(2, 3),
		})
		local left = pick(46, 72)
		Kit.icon(content, icons[m.icon], {
			size = pick(32, 50),
			position = UDim2.new(0, pick(7, 10), 0.5, 0),
			anchor = Vector2.new(0, 0.5),
			tile = tileOf[m.tab],
			radius = pick(9, 12),
		})
		local title = text(content, {
			Name = "Title",
			Size = UDim2.new(1, -left - pick(8, 78), 0, 22),
			Position = UDim2.fromOffset(left, pick(4, 9)),
			Text = m.title,
			TextSize = pick(14, 18),
		})
		local right = pick(56, 122)
		local barBack = Instance.new("Frame")
		barBack.Name = "Bar"
		barBack.BackgroundColor3 = C.well
		barBack.BorderSizePixel = 0
		barBack.Size = UDim2.new(1, -left - right - pick(12, 16), 0, pick(8, 10))
		barBack.Position = UDim2.fromOffset(left, pick(29, 44))
		barBack.Parent = content
		Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = ready and C.ready or C.accent
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(m.have / m.need, 1)
		fill.Parent = barBack
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
		local count = text(content, {
			Name = "Count",
			Size = UDim2.fromOffset(pick(right, 44), 18),
			Position = UDim2.new(1, -right - pick(7, 9), 0, pick(24, 39)),
			Text = m.have .. "/" .. m.need,
			TextColor3 = C.muted,
			TextXAlignment = pick(Enum.TextXAlignment.Right, Enum.TextXAlignment.Left),
		})
		if not phone then -- room for what the mission pays: the row answers "is it worth it" without a tap
			Kit.icon(content, icons.coin, { name = "Pay", size = 20, position = UDim2.new(1, -78, 0, 38) })
			text(content, {
				Name = "PayAmount",
				Size = UDim2.fromOffset(50, 18),
				Position = UDim2.new(1, -55, 0, 39),
				Text = Kit.comma(m.coins),
				TextColor3 = C.gold,
				FontFace = BLACK,
			})
		end
		-- "ready" has its own mark, never the selection outline. On a phone it takes the count's place.
		local chip, chipContent = Kit.card(content, {
			name = "Ready",
			size = UDim2.fromOffset(pick(54, 60), pick(18, 20)),
			position = UDim2.new(1, -pick(8, 9), 0, pick(21, 9)),
			anchor = Vector2.new(1, 0),
			fill = C.ready,
			radius = 7,
			strokeWidth = 1.5,
			topLight = false,
		})
		text(chipContent, { Size = UDim2.fromScale(1, 1), Text = "READY", TextSize = pick(14, 13), FontFace = BLACK, TextColor3 = Kit.ink(C.ready), TextXAlignment = Enum.TextXAlignment.Center })
		chip.Visible = ready
		count.Visible = not (phone and ready)
		list:add(m.id, row)
		rows[m.id] = { row = row, fill = fill, count = count, chip = chip, title = title, mission = m }
		if ready then
			Kit.pulse(chip, 0.06, 1.1)
		end
	end

	-- the detail card: the one bright surface, with the selected mission's art as its largest piece
	local cardX = pad + listW + pick(6, 10)
	local cardW = W - cardX - pad
	local pane, detail = Kit.card(body, {
		name = "Detail",
		size = UDim2.fromOffset(cardW, bodyH),
		position = UDim2.fromOffset(cardX, bodyTop),
		fill = C.card,
		stroke = C.dark,
		radius = pick(10, 14),
		lift = 0.1,
		glass = 0.8, -- faint on a light card: its text sits on it
	})
	local inset = pick(8, 16)
	local artSize = pick(46, 76)
	-- a tinted band behind the art and the title: the card has a head and a body, not one white sheet
	local headBand = Instance.new("Frame")
	headBand.Name = "Backdrop"
	headBand.BackgroundColor3 = C.cardHead
	headBand.BorderSizePixel = 0
	headBand.Position = UDim2.fromOffset(pick(4, 7), pick(4, 7))
	headBand.Parent = detail
	Instance.new("UICorner", headBand).CornerRadius = UDim.new(0, pick(8, 10))
	-- desktop: the art leans out over the card's corner, as the emblem does over the frame's
	local art, artImage = Kit.icon(detail, icons.egg, {
		name = "Art",
		size = artSize,
		position = UDim2.fromOffset(inset - pick(0, 8), inset - pick(0, 12)),
		tile = tileOf.Daily,
		radius = pick(12, 20),
		depth = pick(2, 4),
		pad = 0.12,
	})
	if not phone then
		art:SetAttribute("KitBreakout", "ornament")
		pane:SetAttribute("KitHost", true) -- the lint: the art is an ornament of the card, so it may rest on the card's own body
		art.Rotation = -5
		-- three small stars at rest: beside the emblem, at the end of the title, on the frame's far corner
		Kit.sparkle(body, UDim2.fromOffset(pad + 68, pad + 2), 24)
		Kit.sparkle(head, UDim2.fromOffset(240, 13), 18)
		Kit.sparkle(body, UDim2.new(1, -14, 1, -12), 20)
	end
	local textX = inset + artSize + pick(8, 14)
	local title = text(detail, {
		Name = "Title",
		Size = UDim2.new(1, -textX - inset, 0, pick(20, 30)),
		Position = UDim2.fromOffset(textX, inset + pick(0, 4)),
		TextSize = pick(16, 26),
		FontFace = BLACK,
		TextColor3 = C.ink,
	})
	local tag, tagContent = Kit.card(detail, {
		name = "Tag",
		size = UDim2.fromOffset(pick(58, 66), pick(18, 22)),
		position = UDim2.fromOffset(textX, inset + pick(24, 42)),
		fill = C.daily,
		radius = 7,
		strokeWidth = 1.5,
		topLight = false,
	})
	local tagText = text(tagContent, { Size = UDim2.fromScale(1, 1), Text = "DAILY", TextSize = pick(14, 13), FontFace = BLACK, TextColor3 = Kit.ink(C.daily), TextXAlignment = Enum.TextXAlignment.Center })
	local clock = Kit.icon(detail, icons.timer, { name = "Clock", size = pick(16, 20), position = UDim2.fromOffset(textX + pick(64, 76), inset + pick(25, 43)) })
	local timer = text(detail, {
		Name = "Timer",
		Size = UDim2.fromOffset(96, pick(18, 22)),
		Position = UDim2.fromOffset(textX + pick(83, 100), inset + pick(24, 42)),
		TextColor3 = C.inkMuted,
		TextSize = pick(14, 15),
	})
	local infoY = inset + artSize + pick(5, 14)
	local info = text(detail, {
		Name = "Info",
		Size = UDim2.new(1, -2 * inset, 0, pick(34, 40)),
		Position = UDim2.fromOffset(inset, infoY),
		TextColor3 = C.inkMuted,
		TextSize = pick(14, 16),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	-- the band holds what the mission is (art, title, tag, the line of text); under it, progress and pay
	headBand.Size = UDim2.new(1, -2 * pick(4, 7), 0, infoY + pick(36, 42) - pick(4, 7))
	local stepsY = infoY + pick(46, 72)
	local stepsHolder = Instance.new("Frame")
	stepsHolder.Name = "Progress"
	stepsHolder.BackgroundTransparency = 1
	stepsHolder.Size = UDim2.new(1, -2 * inset - 46, 0, pick(10, 16))
	stepsHolder.Position = UDim2.fromOffset(inset, stepsY)
	stepsHolder.Parent = detail
	local progress = text(detail, {
		Name = "Count",
		Size = UDim2.fromOffset(42, 18),
		Position = UDim2.new(1, -inset - 42, 0, stepsY - pick(4, 2)),
		TextColor3 = C.ink,
		FontFace = BLACK,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local caption = text(detail, {
		Name = "Caption",
		Size = UDim2.fromOffset(120, 18),
		Position = UDim2.fromOffset(inset, stepsY - 22),
		Text = "PROGRESS",
		TextColor3 = C.inkMuted,
		FontFace = BLACK,
		Visible = not phone, -- no room for it on a phone
	})
	-- phone: reward tiles and the main button share one row; larger screens: tiles across, the button under them
	local tilesY = stepsY + pick(24, 30)
	local tileH = pick(44, 60)
	local tilesW = pick(146, cardW - 2 * inset)
	local tileGap = pick(6, 10)
	local tiles = {}
	for _, kind in { "coins", "gems" } do
		local tile, tileContent = Kit.card(detail, {
			name = kind .. "Tile",
			size = UDim2.fromOffset((tilesW - tileGap) / 2, tileH),
			position = UDim2.fromOffset(inset, tilesY),
			fill = kind == "gems" and C.gemTile or C.coinTile, -- each currency has its own tile colour
			stroke = Kit.shade(kind == "gems" and C.gemTile or C.coinTile, -0.5),
			radius = pick(9, 12),
			gloss = 0.5,
		})
		local _, picture = Kit.icon(tileContent, icons[kind == "gems" and "gem" or "coin"], {
			size = pick(26, 44),
			position = UDim2.new(0, pick(5, 10), 0.5, 0),
			anchor = Vector2.new(0, 0.5),
		})
		local amount = text(tileContent, {
			Name = "Amount",
			Size = UDim2.new(1, -pick(37, 66), 1, 0),
			Position = UDim2.fromOffset(pick(34, 60), 0),
			TextSize = pick(14, 24),
			FontFace = NUMBER, -- an amount: the skin's number face (a typewriter display face did not fit "+400" on a phone tile)
			TextColor3 = C.ink,
		})
		local name: TextLabel? = nil
		if not phone then -- room for the reward's name: it fills a wide tile when there is only one
			name = text(tileContent, {
				Name = "Caption",
				Size = UDim2.new(0, 70, 1, 0),
				Position = UDim2.new(1, -82, 0, 0),
				Text = kind == "gems" and "Gems" or "Coins",
				TextColor3 = C.inkMuted,
				TextXAlignment = Enum.TextXAlignment.Right,
			})
		end
		tiles[kind] = { tile = tile, icon = picture, amount = amount, name = name }
	end
	local main, mainLabel = Kit.button(detail, {
		name = "Main",
		hit = 44,
		text = "CLAIM",
		textSize = pick(15, 28),
		textColor = C.text, -- white with a dark outline on every state of the button
		fontFace = BLACK,
		fill = C.go,
		size = pick(UDim2.fromOffset(cardW - 2 * inset - tilesW - 6, 44), UDim2.fromOffset(cardW - 2 * inset, 58)),
		position = pick(UDim2.fromOffset(inset + tilesW + 6, tilesY), UDim2.fromOffset(inset, tilesY + tileH + 10)),
		radius = pick(12, 14),
		strokeWidth = pick(2, 3),
		depth = pick(3, 5),
	})

	-- the stamped title of a big moment: a ribbon over the window, above the flying rewards
	local stamp, stampContent = Kit.card(top, {
		name = "Stamp",
		size = UDim2.fromOffset(pick(340, 600), pick(46, 88)),
		position = pick(UDim2.new(0.5, 0, 0, 38 + H / 2), windowPosition),
		anchor = Vector2.new(0.5, 0.5),
		fill = C.ribbon,
		stroke = C.dark,
		radius = pick(12, 16),
		strokeWidth = pick(3, 4),
		depth = pick(5, 8),
		gloss = 0.5,
		rim = true,
		sheen = true,
	})
	outline(
		text(stampContent, { Size = UDim2.fromScale(1, 1), Text = "WEEKLY CLEAR!", TextSize = pick(26, 54), FontFace = BLACK, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Center }),
		C.dark,
		pick(2, 3)
	)
	stamp.Visible = false

	local state = { tab = "All", selected = nil :: string?, claimed = {} :: { [string]: boolean }, steps = nil :: any, open = false }

	local function keysFor(tab: string): { string }
		local open, done = {}, {}
		for _, m in MISSIONS do
			if tab == "All" or m.tab == tab then
				table.insert(state.claimed[m.id] and done or open, m.id)
			end
		end
		return table.move(done, 1, #done, #open + 1, open) -- claimed rows go to the bottom
	end

	local function paintMain(m)
		local claimed, ready = state.claimed[m.id], m.have >= m.need
		mainLabel.Text = claimed and "CLAIMED" or (ready and "CLAIM" or "IN PROGRESS")
		Kit.recolor(main, claimed and C.done or (ready and C.go or C.idle))
		Kit.still(main)
		if ready and not claimed then
			Kit.pulse(main, 0.03, 1.3)
			Kit.sheen(main, { period = 2.6 })
		end
	end

	-- a claimed reward keeps its tile, greyed: the same on the claim and on every later visit
	local function paintTiles(m)
		local claimed = state.claimed[m.id]
		local shown = {}
		for _, kind in { "coins", "gems" } do
			local t = tiles[kind]
			t.tile.Visible = m[kind] > 0
			if m[kind] > 0 then
				table.insert(shown, t)
				t.amount.Text = "+" .. pick(short(m[kind]), Kit.comma(m[kind]))
				local fill = kind == "gems" and C.gemTile or C.coinTile
				t.amount.TextColor3 = claimed and C.inkMuted or C.ink
				t.icon.ImageTransparency = claimed and 0.55 or 0
				Kit.recolor(t.tile, claimed and C.tileDone or fill, claimed and Kit.shade(C.tileDone, -0.25) or Kit.shade(fill, -0.5))
			end
		end
		local each = (tilesW - (#shown - 1) * tileGap) / #shown
		for i, t in shown do
			t.tile.Size = UDim2.fromOffset(each, tileH)
			t.tile.Position = UDim2.fromOffset(inset + (i - 1) * (each + tileGap), tilesY)
			Kit.fitText(t.amount) -- a wide number face on a phone tile
			if t.name then -- a long amount in a wide font takes the name's room: the number stays, the name goes
				local nameLeft = t.name.AbsolutePosition.X + t.name.AbsoluteSize.X - t.name.TextBounds.X
				t.name.Visible = t.amount.AbsolutePosition.X + t.amount.TextBounds.X + 6 < nameLeft
			end
		end
	end

	local function select(id: string, first: boolean?)
		if state.selected == id then
			return
		end
		local was = state.selected and rows[state.selected]
		if was then
			Kit.recolor(was.row, state.claimed[state.selected :: string] and C.rowDone or C.row, C.dark)
			Kit.glow(was.row, nil)
		end
		state.selected = id
		local r = rows[id]
		local m = r.mission
		-- selected: a lighter fill and a bright outline that belong to the row, so they travel with it
		Kit.recolor(r.row, C.rowSelected, C.select)
		if GLOW then
			Kit.glow(r.row, C.select, { size = 8 })
		end
		list:reveal(id)
		-- the card changes on the same frame as the row
		artImage.Image = icons[m.icon]
		Kit.recolor(art, tileOf[m.tab])
		title.Text = m.title
		Kit.fitText(title) -- a long title in a wide display face ("Beat the island boss" in the grim skin) steps down
		info.Text = m.info
		tagText.Text = string.upper(m.tab)
		Kit.recolor(tag, m.tab == "Daily" and C.daily or C.weekly)
		tagText.TextColor3 = Kit.ink(m.tab == "Daily" and C.daily or C.weekly)
		timer.Text = timeLeft(m.tab)
		progress.Text = m.have .. "/" .. m.need
		stepsHolder:ClearAllChildren()
		state.steps = Kit.steps(stepsHolder, m.need, m.have, { color = m.have >= m.need and C.ready or C.accent, empty = C.empty })
		paintTiles(m)
		paintMain(m)
		local shown = {}
		for _, kind in { "coins", "gems" } do
			if m[kind] > 0 then
				table.insert(shown, tiles[kind].tile)
			end
		end
		local stepsParts = table.clone(state.steps.slots)
		table.insert(stepsParts, progress)
		if first then
			-- with the window: the art and the texts come with the card (never an empty card); the steps, the
			-- rewards and the button pop in beside the first rows
			Kit.open(pane, { { stepsParts, "pop", gap = 0.02 }, { shown, "pop", gap = 0.04 }, { main, "pop" } }, { shell = false, budget = 0.4 })
		else
			-- another row or tab: everything dips and comes back together, so the button never shows over a blank card
			local items = { title, tag, clock, timer, info, progress }
			table.move(state.steps.slots, 1, #state.steps.slots, #items + 1, items)
			table.move(shown, 1, #shown, #items + 1, items)
			Kit.refresh(items, { art })
		end
	end

	function setTab(name: string)
		if state.tab == name then
			return
		end
		state.tab = name
		tabs.pick(name, true)
		local keys = keysFor(name)
		list:show(keys, false, true) -- old rows leave, new ones arrive and the ones that stay step in: the list is seen to change, never blank
		if keys[1] then
			select(keys[1])
		end
	end

	local function claim(id: string)
		local r = rows[id]
		local m = r.mission
		if state.claimed[id] or m.have < m.need then
			return
		end
		state.claimed[id] = true
		paintMain(m) -- the squash already ran: the button changes now
		r.chip.Visible = false
		Kit.still(r.chip)
		r.count.Visible = true
		r.count.Text = "DONE"
		local function resort()
			if gui.Parent then
				Kit.recolor(r.row, C.rowDone, state.selected == id and C.select or C.dark)
				r.fill.BackgroundColor3 = C.idle
				r.title.TextColor3 = C.muted
				list:order(keysFor(state.tab)) -- the claimed row leaves and comes back at the bottom; the others close the gap
			end
		end
		if m.special then
			-- the bigger reward: a title lands over rays, and the list waits until it has gone
			Kit.stamp(stamp, 1.1, resort, { dim = window })
			Kit.burst(stamp, { tier = 3, color = C.accent, radius = pick(190, 340) })
		else
			task.delay(1.1, resort)
		end
		for _, kind in { "coins", "gems" } do
			local amount = m[kind]
			if amount > 0 then
				Kit.fly(tiles[kind].icon, counters[kind].icon, {
					amount = amount, -- the pieces follow what the player gets (six, or eight for a big amount)
					arc = -0.3, -- out over the window's edge, not across the card's title
					onArrive = function(i)
						if i == 1 then
							Kit.count(counters[kind].amount, wallet[kind], wallet[kind] + amount, { rise = 8 }) -- the window's close button is right under the counters
							wallet[kind] += amount
						end
					end,
				})
			end
		end
		task.delay(0.2, function() -- the pieces have left the tiles
			if gui.Parent and state.selected == id then
				paintTiles(m)
			end
		end)
	end

	for id, r in rows do
		Kit.press(r.row, function()
			select(id)
		end)
	end

	-- under the last row: when more missions come. A short tab does not end in an empty well.
	local foot = Instance.new("Frame")
	foot.Name = "Foot"
	foot.BackgroundTransparency = 1
	foot.Size = UDim2.new(1, -pick(18, 22), 0, pick(30, 44))
	foot.Position = UDim2.fromOffset(pick(6, 8), 0)
	Kit.icon(foot, icons.timer, { name = "Clock", size = pick(16, 22), position = UDim2.new(0.5, -pick(84, 104), 0.5, 0), anchor = Vector2.new(0, 0.5) })
	local footText = text(foot, {
		Name = "Next",
		Size = UDim2.new(0, pick(150, 190), 1, 0),
		Position = UDim2.new(0.5, -pick(62, 76), 0, 0),
		Text = "New missions in " .. timeLeft("Daily"),
		TextColor3 = C.muted,
		TextSize = pick(14, 16),
	})
	list:foot(foot)
	Kit.press(main, function()
		if state.selected then
			claim(state.selected)
		end
	end)

	task.spawn(function() -- the countdown is live
		while gui.Parent do
			local r = state.selected and rows[state.selected]
			if r and state.open then
				timer.Text = timeLeft(r.mission.tab)
				footText.Text = "New missions in " .. timeLeft(state.tab == "Weekly" and "Weekly" or "Daily")
			end
			task.wait(1)
		end
	end)

	local function waiting(): number
		local n = 0
		for _, m in MISSIONS do
			n += (m.have >= m.need and not state.claimed[m.id]) and 1 or 0
		end
		return n
	end
	badge.set(waiting())

	local api = { gui = gui, hudGui = hudGui, window = window, main = main, closeButton = close, missionsButton = missionsButton, rows = rows, tabs = tabs, state = state, phone = phone }
	function api.open()
		state.open = true
		GuiService.TouchControlsEnabled = false -- the window takes the screen: no thumbstick under it
		dim.show()
		dock.hide()
		local keys = keysFor(state.tab)
		list:show(keys, true)
		Kit.open(window, {
			{ emblem, "pop" },
			{ close, "spin" }, -- the way out is there from the start
			{ list:shown(), "slide", from = "left", gap = 0.035 },
		})
		state.selected = nil
		select(keys[1], true)
		if not phone then
			Kit.bob(emblem, 2, 2.6, 1.5)
		end
	end
	function api.close()
		state.open = false
		Kit.still(emblem)
		Kit.close(window, { first = close })
		dim.hide()
		badge.set(waiting()) -- what is left to claim, set before the HUD is back
		dock.show(0.06) -- while the window fades: the way back is seen
		GuiService.TouchControlsEnabled = true
	end
	-- with the window closed: every mission back to where it started, the GUI kept. A tour that destroyed its
	-- GUI and built it again showed the HUD leaving, an empty screen and the HUD back with the window to two
	-- judges (2026-11-21)
	function api.reset()
		for _, m in MISSIONS do
			local r = rows[m.id]
			local ready = m.have >= m.need
			state.claimed[m.id] = nil
			Kit.recolor(r.row, C.row, C.dark)
			Kit.glow(r.row, nil)
			r.fill.BackgroundColor3 = ready and C.ready or C.accent
			r.title.TextColor3 = C.text
			r.count.Text = m.have .. "/" .. m.need
			r.count.Visible = not (phone and ready)
			if ready and not r.chip.Visible then
				r.chip.Visible = true
				Kit.pulse(r.chip, 0.06, 1.1)
			end
		end
		state.selected = nil
		state.tab = "All"
		tabs.pick("All", true)
		badge.set(waiting())
	end
	api.select, api.setTab, api.claim = select, setTab, claim
	Kit.press(close, api.close)
	Kit.press(missionsButton, api.open)
	return api
end

-- the tour: every motion once, about 15 s, then again
function Demo.run(playerGui: Instance?, options: { icons: { [string]: string }?, skin: (string | { [string]: any })? }?)
	local target = playerGui or Players.LocalPlayer:WaitForChild("PlayerGui")
	local ui = Demo.build(target, options)
	local function tap(button: GuiObject, fn: () -> ())
		Kit.squash(button)
		task.wait(Kit.TIMES.press)
		fn()
	end
	task.spawn(function()
		while ui.gui.Parent do
			task.wait(1.2) -- the HUD at rest, then the press that opens the window
			tap(ui.missionsButton, ui.open)
			task.wait(1.8)
			tap(ui.rows.d2.row, function()
				ui.select("d2")
			end)
			task.wait(1)
			tap(ui.rows.d3.row, function()
				ui.select("d3")
			end)
			task.wait(1)
			ui.setTab("Daily")
			task.wait(1.3)
			tap(ui.main, function()
				ui.claim("d1")
			end)
			task.wait(2.6)
			ui.setTab("Weekly")
			task.wait(1.3)
			tap(ui.main, function()
				ui.claim("w1")
			end)
			task.wait(3.2)
			tap(ui.closeButton, ui.close)
			task.wait(1.4)
			if not ui.gui.Parent then -- destroyed from outside: the tour ends
				break
			end
			ui.reset() -- the data goes back; the GUI stays
		end
	end)
	return ui
end

return Demo
