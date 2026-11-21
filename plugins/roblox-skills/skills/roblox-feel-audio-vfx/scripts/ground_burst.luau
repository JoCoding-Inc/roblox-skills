--!nonstrict
-- ground_burst: the after-beat on the floor: a flat ground ring and a low shock wall that expand, a rim of slabs
-- that rise out of the floor, rock debris thrown up and moved by script on the clock (taking the floor's
-- Material and Color from a raycast), and dust that rolls out along the ground. Client only, on the fx clock.
-- roblox-feel-audio-vfx section 3e; ran in Studio 0.747 and 0.748 Play, 2026-11-18.
--
-- GroundBurst.play(point, opts?) -> clock
--   point          Vector3 on (or above) the floor; a raycast down finds the floor
--   opts.ringR     final radius of the ground ring (default 13 studs), opts.debris (default 18), opts.slabs (9)
--   opts.dust      dust puffs (default 28), opts.dir: Vector3 bias of the throw (default none), opts.scale (1)
--   opts.clock / opts.at / opts.seed
--
-- Beat table (clock s, 60 fps frames in brackets):
--   0.000 [0]      ground ring and shock wall start (radius 1 -> ringR over 0.32 s, out-quart), light pulse
--   0.000-0.10     rim slabs rise out of the floor, tilted outward, held, sink and shrink 1.1-1.5 s
--   0.017 [1]      debris thrown: life 70-120 frames (1.17-2.0 s), tumble, bounce on the floor, shrink away
--                  over the last 0.35 s of each piece's life
--   0.033 [2]      dust: puffs roll outward along the floor, life 30-70 frames (0.5-1.17 s), grow 2.5 -> 7 studs;
--                  more dust where a big piece lands
--   2.1            cleanup
-- Built to what four public showcase clips showed (read 2026-11-17; frame counts at each clip's own rate, 30 or 60
-- fps): debris cubes and slabs of 0.1-1x character height living 70-120 frames, dust or smoke 30-70 frames, lit by
-- the effect hue early and grey later; this layer carries the long hold after the peak.
-- What failed while building: 2.4-4.2 stud pieces piled into a wall of boxes on the target; dark, 35 %
-- transparent dust made a black ball; studded surfaces; debris lit only by Ambient 110 came out near black next
-- to the same-coloured floor (the stage's Ambient 135 / OutdoorAmbient 148 brings them to dark grey; measured).
-- Limits: debris are plain boxes and still read darker than the floor they came from; no crater decal.

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)
local Stage = require(script.Parent.cine_stage)

local GroundBurst = {}

local H = Stage.HUE
GroundBurst.DURATION = 2.1
GroundBurst.CAPTURE_TIMES = { 0.0, 0.017, 0.033, 0.05, 0.083, 0.12, 0.2, 0.3, 0.5, 0.75, 1.0, 1.3, 1.6, 1.9 }
GroundBurst.GRAVITY = 120

local function floorHit(p: Vector3)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = { workspace:FindFirstChild("FxRuntime"), workspace:FindFirstChild("CineStage") }
	local plr = game:GetService("Players").LocalPlayer
	if plr and plr.Character then
		table.insert(ex, plr.Character)
	end
	params.FilterDescendantsInstances = ex
	local r = workspace:Raycast(p + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), params)
	if r then
		return r.Position, r.Instance.Material, r.Instance.Color, r.Instance
	end
	return Vector3.new(p.X, 0, p.Z), Enum.Material.SmoothPlastic, Color3.fromRGB(125, 127, 131), nil
end
GroundBurst.floorHit = floorHit

function GroundBurst.play(point: Vector3, opts)
	opts = opts or {}
	local scale = opts.scale or 1
	local c, root, own = FxClock.attach("GroundBurst", GroundBurst.DURATION, opts)
	local rng = Random.new(opts.seed or 41)
	c:at(0, function()
		local p0, mat, col = floorHit(point)
		local y0 = p0.Y
		-- light pulse
		local la = c:attachment(CFrame.new(p0 + Vector3.new(0, 1.5, 0)))
		local light = c:light(la, { Range = 20 * scale, Color = H.cyan })
		c:span(0, 0.6, function(u)
			light.Brightness = 4.5 * (1 - u) ^ 2
		end)

		-- ground ring + dark ring (flat), and the shock wall (upright band)
		local ringR = (opts.ringR or 13) * scale
		local N = 20
		local function ring(props)
			return c:ribbon(N, props)
		end
		local flat = ring({ LightEmission = 0.8, Brightness = 2.5, ZOffset = 0.2, Segments = 6 })
		local dark = ring({ LightEmission = 0, Brightness = 1, ZOffset = 0, Segments = 6 })
		local wall = ring({ LightEmission = 0.7, Brightness = 2, ZOffset = 0.1, Segments = 6 })
		c:span(0, 0.5, function(u, t)
			local k = FxClock.outQuart(math.clamp(t / 0.32, 0, 1))
			local r = 1 + (ringR - 1) * k
			local rd = 1 + (ringR * 0.92 - 1) * FxClock.outQuart(math.clamp((t - 0.03) / 0.36, 0, 1))
			local fade = FxClock.smooth(0.12, 0.5, t)
			local function jf(rr, w, alpha, color, upright)
				return function(j)
					local th = (j - 1) / N * math.pi * 2
					local radial = Vector3.new(math.cos(th), 0, math.sin(th))
					local tan = Vector3.new(-math.sin(th), 0, math.cos(th))
					local pos = p0 + radial * rr + Vector3.new(0, if upright then w * 0.5 else 0.06, 0)
					local yv = if upright then Vector3.yAxis else radial
					return { cf = CFrame.fromMatrix(pos, tan, yv), width = w, alpha = alpha, color = color }
				end
			end
			flat.update(jf(r, (1.6 - 1.3 * k) * scale, 0.05 + 0.95 * fade, FxClock.ramp({ { 0, H.white }, { 0.3, H.hot }, { 1, H.cyan } }, k), false))
			dark.update(jf(rd, (2.6 - 1.8 * k) * scale, 0.45 + 0.55 * fade, H.navy, false))
			wall.update(jf(r * 0.97, (1.0 * (1 - k) + 0.15) * scale, 0.25 + 0.75 * FxClock.smooth(0.05, 0.35, t), FxClock.ramp({ { 0, H.white }, { 1, H.cyan } }, k), true))
			if t >= 0.5 then
				flat.hide()
				dark.hide()
				wall.hide()
			end
		end)

		-- rim slabs rising out of the floor
		local slabs = {}
		for i = 1, opts.slabs or 9 do
			local th = (i - 1) / (opts.slabs or 9) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
			local size = Vector3.new(rng:NextNumber(1.4, 2.6), rng:NextNumber(1.6, 3.0), rng:NextNumber(0.8, 1.4)) * scale
			local rr = rng:NextNumber(2.6, 3.6) * scale
			local part = c:part({ Name = "Slab", Size = size, Material = mat, Color = col, Transparency = 0, CastShadow = true })
			local radial = Vector3.new(math.cos(th), 0, math.sin(th))
			local base = CFrame.lookAt(p0 + radial * rr, p0 + radial * (rr + 1)) -- -Z points outward
			table.insert(slabs, { part = part, base = base, size = size, tilt = rng:NextNumber(25, 50), spin = rng:NextNumber(-20, 20) })
		end
		c:span(0, 1.5, function(_, t)
			local up = FxClock.outCubic(math.clamp(t / 0.1, 0, 1))
			local down = FxClock.smooth(1.1, 1.5, t)
			for _, s in slabs do
				local h = s.size.Y
				local rise = -h * 0.7 + h * 0.75 * up - h * 0.5 * down
				local k = 1 - down * 0.6
				s.part.Size = s.size * k
				s.part.CFrame = s.base * CFrame.new(0, rise, 0) * CFrame.Angles(math.rad(-s.tilt * up), math.rad(s.spin), 0)
			end
		end)

		-- debris: thrown, tumbling, bouncing, shrinking away
		local pieces = {}
		local n = opts.debris or 18
		for i = 1, n do
			local big = i <= 4
			-- r1: 2.4-4.2 stud pieces piled into a wall of boxes on the target; big pieces 1.6-3, fewer stay close
			local sz = if big then rng:NextNumber(1.6, 3.0) else rng:NextNumber(0.45, 1.4)
			local size = Vector3.new(sz * rng:NextNumber(0.7, 1.2), sz * rng:NextNumber(0.5, 0.9), sz * rng:NextNumber(0.7, 1.2)) * scale
			local th = rng:NextNumber() * math.pi * 2
			local out = Vector3.new(math.cos(th), 0, math.sin(th))
			if opts.dir then
				out = (out + opts.dir.Unit * 0.8).Unit
			end
			local speed = if big then rng:NextNumber(12, 20) else rng:NextNumber(14, 30)
			local vy = if big then rng:NextNumber(22, 34) else rng:NextNumber(26, 46)
			local life = rng:NextInteger(70, 120) / 60
			local part = c:part({ Name = "Debris", Size = size, Material = mat, Color = col, Transparency = 0, CastShadow = true })
			part.LocalTransparencyModifier = 1
			table.insert(pieces, {
				part = part,
				size = size,
				p = p0 + out * rng:NextNumber(0.5, 2.0) * scale + Vector3.new(0, size.Y * 0.5, 0),
				v = out * speed * scale + Vector3.new(0, vy * math.sqrt(scale), 0),
				r = CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)),
				w = Vector3.new(rng:NextNumber(-9, 9), rng:NextNumber(-9, 9), rng:NextNumber(-9, 9)),
				life = life,
				big = big,
				landed = false,
			})
		end
		local dustAtt = c:attachment(CFrame.new(p0))
		local dust = c:emitter(dustAtt, {
			Name = "Dust",
			Lifetime = NumberRange.new(0.5, 1.17),
			Speed = NumberRange.new(0),
			Drag = 2.2,
			RotSpeed = NumberRange.new(-30, 30),
			Acceleration = Vector3.new(0, 1.2, 0),
			-- r1: dark (92-150 grey, LightInfluence 0.6) and 35 % transparent puffs made a black ball on the target
			Size = FxClock.ns({ { 0, 2.5 * scale, 0.5 }, { 1, 7 * scale, 1.2 } }),
			Transparency = FxClock.ns({ { 0, 1 }, { 0.1, 0.5 }, { 0.6, 0.7 }, { 1, 1 } }),
			Color = FxClock.cs({ { 0, Color3.fromRGB(176, 179, 184) }, { 1, Color3.fromRGB(150, 153, 158) } }),
			LightEmission = 0,
			LightInfluence = 0,
			ZOffset = -1,
		})
		FxTextures.apply(dust, "smoke")
		-- each puff from its own place and direction (emitAt: moving one emitter put every puff of a step at the last)
		local function puff(at: Vector3, vel: Vector3, k)
			local cf = CFrame.lookAt(at, at + vel) * CFrame.Angles(-math.pi / 2, 0, 0) -- emitter Top = +Y of the attachment
			c:emitAt(dust, cf, k, { Speed = NumberRange.new(vel.Magnitude) })
		end
		c:at(0.033, function()
			local nd = opts.dust or 28
			for i = 1, nd do
				local th = (i - 1) / nd * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
				local radial = Vector3.new(math.cos(th), 0, math.sin(th))
				puff(p0 + radial * rng:NextNumber(1.5, 3.5) * scale + Vector3.new(0, 0.8, 0), radial * rng:NextNumber(12, 20) * scale + Vector3.new(0, rng:NextNumber(0, 1.5), 0), 1)
			end
		end)
		c:at(0.2, function()
			for _ = 1, 8 do
				local th = rng:NextNumber() * math.pi * 2
				local radial = Vector3.new(math.cos(th), 0, math.sin(th))
				puff(p0 + radial * rng:NextNumber(3, 6) * scale + Vector3.new(0, 1.2, 0), radial * rng:NextNumber(3, 6) + Vector3.new(0, 3, 0), 1)
			end
		end)
		c:every(function(t, dt)
			if t < 0.017 then
				return
			end
			for _, d in pieces do
				local age = t - 0.017
				if age > d.life then
					d.part.LocalTransparencyModifier = 1
					continue
				end
				d.part.LocalTransparencyModifier = 0
				if dt > 0 then
					d.v += Vector3.new(0, -GroundBurst.GRAVITY * dt, 0)
					d.p += d.v * dt
					d.r = d.r * CFrame.Angles(d.w.X * dt, d.w.Y * dt, d.w.Z * dt)
					local hy = d.size.Y * 0.4
					if d.p.Y < y0 + hy then
						d.p = Vector3.new(d.p.X, y0 + hy, d.p.Z)
						if d.v.Y < -6 then
							if d.big and not d.landed then
								d.landed = true
								puff(d.p, Vector3.new(0, 4, 0), 2)
							end
							d.v = Vector3.new(d.v.X * 0.55, -d.v.Y * 0.28, d.v.Z * 0.55)
							d.w *= 0.5
						else
							d.v = Vector3.new(d.v.X * 0.8, 0, d.v.Z * 0.8)
							d.w *= 0.8
						end
					end
				end
				local k = 1 - FxClock.smooth(d.life - 0.35, d.life, age)
				d.part.Size = d.size * math.max(k, 0.02)
				d.part.CFrame = CFrame.new(d.p) * d.r
			end
		end)
	end)
	if own then
		root:play()
	end
	return root
end

return GroundBurst
