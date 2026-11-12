-- Device sweep: checks the game's UI in the real Device Simulator viewport of each device in DEVICES
-- (roblox-ui-layout section 6, roblox-ui-mobile section 1). It draws nothing. For each device it
-- switches the simulator, reads AbsolutePosition and AbsoluteSize of the live UI, and returns:
--   screen and safe-frame size, HUD coverage of the screen and of the centre 50% x 50% box,
--   buttons inside Roblox's reserved zones (jump button, thumbstick, hotbar, chat, player list),
--   buttons under 44 px on touch, text under 14 px (12 px for bold, stroked text),
--   painted elements outside the safe frame, and the phone HUD budgets (section 2).
-- Run with Studio MCP execute_luau:
--   Play, datamodel Client: checks PlayerGui (UI that scripts build, real touch controls). Preferred.
--   Edit: checks StarterGui only; touch zones come from the formulas below, and the safe frame is
--   58 px taller than in Play because Edit draws no top bar.
-- Run it at idle with every panel closed for the HUD budgets, then again with each panel open.
-- The simulated device is shared by every Studio window on the machine: the sweep puts the first
-- device back when it ends. Tested 2026-11-12 in Studio 0.747 (Play and Edit).
local DEVICES = { -- display names of Studio presets; an unknown name is reported, not guessed
	"Samsung Galaxy A06", -- 800x360, safe 705x280: smallest common phone frame
	"iPhone 17 Pro", -- 874x402, safe 750x323: Dynamic Island insets
	"Amazon Fire HD 10 (2023)", -- 960x600: small tablet, large touch controls
	"iPad 10th Generation", -- 1180x820: tablet, Medium display size
	"Average Windows", -- 1366x768 laptop
	"HD 1080", -- 1920x1080 desktop
}
local MIN_TARGET, MIN_TEXT, MIN_HUD_TEXT = 44, 14, 12 -- HUD text may go to 12 px when bold and stroked
local CELL = 4 -- px per raster cell for the coverage numbers
local SETTLE = 1 -- seconds to wait after a device switch (scripts re-layout, touch controls resize)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
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

local function boldStroked(o: any): boolean
	local st = o:FindFirstChildOfClass("UIStroke")
	local stroked = (st ~= nil and st.Enabled and st.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual)
		or o.TextStrokeTransparency < 1
	return stroked and o.FontFace.Weight.Value >= Enum.FontWeight.Bold.Value
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
	local touch = if playing then UserInputService.PreferredInput == Enum.PreferredInput.Touch else info.LandscapeKeyboardHeight > 0
	local large = math.min(W, H) > 500 -- the engine's touch-control breakpoint
	local phone = touch and not large

	-- reserved zones in safe-frame px: { name, x0, y0, x1, y1, severity }
	local zones = {}
	local function zone(n: string, x0: number, y0: number, x1: number, y1: number, sev: string)
		table.insert(zones, { n, x0, y0, x1, y1, sev })
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
			zone("the resting thumbstick ring (keep it clear; last resort only)", 0, H - (large and 195 or 100), large and 215 or 110, H, "warn")
		end
	end
	if hasTools() and coreGui(Enum.CoreGuiType.Backpack) then
		local hw = (touch and W < 1024) and 200 or 655
		zone("the hotbar", W / 2 - hw / 2, H - 110, W / 2 + hw / 2, H, "warn")
	end
	if not touch and not phone then
		if coreGui(Enum.CoreGuiType.Chat) then
			zone("the chat window (approx)", 0, 0, 0.3 * W, 0.25 * H + 24, "warn")
		end
		if coreGui(Enum.CoreGuiType.PlayerList) then
			zone("the player list (approx)", W - 214, 4, W - 4, 0.5 * H, "warn")
		end
	end

	-- raster of the whole screen: 1 = painted game UI, 2 = button
	local cols, rows = math.ceil(FW / CELL), math.ceil(FH / CELL)
	local painted = table.create(cols * rows, false)
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
	for _, gui in root:GetChildren() do
		if not gui:IsA("ScreenGui") or not gui.Enabled or gui == safeProbe or gui == fullProbe or gui.Name == "TouchGui" then
			continue
		end
		local inSafe = gui.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets
		for _, o in gui:GetDescendants() do
			if not o:IsA("GuiObject") or not shown(o) then
				continue
			end
			local x0, y0, x1, y1 = clipped(o)
			if x1 <= x0 or y1 <= y0 then
				continue
			end
			local path = o:GetFullName():gsub("^.-Gui%.", "", 1)
			local size = o.AbsoluteSize
			local hasBack = o.BackgroundTransparency < 1
			local hasImage = (o:IsA("ImageLabel") or o:IsA("ImageButton")) and (o :: any).Image ~= "" and (o :: any).ImageTransparency < 1
			local text = isText(o)
			if hasBack or hasImage then
				mark(painted, x0, y0, x1, y1)
			elseif text then -- text with no plate: count its bounds, placed by its alignment
				local t = o :: any
				local bw, bh = math.min(t.TextBounds.X, x1 - x0), math.min(t.TextBounds.Y, y1 - y0)
				local ax = if t.TextXAlignment == Enum.TextXAlignment.Left then 0 elseif t.TextXAlignment == Enum.TextXAlignment.Right then 1 else 0.5
				local ay = if t.TextYAlignment == Enum.TextYAlignment.Top then 0 elseif t.TextYAlignment == Enum.TextYAlignment.Bottom then 1 else 0.5
				local tx, ty = x0 + (x1 - x0 - bw) * ax, y0 + (y1 - y0 - bh) * ay
				mark(painted, tx, ty, tx + bw, ty + bh)
			end

			if o:IsA("GuiButton") and o.Active and o.Interactable then
				buttons += 1
				mark(buttonCells, x0, y0, x1, y1)
				for _, z in zones do
					if x0 < z[4] and x1 > z[2] and y0 < z[5] and y1 > z[3] then
						table.insert(problems, string.format("%s: button %s is inside %s", z[6], path, z[1]))
					end
				end
				if touch and math.min(size.X, size.Y) < MIN_TARGET then
					table.insert(problems, string.format("warn: button %s is %dx%d px, under %d", path, size.X, size.Y, MIN_TARGET))
				end
			end
			if text then
				local t = o :: any
				local px = if t.TextScaled then t.TextBounds.Y else t.TextSize * uiScale(o)
				local floor = boldStroked(o) and MIN_HUD_TEXT or MIN_TEXT
				if px < floor - 0.5 then
					table.insert(problems, string.format("warn: text %s is about %d px, under %d", path, px, floor))
				end
			end
			if inSafe and (hasBack or hasImage or text) and not crossing[o.Parent] then
				if x1 < 0 or y1 < 0 or x0 > W or y0 > H then
					crossing[o] = true
					table.insert(problems, string.format("warn: %s is outside the safe frame", path))
				elseif x0 < -1 or y0 < -1 or x1 > W + 1 or y1 > H + 1 then
					crossing[o] = true
					table.insert(problems, string.format("warn: %s crosses the safe-frame edge", path))
				end
			elseif crossing[o.Parent] then
				crossing[o] = true
			end
		end
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
				if painted[i] then
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
	local stick = if startAll > 0 then 100 * startButtons / startAll else 0
	if stick > 0 then
		table.insert(problems, string.format("%s: buttons cover %.0f%% of the thumbstick start area, where a touch on a button cannot start the stick (roblox-ui-layout section 1: warn over 17%%, error over 33%%)",
			if stick > 33 then "error" elseif stick > 17 then "warn" else "note", stick))
	end
	if phone then -- phone HUD budgets (roblox-ui-layout section 2); they assume idle play with panels closed
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
	return string.format("%s: screen %dx%d, safe frame %dx%d, %s, %s, HUD %.1f%% of the screen, centre box %.1f%%, %d buttons\n  %s",
		name, FW, FH, W, H, GuiService.ViewportDisplaySize.Name,
		if touch then (large and "large touch controls" or "small touch controls") else "no touch controls", hud, mid, buttons,
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
if okBefore and before and before ~= "" then
	pcall(function()
		svc:SetDeviceAsync(before)
	end)
end
return table.concat(out, "\n")
