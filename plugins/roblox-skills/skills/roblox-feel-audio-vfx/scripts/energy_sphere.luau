--!nonstrict
-- energy_sphere: a charge ball that grows from a point to about two character heights across, with inner motion
-- (arcs and sparks inside, a patterned shell), a bright jagged rim that changes every 1-2 frames, a dark halo
-- behind it for contrast, a white-out at its peak that decays over about 10 frames, a blink-out at the end and a
-- grey smoke cloud where it pops. Client only, on the fx clock. roblox-feel-audio-vfx section 3e; ran in Studio
-- 0.747 and 0.748 Play, 2026-11-18.
--
-- EnergySphere.play(anchor, opts?) -> clock
--   anchor        BasePart (followed until the burst) | Vector3 | function() -> Vector3
--   opts.burstAt  Vector3 | function() -> Vector3: where the ball sits from the burst on (default the anchor)
--   opts.charge   s of the small charge ball before the burst (default 0.6), opts.rCharge (default 0.55)
--   opts.R        radius after the burst (default 6 studs, 2.3 character heights across)
--   opts.burst    s to grow from rCharge to R (default 0.22), opts.hold (default 1.1), opts.blink (default true)
--   opts.whiteout false to skip the screen white-out (ImpactFrames.whiteout, through Safety)
--   opts.clock / opts.at / opts.seed
--
-- Layers (inside out): white Neon core 0.45r during the charge, 0.3r after the burst (pulses), cyan Neon body
-- 0.8r at 62 % transparency, two ForceField shells at 1.0r and 1.06r (fresnel edge + the material's own moving
-- pattern), 3 inner lightning arcs (re-shaped every 1.5 frames), a jagged camera-facing rim (a closed 28-point
-- ring 1.0-1.12r plus 7 outward spikes, white core and cyan body beams, re-shaped every 1.5 frames), inner sparks,
-- inward streaks during the charge, a navy soft halo 2.4r behind (LightEmission 0, off during the charge) and a
-- PointLight (range 3r).
--
-- Built to what four public showcase clips showed (read 2026-11-17; frame counts at each clip's own rate, 30 or 60
-- fps): sphere radius about 1.5x the character height; a soft body with a spiky rim that jitters per frame; round
-- from every angle; a white flash in; blink out (on 2 frames, off 2, on 2); a grey smoke cloud that fills its
-- volume and clears.
-- What failed while building: a 0.45r core washed the middle of every close peak shot white (0.3r after the
-- burst); the navy halo behind the small charge ball read as a dark disc (off during the charge); a 0.45 halo
-- read as a grey smudge on the day stage (0.6).
-- Limits: the rim is a chain of straight beam segments and reads beaded, not as one bright jagged edge; the body
-- has no texture motion of its own (arcs and the ForceField pattern carry it).

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)
local Stage = require(script.Parent.cine_stage)
local Lightning = require(script.Parent.lightning)
local ImpactFrames = require(script.Parent.impact_frames)

local EnergySphere = {}

local H = Stage.HUE
EnergySphere.DURATION = 2.2
EnergySphere.CAPTURE_TIMES = { 0.1, 0.4, 0.6, 0.617, 0.633, 0.65, 0.667, 0.7, 0.75, 0.82, 0.9, 1.1, 1.4, 1.62, 1.68, 1.75 }

local function pos(a): Vector3
	local t = typeof(a)
	if t == "Vector3" then
		return a
	elseif t == "function" then
		return a()
	elseif t == "CFrame" then
		return a.Position
	end
	return a.Position
end

function EnergySphere.play(anchor, opts)
	opts = opts or {}
	local charge = opts.charge or 0.6
	local rC = opts.rCharge or 0.55
	local R = opts.R or 6
	local burst = opts.burst or 0.22
	local hold = opts.hold or 1.1
	local blink = opts.blink ~= false
	local tEnd = charge + burst + hold + (if blink then 0.12 else 0.2)
	local smoke = opts.smoke ~= false
	local c, root, own = FxClock.attach("EnergySphere", tEnd + (if smoke then 1.8 else 0.05), opts)
	local rng = Random.new(opts.seed or 31)
	local cam = workspace.CurrentCamera
	local burstPos = nil

	local function centre(t): Vector3
		if t >= charge then
			if not burstPos then
				burstPos = if opts.burstAt then pos(opts.burstAt) else pos(anchor)
			end
			return burstPos
		end
		return pos(anchor)
	end
	local function radius(t): number
		if t < charge then
			-- appears from a point over 0.15 s, then breathes
			local g = FxClock.outCubic(math.clamp(t / 0.15, 0, 1))
			return rC * g * (1 + 0.08 * math.sin(t * 40))
		elseif t < charge + burst then
			local u = (t - charge) / burst
			return rC + (R - rC) * FxClock.outQuart(u)
		elseif t < charge + burst + hold then
			local h = t - charge - burst
			return R * (1 + 0.025 * math.sin(h * 30) + 0.04 * h / hold)
		end
		return R * 1.04
	end
	local function visible(t): boolean
		if t >= tEnd then
			return false
		end
		if blink and t >= charge + burst + hold then
			local k = math.floor((t - charge - burst - hold) / (1 / 30)) -- on 2 f, off 2 f at 60 fps
			return k % 2 == 1 and k < 3
		end
		return true
	end

	c:at(0, function()
		local function ball(name, mat, color, alpha)
			return c:part({ Name = name, Shape = Enum.PartType.Ball, Material = mat, Color = color, Transparency = alpha, Size = Vector3.one * 0.1 })
		end
		local core = ball("Core", Enum.Material.Neon, H.white, 0)
		local body = ball("Body", Enum.Material.Neon, H.cyan, 0.62)
		local shellA = ball("ShellA", Enum.Material.ForceField, H.cyan, 0)
		local shellB = ball("ShellB", Enum.Material.ForceField, H.blue, 0)
		local halo = c:attachment(nil)
		local haloE = c:emitter(halo, {
			Name = "DarkHalo",
			Lifetime = NumberRange.new(10),
			Size = NumberSequence.new(1),
			Transparency = NumberSequence.new(0.6), -- r2: 0.45 read as a dirty grey smudge on the day stage
			Color = ColorSequence.new(H.navy),
			LightEmission = 0,
			ZOffset = -3,
			Rotation = NumberRange.new(0),
		})
		FxTextures.apply(haloE, "glow")
		local light = c:light(core, { Range = 4, Color = H.cyan })
		-- charge streaks: spawn on a sphere, fly inward
		local inAtt = c:attachment(nil)
		local inward = c:emitter(inAtt, {
			Name = "ChargeIn",
			EmissionDirection = Enum.NormalId.Front, -- the attachment looks at the centre
			Lifetime = NumberRange.new(0.18, 0.28),
			Speed = NumberRange.new(9, 14),
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Rotation = NumberRange.new(90),
			Squash = FxClock.ns({ { 0, 1.5 }, { 1, 1.5 } }),
			Size = FxClock.ns({ { 0, 0.1 }, { 0.5, 0.35 }, { 1, 0.05 } }),
			Transparency = FxClock.ns({ { 0, 1 }, { 0.2, 0 }, { 1, 0.2 } }),
			Color = FxClock.cs({ { 0, H.cyan }, { 1, H.white } }),
			LightEmission = 1,
			Brightness = 3,
		})
		FxTextures.apply(inward, "streak")
		local sparks = c:emitter(core, {
			Name = "InnerSparks",
			Lifetime = NumberRange.new(0.15, 0.35),
			Speed = NumberRange.new(4, 10),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 3,
			Size = FxClock.ns({ { 0, 0.5 }, { 1, 0.05 } }),
			Transparency = FxClock.ns({ { 0, 0 }, { 1, 1 } }),
			Color = FxClock.cs({ { 0, H.white }, { 1, H.cyan } }),
			LightEmission = 1,
			Brightness = 4,
		})
		FxTextures.apply(sparks, "star")
		-- inner arcs
		local arcs = {}
		for k = 1, 3 do
			arcs[k] = Lightning.newBolt(c, 9, 1, 3, 0.06, nil)
		end
		-- rim: a closed jagged ring in the camera plane plus outward spikes (two beam layers)
		local NR, NS = 28, 7
		local ringAtt = {}
		for i = 1, NR do
			ringAtt[i] = c:attachment(nil)
		end
		local spikeAtt = {}
		for i = 1, NS * 2 do
			spikeAtt[i] = c:attachment(nil)
		end
		local rimBeams = {}
		local function rimBeam(a0, a1, w, color, bright, alpha)
			local b = c:beam(a0, a1, {
				FaceCamera = true,
				Segments = 1,
				Width0 = w,
				Width1 = w,
				Color = ColorSequence.new(color),
				Transparency = NumberSequence.new(alpha),
				LightEmission = 1,
				Brightness = bright,
				ZOffset = 1,
			})
			table.insert(rimBeams, { b = b, w = w })
			return b
		end
		for i = 1, NR do
			local j = i % NR + 1
			rimBeam(ringAtt[i], ringAtt[j], 0.05, H.white, 5, 0)
			rimBeam(ringAtt[i], ringAtt[j], 0.2, H.cyan, 2.5, 0.25)
		end
		for s = 1, NS do
			local b = rimBeam(spikeAtt[s * 2 - 1], spikeAtt[s * 2], 0.08, H.hot, 4, 0)
			b.Width1 = 0
		end

		local stepK = -1
		local sparkAcc = 0
		c:every(function(t, dt)
			local on = visible(t)
			local r = radius(t)
			local p = centre(t)
			local inCharge = t < charge
			for _, part in { core, body, shellA, shellB } do
				part.LocalTransparencyModifier = if on then 0 else 1
			end
			local pulse = 1 + 0.08 * math.sin(t * 45)
			-- r1: a 0.45r white core washed the middle of every close peak shot to white
			core.Size = Vector3.one * (2 * r * (if inCharge then 0.45 else 0.3) * pulse)
			body.Size = Vector3.one * (2 * r * 0.8)
			shellA.Size = Vector3.one * (2 * r)
			shellB.Size = Vector3.one * (2 * r * 1.06)
			core.CFrame = CFrame.new(p)
			body.CFrame = CFrame.new(p)
			shellA.CFrame = CFrame.new(p) * CFrame.Angles(0, t * 2.2, 0)
			shellB.CFrame = CFrame.new(p) * CFrame.Angles(t * 1.3, -t * 1.7, 0)
			halo.WorldPosition = p
			haloE.Size = NumberSequence.new(r * 2.4)
			-- r1: during the charge the dark halo made the small ball read as a dark disc with a ring: off then
			local haloOn = on and not inCharge
			if haloOn and not haloE:GetAttribute("on") then
				haloE:SetAttribute("on", true)
				haloE:Clear()
				haloE:Emit(1)
			elseif not haloOn and haloE:GetAttribute("on") then
				haloE:SetAttribute("on", false)
				haloE:Clear()
			end
			light.Range = math.clamp(r * 3, 4, 40)
			light.Brightness = if on then (if inCharge then 2 else 3.5) else 0
			-- inward streaks: emitted from a sphere 2.2 studs out during the charge
			if inCharge then
				sparkAcc += 60 * dt
				local n = math.floor(sparkAcc)
				if n > 0 then
					sparkAcc -= n
					-- each streak starts 2.4 studs out on a random direction, aimed at the centre
					for _ = 1, n do
						local d = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
						if d.Magnitude > 0.01 then
							d = d.Unit
							inAtt.WorldCFrame = CFrame.lookAt(p + d * 2.4, p)
							inward:Emit(1)
						end
					end
				end
			elseif on and t < charge + burst + hold then
				if rng:NextNumber() < 0.6 then
					sparks:Emit(1)
				end
			end
			-- re-shape arcs and rim every step
			local k = math.floor(t / Lightning.STEP)
			if k ~= stepK then
				stepK = k
				for _, a in arcs do
					if on and r > 0.3 then
						local d1 = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
						local d2 = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
						local pts = Lightning.jag(rng, p + d1 * r * 0.85, p + d2 * r * 0.85, 3, 0.25)
						a.set(pts, nil, math.max(r / 3, 0.4))
					else
						a.hide()
					end
				end
				local camCF = cam.CFrame
				local right, up = camCF.RightVector, camCF.UpVector
				local toCam = (camCF.Position - p).Unit
				local rimP = p + toCam * r * 0.2
				for i = 1, NR do
					local th = (i - 1) / NR * math.pi * 2
					local rr = r * (1.0 + rng:NextNumber(0, 0.12))
					ringAtt[i].WorldPosition = rimP + (right * math.cos(th) + up * math.sin(th)) * rr
				end
				for s = 1, NS do
					local th = rng:NextNumber() * math.pi * 2
					local d = right * math.cos(th) + up * math.sin(th)
					spikeAtt[s * 2 - 1].WorldPosition = rimP + d * r * 1.02
					spikeAtt[s * 2].WorldPosition = rimP + d * r * (1.15 + rng:NextNumber(0.1, 0.4))
				end
				local wk = if inCharge then r / 2.2 else math.max(r / 3, 0.25)
				for _, rb in rimBeams do
					rb.b.Enabled = on and r > 0.2
					rb.b.Width0 = rb.w * wk
					if rb.b.Width1 > 0 then
						rb.b.Width1 = rb.w * wk
					end
				end
			end
		end)
	end)
	-- the ball pops into a grey smoke cloud that fills its volume and clears
	if smoke then
		c:at(charge + burst + hold, function()
			local p = centre(charge + burst + hold)
			local att = c:attachment(CFrame.new(p))
			local e = c:emitter(att, {
				Name = "PopSmoke",
				Lifetime = NumberRange.new(1.1, 1.7),
				Speed = NumberRange.new(2, 7),
				SpreadAngle = Vector2.new(180, 180),
				Drag = 1.5,
				Acceleration = Vector3.new(0, 1.5, 0),
				RotSpeed = NumberRange.new(-25, 25),
				Size = FxClock.ns({ { 0, R * 0.7, 0.3 }, { 1, R * 1.25 } }),
				Transparency = FxClock.ns({ { 0, 1 }, { 0.1, 0.3 }, { 0.65, 0.6 }, { 1, 1 } }),
				Color = FxClock.cs({ { 0, Color3.fromRGB(200, 214, 222) }, { 0.3, H.smoke1 }, { 1, H.smoke0 } }),
				LightEmission = 0,
				LightInfluence = 0.5,
				ZOffset = -1,
			})
			FxTextures.apply(e, "smoke")
			for _ = 1, 16 do
				local d = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.9, 0.4), rng:NextNumber(-1, 1))
				att.WorldPosition = p + d * R * 0.6
				e:Emit(1)
			end
		end)
	end
	if opts.whiteout ~= false then
		ImpactFrames.whiteout({ clock = c, at = charge, hold = 0.1, decay = 0.17 })
	end
	if own then
		root:play()
	end
	return root
end

function EnergySphere.demo(hero, opts)
	opts = opts or {}
	local fist = hero:FindFirstChild("RightHand")
	local target = Stage.target()
	local tp = target:FindFirstChild("UpperTorso").Position
	local hp = hero:FindFirstChild("UpperTorso").Position
	local dir = (tp - hp).Unit
	return EnergySphere.play(fist, {
		clock = opts.clock,
		at = opts.at,
		burstAt = tp + dir * 4 + Vector3.new(0, 0.5, 0),
	})
end

return EnergySphere
