--!strict
-- PanelStage: opens one panel at a time on a small screen (roblox-ui-mobile section 4).
-- A modal panel (shop, settings, confirm): the game dims or blurs behind it, the HUD layers the
-- panel would cover slide off their own edge, the touch controls hide, the panel pops in. A tap
-- outside closes it. A sheet (modal = false; a unit card beside play) only moves the HUD layers it
-- covers: no backdrop, the touch controls stay. Close brings everything back.
-- While the on-screen keyboard is up, the panel moves up so the focused TextBox stays visible.
-- Client ModuleScript. Tested in the Studio 0.747 Device Simulator on Samsung Galaxy A06,
-- iPhone 17 Pro, Amazon Fire HD 10 (2023), iPad 10th Generation and Average Windows (2026-11-12).
--
-- local stage = PanelStage.new(playerGui)   -- or .new(playerGui, 5): scrim under a HUD of order 10
-- stage:addLayer(hud.Left, "left")      -- a full-size transparent Frame holding that side's HUD
-- stage:addLayer(hud.Right, "right")
-- stage:addLayer(hud.Top, "top")
-- stage:open(shopPanel)                               -- dim, covered layers slide off
-- stage:open(shopPanel, { backdrop = "blur" })        -- world blur plus a light dim
-- stage:open(unitCard, { modal = false })             -- play continues beside it
-- stage:open(otherPanel)                              -- while one is open: swaps, no flicker
-- stage:close()
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

export type Side = "left" | "right" | "top" | "bottom"
export type OpenOptions = {
	modal: boolean?, -- default true; false = a sheet beside play
	backdrop: ("dim" | "blur" | "none")?, -- modal only, default "dim"
	dim: number?, -- scrim darkness 0-1: default 0.5 for "dim", 0.25 for "blur", 0 for "none"
	blur: number?, -- BlurEffect.Size for "blur", default 16
	hide: ("overlap" | "all" | "none")?, -- HUD layers that slide off, default "overlap" (those the panel covers)
	keep: { GuiObject }?, -- layers that never slide
	dismissOnScrim: boolean?, -- modal only, default true
}
type Layer = { frame: GuiObject, side: Side, home: UDim2, out: boolean }

local OPEN_TIME, CLOSE_TIME, SLIDE_OUT, SLIDE_IN, FADE = 0.2, 0.12, 0.18, 0.25, 0.2
local GAP = 8 -- px a HUD element must keep from the panel to stay on screen
local DIRECTION: { [Side]: Vector2 } = {
	left = Vector2.new(-1, 0),
	right = Vector2.new(1, 0),
	top = Vector2.new(0, -1),
	bottom = Vector2.new(0, 1),
}

local PanelStage = {}
PanelStage.__index = PanelStage

-- order: the scrim's DisplayOrder, default 50. Panels live in a ScreenGui above it. HUD below it
-- is dimmed with the game and takes no taps while a modal panel is open; HUD above it stays bright
-- and tappable, so a menu button can switch panels.
function PanelStage.new(playerGui: Instance, order: number?)
	local self = setmetatable({}, PanelStage)
	-- its own ScreenGui with no insets, so it also covers the notch margins and the top bar strip
	local gui = Instance.new("ScreenGui")
	gui.Name = "PanelScrim"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = order or 50
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
	local blur = Instance.new("BlurEffect") -- blurs the 3D world only; UI stays sharp
	blur.Name = "PanelStageBlur"
	blur.Size = 0
	blur.Enabled = false
	blur.Parent = Lighting
	self.gui = gui
	self.scrim = scrim
	self.blur = blur
	self.layers = {} :: { Layer }
	self.panel = nil :: GuiObject?
	self.modal = false
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
	table.insert(self.layers, { frame = frame, side = side, home = frame.Position, out = false })
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

-- true when a visible child of the layer, at the layer's home position, comes within GAP of the panel
local function covered(layer: Layer, panel: GuiObject): boolean
	local frame = layer.frame
	local shift = Vector2.new(frame.Position.X.Offset - layer.home.X.Offset, frame.Position.Y.Offset - layer.home.Y.Offset)
	local p0 = panel.AbsolutePosition - Vector2.new(GAP, GAP)
	local p1 = panel.AbsolutePosition + panel.AbsoluteSize + Vector2.new(GAP, GAP)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			local c0 = child.AbsolutePosition - shift
			local c1 = c0 + child.AbsoluteSize
			if c0.X < p1.X and c1.X > p0.X and c0.Y < p1.Y and c1.Y > p0.Y then
				return true
			end
		end
	end
	return false
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

function PanelStage:_setHidden(want: { [GuiObject]: boolean })
	for _, layer in self.layers :: { Layer } do
		if want[layer.frame] and not layer.out then
			layer.out = true
			local t = tween(layer.frame, SLIDE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Position = travel(layer) })
			if t then
				t.Completed:Once(function()
					if layer.out then -- still hidden: a hidden layer takes no input
						layer.frame.Visible = false
					end
				end)
			else
				layer.frame.Visible = false
			end
		elseif not want[layer.frame] and layer.out then
			layer.out = false
			layer.frame.Visible = true
			tween(layer.frame, SLIDE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = layer.home })
		end
	end
end

function PanelStage:_setBackdrop(modal: boolean, dim: number, blur: number)
	if modal then
		self.gui.Enabled = true
		if not self.modal then
			self.touchWas = GuiService.TouchControlsEnabled
			GuiService.TouchControlsEnabled = false -- the scrim takes every touch, so the controls would be dead
		end
	elseif self.modal then
		GuiService.TouchControlsEnabled = self.touchWas
	end
	self.modal = modal
	local fade = tween(self.scrim, FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 - dim })
	if not modal then
		if fade then
			fade.Completed:Once(function()
				if not self.modal then
					self.gui.Enabled = false
				end
			end)
		else
			self.gui.Enabled = false
		end
	end
	if blur > 0 then
		self.blur.Enabled = true
	end
	local soften = tween(self.blur, FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = blur })
	if blur == 0 then
		if soften then
			soften.Completed:Once(function()
				if self.blur.Size == 0 then
					self.blur.Enabled = false
				end
			end)
		else
			self.blur.Enabled = false
		end
	end
end

function PanelStage:open(panel: GuiObject, options: OpenOptions?)
	local opts: OpenOptions = options or {}
	local swap = self.panel ~= nil
	local old = self.panel
	if old and old ~= panel then
		if self.home then
			old.Position = self.home
			self.home = nil
		end
		old.Visible = false
	end
	self.panel = panel
	local modal = opts.modal ~= false
	local backdrop = if modal then (opts.backdrop or "dim") else "none"
	self.dismiss = modal and opts.dismissOnScrim ~= false
	self:_setBackdrop(
		modal,
		if not modal then 0 else opts.dim or (if backdrop == "dim" then 0.5 elseif backdrop == "blur" then 0.25 else 0),
		if backdrop == "blur" then opts.blur or 16 else 0
	)

	local scale = scaleOf(panel)
	scale.Scale = 1
	panel.Visible = true -- AbsoluteSize below is the panel's final rect
	local hide = opts.hide or "overlap"
	local keep = opts.keep or {}
	local want = {}
	for _, layer in self.layers :: { Layer } do
		if not table.find(keep, layer.frame) and (hide == "all" or (hide == "overlap" and covered(layer, panel))) then
			want[layer.frame] = true
		end
	end
	self:_setHidden(want)

	if not swap and not instant() then
		scale.Scale = 0.9
		tween(scale, OPEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	end
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
	self:_setBackdrop(false, 0, 0)
	self:_setHidden({})
end

return PanelStage
