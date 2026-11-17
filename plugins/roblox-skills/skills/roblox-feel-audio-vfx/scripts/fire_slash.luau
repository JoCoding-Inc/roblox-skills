--!nonstrict
-- fire_slash: a sword swing with a fire crescent, trail, flames, embers, char smoke and a light
-- (roblox-feel-audio-vfx section 3d, recipe card "Fire slash"). Needs fx_clock and fx_textures in the same folder.
-- FireSlash.play(character | rootCFrame, opts?) -> clock. Client only (a LocalScript requires it).
-- The sword (a BasePart named "Sword" in the character, or a temporary one) is posed by the clock along the arc;
-- an IKControl pulls the right arm to it. The character's own Sword is hidden locally while a client copy swings.
-- opts.noPlay = true returns the clock unstarted (call clock:play()).
-- Ran in Studio 0.747 Play on 2026-11-17 on an R15 dummy (desktop view and the Samsung Galaxy A06 Device
-- Simulator preset); not checked in a published game or on a real phone; frame cost not measured.
--
-- Beat table (clock seconds, read from the code below):
-- 0.00-0.12  wind-up: sword moves from rest to the start of the arc (in-out sine)
-- 0.12-0.24  swing: 205 deg sweep, fast start (1 - (1 - u)^2.2)
-- 0.12-0.50  ribbons (trail, dark under, body, hot edge): each joint is born as the blade passes it, then
--            fades over 0.08 s (trail), 0.20 s (under), 0.16 s (body), 0.12 s (edge): the tail erodes first
-- 0.13-0.27  flames: 110/s along the outer blade (about 15), then 12/s to 0.33, each 0.3-0.5 s, rising
-- 0.14-0.50  light: orange PointLight, peak 3.5 at 0.20, 0 at 0.50
-- 0.20/0.23  embers: two bursts of 18 soft dots from three points on the arc, each 0.5-0.9 s
-- 0.26       smoke: 6 dark puffs along the arc, 0.7-1.0 s, behind (ZOffset -2)
-- 0.24-0.50  follow-through (+12 deg), 0.50-0.85 return to rest; 1.30 cleanup

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local FireSlash = {}

local C = Color3.fromRGB
FireSlash.DURATION = 1.3
FireSlash.CAPTURE_TIMES = { 0.08, 0.14, 0.165, 0.19, 0.21, 0.23, 0.26, 0.31, 0.38, 0.5, 0.7, 0.95 }

-- Tunables: sizes in studs, angles in degrees; le = LightEmission, bright = Brightness, z = ZOffset.
FireSlash.P = {
	pivot = Vector3.new(0.45, 0.9, -0.35), -- arc centre in root space (right chest)
	tilt = 55, -- deg: start direction between right (0) and up (90)
	thetaStart = -15,
	thetaEnd = 190,
	rHilt = 1.2,
	bladeLength = 4.2,
	segments = 14,
	trail = { r = 3.6, w = 2.6, grow = 0.001, fade0 = 0, fade1 = 0.08, alpha0 = 0.7, shrink = 0.3, le = 0.6, bright = 1.5, z = -0.6 },
	under = { r = 4.4, w = 1.9, grow = 0.02, fade0 = 0.05, fade1 = 0.2, alpha0 = 0.5, shrink = 0.7, le = 0, bright = 1, z = -0.3 },
	body = { r = 4.4, w = 1.4, grow = 0.02, fade0 = 0.03, fade1 = 0.16, alpha0 = 0, shrink = 0.9, le = 0.35, bright = 2, z = 0 },
	edge = { r = 4.95, w = 0.35, grow = 0.01, fade0 = 0.03, fade1 = 0.12, alpha0 = 0, shrink = 0.6, le = 1, bright = 5, z = 0.4 },
	flameRate = 110,
	emberCount = 18,
	smokeCount = 6,
	light = { range = 12, peak = 3.5 },
}

local PAL = {
	white = C(255, 252, 240),
	yellow = C(255, 214, 90),
	orange = C(255, 128, 32),
	red = C(200, 40, 10),
	char = C(70, 14, 6),
	smoke0 = C(55, 40, 35),
	smoke1 = C(95, 90, 85),
}

local RAMPS = {
	trail = { { 0, C(255, 150, 50) }, { 0.08, C(200, 60, 20) } },
	under = { { 0, C(60, 10, 4) }, { 1, C(60, 10, 4) } },
	body = { { 0, C(255, 225, 120) }, { 0.025, C(255, 170, 50) }, { 0.06, C(255, 110, 25) }, { 0.12, C(220, 50, 12) }, { 0.2, C(140, 20, 8) } },
	edge = { { 0, PAL.white }, { 0.04, C(255, 240, 170) }, { 0.1, C(255, 190, 80) } },
}

local function resolveTarget(target)
	if typeof(target) == "CFrame" then
		return target, nil
	end
	local root = target:FindFirstChild("HumanoidRootPart")
	return root.CFrame, target
end

function FireSlash.play(target, opts)
	opts = opts or {}
	local P = FireSlash.P
	local rootCF, character = resolveTarget(target)
	local clock = FxClock.new("FireSlash", FireSlash.DURATION)
	local lerp, smooth = FxClock.lerp, FxClock.smooth

	-- Arc frame: dir(theta) = e1 cos + e2 sin; e1 up-right, e2 forward; n the plane normal.
	local centre = (rootCF * CFrame.new(P.pivot)).Position
	local tilt = math.rad(P.tilt)
	local e1 = (rootCF.RightVector * math.cos(tilt) + rootCF.UpVector * math.sin(tilt)).Unit
	local look = rootCF.LookVector
	local e2 = (look - e1 * look:Dot(e1)).Unit
	local n = e1:Cross(e2).Unit
	local function dir(th)
		return e1 * math.cos(th) + e2 * math.sin(th)
	end
	local function tangent(th)
		return -e1 * math.sin(th) + e2 * math.cos(th)
	end
	local th0, th1 = math.rad(P.thetaStart), math.rad(P.thetaEnd)

	-- Sword ---------------------------------------------------------------------------------------
	-- The character's own Sword is hidden locally and a client clone swings instead: moving the server-owned
	-- part on the client lost to replication on frozen frames (measured: the sword snapped back to the hand).
	local original = character and character:FindFirstChild("Sword", true)
	local hand = character and character:FindFirstChild("RightHand", true)
	local sword
	if original then
		sword = original:Clone()
		for _, d in sword:GetDescendants() do
			if (d:IsA("JointInstance") or d:IsA("WeldConstraint")) and not ((d.Part0 == nil or d.Part0:IsDescendantOf(sword) or d.Part0 == sword) and (d.Part1 == nil or d.Part1:IsDescendantOf(sword) or d.Part1 == sword)) then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
			end
		end
		sword.Anchored = true
		sword.CanCollide = false
		sword.Parent = clock.model
		local hidden = { original }
		for _, d in original:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(hidden, d)
			end
		end
		for _, part in hidden do
			part.LocalTransparencyModifier = 1
		end
		clock:onCleanup(function()
			for _, part in hidden do
				part.LocalTransparencyModifier = 0
			end
		end)
	else
		sword = clock:part({ Name = "TempSword", Size = Vector3.new(0.3, 0.12, P.bladeLength), Transparency = 0, Color = C(200, 205, 215), Material = Enum.Material.Metal })
	end
	local L = sword.Size.Z
	local restRel = if hand and original then hand.CFrame:Inverse() * original.CFrame else nil
	local function swordAt(th)
		local mid = centre + dir(th) * (P.rHilt + L / 2)
		return CFrame.lookAt(mid, mid + dir(th), n)
	end
	local function restCF()
		if hand and restRel then
			return hand.CFrame * restRel
		end
		return swordAt(th0 - math.rad(60))
	end
	local rest0 = restCF()
	local function blendCF(a, b, u)
		return a:Lerp(b, u)
	end

	-- Swing angle over clock time (nil = not on the arc).
	local function swingTheta(t)
		if t < 0.12 then
			return nil
		elseif t < 0.24 then
			local u = (t - 0.12) / 0.12
			return th0 + (th1 - th0) * (1 - (1 - u) ^ 2.2)
		elseif t < 0.5 then
			return th1 + math.rad(12) * FxClock.outCubic((t - 0.24) / 0.26)
		end
		return th1 + math.rad(12)
	end

	-- Arm IK (best effort; needs an Animator under the Humanoid).
	local ik, ikTarget
	local handRel = if hand and original then original.CFrame:Inverse() * hand.CFrame else nil
	if character and hand and original then
		local hum = character:FindFirstChildOfClass("Humanoid")
		local upper = character:FindFirstChild("RightUpperArm")
		if hum and upper then
			ikTarget = clock:attachment(hand.CFrame)
			pcall(function()
				ik = Instance.new("IKControl")
				ik.Type = Enum.IKControlType.Transform
				ik.ChainRoot = upper
				ik.EndEffector = hand
				ik.Target = ikTarget
				ik.SmoothTime = 0
				ik.Weight = 0
				ik.Parent = hum
			end)
			clock:onCleanup(function()
				if ik then
					ik:Destroy()
				end
			end)
		end
	end

	clock:every(function(t)
		local cf
		local th = swingTheta(t)
		if t < 0.12 then
			cf = blendCF(rest0, swordAt(th0), FxClock.inOutSine(t / 0.12))
		elseif t < 0.5 then
			cf = swordAt(th)
		elseif t < 0.85 then
			cf = blendCF(swordAt(th), restCF(), FxClock.inOutSine((t - 0.5) / 0.35))
		else
			cf = restCF()
		end
		sword.CFrame = cf
		if ik and handRel then
			ikTarget.WorldCFrame = cf * handRel
			ik.Weight = if t < 0.85 then smooth(0, 0.06, t) else 1 - smooth(0.85, 0.95, t)
		end
	end)

	-- Crescent and trail ribbons ------------------------------------------------------------------
	local segs = P.segments
	local jointTheta = {}
	local birth = {}
	local thFirst, thLast = th0 + math.rad(6), th1 + math.rad(12)
	for j = 1, segs + 1 do
		jointTheta[j] = lerp(thFirst, thLast, (j - 1) / segs)
	end
	local prevT, prevTh = 0, nil
	clock:every(function(t)
		local th = swingTheta(t)
		if th and prevTh then
			for j = 1, segs + 1 do
				if not birth[j] and th >= jointTheta[j] then
					local f = if th > prevTh then (jointTheta[j] - prevTh) / (th - prevTh) else 1
					birth[j] = lerp(prevT, t, math.clamp(f, 0, 1))
				end
			end
		end
		prevT, prevTh = t, th
	end)

	local function makeLayer(name, slot)
		local q = P[name]
		local props = { LightEmission = q.le, Brightness = q.bright, ZOffset = q.z, Segments = 8 }
		local ribbon = clock:ribbon(segs, props)
		if slot then
			-- every beam gets the band texture, wrapped finely so the joints between beams do not show
			for _, b in ribbon.beams do
				FxTextures.apply(b, slot)
				b.TextureMode = Enum.TextureMode.Wrap
				b.TextureLength = 0.05
			end
		end
		clock:every(function(t)
			local th = swingTheta(t)
			local headDone = false
			ribbon.update(function(j)
				local tj = jointTheta[j]
				local u = (j - 1) / segs
				local taper = 0.35 + 0.65 * math.sin(math.pi * u) ^ 0.6
				if birth[j] then
					local age = t - birth[j]
					local w = q.w * taper * smooth(0, q.grow, age) * (1 - q.shrink * smooth(q.fade0, q.fade1, age))
					local a = q.alpha0 + (1 - q.alpha0) * smooth(q.fade0, q.fade1, age)
					local pos = centre + dir(tj) * q.r
					return { cf = CFrame.fromMatrix(pos, tangent(tj), dir(tj)), width = w, alpha = a, color = FxClock.ramp(RAMPS[name], age) }
				elseif th and not headDone and th > thFirst then
					headDone = true
					local pos = centre + dir(th) * q.r
					return { cf = CFrame.fromMatrix(pos, tangent(th), dir(th)), width = 0, alpha = q.alpha0, color = FxClock.ramp(RAMPS[name], 0) }
				end
				return nil
			end)
		end)
		return ribbon
	end
	makeLayer("trail", nil)
	makeLayer("under", nil)
	makeLayer("body", nil) -- untextured: the band texture wrapped at 0.05 striped (moire) on capture
	makeLayer("edge", nil)

	-- Flames along the outer blade ----------------------------------------------------------------
	local flameBox = clock:part({ Name = "FlameBox", Size = Vector3.new(0.5, 0.5, 2.6) })
	local fireTex = FxTextures.get("fire")
	local flame = clock:emitter(flameBox, {
		Name = "Flames",
		EmissionDirection = Enum.NormalId.Top,
		Shape = Enum.ParticleEmitterShape.Box,
		Lifetime = NumberRange.new(0.3, 0.5),
		Speed = NumberRange.new(0.5, 2),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 4, 0),
		Drag = 2,
		RotSpeed = NumberRange.new(-90, 90),
		Size = FxClock.ns({ { 0, 1.0, 0.2 }, { 0.2, 2.1, 0.3 }, { 1, 0.9 } }),
		Transparency = FxClock.ns({ { 0, 1 }, { 0.12, 0.2, 0.1 }, { 0.6, 0.45 }, { 1, 1 } }), -- fade in: frame 0 of the sheet read as a red ball
		Color = if fireTex.flipbook
			then FxClock.cs({ { 0, C(255, 245, 220) }, { 0.5, C(255, 170, 90) }, { 1, C(160, 60, 30) } })
			else FxClock.cs({ { 0, C(255, 240, 200) }, { 0.2, C(255, 190, 60) }, { 0.5, PAL.orange }, { 1, C(120, 30, 10) } }),
		LightEmission = if fireTex.flipbook then 0.35 else 0.7,
		Brightness = 2,
		ZOffset = 0.2,
	})
	FxTextures.apply(flame, "fire")
	flame.FlipbookStartRandom = false
	local function placeFlameBox(t)
		local th = swingTheta(t) or th0
		local mid = centre + dir(th) * (P.rHilt + L * 0.68)
		flameBox.CFrame = CFrame.lookAt(mid, mid + dir(th), n) -- long axis on the blade, Top = plane normal
	end
	clock:stream(flame, 0.13, 0.27, function()
		return P.flameRate
	end, placeFlameBox)
	-- the tail stream stops at 0.33: run on, it followed the blade into follow-through and burned at the hip (0.38-0.5 s)
	clock:stream(flame, 0.27, 0.33, function()
		return 12
	end, placeFlameBox)

	-- Embers off the tip --------------------------------------------------------------------------
	local emberAtt = clock:attachment(nil)
	local ember = clock:emitter(emberAtt, {
		Name = "Embers",
		EmissionDirection = Enum.NormalId.Top,
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(35, 35),
		Acceleration = Vector3.new(0, 2, 0),
		Drag = 2.5,
		-- VelocityParallel made the ember sprites vanish on every capture; facing the camera they read.
		-- The additive black-backed streak was invisible on the daylight floor and a burst at the tip flew
		-- behind the hero into the floor; now soft dots, alpha-blended, from three arc points, outward and up
		Size = FxClock.ns({ { 0, 0.55, 0.1 }, { 1, 0.15 } }),
		Transparency = FxClock.ns({ { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } }),
		Color = FxClock.cs({ { 0, C(255, 235, 150) }, { 0.35, C(255, 150, 30) }, { 1, C(200, 50, 10) } }),
		LightEmission = 0.5,
		Brightness = 3,
		ZOffset = 0.6,
	})
	FxTextures.apply(ember, "glow")
	local function emberBurst()
		for _, f in { 0.45, 0.7, 0.92 } do
			local th = th0 + (th1 - th0) * f
			local p = centre + dir(th) * (P.rHilt + L * 0.9)
			local out = (dir(th) + Vector3.yAxis * 0.6).Unit
			emberAtt.WorldCFrame = CFrame.fromMatrix(p, out:Cross(n).Magnitude > 0.1 and out:Cross(n).Unit or Vector3.xAxis, out)
			ember:Emit(math.ceil(P.emberCount / 3))
		end
	end
	clock:at(0.2, emberBurst)
	clock:at(0.23, emberBurst)

	-- Char smoke along the arc --------------------------------------------------------------------
	local smokeAtt = clock:attachment(nil)
	local smoke = clock:emitter(smokeAtt, {
		Name = "Smoke",
		Lifetime = NumberRange.new(0.7, 1.0),
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 2.5, 0),
		Drag = 1,
		RotSpeed = NumberRange.new(-40, 40),
		Size = FxClock.ns({ { 0, 1.4, 0.3 }, { 1, 3.4, 0.4 } }),
		Transparency = FxClock.ns({ { 0, 1 }, { 0.12, 0.5 }, { 0.6, 0.7 }, { 1, 1 } }),
		Color = FxClock.cs({ { 0, PAL.smoke0 }, { 1, PAL.smoke1 } }),
		LightEmission = 0,
		ZOffset = -2,
	})
	FxTextures.apply(smoke, "smoke")
	clock:at(0.26, function()
		for k = 1, P.smokeCount do
			local th = lerp(thFirst, th1, (k - 0.5) / P.smokeCount)
			smokeAtt.WorldCFrame = CFrame.new(centre + dir(th) * P.body.r)
			smoke:Emit(1)
		end
	end)

	-- Light ---------------------------------------------------------------------------------------
	local lightAtt = clock:attachment(CFrame.new(centre + dir(math.rad(90)) * 3))
	local light = clock:light(lightAtt, { Range = P.light.range, Color = C(255, 150, 60) })
	clock:span(0.14, 0.5, function(_, t)
		if t < 0.2 then
			light.Brightness = P.light.peak * smooth(0.14, 0.2, t)
		else
			light.Brightness = P.light.peak * (1 - FxClock.outCubic(math.clamp((t - 0.2) / 0.3, 0, 1)))
		end
	end)

	if opts.noPlay then
		return clock
	end
	return clock:play()
end

return FireSlash
