-- WindowKit demo: a small missions window over a HUD, built only with WindowKit and Frames, and a
-- tour that plays every motion: open in order, select, change tab, a routine claim (rewards fly to
-- the counters, the row moves down), a special claim (burst and stamped title), close.
-- Setup: WindowKit and this file as ModuleScripts in one folder (ReplicatedStorage.Ui), then from a
-- LocalScript: require(ReplicatedStorage.Ui.WindowKitDemo).run()   -- loops the tour until the gui is destroyed
-- Read it for the calls, not for the look: the palette at the top is one example; use your game's.
-- It scales one 16:9 desktop layout to fit the view, which drops text under the floors on a phone:
-- a real screen lays out and sizes its text per device (section 0 and section 4).
local Players = game:GetService("Players")

local Kit = require(script.Parent.WindowKit)

local Demo = {}

local C = {
	window = Color3.fromRGB(43, 49, 84),
	pane = Color3.fromRGB(31, 35, 62),
	row = Color3.fromRGB(58, 66, 110),
	rowSelected = Color3.fromRGB(80, 92, 150),
	rowDone = Color3.fromRGB(40, 45, 74),
	accent = Color3.fromRGB(255, 176, 46),
	ready = Color3.fromRGB(84, 206, 98),
	idle = Color3.fromRGB(96, 104, 140),
	danger = Color3.fromRGB(238, 84, 84),
	coin = Color3.fromRGB(255, 204, 64),
	gem = Color3.fromRGB(94, 214, 255),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(176, 186, 224),
	ink = Color3.fromRGB(18, 20, 38),
	daily = Color3.fromRGB(94, 214, 255),
	weekly = Color3.fromRGB(196, 132, 255),
}
local DISPLAY, BODY = Enum.Font.FredokaOne, Enum.Font.GothamBold

local MISSIONS = {
	{ id = "d1", tab = "Daily", title = "Hatch 5 eggs", info = "Any egg counts. Golden eggs count twice.", have = 5, need = 5, coins = 250, gems = 0 },
	{ id = "d2", tab = "Daily", title = "Win 3 races", info = "Finish first on any track.", have = 2, need = 3, coins = 400, gems = 0 },
	{ id = "d3", tab = "Daily", title = "Feed your pet", info = "Give any pet a treat from the shop.", have = 0, need = 1, coins = 120, gems = 0 },
	{ id = "w1", tab = "Weekly", title = "Beat the island boss", info = "Clear the last gate of any island.", have = 4, need = 4, coins = 2000, gems = 25, special = true },
	{ id = "w2", tab = "Weekly", title = "Trade with 4 friends", info = "Complete a trade in the plaza.", have = 1, need = 4, coins = 900, gems = 10 },
}
local TABS = { "All", "Daily", "Weekly" }

local function text(parent: Instance, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = BODY
	label.TextColor3 = C.text
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in props do
		(label :: any)[k] = v
	end
	label.Parent = parent
	return label
end

local function outline(label: TextLabel, color: Color3?, width: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or C.ink
	s.Thickness = width or 2
	s.Parent = label
	return label
end

-- a coin or a gem drawn with frames (your game uses its icon pack here)
local function token(parent: Instance, kind: string, size: number, position: UDim2?)
	local color = kind == "gem" and C.gem or C.coin
	local t = Kit.card(parent, {
		name = kind,
		size = UDim2.fromOffset(size, size),
		position = position,
		fill = color,
		radius = kind == "gem" and math.floor(size * 0.24) or size,
		strokeWidth = 2,
		lift = 0.22,
	})
	t.Rotation = kind == "gem" and 45 or 0
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(0.5, 0.5)
	inner.BackgroundColor3 = Kit.shade(color, 0.45)
	inner.BackgroundTransparency = 0.35
	inner.BorderSizePixel = 0
	inner.ZIndex = 3
	inner.Parent = t
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(kind == "gem" and 0.2 or 1, 0)
	corner.Parent = inner
	return t
end

function Demo.build(playerGui: Instance)
	local gui = Instance.new("ScreenGui")
	gui.Name = "WindowKitDemo"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local view = workspace.CurrentCamera.ViewportSize
	local fit = math.clamp(math.min(view.X / 980, view.Y / 560), 0.6, 1.6)
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1 / fit, 1 / fit)
	root.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = fit
	scale.Parent = root

	-- HUD: two counters at the top right
	local wallet = { coins = 1200, gems = 30 }
	local counters = {}
	for i, kind in { "coins", "gems" } do
		local pill, content = Kit.card(root, {
			name = kind,
			size = UDim2.fromOffset(150, 40),
			position = UDim2.new(1, -16 - (3 - i) * 162 + 12, 0, 14),
			fill = C.pane,
			radius = 20,
			depth = 3,
		})
		local icon = token(content, kind == "gems" and "gem" or "coin", kind == "gems" and 20 or 26, UDim2.fromOffset(kind == "gems" and 12 or 8, kind == "gems" and 10 or 7))
		local amount = outline(text(content, {
			Name = "Amount",
			Size = UDim2.new(1, -52, 1, 0),
			Position = UDim2.fromOffset(44, 0),
			Text = Kit.comma(wallet[kind]),
			TextSize = 18,
			Font = DISPLAY,
		}))
		counters[kind] = { pill = pill, icon = icon, amount = amount }
	end

	-- the window
	local window, body = Kit.card(root, {
		name = "Window",
		size = UDim2.fromOffset(700, 420),
		position = UDim2.fromScale(0.5, 0.54),
		anchor = Vector2.new(0.5, 0.5),
		fill = C.window,
		radius = 20,
		strokeWidth = 3,
		depth = 9,
	})
	window.Visible = false

	-- title plate and a hero emblem that sit over the top edge
	local plate, plateContent = Kit.card(body, {
		name = "Plate",
		size = UDim2.fromOffset(250, 50),
		position = UDim2.new(0.5, 0, 0, -20),
		anchor = Vector2.new(0.5, 0.5),
		fill = C.accent,
		radius = 14,
		strokeWidth = 3,
		depth = 4,
		sheen = true,
	})
	outline(text(plateContent, { Size = UDim2.fromScale(1, 1), Text = "MISSIONS", TextSize = 26, Font = DISPLAY, TextXAlignment = Enum.TextXAlignment.Center }), Kit.shade(C.accent, -0.6), 2.5)
	local emblem, emblemContent = Kit.card(body, {
		name = "Emblem",
		size = UDim2.fromOffset(92, 92),
		position = UDim2.fromOffset(34, -14),
		anchor = Vector2.new(0.5, 0.5),
		fill = C.coin,
		radius = 46,
		strokeWidth = 4,
		depth = 5,
		lift = 0.25,
	})
	emblem.Rotation = -8
	Kit.glint(emblemContent, 58, Color3.new(1, 1, 1)).Position = UDim2.fromScale(0.5, 0.5)
	local sparkles = {}
	for i, spot in { UDim2.new(0.5, -150, 0, -34), UDim2.new(0.5, 146, 0, -6), UDim2.new(0.5, 168, 0, -38) } do
		local g = Kit.glint(body, 12 + i * 4, Color3.new(1, 1, 1))
		g.Position = spot
		sparkles[i] = g
	end
	local close = Kit.button(body, {
		name = "Close",
		text = "X",
		textSize = 20,
		font = DISPLAY,
		fill = C.danger,
		size = UDim2.fromOffset(44, 44),
		position = UDim2.new(1, -8, 0, 8),
		anchor = Vector2.new(0.5, 0.5),
		radius = 22,
		strokeWidth = 3,
	})

	-- tabs with counts, and a marker that slides under the chosen one
	local tabBar = Instance.new("Frame")
	tabBar.Name = "Tabs"
	tabBar.BackgroundTransparency = 1
	tabBar.Size = UDim2.fromOffset(330, 40)
	tabBar.Position = UDim2.fromOffset(20, 26)
	tabBar.Parent = body
	local tabs = {}
	for i, name in TABS do
		local n = 0
		for _, m in MISSIONS do
			n += (name == "All" or m.tab == name) and 1 or 0
		end
		local tab, label = Kit.button(tabBar, {
			name = name,
			text = name .. "  " .. n,
			textSize = 15,
			fill = C.idle,
			size = UDim2.fromOffset(104, 34),
			position = UDim2.fromOffset((i - 1) * 112, 0),
			radius = 10,
			depth = 3,
		})
		tabs[name] = { button = tab, label = label }
	end
	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.BackgroundColor3 = C.accent
	marker.BorderSizePixel = 0
	marker.Size = UDim2.fromOffset(104, 4)
	marker.Position = UDim2.fromOffset(0, 40)
	marker.Parent = tabBar
	Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)

	-- the list: keyed rows, no UIListLayout
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromOffset(346, 326)
	scroll.Position = UDim2.fromOffset(14, 80)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = C.muted
	scroll.Parent = body
	local list = Kit.list(scroll, { gap = 8, pad = 6 })
	local rows = {}
	for _, m in MISSIONS do
		local row, content = Kit.card(nil :: any, {
			name = m.id,
			button = true,
			size = UDim2.new(1, -18, 0, 66),
			position = UDim2.fromOffset(6, 0),
			fill = C.row,
			radius = 12,
			depth = 3,
		})
		local stripe = Instance.new("Frame")
		stripe.Name = "Stripe"
		stripe.BackgroundColor3 = m.tab == "Daily" and C.daily or C.weekly
		stripe.BorderSizePixel = 0
		stripe.Size = UDim2.new(0, 5, 1, -16)
		stripe.Position = UDim2.fromOffset(8, 8)
		stripe.Parent = content
		Instance.new("UICorner", stripe).CornerRadius = UDim.new(1, 0)
		token(content, m.gems > 0 and "gem" or "coin", m.gems > 0 and 26 or 34, UDim2.fromOffset(m.gems > 0 and 28 or 24, m.gems > 0 and 20 or 16))
		text(content, { Name = "Title", Size = UDim2.new(1, -150, 0, 20), Position = UDim2.fromOffset(70, 10), Text = m.title, TextSize = 16 })
		local barBack = Instance.new("Frame")
		barBack.Name = "Bar"
		barBack.BackgroundColor3 = C.ink
		barBack.BorderSizePixel = 0
		barBack.Size = UDim2.new(1, -150, 0, 10)
		barBack.Position = UDim2.fromOffset(70, 40)
		barBack.Parent = content
		Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = m.have >= m.need and C.ready or C.accent
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(m.have / m.need, 1)
		fill.Parent = barBack
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
		local count = text(content, {
			Name = "Count",
			Size = UDim2.fromOffset(64, 20),
			Position = UDim2.new(1, -74, 0, 34),
			Text = m.have .. "/" .. m.need,
			TextSize = 14,
			TextColor3 = C.muted,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		-- "ready" has its own mark: a green chip, never the selection outline
		local chip, chipContent = Kit.card(content, {
			name = "Ready",
			size = UDim2.fromOffset(62, 22),
			position = UDim2.new(1, -72, 0, 8),
			fill = C.ready,
			radius = 8,
			strokeWidth = 1.5,
		})
		text(chipContent, { Size = UDim2.fromScale(1, 1), Text = "READY", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center })
		chip.Visible = m.have >= m.need
		list:add(m.id, row)
		rows[m.id] = { row = row, fill = fill, count = count, chip = chip, mission = m }
		if chip.Visible then
			Kit.pulse(chip, 0.07, 1.1)
		end
	end

	-- the detail pane: the selected mission's art is the largest thing in it
	local pane, detail = Kit.card(body, {
		name = "Detail",
		size = UDim2.fromOffset(310, 320),
		position = UDim2.fromOffset(374, 84),
		fill = C.pane,
		radius = 16,
		strokeWidth = 2,
	})
	local art = Instance.new("Frame")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.Size = UDim2.fromOffset(96, 96)
	art.Position = UDim2.fromOffset(16, -22)
	art.Parent = detail
	local title = outline(text(detail, { Name = "Title", Size = UDim2.new(1, -132, 0, 44), Position = UDim2.fromOffset(122, 12), TextSize = 20, Font = DISPLAY, TextWrapped = true }))
	local info = text(detail, { Name = "Info", Size = UDim2.new(1, -32, 0, 36), Position = UDim2.fromOffset(16, 80), TextColor3 = C.muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
	local stepsHolder = Instance.new("Frame")
	stepsHolder.Name = "Progress"
	stepsHolder.BackgroundTransparency = 1
	stepsHolder.Size = UDim2.new(1, -32, 0, 18)
	stepsHolder.Position = UDim2.fromOffset(16, 124)
	stepsHolder.Parent = detail
	local tiles = {}
	for i, kind in { "coins", "gems" } do
		local tile, tileContent = Kit.card(detail, {
			name = kind .. "Tile",
			size = UDim2.fromOffset(86, 74),
			position = UDim2.fromOffset(16 + (i - 1) * 96, 160),
			fill = C.row,
			radius = 12,
			depth = 3,
		})
		local icon = token(tileContent, kind == "gems" and "gem" or "coin", kind == "gems" and 28 or 38, UDim2.fromOffset(kind == "gems" and 29 or 24, kind == "gems" and 12 or 8))
		local amount = outline(text(tileContent, { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -24), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center }))
		tiles[kind] = { tile = tile, icon = icon, amount = amount }
	end
	local main, mainLabel = Kit.button(detail, {
		name = "Main",
		text = "CLAIM",
		textSize = 20,
		font = DISPLAY,
		fill = C.ready,
		size = UDim2.new(1, -32, 0, 50),
		position = UDim2.new(0, 16, 1, -64),
		radius = 14,
		strokeWidth = 3,
		depth = 5,
	})
	-- the stamped title of a big moment: a ribbon across the window
	local stamp, stampContent = Kit.card(body, {
		name = "Stamp",
		size = UDim2.new(1, 40, 0, 72),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		z = 20,
		fill = C.accent,
		radius = 16,
		strokeWidth = 4,
		depth = 8,
		sheen = true,
	})
	outline(text(stampContent, { Size = UDim2.fromScale(1, 1), Text = "WEEKLY CLEAR!", TextSize = 40, Font = DISPLAY, TextXAlignment = Enum.TextXAlignment.Center }), Kit.shade(C.accent, -0.6), 3)
	stamp.Visible = false

	local state = { tab = "All", selected = nil :: string?, claimed = {} :: { [string]: boolean }, steps = nil :: any }

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
		Kit.recolor(main, claimed and C.rowDone or (ready and C.ready or C.idle))
		Kit.still(main)
		if ready and not claimed then
			Kit.pulse(main, 0.03, 1.3)
			Kit.sheen(main, { period = 2.6 })
		end
	end

	local function select(id: string, wait: number?)
		if state.selected == id then
			return
		end
		local was = state.selected and rows[state.selected]
		if was then
			Kit.recolor(was.row, state.claimed[state.selected :: string] and C.rowDone or C.row)
		end
		state.selected = id
		local r = rows[id]
		local m = r.mission
		-- selected: a lighter fill and a bright outline that belong to the row, so they travel with it
		Kit.recolor(r.row, C.rowSelected, Color3.new(1, 1, 1))
		-- the pane changes on the same frame, and its parts arrive in order
		art:ClearAllChildren()
		token(art, m.gems > 0 and "gem" or "coin", m.gems > 0 and 64 or 88, UDim2.fromOffset(m.gems > 0 and 16 or 4, m.gems > 0 and 16 or 4))
		title.Text = m.title
		info.Text = m.info
		stepsHolder:ClearAllChildren()
		state.steps = Kit.steps(stepsHolder, m.need, m.have, { color = m.have >= m.need and C.ready or C.accent })
		tiles.coins.amount.Text = Kit.comma(m.coins)
		tiles.gems.amount.Text = Kit.comma(m.gems)
		tiles.gems.tile.Visible = m.gems > 0
		paintMain(m)
		Kit.open(pane, {
			{ art, "pop" },
			{ { title, info }, "fade", gap = 0.03 },
			{ state.steps.slots, "pop", gap = 0.02 },
			{ { tiles.coins.tile, tiles.gems.tile }, "pop", gap = 0.04 },
			{ main, "pop" },
		}, { shell = false, budget = wait and 0.5 or 0.3, delay = wait or 0 }) -- a change of selection is quick; the first fill follows the window
	end

	local function setTab(name: string)
		if state.tab == name then
			return
		end
		Kit.recolor(tabs[state.tab].button, C.idle)
		state.tab = name
		Kit.recolor(tabs[name].button, C.accent)
		Kit.slideTo(marker, tabs[name].button)
		local keys = keysFor(name)
		list:show(keys) -- old rows leave while the new ones arrive: the list is never blank
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
		if m.special then
			Kit.burst(art, { tier = 3, color = C.accent })
			Kit.stamp(stamp, 0.9)
		end
		local last = m.gems > 0 and "gems" or "coins"
		for _, kind in { "coins", "gems" } do
			local amount = m[kind]
			if amount > 0 then
				Kit.fly(tiles[kind].icon, counters[kind].icon, {
					count = m.special and 8 or 5,
					dimSource = false,
					onArrive = function(i)
						if i == 1 then
							Kit.count(counters[kind].amount, wallet[kind], wallet[kind] + amount)
							wallet[kind] += amount
						end
					end,
				})
				Kit.fade(tiles[kind].tile, 0.4, 0.2, 0.25) -- the slot keeps a faded copy
			end
		end
		task.delay(1.0, function()
			if gui.Parent then
				Kit.recolor(r.row, C.rowDone, state.selected == id and Color3.new(1, 1, 1) or nil)
				r.fill.BackgroundColor3 = C.idle
				r.count.Text = "DONE"
				list:order(keysFor(state.tab)) -- the claimed row goes down; the others close the gap
			end
		end)
		return last
	end

	for name, t in tabs do
		Kit.press(t.button, function()
			setTab(name)
		end)
	end
	for id, r in rows do
		Kit.press(r.row, function()
			select(id)
		end)
	end
	Kit.press(main, function()
		if state.selected then
			claim(state.selected)
		end
	end)

	local api = { gui = gui, window = window, main = main, closeButton = close, rows = rows, tabs = tabs, state = state }
	function api.open()
		Kit.recolor(tabs[state.tab].button, C.accent)
		local keys = keysFor(state.tab)
		list:show(keys, true)
		local tabButtons = {}
		for _, name in TABS do
			table.insert(tabButtons, tabs[name].button)
		end
		table.insert(tabButtons, marker)
		Kit.open(window, {
			{ { plate, emblem }, "pop", gap = 0.04 },
			{ tabButtons, "pop", gap = 0.03 },
			{ list:shown(), "slide", from = "left", gap = 0.04 },
			{ sparkles, "pop", gap = 0.05 },
			{ close, "spin" },
		})
		state.selected = nil
		select(keys[1], 0.4) -- the pane is part of the shell; its content waits for the rows
		Kit.bob(emblem, 3, 2.6, 1.5)
	end
	function api.close()
		Kit.still(emblem)
		Kit.close(window, { first = close })
	end
	api.select, api.setTab, api.claim = select, setTab, claim
	Kit.press(close, api.close)
	return api
end

-- the tour: every motion once, about 14 s, then again
function Demo.run(playerGui: Instance?)
	local target = playerGui or Players.LocalPlayer:WaitForChild("PlayerGui")
	local ui = Demo.build(target)
	local function tap(button: GuiObject, fn: () -> ())
		Kit.squash(button)
		task.wait(Kit.TIMES.press)
		fn()
	end
	task.spawn(function()
		while ui.gui.Parent do
			task.wait(1)
			ui.open()
			task.wait(1.8)
			tap(ui.rows.d2.row, function()
				ui.select("d2")
			end)
			task.wait(1)
			tap(ui.rows.w2.row, function()
				ui.select("w2")
			end)
			task.wait(1)
			tap(ui.tabs.Daily.button, function()
				ui.setTab("Daily")
			end)
			task.wait(1.3)
			tap(ui.main, function()
				ui.claim("d1")
			end)
			task.wait(2.4)
			tap(ui.tabs.Weekly.button, function()
				ui.setTab("Weekly")
			end)
			task.wait(1.3)
			tap(ui.main, function()
				ui.claim("w1")
			end)
			task.wait(3)
			tap(ui.closeButton, ui.close)
			task.wait(1.2)
			ui.gui:Destroy()
			ui = Demo.build(target)
		end
	end)
	return ui
end

return Demo
