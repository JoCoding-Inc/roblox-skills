-- Device sweep: checks the game's UI in the real Device Simulator viewport of each device in DEVICES
-- (roblox-ui-layout section 6, roblox-ui-mobile section 1). It draws nothing. For each device it
-- switches the simulator, reads AbsolutePosition and AbsoluteSize of the live UI, and returns:
--   screen and safe-frame size, HUD coverage of the screen and of the centre 50% x 50% box,
--   buttons inside Roblox's reserved zones (jump button, thumbstick, hotbar, chat, player list),
--   (the chat zone is the live chat window when it has been opened, else its measured default box),
--   buttons under 44 px on touch, text under 14 px (12 px for bold text with a stroke or on an opaque plate),
--   painted elements outside the safe frame, backdrops that stop short of the screen edge, buttons and
--   text of a full-screen ScreenGui under a notch, buttons and text of different ScreenGuis that sit
--   on top of each other, and the phone HUD budgets (section 2).
-- Skipped: an element with nothing drawn on the screen (a slid-out HUD layer; the engine cuts a ScreenGui's
-- content at the device safe area unless its ScreenInsets is None), named in one note; a painted
-- full-size backdrop (a panel's dim) is left out of the coverage numbers.
-- SweepIgnore = true on an element: it and its children leave every check. Only for Studio-only debug UI.
-- KitRole = "target" on a clicker's centre tap target: it leaves the centre-box number, not the coverage.
-- Attributes it reads: PassThrough = true on a button (roblox-ui-mobile section 3), and
-- KitTransient = true on a short-lived effect, toast or pop-up play target (the name the RoDesigner
-- kit lint reads): the marked element and its children leave the coverage, overlap and safe-frame
-- checks; a marked button is still checked against the reserved zones and the 44 px floor.
-- Run with Studio MCP execute_luau:
--   Play, datamodel Client: checks PlayerGui (UI that scripts build, real touch controls). Preferred.
--   Edit: checks StarterGui only; touch zones come from the formulas below, and the safe frame is
--   58 px taller than in Play because Edit draws no top bar.
-- Run it at idle with every panel closed for the HUD budgets, then again with each panel open.
-- The simulated device is shared by every Studio window on the machine: the sweep puts the first
-- device back when it ends. Tested 2026-11-12 in Studio 0.747 (Play and Edit); the off-screen skip, the
-- device cut, the backdrop rule and the marks were tested in Play on the Studio viewport and on the Galaxy
-- A06 preset; a game session ran the off-screen skip and the backdrop rule on iPhone 17 Pro, iPad 10th
-- Generation and HD 1080 as well.
local DEVICES = { -- display names of Studio presets; an unknown name is reported, not guessed
	"Samsung Galaxy A06", -- 800x360, safe 705x280: smallest common phone frame
	"iPhone 17 Pro", -- 874x402, safe 750x323: Dynamic Island insets
	"Amazon Fire HD 10 (2023)", -- 960x600: small tablet, large touch controls
	"iPad 10th Generation", -- 1180x820: tablet, Medium display size
	"Average Windows", -- 1366x768 laptop
	"HD 1080", -- 1920x1080 desktop
}
local MIN_TARGET, MIN_TEXT, MIN_HUD_TEXT = 44, 14, 12 -- HUD text may go to 12 px when bold, with a stroke or on a plate
local PLATE_MAX_TRANSPARENCY = 0.25 -- a background or image this opaque or more counts as a plate (judgment)
local CELL = 4 -- px per raster cell for the coverage numbers
local SETTLE = 1 -- seconds to wait after a device switch (scripts re-layout, touch controls resize)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local svc = game:GetService("StudioDeviceSimulatorService")

local playing = RunService:IsRunning() and Players.LocalPlayer ~= nil
local root: Instance = if playing then Players.LocalPlayer:WaitForChild("PlayerGui") else StarterGui

local ids = {}
for _, id in svc:GetDeviceListAsync() do
	ids[svc:GetDeviceInfoAsync(id).Name] = id
end
local okBefore, before = pcall(function()
	return svc:GetDeviceAsync()
end)

local function probe(name: string, insets: Enum.ScreenInsets): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ScreenInsets = insets
	g.ResetOnSpawn = false
	g.Parent = root
	return g
end
local safeProbe = probe("UiSweepSafe", Enum.ScreenInsets.CoreUISafeInsets)
local fullProbe = probe("UiSweepFull", Enum.ScreenInsets.None)
local deviceProbe = probe("UiSweepDevice", Enum.ScreenInsets.DeviceSafeInsets)

local function shown(o: Instance): boolean
	local p: Instance? = o
	while p and p ~= root do
		if p:IsA("GuiObject") and not p.Visible then
			return false
		elseif p:IsA("ScreenGui") and not p.Enabled then
			return false
		end
		p = p.Parent
	end
	return true
end

-- the part of an element that is drawn: its rect cut by every clipping ancestor
local function clipped(o: GuiObject): (number, number, number, number)
	local x0, y0 = o.AbsolutePosition.X, o.AbsolutePosition.Y
	local x1, y1 = x0 + o.AbsoluteSize.X, y0 + o.AbsoluteSize.Y
	local p = o.Parent
	while p and p ~= root do
		if p:IsA("GuiObject") and p.ClipsDescendants then
			local px, py = p.AbsolutePosition.X, p.AbsolutePosition.Y
			x0, y0 = math.max(x0, px), math.max(y0, py)
			x1, y1 = math.min(x1, px + p.AbsoluteSize.X), math.min(y1, py + p.AbsoluteSize.Y)
		end
		p = p.Parent
	end
	return x0, y0, x1, y1
end

local function uiScale(o: Instance): number
	local s = 1
	local p: Instance? = o
	while p and p ~= root do
		local u = p:FindFirstChildOfClass("UIScale")
		if u then
			s *= u.Scale
		end
		p = p.Parent
	end
	return s
end

local function transient(o: Instance): boolean
	local p: Instance? = o
	while p and p ~= root do
		if p:GetAttribute("KitTransient") == true then
			return true
		end
		p = p.Parent
	end
	return false
end

-- KitRole = "target" (the RoDesigner kit lint's mark for a clicker's centre tap target), on the element or an ancestor
local function playTarget(o: Instance): boolean
	local p: Instance? = o
	while p and p ~= root do
		if p:GetAttribute("KitRole") == "target" then
			return true
		end
		p = p.Parent
	end
	return false
end

local function ignored(o: Instance): boolean
	local p: Instance? = o
	while p and p ~= root do
		if p:GetAttribute("SweepIgnore") == true then
			return true
		end
		p = p.Parent
	end
	return false
end

-- display families with one weight that is drawn heavy: their FontFace.Weight reads Regular
local HEAVY = { FredokaOne = true, LuckiestGuy = true, Bangers = true }

-- an opaque layer behind the label: its own background, or the background or image of an ancestor that holds its centre
local function onPlate(o: GuiObject): boolean
	local cx, cy = o.AbsolutePosition.X + o.AbsoluteSize.X / 2, o.AbsolutePosition.Y + o.AbsoluteSize.Y / 2
	local p: Instance? = o
	while p and p ~= root do
		if p:IsA("GuiObject") then
			local px, py = p.AbsolutePosition.X, p.AbsolutePosition.Y
			if cx >= px and cy >= py and cx <= px + p.AbsoluteSize.X and cy <= py + p.AbsoluteSize.Y then
				if p.BackgroundTransparency <= PLATE_MAX_TRANSPARENCY then
					return true
				end
				if (p:IsA("ImageLabel") or p:IsA("ImageButton")) and (p :: any).Image ~= "" and (p :: any).ImageTransparency <= PLATE_MAX_TRANSPARENCY then
					return true
				end
			end
		end
		p = p.Parent
	end
	return false
end

-- the 12 px floor: weight makes text this small legible, a stroke or a plate gives it contrast (roblox-ui-layout section 4)
local function smallTextOk(o: any): boolean
	local face = o.FontFace
	local family = string.match(face.Family, "([%w_]+)%.json$")
	local heavy = face.Weight.Value >= Enum.FontWeight.Bold.Value or (family ~= nil and HEAVY[family] == true)
	if not heavy then
		return false
	end
	local st = o:FindFirstChildOfClass("UIStroke")
	local stroked = (st ~= nil and st.Enabled and st.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual)
		or o.TextStrokeTransparency < 1
	return stroked or onPlate(o)
end

local function isText(o: Instance): boolean
	return (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) and (o :: any).Text ~= "" and (o :: any).TextTransparency < 1
end

local function coreGui(kind: Enum.CoreGuiType): boolean
	local ok, on = pcall(function()
		return StarterGui:GetCoreGuiEnabled(kind)
	end)
	return not ok or on
end

local function hasTools(): boolean
	if game:GetService("StarterPack"):FindFirstChildOfClass("Tool") then
		return true
	end
	local backpack = playing and Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	return backpack ~= nil and backpack ~= false and backpack:FindFirstChildOfClass("Tool") ~= nil
end

local function check(name: string): string
	local id = ids[name]
	if not id then
		return name .. ": no Studio preset with this name"
	end
	svc:SetDeviceAsync(id)
	task.wait(SETTLE)
	local info = svc:GetDeviceInfoAsync(id)
	local W, H = safeProbe.AbsoluteSize.X, safeProbe.AbsoluteSize.Y -- CoreUI-safe frame; its origin is (0, 0)
	local fx, fy = fullProbe.AbsolutePosition.X, fullProbe.AbsolutePosition.Y -- screen corner, in safe-frame px
	local FW, FH = fullProbe.AbsoluteSize.X, fullProbe.AbsoluteSize.Y
	-- device-safe area (clear of notches; the top bar is inside it), in safe-frame px
	local dx0, dy0 = deviceProbe.AbsolutePosition.X, deviceProbe.AbsolutePosition.Y
	local dx1, dy1 = dx0 + deviceProbe.AbsoluteSize.X, dy0 + deviceProbe.AbsoluteSize.Y
	local touch = if playing then UserInputService.PreferredInput == Enum.PreferredInput.Touch else info.LandscapeKeyboardHeight > 0
	local large = math.min(W, H) > 500 -- the engine's touch-control breakpoint
	local phone = touch and not large

	-- reserved zones in safe-frame px: { name, x0, y0, x1, y1, severity, true for a thumbstick zone }
	local zones = {}
	local function zone(n: string, x0: number, y0: number, x1: number, y1: number, sev: string, stick: boolean?)
		table.insert(zones, { n, x0, y0, x1, y1, sev, stick })
	end
	local sx0, sy0, sx1, sy1 = 0, 0, 0, 0 -- thumbstick start area
	if touch then
		local jump = playing and root:FindFirstChild("JumpButton", true)
		if jump and jump:IsA("GuiObject") and shown(jump) then
			zone("the jump button keep box", jump.AbsolutePosition.X, jump.AbsolutePosition.Y, W, H, "error")
		elseif not playing then
			zone("the jump button keep box", W - (large and 170 or 95), H - (large and 210 or 90), W, H, "error")
		end
		if playing and not GuiService.TouchControlsEnabled then
			touch = false -- the game hid the touch controls (a panel is open): no stick or jump zone now
		else
			if H > W then
				sx0, sy0, sx1, sy1 = 0, 0.6 * H, W, H
			else
				sx0, sy0, sx1, sy1 = 0, H / 3, 0.4 * W, H
			end
			zone("the resting thumbstick ring (keep it clear; last resort only)", 0, H - (large and 195 or 100), large and 215 or 110, H, "warn", true)
		end
	end
	if hasTools() and coreGui(Enum.CoreGuiType.Backpack) then
		local hw = (touch and W < 1024) and 200 or 655
		zone("the hotbar", W / 2 - hw / 2, H - 110, W / 2 + hw / 2, H, "warn")
	end
	if not touch and not phone then
		local win = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if coreGui(Enum.CoreGuiType.Chat) and not (win and not win.Enabled) then
			-- default chat window, measured (section 1): 8 px in, 12 px under the top bar, min(0.4 W, 475) wide,
			-- a message list 0.25 H tall and a 45 px input bar under it
			local cx0, cy0, cx1, cy1 = 8, 12, 8 + math.min(0.4 * W, 475), 12 + 0.25 * H + 45
			local label = "the chat window"
			if playing and win then
				if win.AbsoluteSize.X > 0 then -- the live window, once it has been opened (it keeps its last size after closing)
					cx0, cy0 = win.AbsolutePosition.X, win.AbsolutePosition.Y
					cx1, cy1 = cx0 + win.AbsoluteSize.X, cy0 + win.AbsoluteSize.Y
					local bar = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
					if bar and bar.Enabled and bar.AbsoluteSize.X > 0 then
						cx0, cy0 = math.min(cx0, bar.AbsolutePosition.X), math.min(cy0, bar.AbsolutePosition.Y)
						cx1 = math.max(cx1, bar.AbsolutePosition.X + bar.AbsoluteSize.X)
						cy1 = math.max(cy1, bar.AbsolutePosition.Y + bar.AbsoluteSize.Y)
					end
				end
				local ok, active = pcall(function()
					return StarterGui:GetCore("ChatActive")
				end)
				if ok and active == false then
					label = "the chat window (closed now; this is where it opens)"
				end
			end
			zone(label, cx0, cy0, cx1, cy1, "warn")
		end
		if coreGui(Enum.CoreGuiType.PlayerList) then
			zone("the player list (approx)", W - 214, 4, W - 4, 0.5 * H, "warn")
		end
	end

	-- raster of the whole screen: 1 = painted game UI, 2 = button
	local cols, rows = math.ceil(FW / CELL), math.ceil(FH / CELL)
	local painted = table.create(cols * rows, false)
	local paintedCentre = table.create(cols * rows, false) -- the same without play targets: what the centre box counts
	local buttonCells = table.create(cols * rows, false)
	local function mark(grid, x0: number, y0: number, x1: number, y1: number)
		local c0, c1 = math.max(0, math.floor((x0 - fx) / CELL)), math.min(cols - 1, math.ceil((x1 - fx) / CELL) - 1)
		local r0, r1 = math.max(0, math.floor((y0 - fy) / CELL)), math.min(rows - 1, math.ceil((y1 - fy) / CELL) - 1)
		for r = r0, r1 do
			for c = c0, c1 do
				grid[r * cols + c + 1] = true
			end
		end
	end

	local problems = {}
	local buttons = 0
	local crossing = {}
	local outside, across = {}, {} -- paths outside the safe frame, and crossing its edge
	local off, offTop, offList = {}, {}, {} -- elements wholly off the screen (slid-out layers): skipped, named once by their top ancestor
	local leaves = {} -- buttons and text: { gui, DisplayOrder, path, x0, y0, x1, y1 }
	local scrim: string? = nil -- a backdrop over the whole screen or the whole of its ScreenGui (a modal is open)
	local scrimOrder = -math.huge
	for _, gui in root:GetChildren() do
		if not gui:IsA("ScreenGui") or not gui.Enabled or gui == safeProbe or gui == fullProbe or gui == deviceProbe or gui.Name == "TouchGui" then
			continue
		end
		local inSafe = gui.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets
		-- the engine cuts a ScreenGui's content at the device safe area unless its ScreenInsets is None (docs)
		local clipDevice = gui.ClipToDeviceSafeArea and gui.ScreenInsets ~= Enum.ScreenInsets.None
		local gx0, gy0 = gui.AbsolutePosition.X, gui.AbsolutePosition.Y
		local gx1, gy1 = gx0 + gui.AbsoluteSize.X, gy0 + gui.AbsoluteSize.Y
		for _, o in gui:GetDescendants() do
			if not o:IsA("GuiObject") or not shown(o) or ignored(o) then
				continue
			end
			local x0, y0, x1, y1 = clipped(o)
			if x1 <= x0 or y1 <= y0 then
				continue
			end
			local rx0, ry0, rx1, ry1 = x0, y0, x1, y1 -- before the device cut: where the layout put it
			if clipDevice then
				x0, y0, x1, y1 = math.max(x0, dx0), math.max(y0, dy0), math.min(x1, dx1), math.min(y1, dy1)
			end
			if x1 <= x0 or y1 <= y0 or x1 <= fx or y1 <= fy or x0 >= fx + FW or y0 >= fy + FH then
				-- nothing of it is drawn (a HUD layer slid off, a panel parked outside, in the notch strip or past the
				-- screen edge): not a button, not text, not painted
				off[o] = true
				if o:IsA("GuiButton") or o.BackgroundTransparency < 1 or isText(o) or ((o:IsA("ImageLabel") or o:IsA("ImageButton")) and (o :: any).Image ~= "") then
					local top: Instance = o
					while top.Parent and off[top.Parent] do
						top = top.Parent
					end
					if not offTop[top] then
						offTop[top] = true
						table.insert(offList, (top:GetFullName():gsub("^.-Gui%.", "", 1)))
					end
				end
				continue
			end
			local path = o:GetFullName():gsub("^.-Gui%.", "", 1)
			local size = o.AbsoluteSize
			local hasBack = o.BackgroundTransparency < 1
			local hasImage = (o:IsA("ImageLabel") or o:IsA("ImageButton")) and (o :: any).Image ~= "" and (o :: any).ImageTransparency < 1
			local text = isText(o)
			local brief = transient(o)
			local target = playTarget(o)
			local lx0, ly0, lx1, ly1 = x0, y0, x1, y1 -- the rect that counts for overlaps
			-- backdrops: a layer over the whole screen is a scrim; one that fills an inset ScreenGui stops short of it
			local wholeScreen = (x1 - x0) * (y1 - y0) >= 0.95 * FW * FH
			local wholeGui = x0 <= gx0 + 1 and y0 <= gy0 + 1 and x1 >= gx1 - 1 and y1 >= gy1 - 1
			local backdrop = wholeScreen or wholeGui -- also a see-through tap catcher of that size
			if hasBack or hasImage then
				if not brief and not (backdrop and hasBack) then -- a painted backdrop is not HUD: the coverage numbers show what sits on it
					mark(painted, x0, y0, x1, y1)
					if not target then
						mark(paintedCentre, x0, y0, x1, y1)
					end
				end
			elseif text then -- text with no plate: count its bounds, placed by its alignment
				local t = o :: any
				local bw, bh = math.min(t.TextBounds.X, x1 - x0), math.min(t.TextBounds.Y, y1 - y0)
				local ax = if t.TextXAlignment == Enum.TextXAlignment.Left then 0 elseif t.TextXAlignment == Enum.TextXAlignment.Right then 1 else 0.5
				local ay = if t.TextYAlignment == Enum.TextYAlignment.Top then 0 elseif t.TextYAlignment == Enum.TextYAlignment.Bottom then 1 else 0.5
				local tx, ty = x0 + (x1 - x0 - bw) * ax, y0 + (y1 - y0 - bh) * ay
				lx0, ly0, lx1, ly1 = tx, ty, tx + bw, ty + bh
				if not brief then
					mark(painted, lx0, ly0, lx1, ly1)
					if not target then
						mark(paintedCentre, lx0, ly0, lx1, ly1)
					end
				end
			end

			if hasBack and not brief and backdrop then
				if gui.DisplayOrder >= scrimOrder then
					scrim, scrimOrder = path, gui.DisplayOrder
				end
				if not wholeScreen and (gx1 - gx0) * (gy1 - gy0) < 0.98 * FW * FH then
					table.insert(problems, string.format("warn: backdrop %s fills a %s ScreenGui and stops short of the screen edge (left %d, top %d, right %d, bottom %d px); put full-screen layers in a ScreenGui with ScreenInsets None",
						path, gui.ScreenInsets.Name, gx0 - fx, gy0 - fy, fx + FW - gx1, fy + FH - gy1))
				end
			end

			-- a pass-through button (roblox-ui-mobile section 3) lets the stick start, so it is no stick blocker
			local pass = o:GetAttribute("PassThrough") == true
			local isButton = o:IsA("GuiButton") and o.Interactable and (o.Active or pass)
			if isButton and backdrop then
				-- a tap catcher behind a panel is no HUD button, but it does stop the stick while it is up
				mark(buttonCells, x0, y0, x1, y1)
				isButton = false
				text = false
			end
			if isButton then
				-- a button drawn inside a bigger button (a small X in a 44 px hit area) is one target: the outer one
				local outer = o:FindFirstAncestorWhichIsA("GuiButton")
				local nested = outer ~= nil and outer.Interactable and outer.Active
				if not nested then
					buttons += 1
				end
				if not pass then
					mark(buttonCells, x0, y0, x1, y1)
				end
				for _, z in zones do
					if not (pass and z[7]) and x0 < z[4] and x1 > z[2] and y0 < z[5] and y1 > z[3] then
						table.insert(problems, string.format("%s: button %s is inside %s", z[6], path, z[1]))
					end
				end
				if touch and not nested and math.min(size.X, size.Y) < MIN_TARGET then
					table.insert(problems, string.format("warn: button %s is %dx%d px, under %d", path, size.X, size.Y, MIN_TARGET))
				end
			end
			if (isButton or text) and not brief then
				table.insert(leaves, { gui, gui.DisplayOrder, path, lx0, ly0, lx1, ly1 })
				if gui.ScreenInsets == Enum.ScreenInsets.None and (lx0 < dx0 - 1 or ly0 < dy0 - 1 or lx1 > dx1 + 1 or ly1 > dy1 + 1) then
					table.insert(problems, string.format("warn: %s is in a ScreenInsets None ScreenGui and reaches outside the device safe area (a notch or rounded corner can cover it)", path))
				end
			end
			if text then
				local t = o :: any
				local px = if t.TextScaled then t.TextBounds.Y else t.TextSize * uiScale(o)
				local floor = smallTextOk(o) and MIN_HUD_TEXT or MIN_TEXT
				if px < floor - 0.5 then
					table.insert(problems, string.format("warn: text %s is about %d px, under %d", path, px, floor))
				end
			end
			if inSafe and not brief and (hasBack or hasImage or text) and not crossing[o.Parent] then
				if rx1 < 0 or ry1 < 0 or rx0 > W or ry0 > H then
					crossing[o] = true
					table.insert(outside, path)
				elseif rx0 < -1 or ry0 < -1 or rx1 > W + 1 or ry1 > H + 1 then
					crossing[o] = true
					table.insert(across, path)
				end
			elseif crossing[o.Parent] then
				crossing[o] = true
			end
		end
	end
	for _, group in { { outside, "outside the safe frame" }, { across, "across the safe-frame edge" } } do
		local list = group[1] :: { string }
		if #list > 0 then
			table.insert(problems, string.format("warn: %d element%s %s: %s%s", #list, #list == 1 and "" or "s", group[2] :: string,
				table.concat(list, ", ", 1, math.min(#list, 3)), #list > 3 and ", ..." or ""))
		end
	end

	if #offList > 0 then
		table.insert(problems, string.format("note: %d element%s with nothing drawn on the screen %s skipped (slid out or parked): %s%s", #offList, #offList == 1 and "" or "s",
			#offList == 1 and "was" or "were", table.concat(offList, ", ", 1, math.min(#offList, 3)), #offList > 3 and ", ..." or ""))
	end

	-- buttons and text of two different ScreenGuis on top of each other (a quarter of the smaller one or more).
	-- Layers under a scrim are covered on purpose and are skipped.
	local overlaps = 0
	for i = 1, #leaves do
		local a = leaves[i]
		for j = i + 1, #leaves do
			local b = leaves[j]
			if a[1] ~= b[1] and (not scrim or (a[2] >= scrimOrder and b[2] >= scrimOrder)) then
				local w = math.min(a[6], b[6]) - math.max(a[4], b[4])
				local h = math.min(a[7], b[7]) - math.max(a[5], b[5])
				local small = math.min((a[6] - a[4]) * (a[7] - a[5]), (b[6] - b[4]) * (b[7] - b[5]))
				if w > 0 and h > 0 and small > 0 and w * h >= 0.25 * small then
					overlaps += 1
					if overlaps <= 6 then
						table.insert(problems, string.format("warn: %s (ScreenGui %s) and %s (ScreenGui %s) overlap by %dx%d px", a[3], a[1].Name, b[3], b[1].Name, w, h))
					end
				end
			end
		end
	end
	if overlaps > 6 then
		table.insert(problems, string.format("warn: %d more overlaps between ScreenGuis", overlaps - 6))
	end
	if scrim then -- a modal covers the chat window and the player list on purpose
		for i = #problems, 1, -1 do
			if string.find(problems[i], "the chat window", 1, true) or string.find(problems[i], "the player list", 1, true) then
				table.remove(problems, i)
			end
		end
		table.insert(problems, string.format("note: %s is a full-size backdrop (a panel is open): the HUD budgets are skipped and the coverage numbers leave the backdrop out", scrim))
	end

	-- coverage: whole screen, the centre 50% x 50% box, and buttons inside the thumbstick start area
	local all, centre, centreAll, startAll, startButtons = 0, 0, 0, 0, 0
	for r = 0, rows - 1 do
		local y = fy + (r + 0.5) * CELL
		for c = 0, cols - 1 do
			local x = fx + (c + 0.5) * CELL
			local i = r * cols + c + 1
			if painted[i] then
				all += 1
			end
			if c >= cols / 4 and c < cols * 3 / 4 and r >= rows / 4 and r < rows * 3 / 4 then
				centreAll += 1
				if paintedCentre[i] then
					centre += 1
				end
			end
			if x >= sx0 and x < sx1 and y >= sy0 and y < sy1 then
				startAll += 1
				if buttonCells[i] then
					startButtons += 1
				end
			end
		end
	end
	local hud, mid = 100 * all / (cols * rows), 100 * centre / math.max(centreAll, 1)
	local stick = if startAll > 0 and not scrim then 100 * startButtons / startAll else 0
	if stick > 0 then
		table.insert(problems, string.format("%s: buttons cover %.0f%% of the thumbstick start area, where a touch on a button cannot start the stick (roblox-ui-layout section 1: warn over 17%%, error over 33%%)",
			if stick > 33 then "error" elseif stick > 17 then "warn" else "note", stick))
	end
	if phone and not scrim then -- phone HUD budgets (roblox-ui-layout section 2); they assume idle play with panels closed
		if hud > 16 then
			table.insert(problems, string.format("%s: HUD covers %.1f%% of the screen (target 11, warn over 16, fail over 20)", hud > 20 and "error" or "warn", hud))
		end
		if mid > 2 then
			table.insert(problems, string.format("%s: UI covers %.1f%% of the centre box (target 0, warn over 2, fail over 10)", mid > 10 and "error" or "warn", mid))
		end
		if buttons > 9 then
			table.insert(problems, string.format("%s: %d visible buttons (target 5, warn over 9, fail over 12)", buttons > 12 and "error" or "warn", buttons))
		end
	end
	table.sort(problems)
	return string.format("%s: screen %dx%d, safe frame %dx%d, %s, %s, %s %.1f%% of the screen, centre box %.1f%%, %d buttons\n  %s",
		name, FW, FH, W, H, GuiService.ViewportDisplaySize.Name,
		if touch then (large and "large touch controls" or "small touch controls") else "no touch controls",
		if scrim then "panel open (HUD budgets not applied): UI" else "HUD", hud, mid, buttons,
		#problems == 0 and "no problems" or table.concat(problems, "\n  "))
end

local out = {
	if playing
		then "PlayerGui (Play)"
		else "StarterGui only (Edit): UI built by scripts is not checked, and Edit draws no top bar, so the safe frame is 58 px taller than players get. Final numbers come from a Play run.",
}
for _, name in DEVICES do
	local ok, res = pcall(check, name)
	table.insert(out, if ok then res else name .. ": " .. tostring(res))
end
safeProbe:Destroy()
fullProbe:Destroy()
deviceProbe:Destroy()
if okBefore and before and before ~= "" then
	pcall(function()
		svc:SetDeviceAsync(before)
	end)
end
return table.concat(out, "\n")
