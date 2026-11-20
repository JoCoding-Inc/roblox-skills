--!nonstrict
-- fx_recipe: an effect written as data. A recipe is a list of layers; each layer is one of four kinds (burst,
-- stream, ring, light) with plain numbers and palette keys, so a new effect is a new table, not new code
-- (roblox-feel-audio-vfx section 3i). Needs fx_clock and fx_textures. Client only.
--
-- local FxRecipe = require(folder.fx_recipe)
-- FxRecipe.play("hit_electric", targetModel | impactCFrame, { scale = 1, direction = d }) -> clock
-- FxRecipe.play(myRecipeTable, impactCFrame, { palette = "fire" })
--
-- impactCFrame.LookVector = the direction the hit travels; sparks fly back against it. opts.scale multiplies
-- sizes, speeds, radii and light range (times stay); opts.palette overrides the recipe's palette (a name in
-- FxRecipe.palettes or a table with the same keys); opts.noPlay returns the clock unstarted.
--
-- Palette keys: white (the contact frame), hot (bright edge), mid (the saturated body), dark (the underlayer),
-- smoke0 -> smoke1 (smoke over its life), light (the PointLight). A layer names keys, never colours.
--
-- Layer fields (every size, speed and radius is in studs at scale 1):
--   burst : at, count, slot, where ("front" | "hit"), life {min, max}, size {{t, v, envelope?}, ...},
--           alpha {{t, transparency}, ...}, color (key | {{t, key}, ...}), emission, brightness, z,
--           speed {min, max}, spread (deg), drag, accel {x, y, z}, rotation (deg), rotSpeed {min, max},
--           along (true: stretched along its velocity), squash {{t, v}, ...}
--   stream: the burst fields with from, to (s) and rate (per s) in place of at and count
--   ring  : at, dur, r0, r1, w0, w1, segments, color {from key, to key}, emission, brightness, z,
--           twin (true: a dark ring under it, a little behind in time)
--   light : at, dur, peak, range
-- "front" sits 0.4 studs toward the attacker so glow layers do not sink into the target; "hit" is the contact
-- point with its up axis pointing back at the attacker (speed and spread fan out from there).
-- Defaults of a layer written by hand: where "hit", emission 1, brightness 1, z 0, no motion; a ring: 12 segments,
-- emission 0.8, brightness 2.5, z 0.5. rotation is a fixed start angle in degrees (without it each particle starts
-- at a random angle). A template override replaces the whole field (a new size table, not one key of it).
-- duration is when the clock destroys everything: the last death plus a margin. One ring is `segments` beams, and
-- its twin as many again. A pickup or any effect that is not a hit: pass a CFrame that looks straight down, so
-- "back at the attacker" is up, and widen spread (180 sends particles every way).
--
-- hit_electric reproduces scripts/hit_impact.luau layer for layer: built side by side in Studio 0.748 Play on
-- 2026-11-20, all 8 emitters had the same 19 properties and the beam and light counts matched. The five element
-- variants were looked at frozen at 0.05, 0.1 and 0.2 s on a daylight floor; nobody has judged them at real speed,
-- on a phone or in a published game.

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local FxRecipe = {}

local C = Color3.fromRGB

FxRecipe.palettes = {
	electric = { white = C(255, 255, 255), hot = C(110, 200, 255), mid = C(40, 105, 255), dark = C(10, 28, 70), smoke0 = C(55, 65, 85), smoke1 = C(100, 108, 120), light = C(160, 220, 255) },
	fire = { white = C(255, 250, 225), hot = C(255, 190, 70), mid = C(255, 95, 20), dark = C(60, 14, 6), smoke0 = C(40, 34, 32), smoke1 = C(95, 88, 84), light = C(255, 170, 90) },
	ice = { white = C(255, 255, 255), hot = C(190, 240, 255), mid = C(90, 190, 235), dark = C(14, 44, 70), smoke0 = C(150, 175, 195), smoke1 = C(215, 230, 240), light = C(190, 235, 255) },
	holy = { white = C(255, 255, 245), hot = C(255, 240, 170), mid = C(255, 200, 60), dark = C(80, 50, 8), smoke0 = C(120, 105, 70), smoke1 = C(200, 190, 160), light = C(255, 235, 170) },
	shadow = { white = C(240, 220, 255), hot = C(200, 130, 255), mid = C(120, 40, 220), dark = C(20, 6, 40), smoke0 = C(30, 22, 44), smoke1 = C(70, 58, 90), light = C(190, 130, 255) },
	poison = { white = C(245, 255, 220), hot = C(170, 255, 90), mid = C(60, 200, 60), dark = C(10, 50, 16), smoke0 = C(40, 60, 40), smoke1 = C(100, 125, 95), light = C(170, 255, 120) },
}

-- Layer templates: each returns a fresh layer table; pass a table of fields to override.
local function layer(base)
	return function(over)
		local l = table.clone(base)
		for k, v in over or {} do
			l[k] = v
		end
		return l
	end
end

local L = {}
FxRecipe.layers = L

-- the contact frame: one white soft glow for 3 frames
L.flash = layer({ kind = "burst", name = "Flash", at = 0, count = 1, slot = "glow", where = "front", life = { 0.05, 0.05 }, size = { { 0, 1.5 }, { 0.25, 3 }, { 1, 1.95 } }, alpha = { { 0, 0 }, { 0.4, 0.35 }, { 1, 1 } }, color = "white", emission = 1, brightness = 5, z = 1.5 })
-- contrast on a lit floor: a dark soft disc under the bright layers, normal blend
L.under = layer({ kind = "burst", name = "Under", at = 0.017, count = 1, slot = "glow", where = "hit", life = { 0.16, 0.16 }, size = { { 0, 3.5 }, { 1, 6 } }, alpha = { { 0, 0.45 }, { 1, 1 } }, color = "dark", emission = 0, brightness = 1, z = -0.5 })
-- the core: stars that grow and collapse, white to hot to mid
L.core = layer({ kind = "burst", name = "Core", at = 0.017, count = 2, slot = "star", where = "front", life = { 0.12, 0.15 }, size = { { 0, 1 }, { 0.25, 2.6 }, { 1, 0 } }, alpha = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }, color = { { 0, "white" }, { 0.5, "hot" }, { 1, "mid" } }, emission = 1, brightness = 4, z = 1 })
-- the saturated body: without it every layer reads white in daylight
L.body = layer({ kind = "burst", name = "Body", at = 0.017, count = 1, slot = "glow", where = "front", life = { 0.16, 0.16 }, size = { { 0, 2 }, { 1, 5.5 } }, alpha = { { 0, 0.25 }, { 1, 1 } }, color = "mid", emission = 0.5, brightness = 1.5, z = 0.2 })
-- electric accent: bolts for 3-6 frames
L.bolts = layer({ kind = "burst", name = "Bolts", at = 0.017, count = 3, slot = "electric", where = "front", life = { 0.06, 0.1 }, size = { { 0, 2.2, 0.6 }, { 1, 3.4, 0.6 } }, alpha = { { 0, 0 }, { 1, 0.6 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 1, brightness = 4, z = 1.2 })
-- streak sparks thrown back at the attacker; drag stops them, gravity bends them
L.sparks = layer({ kind = "burst", name = "Sparks", at = 0.033, count = 22, slot = "streak", where = "hit", life = { 0.12, 0.32 }, speed = { 25, 45 }, spread = 65, drag = 8, accel = { 0, -25, 0 }, along = true, rotation = 90, squash = { { 0, 1 }, { 1, 0.5 } }, size = { { 0, 0.9, 0.15 }, { 1, 0.2 } }, alpha = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }, color = { { 0, "white" }, { 0.3, "hot" }, { 1, "mid" } }, emission = 1, brightness = 4, z = 0.8 })
-- the dark end of the value range: a few puffs behind everything
L.smoke = layer({ kind = "burst", name = "Smoke", at = 0.067, count = 6, slot = "smoke", where = "hit", life = { 0.5, 0.8 }, speed = { 3, 7 }, spread = 80, drag = 4, accel = { 0, 1.5, 0 }, rotSpeed = { -40, 40 }, size = { { 0, 1.4, 0.2 }, { 1, 4, 0.4 } }, alpha = { { 0, 1 }, { 0.1, 0.35 }, { 1, 1 } }, color = { { 0, "smoke0" }, { 1, "smoke1" } }, emission = 0, brightness = 1, z = -2 })
-- aftermath: a few small stars that pop and vanish
L.pops = layer({ kind = "burst", name = "Pops", at = 0.18, count = 4, slot = "star", where = "hit", life = { 0.25, 0.35 }, speed = { 2, 5 }, spread = 90, size = { { 0, 0 }, { 0.3, 0.9 }, { 1, 0 } }, alpha = { { 0, 0 }, { 1, 0.3 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 1, brightness = 3, z = 0.6 })
-- embers that keep rising after a fire hit (a stream, so the fire shrinks instead of stopping dead)
L.embers = layer({ kind = "stream", name = "Embers", from = 0.05, to = 0.45, rate = 40, slot = "streak", where = "hit", life = { 0.2, 0.45 }, speed = { 4, 10 }, spread = 70, drag = 3, accel = { 0, 14, 0 }, along = true, rotation = 90, size = { { 0, 0.45, 0.1 }, { 1, 0.1 } }, alpha = { { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } }, color = { { 0, "white" }, { 0.25, "hot" }, { 1, "mid" } }, emission = 1, brightness = 4, z = 0.7 })
-- a disc of rays behind the core (holy, a critical hit): one flare for 8 frames
L.rays = layer({ kind = "burst", name = "Rays", at = 0.017, count = 1, slot = "flare", where = "front", life = { 0.14, 0.14 }, size = { { 0, 2 }, { 0.3, 6 }, { 1, 7 } }, alpha = { { 0, 0 }, { 0.5, 0.3 }, { 1, 1 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 1, brightness = 3, z = 0.9 })
-- the shock ring, facing between the attacker and the camera so it never goes edge-on
L.ring = layer({ kind = "ring", name = "Ring", at = 0.05, dur = 0.21, r0 = 0.5, r1 = 3.4, w0 = 0.9, w1 = 0.12, segments = 12, color = { "white", "hot" }, emission = 0.8, brightness = 2.5, z = 0.5, twin = true })
-- the world answers: one light pulse that starts at its peak
L.light = layer({ kind = "light", name = "Light", at = 0, dur = 0.2, peak = 4, range = 10 })

FxRecipe.recipes = {
	-- scripts/hit_impact.luau as data
	hit_electric = {
		palette = "electric",
		duration = 1.0,
		recoilDeg = 9,
		captureTimes = { 0.0, 0.017, 0.033, 0.05, 0.075, 0.1, 0.14, 0.2, 0.28, 0.4, 0.6, 0.85 },
		layers = { L.flash(), L.under(), L.core(), L.bolts(), L.body(), L.sparks(), L.ring(), L.smoke(), L.pops(), L.light() },
	},
	-- The same hit in five more elements: the palette changes the colour, the accent layers change the character.
	-- fire: no bolts; fewer, floatier sparks, embers that keep rising, more smoke
	hit_fire = {
		palette = "fire",
		duration = 1.0,
		recoilDeg = 9,
		layers = { L.flash(), L.under(), L.core(), L.body(), L.sparks({ count = 16, accel = { 0, -12, 0 } }), L.embers(), L.ring(), L.smoke({ count = 8 }), L.pops(), L.light() },
	},
	-- ice: more and faster shards that stop short, a brief pale mist, more glints after
	hit_ice = {
		palette = "ice",
		duration = 1.0,
		recoilDeg = 9,
		layers = { L.flash(), L.under(), L.core({ count = 3 }), L.body(), L.sparks({ count = 26, speed = { 30, 55 }, drag = 10 }), L.ring(), L.smoke({ count = 5, life = { 0.35, 0.6 } }), L.pops({ count = 8 }), L.light() },
	},
	-- holy: a disc of rays, sparks that rise, many slow glints, no smoke
	hit_holy = {
		palette = "holy",
		duration = 1.0,
		recoilDeg = 9,
		layers = { L.flash(), L.under(), L.rays(), L.core({ count = 3 }), L.body(), L.sparks({ count = 14, speed = { 18, 32 }, accel = { 0, 8, 0 } }), L.ring(), L.pops({ count = 10, life = { 0.3, 0.5 }, speed = { 3, 8 } }), L.light() },
	},
	-- shadow: a tinted flash, a wider dark underlayer, two bolts, long dark wisps
	hit_shadow = {
		palette = "shadow",
		duration = 1.0,
		recoilDeg = 9,
		layers = { L.flash({ color = "hot" }), L.under({ size = { { 0, 4.5 }, { 1, 7.5 } }, alpha = { { 0, 0.3 }, { 1, 1 } } }), L.core(), L.bolts({ count = 2 }), L.body(), L.sparks({ count = 18 }), L.ring(), L.smoke({ count = 9, life = { 0.55, 0.9 } }), L.pops({ count = 3 }), L.light() },
	},
	-- poison: slow droplets, a cloud that lingers and rises, bubbles that float up
	hit_poison = {
		palette = "poison",
		duration = 1.1,
		recoilDeg = 9,
		layers = { L.flash(), L.under(), L.core(), L.body(), L.sparks({ count = 12, speed = { 12, 24 }, drag = 6 }), L.ring(), L.smoke({ count = 10, life = { 0.6, 1.0 }, accel = { 0, 3, 0 }, alpha = { { 0, 1 }, { 0.1, 0.25 }, { 1, 1 } } }), L.pops({ count = 8, accel = { 0, 10, 0 }, life = { 0.3, 0.55 } }), L.light() },
	},
}

local function key(pal, k)
	local c = pal[k]
	if not c then
		error(`fx_recipe: palette has no key "{k}"`, 3)
	end
	return c
end

local function colorOf(pal, c)
	if type(c) == "string" then
		return ColorSequence.new(key(pal, c))
	end
	local pts = {}
	for i, p in c do
		pts[i] = { p[1], key(pal, p[2]) }
	end
	return FxClock.cs(pts)
end

local function sized(points, s)
	local out = {}
	for i, p in points do
		out[i] = { p[1], p[2] * s, p[3] and p[3] * s }
	end
	return FxClock.ns(out)
end

local function emitterProps(l, pal, s)
	local props = {
		Name = l.name or "Layer",
		Lifetime = NumberRange.new(l.life[1], l.life[2]),
		Size = sized(l.size, s),
		Transparency = FxClock.ns(l.alpha),
		Color = colorOf(pal, l.color),
		LightEmission = l.emission or 1,
		Brightness = l.brightness or 1,
		ZOffset = l.z or 0,
	}
	if l.speed then
		props.EmissionDirection = Enum.NormalId.Top
		props.Speed = NumberRange.new(l.speed[1] * s, l.speed[2] * s)
		props.SpreadAngle = Vector2.new(l.spread or 0, l.spread or 0)
	end
	if l.drag then
		props.Drag = l.drag
	end
	if l.accel then
		props.Acceleration = Vector3.new(l.accel[1], l.accel[2], l.accel[3]) * s
	end
	if l.rotation then
		props.Rotation = NumberRange.new(l.rotation)
	end
	if l.rotSpeed then
		props.RotSpeed = NumberRange.new(l.rotSpeed[1], l.rotSpeed[2])
	end
	if l.along then
		props.Orientation = Enum.ParticleOrientation.VelocityParallel
	end
	if l.squash then
		props.Squash = FxClock.ns(l.squash)
	end
	return props
end

local function resolve(target, opts)
	if typeof(target) == "CFrame" then
		return target.Position, target.LookVector, nil
	end
	local root = target:FindFirstChild("HumanoidRootPart")
	local torso = target:FindFirstChild("UpperTorso") or root
	local d = (opts.direction or -root.CFrame.LookVector).Unit
	return torso.Position - d * 0.6, d, target
end

function FxRecipe.play(recipe, target, opts)
	opts = opts or {}
	if type(recipe) == "string" then
		local r = FxRecipe.recipes[recipe]
		if not r then
			error(`fx_recipe: no recipe "{recipe}"`, 2)
		end
		recipe = r
	end
	local pal = opts.palette or recipe.palette
	if type(pal) == "string" then
		pal = FxRecipe.palettes[pal] or error(`fx_recipe: no palette "{pal}"`, 2)
	end
	local s = opts.scale or 1
	local p, d, model = resolve(target, opts)
	local clock = FxClock.new(recipe.name or "FxRecipe", recipe.duration)
	local smooth, lerp = FxClock.smooth, FxClock.lerp
	local spray = -d
	local side = (math.abs(spray.Y) < 0.9 and spray:Cross(Vector3.yAxis) or spray:Cross(Vector3.xAxis)).Unit
	local atts = {
		hit = clock:attachment(CFrame.fromMatrix(p, side, spray)),
		front = clock:attachment(CFrame.new(p + spray * 0.4 * s)),
	}

	for _, l in recipe.layers do
		if l.kind == "burst" or l.kind == "stream" then
			local e = clock:emitter(atts[l.where or "hit"], emitterProps(l, pal, s))
			FxTextures.apply(e, l.slot)
			if l.kind == "burst" then
				clock:at(l.at, function()
					e:Emit(l.count)
				end)
			else
				-- the rate ramps in and out over 15% of the span, so the stream has no seam
				clock:stream(e, l.from, l.to, function(t)
					local u = (t - l.from) / (l.to - l.from)
					return l.rate * smooth(0, 0.15, u) * (1 - smooth(0.85, 1, u))
				end)
			end
		elseif l.kind == "ring" then
			local cam = workspace.CurrentCamera
			local toCam = if cam then (cam.CFrame.Position - p).Unit else spray
			local n = (spray + toCam).Unit
			local b1 = (math.abs(n.Y) < 0.9 and n:Cross(Vector3.yAxis) or n:Cross(Vector3.xAxis)).Unit
			local b2 = n:Cross(b1).Unit
			local segs = l.segments or 12
			local function joint(j, r, w, a, col)
				local ang = (j - 1) / segs * math.pi * 2
				local radial = b1 * math.cos(ang) + b2 * math.sin(ang)
				local tan = -b1 * math.sin(ang) + b2 * math.cos(ang)
				return { cf = CFrame.fromMatrix(p + radial * r, tan, radial), width = w, alpha = a, color = col }
			end
			local c0, c1, dark = key(pal, l.color[1]), key(pal, l.color[2]), key(pal, "dark")
			local r0, r1, w0, w1 = l.r0 * s, l.r1 * s, l.w0 * s, l.w1 * s
			local ring = clock:ribbon(segs, { LightEmission = l.emission or 0.8, Brightness = l.brightness or 2.5, ZOffset = l.z or 0.5 })
			local twin = l.twin and clock:ribbon(segs, { LightEmission = 0, Brightness = 1, ZOffset = -0.3 })
			clock:span(l.at, l.at + l.dur, function(u)
				local e = FxClock.outQuart(u)
				local col = c0:Lerp(c1, smooth(0, 0.25, u))
				ring.update(function(j)
					return joint(j, lerp(r0, r1, e), lerp(w0, w1, e), smooth(0.35, 1, u), col)
				end)
				if twin then
					local u2 = math.max(u - 0.08, 0)
					local e2 = FxClock.outQuart(u2)
					twin.update(function(j)
						return joint(j, lerp(r0, r1 * 0.92, e2), lerp(w0 * 1.6, w1 * 1.67, e2), 0.5 + 0.5 * smooth(0.3, 1, u2), dark)
					end)
				end
				if u >= 1 then
					ring.hide()
					if twin then
						twin.hide()
					end
				end
			end)
		elseif l.kind == "light" then
			local light = clock:light(atts.front, { Range = l.range * s, Color = key(pal, "light") })
			clock:span(l.at, l.at + l.dur, function(u)
				light.Brightness = l.peak * (1 - u) ^ 2
			end)
		else
			error(`fx_recipe: unknown layer kind "{l.kind}"`, 2)
		end
	end

	-- recoil lean of an R15 target (visual only, on this client)
	if model and (recipe.recoilDeg or 0) > 0 then
		local lower = model:FindFirstChild("LowerTorso")
		local joint = lower and lower:FindFirstChild("Root")
		if joint and joint:IsA("Motor6D") then
			local c0 = joint.C0
			local axis = model.HumanoidRootPart.CFrame:VectorToObjectSpace(d:Cross(Vector3.yAxis)).Unit
			clock:span(0, 0.4, function(_, t)
				local k = if t < 0.05 then math.sin(t / 0.05 * math.pi / 2) else 1 - smooth(0.05, 0.4, t)
				joint.C0 = c0 * CFrame.fromAxisAngle(axis, -math.rad(recipe.recoilDeg) * k)
			end)
			clock:onCleanup(function()
				joint.C0 = c0
			end)
		end
	end

	if opts.noPlay then
		return clock
	end
	return clock:play()
end

return FxRecipe
