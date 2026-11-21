-- WindowKit: the finish and the motion of a designed window (roblox-ui-mobile section 4,
-- "A window that looks designed, opens in order and answers a press").
-- Finish: card() and button() build a surface with a dark outline, a lighter top, a light line
-- inside the top edge and a shadow, so every panel, row and button of a screen shares one depth;
-- icon() puts an image of your icon pack in a well with the same finish; tabs() is a tab strip.
-- Screen: stage() sizes a window by its share of the screen, scrim() dims the whole screen under it.
-- Motion: open() grows the window in while its content arrives in order, close() fades it out,
-- press() squashes a button before its state changes, fly() and count() send rewards to a
-- counter, list() keeps keyed rows that tween to their new places, burst() and stamp() make a
-- bigger moment for a bigger reward. Shapes are Frames; icons are image ids you pass in.
-- Client ModuleScript. The ScreenGui must use ZIndexBehavior Sibling. Honours Reduced Motion.
-- Use its own dim and sizing (scrim, stage) or PanelStage for a window, not both.
-- Demo: window_kit_demo.luau (a phone layout and a larger one; lint-clean on four device presets).
--
-- local Kit = require(ReplicatedStorage.Ui.WindowKit)
-- local layer = Kit.stage(gui, Vector2.new(760, 440))            -- the window's design size
-- local window, content = Kit.card(layer, { size = UDim2.fromOffset(760, 440), fill = indigo, depth = 8, role = "panel" })
-- local claim, label = Kit.button(content, { text = "CLAIM", fill = green, size = UDim2.fromOffset(180, 52), hit = 44 })
-- Kit.press(claim, function() ... end)          -- runs after the squash, not on the press frame
-- Kit.open(window, { { emblem, "pop" }, { rows, "slide", from = "left" }, { closeButton, "spin" } })
-- Kit.close(window)
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Kit = {}

-- seconds; measured on a designer's window and on live games (section 4 and 4a)
Kit.TIMES = {
	shell = 0.2, -- the window grows in with a small overshoot
	budget = 0.7, -- everything of an open has started by budget - 0.2
	pop = 0.2,
	slide = 0.18,
	fade = 0.14,
	close = 0.22,
	press = 0.08,
	rebound = 0.2,
	fly = 0.4,
	flyGap = 0.07,
	count = 0.5,
	sort = 0.28,
}

local Quad, Back, Sine, Linear = Enum.EasingStyle.Quad, Enum.EasingStyle.Back, Enum.EasingStyle.Sine, Enum.EasingStyle.Linear
local Out, In, InOut = Enum.EasingDirection.Out, Enum.EasingDirection.In, Enum.EasingDirection.InOut

local function reduced(): boolean
	return GuiService.ReducedMotionEnabled
end

-- ---------- animation driver: one RenderStepped connection, animations keyed by owner and channel ----------

local active = {}
local byOwner = {} -- owner -> { channel -> animation }; strong on purpose: a weak table drops Instance keys that Lua holds nowhere else
local connection: RBXScriptConnection? = nil

local function finishAnim(a)
	if a.dead then
		return
	end
	a.dead = true
	local slot = byOwner[a.owner]
	if slot and slot[a.channel] == a then
		slot[a.channel] = nil
		if next(slot) == nil then
			byOwner[a.owner] = nil
		end
	end
	a.step(1, 1)
	if a.done then
		a.done()
	end
end

local function tick()
	local now = os.clock()
	for i = #active, 1, -1 do
		local a = active[i]
		if a.dead then
			table.remove(active, i)
		else
			local t = (now - a.t0) / a.dur
			if t >= 1 then
				table.remove(active, i)
				finishAnim(a)
			elseif t >= 0 then
				a.step(TweenService:GetValue(t, a.style, a.dir), t)
			end
		end
	end
	if #active == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- step(eased, raw): eased may pass 1 on Back; a new animation on the same owner and channel ends the old one first
local function run(owner: Instance, channel: string, delay: number, dur: number, style, dir, step, done)
	local slot = byOwner[owner]
	if not slot then
		slot = {}
		byOwner[owner] = slot
	end
	for _ = 1, 4 do -- an ending animation may start its follow-up on the same channel: end that too
		if not slot[channel] then
			break
		end
		finishAnim(slot[channel])
	end
	local a = { owner = owner, channel = channel, t0 = os.clock() + delay, dur = math.max(dur, 0.001), style = style, dir = dir, step = step, done = done }
	if reduced() and channel ~= "fade" and channel ~= "count" then
		a.dur = 0.001
	end
	slot[channel] = a
	table.insert(active, a)
	if not connection then
		connection = RunService.RenderStepped:Connect(tick)
	end
	return a
end

local function stop(owner: Instance, channel: string)
	local slot = byOwner[owner]
	for _ = 1, 4 do
		if not (slot and slot[channel]) then
			break
		end
		finishAnim(slot[channel])
	end
end

-- end every animation on root and under it now, at its final state
function Kit.settle(root: Instance)
	for i = #active, 1, -1 do
		local a = active[i]
		if a and not a.dead and (a.owner == root or a.owner:IsDescendantOf(root)) then
			finishAnim(a)
		end
	end
end

-- ---------- small helpers ----------

local function scaleOf(gui: Instance): UIScale
	local s = gui:FindFirstChildOfClass("UIScale")
	if not s then
		s = Instance.new("UIScale")
		s.Parent = gui
	end
	return s :: UIScale
end

-- product of the UIScale factors above an object: one Offset unit inside it is that many px on screen
local function scaleAbove(o: Instance): number
	local s = 1
	local p = o.Parent
	while p do
		local u = p:FindFirstChildOfClass("UIScale")
		if u then
			s *= u.Scale
		end
		p = p.Parent
	end
	return s
end

-- false under a layout object: Position does nothing there, so slides and big pops fall back to a small scale
local function free(gui: Instance): boolean
	local p = gui.Parent
	return not (p and (p:FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil))
end

local function shade(c: Color3, k: number): Color3 -- k < 0 darker, k > 0 lighter
	if k < 0 then
		return c:Lerp(Color3.new(0, 0, 0), -k)
	end
	return c:Lerp(Color3.new(1, 1, 1), k)
end
Kit.shade = shade

-- The label colour that reads on a fill: white with a dark outline on a dark fill, dark ink and no
-- outline on a bright one (an outline does not raise contrast). Returns (text colour, outline colour or nil).
local function ink(fill: Color3): (Color3, Color3?)
	local function lin(c: number): number
		return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
	end
	local function lum(c: Color3): number
		return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
	end
	local dark = shade(fill, -0.82)
	local l = lum(fill)
	if 1.05 / (l + 0.05) >= (l + 0.05) / (lum(dark) + 0.05) then
		return Color3.new(1, 1, 1), shade(fill, -0.6)
	end
	return dark, nil
end
Kit.ink = ink

local function make(class: string, props, parent: Instance?)
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

-- ---------- fading a whole item: its own transparencies and its descendants', back to what they were ----------
-- One state per faded root. An instance is held by one state at a time, with the value it had as built:
-- a fade that starts inside another (a pane's content inside an opening window) takes its instances over
-- with those values, so nested fades never record a half-faded value.

local fades = {} -- root -> { root, map = { [instance] = { {property, original} } }, alpha }
local holder = {} -- instance -> the state that holds it (both strong: emptied by release, and when the root is destroyed)

local function record(o: Instance)
	local rec = {}
	local function keep(prop: string)
		table.insert(rec, { prop, (o :: any)[prop] })
	end
	if o:IsA("CanvasGroup") then
		keep("GroupTransparency")
	elseif o:IsA("GuiObject") then
		keep("BackgroundTransparency")
		if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
			keep("TextTransparency")
			keep("TextStrokeTransparency")
		elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
			keep("ImageTransparency")
		elseif o:IsA("ScrollingFrame") then
			keep("ScrollBarImageTransparency")
		end
	elseif o:IsA("UIStroke") then
		keep("Transparency")
	end
	return rec
end

-- takeover (a closing window): the fade states found inside keep their own values and follow this one
local function gather(state, skip: { [Instance]: boolean }?, takeover: boolean?)
	if takeover then
		state.inner = {}
	end
	local function visit(o: Instance)
		if o ~= state.root then
			if skip and skip[o] then
				return
			end
			local inner = fades[o]
			if inner then
				if not takeover then
					return
				end
				table.insert(state.inner, { inner, inner.alpha })
			end
		end
		local held = holder[o]
		if held ~= state and not (held and held.root:IsDescendantOf(state.root)) then
			if held then -- an outer state holds it: take it over with the value it had as built
				state.map[o] = held.map[o]
				held.map[o] = nil
			else
				local rec = record(o)
				if #rec > 0 then
					state.map[o] = rec
				end
			end
			if state.map[o] then
				holder[o] = state
			end
		end
		if not o:IsA("CanvasGroup") then
			for _, c in o:GetChildren() do
				visit(c)
			end
		end
	end
	visit(state.root)
end

local function release(state)
	for o in state.map do
		if holder[o] == state then
			holder[o] = nil
		end
	end
	if fades[state.root] == state then
		fades[state.root] = nil
	end
end

local function fadeState(root: Instance, skip: { [Instance]: boolean }?, takeover: boolean?)
	local state = fades[root]
	if not state then
		state = { root = root, map = {}, alpha = 1 }
		fades[root] = state
		root.Destroying:Once(function()
			release(state)
		end)
	end
	gather(state, skip, takeover)
	return state
end

local applyAlpha
function applyAlpha(state, alpha: number)
	state.alpha = alpha
	local a = math.clamp(alpha, 0, 1)
	for o, rec in state.map do
		for _, e in rec do
			(o :: any)[e[1]] = 1 - (1 - e[2]) * a
		end
	end
	for _, i in state.inner or {} do
		applyAlpha(i[1], i[2] * a)
	end
end

-- set an item's visibility now (0 hidden, 1 as built)
local function fadeSet(root: Instance, alpha: number, skip: { [Instance]: boolean }?, takeover: boolean?)
	local state = fadeState(root, skip, takeover)
	applyAlpha(state, alpha)
	if alpha >= 1 then
		release(state)
	end
end

local function fade(root: Instance, from: number, to: number, delay: number, dur: number, done: (() -> ())?, skip: { [Instance]: boolean }?, takeover: boolean?)
	stop(root, "fade")
	local state = fadeState(root, skip, takeover)
	applyAlpha(state, from)
	run(root, "fade", delay, dur, Quad, Out, function(e)
		applyAlpha(state, from + (to - from) * math.clamp(e, 0, 1))
	end, function()
		if to >= 1 then
			release(state)
		end
		if done then
			done()
		end
	end)
end

-- fade an item by hand: Kit.fade(gui, 0) hides it, Kit.fade(gui, 1) brings it back as built, 0.4 dims it
function Kit.fade(gui: Instance, to: number, dur: number?, delay: number?)
	local state = fades[gui]
	fade(gui, state and state.alpha or 1, to, delay or 0, dur or Kit.TIMES.fade)
end

-- ---------- finish ----------

export type CardOptions = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	order: number?, -- LayoutOrder
	z: number?, -- ZIndex
	fill: Color3?,
	stroke: Color3?, -- default: the fill, 55% darker
	strokeWidth: number?, -- default 2; 3-4 on a window; 0 = no outline (a piece inside an outlined track)
	radius: number?, -- px, default 12
	depth: number?, -- shadow drop in px, default 0 (none); 6-8 on a window, 4 on a button
	lift: number?, -- how much lighter the top is than the bottom, default 0.14
	topLight: boolean?, -- the light line inside the top edge, default true (never on a radius over 24)
	sheen: boolean?, -- one diagonal band at rest (animate it with Kit.sheen), default false
	padding: number?, -- px of UIPadding on the content, default 0
	button: boolean?, -- a TextButton instead of a Frame
	clip: boolean?, -- the content clips its children, default false
	hit: number?, -- the smallest tap area in screen px (44 on touch): a button drawn smaller gets an invisible pad
	role: string?, -- the lint's KitRole attribute: "menu", "action", "currency", "panel", ...
	breakout: string?, -- the lint's KitBreakout attribute for a piece that sticks out of its host on purpose: "ornament", "badge", ...
}

-- A surface. Returns (outer, content): place, size and animate outer; parent your own children to content.
-- outer > Shadow, Body (fill, outline, top light, sheen), Content.
function Kit.card(parent: Instance, o: CardOptions?)
	local opt: CardOptions = o or {}
	local fill = opt.fill or Color3.fromRGB(44, 52, 78)
	local radius = opt.radius or 12
	local depth = opt.depth or 0
	local outer = make(opt.button and "TextButton" or "Frame", {
		Name = opt.name or (opt.button and "Button" or "Card"),
		BackgroundTransparency = 1,
		Size = opt.size or UDim2.fromOffset(240, 80),
		Position = opt.position or UDim2.new(),
		AnchorPoint = opt.anchor or Vector2.zero,
		LayoutOrder = opt.order or 0,
		ZIndex = opt.z or 1,
	})
	if opt.button then
		(outer :: any).Text = ""
		;(outer :: any).AutoButtonColor = false
	end
	if depth > 0 then
		-- the body covers all but the drop. Under an outline the shadow is 1 px larger all round (hidden by the
		-- outline), so it wholly holds the body at any scale: a lint that reads a small frame crossing a stroke
		-- as an icon on the stroke passes it.
		local grow = opt.strokeWidth ~= 0 and 1 or 0
		local shadow = make("Frame", {
			Name = "Shadow",
			ZIndex = 0,
			Size = UDim2.new(1, 2 * grow, 1, depth + 2 * grow),
			Position = UDim2.fromOffset(-grow, -grow),
			BackgroundColor3 = shade(fill, -0.8),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
		}, outer)
		make("UICorner", { CornerRadius = UDim.new(0, radius + grow) }, shadow)
	end
	local body = make("Frame", { Name = "Body", ZIndex = 1, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = fill, BorderSizePixel = 0 }, outer)
	make("UICorner", { CornerRadius = UDim.new(0, radius) }, body)
	if opt.strokeWidth ~= 0 then
		make("UIStroke", {
			Color = opt.stroke or shade(fill, -0.55),
			Thickness = opt.strokeWidth or 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, body)
	end
	local lift = opt.lift or 0.14
	make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(shade(Color3.new(1, 1, 1), 0), Color3.new(1 - lift, 1 - lift, 1 - lift)),
	}, body)
	body.BackgroundColor3 = shade(fill, lift * 0.5) -- the gradient darkens the bottom; keep the middle on the asked colour
	if opt.topLight ~= false and radius <= 24 then -- a straight line does not sit inside a round shape
		local line = make("Frame", {
			Name = "TopLight",
			Size = UDim2.new(1, -2 * radius, 0, 2),
			Position = UDim2.fromOffset(radius, 2),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
		}, body)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, line)
	end
	if opt.sheen then
		Kit.sheen(outer, { once = true, rest = true })
	end
	local content = make("Frame", {
		Name = "Content",
		ZIndex = 2,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = opt.clip == true,
	}, outer)
	if opt.padding and opt.padding > 0 then
		local p = UDim.new(0, opt.padding)
		make("UIPadding", { PaddingLeft = p, PaddingRight = p, PaddingTop = p, PaddingBottom = p }, content)
	end
	if opt.role then
		outer:SetAttribute("KitRole", opt.role)
	end
	if opt.breakout then
		outer:SetAttribute("KitBreakout", opt.breakout)
	end
	outer.Parent = parent
	if opt.hit and opt.button then
		local k = scaleAbove(outer)
		local size = outer.Size
		local w = size.X.Scale == 0 and size.X.Offset * k or outer.AbsoluteSize.X
		local h = size.Y.Scale == 0 and size.Y.Offset * k or outer.AbsoluteSize.Y
		if w > 0 and h > 0 and (w < opt.hit or h < opt.hit) then
			local pad = make("TextButton", {
				Name = "Hit",
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(math.ceil(math.max(w, opt.hit + 1) / k), math.ceil(math.max(h, opt.hit + 1) / k)),
				ZIndex = 3,
			}, outer)
			pad:SetAttribute("KitHit", true)
		end
	end
	return outer, content
end

export type ButtonOptions = CardOptions & {
	text: string?,
	textColor: Color3?, -- default: Kit.ink(fill), the colour that reads on the fill
	textSize: number?,
	font: Enum.Font?,
	fontFace: Font?,
}

-- A button with the same finish, a stroked label and the press feedback wired. Returns (button, label, content).
function Kit.button(parent: Instance, o: ButtonOptions?)
	local opt: ButtonOptions = o or {}
	local cardOpt = table.clone(opt) :: any
	cardOpt.button = true
	cardOpt.fill = opt.fill or Color3.fromRGB(64, 196, 92)
	cardOpt.depth = opt.depth or 4
	cardOpt.size = opt.size or UDim2.fromOffset(180, 52)
	cardOpt.name = opt.name or "Button"
	local outer, content = Kit.card(parent, cardOpt)
	local color, line = ink(cardOpt.fill)
	local label = make("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = opt.text or "",
		TextColor3 = opt.textColor or color,
		TextSize = opt.textSize or 20,
		Font = opt.font or Enum.Font.GothamBold,
	}, content)
	if opt.fontFace then
		label.FontFace = opt.fontFace
	end
	label:SetAttribute("KitInk", opt.textColor == nil) -- recolor() keeps the label readable on the new fill
	make("UIStroke", { Color = line or color, Thickness = 2, Enabled = opt.textColor ~= nil or line ~= nil }, label)
	return outer, label, content
end

-- change a card's or a button's fill (a state change: in progress, claim, claimed, locked), in 0.12 s
function Kit.recolor(card: Instance, fill: Color3, stroke: Color3?)
	local body = card:FindFirstChild("Body") :: Frame?
	if not body then
		return
	end
	local line = body:FindFirstChildOfClass("UIStroke")
	stop(body, "flash")
	stop(body, "color")
	local from, fromStroke = body.BackgroundColor3, line and line.Color
	local grad = body:FindFirstChildOfClass("UIGradient")
	local lift = grad and (1 - grad.Color.Keypoints[#grad.Color.Keypoints].Value.R) or 0
	local to, toStroke = shade(fill, lift * 0.5), stroke or shade(fill, -0.55)
	run(body, "color", 0, 0.12, Quad, Out, function(e)
		local k = math.clamp(e, 0, 1)
		body.BackgroundColor3 = from:Lerp(to, k)
		if line and fromStroke then
			line.Color = fromStroke:Lerp(toStroke, k)
		end
	end)
	local label = card:FindFirstChild("Label", true) :: TextLabel?
	local labelStroke = label and label:FindFirstChildOfClass("UIStroke")
	if label and label:GetAttribute("KitInk") then
		local color, outline = ink(fill)
		label.TextColor3 = color
		if labelStroke then
			labelStroke.Enabled = outline ~= nil
			labelStroke.Color = outline or color
		end
	elseif labelStroke then
		labelStroke.Color = shade(fill, -0.6)
	end
end

-- the light finish for a Frame you already have (corner, outline, lighter top): no shadow, no extra children
function Kit.finish(gui: GuiObject, o: { radius: number?, stroke: Color3?, strokeWidth: number?, lift: number? }?)
	local opt = o or {}
	if not gui:FindFirstChildOfClass("UICorner") then
		make("UICorner", { CornerRadius = UDim.new(0, opt.radius or 12) }, gui)
	end
	if not gui:FindFirstChildOfClass("UIStroke") then
		make("UIStroke", {
			Color = opt.stroke or shade(gui.BackgroundColor3, -0.55),
			Thickness = opt.strokeWidth or 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, gui)
	end
	if not gui:FindFirstChildOfClass("UIGradient") then
		local lift = opt.lift or 0.14
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1 - lift, 1 - lift, 1 - lift)) }, gui)
	end
	return gui
end

-- ---------- press ----------

-- what takes the tap: the button's hit pad when it has one (the pad lies over the button, so the button's
-- own Activated no longer fires). Connect to Kit.target(button).Activated, or use Kit.press.
function Kit.target(button: GuiButton): GuiButton
	local pad = button:FindFirstChild("Hit")
	return (pad and pad:IsA("GuiButton")) and pad or button
end

-- Squash, rebound and a light flash on press; fn runs after the squash (70 ms), so the state changes after
-- the press is seen. Hover lifts the button a little on a mouse.
function Kit.press(button: GuiButton, fn: (() -> ())?)
	local s = scaleOf(button)
	local body = (button:FindFirstChild("Body") or button) :: GuiObject
	local busy = false
	local target = Kit.target(button)
	button.MouseEnter:Connect(function()
		if not busy then
			local from = s.Scale
			run(button, "scale", 0, 0.09, Quad, Out, function(e)
				s.Scale = from + (1.03 - from) * e
			end)
		end
	end)
	button.MouseLeave:Connect(function()
		if not busy then
			local from = s.Scale
			run(button, "scale", 0, 0.09, Quad, Out, function(e)
				s.Scale = from + (1 - from) * e
			end)
		end
	end)
	target.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		Kit.squash(button, function()
			busy = false
		end)
		task.delay(reduced() and 0 or Kit.TIMES.press, function()
			if fn then
				fn()
			end
		end)
	end)
	return body
end

-- the press motion alone (a scripted tour, or a press you handle yourself)
function Kit.squash(gui: GuiObject, done: (() -> ())?)
	local s = scaleOf(gui)
	local body = (gui:FindFirstChild("Body") or gui) :: GuiObject
	local T = Kit.TIMES
	stop(body, "flash")
	local base = body.BackgroundColor3
	run(body, "flash", 0, 0.11, Quad, Out, function(e)
		body.BackgroundColor3 = shade(base, 0.45):Lerp(base, math.clamp(e, 0, 1))
	end)
	run(gui, "scale", 0, T.press, Quad, Out, function(e)
		s.Scale = 1 + (0.88 - 1) * e
	end, function()
		run(gui, "scale", 0, T.rebound, Back, Out, function(e)
			s.Scale = 0.88 + (1 - 0.88) * e
		end, done)
	end)
end

-- ---------- open and close ----------

local warned = false
local OFFSET = { left = Vector2.new(-28, 0), right = Vector2.new(28, 0), top = Vector2.new(0, -20), bottom = Vector2.new(0, 20) }

local function enter(item: GuiObject, kind: string, delay: number, from: string?)
	local T = Kit.TIMES
	local s = scaleOf(item)
	local loose = free(item)
	fade(item, 0, 1, delay, T.fade)
	if kind == "fade" then
		return T.fade
	end
	if kind == "slide" and loose then
		stop(item, "move")
		local home = item.Position
		local d = OFFSET[from or "left"] or OFFSET.left
		item.Position = home + UDim2.fromOffset(d.X, d.Y)
		run(item, "move", delay, T.slide, Quad, Out, function(e)
			item.Position = home + UDim2.fromOffset(d.X * (1 - e), d.Y * (1 - e))
		end)
		return T.slide
	end
	if kind == "fill" then -- a bar: grows from nothing to its width
		local size = item.Size
		item.Size = UDim2.new(0, 0, size.Y.Scale, size.Y.Offset)
		run(item, "size", delay, 0.3, Quad, Out, function(e)
			item.Size = UDim2.new(size.X.Scale * e, size.X.Offset * e, size.Y.Scale, size.Y.Offset)
		end)
		return 0.3
	end
	local start = (loose and kind ~= "slide") and 0.6 or 0.9
	s.Scale = start
	if kind == "spin" then
		local rest = item.Rotation
		item.Rotation = rest - 90
		run(item, "turn", delay, T.pop + 0.06, Back, Out, function(e)
			item.Rotation = rest - 90 * (1 - e)
		end)
	end
	run(item, "scale", delay, T.pop, Back, Out, function(e)
		s.Scale = start + (1 - start) * e
	end)
	return T.pop
end

export type Group = { any } -- { item or { items }, kind, gap = seconds, from = side, after = seconds }

-- Open a window: it grows in from 0.9 with a small overshoot (0.2 s) while it fades in, and the groups
-- arrive in the order given from the start, their items one after another. List only what should be
-- staged (rows, the parts of a pane, the close button, an emblem): the header, the panes and the tab
-- strip come with the window, so it is never an empty shell. Kinds: "pop" (scale with overshoot), "slide" (from = "left" | "right" | "top" |
-- "bottom"), "fade", "spin" (pop with a quarter turn: a close button), "fill" (a bar grows).
-- Every item arrives whole, with its content. Everything has started by about 0.5 s.
-- options: shell = false when something else pops the window (PanelStage) or for a pane inside an open
-- window; budget = seconds; delay = seconds before the first group (content of a pane that waits for its window).
function Kit.open(root: GuiObject, groups: { Group }?, options: { shell: boolean?, budget: number?, delay: number? }?)
	local T = Kit.TIMES
	local opt = options or {}
	local screen = root:FindFirstAncestorWhichIsA("LayerCollector") :: any
	if screen and screen.ZIndexBehavior ~= Enum.ZIndexBehavior.Sibling and not warned then
		warned = true
		warn("WindowKit: " .. screen:GetFullName() .. " uses ZIndexBehavior Global; set it to Sibling or cards draw in the wrong order")
	end
	Kit.settle(root)
	local plan = {}
	local listed = {}
	local t = opt.shell == false and 0 or 0.02 -- the content starts while the window is still growing: no empty window
	for _, g in groups or {} do
		local items = typeof(g[1]) == "Instance" and { g[1] } or g[1]
		local gap = g.gap or 0.03
		for i, item in items do
			table.insert(plan, { item = item, kind = g[2] or "fade", delay = t + (i - 1) * gap, from = g.from })
			listed[item] = true
		end
		t += math.min((#items - 1) * gap, 0.12) + (g.after or 0.04)
	end
	local last = 0
	for _, p in plan do
		last = math.max(last, p.delay)
	end
	local limit = (opt.budget or T.budget) - 0.2
	local squeeze = last > limit and limit / last or 1
	root.Visible = true
	for _, p in plan do
		fadeSet(p.item, 0, listed)
	end
	if opt.shell ~= false then
		local s = scaleOf(root)
		s.Scale = 0.9
		run(root, "scale", 0, T.shell, Back, Out, function(e)
			s.Scale = 0.9 + 0.1 * e
		end)
		fade(root, 0, 1, 0, 0.12, nil, listed)
	end
	for _, p in plan do
		enter(p.item, p.kind, (opt.delay or 0) + p.delay * squeeze, p.from)
	end
end

-- Close a window: an optional first item (the close button) pops out, then the window fades while it
-- shrinks a little, 0.22 s, and is hidden. Everything is put back for the next open.
function Kit.close(root: GuiObject, options: { first: GuiObject?, done: (() -> ())? }?)
	local T = Kit.TIMES
	local opt = options or {}
	Kit.settle(root)
	local firstScale = opt.first and scaleOf(opt.first)
	if firstScale then
		run(opt.first :: GuiObject, "scale", 0, 0.07, Quad, In, function(e)
			firstScale.Scale = 1 - math.clamp(e, 0, 1)
		end)
	end
	local s = scaleOf(root)
	local delay = firstScale and 0.05 or 0
	run(root, "scale", delay, T.close, Quad, In, function(e)
		s.Scale = 1 - 0.06 * e
	end)
	fade(root, 1, 0, delay, T.close, function()
		root.Visible = false
		Kit.settle(root)
		fadeSet(root, 1)
		s.Scale = 1
		if firstScale then
			firstScale.Scale = 1
		end
		if opt.done then
			opt.done()
		end
	end, nil, true)
end

-- ---------- keyed list: rows that tween to their new places ----------

-- A list without a UIListLayout: the kit sets each row's Y, so rows can slide, re-sort and leave.
-- container: a ScrollingFrame (its CanvasSize follows) or a Frame, with no layout object in it.
-- local list = Kit.list(scroll, { gap = 8, pad = 6 })
-- list:add("daily_1", row)      -- row: any GuiObject with a fixed height (Size.Y.Offset); its X is yours
-- list:show({ "daily_2", "daily_1" })   -- these rows, in this order: others leave, new ones arrive, the rest move
-- list:order({ ... })           -- the same rows in a new order (a claimed row is lifted and slides down)
function Kit.list(container: GuiObject, o: { gap: number?, pad: number? }?)
	local opt = o or {}
	local gap, pad = opt.gap or 8, opt.pad or 0
	local T = Kit.TIMES
	local self = { rows = {} :: { [string]: GuiObject }, keys = {} :: { string }, visible = {} :: { [string]: boolean } }

	local function setY(row: GuiObject, y: number)
		row.Position = UDim2.new(row.Position.X.Scale, row.Position.X.Offset, 0, y)
	end

	local function targets(keys: { string })
		local out, y = {}, pad
		for _, k in keys do
			local row = self.rows[k]
			if row then
				out[k] = y
				y += row.Size.Y.Offset + gap
			end
		end
		return out, math.max(y - gap + pad, 0)
	end

	function self:add(key: string, row: GuiObject)
		row.Parent = container
		self.rows[key] = row
		self.visible[key] = true
		table.insert(self.keys, key)
		local ys, height = targets(self.keys)
		setY(row, ys[key])
		if container:IsA("ScrollingFrame") then
			container.CanvasSize = UDim2.new(0, 0, 0, height)
		end
		return row
	end

	function self:get(key: string): GuiObject?
		return self.rows[key]
	end

	-- keys: the rows to show, top to bottom. instant = true skips the motion.
	function self:show(keys: { string }, instant: boolean?)
		local ys, height = targets(keys)
		local want = {}
		for _, k in keys do
			want[k] = true
		end
		-- rows that would cross each other: the one that travels farthest is lifted over the others
		local staying, hop = {}, {}
		for _, k in keys do
			local row = self.rows[k]
			if row and self.visible[k] then
				Kit.settle(row)
				table.insert(staying, { key = k, from = row.Position.Y.Offset, to = ys[k] })
			end
		end
		while not instant do
			local worst, far = nil, 0
			for _, a in staying do
				for _, b in staying do
					if a ~= b and not hop[a.key] and not hop[b.key] and (a.from - b.from) * (a.to - b.to) < 0 then
						local d = math.abs(a.to - a.from) + (a.to > a.from and 0.5 or 0)
						if d > far then
							worst, far = a, d
						end
					end
				end
			end
			if not worst then
				break
			end
			hop[worst.key] = true
		end
		for _, m in staying do
			local row = self.rows[m.key]
			if instant or m.from == m.to then
				setY(row, m.to)
			elseif hop[m.key] then
				-- lifted: drawn over the rows it passes, a little larger on the way, so the move reads as a move
				local z, sc = row.ZIndex, scaleOf(row)
				row.ZIndex = z + 10
				run(row, "move", 0, T.sort + 0.1, Quad, InOut, function(e, raw)
					setY(row, m.from + (m.to - m.from) * e)
					sc.Scale = 1 + 0.04 * math.sin(math.clamp(raw, 0, 1) * math.pi)
				end, function()
					row.ZIndex = z
					sc.Scale = 1
				end)
			else
				run(row, "move", 0, T.sort, Quad, Out, function(e)
					setY(row, m.from + (m.to - m.from) * e)
				end)
			end
		end
		local arriving = 0
		for _, k in keys do
			local row = self.rows[k]
			if row and not self.visible[k] then
				Kit.settle(row)
				row.Visible = true
				setY(row, ys[k])
				if not instant then
					enter(row, "slide", 0.1 + arriving * 0.03, "left")
					arriving += 1
				end
			end
		end
		for k, row in self.rows do
			if not want[k] and self.visible[k] then
				Kit.settle(row)
				if instant then
					row.Visible = false
				else
					fade(row, 1, 0, 0, 0.1, function()
						row.Visible = false
						fadeSet(row, 1)
					end)
				end
			end
			self.visible[k] = want[k] == true
		end
		self.keys = table.clone(keys)
		if container:IsA("ScrollingFrame") then
			container.CanvasSize = UDim2.new(0, 0, 0, height)
		end
	end

	-- scroll so the row is inside the view (a selection made by code, or a row that moved)
	function self:reveal(key: string)
		local row = self.rows[key]
		if not (row and container:IsA("ScrollingFrame")) then
			return
		end
		local k = scaleAbove(row) -- CanvasPosition is in screen px
		local top, bottom = (row.Position.Y.Offset - pad) * k, (row.Position.Y.Offset + row.Size.Y.Offset + pad) * k
		local from, view = container.CanvasPosition.Y, container.AbsoluteWindowSize.Y
		local to = math.clamp(from, bottom - view, top)
		if to ~= from then
			run(container, "scroll", 0, 0.2, Quad, Out, function(e)
				container.CanvasPosition = Vector2.new(0, from + (to - from) * math.clamp(e, 0, 1))
			end)
		end
	end

	function self:order(keys: { string }, instant: boolean?)
		self:show(keys, instant)
	end

	function self:shown(): { GuiObject } -- the visible rows, top to bottom (for Kit.open)
		local out = {}
		for _, k in self.keys do
			if self.visible[k] and self.rows[k] then
				table.insert(out, self.rows[k])
			end
		end
		return out
	end

	return self
end

-- ---------- rewards: fly to a counter, count up ----------

-- a full-size layer on top of the ScreenGui that draws above (the higher DisplayOrder of the two)
local function overlayOf(gui: GuiObject, other: GuiObject?): GuiObject
	local screen = gui:FindFirstAncestorWhichIsA("LayerCollector") :: any
	local second = other and other:FindFirstAncestorWhichIsA("LayerCollector") :: any
	if second and second ~= screen and second:IsA("ScreenGui") and screen:IsA("ScreenGui") and second.DisplayOrder > screen.DisplayOrder then
		screen = second
	end
	local layer = screen:FindFirstChild("KitOverlay")
	if not layer then
		layer = make("Frame", { Name = "KitOverlay", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 1000, Active = false }, screen)
		layer:SetAttribute("KitTransient", true) -- short-lived effects: a UI lint judges them as such
	end
	return layer :: GuiObject
end

local function centerIn(layer: GuiObject, gui: GuiObject): Vector2
	local k = 1 / scaleAbove(layer)
	return (gui.AbsolutePosition + gui.AbsoluteSize / 2 - layer.AbsolutePosition) * k
end

local function comma(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
Kit.comma = comma

-- Count a label from one number to another in 0.5 s, with a bump on arrival and a "+N" that rises and fades.
-- options: time, format = function(n) -> string, plus = false to leave the "+N" out, color for the "+N"
function Kit.count(label: TextLabel, from: number, to: number, options: { time: number?, format: ((number) -> string)?, plus: boolean?, color: Color3? }?)
	local opt = options or {}
	local format = opt.format or comma
	run(label, "count", 0, opt.time or Kit.TIMES.count, Quad, Out, function(e)
		label.Text = format(from + (to - from) * math.clamp(e, 0, 1))
	end)
	local s = scaleOf(label)
	run(label, "scale", 0, 0.09, Quad, Out, function(e)
		s.Scale = 1 + 0.15 * e
	end, function()
		run(label, "scale", 0, 0.16, Quad, Out, function(e)
			s.Scale = 1.15 - 0.15 * e
		end)
	end)
	if opt.plus ~= false and to ~= from then
		local layer = overlayOf(label)
		local c = centerIn(layer, label)
		local half = label.AbsoluteSize.Y * 0.5 / scaleAbove(layer)
		local dir = c.Y < 70 and 1 or -1 -- a counter at the top edge: the label goes under it, not off the screen
		local plus = make("TextLabel", {
			Name = "Plus",
			AnchorPoint = Vector2.new(0.5, dir > 0 and 0 or 1),
			Position = UDim2.fromOffset(c.X, c.Y + dir * half),
			Size = UDim2.fromOffset(160, 26),
			BackgroundTransparency = 1,
			Text = (to > from and "+" or "-") .. format(math.abs(to - from)),
			TextColor3 = opt.color or Color3.fromRGB(150, 255, 160),
			TextSize = math.max(label.TextSize * 1.1, 18),
			FontFace = label.FontFace,
		}, layer)
		make("UIStroke", { Color = Color3.fromRGB(14, 40, 20), Thickness = 2.5 }, plus)
		local y0 = plus.Position.Y.Offset
		local ps = scaleOf(plus)
		run(plus, "move", 0, 0.9, Quad, Out, function(e, raw)
			plus.Position = UDim2.fromOffset(c.X, y0 + dir * 26 * e)
			ps.Scale = raw < 0.12 and 0.6 + 0.5 * raw / 0.12 or math.max(1, 1.1 - (raw - 0.12))
			local a = raw < 0.7 and 0 or (raw - 0.7) / 0.3
			plus.TextTransparency = a
			;(plus:FindFirstChildOfClass("UIStroke") :: UIStroke).Transparency = a
		end, function()
			plus:Destroy()
		end)
	end
end

-- Send copies of a reward from its tile to a counter: they burst out of the tile into a loose ring
-- (0.16 s), then one after another fly on an arc and shrink into the counter, 0.4 s each and 70 ms apart;
-- onArrive(i) fires as each lands (count the counter up on the first). options: count (pieces, default 6),
-- piece = function() -> GuiObject (default: a clone of from), gap, time, arc (0-1, share of the distance,
-- default 0.25), scatter (ring radius in px, default 0.9 x the piece's size; 0 = no burst), dimSource (the
-- tile fades to 40%)
function Kit.fly(from: GuiObject, to: GuiObject, options: { count: number?, piece: (() -> GuiObject)?, gap: number?, time: number?, arc: number?, scatter: number?, dimSource: boolean?, onArrive: ((number) -> ())? }?)
	local opt = options or {}
	local T = Kit.TIMES
	local layer = overlayOf(to, from)
	local a, b = centerIn(layer, from), centerIn(layer, to)
	local n = reduced() and 1 or (opt.count or 6)
	local dur, gap = opt.time or T.fly, opt.gap or T.flyGap
	local size = from.AbsoluteSize / scaleAbove(layer)
	local ring = n > 1 and (opt.scatter or math.max(size.X, size.Y) * 0.9) or 0
	local hold = ring > 0 and 0.2 or 0
	local turn = Random.new():NextNumber(0, math.pi * 2)
	for i = 1, n do
		local piece = opt.piece and opt.piece() or from:Clone()
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Size = UDim2.fromOffset(size.X, size.Y)
		piece.Position = UDim2.fromOffset(a.X, a.Y)
		piece.Visible = false
		piece.Parent = layer
		local s = scaleOf(piece)
		-- the burst: an uneven ring around the tile
		local angle = turn + (i - 1) / n * math.pi * 2
		local start = a + Vector2.new(math.cos(angle), math.sin(angle)) * ring * (0.7 + 0.3 * ((i * 7) % 5) / 4)
		if ring > 0 then
			run(piece, "burst", 0, 0.16, Quad, Out, function(e)
				piece.Visible = true
				local p = a:Lerp(start, e)
				piece.Position = UDim2.fromOffset(p.X, p.Y)
				s.Scale = 0.4 + 0.6 * e
			end)
		end
		local span = b - start
		local side = Vector2.new(-span.Y, span.X)
		if side.Y > 0 then
			side = -side -- the arc bends up
		end
		local spread = ((i - 1) / math.max(n - 1, 1) - 0.5) * 0.5
		local mid = start + span * 0.5 + side * ((opt.arc or 0.25) + spread * 0.4)
		local tilt = (i % 2 == 0 and 1 or -1) * (10 + 4 * i)
		run(piece, "move", hold + (i - 1) * gap, dur, Sine, InOut, function(e, raw)
			piece.Visible = true
			local k = math.clamp(e, 0, 1)
			local p = start:Lerp(mid, k):Lerp(mid:Lerp(b, k), k)
			piece.Position = UDim2.fromOffset(p.X, p.Y)
			piece.Rotation = tilt * math.sin(raw * math.pi)
			s.Scale = raw < 0.3 and 1 + 0.25 * (raw / 0.3) or 1.25 - 0.85 * ((raw - 0.3) / 0.7)
		end, function()
			piece:Destroy()
			local bump = scaleOf(to)
			run(to, "scale", 0, 0.08, Quad, Out, function(e)
				bump.Scale = 1 + 0.15 * e
			end, function()
				run(to, "scale", 0, 0.14, Quad, Out, function(e)
					bump.Scale = 1.15 - 0.15 * e
				end)
			end)
			if opt.onArrive then
				opt.onArrive(i)
			end
		end)
	end
	if opt.dimSource then
		fade(from, 1, 0.4, 0, 0.15)
	end
end

-- ---------- bigger moments ----------

-- a four-point glint: two crossed bars that fade to their ends
local function glint(parent: Instance, size: number, color: Color3): Frame
	local root = make("Frame", { Name = "Glint", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, parent)
	for i = 0, 1 do
		local bar = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, math.max(2, size * 0.14)),
			Rotation = i * 90,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, root)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
		make("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
		}, bar)
	end
	local core = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.26, 0.26),
		Rotation = 45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, root)
	make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, core)
	return root
end
Kit.glint = glint

-- A burst behind a reward: rays that turn and fade, and glints thrown outward. tier 1 a few glints,
-- tier 2 rays and glints, tier 3 more of both and longer. Put it on the bigger rewards only.
-- options: tier (1-3, default 2), color, radius (px, default 1.2 x the anchor's larger side), behind (default true)
function Kit.burst(anchor: GuiObject, options: { tier: number?, color: Color3?, radius: number?, behind: boolean? }?)
	local opt = options or {}
	local tier = math.clamp(opt.tier or 2, 1, 3)
	local color = opt.color or Color3.fromRGB(255, 220, 110)
	local life = 0.6 + 0.2 * tier
	-- behind: a sibling one ZIndex under the anchor (its parent must not hold a layout or clip); else on the overlay
	local behind = opt.behind ~= false and free(anchor) and anchor.Parent ~= nil
	local size = anchor.AbsoluteSize / scaleAbove(anchor)
	local radius = opt.radius or math.max(size.X, size.Y) * 1.2
	local root = make("Frame", { Name = "Burst", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(radius * 2, radius * 2), BackgroundTransparency = 1 })
	root:SetAttribute("KitTransient", true)
	if behind then
		root.Position = anchor.Position + UDim2.fromOffset((0.5 - anchor.AnchorPoint.X) * size.X, (0.5 - anchor.AnchorPoint.Y) * size.Y)
		root.ZIndex = anchor.ZIndex - 1
		root.Parent = anchor.Parent
	else
		local layer = overlayOf(anchor)
		local c = centerIn(layer, anchor)
		root.Position = UDim2.fromOffset(c.X, c.Y)
		root.Parent = layer
	end
	if tier >= 2 and behind and not reduced() then
		local rays = make("Frame", { Name = "Rays", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, root)
		local n = tier == 2 and 10 or 14
		local bars = {}
		for i = 1, n do
			local bar = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 0, 0, radius * (i % 2 == 0 and 0.16 or 0.09)),
				Rotation = (i - 1) * 360 / n,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
			}, rays)
			local g = make("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.56, 1),
					NumberSequenceKeypoint.new(0.6, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}, bar)
			bars[i] = { bar, g }
		end
		run(rays, "turn", 0, life, Linear, Out, function(_, raw)
			rays.Rotation = 30 * raw / (0.8 / life)
			local a = raw < 0.15 and 1 - raw / 0.15 or (raw > 0.6 and (raw - 0.6) / 0.4 or 0)
			for _, b in bars do
				b[1].BackgroundTransparency = a
			end
		end)
	end
	local count = reduced() and 0 or ({ 8, 20, 30 })[tier]
	local rng = Random.new()
	for i = 1, count do
		local g = glint(root, rng:NextNumber(10, 22), i % 3 == 0 and Color3.new(1, 1, 1) or color)
		local angle = rng:NextNumber(0, math.pi * 2)
		local reach = radius * rng:NextNumber(0.5, 1.15)
		local spin = rng:NextNumber(-120, 120)
		local sc = scaleOf(g)
		run(g, "move", rng:NextNumber(0, 0.12), life * rng:NextNumber(0.7, 1), Quad, Out, function(e, raw)
			local k = math.clamp(e, 0, 1)
			g.Position = UDim2.new(0.5, math.cos(angle) * reach * k, 0.5, math.sin(angle) * reach * k + 30 * raw * raw)
			g.Rotation = spin * raw
			sc.Scale = raw < 0.2 and raw / 0.2 or 1 - math.max(raw - 0.5, 0) / 0.5
		end, function()
			g:Destroy()
		end)
	end
	task.delay(life + 0.2, function()
		root:Destroy()
	end)
	return root
end

-- a title that lands: scales 1.4 -> 1 in 0.25 s, holds, fades. hold in seconds (default 0.9)
function Kit.stamp(label: GuiObject, hold: number?)
	local s = scaleOf(label)
	label:SetAttribute("KitTransient", true)
	label.Visible = true
	fade(label, 0, 1, 0, 0.1)
	s.Scale = 1.4
	run(label, "scale", 0, 0.25, Back, Out, function(e)
		s.Scale = 1.4 - 0.4 * e
	end, function()
		fade(label, 1, 0, hold or 0.9, 0.2, function()
			label.Visible = false
			fadeSet(label, 1)
		end)
	end)
end

-- ---------- progress as steps ----------

-- A row of step slots (3/5): filled ones in the accent colour with a light top, empty ones dark.
-- local steps = Kit.steps(parent, 5, 3, { size = UDim2.new(1, 0, 0, 18), color = green }); steps:set(4) pops the new one
function Kit.steps(parent: Instance, total: number, done: number, o: { size: UDim2?, position: UDim2?, color: Color3?, empty: Color3?, gap: number?, radius: number? }?)
	local opt = o or {}
	local color, empty = opt.color or Color3.fromRGB(96, 214, 110), opt.empty or Color3.fromRGB(26, 30, 46)
	local gap = opt.gap or 6 -- outlined neighbours closer than 6 px read as one thick line
	local root = make("Frame", {
		Name = "Steps",
		Size = opt.size or UDim2.new(1, 0, 0, 16),
		Position = opt.position or UDim2.new(),
		BackgroundTransparency = 1,
	}, parent)
	local self = { root = root, slots = {} :: { Frame }, done = done }
	for i = 1, total do
		local slot = make("Frame", {
			Name = "Step" .. i,
			Size = UDim2.new(1 / total, -gap * (total - 1) / total, 1, 0),
			Position = UDim2.new((i - 1) / total, gap * (i - 1) / total, 0, 0),
			BackgroundColor3 = i <= done and color or empty,
			BorderSizePixel = 0,
		}, root)
		Kit.finish(slot, { radius = opt.radius or 5, stroke = shade(empty, -0.4), strokeWidth = 1.5, lift = i <= done and 0.18 or 0.05 })
		self.slots[i] = slot
	end
	function self:set(n: number)
		for i, slot in self.slots do
			local on = i <= n
			if on ~= (i <= self.done) then
				slot.BackgroundColor3 = on and color or empty
				if on then
					local s = scaleOf(slot)
					s.Scale = 1.35
					run(slot, "scale", (i - self.done - 1) * 0.05, 0.22, Back, Out, function(e)
						s.Scale = 1.35 - 0.35 * e
					end)
				end
			end
		end
		self.done = n
	end
	return self
end

-- ---------- idle motion and small moves ----------

local loops = {}

local function loop(gui: Instance, channel: string, period: number, step: (number) -> ())
	loops[gui] = loops[gui] or {}
	if loops[gui][channel] then
		loops[gui][channel]:Disconnect()
	end
	if reduced() then
		return
	end
	local t0 = os.clock()
	local c
	c = RunService.RenderStepped:Connect(function()
		step(((os.clock() - t0) % period) / period)
	end)
	gui.Destroying:Once(function()
		c:Disconnect()
		loops[gui] = nil
	end)
	loops[gui][channel] = c
end

-- stop the idle motion of an item (Kit.pulse, Kit.bob, Kit.sheen)
function Kit.still(gui: Instance)
	for _, c in loops[gui] or {} do
		c:Disconnect()
	end
	loops[gui] = nil
end

-- a slow breath in scale: the mark of something ready (a claim button, a gift)
function Kit.pulse(gui: GuiObject, amount: number?, period: number?)
	local s = scaleOf(gui)
	loop(gui, "pulse", period or 1.2, function(p)
		s.Scale = 1 + (amount or 0.04) * (0.5 - 0.5 * math.cos(p * math.pi * 2))
	end)
end

-- a small float up and down with a tilt: a hero emblem that sits over the frame
function Kit.bob(gui: GuiObject, px: number?, period: number?, tilt: number?)
	local home, rest = gui.Position, gui.Rotation
	loop(gui, "bob", period or 2.4, function(p)
		local w = math.sin(p * math.pi * 2)
		gui.Position = home + UDim2.fromOffset(0, -(px or 3) * w)
		gui.Rotation = rest + (tilt or 0) * w
	end)
end

-- A diagonal light band across a card or a button. once = true: one sweep now; otherwise a sweep every
-- period seconds (default 3.2). The card must come from Kit.card or Kit.button (the band lives in its Body).
function Kit.sheen(card: Instance, o: { period: number?, once: boolean?, rest: boolean? }?)
	local opt = o or {}
	local body = card:FindFirstChild("Body") or card
	local band = body:FindFirstChild("Sheen") :: Frame?
	local grad: UIGradient
	if not band then
		local corner = body:FindFirstChildOfClass("UICorner")
		band = make("Frame", { Name = "Sheen", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5 }, body)
		make("UICorner", { CornerRadius = corner and corner.CornerRadius or UDim.new(0, 12) }, band)
		grad = make("UIGradient", {
			Rotation = 20,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.38, 1),
				NumberSequenceKeypoint.new(0.5, 0.86),
				NumberSequenceKeypoint.new(0.62, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, band)
	else
		grad = band:FindFirstChildOfClass("UIGradient") :: UIGradient
	end
	if opt.rest then
		grad.Offset = Vector2.new(-0.15, 0)
		return
	end
	local function sweep()
		run(band :: Frame, "sheen", 0, 0.55, Quad, InOut, function(e)
			grad.Offset = Vector2.new(-1 + 2 * math.clamp(e, 0, 1), 0)
		end)
	end
	if opt.once then
		sweep()
		return
	end
	local period = opt.period or 3.2
	local fired = false
	grad.Offset = Vector2.new(-1, 0)
	loop(card, "sheen", period, function(p)
		if p < 0.1 and not fired then
			fired = true
			sweep()
		elseif p > 0.5 then
			fired = false
		end
	end)
end

-- move a tab indicator (or any marker) under a target in 0.2 s; both share one parent
function Kit.slideTo(marker: GuiObject, target: GuiObject, time: number?)
	local from = marker.Position
	local to = UDim2.new(target.Position.X.Scale, target.Position.X.Offset, from.Y.Scale, from.Y.Offset)
	local w0, w1 = marker.Size, UDim2.new(target.Size.X.Scale, target.Size.X.Offset, marker.Size.Y.Scale, marker.Size.Y.Offset)
	run(marker, "move", 0, time or 0.2, Quad, Out, function(e)
		marker.Position = from:Lerp(to, e)
		marker.Size = w0:Lerp(w1, e)
	end)
end

-- ---------- the screen: size by share, dim, icons, tabs ----------

-- A full-screen layer that sizes what it holds by its share of the screen, not by a device class. Lay the
-- window out at `design` px (a phone design and a larger desktop design are two calls with two sizes); the
-- layer's UIScale takes that size to share.X of the screen width or share.Y of its height, whichever comes
-- first, between min and max, and follows the screen when it changes. Returns (layer, scale).
-- local layer, k = Kit.stage(gui, Vector2.new(760, 440), { share = Vector2.new(0.8, 0.74) })
function Kit.stage(gui: LayerCollector, design: Vector2, o: { share: Vector2?, min: number?, max: number?, name: string?, z: number? }?)
	local opt = o or {}
	local share = opt.share or Vector2.new(0.8, 0.74)
	local layer = make("Frame", { Name = opt.name or "Stage", BackgroundTransparency = 1, ZIndex = opt.z or 1 }, gui)
	local scale = make("UIScale", {}, layer)
	local function fit()
		local view = (gui :: any).AbsoluteSize
		if view.X <= 0 or view.Y <= 0 then -- not laid out yet: the camera's view is close enough for the first frame
			view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		end
		local k = math.clamp(math.min(view.X * share.X / design.X, view.Y * share.Y / design.Y), opt.min or 1, opt.max or 1.6)
		scale.Scale = k
		layer.Size = UDim2.fromScale(1 / k, 1 / k)
	end
	fit()
	;(gui :: any):GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	return layer, scale.Scale
end

-- The dim behind an open window: its own ScreenGui that covers the whole screen (the notch and home-bar
-- strips too), one DisplayOrder under gui. What must stay bright (the counters) lives in gui or above it;
-- the HUD that dims lives in a ScreenGui under it. local dim = Kit.scrim(gui); dim.show(); dim.hide()
function Kit.scrim(gui: ScreenGui, o: { color: Color3?, transparency: number?, time: number? }?)
	local opt = o or {}
	local screen = make("ScreenGui", {
		Name = gui.Name .. "Scrim",
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		DisplayOrder = gui.DisplayOrder - 1,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, gui.Parent)
	local frame = make("Frame", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = opt.color or Color3.fromRGB(8, 10, 24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Active = true, -- taps do not reach the HUD under it
	}, screen)
	gui.Destroying:Once(function()
		screen:Destroy()
	end)
	local function to(target: number, done: (() -> ())?)
		local from = frame.BackgroundTransparency
		run(frame, "dim", 0, opt.time or 0.2, Quad, Out, function(e)
			frame.BackgroundTransparency = from + (target - from) * math.clamp(e, 0, 1)
		end, done)
	end
	return {
		frame = frame,
		show = function()
			frame.Visible = true
			to(opt.transparency or 0.45)
		end,
		hide = function()
			to(1, function()
				frame.Visible = false
			end)
		end,
	}
end

-- An icon from your icon pack (an image id), never a drawn one. tile = a colour: the icon sits in a rounded
-- well with the kit's finish; without it, the bare image. size in px. Returns (outer, image).
function Kit.icon(parent: Instance, image: string, o: { name: string?, size: number?, position: UDim2?, anchor: Vector2?, z: number?, order: number?, tile: Color3?, radius: number?, pad: number?, depth: number? }?)
	local opt = o or {}
	local size = opt.size or 40
	local holder: GuiObject, inside: Instance
	if opt.tile then
		holder, inside = Kit.card(parent, {
			name = opt.name or "Icon",
			size = UDim2.fromOffset(size, size),
			position = opt.position,
			anchor = opt.anchor,
			z = opt.z,
			order = opt.order,
			fill = opt.tile,
			radius = opt.radius or math.floor(size * 0.26),
			depth = opt.depth,
			lift = 0.2,
			topLight = false,
		})
	else
		holder = make("Frame", {
			Name = opt.name or "Icon",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
			Position = opt.position or UDim2.new(),
			AnchorPoint = opt.anchor or Vector2.zero,
			ZIndex = opt.z or 1,
			LayoutOrder = opt.order or 0,
		}, parent)
		inside = holder
	end
	local pad = opt.tile and (opt.pad or 0.14) or (opt.pad or 0)
	local picture = make("ImageLabel", {
		Name = "Image",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1 - 2 * pad, 1 - 2 * pad),
		Image = image,
		ScaleType = Enum.ScaleType.Fit,
	}, inside)
	return holder, picture
end

-- A tab strip: one pill slides under the labels to the chosen tab (0.2 s), the labels change colour, the
-- other tabs never repaint. items: { { key = "daily", text = "Daily", count = 3 }, ... }
-- local tabs = Kit.tabs(header, items, { size = UDim2.fromOffset(300, 34), onPick = function(key) ... end })
-- tabs.pick(key) moves the pill (and calls onPick unless silent); tabs.count(key, n) changes a count.
function Kit.tabs(parent: Instance, items: { { key: string, text: string, count: number? } }, o: { name: string?, size: UDim2?, position: UDim2?, anchor: Vector2?, z: number?, fill: Color3?, pill: Color3?, textSize: number?, font: Enum.Font?, fontFace: Font?, hit: number?, onPick: ((string) -> ())? }?)
	local opt = o or {}
	local track = opt.fill or Color3.fromRGB(28, 32, 78)
	local pillColor = opt.pill or Color3.fromRGB(255, 196, 60)
	local size = opt.size or UDim2.fromOffset(100 * #items, 34)
	local h = size.Y.Offset
	local root, content = Kit.card(parent, {
		name = opt.name or "Tabs",
		size = size,
		position = opt.position,
		anchor = opt.anchor,
		z = opt.z,
		fill = track,
		radius = math.floor(h / 2),
		lift = 0.06,
		topLight = false,
	})
	local n = #items
	local pill = Kit.card(content, {
		name = "Pill",
		size = UDim2.new(1 / n, -6, 1, -6),
		position = UDim2.new(0, 3, 0, 3),
		fill = pillColor,
		radius = math.floor(h / 2) - 3,
		strokeWidth = 0,
		lift = 0.2,
		z = 1,
	})
	local on, onLine = ink(pillColor)
	local off = shade(track, 0.72)
	local self = { root = root, pill = pill, buttons = {} :: { [string]: TextButton }, key = items[1].key }
	local texts = {}
	local function caption(item): string
		return item.count and (item.text .. "  " .. item.count) or item.text
	end
	local function paint()
		for key, button in self.buttons do
			button.TextColor3 = key == self.key and on or off
			local line = button:FindFirstChildOfClass("UIStroke") :: UIStroke
			line.Enabled = key == self.key and onLine ~= nil
		end
	end
	for i, item in items do
		local button = make("TextButton", {
			Name = item.key,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Size = UDim2.new(1 / n, -8, 1, 0), -- air between the cells: a pressed or hovered tab never reaches its neighbour
			Position = UDim2.new((i - 1) / n, 4, 0, 0),
			Text = caption(item),
			TextSize = opt.textSize or 15,
			Font = opt.font or Enum.Font.GothamBold,
			ZIndex = 2,
		}, content)
		if opt.fontFace then
			button.FontFace = opt.fontFace
		end
		make("UIStroke", { Color = onLine or on, Thickness = 1.5, Enabled = false }, button)
		if opt.hit then
			local k = scaleAbove(button)
			if h * k < opt.hit then
				local pad = make("TextButton", { Name = "Hit", Text = "", BackgroundTransparency = 1, AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, math.ceil((opt.hit + 1) / k)), ZIndex = 3 }, button)
				pad:SetAttribute("KitHit", true)
			end
		end
		self.buttons[item.key] = button
		texts[item.key] = item
		Kit.target(button).Activated:Connect(function()
			self.pick(item.key)
		end)
	end
	function self.pick(key: string, silent: boolean?)
		local index = 0
		for i, item in items do
			if item.key == key then
				index = i
			end
		end
		if index == 0 or key == self.key then
			return
		end
		self.key = key
		local from, to = pill.Position.X.Scale, (index - 1) / n
		local colors = {}
		for name, button in self.buttons do
			colors[name] = button.TextColor3
		end
		run(pill, "move", 0, 0.2, Quad, Out, function(e)
			local k = math.clamp(e, 0, 1)
			pill.Position = UDim2.new(from + (to - from) * e, 3, 0, 3)
			for name, button in self.buttons do -- the labels change with the pill, never a frame of dark on dark
				button.TextColor3 = colors[name]:Lerp(name == key and on or off, k)
			end
		end, paint)
		if opt.onPick and not silent then
			opt.onPick(key)
		end
	end
	function self.count(key: string, value: number)
		local item = texts[key]
		if item then
			item.count = value
			self.buttons[key].Text = caption(item)
		end
	end
	paint()
	return self
end

Kit.run = run -- run(owner, channel, delay, duration, style, direction, step(eased, raw), done): your own motion on the same clock

return Kit
