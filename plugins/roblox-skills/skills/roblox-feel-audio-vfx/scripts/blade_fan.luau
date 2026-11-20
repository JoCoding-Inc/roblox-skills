--!nonstrict
-- BladeFan (client): a blade trail drawn as a fan of curved beam bands, for fast sword cuts.
--
-- The sweep is cut into bands along the blade, guard to tip. Each band is a chain of flat beams through the band's
-- middle at the blade now and every `grid` seconds back. A band keeps its full width for 55 % of its life, then
-- narrows to a point, and the bands live different times (longer toward the tip, every other one shorter): one sheet
-- at the blade that ends in a row of pointed tails of unequal length. A band is white at the blade, the body colour
-- from 14 % of its life on and the tail colour at its end; a white core rides the outer half of the blade for a very
-- short time. Only points cut inside a swing window (fan:swing) draw, and only where the tip crosses the blade's line
-- faster than `minSpeed`, so wind-ups and holds leave nothing.
--
-- The blade's past is a record of its guard and tip at every drawn frame, read back on the grid: between two frames
-- the blade's direction turns on the shortest arc and the guard turns with it about the point that move implies (a
-- hand on a swinging arm), so a fast cut draws an arc, not a chord. Measured against the exact poses of the demo's
-- cuts (fast parts of 0.035 s, sampled at 60 fps): 0.29 studs mean error at the tip, against 0.35 with the guard
-- moved in a line and 0.38 with the grip frame's rotation interpolated. A turn of more than 115 degrees between two
-- frames whose next frame turns the other way went the long way round, and is redrawn so from that next frame on.
-- Cuts that fast need 60 fps: at 30 fps the mean error was 1.25 studs, so give the fast part of a cut at least 3-4
-- frames of the frame rate it must hold.
--
-- Built on a dual-blade combo demo in Studio 0.748 Play (2026-11-20); the owner approved its look on video. The
-- defaults are chosen by eye for cuts whose fast part takes 0.035-0.05 s: set `coreLife` to about a third of your
-- cuts' sweep time and keep `life` near 0.15-0.2 s. Guide: roblox-feel-audio-vfx section 3j.
--
--   local fan = BladeFan.new(guardAttachment, tipAttachment, { color = Color3.fromRGB(80, 150, 255) })
--   fan:swing(0.1)        -- at the first frame of a cut: points cut from just before now to 0.1 s on draw
--   fan:swing(0.25, 0.6)  -- a spin: its bands live 0.6 of their life
--   fan:setSpeed(0)       -- hit-stop: the fan holds; fan:setSpeed(1) goes on (0.2 for slow motion)
--   fan:destroy()

local RunService = game:GetService("RunService")

local BladeFan = {}
BladeFan.__index = BladeFan

BladeFan.defaults = {
	bands = 7, -- bands along the blade (4 for other players' blades)
	life = 0.15, -- seconds the band at the tip lives (0.2 for a greatsword's 0.16 s sweep)
	coreLife = 0.014, -- seconds the white core lives: about a third of the sweep time; 0 for no core
	grid = 1 / 150, -- seconds between chain points (1 / 90 for other players' blades)
	color = Color3.fromRGB(240, 50, 95), -- the body
	tail = Color3.fromRGB(150, 8, 38), -- the end of every tail: the body's hue, darker
	lightEmission = 0.45, -- 1 burnt the fan white; 0.6 with brightness 1.4 turned this crimson pale pink at night
	brightness = 1.25,
	minSpeed = 40, -- studs/s the tip crosses the blade's line: nothing draws below it ...
	fullSpeed = 110, -- ... and the bands are full from here
	near = 5, -- studs from the camera: a closer trail fades, gone at half of it
	light = true, -- a PointLight at the tip while the fan draws
}
-- false before the first BladeFan.new: nothing is bound, call BladeFan.step(dt) yourself (a replay, a fixed step)
BladeFan.autoStep = true

local LAP = 0.012 -- each band overlaps its neighbours by this share of the blade: no hairline between bands
local SHORT, STEP = 0.55, 0.78 -- the guard band lives SHORT of the tip band's life; every other band STEP of its own
local FULLW = 0.55 -- a band keeps its full width for this share of its life
local CLEAR = { 0.06, 0.12, 0.3 } -- band transparency at birth, at half its life, at its end
local WHITE, HUE = 0.04, 0.14 -- white until WHITE of a band's life, the body colour from HUE
local CORE_FROM, CORE_BRIGHT = 0.5, 2 -- the core covers the blade from half way to the tip
local MAXTILT = math.tan(math.rad(20)) -- a point's curve direction leaves the blade's square plane by 20 degrees at most
local LONGWAY = 2 -- radians: a turn this big between two frames is checked against the next frame's turn
local SEGMENTS = 10 -- per beam: 3 showed corners on the fan's edge
local WHITE3 = Color3.new(1, 1, 1)
local BIND = "BladeFan"

local fans = {}
local bound = false
local folder = nil

local function smooth(e0: number, e1: number, x: number): number
	local u = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return u * u * (3 - 2 * u)
end

local function taper(f: number): number
	return if f <= FULLW then 1 else math.max(0, 1 - (f - FULLW) / (1 - FULLW))
end

local function clearAt(f: number): number
	if f <= 0.5 then
		return CLEAR[1] + (CLEAR[2] - CLEAR[1]) * f * 2
	end
	return CLEAR[2] + (CLEAR[3] - CLEAR[2]) * math.clamp(f * 2 - 1, 0, 1)
end

-- a frame from the tip's travel, for a point whose band gives no direction: X across the blade, Y along it
local function frame(travel: Vector3, dir: Vector3): CFrame?
	local x = travel - dir * travel:Dot(dir)
	if x.Magnitude < 1e-4 then
		return nil
	end
	return CFrame.fromMatrix(Vector3.zero, x.Unit, dir)
end

-- n attachments joined by n - 1 flat untextured beams
local function chain(host: BasePart, n: number, light: number, bright: number)
	local c = { pts = {}, segs = {}, on = {} }
	for m = 1, n do
		local a = Instance.new("Attachment")
		a.Parent = host
		c.pts[m] = a
	end
	for m = 1, n - 1 do
		local beam = Instance.new("Beam")
		beam.Attachment0 = c.pts[m]
		beam.Attachment1 = c.pts[m + 1]
		beam.FaceCamera = false
		beam.Segments = SEGMENTS
		beam.LightEmission = light
		beam.LightInfluence = 0
		beam.Brightness = bright
		beam.Enabled = false
		beam.Parent = host
		c.segs[m] = beam
		c.on[m] = false
	end
	return c
end

local function hideChain(c)
	for m, seg in c.segs do
		if c.on[m] then
			seg.Enabled = false
			c.on[m] = false
		end
	end
end

-- the per-frame update of every fan; bound at RenderPriority.Last (after the camera) unless autoStep is false
function BladeFan.step(dt: number)
	for fan in fans do
		fan:_step(dt)
	end
end

-- guard and tip: attachments on the blade where the trail starts and ends. opts: fields of BladeFan.defaults.
function BladeFan.new(guard: Attachment, tip: Attachment, opts)
	local o = table.clone(BladeFan.defaults)
	for k, v in opts or {} do
		o[k] = v
	end
	local self = setmetatable({}, BladeFan)
	self.guard, self.tip, self.o = guard, tip, o
	self.clock, self.speed, self.busyUntil, self.idle = 0, 1, -1, true
	self.hist, self.windows = {}, {}
	self.bands = {}
	for i = 1, o.bands do
		local f0 = math.max((i - 1) / o.bands - LAP, 0)
		local f1 = math.min(i / o.bands + LAP, 1)
		local k = if o.bands > 1 then (i - 1) / (o.bands - 1) else 1
		self.bands[i] = {
			at = (f0 + f1) / 2,
			share = f1 - f0,
			life = o.life * (SHORT + (1 - SHORT) * k) * (if i % 2 == 0 then STEP else 1),
		}
	end
	if not (folder and folder.Parent) then
		folder = Instance.new("Folder")
		folder.Name = "BladeFans"
		folder.Parent = workspace
	end
	local host = Instance.new("Part")
	host.Name = "BladeFan"
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.CastShadow = false
	host.Transparency = 1
	host.Size = Vector3.new(0.2, 0.2, 0.2)
	host.CFrame = CFrame.identity
	self.host = host
	self.np = math.ceil(o.life / o.grid) + 2
	self.chains = {}
	for i = 1, o.bands do
		self.chains[i] = chain(host, self.np, o.lightEmission, o.brightness)
	end
	if o.coreLife > 0 then
		self.coreBand = { at = (CORE_FROM + 1) / 2, share = 1 - CORE_FROM, life = o.coreLife }
		self.core = chain(host, math.ceil(o.coreLife / o.grid) + 2, 1, CORE_BRIGHT)
		for _, seg in self.core.segs do
			seg.Color = ColorSequence.new(WHITE3)
		end
	end
	if o.light then
		local a = Instance.new("Attachment")
		a.Parent = host
		local light = Instance.new("PointLight")
		light.Color = o.color:Lerp(WHITE3, 0.3)
		light.Range = 5
		light.Shadows = false
		light.Enabled = false
		light.Parent = a
		self.lightAt, self.light = a, light
	end
	host.Parent = folder
	self.pos, self.wid, self.tr, self.col = {}, {}, {}, {}
	fans[self] = true
	if BladeFan.autoStep and not bound then
		bound = true
		RunService:BindToRenderStep(BIND, Enum.RenderPriority.Last.Value, BladeFan.step)
	end
	return self
end

-- Opens a swing window: points cut from 0.03 s before now (a call one frame late still gets the whole cut) to
-- `duration` s after it draw. life: share of the bands' life for those points (0.05-1).
function BladeFan:swing(duration: number?, life: number?)
	local t0 = self.clock
	local w = { t0 = t0, t2 = t0 + (duration or 0.1), life = math.clamp(life or 1, 0.05, 1) }
	for i = #self.windows, 1, -1 do
		if self.windows[i].t2 < t0 - self.o.life - 0.1 then
			table.remove(self.windows, i)
		end
	end
	table.insert(self.windows, w)
	self.busyUntil = math.max(self.busyUntil, w.t2 + 0.01 + self.o.life)
end

-- 1 normal, 0 hold (hit-stop), 0.2 slow motion: the fan's clock runs at this rate, so trails age with the body
function BladeFan:setSpeed(speed: number)
	self.speed = speed
end

function BladeFan:destroy()
	fans[self] = nil
	self.host:Destroy()
	if bound and next(fans) == nil then
		bound = false
		RunService:UnbindFromRenderStep(BIND)
	end
end

function BladeFan:_hide()
	if self.idle then
		return
	end
	self.idle = true
	for _, c in self.chains do
		hideChain(c)
	end
	if self.core then
		hideChain(self.core)
	end
	if self.light then
		self.light.Enabled = false
	end
end

-- 0..1: how far fan time s is inside a swing window (soft edges)
function BladeFan:_gate(s: number): number
	local g = 0
	for _, w in self.windows do
		g = math.max(g, smooth(w.t0 - 0.03, w.t0 - 0.01, s) * (1 - smooth(w.t2 - 0.03, w.t2 + 0.01, s)))
	end
	return g
end

-- share of the bands' life for a point cut at fan time s (the latest window that holds it decides)
function BladeFan:_life(s: number): number
	for i = #self.windows, 1, -1 do
		local w = self.windows[i]
		if s >= w.t0 - 0.03 and s <= w.t2 + 0.01 then
			return w.life
		end
	end
	return 1
end

function BladeFan:_step(dt: number)
	local guard, tip = self.guard, self.tip
	if not (guard:IsDescendantOf(workspace) and tip:IsDescendantOf(workspace)) then
		table.clear(self.hist)
		self:_hide()
		return
	end
	-- record the blade: guard, tip, direction, length, and the turn since the last frame (w radians about n)
	local base, tipAt = guard.WorldPosition, tip.WorldPosition
	local h = self.hist
	local n = #h
	local adv = dt * self.speed
	if adv <= 0 and n > 0 and (h[n].tip - tipAt).Magnitude > 0.02 then
		-- held, yet the blade moved since the last frame: it moved before the hold began (a hit lands between two
		-- frames), so this frame runs at full speed. Without it that motion aged 0 s and the hold showed a white fan.
		adv = dt
	end
	self.clock += adv
	local t = self.clock
	if n > 0 and t - h[n].t < 1e-6 then
		h[n] = nil -- the clock did not move (hit-stop): this frame's pose replaces the last
		n -= 1
	end
	local len = (tipAt - base).Magnitude
	local rec = { t = t, base = base, tip = tipAt, dir = (tipAt - base) / len, len = len, w = 0 }
	if n > 0 then
		local p = h[n]
		local c = p.dir:Cross(rec.dir)
		local cm = c.Magnitude
		rec.w = math.atan2(cm, p.dir:Dot(rec.dir))
		if cm > 1e-4 then
			rec.n = c / cm
			if rec.w > 0.02 then
				-- the point the guard turned about with the blade (a hand on a swinging arm), from the guard's move
				-- square to n: the guard is pv from it at the last frame, and shifts h along n
				local move = base - p.base
				rec.h = move:Dot(rec.n)
				local q = move - rec.n * rec.h
				rec.pv = -q / 2 - rec.n:Cross(q) * (0.5 / math.tan(rec.w / 2))
			end
		end
		-- the turn before this one: over LONGWAY on the shortest arc, while this frame clearly turns the other way, so
		-- it went the long way round (a cut's follow-through keeps its sense; its wind-up does not, so only the
		-- next frame decides)
		if p.w > LONGWAY and p.n and rec.n and rec.w > 0.2 and p.n:Dot(rec.n) < -0.3 then
			p.long = true
		end
	end
	h[n + 1] = rec
	local keep = t - self.o.life - 3 * self.o.grid - 0.05
	while #h > 2 and h[2].t < keep do
		table.remove(h, 1)
	end
	if t > self.busyUntil then
		self:_hide()
		return
	end
	self.idle = false
	self:_draw(t)
end

-- the blade at fan time s from the record; i: where to start looking back. Returns nil before the record starts.
function BladeFan:_at(s: number, i: number?)
	local h = self.hist
	i = i or #h
	while i > 1 and h[i].t > s do
		i -= 1
	end
	local a = h[i]
	if not a or a.t > s + 1e-9 then
		return nil, i
	end
	local b = h[i + 1]
	if not b then
		return a, i
	end
	local u = (s - a.t) / (b.t - a.t)
	local dir, base
	if b.n then
		-- a.dir turned about b.n (square to it): the shortest arc, or the rest of the circle the other way
		local phi = if b.long then -(2 * math.pi - b.w) * u else b.w * u
		local cs, sn = math.cos(phi), math.sin(phi)
		dir = a.dir * cs + b.n:Cross(a.dir) * sn
		if b.pv then
			-- the guard turns with the blade about the pivot: an arc, not a chord
			base = a.base - b.pv + b.pv * cs + b.n:Cross(b.pv) * sn + b.n * (b.h * u)
		end
	else
		dir = if u < 0.5 then a.dir else b.dir
	end
	base = base or a.base:Lerp(b.base, u)
	return { base = base, tip = base + dir * (a.len + (b.len - a.len) * u), dir = dir }, i
end

function BladeFan:_color(f: number): Color3
	local o = self.o
	if f <= WHITE then
		return WHITE3
	elseif f <= HUE then
		return WHITE3:Lerp(o.color, (f - WHITE) / (HUE - WHITE))
	end
	return o.color:Lerp(o.tail, math.clamp((f - HUE) / (1 - HUE), 0, 1))
end

function BladeFan:_draw(t: number)
	local o = self.o
	local P = o.grid
	local np = self.np
	local j = math.floor(t / P)
	local camPos = workspace.CurrentCamera.CFrame.Position
	-- chain point 1 is the blade now, then back on the grid: g[k] is the blade at (j - k) * P
	local now = self:_at(t)
	local nowPrev = self:_at(t - P)
	local g, hint = {}, nil
	for k = 0, np - 1 do
		g[k], hint = self:_at((j - k) * P, hint)
		if not g[k] then
			break
		end
	end
	local smp, age, gate, ls, rot = {}, {}, {}, {}, {}
	local n = 0
	for m = 1, np do
		local s, prev, at
		if m == 1 then
			s, prev, at = now, nowPrev, t
		else
			s, prev, at = g[m - 2], g[m - 1], (j - (m - 2)) * P
		end
		if not s then
			break
		end
		n = m
		smp[m] = s
		age[m] = t - at
		-- sweep speed: the tip's motion across the blade only (a blade sliding along itself is no cut)
		local speed = 0
		if prev then
			local move = s.tip - prev.tip
			speed = (move - s.dir * move:Dot(s.dir)).Magnitude / P
		end
		gate[m] = smooth(o.minSpeed, o.fullSpeed, speed)
			* self:_gate(at)
			* smooth(o.near * 0.5, o.near, ((s.base + s.tip) * 0.5 - camPos).Magnitude)
		ls[m] = self:_life(at)
	end
	for m = 1, n do
		rot[m] = frame(smp[math.max(m - 1, 1)].tip - (smp[m + 1] or smp[m]).tip, smp[m].dir)
	end
	local fill = nil
	for m = n, 1, -1 do
		fill = rot[m] or fill
		rot[m] = fill
	end
	fill = CFrame.identity
	for m = 1, n do
		fill = rot[m] or fill
		rot[m] = fill
	end
	local span = (now.tip - now.base).Magnitude
	for i, band in self.bands do
		self:_chain(self.chains[i], band, span, smp, age, gate, rot, ls, false)
	end
	if self.core then
		self:_chain(self.core, self.coreBand, span, smp, age, gate, rot, ls, true)
	end
	if self.light then
		local b = 0.9 * math.max(gate[1] or 0, gate[2] or 0)
		self.lightAt.Position = now.tip
		self.light.Brightness = b
		self.light.Enabled = b > 0.01
	end
end

-- One band (or the core) along its chain. The oldest live point is pulled back to where the band's life ends, so a
-- tapering band ends in a point exactly there.
function BladeFan:_chain(c, band, span: number, smp, age, gate, rot, ls, core: boolean)
	local n = #c.pts
	local pos, wid, tr, col = self.pos, self.wid, self.tr, self.col
	local width = band.share * span
	local last, prev = 0, 0
	for m = 1, n do
		local s = smp[m]
		if not s then
			break
		end
		local f = age[m] / (band.life * ls[m])
		local fc = math.min(f, 1)
		pos[m] = s.base:Lerp(s.tip, band.at)
		if core then
			wid[m] = width
			tr[m] = 1 - (1 - fc) * gate[m]
		else
			wid[m] = width * taper(fc)
			tr[m] = 1 - (1 - clearAt(fc)) * gate[m]
			col[m] = self:_color(fc)
		end
		last = m
		if f >= 1 then
			if m > 1 then
				pos[m] = pos[m]:Lerp(pos[m - 1], math.clamp((f - 1) / (f - prev), 0, 1))
			end
			break
		end
		prev = f
	end
	-- X is the band's own path direction (points closer together count more), Y the blade made square to it. The
	-- blade also slides along itself, so an X forced square to the blade sat up to 45 degrees off the path and every
	-- segment bulged into a wave. Where the path runs almost along the blade the width would turn with it and twist
	-- the ribbon into teeth, so X leaves the blade's square plane by MAXTILT at most.
	for m = 1, last do
		local a = if m > 1 then pos[m - 1] - pos[m] else Vector3.zero
		local b = if m < last then pos[m] - pos[m + 1] else Vector3.zero
		local da, db = a.Magnitude, b.Magnitude
		local dirn = if da < 1e-4 then b elseif db < 1e-4 then a else a * (db / (da * (da + db))) + b * (da / (db * (da + db)))
		local fr = nil
		local d = smp[m].dir
		local along = dirn:Dot(d)
		local perp = dirn - d * along
		local pm = perp.Magnitude
		if pm > 1e-4 then
			local cap = MAXTILT * pm
			local x = (perp + d * math.clamp(along, -cap, cap)).Unit
			fr = CFrame.fromMatrix(Vector3.zero, x, (d - x * d:Dot(x)).Unit)
		end
		c.pts[m].CFrame = (fr or rot[m]) + pos[m]
	end
	for m = 1, n - 1 do
		local seg = c.segs[m]
		local len = if m < last then (pos[m] - pos[m + 1]).Magnitude else 0
		if len < 1e-3 or (tr[m] > 0.99 and tr[m + 1] > 0.99) then
			if c.on[m] then
				seg.Enabled = false
				c.on[m] = false
			end
		else
			seg.Width0, seg.Width1 = wid[m], wid[m + 1]
			seg.Transparency = NumberSequence.new(tr[m], tr[m + 1])
			if not core then
				seg.Color = ColorSequence.new(col[m], col[m + 1])
			end
			-- curved through the joints (each attachment's X points to the newer end): straight beams showed corners
			seg.CurveSize0, seg.CurveSize1 = -len / 3, -len / 3
			if not c.on[m] then
				seg.Enabled = true
				c.on[m] = true
			end
		end
	end
end

return BladeFan
