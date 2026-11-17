--!nonstrict
-- fx_clock: one shared clock for every layer of an effect (roblox-feel-audio-vfx sections 3c and 3d).
-- Every layer is scheduled on clock time: events (at), curves over a span (span), per-step callbacks (every)
-- and emission streams (stream). Emitter TimeScale and Beam TextureSpeed follow the clock scale, so the same
-- effect runs at 1x in play, at 0.1x for a capture, and freezes (scale 0) on a beat for a still frame.
-- Client only. Each effect builds its instances under one Model in workspace.FxRuntime and removes them on stop.
--
-- Part of a set: fx_clock, fx_textures, fire_slash, hit_impact, level_up_aura, fx_capture. Copy all six as
-- ModuleScripts with these names into one folder (for example ReplicatedStorage.Fx) and require them from a
-- LocalScript. Ran in Studio 0.747 Play on 2026-11-17 (desktop view and the Samsung Galaxy A06 Device
-- Simulator preset); not checked in a published game or on a real phone; frame cost not measured.
--
-- local clock = FxClock.new("MyFx", 1.0)            -- name, duration in clock seconds
-- clock:at(0.1, function() emitter:Emit(8) end)     -- an event at a time
-- clock:span(0, 0.2, function(u, t) light.Brightness = 4 * (1 - u) end) -- a curve over a span
-- clock:play()                                       -- runs on RenderStepped, cleans up at the duration

local RunService = game:GetService("RunService")

local FxClock = {}
FxClock.__index = FxClock

-- Capture hooks, read by clocks created after they are set (fx_capture sets them).
FxClock.defaultScale = 1
FxClock.breakpoints = nil :: { number }?
FxClock.onBreak = nil :: ((clock: any, t: number, index: number) -> ())?
FxClock.onStop = nil :: ((clock: any) -> ())?
FxClock.active = {} :: { [any]: boolean }

local function runtimeFolder(): Instance
	local f = workspace:FindFirstChild("FxRuntime")
	if not f then
		f = Instance.new("Folder")
		f.Name = "FxRuntime"
		f.Parent = workspace
	end
	return f :: Instance
end

function FxClock.new(name: string, duration: number)
	local self = setmetatable({}, FxClock)
	self.name = name
	self.t = 0
	self.duration = duration
	self.scale = FxClock.defaultScale
	self.events = {} :: { { t: number, fn: () -> (), done: boolean } }
	self.spans = {} :: { { t0: number, t1: number, fn: (u: number, t: number) -> (), done: boolean } }
	self.steps = {} :: { (t: number, dt: number) -> () }
	self.emitters = {} :: { ParticleEmitter }
	self.beams = {} :: { [Beam]: number }
	self.cleanups = {} :: { () -> () }
	self.breaks = if FxClock.breakpoints then table.clone(FxClock.breakpoints) else nil
	self.breakIndex = 1
	self.onBreak = FxClock.onBreak
	local model = Instance.new("Model")
	model.Name = "Fx_" .. name
	model.Parent = runtimeFolder()
	self.model = model
	-- One invisible anchored host part at the world origin; attachments on it are placed by WorldCFrame.
	self.host = self:part({ Name = "Host", Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new() })
	return self
end

-- Instances -------------------------------------------------------------------------------------------

function FxClock:part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Locked = true
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = self.model
	return p
end

function FxClock:attachment(cf: CFrame?, parent: Instance?): Attachment
	local a = Instance.new("Attachment")
	a.Parent = parent or self.host
	if cf then
		a.WorldCFrame = cf
	end
	return a
end

-- A burst emitter: Enabled false, every property set explicitly (fresh-instance defaults are not trusted).
function FxClock:emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.Rate = 0
	e.LightInfluence = 0
	e.LockedToPart = false
	e.Speed = NumberRange.new(0)
	e.SpreadAngle = Vector2.new(0, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(0)
	e.Drag = 0
	e.Acceleration = Vector3.zero
	e.ZOffset = 0
	e.VelocityInheritance = 0
	for k, v in props do
		(e :: any)[k] = v
	end
	e.TimeScale = math.clamp(self.scale, 0, 1)
	e.Parent = parent
	table.insert(self.emitters, e)
	return e
end

function FxClock:beam(a0: Attachment, a1: Attachment, props: { [string]: any }): Beam
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.FaceCamera = false
	b.LightInfluence = 0
	b.Segments = 10
	b.TextureSpeed = 0
	for k, v in props do
		(b :: any)[k] = v
	end
	self.beams[b] = b.TextureSpeed
	b.TextureSpeed = b.TextureSpeed * self.scale
	b.Parent = self.host
	return b
end

function FxClock:light(parent: Instance, props: { [string]: any }): PointLight
	local l = Instance.new("PointLight")
	l.Shadows = false
	l.Brightness = 0
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

-- Scheduling ------------------------------------------------------------------------------------------

function FxClock:at(t: number, fn: () -> ())
	table.insert(self.events, { t = t, fn = fn, done = false })
	table.sort(self.events, function(a, b)
		return a.t < b.t
	end)
end

-- fn(u, t) runs every step while t0 <= t <= t1 (u 0..1) and once more with u = 1 when the clock passes t1.
function FxClock:span(t0: number, t1: number, fn: (u: number, t: number) -> ())
	table.insert(self.spans, { t0 = t0, t1 = t1, fn = fn, done = false })
end

function FxClock:every(fn: (t: number, dt: number) -> ())
	table.insert(self.steps, fn)
end

function FxClock:onCleanup(fn: () -> ())
	table.insert(self.cleanups, fn)
end

-- Clock-driven emission (instead of Rate): rate(t) particles per clock second between t0 and t1.
-- before(n) can move the emitter's host before each Emit (for emission along a moving blade).
function FxClock:stream(e: ParticleEmitter, t0: number, t1: number, rate: (t: number) -> number, before: ((t: number) -> ())?)
	local acc = 0
	self:every(function(t, dt)
		if t < t0 or t > t1 or dt <= 0 then
			return
		end
		acc += rate(t) * dt
		local n = math.floor(acc)
		if n > 0 then
			acc -= n
			if before then
				for _ = 1, n do
					before(t)
					e:Emit(1)
				end
			else
				e:Emit(n)
			end
		end
	end)
end

function FxClock:setScale(s: number)
	self.scale = math.clamp(s, 0, 1)
	for _, e in self.emitters do
		if e.Parent then
			e.TimeScale = self.scale
		end
	end
	for b, base in self.beams do
		if b.Parent then
			b.TextureSpeed = base * self.scale
		end
	end
end

-- Running ---------------------------------------------------------------------------------------------

function FxClock:_advance(newT: number, dt: number)
	self.t = newT
	for _, ev in self.events do
		if not ev.done and ev.t <= newT then
			ev.done = true
			ev.fn()
		end
	end
	for _, sp in self.spans do
		if not sp.done and newT >= sp.t0 then
			local u = math.clamp((newT - sp.t0) / math.max(sp.t1 - sp.t0, 1e-6), 0, 1)
			sp.fn(u, newT)
			if newT >= sp.t1 then
				sp.done = true
			end
		end
	end
	for _, fn in self.steps do
		fn(newT, dt)
	end
end

function FxClock:step(realDt: number)
	if self.scale <= 0 then
		return
	end
	local dt = realDt * self.scale
	local newT = self.t + dt
	local hitBreak: number? = nil
	if self.breaks then
		local bp = self.breaks[self.breakIndex]
		if bp and newT >= bp then
			dt = math.max(bp - self.t, 0)
			newT = bp
			hitBreak = bp
		end
	end
	self:_advance(newT, dt)
	if hitBreak then
		local index = self.breakIndex
		self.breakIndex += 1
		self:setScale(0)
		if self.onBreak then
			self.onBreak(self, hitBreak, index)
		end
	end
	if self.t >= self.duration then
		self:stop()
	end
end

function FxClock:play()
	FxClock.active[self] = true
	self:_advance(0, 0)
	self.conn = RunService.RenderStepped:Connect(function(dt)
		self:step(dt)
	end)
	return self
end

function FxClock:stop()
	if self.stopped then
		return
	end
	self.stopped = true
	if self.conn then
		self.conn:Disconnect()
	end
	for _, fn in self.cleanups do
		pcall(fn)
	end
	self.model:Destroy()
	FxClock.active[self] = nil
	if FxClock.onStop then
		FxClock.onStop(self)
	end
end

-- Curves and colour helpers -----------------------------------------------------------------------------

function FxClock.lerp(a: number, b: number, u: number): number
	return a + (b - a) * u
end

function FxClock.clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

function FxClock.outCubic(u: number): number
	return 1 - (1 - u) ^ 3
end

function FxClock.outQuart(u: number): number
	return 1 - (1 - u) ^ 4
end

function FxClock.inOutSine(u: number): number
	return -(math.cos(math.pi * u) - 1) / 2
end

function FxClock.smooth(e0: number, e1: number, x: number): number
	local u = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return u * u * (3 - 2 * u)
end

-- Piecewise-linear colour ramp: stops = { {0, Color3}, {0.3, Color3}, ... }
function FxClock.ramp(stops: { { any } }, u: number): Color3
	if u <= stops[1][1] then
		return stops[1][2]
	end
	for i = 1, #stops - 1 do
		local a, b = stops[i], stops[i + 1]
		if u <= b[1] then
			return (a[2] :: Color3):Lerp(b[2], (u - a[1]) / (b[1] - a[1]))
		end
	end
	return stops[#stops][2]
end

function FxClock.ns(points: { { number } }): NumberSequence
	local kps = {}
	for _, p in points do
		table.insert(kps, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0))
	end
	return NumberSequence.new(kps)
end

function FxClock.cs(points: { { any } }): ColorSequence
	local kps = {}
	for _, p in points do
		table.insert(kps, ColorSequenceKeypoint.new(p[1], p[2]))
	end
	return ColorSequence.new(kps)
end

-- Ribbon: a chain of flat curved Beams through joints (section 3c "arc ribbon"). jointFn(j) returns, per joint,
-- a CFrame (position; X axis = direction of travel; Y axis = width direction), width, transparency and colour,
-- or nil to hide the joint. CurveSize per segment comes from the joints' tangents, exact for circular arcs.
export type Joint = { cf: CFrame, width: number, alpha: number, color: Color3 }

function FxClock:ribbon(n: number, props: { [string]: any })
	local atts: { Attachment } = {}
	local beams: { Beam } = {}
	for j = 1, n + 1 do
		atts[j] = self:attachment(nil)
	end
	for i = 1, n do
		beams[i] = self:beam(atts[i], atts[i + 1], props)
		beams[i].Enabled = false
	end
	local ribbon = { beams = beams, attachments = atts }
	function ribbon.update(jointFn: (j: number) -> Joint?)
		local joints: { Joint? } = {}
		for j = 1, n + 1 do
			local jt = jointFn(j)
			joints[j] = jt
			if jt then
				atts[j].WorldCFrame = jt.cf
			end
		end
		for i = 1, n do
			local a, b = joints[i], joints[i + 1]
			local beam = beams[i]
			if a and b and (a.alpha < 1 or b.alpha < 1) and (a.width > 0.001 or b.width > 0.001) then
				local p0, p1 = a.cf.Position, b.cf.Position
				local chord = (p1 - p0).Magnitude
				local cosT = math.clamp(a.cf.XVector:Dot(b.cf.XVector), -1, 1)
				local theta = math.acos(cosT)
				local handle
				if theta < 1e-3 then
					handle = chord / 3
				else
					local r = chord / (2 * math.sin(theta / 2))
					handle = 4 / 3 * math.tan(theta / 4) * r
				end
				beam.CurveSize0 = handle
				beam.CurveSize1 = handle
				beam.Width0 = a.width
				beam.Width1 = b.width
				beam.Transparency = NumberSequence.new(math.clamp(a.alpha, 0, 1), math.clamp(b.alpha, 0, 1))
				beam.Color = ColorSequence.new(a.color, b.color)
				beam.Enabled = true
			else
				beam.Enabled = false
			end
		end
	end
	function ribbon.hide()
		for _, b in beams do
			b.Enabled = false
		end
	end
	return ribbon
end

return FxClock
