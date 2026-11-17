--!nonstrict
-- lettering: big sound-effect words that pop in at full size, jitter every frame while held and fade in 2-3
-- frames. Our own short words in Latin letters, a bold display font (Bangers, a built-in Roblox font) with a
-- thick black stroke, a white-to-cyan fill and a navy drop layer. Screen space (ScreenGui "CineScreen"), placed
-- by screen fraction and tilted, so it fits any device; sized from the screen height. Client only, fx clock.
-- roblox-feel-audio-vfx section 3e; ran in Studio 0.747 and 0.748 Play, 2026-11-18 (desktop and the Samsung
-- Galaxy A06 Device Simulator preset: KRAK! 78 px and VMM 47 px tall on a 338 px viewport, both readable).
--
-- Lettering.play(words, opts?) -> clock. words = { { text, pos = Vector2 (screen fraction of the centre),
--   rot = deg, size = fraction of the screen height (default 0.2), at = s, hold = s (default 1.4),
--   fade = s (default 0.05 = 3 frames) } }
-- opts.clock / opts.at / opts.seed. With reduced motion the jitter is off (the pop and fade stay).
--
-- Beat per word: frame 0 pops in at 1.25x scale, 1.0x by frame 2 (0.033 s); every frame while held the word
-- moves by up to 0.4 % of the screen height and turns by up to 0.6 degrees (re-drawn every 1/60 s of clock time);
-- it fades in over 2 frames (transparency 0.6, 0.3, 0; `fadeIn`) and out over `fade`.
-- Built to what four public showcase clips showed (read 2026-11-17; frame counts at each clip's own rate, 30 or 60
-- fps): each word about 0.35-0.45x character height, tilted 10-20 deg, a gradient fill, a thick black outline and a
-- thin white inner edge, popping in at full size inside the flash, held about 71 frames (2.4 s), fading over 2-3
-- frames, a jitter of 1-3 px at 1280 wide every frame and no rotation jitter (ours adds a little). The words, font
-- and colours here are our own.
-- What failed while building: the word was fully opaque on its first frame (fade-in added); a 1.6 deg rotation
-- jitter read as wobble (0.6 now); a word placed on the hero's head.
-- Limits: one UIStroke only, so no thin inner white edge; a built-in font, not drawn lettering.

local FxClock = require(script.Parent.fx_clock)
local Safety = require(script.Parent.flash_safety)
local Stage = require(script.Parent.cine_stage)
local ScreenOverlays = require(script.Parent.screen_overlays)

local Lettering = {}

local H = Stage.HUE
Lettering.FONT = Font.fromEnum(Enum.Font.Bangers)
Lettering.CAPTURE_TIMES = { 0.0, 0.017, 0.033, 0.05, 0.3, 0.317, 0.333, 1.0, 1.42, 1.433, 1.45, 1.47 }

local function label(parent, text, color, strokeColor, stroke, z)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Size = UDim2.fromScale(1, 1)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.FontFace = Lettering.FONT
	t.Text = text
	t.TextScaled = true
	t.TextColor3 = color
	t.ZIndex = z
	local s = Instance.new("UIStroke")
	s.Color = strokeColor
	s.Thickness = stroke
	s.LineJoinMode = Enum.LineJoinMode.Miter
	s.Parent = t
	t.Parent = parent
	return t, s
end

function Lettering.play(words, opts)
	opts = opts or {}
	local last = 0
	for _, w in words do
		last = math.max(last, (w.at or 0) + (w.hold or 1.4) + (w.fade or 0.05))
	end
	local c, root, own = FxClock.attach("Lettering", last + 0.05, opts)
	local rng = Random.new(opts.seed or 71)
	local items = {}
	c:at(0, function()
		local layer = ScreenOverlays.layer(c, "Lettering", 8)
		for i, w in words do
			local holder = Instance.new("Frame")
			holder.BackgroundTransparency = 1
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Visible = false
			holder.ZIndex = 8
			local sc = Instance.new("UIScale")
			sc.Parent = holder
			holder.Parent = layer
			-- navy drop layer, then the main fill with a white-to-cyan gradient and a black stroke
			local drop, dropS = label(holder, w.text, H.navy, H.navy, 1, 8)
			local main, mainS = label(holder, w.text, H.white, Color3.new(0, 0, 0), 1, 9)
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, H.white),
				ColorSequenceKeypoint.new(0.45, H.hot),
				ColorSequenceKeypoint.new(1, H.cyan),
			})
			g.Rotation = 90
			g.Parent = main
			items[i] = { w = w, holder = holder, sc = sc, main = main, mainS = mainS, drop = drop, dropS = dropS }
		end
	end)
	c:every(function(t)
		local vp = workspace.CurrentCamera.ViewportSize
		local k = math.floor(t * 60)
		for i, it in items do
			local w = it.w
			local t0 = w.at or 0
			local hold = w.hold or 1.4
			local fade = w.fade or 0.05
			local age = t - t0
			if age < 0 or age > hold + fade then
				it.holder.Visible = false
				continue
			end
			it.holder.Visible = true
			local hpx = (w.size or 0.2) * vp.Y
			local wpx = hpx * 0.62 * #w.text
			it.holder.Size = UDim2.fromOffset(wpx, hpx)
			local stroke = math.max(2, hpx * 0.07)
			it.mainS.Thickness = stroke
			it.dropS.Thickness = stroke
			it.drop.Position = UDim2.new(0.5, stroke * 0.9, 0.5, stroke * 1.1)
			-- pop: 1.25 -> 1.0 over 2 frames
			it.sc.Scale = 1 + 0.25 * (1 - FxClock.smooth(0, 0.033, age))
			local jx, jy, jr = 0, 0, 0
			if not Safety.reduced() then
				local r = Random.new((opts.seed or 71) * 131 + i * 7 + k)
				jx = r:NextNumber(-1, 1) * 0.004 * vp.Y
				jy = r:NextNumber(-1, 1) * 0.004 * vp.Y
				jr = r:NextNumber(-1, 1) * 0.6 -- r1: 1.6 deg read as wobble; the clips have none
			end
			local p = w.pos or Vector2.new(0.5, 0.3)
			it.holder.Position = UDim2.fromOffset(p.X * vp.X + jx, p.Y * vp.Y + jy)
			it.holder.Rotation = (w.rot or 0) + jr
			-- r1: the word was fully opaque on its first frame; it now fades in over 2 frames (0.6, 0.3, 0)
			local fadeIn = w.fadeIn or 0.033
			local a = math.max(0.6 * (1 - math.clamp(age / fadeIn, 0, 1)), FxClock.smooth(hold, hold + fade, age))
			it.main.TextTransparency = a
			it.drop.TextTransparency = a
			it.mainS.Transparency = a
			it.dropS.Transparency = a
		end
	end)
	if own then
		root:play()
	end
	return root
end

-- The demo: two words around the dummies.
function Lettering.demo(opts)
	return Lettering.play({
		-- r2: KRAK! sat on the hero's head; moved into the empty sky and both words sized up for phones
		{ text = "KRAK!", pos = Vector2.new(0.42, 0.24), rot = -12, at = 0, hold = 1.4, size = 0.22 },
		{ text = "VMM", pos = Vector2.new(0.8, 0.62), rot = 9, at = 0.3, hold = 1.1, size = 0.14 },
	}, opts)
end

return Lettering
