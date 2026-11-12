--!strict
-- PanelStage: opens one panel at a time the way phone players expect (roblox-ui-mobile section 5).
-- On open: the game dims behind a scrim, HUD layers slide off their own edge, the touch controls
-- hide, the panel pops in. On close everything comes back. A tap on the scrim closes the panel.
-- While the on-screen keyboard is up, the panel moves up so the focused TextBox stays visible.
-- Client ModuleScript. Tested in the Studio 0.747 Device Simulator on Samsung Galaxy A06,
-- iPhone 17 Pro, iPad 10th Generation and Average Windows (2026-11-12).
--
-- local stage = PanelStage.new(playerGui)
-- stage:addLayer(hud.Left, "left")      -- a full-size transparent Frame holding that side's HUD
-- stage:addLayer(hud.Right, "right")
-- stage:open(shopPanel, { keep = { hud.Top } })   -- keep: layers that stay on screen
-- stage:open(otherPanel)                          -- while one is open: swaps the panel only
-- stage:close()
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

export type Side = "left" | "right" | "top" | "bottom"
export type OpenOptions = {
	dim: number?, -- scrim darkness 0-1, default 0.5
	keep: { GuiObject }?, -- layers that stay on screen
	dismissOnScrim: boolean?, -- default true
	hideTouchControls: boolean?, -- default true
}
type Layer = { frame: GuiObject, side: Side, home: UDim2 }

local OPEN_TIME, CLOSE_TIME, SLIDE_OUT, SLIDE_IN = 0.25, 0.12, 0.18, 0.25
local DIRECTION: { [Side]: Vector2 } = {
	left = Vector2.new(-1, 0),
	right = Vector2.new(1, 0),
	top = Vector2.new(0, -1),
	bottom = Vector2.new(0, 1),
}

local PanelStage = {}
PanelStage.__index = PanelStage

function PanelStage.new(playerGui: Instance)
	local self = setmetatable({}, PanelStage)
	-- The scrim has its own ScreenGui with no insets, so it also covers the notch margins and
	-- the top bar strip. Panels live in a ScreenGui with a higher DisplayOrder than this one.
	local gui = Instance.new("ScreenGui")
	gui.Name = "PanelScrim"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = 50
	gui.Enabled = false
	local scrim = Instance.new("TextButton") -- a button, so taps reach neither the HUD nor the world
	scrim.Name = "Scrim"
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = Color3.new(0, 0, 0)
	scrim.BackgroundTransparency = 1
	scrim.BorderSizePixel = 0
	scrim.Parent = gui
	gui.Parent = playerGui
	self.gui = gui
	self.scrim = scrim
	self.layers = {} :: { Layer }
	self.panel = nil :: GuiObject?
	self.hidden = {} :: { Layer }
	self.touchWas = true
	self.dismiss = true
	self.home = nil :: UDim2? -- the open panel's position before the keyboard moved it
	UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
		self:_followKeyboard()
	end)
	scrim.Activated:Connect(function()
		if self.dismiss then
			self:close()
		end
	end)
	return self
end

-- OnScreenKeyboardPosition is in viewport px; AbsolutePosition starts below the top bar inset.
function PanelStage:_followKeyboard()
	local panel = self.panel
	if not panel then
		return
	end
	local box = UserInputService:GetFocusedTextBox()
	if UserInputService.OnScreenKeyboardVisible and box and box:IsDescendantOf(panel) then
		local keyboardTop = UserInputService.OnScreenKeyboardPosition.Y - GuiService:GetGuiInset().Y
		local over = box.AbsolutePosition.Y + box.AbsoluteSize.Y + 8 - keyboardTop
		if over > 0 then
			self.home = self.home or panel.Position
			local lift = math.min(over, panel.AbsolutePosition.Y) -- never push the panel off the top
			panel.Position = panel.Position - UDim2.fromOffset(0, lift)
		end
	elseif self.home then
		panel.Position = self.home
		self.home = nil
	end
end

function PanelStage:addLayer(frame: GuiObject, side: Side)
	table.insert(self.layers, { frame = frame, side = side, home = frame.Position })
end

local function instant(): boolean
	return GuiService.ReducedMotionEnabled
end

local function tween(object: Instance, time: number, style: Enum.EasingStyle, dir: Enum.EasingDirection, goal: { [string]: any })
	if instant() then
		for key, value in goal do
			(object :: any)[key] = value
		end
		return nil
	end
	local t = TweenService:Create(object, TweenInfo.new(time, style, dir), goal)
	t:Play()
	return t
end

-- how far a layer must move so that its visible children leave the screen on its side
local function travel(layer: Layer): UDim2
	local frame = layer.frame
	local origin, size = frame.AbsolutePosition, frame.AbsoluteSize
	local reach = 0
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			local p, s = child.AbsolutePosition - origin, child.AbsoluteSize
			if layer.side == "left" then
				reach = math.max(reach, p.X + s.X)
			elseif layer.side == "right" then
				reach = math.max(reach, size.X - p.X)
			elseif layer.side == "top" then
				reach = math.max(reach, p.Y + s.Y)
			else
				reach = math.max(reach, size.Y - p.Y)
			end
		end
	end
	-- 80 px more: on a notched phone the layer starts inside the notch margin
	local d = DIRECTION[layer.side] * (reach + 80)
	return layer.home + UDim2.fromOffset(d.X, d.Y)
end

local function scaleOf(panel: GuiObject): UIScale
	local s = panel:FindFirstChildOfClass("UIScale")
	if not s then
		local new = Instance.new("UIScale")
		new.Parent = panel
		return new
	end
	return s
end

function PanelStage:open(panel: GuiObject, options: OpenOptions?)
	local opts: OpenOptions = options or {}
	local scale = scaleOf(panel)
	if self.panel then -- swap panels: the scrim and the hidden layers stay as they are
		if self.panel ~= panel then
			if self.home then
				self.panel.Position = self.home
				self.home = nil
			end
			self.panel.Visible = false
		end
		self.panel = panel
		self.dismiss = opts.dismissOnScrim ~= false
		scale.Scale = 1
		panel.Visible = true
		return
	end
	self.panel = panel
	self.dismiss = opts.dismissOnScrim ~= false
	self.gui.Enabled = true
	tween(self.scrim, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 - (opts.dim or 0.5) })

	local keep = opts.keep or {}
	self.hidden = {}
	for _, layer in self.layers do
		if not table.find(keep, layer.frame) then
			table.insert(self.hidden, layer)
			local t = tween(layer.frame, SLIDE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Position = travel(layer) })
			if t then
				t.Completed:Once(function()
					if self.panel then -- still open: a hidden layer takes no input
						layer.frame.Visible = false
					end
				end)
			else
				layer.frame.Visible = false
			end
		end
	end

	if opts.hideTouchControls ~= false then
		self.touchWas = GuiService.TouchControlsEnabled
		GuiService.TouchControlsEnabled = false
	end

	scale.Scale = if instant() then 1 else 0.9
	panel.Visible = true
	tween(scale, OPEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
end

function PanelStage:close(now: boolean?)
	local panel = self.panel
	if not panel then
		return
	end
	self.panel = nil
	if self.home then
		panel.Position = self.home
		self.home = nil
	end
	local scale = scaleOf(panel)
	local t = if now then nil else tween(scale, CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.9 })
	if t then
		t.Completed:Once(function()
			if self.panel ~= panel then
				panel.Visible = false
			end
		end)
	else
		panel.Visible = false
	end

	local fade = tween(self.scrim, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
	if fade then
		fade.Completed:Once(function()
			if not self.panel then
				self.gui.Enabled = false
			end
		end)
	else
		self.gui.Enabled = false
	end

	for _, layer in self.hidden do
		layer.frame.Visible = true
		tween(layer.frame, SLIDE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = layer.home })
	end
	self.hidden = {}
	GuiService.TouchControlsEnabled = self.touchWas
end

return PanelStage
