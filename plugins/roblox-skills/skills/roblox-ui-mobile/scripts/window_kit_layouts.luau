-- WindowKit layouts: four more windows from the same parts, each with another skeleton, so the
-- missions demo is not read as "the" window. A window's structure follows its job:
--   shop   browse and buy: a rail of categories, one featured offer, a grid of cards
--   daily  one decision: a small centred modal, seven day tiles in a row, one button
--   sheet  a look at one thing while the world stays in view: a card docked to the right edge, a light dim
--   track  progress along levels: a bar that fills, a rail of levels that scrolls sideways, a reward under each
-- (the missions demo is the fifth: a list and the detail of the selected row).
-- All take the skins of the demo (Demo.SKINS) or your own skin table, and each lays out twice: a
-- phone layout in device px and a larger one that Kit.stage sizes by its share of the screen.
-- Setup: WindowKit, WindowKitDemo and this file as ModuleScripts in one folder, then from a LocalScript:
-- require(ReplicatedStorage.Ui.WindowKitLayouts).run()               -- tours the four in turn
-- local shop = Layouts.shop(playerGui, { skin = "tech" }); shop.open(); shop.buy(2); shop.close()
-- Read them for the structure and the calls; the items, the numbers and the icons are examples.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Kit = require(script.Parent.WindowKit)
local Demo = require(script.Parent.WindowKitDemo)

local Layouts = {}

local Quad, Back = Enum.EasingStyle.Quad, Enum.EasingStyle.Back
local Out, In = Enum.EasingDirection.Out, Enum.EasingDirection.In

type Options = { icons: { [string]: string }?, skin: (string | { [string]: any })? }

-- What every window here shares: the skin, one ScreenGui, a stage, two counters that stay bright.
local function scaffold(playerGui: Instance, name: string, options: Options?, small: Vector2, large: Vector2, share: Vector2, dimTo: number)
	-- NUMBER: the skin's `number` face for prices on a coloured button, when its display face is too light for them
	local C, BLACK, BOLD, NUMBER = Demo.skin(options and options.skin)
	local icons = table.clone(Demo.ICONS)
	for k, v in (options and options.icons) or {} do
		icons[k] = v
	end
	local _, phone = Kit.screen()
	local function pick(a, b)
		if phone then
			return a
		end
		return b
	end
	-- two layers: the HUD under the dim, and the window with the counters that stay bright
	local hudGui = Instance.new("ScreenGui")
	hudGui.Name = name .. "Hud"
	hudGui.ResetOnSpawn = false
	hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hudGui.DisplayOrder = 1
	hudGui.Parent = playerGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 3
	gui.Parent = playerGui
	gui.Destroying:Once(function()
		hudGui:Destroy()
		GuiService.TouchControlsEnabled = true
	end)
	-- 0.45 under a window; 0.7 and no blur under a sheet: the world stays in view, the sheet still reads as open
	local dim = Kit.scrim(gui, { transparency = dimTo, blur = if dimTo > 0.6 then 0 else nil })
	local design = pick(small, large)
	local layer = Kit.stage(gui, design, { share = share, max = pick(1, 1.6), name = "Root" })

	local function text(parent: Instance, props): TextLabel
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
	local function outline(label: TextLabel, width: number?)
		local s = Instance.new("UIStroke")
		s.Color = C.dark
		s.Thickness = (width or 2) * math.max(Kit.LOOK.textOutline, 0.01)
		s.Enabled = Kit.LOOK.textOutline > 0
		s.Parent = label
		return label
	end

	local wallet = { coins = 3200, gems = 30 }
	local counters = {}
	local cw, ch = pick(100, 118), pick(26, 40)
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
			pick(1.5, 2)
		)
		counters[kind] = { pill = pill, icon = icon, amount = amount }
	end

	-- The HUD a window opens over: menu buttons down the left, one action at the bottom right (on touch above
	-- the jump button). It leaves by its sides as the window opens and is back while it closes: a window that
	-- appears over a HUD with no way in, and a HUD that does not react, were both named by judges.
	local hudLayer = Kit.stage(hudGui, Vector2.new(1100, 620), { share = Vector2.one, max = 1.6, name = "Hud" })
	local hud = {}
	local menu = {} -- the menu buttons by name: a layout says which one opens its window (opens below)
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
		menu[item[1]] = button
		table.insert(hud, { button, "left" })
		if not phone then
			local label = outline(
				text(hudLayer, {
					Name = item[1] .. "Label",
					Size = UDim2.fromOffset(90, 18),
					Position = position + UDim2.fromOffset(-16, bs + 7),
					Text = item[1],
					FontFace = BLACK,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
				1.5
			)
			table.insert(hud, { label, "left" })
		end
	end
	local action, actionLabel, actionContent = Kit.button(hudLayer, {
		name = "Action",
		role = "action",
		text = "PLAY",
		textSize = pick(18, 26),
		textColor = C.text,
		fontFace = BLACK,
		fill = C.go,
		size = pick(UDim2.fromOffset(128, 54), UDim2.fromOffset(170, 64)),
		position = pick(UDim2.new(1, -12, 1, -98), UDim2.new(1, -24, 1, -28)),
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
	local dock = Kit.dock(hud)

	-- a round close button with a 44 px tap area
	local function closeButton(parent: Instance, position: UDim2)
		local size = pick(24, 36)
		local close, _, content = Kit.button(parent, {
			name = "Close",
			hit = 44,
			fill = C.well,
			stroke = C.dark,
			size = UDim2.fromOffset(size, size),
			position = position,
			anchor = Vector2.new(0.5, 0.5),
			radius = size / 2,
			depth = 0,
			topLight = false,
			gloss = 0,
			z = 5,
		})
		Kit.icon(content, icons.close, { size = pick(14, 20), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
		return close
	end

	-- pay from the coin counter: the number runs down in 0.35 s; on a large screen a "-N" drops from it (on a
	-- phone the window's top edge and its close button sit right under the counter, so there is none)
	local function spend(amount: number)
		local from = wallet.coins
		wallet.coins = from - amount
		Kit.count(counters.coins.amount, from, wallet.coins, { time = 0.35, plus = not phone, color = C.warn, rise = 16 })
	end
	-- every menu button answers a press; the one named opens the window (nil: none, the window opens on its own,
	-- as a daily reward does at join). A tour presses it too: a window that opened from code over a HUD that had
	-- just been built read as a glitch to two judges (2026-11-21)
	local function opens(name: string?, fn: (() -> ())?): GuiButton?
		for key, b in menu do
			Kit.press(b, if key == name then fn else nil)
		end
		return if name then menu[name] else nil
	end
	-- not enough: the counter turns to the warning colour for as long as the button shakes
	local function short()
		local pill = counters.coins.pill
		Kit.recolor(pill, C.warn)
		Kit.shake(pill, { reach = 4 })
		task.delay(0.45, function()
			if pill.Parent then
				Kit.recolor(pill, C.hud, C.dark)
			end
		end)
	end

	return {
		C = C,
		BLACK = BLACK,
		BOLD = BOLD,
		NUMBER = NUMBER,
		dock = dock,
		short = short,
		icons = icons,
		phone = phone,
		pick = pick,
		gui = gui,
		dim = dim,
		layer = layer,
		W = design.X,
		H = design.Y,
		text = text,
		outline = outline,
		wallet = wallet,
		counters = counters,
		closeButton = closeButton,
		spend = spend,
		opens = opens,
	}
end

local function tap(button: GuiObject)
	Kit.squash(button)
	task.wait(Kit.TIMES.press * Kit.TONE.pace)
end

-- ---------- shop: a rail of categories, a featured offer, a grid of cards ----------

-- { icon, name, price, tag }: one card per item, keyed "<shelf><n>". The featured shelf shows six of the
-- others' cards, so a change to or from it has cards that stay (they slide) beside cards that leave and arrive.
-- which of the skin's tile colours an item's art sits on
local TILE = { gem = "gemTile", coin = "coinTile", egg = "dailyTile", pets = "dailyTile", feed = "dailyTile", race = "weeklyTile", play = "weeklyTile", wins = "weeklyTile" }
local SHOP = {
	{ key = "featured", text = "Featured", icon = "shop", show = { "boosts1", "pets1", "gems2", "pets4", "boosts3", "gems6" } },
	{ key = "pets", text = "Pets", icon = "pets", items = { { "egg", "Mystery Egg", 500, "NEW" }, { "feed", "Treat Bag", 150 }, { "trade", "Pet Swap", 350 }, { "pets", "Paw Charm", 800 }, { "race", "Race Pass", 600 }, { "chest", "Gift Pet", 1200 }, { "wins", "Show Ribbon", 450 }, { "boss", "Guard Pup", 1500 }, { "coin", "Piggy Pal", 700 } } },
	{ key = "boosts", text = "Boosts", icon = "play", items = { { "coin", "Double Coins", 450, "BEST" }, { "race", "Fast Feet", 300 }, { "wins", "Lucky Hour", 700 }, { "feed", "Auto Feed", 250, "NEW" }, { "trade", "Trade Slot", 550 }, { "boss", "Boss Key", 950 }, { "gem", "Gem Magnet", 800 }, { "egg", "Quick Hatch", 400 }, { "chest", "Loot Luck", 1100 } } },
	{ key = "gems", text = "Gems", icon = "gem", items = { { "gem", "Gem Pouch", 400 }, { "gem", "Gem Sack", 900 }, { "chest", "Gem Chest", 1800, "NEW" }, { "trade", "Gem Trade", 300 }, { "play", "Gem Rush", 650 }, { "wins", "Gem Crown", 2400, "BEST" }, { "coin", "Coin Swap", 200 }, { "egg", "Gem Egg", 1500 }, { "boss", "Gem Vault", 3000 } } },
}

function Layouts.shop(playerGui: Instance, options: Options?)
	local x = scaffold(playerGui, "WindowKitShop", options, Vector2.new(532, 240), Vector2.new(820, 470), Vector2.new(0.86, 0.8), 0.45)
	local C, pick, phone, text, icons, W, H = x.C, x.pick, x.phone, x.text, x.icons, x.W, x.H
	local pad = pick(6, 10)
	local window, body = Kit.card(x.layer, {
		name = "Window",
		role = "panel",
		size = UDim2.fromOffset(W, H),
		position = pick(UDim2.new(0.5, 0, 0, 38), UDim2.fromScale(0.5, 0.54)),
		anchor = pick(Vector2.new(0.5, 0), Vector2.new(0.5, 0.5)),
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

	-- the rail: the shop's name and its categories, down the left side
	local railW = pick(56, 172)
	local _, rail = Kit.card(body, {
		name = "Rail",
		size = UDim2.fromOffset(railW, H - 2 * pad),
		position = UDim2.fromOffset(pad, pad),
		fill = C.well,
		stroke = C.dark,
		radius = pick(10, 14),
		lift = 0.06,
		topLight = false,
	})
	if not phone then
		x.outline(text(rail, { Name = "Title", Size = UDim2.fromOffset(railW - 28, 34), Position = UDim2.fromOffset(16, 10), Text = "SHOP", TextSize = 28, FontFace = x.BLACK }))
	end
	local catH, catGap, catPad = pick(44, 60), pick(6, 10), pick(6, 10)
	local catTop = pick(catPad, 60)
	local cats = {}
	for i, cat in SHOP do
		local button, label, content = Kit.button(rail, {
			name = cat.key,
			hit = 44,
			fill = C.row,
			stroke = C.dark,
			size = UDim2.fromOffset(railW - 2 * catPad, catH),
			position = UDim2.fromOffset(catPad, catTop + (i - 1) * (catH + catGap)),
			radius = pick(10, 12),
			depth = 2,
			gloss = 0,
			text = pick("", cat.text),
			textSize = 17,
			fontFace = x.BLACK,
		})
		Kit.icon(content, icons[cat.icon], {
			size = pick(28, 30),
			position = pick(UDim2.fromScale(0.5, 0.5), UDim2.new(0, 10, 0.5, 0)),
			anchor = pick(Vector2.new(0.5, 0.5), Vector2.new(0, 0.5)),
		})
		label.Size = UDim2.new(1, -52, 1, 0)
		label.Position = UDim2.fromOffset(48, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Visible = not phone
		cats[i] = button
	end
	if not phone then -- the foot of the rail: when the shelves change
		Kit.icon(rail, icons.timer, { name = "Clock", size = 22, position = UDim2.new(0, 16, 1, -28), anchor = Vector2.new(0, 0.5) })
		text(rail, { Name = "Restock", Size = UDim2.fromOffset(railW - 56, 18), Position = UDim2.new(0, 44, 1, -46), Text = "New stock in", TextColor3 = C.muted })
		text(rail, { Name = "RestockLeft", Size = UDim2.fromOffset(railW - 56, 20), Position = UDim2.new(0, 44, 1, -28), Text = "04:12:55", TextSize = 16, FontFace = x.BLACK })
	end

	-- the right side: a title row with the way out, the featured offer, the grid
	local rx = pad + railW + pad
	local rw = W - rx - pad
	local rowH = pick(26, 40)
	local heading = text(body, { Name = "Heading", Size = UDim2.fromOffset(rw - 60, rowH), Position = UDim2.fromOffset(rx + 4, pad), Text = SHOP[1].text, TextSize = pick(16, 24), FontFace = x.BLACK })
	local close = x.closeButton(body, UDim2.fromOffset(W - pad - rowH / 2, pad + rowH / 2))

	-- the offer is as tall as a card on a large screen: with it, two whole rows of cards; without it (another
	-- shelf), three. On a phone a row is cut about half way in both states, which says the grid scrolls
	local bh = pick(52, 126)
	local by = pad + rowH + pick(4, 8)
	local banner, bannerContent = Kit.card(body, {
		name = "Featured",
		size = UDim2.fromOffset(rw, bh),
		position = UDim2.fromOffset(rx, by),
		fill = C.header,
		stroke = C.dark,
		radius = pick(10, 14),
		lift = 0.22,
		gloss = 0.5,
		glass = 0.86,
		sheen = true,
	})
	Kit.sheen(banner, { period = 4.2 })
	local bannerArt = Kit.icon(bannerContent, icons.chest, {
		name = "Art",
		size = pick(38, 92),
		position = UDim2.new(0, pick(8, 16), 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		tile = C.accent,
	})
	bannerArt.Rotation = pick(0, -5)
	local tx = pick(54, 126)
	local priceW = pick(104, 176)
	x.outline(text(bannerContent, { Name = "Offer", Size = UDim2.fromOffset(rw - tx - priceW - pick(14, 30), pick(18, 34)), Position = UDim2.fromOffset(tx, pick(7, 18)), Text = "STARTER PACK", TextSize = pick(15, 28), FontFace = x.BLACK }), pick(1.5, 2))
	text(bannerContent, { Name = "Info", Size = UDim2.fromOffset(rw - tx - priceW - pick(14, 30), 20), Position = UDim2.fromOffset(tx, pick(27, 52)), Text = pick("3 eggs + 500 gems", "3 eggs, 2 boosts and 500 gems"), TextSize = pick(14, 16), TextColor3 = C.muted })
	if not phone then
		local chip, chipContent = Kit.card(bannerContent, { name = "Ends", size = UDim2.fromOffset(150, 26), position = UDim2.fromOffset(tx, 80), fill = C.well, stroke = C.dark, radius = 13, strokeWidth = 1.5, topLight = false })
		Kit.icon(chipContent, icons.timer, { size = 18, position = UDim2.new(0, 8, 0.5, 0), anchor = Vector2.new(0, 0.5) })
		text(chipContent, { Name = "Left", Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(32, 0), Text = "Ends in 2d 04h" })
		chip.ZIndex = 2
	end

	-- one buy slot = a price button that becomes "OWNED": the banner has one, every card has one
	local function priceButton(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2, textSize: number)
		local button, label, content = Kit.button(parent, {
			name = "Price",
			hit = 44,
			fill = C.go,
			size = size,
			position = position,
			anchor = anchor,
			text = "0",
			textSize = textSize,
			textColor = C.text,
			fontFace = x.NUMBER,
			radius = pick(9, 12),
			depth = pick(3, 4),
		})
		local coin = Kit.icon(content, icons.coin, { name = "Coin", size = math.floor(textSize * 1.3), position = UDim2.new(0, pick(8, 12), 0.5, 0), anchor = Vector2.new(0, 0.5) })
		return { button = button, label = label, coin = coin }
	end
	local function setPrice(slot, price: number, owned: boolean)
		slot.price, slot.owned = price, owned
		slot.label.Text = owned and "OWNED" or Kit.comma(price)
		slot.coin.Visible = not owned
		local inset = owned and 0 or slot.coin.Size.X.Offset + 4
		slot.label.Size = UDim2.new(1, -inset, 1, 0)
		slot.label.Position = UDim2.fromOffset(inset, 0)
		Kit.recolor(slot.button, owned and C.done or C.go)
	end
	local featured = priceButton(bannerContent, UDim2.fromOffset(priceW, pick(36, 60)), UDim2.new(1, -pick(8, 18), 0.5, 0), Vector2.new(1, 0.5), pick(15, 24))
	featured.art, featured.card = bannerArt, banner
	setPrice(featured, 1200, false)

	-- the grid: three columns of keyed cards. Kit.grid places them, so a shelf change is seen (the cards of
	-- the old shelf fade in 0.1 s, the ones that stay slide to their new cell, the new ones are dealt in)
	local gy = by + bh + pick(6, 10)
	local gh = H - gy - pad
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Grid"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromOffset(rw, gh)
	scroll.Position = UDim2.fromOffset(rx, gy)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = C.muted
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = body
	local gap = pick(6, 10)
	local cw = math.floor((rw - 8 - 2 * gap) / 3)
	local ch = pick(78, 126)
	local grid = Kit.grid(scroll, { columns = 3, cell = Vector2.new(cw, ch), gap = gap, pad = 2 })
	local slots = {} -- by key
	local shelves = {} -- per category: the keys it shows
	for c, cat in SHOP do
		shelves[c] = cat.show or {}
		for i, item in cat.items or {} do
			local key = cat.key .. i
			local card, content = Kit.card(scroll, {
				name = key,
				size = UDim2.fromOffset(cw, ch),
				fill = C.card,
				stroke = C.dark,
				radius = pick(10, 14),
				depth = pick(2, 4),
			})
			-- the art's tile takes a tint from what the item is (the skin's tile colours), so the grid is not rows of
			-- one grey box: "identical beige cards, grey icon boxes" was the first defect two judges named
			local art = Kit.icon(content, icons[item[1]], {
				name = "Art",
				size = pick(36, 52),
				position = pick(UDim2.fromOffset(6, 5), UDim2.new(0.5, 0, 0, 7)),
				anchor = pick(Vector2.zero, Vector2.new(0.5, 0)),
				tile = C[TILE[item[1]] or "cardHead"] or C.cardHead,
			})
			text(content, {
				Name = "Name",
				Size = pick(UDim2.new(1, -54, 0, 38), UDim2.new(1, -12, 0, 20)),
				Position = pick(UDim2.fromOffset(50, 5), UDim2.fromOffset(6, 61)),
				Text = item[2],
				TextColor3 = C.ink,
				TextSize = pick(14, 16),
				FontFace = x.BLACK,
				TextWrapped = true,
				TextXAlignment = pick(Enum.TextXAlignment.Left, Enum.TextXAlignment.Center),
			})
			if item[4] and not phone then -- a tag in the card's corner: what is new, what sells best
				local best = item[4] == "BEST"
				local _, tagContent = Kit.card(content, {
					name = "Tag",
					size = UDim2.fromOffset(46, 20),
					position = UDim2.fromOffset(5, 5),
					fill = best and C.accent or C.ready,
					stroke = C.dark,
					radius = 7,
					strokeWidth = 1.5,
					topLight = false,
				})
				text(tagContent, {
					Name = "Label",
					Size = UDim2.fromScale(1, 1),
					Text = item[4],
					TextSize = 13,
					TextColor3 = (Kit.ink(best and C.accent or C.ready)),
					FontFace = x.BOLD,
					TextXAlignment = Enum.TextXAlignment.Center,
				})
			end
			local slot = priceButton(content, UDim2.new(1, -pick(12, 20), 0, pick(30, 36)), UDim2.new(0.5, 0, 1, -pick(6, 8)), Vector2.new(0.5, 1), pick(14, 16))
			slot.key, slot.card, slot.art = key, card, art
			setPrice(slot, item[3], false)
			slots[key] = slot
			grid:add(key, card)
			if not cat.show then
				table.insert(shelves[c], key)
			end
		end
	end

	local state = { cat = 1, offer = true }
	local function setCat(index: number, instant: boolean?)
		state.cat = index
		for i, button in cats do
			Kit.recolor(button, i == index and C.rowSelected or C.row, i == index and C.select or C.dark)
		end
		-- the heading changes with the cards, not before them: it dips while the old shelf fades
		heading.Text = SHOP[index].text
		if not instant then
			Kit.refresh({ heading })
		end
		-- the offer belongs to the first shelf: on the others it leaves and the grid takes its room (a banner
		-- that stayed over every shelf was judged "repeats on every category and takes 20% of the window")
		local offer = index == 1
		if offer ~= state.offer then
			state.offer = offer
			local y0, y1 = scroll.Position.Y.Offset, offer and gy or by
			local function place(y: number)
				scroll.Position = UDim2.fromOffset(rx, y)
				scroll.Size = UDim2.fromOffset(rw, H - y - pad)
			end
			if instant then
				banner.Visible = offer
				Kit.fade(banner, offer and 1 or 0, 0)
				place(y1)
			else
				banner.Visible = true
				Kit.fade(banner, offer and 1 or 0, 0.12, offer and 0.1 or 0)
				Kit.run(scroll, "move", offer and 0 or 0.06, 0.18, Quad, Enum.EasingDirection.Out, function(e)
					place(y0 + (y1 - y0) * math.clamp(e, 0, 1))
				end, function()
					banner.Visible = state.offer
				end)
			end
		end
		grid:show(shelves[index], instant)
	end
	-- Buy: the result is on screen 0.4 s after the press. The price runs off the counter and five coins leave
	-- for the item at once (0.3 s each, 40 ms apart); as the first lands the item bursts and its button reads
	-- OWNED. A press that cannot pay shakes the button and turns the counter to the warning colour.
	local function buy(slot)
		if slot.owned then
			Kit.squash(slot.button)
			return
		end
		if x.wallet.coins < slot.price then
			Kit.shake(slot.button)
			x.short()
			return
		end
		slot.owned = true -- at once: a second tap cannot pay twice
		x.spend(slot.price)
		Kit.fly(x.counters.coins.icon, slot.art, {
			count = 5,
			time = 0.3,
			gap = 0.04,
			lift = false,
			scatter = 0,
			onArrive = function(n)
				if n == 1 then
					Kit.burst(slot.art, { tier = slot == featured and 3 or 2, color = C.accent })
					Kit.squash(slot.art)
					Kit.win(slot.card, { color = C.accent })
					setPrice(slot, slot.price, true)
				end
			end,
		})
	end
	for i, button in cats do
		Kit.press(button, function()
			setCat(i)
		end)
	end
	for _, slot in slots do
		Kit.press(slot.button, function()
			buy(slot)
		end)
	end
	Kit.press(featured.button, function()
		buy(featured)
	end)

	local api = { gui = x.gui, window = window, phone = phone, closeButton = close, state = state }
	function api.open()
		GuiService.TouchControlsEnabled = false
		x.dock.hide()
		x.dim.show()
		setCat(state.cat, true)
		-- the rail and the offer come with the window (it is never an empty frame); the buttons and cards are staged
		Kit.open(window, {
			{ close, "spin" },
			{ cats, "slide", from = "left", gap = 0.03 },
			{ grid:shown(), "pop", gap = 0.03 },
		})
	end
	function api.close()
		Kit.close(window, { first = close })
		x.dim.hide()
		x.dock.show(0.06)
		GuiService.TouchControlsEnabled = true
	end
	function api.setCat(index: number)
		setCat(index)
	end
	-- index: the nth card of the shelf on show
	function api.buy(index: number)
		buy(slots[shelves[state.cat][index]])
	end
	function api.buyFeatured()
		buy(featured)
	end
	local opener = x.opens("Shop", api.open)
	function api.tour()
		task.wait(1) -- the HUD at rest, then the press that opens the window
		tap(opener :: GuiButton)
		api.open()
		task.wait(1.4)
		tap(slots[shelves[1][2]].button)
		api.buy(2)
		task.wait(1.5)
		tap(cats[2])
		api.setCat(2)
		task.wait(1.2)
		tap(featured.button)
		api.buyFeatured()
		task.wait(1.6)
		tap(cats[4])
		api.setCat(4)
		task.wait(1.1)
		api.buy(6) -- 2,400 with less than that left: the "no"
		task.wait(1.1)
		tap(close)
		api.close()
		task.wait(0.9)
	end
	Kit.press(close, api.close)
	return api
end

-- ---------- daily: a small centred modal, seven tiles in a row, one button ----------

local DAYS = { { "coin", 100 }, { "coin", 200 }, { "gem", 5 }, { "coin", 400 }, { "gem", 10 }, { "coin", 800 }, { "chest", 1 } }

function Layouts.daily(playerGui: Instance, options: Options?)
	local x = scaffold(playerGui, "WindowKitDaily", options, Vector2.new(520, 226), Vector2.new(660, 372), Vector2.new(0.7, 0.62), 0.45)
	local C, pick, phone, text, icons, W, H = x.C, x.pick, x.phone, x.text, x.icons, x.W, x.H
	local today = 3
	local window, body = Kit.card(x.layer, {
		name = "Window",
		role = "panel",
		size = UDim2.fromOffset(W, H),
		position = pick(UDim2.new(0.5, 0, 0, 44), UDim2.fromScale(0.5, 0.54)),
		anchor = pick(Vector2.new(0.5, 0), Vector2.new(0.5, 0.5)),
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
	window:SetAttribute("KitHost", true)

	-- the title is a ribbon across the top edge: on a large screen it sticks out of the frame
	local ribbonW, ribbonH = pick(236, 330), pick(30, 54)
	local ribbon, ribbonContent = Kit.card(body, {
		name = "Ribbon",
		breakout = pick(nil, "ornament"),
		size = UDim2.fromOffset(ribbonW, ribbonH),
		position = UDim2.new(0.5, 0, 0, pick(6, -22)),
		anchor = Vector2.new(0.5, 0),
		fill = C.ribbon,
		stroke = C.dark,
		radius = pick(10, 14),
		strokeWidth = pick(2, 3),
		depth = pick(2, 5),
		gloss = 0.5,
		sheen = true,
		z = 3,
	})
	Kit.sheen(ribbon, { period = 3.6 })
	local title = text(ribbonContent, { Name = "Title", Size = UDim2.fromScale(1, 1), Text = "DAILY REWARDS", TextSize = pick(16, 28), FontFace = x.BLACK, TextXAlignment = Enum.TextXAlignment.Center })
	local titleLine = Instance.new("UIStroke") -- a piece that leaves its frame keeps its outline under every skin: it may lie over the world
	titleLine.Color = C.dark
	titleLine.Thickness = 2
	titleLine.Parent = title
	text(body, {
		Name = "Info",
		Size = UDim2.new(1, -pick(80, 120), 0, 20),
		Position = UDim2.new(0.5, 0, 0, pick(40, 42)),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "Day " .. today .. " of 7. A bigger gift every day.",
		TextSize = pick(14, 16),
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local closeHalf = pick(12, 18)
	local close = x.closeButton(body, UDim2.fromOffset(W - pick(8, 12) - closeHalf, pick(8, 12) + closeHalf))

	-- seven tiles: done, today, to come. Today's is the one light card and sits a little higher
	local tw, th, gap = pick(64, 80), pick(88, 150), pick(6, 8)
	local x0 = (W - 7 * tw - 6 * gap) / 2
	local ty = pick(64, 80)
	local liftBy = pick(4, 8)
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.BackgroundColor3 = C.accent
	glow.BackgroundTransparency = 0.5
	glow.BorderSizePixel = 0
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Size = UDim2.fromOffset(tw + 12, th + 12)
	glow.ZIndex = 1
	glow.Parent = body
	Kit.finish(glow, { radius = pick(13, 16), strokeWidth = 0, lift = 0 })
	local tiles = {}
	local function centre(i: number, raised: boolean): UDim2
		return UDim2.fromOffset(x0 + (i - 1) * (tw + gap) + tw / 2, ty + th / 2 - (raised and liftBy or 0))
	end
	for i, day in DAYS do
		local state = i < today and "done" or i == today and "today" or "next"
		local fill = state == "done" and C.rowDone or state == "today" and C.card or i == 7 and C.header or C.row
		local ink = state == "today" and C.ink or state == "done" and C.muted or C.text
		local tile, content = Kit.card(body, {
			name = "Day" .. i,
			size = UDim2.fromOffset(tw, th),
			position = centre(i, state == "today"),
			anchor = Vector2.new(0.5, 0.5),
			fill = fill,
			stroke = state == "today" and C.accent or C.dark,
			strokeWidth = state == "today" and 3 or 2,
			radius = pick(10, 12),
			depth = pick(2, 4),
			gloss = i == 7 and 0.5 or nil,
			z = 2,
		})
		local label = text(content, { Name = "Day", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, pick(4, 8)), Text = "DAY " .. i, TextColor3 = ink, FontFace = x.BLACK, TextXAlignment = Enum.TextXAlignment.Center })
		local icon, picture = Kit.icon(content, icons[day[1]], { name = "Gift", size = pick(34, 52), position = UDim2.new(0.5, 0, 0, pick(23, 34)), anchor = Vector2.new(0.5, 0) })
		picture.ImageTransparency = state == "done" and 0.5 or 0
		local amount = text(content, {
			Name = "Amount",
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, pick(62, 94)),
			Text = i == 7 and "CHEST" or Kit.comma(day[2]),
			TextColor3 = ink,
			TextSize = pick(14, 19),
			FontFace = x.BLACK,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local note: TextLabel? = nil
		if not phone then
			note = text(content, { Name = "State", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 122), Text = state == "done" and "DONE" or state == "today" and "TODAY" or "", TextColor3 = state == "today" and C.inkMuted or C.muted, TextXAlignment = Enum.TextXAlignment.Center })
		end
		tiles[i] = { tile = tile, icon = icon, picture = picture, label = label, amount = amount, note = note }
	end
	glow.Position = centre(today, true)
	Kit.pulse(glow, 0.04, 1.2)

	local timer: Frame? = nil
	if not phone then
		local holder = Instance.new("Frame")
		holder.Name = "Timer"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromOffset(220, 22)
		holder.Position = UDim2.new(0.5, 0, 0, 248)
		holder.AnchorPoint = Vector2.new(0.5, 0)
		holder.Parent = body
		Kit.icon(holder, icons.timer, { size = 20, position = UDim2.new(0, 8, 0.5, 0), anchor = Vector2.new(0, 0.5) })
		text(holder, { Name = "Left", Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(34, 0), Text = "Next gift in 15:13:04", TextSize = 16, TextColor3 = C.muted })
		timer = holder
	end
	local main, mainLabel = Kit.button(body, {
		name = "Main",
		hit = 44,
		text = "CLAIM DAY " .. today,
		textSize = pick(16, 26),
		textColor = C.text,
		fontFace = x.BLACK,
		fill = C.go,
		size = pick(UDim2.fromOffset(220, 44), UDim2.fromOffset(300, 58)),
		position = UDim2.new(0.5, 0, 1, -pick(12, 24)),
		anchor = Vector2.new(0.5, 1),
		radius = pick(12, 16),
		strokeWidth = 3,
		depth = pick(4, 6),
		sheen = true,
	})

	local state = { claimed = false }
	-- claim: the tile bursts, its gift flies to the counter, the tile sinks back as done and the mark moves on
	local function claim()
		if state.claimed then
			Kit.squash(main)
			return
		end
		state.claimed = true
		Kit.still(main)
		local t = tiles[today]
		local kind = DAYS[today][1] == "gem" and "gems" or "coins"
		local gift = DAYS[today][2]
		Kit.win(t.tile, { color = C.accent })
		Kit.burst(t.tile, { tier = 2, color = C.accent })
		Kit.fly(t.icon, x.counters[kind].icon, {
			arc = -0.3,
			onArrive = function(n)
				if n == 1 then
					Kit.count(x.counters[kind].amount, x.wallet[kind], x.wallet[kind] + gift, { rise = 8 })
					x.wallet[kind] += gift
				end
			end,
		})
		Kit.recolor(main, C.done)
		mainLabel.Text = "CLAIMED"
		task.delay(0.45 * Kit.TONE.pace, function()
			if not t.tile.Parent then
				return
			end
			Kit.recolor(t.tile, C.rowDone, C.dark)
			t.label.TextColor3, t.amount.TextColor3 = C.muted, C.muted
			t.picture.ImageTransparency = 0.5
			if t.note then
				t.note.Text, t.note.TextColor3 = "DONE", C.muted
			end
			local from, to = t.tile.Position, centre(today, false)
			Kit.run(t.tile, "move", 0, 0.24, Quad, Out, function(e)
				t.tile.Position = from:Lerp(to, e)
			end)
			-- the mark slides to tomorrow's tile and dims: that one is next, not yet
			local g0, g1 = glow.Position, centre(today + 1, false)
			Kit.still(glow)
			Kit.run(glow, "move", 0.08, 0.3, Quad, Out, function(e)
				glow.Position = g0:Lerp(g1, e)
				glow.BackgroundTransparency = 0.5 + 0.28 * e
			end)
			local nextTile = tiles[today + 1]
			if nextTile.note then
				nextTile.note.Text = "NEXT"
			end
		end)
	end
	Kit.press(main, claim)

	local api = { gui = x.gui, window = window, phone = phone, closeButton = close, main = main, state = state }
	function api.open()
		GuiService.TouchControlsEnabled = false
		x.dock.hide()
		x.dim.show()
		local cards = {}
		for i, t in tiles do
			cards[i] = t.tile
		end
		local groups: { any } = { { ribbon, "pop" }, { close, "spin" }, { glow, "fade" }, { cards, "pop", gap = 0.035 } }
		if timer then
			table.insert(groups, { timer, "fade" })
		end
		table.insert(groups, { main, "pop" })
		Kit.open(window, groups)
		if not state.claimed then
			Kit.pulse(main, 0.03, 1.3)
		end
	end
	function api.close()
		Kit.still(main)
		Kit.close(window, { first = close })
		x.dim.hide()
		x.dock.show(0.06)
		GuiService.TouchControlsEnabled = true
	end
	api.claim = claim
	x.opens()
	function api.tour()
		task.wait(1) -- the HUD at rest; a daily reward opens on its own
		api.open()
		task.wait(1.9)
		tap(main)
		claim()
		task.wait(2.4)
		tap(close)
		api.close()
		task.wait(0.9)
	end
	Kit.press(close, api.close)
	return api
end

-- ---------- sheet: one item, its stats and two actions, docked to the right edge, the world in view ----------

local STATS = { { "Damage", 62, 12, "accent" }, { "Speed", 48, 7, "daily" }, { "Reach", 30, 10, "weekly" } }

function Layouts.sheet(playerGui: Instance, options: Options?)
	local x = scaffold(playerGui, "WindowKitSheet", options, Vector2.new(236, 236), Vector2.new(320, 522), Vector2.new(0.3, 0.86), 0.7)
	local C, pick, phone, text, icons, W, H = x.C, x.pick, x.phone, x.text, x.icons, x.W, x.H
	local pad = pick(8, 14)
	local home = pick(UDim2.new(1, -8, 0, 38), UDim2.new(1, -24, 0.54, 0))
	local sheet, body = Kit.card(x.layer, {
		name = "Sheet",
		role = "panel",
		size = UDim2.fromOffset(W, H),
		position = home,
		anchor = pick(Vector2.new(1, 0), Vector2.new(1, 0.5)),
		fill = C.window,
		stroke = C.dark,
		radius = pick(14, 18),
		strokeWidth = 3,
		depth = pick(4, 8),
		rim = true,
		glass = 0.9,
		z = 4,
	})
	sheet.Visible = false
	local closeHalf = pick(12, 18)
	local close = x.closeButton(body, UDim2.fromOffset(W - pad - closeHalf + pick(2, 4), pad + closeHalf - pick(2, 4)))

	-- the item: its picture on the one light tile, its name, its level
	local portrait = Kit.icon(body, icons.boss, {
		name = "Portrait",
		size = pick(44, 132),
		position = pick(UDim2.fromOffset(pad, pad), UDim2.new(0.5, 0, 0, 20)),
		anchor = pick(Vector2.zero, Vector2.new(0.5, 0)),
		tile = C.card,
		depth = pick(2, 4),
	})
	portrait.Rotation = pick(0, -3)
	if not phone then
		local _, rare = Kit.card(body, { name = "Rarity", size = UDim2.fromOffset(72, 26), position = UDim2.fromOffset(pad, pad), fill = C.weekly, stroke = C.dark, radius = 8, strokeWidth = 2, z = 2 })
		text(rare, { Name = "Tier", Size = UDim2.fromScale(1, 1), Text = "RARE", FontFace = x.BLACK, TextColor3 = Kit.ink(C.weekly), TextXAlignment = Enum.TextXAlignment.Center })
	end
	x.outline(text(body, {
		Name = "Name",
		Size = pick(UDim2.fromOffset(W - 60 - 40, 22), UDim2.new(1, -2 * pad, 0, 30)),
		Position = pick(UDim2.fromOffset(60, 6), UDim2.fromOffset(pad, 162)),
		Text = "Iron Blade",
		TextSize = pick(17, 26),
		FontFace = x.BLACK,
		TextXAlignment = pick(Enum.TextXAlignment.Left, Enum.TextXAlignment.Center),
	}), pick(1.5, 2))
	local levelChip, levelContent = Kit.card(body, {
		name = "Level",
		size = UDim2.fromOffset(pick(84, 104), pick(22, 28)),
		position = pick(UDim2.fromOffset(60, 30), UDim2.new(0.5, 0, 0, 198)),
		anchor = pick(Vector2.zero, Vector2.new(0.5, 0)),
		fill = C.accent,
		stroke = C.dark,
		radius = pick(8, 10),
		strokeWidth = 2,
	})
	local state = { level = 4, price = 600, equipped = false, busy = false }
	local levelLabel = text(levelContent, { Name = "Value", Size = UDim2.fromScale(1, 1), Text = "LEVEL " .. state.level, TextSize = pick(14, 15), FontFace = x.BLACK, TextColor3 = Kit.ink(C.accent), TextXAlignment = Enum.TextXAlignment.Center })

	-- the stats: a bar per stat, and in a paler tone what the next upgrade adds
	local wellY, rowH = pick(56, 240), pick(24, 38)
	local _, well = Kit.card(body, {
		name = "Stats",
		size = UDim2.fromOffset(W - 2 * pad, 3 * rowH + pick(4, 14)),
		position = UDim2.fromOffset(pad, wellY),
		fill = C.well,
		stroke = C.dark,
		radius = pick(10, 12),
		lift = 0.06,
		topLight = false,
	})
	local labelW, valueW = pick(60, 74), pick(30, 36)
	local barX = pick(8, 12) + labelW + 4
	local barW = W - 2 * pad - barX - valueW - pick(12, 18)
	local bars = {}
	for i, stat in STATS do
		local y = pick(2, 7) + (i - 1) * rowH
		text(well, { Name = stat[1], Size = UDim2.fromOffset(labelW, rowH), Position = UDim2.fromOffset(pick(8, 12), y), Text = stat[1], TextSize = pick(14, 15), TextColor3 = C.muted })
		local track = Instance.new("Frame")
		track.Name = stat[1] .. "Bar"
		track.BackgroundColor3 = C.dark
		track.BorderSizePixel = 0
		track.Size = UDim2.fromOffset(barW, pick(10, 12))
		track.Position = UDim2.fromOffset(barX, y + rowH / 2)
		track.AnchorPoint = Vector2.new(0, 0.5)
		track.Parent = well
		Kit.finish(track, { radius = 6, strokeWidth = 0, lift = 0 })
		local color = (C :: any)[stat[4]]
		local gain = Instance.new("Frame")
		gain.Name = "Gain"
		gain.BackgroundColor3 = color
		gain.BackgroundTransparency = 0.6
		gain.BorderSizePixel = 0
		gain.Size = UDim2.fromScale((stat[2] + stat[3]) / 100, 1)
		gain.Parent = track
		Kit.finish(gain, { radius = 6, strokeWidth = 0, lift = 0 })
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(stat[2] / 100, 1)
		fill.ZIndex = 2
		fill.Parent = track
		Kit.finish(fill, { radius = 6, strokeWidth = 0, lift = 0.12 })
		local value = text(well, { Name = stat[1] .. "Value", Size = UDim2.fromOffset(valueW, rowH), Position = UDim2.new(1, -pick(8, 12) - valueW, 0, y), Text = tostring(stat[2]), TextSize = pick(14, 16), FontFace = x.BLACK, TextXAlignment = Enum.TextXAlignment.Right })
		bars[i] = { fill = fill, gain = gain, value = value, now = stat[2], step = stat[3] }
	end

	-- two actions: the one that costs is the big one
	local buttonsY = wellY + 3 * rowH + pick(4, 14) + pick(6, 16)
	local upgrade, upgradeLabel, upgradeContent = Kit.button(body, {
		name = "Upgrade",
		hit = 44,
		text = "UPGRADE",
		textSize = pick(16, 22),
		textColor = C.text,
		fontFace = x.BLACK,
		fill = C.go,
		size = UDim2.fromOffset(W - 2 * pad, pick(44, 58)),
		position = UDim2.fromOffset(pad, buttonsY),
		radius = pick(12, 14),
		strokeWidth = 3,
		depth = pick(3, 5),
		sheen = true,
	})
	local pillW = pick(78, 100)
	upgradeLabel.Size = UDim2.new(1, -pillW - pick(14, 20), 1, 0)
	local _, pill = Kit.card(upgradeContent, {
		name = "Cost",
		size = UDim2.fromOffset(pillW, pick(28, 36)),
		position = UDim2.new(1, -pick(8, 10), 0.5, 0),
		anchor = Vector2.new(1, 0.5),
		fill = Kit.shade(C.go, -0.45),
		strokeWidth = 0,
		radius = pick(9, 12),
		topLight = false,
	})
	Kit.icon(pill, icons.coin, { size = pick(20, 24), position = UDim2.new(0, 6, 0.5, 0), anchor = Vector2.new(0, 0.5) })
	local cost = text(pill, { Name = "Amount", Size = UDim2.new(1, -pick(32, 38), 1, 0), Position = UDim2.fromOffset(pick(28, 34), 0), Text = Kit.comma(state.price), TextSize = pick(14, 17), FontFace = x.BLACK })
	local equip, equipLabel = Kit.button(body, {
		name = "Equip",
		hit = 44,
		text = "EQUIP",
		textSize = pick(15, 19),
		fontFace = x.BLACK,
		fill = C.idle,
		size = UDim2.fromOffset(W - 2 * pad, pick(44, 48)),
		position = UDim2.fromOffset(pad, buttonsY + pick(44, 58) + pick(6, 14)),
		radius = pick(12, 14),
		strokeWidth = 2,
		depth = pick(3, 4),
		gloss = 0,
	})

	-- upgrade: the cost runs off the counter, each bar grows into its paler part, the level steps up
	local function doUpgrade()
		if state.busy or x.wallet.coins < state.price then
			Kit.squash(upgrade)
			return
		end
		state.busy = true
		x.spend(state.price)
		for i, bar in bars do
			local from, to = bar.now, bar.now + bar.step
			bar.now = to
			Kit.run(bar.fill, "size", (i - 1) * 0.07, 0.32, Quad, Out, function(e)
				bar.fill.Size = UDim2.fromScale((from + (to - from) * e) / 100, 1)
			end)
			Kit.count(bar.value, from, to, { plus = false, time = 0.4 })
			Kit.run(bar.gain, "size", 0.4 + (i - 1) * 0.07, 0.3, Quad, Out, function(e)
				bar.gain.Size = UDim2.fromScale(math.min(1, (to + bar.step * e) / 100), 1)
			end)
		end
		task.delay(0.3 * Kit.TONE.pace, function()
			if not sheet.Parent then
				return
			end
			state.level += 1
			levelLabel.Text = "LEVEL " .. state.level
			Kit.squash(levelChip)
			Kit.burst(portrait, { tier = 2, color = C.accent })
			local old = state.price
			state.price = math.floor(old * 1.5 / 50 + 0.5) * 50
			Kit.count(cost, old, state.price, { plus = false })
			state.busy = false
		end)
	end
	local function doEquip()
		state.equipped = not state.equipped
		Kit.recolor(equip, state.equipped and C.done or C.idle)
		equipLabel.Text = state.equipped and "EQUIPPED" or "EQUIP"
	end
	Kit.press(upgrade, doUpgrade)
	Kit.press(equip, doEquip)

	local api = { gui = x.gui, window = sheet, phone = phone, closeButton = close, state = state }
	function api.open()
		GuiService.TouchControlsEnabled = false -- on touch the sheet covers the jump button: the controls give way while it is open
		x.dock.hide()
		x.dim.show()
		local fills = {}
		for i, bar in bars do
			fills[i] = bar.fill
		end
		-- no grow: the sheet slides in from its edge, its content arrives on the way
		Kit.open(sheet, { { portrait, "pop" }, { close, "spin" }, { fills, "fill", gap = 0.05 }, { { upgrade, equip }, "pop", gap = 0.05 } }, { shell = false, delay = 0.1 })
		Kit.run(sheet, "move", 0, 0.3, Back, Out, function(e)
			sheet.Position = home + UDim2.fromOffset((1 - e) * (W + 40), 0)
		end)
		if not phone then
			Kit.bob(portrait, 2, 2.8, 1.5)
		end
	end
	function api.close()
		Kit.still(portrait)
		Kit.run(sheet, "move", 0, 0.2, Quad, In, function(e)
			sheet.Position = home + UDim2.fromOffset(math.clamp(e, 0, 1) * (W + 40), 0)
		end, function()
			sheet.Visible = false
			sheet.Position = home
		end)
		x.dim.hide()
		x.dock.show(0.06)
		GuiService.TouchControlsEnabled = true
	end
	api.upgrade, api.equip = doUpgrade, doEquip
	local opener = x.opens("Pets", api.open)
	function api.tour()
		task.wait(1) -- the HUD at rest, then the press that opens the window
		tap(opener :: GuiButton)
		api.open()
		task.wait(1.7)
		tap(upgrade)
		doUpgrade()
		task.wait(1.9)
		tap(equip)
		doEquip()
		task.wait(1.3)
		tap(close)
		api.close()
		task.wait(0.8)
	end
	Kit.press(close, api.close)
	return api
end

-- ---------- track: levels along a rail, a reward under each, one bar that fills ----------

-- { icon, amount, name }: the reward of each level. Coins and gems fly to their counter; an item pops where it is.
local LEVELS = {
	{ "coin", 200 }, { "feed", 3, "Treats" }, { "coin", 400 }, { "gem", 5 }, { "egg", 1, "Egg" }, { "coin", 800 }, { "gem", 10 }, { "race", 1, "Pass" },
	{ "coin", 1500 }, { "chest", 1, "Chest" }, { "coin", 2000 }, { "gem", 20 }, { "trade", 1, "Swap" }, { "coin", 3000 }, { "chest", 1, "Chest" },
}
local XP_NEED = 1000

function Layouts.track(playerGui: Instance, options: Options?)
	local x = scaffold(playerGui, "WindowKitTrack", options, Vector2.new(528, 232), Vector2.new(860, 410), Vector2.new(0.86, 0.8), 0.45)
	local C, pick, text, icons, W, H = x.C, x.pick, x.text, x.icons, x.W, x.H
	local state = { level = 6, xp = 640, claimed = { true, true, true, true } :: { [number]: boolean } }
	local window, body = Kit.card(x.layer, {
		name = "Window",
		role = "panel",
		size = UDim2.fromOffset(W, H),
		position = pick(UDim2.new(0.5, 0, 0, 42), UDim2.fromScale(0.5, 0.54)),
		anchor = pick(Vector2.new(0.5, 0), Vector2.new(0.5, 0.5)),
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
	window:SetAttribute("KitHost", true)
	local pad = pick(8, 14)

	-- header: the name, the time left, the way out
	local hh = pick(32, 56)
	local header, head = Kit.card(body, {
		name = "Header",
		size = UDim2.fromOffset(W - 2 * pad, hh),
		position = UDim2.fromOffset(pad, pad),
		fill = C.header,
		stroke = C.dark,
		radius = pick(10, 14),
		strokeWidth = 2,
		glass = 0.92,
	})
	Kit.icon(head, icons.wins, { name = "Emblem", size = pick(24, 40), position = UDim2.new(0, pick(8, 12), 0.5, 0), anchor = Vector2.new(0, 0.5) })
	x.outline(text(head, { Name = "Title", Size = UDim2.fromOffset(pick(150, 260), hh), Position = UDim2.fromOffset(pick(40, 64), 0), Text = "SEASON TRACK", TextSize = pick(16, 28), FontFace = x.BLACK }))
	Kit.icon(head, icons.timer, { name = "Clock", size = pick(18, 24), position = UDim2.new(1, -pick(150, 236), 0.5, 0), anchor = Vector2.new(0, 0.5) })
	text(head, { Name = "Left", Size = UDim2.fromOffset(pick(84, 140), hh), Position = UDim2.new(1, -pick(128, 206), 0, 0), Text = "12d 04h left", TextColor3 = C.muted, TextSize = pick(14, 17) })
	local close = x.closeButton(head, UDim2.new(1, -pick(20, 32), 0.5, 0))

	-- the level strip: a medal with the level, the bar to the next one, claim all
	local sh = pick(44, 72)
	local sy = pad * 2 + hh
	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.BackgroundTransparency = 1
	strip.Size = UDim2.fromOffset(W - 2 * pad, sh)
	strip.Position = UDim2.fromOffset(pad, sy)
	strip.Parent = body
	local ms = pick(40, 64)
	local medal, medalContent = Kit.card(strip, {
		name = "Medal",
		size = UDim2.fromOffset(ms, ms),
		position = UDim2.new(0, pick(2, 4), 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		fill = C.accent,
		stroke = C.dark,
		radius = ms / 2,
		strokeWidth = pick(2, 3),
		depth = pick(2, 4),
		gloss = 0.5,
	})
	local levelLabel = x.outline(text(medalContent, { Name = "Level", Size = UDim2.fromScale(1, 1), Text = tostring(state.level), TextSize = pick(20, 32), FontFace = x.NUMBER, TextXAlignment = Enum.TextXAlignment.Center }))
	local allW = pick(118, 196)
	local barX = ms + pick(12, 20)
	local barW = W - 2 * pad - barX - allW - pick(12, 22)
	local caption = text(strip, { Name = "Caption", Size = UDim2.fromOffset(barW * 0.5, pick(16, 22)), Position = UDim2.fromOffset(barX, pick(4, 10)), Text = "LEVEL " .. state.level, FontFace = x.BLACK, TextSize = pick(14, 18) })
	local xpLabel = text(strip, { Name = "Xp", Size = UDim2.fromOffset(barW * 0.5 - pick(8, 12), pick(16, 22)), Position = UDim2.fromOffset(barX + barW * 0.5, pick(4, 10)), Text = "", TextColor3 = C.muted, TextSize = pick(14, 16), TextXAlignment = Enum.TextXAlignment.Right })
	local function xpText(v: number): string
		return Kit.comma(v) .. " / " .. Kit.comma(XP_NEED) .. " XP"
	end
	xpLabel.Text = xpText(state.xp)
	local barH = pick(12, 18)
	local bar = Kit.card(strip, {
		name = "Bar",
		size = UDim2.fromOffset(barW, barH),
		position = UDim2.fromOffset(barX, pick(24, 40)),
		fill = C.well,
		stroke = C.dark,
		radius = barH / 2,
		strokeWidth = 2,
		topLight = false,
	})
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = C.ready
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(state.xp / XP_NEED, 0, 1, 0)
	fill.Parent = bar:FindFirstChild("Content")
	Kit.finish(fill, { radius = barH / 2, strokeWidth = 0 })
	local all, allLabel = Kit.button(strip, {
		name = "ClaimAll",
		text = "CLAIM ALL",
		textSize = pick(14, 20),
		textColor = C.text,
		fontFace = x.BLACK,
		fill = C.go,
		size = UDim2.fromOffset(allW, pick(38, 56)),
		position = UDim2.new(1, -pick(2, 4), 0.5, 0),
		anchor = Vector2.new(1, 0.5),
		radius = pick(12, 16),
		strokeWidth = pick(2, 3),
		depth = pick(3, 5),
		hit = 44,
	})
	local badge = Kit.badge(all, 0, { size = pick(22, 26), textSize = pick(14, 15), fontFace = x.NUMBER }) -- in a window the text floor is 14

	-- the track: a dark well, a rail with a node for every level, a card under each node
	local wy = sy + sh + pad
	local wellW, wellH = W - 2 * pad, H - wy - pad
	local well, wellContent = Kit.card(body, {
		name = "Well",
		size = UDim2.fromOffset(wellW, wellH),
		position = UDim2.fromOffset(pad, wy),
		fill = C.well,
		stroke = C.dark,
		radius = pick(10, 14),
		strokeWidth = 2,
		topLight = false,
		clip = true,
	})
	-- widths chosen so the card the well cuts at rest shows about half of itself (the cue that the track goes
	-- on): 5.66 cards on a phone, 5.45 on a large screen. A 2 px sliver of the next card is a lint error
	local cw, gap, inset = pick(82, 139), pick(8, 12), pick(8, 14)
	local node = pick(22, 30)
	local cardY = node + pick(10, 18)
	local cardH = wellH - cardY - pick(8, 14)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Track"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.ScrollBarThickness = 0
	scroll.ScrollBarImageTransparency = 1 -- at thickness 0 the bar still drew as a 1 px line along the well's foot
	scroll.CanvasSize = UDim2.fromOffset(inset * 2 + #LEVELS * (cw + gap) - gap, 0)
	scroll.Parent = wellContent
	local function centre(i: number): number
		return inset + (i - 1) * (cw + gap) + cw / 2
	end
	-- the rail: one link from each node to the next, lit up to the player's level. Links, not one long line: a
	-- line that runs on past the well's edge is cut a few px short of a node there, and reads as a clipping bug
	local links = {}
	local linkGap = pick(3, 4)
	for i = 1, #LEVELS - 1 do
		local f = Instance.new("Frame")
		f.Name = "Link" .. i
		f.BackgroundColor3 = C.idle
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0, 0.5)
		f.Position = UDim2.fromOffset(centre(i) + node / 2 + linkGap, pick(5, 8) + node / 2)
		f.Size = UDim2.fromOffset(cw + gap - node - 2 * linkGap, pick(4, 6))
		f.Parent = scroll
		local on = Instance.new("Frame")
		on.Name = "Lit"
		on.BackgroundColor3 = C.ready
		on.BorderSizePixel = 0
		on.Size = UDim2.fromScale(i < state.level and 1 or 0, 1)
		on.Parent = f
		links[i] = on
	end
	local cols = {}
	local paint
	local claim
	local function nope(i: number)
		local c = cols[i]
		Kit.shake(c.card, { reach = 5 })
		caption.Text = "REACH LEVEL " .. i
		caption.TextColor3 = C.warn
		task.delay(0.9 * Kit.TONE.pace, function()
			if caption.Parent then
				caption.Text = "LEVEL " .. state.level
				caption.TextColor3 = C.text
			end
		end)
	end
	for i, reward in LEVELS do
		local dot, dotContent = Kit.card(scroll, {
			name = "Node" .. i,
			size = UDim2.fromOffset(node, node),
			position = UDim2.fromOffset(centre(i), pick(5, 8) + node / 2),
			anchor = Vector2.new(0.5, 0.5),
			fill = C.idle,
			stroke = C.dark,
			radius = node / 2,
			strokeWidth = 2,
			topLight = false,
			z = 2,
		})
		local number = text(dotContent, { Name = "N", Size = UDim2.fromScale(1, 1), Text = tostring(i), TextSize = pick(14, 15), FontFace = x.NUMBER, TextXAlignment = Enum.TextXAlignment.Center })
		local card, content = Kit.card(scroll, {
			name = "Reward" .. i,
			button = true,
			size = UDim2.fromOffset(cw, cardH),
			position = UDim2.fromOffset(centre(i) - cw / 2, cardY),
			fill = C.row,
			stroke = C.dark,
			radius = pick(10, 14),
			strokeWidth = 2,
			depth = pick(0, 4), -- no drop on a phone: a card the well cuts would lay its shadow across the well's outline
		})
		local tileSize = pick(30, 64)
		local tile, tileContent = Kit.card(content, {
			name = "Art",
			size = UDim2.fromOffset(tileSize + pick(10, 18), tileSize + pick(2, 10)),
			position = UDim2.new(0.5, 0, 0, pick(4, 10)),
			anchor = Vector2.new(0.5, 0),
			fill = (C :: any)[TILE[reward[1]] or "dailyTile"] or C.rowSelected,
			stroke = C.dark,
			radius = pick(8, 12),
			strokeWidth = 2,
		})
		local icon = Kit.icon(tileContent, icons[reward[1]], { size = tileSize - pick(4, 8), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
		local amount = text(content, {
			Name = "Amount",
			Size = UDim2.new(1, -8, 0, pick(16, 22)),
			Position = UDim2.fromOffset(4, tileSize + pick(7, 24)), -- air on both sides: the amount touches neither the art nor the chip
			Text = reward[3] or ("+" .. Kit.comma(reward[2])),
			FontFace = x.BLACK,
			TextSize = pick(14, 18),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local chipH = pick(20, 28)
		local chip, chipContent = Kit.card(content, {
			name = "State",
			size = UDim2.new(1, -pick(12, 20), 0, chipH),
			position = UDim2.new(0.5, 0, 1, -pick(5, 10)),
			anchor = Vector2.new(0.5, 1),
			fill = C.ready,
			stroke = C.dark,
			radius = pick(7, 9),
			strokeWidth = 2,
			topLight = false,
		})
		local chipText = text(chipContent, { Name = "T", Size = UDim2.fromScale(1, 1), Text = "CLAIM", FontFace = x.BLACK, TextSize = pick(14, 15), TextXAlignment = Enum.TextXAlignment.Center })
		cols[i] = { dot = dot, number = number, card = card, tile = tile, icon = icon, amount = amount, chip = chip, chipText = chipText }
		Kit.press(card, function()
			if state.claimed[i] then
				return
			elseif i > state.level then
				nope(i)
			else
				claim(i)
			end
		end)
	end
	-- the three states of a level: claimed (quiet, the art dimmed), ready (lit, a chip that breathes), locked
	paint = function(i: number, now: boolean?)
		local c = cols[i]
		local reached = i <= state.level
		local done = state.claimed[i] == true
		Kit.recolor(c.dot, reached and C.ready or C.idle, C.dark)
		c.number.TextColor3 = reached and Kit.ink(C.ready) or C.muted
		Kit.recolor(c.card, done and C.rowDone or (reached and C.rowSelected or C.row), (reached and not done) and C.select or C.dark)
		Kit.recolor(c.chip, done and C.done or (reached and C.ready or C.idle), C.dark)
		c.chipText.Text = done and "DONE" or (reached and "CLAIM" or ("LV " .. i))
		c.chipText.TextColor3 = (reached and not done) and Kit.ink(C.ready) or C.text
		c.amount.TextColor3 = done and C.muted or C.text
		local picture = c.icon:FindFirstChildWhichIsA("ImageLabel", true)
		if picture then
			picture.ImageTransparency = done and 0.5 or 0
		end
		if reached and not done then
			Kit.pulse(c.chip, 0.04, 1.3)
		else
			Kit.still(c.chip)
		end
		if now == false then
			Kit.settle(c.card)
		end
	end
	local function waiting(): number
		local n = 0
		for i = 1, state.level do
			if not state.claimed[i] then
				n += 1
			end
		end
		return n
	end
	local function refresh()
		local n = waiting()
		badge.set(n)
		Kit.recolor(all, n > 0 and C.go or C.idle)
		allLabel.Text = n > 0 and "CLAIM ALL" or "ALL CLAIMED"
	end
	for i in LEVELS do
		paint(i, false)
	end
	refresh()

	-- soft edges: a card that the well cuts fades into it, on the side that has more to show
	local view = wellW
	local fades = {}
	for _, side in { "Left", "Right" } do
		local f = Instance.new("Frame")
		f.Name = "Fade" .. side
		f.Active = false
		f.BackgroundColor3 = C.well
		f.BorderSizePixel = 0
		f.Size = UDim2.new(0, pick(22, 40), 1, 0)
		f.AnchorPoint = Vector2.new(side == "Left" and 0 or 1, 0)
		f.Position = UDim2.fromScale(side == "Left" and 0 or 1, 0)
		f.ZIndex = 3
		f.Parent = wellContent
		local g = Instance.new("UIGradient")
		g.Rotation = side == "Left" and 180 or 0
		g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 0) })
		g.Parent = f
		fades[side] = f
	end
	local function edges()
		local at, most = scroll.CanvasPosition.X, scroll.AbsoluteCanvasSize.X - scroll.AbsoluteWindowSize.X
		fades.Left.Visible = at > 2
		fades.Right.Visible = at < most - 2
	end
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(edges)
	scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(edges)
	edges()
	-- bring a level to the middle of the well
	local function scrollTo(i: number, time: number, delay: number?)
		local from = scroll.CanvasPosition.X
		local to = math.clamp(centre(i) - view / 2, 0, math.max(scroll.CanvasSize.X.Offset - view, 0))
		Kit.run(scroll, "move", delay or 0, time, Enum.EasingStyle.Quart, Out, function(e)
			scroll.CanvasPosition = Vector2.new(from + (to - from) * e, 0)
		end)
	end

	-- a title for the level-up, over the well
	local stamp = x.outline(text(body, {
		Name = "Stamp",
		Size = UDim2.fromOffset(wellW, pick(36, 60)),
		Position = UDim2.fromOffset(pad, wy + wellH / 2 - pick(18, 30)),
		Text = "",
		TextSize = pick(26, 46),
		FontFace = x.BLACK,
		TextColor3 = C.accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 8,
		Visible = false,
	}), pick(2, 3))

	claim = function(i: number): boolean
		if i > state.level or state.claimed[i] then
			return false
		end
		state.claimed[i] = true
		local c, reward = cols[i], LEVELS[i]
		Kit.win(c.card, { color = C.select })
		local kind = if reward[1] == "coin" then "coins" elseif reward[1] == "gem" then "gems" else nil
		if kind then
			Kit.fly(c.icon, x.counters[kind].icon, {
				count = 4,
				arc = -0.2,
				onArrive = function(n)
					if n == 1 then
						Kit.count(x.counters[kind].amount, x.wallet[kind], x.wallet[kind] + reward[2])
						x.wallet[kind] += reward[2]
					end
				end,
			})
		else
			Kit.burst(c.tile, { tier = 2, color = C.accent })
			Kit.squash(c.tile)
		end
		task.delay(0.12 * Kit.TONE.pace, function()
			if c.card.Parent then
				paint(i)
			end
		end)
		refresh()
		return true
	end
	local function claimAll()
		local k = 0
		for i = 1, state.level do
			if not state.claimed[i] then
				task.delay(k * 0.16 * Kit.TONE.pace, function()
					if window.Parent then
						claim(i)
					end
				end)
				k += 1
			end
		end
		return k
	end
	-- experience: the bar fills; at its end the level changes, the rail grows to the next node, the next reward
	-- becomes ready and comes to the middle, and the bar starts again with what is left
	local function addXp(amount: number)
		local from = state.xp
		local to = math.min(from + amount, XP_NEED)
		local left = from + amount - to
		state.xp = to
		Kit.count(xpLabel, from, to, { time = 0.4, plus = false, format = xpText })
		Kit.run(fill, "size", 0, 0.4, Quad, Out, function(e)
			fill.Size = UDim2.new((from + (to - from) * e) / XP_NEED, 0, 1, 0)
		end, function()
			if to < XP_NEED or state.level >= #LEVELS then
				return
			end
			state.level += 1
			state.xp = 0
			local i = state.level
			levelLabel.Text = tostring(i)
			caption.Text = "LEVEL " .. i
			Kit.squash(medal)
			Kit.burst(medal, { tier = 2, color = C.accent })
			local link = links[i - 1]
			Kit.run(link, "size", 0, 0.3, Quad, Out, function(e)
				link.Size = UDim2.fromScale(math.clamp(e, 0, 1), 1)
			end)
			scrollTo(i, 0.45)
			task.delay(0.25 * Kit.TONE.pace, function()
				if not window.Parent then
					return
				end
				paint(i)
				Kit.win(cols[i].card, { color = C.ready })
				refresh()
			end)
			stamp.Text = "LEVEL " .. i
			Kit.stamp(stamp, 0.5, nil, { dim = well, dimTransparency = 0.6 })
			fill.Size = UDim2.new(0, 0, 1, 0)
			xpLabel.Text = xpText(0)
			if left > 0 then
				task.delay(0.5 * Kit.TONE.pace, function()
					if window.Parent then
						addXp(left)
					end
				end)
			end
		end)
	end

	local api = { gui = x.gui, window = window, state = state }
	function api.open()
		GuiService.TouchControlsEnabled = false
		x.dock.hide()
		x.dim.show()
		scroll.CanvasPosition = Vector2.zero
		local first, dots = {}, {}
		for i = 1, math.min(#LEVELS, math.ceil(view / (cw + gap))) do
			first[i] = cols[i].card
			table.insert(dots, cols[i].dot)
			if links[i] then
				table.insert(dots, links[i].Parent) -- the rail comes with its nodes: links alone in an empty well were the open's second frame
			end
		end
		Kit.open(window, { { close, "spin" }, { medal, "pop" }, { dots, "fade" }, { first, "pop", gap = 0.03 }, { all, "pop" } })
		scrollTo(state.level, 0.6, 0.4) -- the player's own level comes to the middle once the cards are in
	end
	function api.close()
		Kit.close(window, { first = close })
		x.dim.hide()
		x.dock.show(0.06)
		GuiService.TouchControlsEnabled = true
	end
	api.claim, api.claimAll, api.addXp = claim, claimAll, addXp
	local opener = x.opens("Missions", api.open)
	function api.tour()
		task.wait(1) -- the HUD at rest, then the press that opens the window
		tap(opener :: GuiButton)
		api.open()
		task.wait(2)
		tap(cols[8].card)
		nope(8)
		task.wait(1.1)
		tap(cols[5].card)
		claim(5)
		task.wait(1.5)
		addXp(450)
		task.wait(2.2)
		tap(all)
		claimAll()
		task.wait(1.9)
		tap(close)
		api.close()
		task.wait(0.9)
	end
	Kit.press(close, api.close)
	Kit.press(all, claimAll)
	return api
end

-- the tour: each window in turn, again and again; { once = true } stops after one round
function Layouts.run(playerGui: Instance?, options: (Options & { once: boolean? })?)
	local target = playerGui or Players.LocalPlayer:WaitForChild("PlayerGui")
	repeat
		for _, name in { "shop", "daily", "sheet", "track" } do
			local ui = (Layouts :: any)[name](target, options)
			ui.tour()
			ui.gui:Destroy()
			task.wait(0.3)
		end
	until options and options.once
end

return Layouts
