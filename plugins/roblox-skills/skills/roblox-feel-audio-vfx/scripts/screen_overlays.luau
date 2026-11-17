--!nonstrict
-- screen_overlays: radial speed lines, letterbox bars and a vignette, drawn from UI primitives (no images) in one
-- full-screen ScreenGui "CineScreen" (IgnoreGuiInset, ScreenInsets None: the bars and lines must reach the real
-- screen edges). Client only, on the fx clock. Post effects never touch GuiObjects (docs), so these stay black
-- or white through every impact state.
--
-- ScreenOverlays.speedLines(opts?) -> clock
--   opts.focus    Vector3 (world point the lines converge on) or Vector2 (screen fraction); default centre
--   opts.dur      s on screen (default 0.27 = 16 frames), opts.step re-shape period (default 0.025 = 1.5 f)
--   opts.count    lines (default 56), opts.color (default black), opts.clear inner clear radius as a fraction
--                 of the frame height (default 0.3)
-- ScreenOverlays.letterbox(opts?) -> clock   bars of opts.size (fraction of the screen height, default 0.11)
--   slide in over opts.inDur (0.25 s), hold, slide out over opts.outDur (0.3 s) at opts.dur (default 3 s)
-- ScreenOverlays.vignette(opts?) -> clock    4 edge gradients, opts.strength (0..1, default 0.55), opts.dur
-- ScreenOverlays.gui() -> ScreenGui           the shared ScreenGui (created on demand)
-- All take opts.clock / opts.at. With reduced motion the speed lines are drawn once and not re-shaped.
--
-- Build of a speed line: a thin Frame rotated about its centre to point at the focus, laid from the clear radius
-- to past the farthest screen corner, with a UIGradient on transparency (solid at the screen edge, gone at the
-- inner end) so each line reads as a taper. Widths 1.5-6 px at a 360 px high screen, scaled by screen height.
-- Built to what four public showcase clips showed (read 2026-11-17; frame counts at each clip's own rate, 30 or 60
-- fps): black radial lines converging on the head, 16 frames, a new state every 1-2 frames, reaching the frame
-- edges. roblox-feel-audio-vfx section 3e; ran in Studio 0.747 and 0.748 Play, 2026-11-18, desktop and the Samsung
-- Galaxy A06 Device Simulator preset. Measured: a new ScreenGui has ZIndexBehavior Global, so a later layer's
-- children drew over the letterbox bars; Sibling (set here) fixes it. White lines vanished on the light-grey stage
-- until a thin navy edge was added.
-- Limits: lines are uniform straight tapers (drawn lines vary in width and end in a brush stroke); up to 56
-- Frames re-laid every 1.5 frames, not measured on a real phone.

local Players = game:GetService("Players")

local FxClock = require(script.Parent.fx_clock)
local Safety = require(script.Parent.flash_safety)
local Stage = require(script.Parent.cine_stage)

local ScreenOverlays = {}

function ScreenOverlays.gui(): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local g = pg:FindFirstChild("CineScreen")
	if not g then
		g = Instance.new("ScreenGui")
		g.Name = "CineScreen"
		g.IgnoreGuiInset = true
		g.ScreenInsets = Enum.ScreenInsets.None
		g.ResetOnSpawn = false
		g.DisplayOrder = 50
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- r2: speed lines drew over the letterbox bars
		g.Parent = pg
	end
	return g
end

-- A container Frame for one element window, removed at cleanup.
function ScreenOverlays.layer(c, name: string, z: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.ZIndex = z or 1
	f.Parent = ScreenOverlays.gui()
	c:onCleanup(function()
		f:Destroy()
	end)
	return f
end

local function screenPoint(focus): Vector2
	local cam = workspace.CurrentCamera
	local vp = cam.ViewportSize
	if typeof(focus) == "Vector3" then
		local p, onScreen = cam:WorldToViewportPoint(focus)
		if p.Z > 0 then
			return Vector2.new(math.clamp(p.X, 0, vp.X), math.clamp(p.Y, 0, vp.Y))
		end
		return vp / 2
	elseif typeof(focus) == "Vector2" then
		return Vector2.new(focus.X * vp.X, focus.Y * vp.Y)
	end
	return vp / 2
end

function ScreenOverlays.speedLines(opts)
	opts = opts or {}
	local dur = opts.dur or 0.27
	local step = opts.step or 0.025
	local n = opts.count or 56
	local c, root, own = FxClock.attach("SpeedLines", dur + 0.02, opts)
	local rng = Random.new(opts.seed or 61)
	local lines = {}
	local layer
	c:at(0, function()
		layer = ScreenOverlays.layer(c, "SpeedLines", 3)
		for i = 1, n do
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.BackgroundColor3 = opts.color or Color3.new(0, 0, 0)
			local g = Instance.new("UIGradient")
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.35, 0.55),
				NumberSequenceKeypoint.new(1, 0),
			})
			g.Parent = f
			local col = opts.color or Color3.new(0, 0, 0)
			if col.R + col.G + col.B > 2 then
				-- r1: white lines vanished on the light-grey stage; a thin navy edge keeps them on any ground
				local st = Instance.new("UIStroke")
				st.Color = Stage.HUE.navy
				st.Thickness = 1.5
				st.Transparency = 0.25
				st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				g:Clone().Parent = st -- the edge fades with the line
				st.Parent = f
			end
			f.Parent = layer
			lines[i] = f
		end
	end)
	local lastK = -1
	c:every(function(t)
		if not layer then
			return
		end
		layer.Visible = t < dur
		local k = math.floor(t / step)
		if Safety.reduced() and lastK >= 0 then
			return
		end
		if k == lastK then
			return
		end
		lastK = k
		local vp = workspace.CurrentCamera.ViewportSize
		local fp = screenPoint(opts.focus)
		local far = 0
		for _, corner in { Vector2.zero, Vector2.new(vp.X, 0), Vector2.new(0, vp.Y), vp } do
			far = math.max(far, (corner - fp).Magnitude)
		end
		local px = vp.Y / 360
		local clear = (opts.clear or 0.3) * vp.Y
		local srng = Random.new((opts.seed or 61) * 977 + k)
		for i, f in lines do
			local th = (i - 1 + srng:NextNumber(-0.45, 0.45)) / n * math.pi * 2
			local r0 = clear * srng:NextNumber(0.85, 1.6)
			local r1 = far + 10
			local d = Vector2.new(math.cos(th), math.sin(th))
			local mid = fp + d * (r0 + r1) / 2
			f.Size = UDim2.fromOffset(r1 - r0, srng:NextNumber(1.5, 6) * px)
			f.Position = UDim2.fromOffset(mid.X, mid.Y)
			f.Rotation = math.deg(th)
			f.Visible = srng:NextNumber() < 0.85
		end
	end)
	if own then
		root:play()
	end
	return root
end

function ScreenOverlays.letterbox(opts)
	opts = opts or {}
	local size = opts.size or 0.11
	local inDur, outDur = opts.inDur or 0.25, opts.outDur or 0.3
	local dur = opts.dur or 3
	local c, root, own = FxClock.attach("Letterbox", dur + 0.02, opts)
	local top, bot
	c:at(0, function()
		local layer = ScreenOverlays.layer(c, "Letterbox", 5)
		top = Instance.new("Frame")
		top.BorderSizePixel = 0
		top.BackgroundColor3 = Color3.new(0, 0, 0)
		top.Size = UDim2.fromScale(1, size)
		top.Parent = layer
		bot = top:Clone()
		bot.AnchorPoint = Vector2.new(0, 1)
		bot.Parent = layer
	end)
	c:every(function(t)
		if not top then
			return
		end
		local u = FxClock.outCubic(math.clamp(t / inDur, 0, 1)) * (1 - FxClock.inOutSine(math.clamp((t - (dur - outDur)) / outDur, 0, 1)))
		top.Position = UDim2.fromScale(0, -size * (1 - u))
		bot.Position = UDim2.fromScale(0, 1 + size * (1 - u))
	end)
	if own then
		root:play()
	end
	return root
end

function ScreenOverlays.vignette(opts)
	opts = opts or {}
	local dur = opts.dur or 3
	local strength = opts.strength or 0.55
	local c, root, own = FxClock.attach("Vignette", dur + 0.02, opts)
	local edges = {}
	c:at(0, function()
		local layer = ScreenOverlays.layer(c, "Vignette", 2)
		-- size, position, gradient rotation (the gradient runs solid at the edge -> clear inward)
		local spec = {
			{ UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0), 90 },
			{ UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.7), -90 },
			{ UDim2.fromScale(0.22, 1), UDim2.fromScale(0, 0), 0 },
			{ UDim2.fromScale(0.22, 1), UDim2.fromScale(0.78, 0), 180 },
		}
		for _, s in spec do
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.BackgroundColor3 = opts.color or Color3.new(0, 0, 0)
			f.Size = s[1]
			f.Position = s[2]
			local g = Instance.new("UIGradient")
			g.Rotation = s[3]
			g.Parent = f
			f.Parent = layer
			table.insert(edges, g)
		end
	end)
	c:every(function(t)
		local u = FxClock.smooth(0, 0.3, t) * (1 - FxClock.smooth(dur - 0.3, dur, t))
		local a = 1 - strength * u
		for _, g in edges do
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, a),
				NumberSequenceKeypoint.new(0.45, 1 - (1 - a) * 0.35),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
	end)
	if own then
		root:play()
	end
	return root
end

ScreenOverlays.CAPTURE_TIMES = { 0.1, 0.3, 0.6, 0.617, 0.633, 0.65, 0.667, 0.7, 0.8, 1.2, 1.6, 2.0 }

-- The demo: letterbox and vignette in, speed lines on the hero's head at 0.6 s, out at 2.2 s.
function ScreenOverlays.demo(hero, opts)
	opts = opts or {}
	local c, root, own = FxClock.attach("OverlaysDemo", 2.3, opts)
	ScreenOverlays.letterbox({ clock = c, at = 0, dur = 2.2 })
	ScreenOverlays.vignette({ clock = c, at = 0, dur = 2.2, strength = 0.6 })
	ScreenOverlays.speedLines({ clock = c, at = 0.6, focus = hero:FindFirstChild("Head").Position, color = Color3.new(0, 0, 0) })
	ScreenOverlays.speedLines({ clock = c, at = 1.3, dur = 0.27, focus = hero:FindFirstChild("Head").Position, color = Color3.new(1, 1, 1), seed = 9, count = 44, clear = 0.36 })
	if own then
		root:play()
	end
	return root
end

return ScreenOverlays
