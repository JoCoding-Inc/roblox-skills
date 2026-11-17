--!nonstrict
-- lightning: jagged bolts re-shaped every 1-2 frames, each alive 2-8 frames, with a glow halo, branches, a
-- ground strike and an ambient crackle around a body part. Client only, on the fx clock.
-- roblox-feel-audio-vfx section 3e; ran in Studio 0.747 and 0.748 Play, 2026-11-18.
--
-- Lightning.strike(a, b, opts?) -> clock     one bolt from a to b (Vector3s); opts.life (s, default 0.12),
--                                             opts.restrike (gap s, default 0.04: off, then on again for 0.06 s)
-- Lightning.ground(point, opts?) -> clock     a sky-to-ground strike at point: bolt from 40-48 studs up, ground
--                                             flash, sparks, a light pulse
-- Lightning.ambient(part, opts?) -> clock     small bolts crackling on a shell around part (opts.dur, opts.radius,
--                                             opts.every = mean gap between new bolts, opts.scale = size)
-- Lightning.play(hero, opts?) -> clock        the demo: ambient crackle on the fist, then three ground strikes
-- All take opts.clock / opts.at (embed in a cutscene clock) and opts.seed (same seed = same bolts).
--
-- Build: a bolt is a polyline from midpoint displacement (depth 4-5: 16-32 segments, displacement 0.22 of the
-- segment length, halving per level) plus 1-3 branches (depth 2-3) forking 25-45 deg off at 20-80 % of the
-- way. Three camera-facing untextured Beam layers per segment share the joints: core white (LightEmission 1,
-- Brightness 6), body cyan 2.6x wider, halo blue 8x wider at 62 % transparency (r2); the stage Bloom (threshold
-- 1.05) adds the soft glow. Shapes are re-drawn every STEP s of clock time (1.5 frames at 60 fps).
--
-- Built to what four public showcase clips showed (read 2026-11-17; frame counts at each clip's own rate, 30 or 60
-- fps): each bolt 2-8 frames, re-shaped every 1-2 frames (30-60 Hz), small bolts 0.3-0.6x character height,
-- background strikes 2-4x height, pop on and pop off, a bloom halo of 5-10 % of the frame.
-- What failed while building: bolts sharing a pool were hidden early by an older bolt's timer (the owner token in
-- lifeOf fixes it); a 7-stud ground flash at Brightness 4 blew the floor to white; a 0.78 halo vanished on the
-- light-grey stage (0.62 now).
-- Limits: on a light daylight floor the bolt reads thin and pale (it reads best in the dark beat and the peak);
-- every bolt keeps a pool of hidden beams (3 layers per segment), most of the beam count at the cutscene peak.

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)
local Stage = require(script.Parent.cine_stage)

local Lightning = {}

local H = Stage.HUE
Lightning.STEP = 0.025

-- Points of a jagged line from a to b: midpoint displacement in 3D.
local function jag(rng: Random, a: Vector3, b: Vector3, depth: number, rough: number): { Vector3 }
	local pts = { a, b }
	local amp = (b - a).Magnitude * rough
	local dir = (b - a).Unit
	local side = dir:Cross(math.abs(dir.Y) < 0.9 and Vector3.yAxis or Vector3.xAxis).Unit
	local up = side:Cross(dir).Unit
	for _ = 1, depth do
		local nxt = { pts[1] }
		for i = 1, #pts - 1 do
			local p, q = pts[i], pts[i + 1]
			local th = rng:NextNumber() * math.pi * 2
			local off = (side * math.cos(th) + up * math.sin(th)) * amp * rng:NextNumber(0.35, 1)
			table.insert(nxt, (p + q) / 2 + off)
			table.insert(nxt, q)
		end
		pts = nxt
		amp *= 0.5
	end
	return pts
end
Lightning.jag = jag

-- Random unit vector off `dir` by deg degrees.
local function deviate(rng: Random, dir: Vector3, deg: number): Vector3
	local side = dir:Cross(math.abs(dir.Y) < 0.9 and Vector3.yAxis or Vector3.xAxis).Unit
	local up = side:Cross(dir).Unit
	local th = rng:NextNumber() * math.pi * 2
	local r = math.rad(deg)
	return (dir * math.cos(r) + (side * math.cos(th) + up * math.sin(th)) * math.sin(r)).Unit
end

-- A drawable bolt: pools of attachments and three beam layers for a main chain of nMain points and up to
-- nBranch chains of nB points each.
local function newBolt(c, nMain: number, nBranch: number, nB: number, w: number, hue)
	hue = hue or {}
	local layers = {
		{ width = w, color = hue.core or H.white, alpha = 0, le = 1, bright = 6, z = 0.2 },
		-- r1: body at LightEmission 1, Brightness 3 washed to white on the grey sky; lower keeps the cyan
		{ width = w * 2.6, color = hue.body or H.cyan, alpha = 0.15, le = 0.6, bright = 1.6, z = 0.1 },
		-- r2: on the light-grey day stage the 0.78 halo vanished; 0.62 and 8x wide keeps a blue glow around the core
		{ width = w * 8, color = hue.halo or H.blue, alpha = 0.62, le = 0.7, bright = 1, z = 0 },
	}
	local chains = {}
	local function chain(n)
		local atts = {}
		for i = 1, n do
			atts[i] = c:attachment(nil)
		end
		local beams = {}
		for li, L in layers do
			beams[li] = {}
			for i = 1, n - 1 do
				local b = c:beam(atts[i], atts[i + 1], {
					FaceCamera = true,
					Segments = 1,
					Width0 = L.width,
					Width1 = L.width,
					Color = ColorSequence.new(L.color),
					Transparency = NumberSequence.new(L.alpha),
					LightEmission = L.le,
					Brightness = L.bright,
					ZOffset = L.z,
				})
				b.Enabled = false
				beams[li][i] = b
			end
		end
		return { atts = atts, beams = beams, n = n }
	end
	local main = chain(nMain)
	for k = 1, nBranch do
		chains[k] = chain(nB)
	end
	local bolt = { visible = false }
	local function draw(ch, pts, taper, wscale)
		local m = math.min(#pts, ch.n)
		for i = 1, m do
			ch.atts[i].WorldPosition = pts[i]
		end
		for li, L in layers do
			for i = 1, ch.n - 1 do
				local b = ch.beams[li][i]
				if i < m then
					local u0, u1 = (i - 1) / (m - 1), i / (m - 1)
					local w0 = L.width * wscale * (1 - taper * u0)
					local w1 = L.width * wscale * (1 - taper * u1)
					b.Width0, b.Width1 = w0, w1
					b.Enabled = true
				else
					b.Enabled = false
				end
			end
		end
	end
	local function hideChain(ch)
		for li = 1, #layers do
			for _, b in ch.beams[li] do
				b.Enabled = false
			end
		end
	end
	-- pts: main points; branches: list of point lists
	function bolt.set(pts, branches, wscale)
		bolt.visible = true
		draw(main, pts, 0.35, wscale or 1)
		for k, ch in chains do
			local bp = branches and branches[k]
			if bp then
				draw(ch, bp, 0.8, (wscale or 1) * 0.6)
			else
				hideChain(ch)
			end
		end
	end
	function bolt.hide()
		bolt.visible = false
		hideChain(main)
		for _, ch in chains do
			hideChain(ch)
		end
	end
	return bolt
end
Lightning.newBolt = newBolt

-- Shape a bolt with branches between a and b.
local function shape(rng, a, b, depth, nBranch, rough)
	local pts = jag(rng, a, b, depth, rough or 0.22)
	local branches = {}
	local dir = (b - a).Unit
	for k = 1, nBranch do
		local i = rng:NextInteger(math.floor(#pts * 0.2) + 1, math.floor(#pts * 0.8))
		local p = pts[i]
		local rest = (b - p).Magnitude
		local d = deviate(rng, dir, rng:NextNumber(25, 45))
		branches[k] = jag(rng, p, p + d * rest * rng:NextNumber(0.3, 0.5), 2, 0.3)
	end
	return pts, branches
end

-- Schedules one bolt's life on window c from t0: on for `life` s, re-shaped every STEP; optional restrike.
local function lifeOf(c, bolt, rng, t0, life, getAB, depth, nBranch, restrike, wscale)
	local segs = {}
	table.insert(segs, { t0, t0 + life })
	if restrike then
		local t1 = t0 + life + restrike
		table.insert(segs, { t1, t1 + life * 0.5 })
	end
	local lastStep = -1
	local token = {}
	c:every(function(t)
		local on = false
		for _, s in segs do
			if t >= s[1] and t < s[2] then
				on = true
			end
		end
		if on then
			local k = math.floor((t - t0) / Lightning.STEP)
			if k ~= lastStep or not bolt.visible or bolt.owner ~= token then
				lastStep = k
				bolt.owner = token
				local a, b = getAB(t)
				local pts, br = shape(rng, a, b, depth, nBranch)
				bolt.set(pts, br, wscale)
			end
		elseif bolt.visible and bolt.owner == token then
			bolt.hide()
		end
	end)
end

function Lightning.strike(a: Vector3, b: Vector3, opts)
	opts = opts or {}
	local life = opts.life or 0.12
	local restrike = if opts.restrike == false then nil else (opts.restrike or 0.04)
	local c, root, own = FxClock.attach("Strike", life * 1.6 + (restrike or 0) + 0.1, opts)
	local rng = Random.new(opts.seed or 7)
	local depth = opts.depth or 5
	local nBranch = opts.branches or 3
	c:at(0, function()
		local bolt = newBolt(c, 2 ^ depth + 1, nBranch, 5, opts.width or 0.14, opts.hue)
		lifeOf(c, bolt, rng, 0, life, function()
			return a, b
		end, depth, nBranch, restrike)
	end)
	if own then
		root:play()
	end
	return root
end

function Lightning.ground(point: Vector3, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 11)
	local top = point + Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(40, 48), rng:NextNumber(-8, 8))
	local c, root, own = FxClock.attach("GroundStrike", 0.75, opts)
	-- the bolt
	Lightning.strike(top, point, { clock = c, at = 0, seed = opts.seed, width = opts.width or 0.22, depth = 5, branches = 3, life = opts.life or 0.1 })
	c:at(0, function()
		local att = c:attachment(CFrame.new(point + Vector3.new(0, 0.3, 0)))
		local flash = c:emitter(att, {
			Name = "GroundFlash",
			Lifetime = NumberRange.new(0.1),
			-- r1: 7 studs at Brightness 4 blew the floor and the target to white
			Size = FxClock.ns({ { 0, 1.5 }, { 0.3, 3.5 }, { 1, 2.5 } }),
			Transparency = FxClock.ns({ { 0, 0.1 }, { 0.5, 0.4 }, { 1, 1 } }),
			Color = FxClock.cs({ { 0, H.white }, { 0.4, H.hot }, { 1, H.cyan } }),
			LightEmission = 1,
			Brightness = 2.5,
			ZOffset = 1,
		})
		FxTextures.apply(flash, "glow")
		flash:Emit(1)
		local spark = c:emitter(att, {
			Name = "GroundSparks",
			EmissionDirection = Enum.NormalId.Top,
			Lifetime = NumberRange.new(0.12, 0.3),
			Speed = NumberRange.new(18, 40),
			SpreadAngle = Vector2.new(70, 70),
			Acceleration = Vector3.new(0, -60, 0),
			Drag = 4,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Rotation = NumberRange.new(90),
			Squash = FxClock.ns({ { 0, 1.2 }, { 1, 1.2 } }),
			Size = FxClock.ns({ { 0, 0.7 }, { 1, 0.1 } }),
			Transparency = FxClock.ns({ { 0, 0 }, { 1, 1 } }),
			Color = FxClock.cs({ { 0, H.white }, { 0.5, H.cyan }, { 1, H.blue } }),
			LightEmission = 1,
			Brightness = 3,
		})
		FxTextures.apply(spark, "streak")
		spark:Emit(18)
		local light = c:light(att, { Range = 16, Color = H.cyan })
		c:span(0, 0.22, function(u)
			light.Brightness = 3 * (1 - u) ^ 2
		end)
	end)
	if own then
		root:play()
	end
	return root
end

function Lightning.ambient(part: BasePart, opts)
	opts = opts or {}
	local dur = opts.dur or 1.2
	local radius = opts.radius or 1.6
	local gap = opts.every or 0.05
	local scale = opts.scale or 1
	local c, root, own = FxClock.attach("Ambient", dur + 0.15, opts)
	local rng = Random.new(opts.seed or 23)
	local pool = {}
	c:at(0, function()
		for k = 1, opts.pool or 5 do
			pool[k] = newBolt(c, 9, 1, 3, 0.05 * scale, opts.hue)
		end
		-- pre-plan every bolt: start, life (2-6 frames), endpoints on a shell around the part
		local t = 0
		local k = 0
		while t < dur do
			k = k % #pool + 1
			local bolt = pool[k]
			local life = rng:NextInteger(2, 6) / 60
			local d1 = deviate(rng, Vector3.yAxis, rng:NextNumber(0, 180))
			local d2 = deviate(rng, d1, rng:NextNumber(50, 120))
			local r1 = radius * rng:NextNumber(0.35, 1)
			local r2 = radius * rng:NextNumber(0.6, 1.25)
			local lrng = Random.new(rng:NextInteger(1, 1e6))
			lifeOf(c, bolt, lrng, t, life, function()
				local p = part.Position
				return p + d1 * r1, p + d2 * r2
			end, 3, if rng:NextNumber() < 0.4 then 1 else 0, nil, scale)
			t += gap * rng:NextNumber(0.5, 1.5)
		end
	end)
	-- a faint flicker light on the part
	c:at(0, function()
		local light = c:light(part, { Range = 8 * scale, Color = H.cyan })
		c:every(function(tt)
			local k = math.floor(tt / Lightning.STEP)
			light.Brightness = if tt < dur then 1.5 + 2.5 * ((k * 7919) % 10) / 10 else 0
		end)
		c:onCleanup(function()
			light:Destroy()
		end)
	end)
	if own then
		root:play()
	end
	return root
end

Lightning.DURATION = 1.6
Lightning.CAPTURE_TIMES = { 0.1, 0.117, 0.133, 0.15, 0.4, 0.417, 0.433, 0.45, 0.467, 0.7, 0.717, 0.733, 1.0, 1.05, 1.1, 1.3 }

function Lightning.play(hero, opts)
	opts = opts or {}
	local c, root, own = FxClock.attach("LightningDemo", Lightning.DURATION, opts)
	local fist = hero:FindFirstChild("RightHand")
	Lightning.ambient(fist, { clock = c, at = 0.05, dur = 1.4, radius = 1.4, seed = 5 })
	local target = Stage.target()
	local base = target:GetPivot().Position
	local floorY = 0
	local pts = {
		Vector3.new(base.X - 6, floorY, base.Z - 4),
		Vector3.new(base.X + 5, floorY, base.Z - 8),
		Vector3.new(base.X - 1, floorY, base.Z - 2),
	}
	for i, p in pts do
		Lightning.ground(p, { clock = c, at = 0.1 + (i - 1) * 0.3, seed = 100 + i })
	end
	-- an arc from the fist to the target's chest
	c:at(1.0, function()
		local chest = target:FindFirstChild("UpperTorso").Position
		Lightning.strike(fist.Position, chest, { clock = c, at = 1.0, seed = 77, width = 0.1, depth = 4, branches = 2, life = 0.1 })
	end)
	if own then
		root:play()
	end
	return root
end

return Lightning
