--!nonstrict
-- ink_shapes: flat, hard-edged, camera-facing graphic shapes that sit for 1-5 frames at a peak: black ink spikes
-- radiating from a point, black brush smears from a frame edge, and white or pale grey shards. Re-drawn every
-- frame they are on. Client only, on the fx clock. roblox-feel-audio-vfx section 3e; ran in Studio 0.747 and
-- 0.748 Play, 2026-11-18.
--
-- InkShapes.play(opts) -> clock
--   opts.kind     "spikes" | "smear" | "shards"
--   opts.focus    Vector3 (world point the shapes radiate from; default the frame centre)
--   opts.frames   frames on screen at 60 fps (default 3); opts.step re-draw period (default 1 frame)
--   opts.depth    "behind" (default: a plane 2 studs behind the focus, so the characters cover the shapes) |
--                 "front" (a plane 1 stud in front of the camera, over everything)
--   opts.count, opts.color, opts.clock / opts.at / opts.seed
--
-- Build: every shape is made of triangles; a triangle is two thin WedgeParts (the usual two-wedge triangle
-- construction), Neon material so the colour is flat and unshaded (Neon black renders pure black; Neon white
-- blooms a little). Shapes are laid out in screen units (fractions of the frame height) on a plane facing the
-- camera and re-drawn from the camera of the current frame, so they stay flat through cuts and shake.
-- Coverage is kept under about 35 % of the frame so these do not count as screen-wide flashes (flash_safety).
--
-- Built to what four public showcase clips showed (read 2026-11-17; frame counts at each clip's own rate, 30 or 60
-- fps): black spikes and smears for 1-5 frames covering 30-80 % of the frame, ink streaks up to 45 frames, white
-- shards for 2-5 frames; pure black or white, hard edges, no shading, pop on and off, a new shape every 1-2 frames.
-- Ours stay under about 35 % (see above).
-- What failed while building: shards on the "behind" plane below the horizon were cut by the floor (now in front).
-- Limits: edges are perfectly straight triangles (brush ink has ragged, tapering edges); 60 triangles = 120
-- WedgeParts per call, re-laid every frame.

local FxClock = require(script.Parent.fx_clock)
local Stage = require(script.Parent.cine_stage)

local InkShapes = {}

local H = Stage.HUE
InkShapes.CAPTURE_TIMES = { 0.0, 0.017, 0.033, 0.05, 0.067 }

local THICK = 0.01

-- Fill two wedges w1, w2 so they draw the triangle a, b, c (world points).
local function triangle(a: Vector3, b: Vector3, c: Vector3, w1: BasePart, w2: BasePart)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cr = ac:Cross(ab)
	if cr.Magnitude < 1e-6 or bc.Magnitude < 1e-6 then
		w1.LocalTransparencyModifier, w2.LocalTransparencyModifier = 1, 1
		return
	end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	w1.Size = Vector3.new(THICK, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	w2.Size = Vector3.new(THICK, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
	w1.LocalTransparencyModifier, w2.LocalTransparencyModifier = 0, 0
end
InkShapes.triangle = triangle

local function wedge(c, color)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	w.CastShadow = false
	w.Material = Enum.Material.Neon
	w.Color = color
	w.Size = Vector3.new(THICK, 0.1, 0.1)
	w.LocalTransparencyModifier = 1
	w.Parent = c.model
	return w
end

-- Shapes in screen units: x right, y up, in fractions of the frame height, origin at the focus.
-- Each returns a list of triangles { {x,y}, {x,y}, {x,y} }.
local function spikes(rng, n)
	local tris = {}
	for i = 1, n do
		local th = (i - 1) / n * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
		local d = Vector2.new(math.cos(th), math.sin(th))
		local nrm = Vector2.new(-d.Y, d.X)
		local r0 = rng:NextNumber(0.2, 0.36)
		local r1 = r0 + rng:NextNumber(0.7, 1.3)
		local w = rng:NextNumber(0.025, 0.07)
		local base = d * r1
		local tip = d * r0
		table.insert(tris, { tip, base + nrm * w, base - nrm * w })
		-- a thin barb on some
		if rng:NextNumber() < 0.4 then
			local m = d * (r0 + (r1 - r0) * 0.45)
			local bd = (d + nrm * rng:NextNumber(-0.8, 0.8)).Unit
			table.insert(tris, { m + bd * 0.25, m + nrm * w * 0.5, m - nrm * w * 0.5 })
		end
	end
	return tris
end

local function smear(rng, n, aspect)
	local tris = {}
	for _ = 1, n do
		-- a tapered stroke from the top edge down (in the clips, smears drop from the top)
		local x0 = rng:NextNumber(-0.5 * aspect, 0.5 * aspect)
		local len = rng:NextNumber(0.35, 0.75)
		local w0 = rng:NextNumber(0.06, 0.16)
		local slant = rng:NextNumber(-0.25, 0.25)
		local top = Vector2.new(x0, 0.62)
		local bot = Vector2.new(x0 + slant, 0.62 - len)
		local d = (bot - top).Unit
		local nrm = Vector2.new(-d.Y, d.X)
		local mid = top + (bot - top) * 0.55
		local a1, a2 = top + nrm * w0, top - nrm * w0
		local m1, m2 = mid + nrm * w0 * 0.7 + nrm * rng:NextNumber(-0.02, 0.02), mid - nrm * w0 * 0.55
		table.insert(tris, { a1, a2, m1 })
		table.insert(tris, { a2, m2, m1 })
		table.insert(tris, { m1, m2, bot })
	end
	return tris
end

local function shards(rng, n)
	local tris = {}
	for i = 1, n do
		local th = (i - 1) / n * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local d = Vector2.new(math.cos(th), math.sin(th))
		local nrm = Vector2.new(-d.Y, d.X)
		local r0 = rng:NextNumber(0.15, 0.3)
		local r1 = r0 + rng:NextNumber(0.35, 0.8)
		local w = rng:NextNumber(0.06, 0.16)
		local p0 = d * r0 + nrm * rng:NextNumber(-0.03, 0.03)
		table.insert(tris, { p0, d * r1 + nrm * w, d * (r1 * 0.85) - nrm * w * 0.6 })
	end
	return tris
end

function InkShapes.play(opts)
	opts = opts or {}
	local kind = opts.kind or "spikes"
	local frames = opts.frames or 3
	local dur = frames / 60
	local step = opts.step or (1 / 60)
	local c, root, own = FxClock.attach("Ink_" .. kind, dur + 0.02, opts)
	local rng = Random.new(opts.seed or 53)
	local cam = workspace.CurrentCamera
	local color = opts.color or (if kind == "shards" then Color3.fromRGB(236, 240, 244) else H.ink)
	local maxTris = 60
	local pool = {}
	c:at(0, function()
		for i = 1, maxTris do
			local col = color
			if kind == "shards" and i % 3 == 0 then
				col = Color3.fromRGB(176, 182, 190)
			end
			pool[i] = { wedge(c, col), wedge(c, col) }
		end
	end)
	local lastK = -1
	c:every(function(t)
		local k = math.floor(t / step)
		if t >= dur then
			for _, pr in pool do
				pr[1].LocalTransparencyModifier, pr[2].LocalTransparencyModifier = 1, 1
			end
			return
		end
		if k == lastK then
			-- keep the shapes glued to the camera (it may move inside a frame step)
		end
		lastK = k
		local camCF = cam.CFrame
		local vp = cam.ViewportSize
		local aspect = vp.X / math.max(vp.Y, 1)
		local focus = opts.focus or (camCF.Position + camCF.LookVector * 20)
		local dist
		if opts.depth == "front" then
			dist = 1
		else
			dist = math.max((focus - camCF.Position):Dot(camCF.LookVector) + 2, 1.5)
		end
		local hh = dist * math.tan(math.rad(cam.FieldOfView) / 2) -- half frame height in studs at that depth
		-- focus on the plane
		local rel = camCF:PointToObjectSpace(focus)
		local fx = if rel.Z < -0.1 then rel.X / -rel.Z * dist else 0
		local fy = if rel.Z < -0.1 then rel.Y / -rel.Z * dist else 0
		local planeC = camCF * CFrame.new(fx, fy, -dist)
		local srng = Random.new((opts.seed or 53) * 1000 + k)
		local tris
		if kind == "spikes" then
			tris = spikes(srng, opts.count or 12)
		elseif kind == "smear" then
			planeC = camCF * CFrame.new(0, 0, -dist)
			tris = smear(srng, opts.count or 4, aspect)
		else
			tris = shards(srng, opts.count or 7)
		end
		local scale = hh * 2 -- screen unit (frame height) to studs
		for i, pr in pool do
			local tri = tris[i]
			if tri then
				local function w(v)
					return planeC * Vector3.new(v.X * scale, v.Y * scale, 0)
				end
				triangle(w(tri[1]), w(tri[2]), w(tri[3]), pr[1], pr[2])
			else
				pr[1].LocalTransparencyModifier, pr[2].LocalTransparencyModifier = 1, 1
			end
		end
	end)
	if own then
		root:play()
	end
	return root
end

return InkShapes
