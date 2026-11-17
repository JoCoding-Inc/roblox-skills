--!nonstrict
-- impact_frames: screen-wide impact states (33-100 ms each), played as a block of 3-5 states (0.15-0.25 s), the
-- "dark before the hit" beat (0.25-0.7 s) and a white-out that decays (the peak of a burst). Client only.
-- Those ranges were read from four public showcase clips (30 or 60 fps, 2026-11-17); roblox-feel-audio-vfx
-- section 3e. Ran in Studio 0.747 and 0.748 Play, 2026-11-18.
--
-- ImpactFrames.block(states, opts?) -> clock. states = { { kind, dur, ... } }, kinds:
--   "white"   ColorCorrection Brightness +1 (pure white, the world and every effect)            L 1.0
--   "black"   ColorCorrection Brightness -1                                                       L 0.03
--   "field"   flat colour field with the characters as flat silhouettes: a Neon plane 0.6 studs in front of
--             the camera hides the world, Highlights (AlwaysOnTop, fill only) draw the characters over it.
--             { color = Color3, sil = Color3 }                                                     L ~ field
--   "invert"  ColorCorrection Contrast -2 (+ Saturation -1, Brightness -0.15: a deep grey negative)  L ~ 0.45
--   "mono"    the world in hard black and white (Saturation -1, Contrast 3), the hue kept only on the
--             subjects given in opts.keep (Highlight fill, which ColorCorrection does not touch)   L ~ 0.6
--   "scene"   nothing (a state that shows the plain frame)                                          L 0.5
-- ImpactFrames.dark(opts) -> clock: the beat before the hit; the world goes near black (Lighting blackout: sun,
--   ambient, fog to 0) while emissive layers (Neon, particles with LightEmission, beams) keep glowing;
--   opts.dur (default 0.5), opts.silhouette = { models } adds a navy Highlight so the bodies read as shapes.
-- ImpactFrames.whiteout(opts) -> clock: Brightness +1 for opts.hold (default 0.1 s), then decays to 0 over
--   opts.decay (default 0.17 s = 10 frames at 60 fps).
-- Common opts: clock/at (embed in a cutscene clock), subjects = { models } for silhouettes (default the two
-- stage dummies).
--
-- Safety (flash_safety.luau): every state change asks Safety.request with its screen value L; a refused state
-- keeps the previous one on screen (so the count of flashes never passes 3 in any second of clock time). With
-- reduced motion (Safety.reduced()) a block, a dark beat or a white-out is replaced by one soft dim: Brightness
-- -0.25 in 0.08 s, back over 0.3 s.
--
-- Measured (Studio 0.747 Play, 2026-11-18): ColorCorrection under the Camera recolours every part, particle,
-- Neon glow, beam and BillboardGui, but not ScreenGuis and not Highlight fills; Highlight with AlwaysOnTop draws
-- through a part in front of it; Saturation -1 turned the cyan Neon ball pink-white (not grey) until Contrast 3
-- was added; Contrast -2 inverts (cyan turns red-orange); Brightness +1 with a cyan TintColor gives a flat cyan
-- frame but tints the silhouettes too, hence the plane + Highlight field; a Neon plane 15 studs ahead was cut by
-- the floor at the bottom of a low shot, 0.6 studs ahead covers the frame.
-- Limits: silhouettes are the rig's own outline (flat, no inner lines); the invert of a grey stage is mostly grey
-- (a negative reads only on the figures and the effects); the dark beat writes Lighting (Brightness, ambients,
-- fog, exposure) and puts it back, so other code must not change Lighting while it runs.

local Lighting = game:GetService("Lighting")

local FxClock = require(script.Parent.fx_clock)
local Safety = require(script.Parent.flash_safety)
local Stage = require(script.Parent.cine_stage)

local ImpactFrames = {}

local H = Stage.HUE
ImpactFrames.L = { white = 1, black = 0.03, scene = 0.5, invert = 0.45, mono = 0.6 }

local function lum(c: Color3): number
	return (c.R + c.G + c.B) / 3
end

local function subjects(opts)
	return opts.subjects or { Stage.hero(), Stage.target() }
end

-- One CC effect per element window, under the Camera (local only), removed at cleanup.
local function makeCC(c)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "CineImpactCC"
	cc.Parent = workspace.CurrentCamera
	c:onCleanup(function()
		cc:Destroy()
	end)
	return cc
end

local function softDim(c, t0)
	local cc = makeCC(c)
	c:span(t0, t0 + 0.4, function(u)
		local x = u * 0.4
		cc.Brightness = if x < 0.08 then -0.25 * x / 0.08 else -0.25 * (1 - FxClock.smooth(0.08, 0.4, x))
	end)
end

local function stateL(s): number
	if s.kind == "field" then
		local fl = lum(s.color or H.cyan)
		local sl = lum(s.sil or H.ink)
		return fl * 0.85 + sl * 0.15 -- the silhouettes cover about 15 % of a medium frame
	end
	return ImpactFrames.L[s.kind] or 0.5
end
ImpactFrames.stateL = stateL

function ImpactFrames.block(states, opts)
	opts = opts or {}
	local total = 0
	for _, s in states do
		total += s.dur
	end
	local c, root, own = FxClock.attach("ImpactBlock", total + 0.45, opts)
	local cam = workspace.CurrentCamera
	local cc, plane = nil, nil
	local hls = {}

	local function clear()
		cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = 0, 0, 0, Color3.new(1, 1, 1)
		if plane then
			plane.Transparency = 1
		end
		for _, h in hls do
			h.Enabled = false
		end
	end

	local function apply(s)
		clear()
		if s.kind == "white" then
			cc.Brightness = 1
		elseif s.kind == "black" then
			cc.Brightness = -1
		elseif s.kind == "invert" then
			-- r1: Saturation -1 with a cyan tint read as a flat light-blue card; a grey negative reads as a negative
			-- r2: the grey negative was low contrast (mid-grey sky, light figures); Brightness -0.15 deepens the field
			cc.Contrast = -2
			cc.Brightness = s.bright or -0.15
			cc.Saturation = s.sat or -1
			cc.TintColor = s.tint or Color3.new(1, 1, 1)
		elseif s.kind == "mono" then
			cc.Saturation = -1
			cc.Contrast = 3
			for _, h in hls do
				if h:GetAttribute("keep") then
					h.FillColor = s.keepColor or H.cyan
					h.Enabled = true
				end
			end
		elseif s.kind == "field" then
			if not plane then
				plane = c:part({ Name = "FieldPlane", Size = Vector3.new(6, 6, 0.02), Material = Enum.Material.Neon })
			end
			plane.Color = s.color or H.cyan
			plane.Transparency = 0
			plane.CFrame = cam.CFrame * CFrame.new(0, 0, -0.6)
			for _, h in hls do
				h.FillColor = s.sil or H.ink
				h.Enabled = true
			end
		end
	end

	local function highlight(m, keep)
		local h = Instance.new("Highlight")
		h.Adornee = m
		h.FillTransparency = 0
		h.OutlineTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Enabled = false
		if keep then
			h:SetAttribute("keep", true)
		end
		h.Parent = c.model
		table.insert(hls, h)
	end

	-- Everything is decided when the block starts (lazy), so the flash count sees what ran before it.
	c:at(0, function()
		if Safety.reduced() then
			softDim(c, 0)
			return
		end
		-- fit: drop states from the end until the sequence (with the return to the scene) passes the flash cap;
		-- the kept states stretch to the same total length
		local t0 = root.t
		local function seq(list)
			local items, tt = {}, 0
			for _, s in list do
				table.insert(items, { t = t0 + tt, L = stateL(s) })
				tt += s.dur
			end
			table.insert(items, { t = t0 + total, L = opts.endL or ImpactFrames.L.scene })
			return items
		end
		local fitted = table.clone(states)
		while #fitted > 0 and not Safety.fits(root, seq(fitted)) do
			table.remove(fitted)
		end
		if #fitted == 0 then
			print(string.format("FLASHFIT|%.3f|block replaced by a soft dim", t0))
			softDim(c, 0)
			return
		end
		if #fitted < #states then
			local kept = 0
			for _, s in fitted do
				kept += s.dur
			end
			for i, s in fitted do
				fitted[i] = table.clone(s)
				fitted[i].dur = s.dur * total / kept
			end
			print(string.format("FLASHFIT|%.3f|kept %d of %d states", t0, #fitted, #states))
		end
		cc = makeCC(c)
		for _, m in subjects(opts) do
			highlight(m, false)
		end
		for _, m in opts.keep or {} do
			highlight(m, true)
		end
		local tt = 0
		for _, s in fitted do
			c:at(tt, function()
				if Safety.request(root, root.t, stateL(s), "impact:" .. s.kind) then
					apply(s)
				end
				-- refused: the previous state stays on screen
			end)
			tt += s.dur
		end
		c:at(total, function()
			Safety.request(root, root.t, opts.endL or ImpactFrames.L.scene, "impact:end")
			clear()
		end)
		c:every(function(t)
			if plane and plane.Transparency < 1 then
				plane.CFrame = cam.CFrame * CFrame.new(0, 0, -0.6)
			end
		end)
	end)
	if own then
		root:play()
	end
	return root
end

function ImpactFrames.whiteout(opts)
	opts = opts or {}
	local hold = opts.hold or 0.1
	local decay = opts.decay or 0.17
	local c, root, own = FxClock.attach("WhiteOut", hold + decay + 0.42, opts)
	if Safety.reduced() then
		softDim(c, 0)
	else
		local cc = makeCC(c)
		local allowed = false
		c:at(0, function()
			local t0 = root.t
			allowed = Safety.fits(root, { { t = t0, L = 1 }, { t = t0 + hold + decay * 0.3, L = 0.5 } })
				and Safety.request(root, t0, 1, "whiteout")
			if not allowed then
				-- refused: a soft bright pulse below the flash threshold instead
				cc.Brightness = 0.15
				c:span(0, 0.25, function(u)
					cc.Brightness = 0.15 * (1 - u)
				end)
				return
			end
			if allowed then
				cc.Brightness = 1
			end
		end)
		local logged = false
		c:span(hold, hold + decay, function(u)
			if not allowed then
				return
			end
			-- exposure-like decay: fast at first
			local b = 1 - FxClock.outCubic(u)
			cc.Brightness = b
			if not logged and b < 0.45 then
				logged = true
				Safety.request(root, root.t, 0.5, "whiteout:decay")
			end
		end)
	end
	if own then
		root:play()
	end
	return root
end

function ImpactFrames.dark(opts)
	opts = opts or {}
	local dur = opts.dur or 0.5
	local c, root, own = FxClock.attach("DarkBeat", dur + 0.45, opts)
	if Safety.reduced() then
		softDim(c, 0)
		if own then
			root:play()
		end
		return root
	end
	local saved = {}
	local keys = { "Brightness", "Ambient", "OutdoorAmbient", "FogColor", "ExposureCompensation" }
	local hls = {}
	local fadeIn = opts.fadeIn or 0.08
	c:at(0, function()
		for _, k in keys do
			saved[k] = Lighting[k]
		end
		Safety.request(root, root.t, 0.08, "dark")
		for _, m in opts.silhouette or {} do
			local h = Instance.new("Highlight")
			h.Adornee = m
			h.FillColor = H.navy
			h.FillTransparency = 1
			h.OutlineColor = H.blue
			h.OutlineTransparency = 1
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Parent = c.model
			table.insert(hls, h)
		end
	end)
	local function setDark(k)
		-- k = 0 normal .. 1 dark
		Lighting.Brightness = saved.Brightness * (1 - k)
		Lighting.Ambient = saved.Ambient:Lerp(Color3.fromRGB(4, 6, 12), k)
		Lighting.OutdoorAmbient = saved.OutdoorAmbient:Lerp(Color3.fromRGB(4, 6, 12), k)
		Lighting.FogColor = saved.FogColor:Lerp(Color3.fromRGB(6, 9, 18), k)
		Lighting.ExposureCompensation = saved.ExposureCompensation - 1.2 * k
		for _, h in hls do
			h.FillTransparency = 1 - 0.85 * k
			h.OutlineTransparency = 1 - 0.6 * k
		end
	end
	c:span(0, dur, function(u)
		-- r3: the span also runs at u = 1 after the end event, which left the world dark until cleanup
		if u >= 1 then
			return
		end
		local x = u * dur
		setDark(if fadeIn > 0 then FxClock.smooth(0, fadeIn, x) else 1)
	end)
	local restored = false
	c:at(dur, function()
		setDark(0)
		restored = true
		Safety.request(root, root.t, opts.endL or 0.5, "dark:end")
	end)
	c:onCleanup(function()
		-- only when cut short: a later dark beat may own Lighting by now
		if saved.Brightness and not restored then
			setDark(0)
		end
	end)
	if own then
		root:play()
	end
	return root
end

-- The default block of the demo: white -> cyan field with black silhouettes -> cyan negative -> navy field with
-- white silhouettes (0.21 s). Luminance 1 -> 0.6 -> 0.55 -> 0.2: one up and one down change, then the return.
ImpactFrames.DEFAULT = {
	{ kind = "white", dur = 0.05 },
	{ kind = "field", dur = 0.05, color = H.cyan, sil = H.ink },
	{ kind = "invert", dur = 0.05 },
	{ kind = "field", dur = 0.06, color = H.blue, sil = H.white },
}

return ImpactFrames
