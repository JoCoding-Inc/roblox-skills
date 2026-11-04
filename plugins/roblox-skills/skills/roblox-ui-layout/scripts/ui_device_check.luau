-- Preview the game's UI at one device size inside Studio and check it against Roblox's reserved
-- zones (roblox-ui-layout section 1). It copies every ScreenGui in StarterGui into a frame the
-- size of that device's CoreUI-safe area (below the top bar, inside the notch insets), draws the
-- reserved zones in red, and returns problems: buttons inside a zone, buttons under 44 px on touch
-- devices, text under 14 px, elements outside the safe area.
-- Use: set DEVICE, run with Studio MCP execute_luau (Edit), screen_capture, repeat per device,
-- then delete StarterGui.UiDeviceCheck. UI that LocalScripts build at runtime is not in StarterGui:
-- run once in Play, copy PlayerGui's ScreenGuis into StarterGui of a scratch copy, then check.
local DEVICE = "phone" -- phone, phone_notch, phone_portrait, tablet, desktop, console

-- full screen size in Roblox UI px and insets (top includes the 58 px top bar)
local DEVICES = {
	phone = { w = 667, h = 375, l = 0, r = 0, t = 58, b = 0, touch = true }, -- small, no notch
	phone_notch = { w = 851, h = 392, l = 59, r = 59, t = 58, b = 21, touch = true }, -- docs GetInsetArea sample
	phone_portrait = { w = 375, h = 667, l = 0, r = 0, t = 58, b = 0, touch = true, portrait = true },
	tablet = { w = 1024, h = 768, l = 0, r = 0, t = 58, b = 0, touch = true },
	desktop = { w = 1920, h = 1080, l = 0, r = 0, t = 58, b = 0 },
	console = { w = 1920, h = 1080, l = 0, r = 0, t = 87, b = 0, tv = true }, -- 58 x 1.5 ten-foot bar
}
local MIN_TARGET, MIN_TEXT = 44, 14

local d = DEVICES[DEVICE]
local W, H = d.w - d.l - d.r, d.h - d.t - d.b -- CoreUI-safe frame
local small = math.min(W, H) <= 500 -- the engine's touch-control breakpoint

local SG = game:GetService("StarterGui")
local old = SG:FindFirstChild("UiDeviceCheck")
if old then
	old:Destroy()
end
local cam = workspace.CurrentCamera.ViewportSize
local fit = math.min(1, (cam.X - 20) / d.w, (cam.Y - 20) / d.h)

local gui = Instance.new("ScreenGui")
gui.Name = "UiDeviceCheck"
gui.ScreenInsets = Enum.ScreenInsets.None
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
backdrop.Parent = gui
local screen = Instance.new("Frame") -- the whole device screen
screen.Size = UDim2.fromOffset(d.w, d.h)
screen.Position = UDim2.fromOffset(10, 10)
screen.BackgroundColor3 = Color3.fromRGB(120, 150, 170)
screen.ClipsDescendants = true
screen.Parent = backdrop
local scale = Instance.new("UIScale")
scale.Scale = fit
scale.Parent = screen
local bar = Instance.new("Frame") -- Roblox top bar strip
bar.Size = UDim2.fromOffset(d.w, d.t)
bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
bar.BackgroundTransparency = 0.3
bar.ZIndex = 50
bar.Parent = screen
local safe = Instance.new("Frame") -- CoreUI-safe area: default ScreenGuis live here
safe.Name = "Safe"
safe.Size = UDim2.fromOffset(W, H)
safe.Position = UDim2.fromOffset(d.l, d.t)
safe.BackgroundTransparency = 1
safe.Parent = screen

-- reserved zones in safe-frame px: { name, x0, y0, x1, y1, severity }
local zones = {}
local function zone(name, x0, y0, x1, y1, sev)
	table.insert(zones, { name, x0, y0, x1, y1, sev })
end
if d.touch then
	if small then
		zone("thumbstick ring", 0, H - 100, 110, H, "error")
		zone("jump button", W - 95, H - 90, W, H, "error")
	else
		zone("thumbstick ring", 0, H - 195, 215, H, "error")
		zone("jump button", W - 170, H - 210, W, H, "error")
	end
	local hw = (W < 1024) and 200 or 655
	zone("hotbar (only with Tools)", W / 2 - hw / 2, H - 110, W / 2 + hw / 2, H, "warn")
else
	local hw = d.tv and 1055 or 655
	local hh = d.tv and 150 or 110
	zone("hotbar (only with Tools)", W / 2 - hw / 2, H - hh, W / 2 + hw / 2, H, "warn")
end
if DEVICE == "desktop" then
	zone("chat window (approx)", 0, 0, 0.3 * W, 0.25 * H + 24, "warn")
	zone("player list (approx)", W - 214, 4, W - 4, 0.5 * H, "warn")
end
if d.tv then -- 5 percent TV-safe border of the full screen
	local bx, by = 0.05 * d.w, 0.05 * d.h
	zone("TV-safe left", -d.l, -d.t, bx - d.l, d.h, "error")
	zone("TV-safe right", d.w - bx - d.l, -d.t, d.w, d.h, "error")
	zone("TV-safe bottom", -d.l, d.h - by - d.t, d.w, d.h, "error")
end
for _, z in zones do
	local f = Instance.new("Frame")
	f.Name = "Zone: " .. z[1]
	f.Position = UDim2.fromOffset(z[2], z[3])
	f.Size = UDim2.fromOffset(z[4] - z[2], z[5] - z[3])
	f.BackgroundColor3 = z[6] == "error" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 170, 0)
	f.BackgroundTransparency = 0.6
	f.ZIndex = 60
	f.Parent = safe
end
if d.touch then -- dynamic thumbstick start area (outline only: info may sit here, buttons should not)
	local f = Instance.new("Frame")
	f.Name = "Zone outline: thumbstick start area"
	if d.portrait then
		f.Position, f.Size = UDim2.fromOffset(0, 0.6 * H), UDim2.fromOffset(W, 0.4 * H)
	else
		f.Position, f.Size = UDim2.fromOffset(0, H / 3), UDim2.fromOffset(0.4 * W, 2 * H / 3)
	end
	f.BackgroundTransparency = 1
	f.ZIndex = 60
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 0, 0)
	s.Thickness = 2
	s.Parent = f
	f.Parent = safe
end

-- copy the game's ScreenGuis into the safe frame, in DisplayOrder
local guis = {}
for _, g in SG:GetChildren() do
	if g:IsA("ScreenGui") and g ~= gui and g.Enabled then
		table.insert(guis, g)
	end
end
table.sort(guis, function(a, b)
	return a.DisplayOrder < b.DisplayOrder
end)
for i, g in guis do
	local holder = Instance.new("Frame")
	holder.Name = g.Name
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.ZIndex = i
	for _, c in g:GetChildren() do
		c:Clone().Parent = holder
	end
	for _, x in holder:GetDescendants() do
		if x:IsA("LuaSourceContainer") then
			x:Destroy()
		end
	end
	holder.Parent = safe
end
gui.Parent = SG

-- checks, in unscaled device px relative to the safe frame
local origin = safe.AbsolutePosition
local function rect(o)
	local p = (o.AbsolutePosition - origin) / fit
	local s = o.AbsoluteSize / fit
	return p.X, p.Y, p.X + s.X, p.Y + s.Y, s
end
local function shown(o)
	while o and o ~= safe do
		if o:IsA("GuiObject") and not o.Visible then
			return false
		end
		o = o.Parent
	end
	return true
end
local problems = {}
for _, holder in safe:GetChildren() do
	if holder.Name == "Zone" or holder.Name:sub(1, 5) == "Zone:" or holder.Name:sub(1, 5) == "Zone " then
		continue
	end
	for _, o in holder:GetDescendants() do
		if not o:IsA("GuiObject") or not shown(o) then
			continue
		end
		local x0, y0, x1, y1, s = rect(o)
		local name = o:GetFullName():gsub("^.-Safe%.", "")
		if o:IsA("GuiButton") then
			for _, z in zones do
				if x0 < z[4] and x1 > z[2] and y0 < z[5] and y1 > z[3] then
					table.insert(problems, string.format("%s: button %s inside %s", z[6], name, z[1]))
				end
			end
			if d.touch and math.min(s.X, s.Y) < MIN_TARGET then
				table.insert(problems, string.format("warn: button %s is %dx%d px, under %d", name, s.X, s.Y, MIN_TARGET))
			end
		end
		if (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) and o.Text ~= "" and o.TextTransparency < 1 then
			local px = o.TextScaled and (o.TextBounds.Y / fit) or o.TextSize
			if px < MIN_TEXT then
				table.insert(problems, string.format("warn: text %s about %d px, under %d", name, px, MIN_TEXT))
			end
		end
		if s.X > 0 and (x1 < 0 or y1 < 0 or x0 > W or y0 > H) then
			table.insert(problems, string.format("warn: %s is outside the safe area", name))
		elseif s.X > 0 and o.Parent == holder and (x0 < -1 or y0 < -1 or x1 > W + 1 or y1 > H + 1) then
			table.insert(problems, string.format("warn: %s crosses the safe-area edge", name))
		end
	end
end
return string.format("%s: screen %dx%d, safe %dx%d, %s touch controls, preview scale %.2f\n%s",
	DEVICE, d.w, d.h, W, H, d.touch and (small and "small" or "large") or "no", fit,
	#problems == 0 and "no problems" or table.concat(problems, "\n"))
