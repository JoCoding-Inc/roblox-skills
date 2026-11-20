--!nonstrict
-- fx_recipe: an effect written as data. A recipe is a list of layers; each layer is one of four kinds (burst,
-- stream, ring, light) with plain numbers and palette keys, so a new effect is a new table, not new code
-- (roblox-feel-audio-vfx section 3i). Needs fx_clock and fx_textures. Client only.
--
-- local FxRecipe = require(folder.fx_recipe)
-- FxRecipe.play("hit_electric", targetModel | impactCFrame, { scale = 1, direction = d }) -> clock
-- FxRecipe.play(myRecipeTable, impactCFrame, { palette = "fire" })
-- FxRecipe.play("aura", characterModel, { duration = 6 })
--
-- impactCFrame.LookVector = the direction the hit travels; sparks fly back against it. opts.scale multiplies
-- sizes, speeds, radii and light range (times stay); opts.palette overrides the recipe's palette (a name in
-- FxRecipe.palettes or a table with the same keys); opts.duration replaces the recipe's duration (how long an aura
-- holds); opts.noPlay returns the clock unstarted.
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
--   light : at, dur, peak, range, hold (true: ramps in, holds and ramps out, for an aura)
-- More fields: a burst or stream takes up (studs above the anchor), disc {radius, partial} (emit from a flat disc
-- at the anchor: partial 1 fills it, 0 is the rim only) and flat (true: the particle lies on the floor); a ring
-- takes plane ("floor": it lies flat) and y0, y1 (it travels from y0 to y1 studs above the anchor); a stream's
-- `to` may be "end" (runs until 0.35 s before the clock ends, so opts.duration sets how long an aura holds);
-- a ring's or a light's dur may be "end" too (a ring with r0 = r1 then holds its size and fades out).
-- recipe.anchor: "hit" (default: the contact point, sparks go back at the attacker), "up" (the same point, up is
-- world up: pickups, explosions) or "feet" (the floor under a model, or the CFrame's position: auras, level-ups,
-- ground hits).
-- "front" sits 0.4 studs toward the attacker so glow layers do not sink into the target; "hit" is the contact
-- point with its up axis pointing back at the attacker (speed and spread fan out from there).
-- Defaults of a layer written by hand: where "hit", emission 1, brightness 1, z 0, no motion; a ring: 12 segments,
-- emission 0.8, brightness 2.5, z 0.5. rotation is a fixed start angle in degrees (without it each particle starts
-- at a random angle). A template override replaces the whole field (a new size table, not one key of it).
-- duration is when the clock destroys everything: the last death plus a margin. One ring is `segments` beams, and
-- its twin as many again. An effect that is not a hit sets recipe.anchor ("up" or "feet"), so speed and spread fan
-- out from world up; spread 180 sends particles every way.
--
-- hit_electric reproduces scripts/hit_impact.luau layer for layer: built side by side in Studio 0.748 Play on
-- 2026-11-20, all 8 emitters had the same 19 properties and the beam and light counts matched. The six element
-- hits were judged good by the owner at real speed in Studio on a desktop (2026-11-20). hit_water and the recipes
-- that are not hits ran with no errors in Studio Play and were looked at frozen at 0.08, 0.3 and 0.7 s (level_up,
-- aura, heal and spawn_in once more at 0.6 s after their streaks and dots were made smaller); the last size changes
-- to wisps, debris and embers were not captured again, and nobody has judged these at real speed. Nothing here was
-- checked on a phone or in a published game.

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
	water = { white = C(245, 252, 255), hot = C(150, 225, 255), mid = C(30, 150, 235), dark = C(8, 40, 78), smoke0 = C(110, 150, 185), smoke1 = C(200, 225, 240), light = C(150, 215, 255) },
	gold = { white = C(255, 255, 240), hot = C(255, 225, 110), mid = C(255, 170, 20), dark = C(70, 38, 4), smoke0 = C(120, 100, 60), smoke1 = C(205, 190, 150), light = C(255, 215, 120) },
	heal = { white = C(250, 255, 245), hot = C(170, 255, 190), mid = C(60, 220, 130), dark = C(8, 54, 34), smoke0 = C(90, 130, 110), smoke1 = C(190, 225, 205), light = C(170, 255, 200) },
	earth = { white = C(255, 248, 230), hot = C(240, 205, 150), mid = C(190, 130, 70), dark = C(48, 32, 20), smoke0 = C(92, 80, 68), smoke1 = C(165, 152, 138), light = C(255, 215, 160) },
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
L.embers = layer({ kind = "stream", name = "Embers", from = 0.05, to = 0.45, rate = 40, slot = "streak", where = "hit", life = { 0.2, 0.45 }, speed = { 4, 10 }, spread = 70, drag = 3, accel = { 0, 14, 0 }, along = true, rotation = 90, squash = { { 0, 1.2 }, { 1, 0.7 } }, size = { { 0, 0.4, 0.1 }, { 1, 0.1 } }, alpha = { { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } }, color = { { 0, "white" }, { 0.25, "hot" }, { 1, "mid" } }, emission = 1, brightness = 4, z = 0.7 })
-- a disc of rays behind the core (holy, a critical hit): one flare for 8 frames
L.rays = layer({ kind = "burst", name = "Rays", at = 0.017, count = 1, slot = "flare", where = "front", life = { 0.14, 0.14 }, size = { { 0, 2 }, { 0.3, 6 }, { 1, 7 } }, alpha = { { 0, 0 }, { 0.5, 0.3 }, { 1, 1 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 1, brightness = 3, z = 0.9 })
-- the shock ring, facing between the attacker and the camera so it never goes edge-on
L.ring = layer({ kind = "ring", name = "Ring", at = 0.05, dur = 0.21, r0 = 0.5, r1 = 3.4, w0 = 0.9, w1 = 0.12, segments = 12, color = { "white", "hot" }, emission = 0.8, brightness = 2.5, z = 0.5, twin = true })
-- the world answers: one light pulse that starts at its peak
L.light = layer({ kind = "light", name = "Light", at = 0, dur = 0.2, peak = 4, range = 10 })

-- Floor and body layers (recipes with anchor "feet" or "up") --------------------------------------------------
-- a shock ring lying on the floor
L.floorRing = layer({ kind = "ring", name = "FloorRing", plane = "floor", at = 0, dur = 0.3, r0 = 0.6, r1 = 5, w0 = 1.2, w1 = 0.15, segments = 16, color = { "white", "hot" }, emission = 0.8, brightness = 2.5, z = 0.5, twin = true })
-- a thin ring that travels up (or down) the body
L.riseRing = layer({ kind = "ring", name = "RiseRing", plane = "floor", at = 0.1, dur = 0.55, r0 = 2.4, r1 = 1.9, w0 = 0.45, w1 = 0.08, y0 = 0.3, y1 = 5.2, segments = 16, color = { "white", "hot" }, emission = 0.9, brightness = 3, z = 0.5 })
-- a soft colour disc lying on the floor (the glow under an effect)
L.floorGlow = layer({ kind = "burst", name = "FloorGlow", at = 0, count = 1, slot = "glow", where = "hit", up = 0.1, flat = true, life = { 0.3, 0.3 }, size = { { 0, 3 }, { 1, 7 } }, alpha = { { 0, 0.35 }, { 1, 1 } }, color = "mid", emission = 0.6, brightness = 1.5, z = 0.1 })
-- a dark mark left on the floor (lives longer than the rest: it is the underlayer of a ground hit)
L.scorch = layer({ kind = "burst", name = "Scorch", at = 0.03, count = 1, slot = "glow", where = "hit", up = 0.08, flat = true, life = { 0.7, 0.7 }, size = { { 0, 4 }, { 0.2, 6.5 }, { 1, 7 } }, alpha = { { 0, 0.3 }, { 0.6, 0.5 }, { 1, 1 } }, color = "dark", emission = 0, brightness = 1, z = -0.4 })
-- a column of light on the body: one soft glow squashed tall
L.pillar = layer({ kind = "burst", name = "Pillar", at = 0.05, count = 1, slot = "glow", where = "hit", up = 3, life = { 0.3, 0.3 }, size = { { 0, 3 }, { 1, 4.5 } }, squash = { { 0, 1.4 }, { 1, 2.4 } }, rotation = 0, alpha = { { 0, 0.2 }, { 0.5, 0.45 }, { 1, 1 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 1, brightness = 2.5, z = 0.3 })
-- streaks that rise from a ring at the feet
L.motes = layer({ kind = "stream", name = "Motes", from = 0.1, to = 1.0, rate = 60, slot = "streak", where = "hit", up = 0.2, disc = { 2.2, 0.25 }, life = { 0.25, 0.35 }, speed = { 12, 20 }, spread = 4, along = true, rotation = 90, squash = { { 0, 1.6 }, { 1, 0.9 } }, size = { { 0, 0.35, 0.08 }, { 1, 0.1 } }, alpha = { { 0, 0.4 }, { 0.2, 0 }, { 1, 1 } }, color = { { 0, "white" }, { 0.4, "hot" }, { 1, "mid" } }, emission = 1, brightness = 3.5, z = 0.6 })
-- small bright dots that drift up around the body (kept under half a stud: bigger ones read as blobs)
L.wisps = layer({ kind = "stream", name = "Wisps", from = 0.1, to = 1.0, rate = 24, slot = "glow", where = "hit", up = 2.5, disc = { 2.2, 1 }, life = { 0.3, 0.35 }, speed = { 2, 5 }, spread = 30, size = { { 0, 0 }, { 0.3, 0.28, 0.08 }, { 1, 0 } }, alpha = { { 0, 0.1 }, { 1, 0.5 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 1, brightness = 3, z = 0.4 })
-- dust thrown out along the floor
L.dust = layer({ kind = "burst", name = "Dust", at = 0.04, count = 14, slot = "smoke", where = "hit", up = 0.4, life = { 0.5, 0.8 }, speed = { 9, 17 }, spread = 86, drag = 5, accel = { 0, 2, 0 }, rotSpeed = { -50, 50 }, size = { { 0, 1.2, 0.2 }, { 1, 3.6, 0.5 } }, alpha = { { 0, 1 }, { 0.12, 0.4 }, { 1, 1 } }, color = { { 0, "smoke0" }, { 1, "smoke1" } }, emission = 0, brightness = 1, z = -1 })
-- chips thrown up that fall back
L.debris = layer({ kind = "burst", name = "Debris", at = 0.03, count = 16, slot = "streak", where = "hit", up = 0.3, life = { 0.28, 0.35 }, speed = { 20, 36 }, spread = 42, drag = 2, accel = { 0, -70, 0 }, along = true, rotation = 90, squash = { { 0, 1.4 }, { 1, 0.8 } }, size = { { 0, 0.5, 0.1 }, { 1, 0.18 } }, alpha = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }, color = { { 0, "white" }, { 0.3, "hot" }, { 1, "mid" } }, emission = 0.9, brightness = 3, z = 0.7 })
-- a fireball: lumps of an explosion flipbook that play once over their life
L.fireball = layer({ kind = "burst", name = "Fireball", at = 0.02, count = 5, slot = "fire", where = "hit", life = { 0.28, 0.35 }, speed = { 2, 6 }, spread = 180, drag = 3, size = { { 0, 2.2, 0.4 }, { 1, 5.5, 0.6 } }, alpha = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } }, color = { { 0, "white" }, { 0.35, "hot" }, { 1, "mid" } }, emission = 0.7, brightness = 2.5, z = 0.4 })

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

	-- water: no stars or bolts; a spray of thin drops that arc and fall, a thicker ripple ring, a pale mist.
	-- Round drops stay small (0.3 studs): at 0.6 and more they read as blobs (owner, 2026-11-20).
	hit_water = {
		palette = "water",
		duration = 1.0,
		recoilDeg = 9,
		layers = {
			L.flash(),
			L.under(),
			L.core({ slot = "glow", count = 1, size = { { 0, 1 }, { 0.25, 2.2 }, { 1, 0 } } }),
			L.body(),
			L.sparks({ name = "Spray", count = 24, speed = { 18, 34 }, spread = 70, drag = 5, accel = { 0, -55, 0 }, life = { 0.2, 0.35 }, size = { { 0, 0.7, 0.15 }, { 1, 0.2 } } }),
			{ kind = "burst", name = "Drops", at = 0.04, count = 10, slot = "glow", where = "hit", life = { 0.25, 0.35 }, speed = { 8, 16 }, spread = 80, drag = 2, accel = { 0, -50, 0 }, size = { { 0, 0.3, 0.08 }, { 1, 0.12 } }, alpha = { { 0, 0.1 }, { 0.7, 0.2 }, { 1, 1 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 0.6, brightness = 2, z = 0.7 },
			L.ring({ w0 = 1.2, w1 = 0.2, r1 = 3.8, dur = 0.26 }),
			L.smoke({ count = 5, life = { 0.4, 0.65 }, alpha = { { 0, 1 }, { 0.1, 0.5 }, { 1, 1 } } }),
			L.light(),
		},
	},

	-- Not hits ---------------------------------------------------------------------------------------------
	-- a coin or reward picked up: a small bright pop with a fountain of sparks that fall back (about 4 studs)
	pickup = {
		palette = "gold",
		anchor = "up",
		duration = 0.8,
		layers = {
			L.flash({ size = { { 0, 0.8 }, { 0.25, 1.8 }, { 1, 1.2 } } }),
			L.core({ count = 2, size = { { 0, 0.5 }, { 0.25, 1.7 }, { 1, 0 } } }),
			L.body({ size = { { 0, 1 }, { 1, 2.8 } } }),
			L.sparks({ count = 12, speed = { 11, 19 }, spread = 60, drag = 2, accel = { 0, -45, 0 }, life = { 0.25, 0.35 }, size = { { 0, 0.55, 0.1 }, { 1, 0.15 } } }),
			L.ring({ r0 = 0.3, r1 = 2, w0 = 0.45, w1 = 0.06, dur = 0.18, twin = false }),
			L.pops({ at = 0.1, count = 6, speed = { 2, 5 }, spread = 180, size = { { 0, 0 }, { 0.3, 0.7 }, { 1, 0 } } }),
			L.light({ peak = 2, range = 6, dur = 0.18 }),
		},
	},
	-- level up: a floor ring, a column of light, two rings that climb the body, rising streaks, stars at the top
	level_up = {
		palette = "holy",
		anchor = "feet",
		duration = 1.7,
		layers = {
			L.floorGlow({ size = { { 0, 3 }, { 1, 9 } } }),
			L.floorRing({ r1 = 5.5 }),
			L.pillar(),
			L.flash({ at = 0.05, up = 3, size = { { 0, 2 }, { 0.25, 4 }, { 1, 2.6 } } }),
			L.riseRing(),
			L.riseRing({ name = "RiseRing2", at = 0.32 }),
			L.motes(),
			L.wisps({ from = 0.2, to = 1.2 }),
			L.pops({ at = 0.55, up = 5, count = 8, speed = { 3, 8 }, spread = 180, life = { 0.3, 0.35 } }),
			L.pops({ name = "Pops2", at = 0.85, up = 5.5, count = 6, speed = { 2, 6 }, spread = 180, life = { 0.3, 0.35 } }),
			L.light({ up = 3, peak = 3, range = 14, dur = 1.1, hold = true }),
		},
	},
	-- an aura that holds as long as opts.duration says (default 3 s): rising streaks, drifting lights, a floor pulse
	aura = {
		palette = "electric",
		anchor = "feet",
		duration = 3,
		layers = {
			L.floorRing({ r1 = 3.6, w0 = 0.8, dur = 0.25, twin = false }),
			L.floorRing({ name = "HeldRing", at = 0.2, dur = "end", r0 = 2.6, r1 = 2.6, w0 = 0.25, w1 = 0.25, twin = false }),
			L.floorGlow({ kind = "stream", from = 0.05, to = "end", rate = 5, life = { 0.3, 0.35 }, size = { { 0, 3.5 }, { 1, 5.5 } }, alpha = { { 0, 1 }, { 0.4, 0.45 }, { 1, 1 } } }),
			L.motes({ from = 0.05, to = "end", rate = 45, disc = { 2, 0.3 } }),
			L.wisps({ from = 0.05, to = "end", rate = 16 }),
			L.pops({ kind = "stream", from = 0.3, to = "end", rate = 4, up = 2.5, disc = { 2.2, 1 }, speed = { 1, 3 }, spread = 60, life = { 0.25, 0.35 } }),
			L.light({ up = 2.5, peak = 1.6, range = 9, dur = "end", hold = true }),
		},
	},
	-- a ground hit: a flash, a mark on the floor, a wide floor ring, dust along the floor, chips that fall back
	ground_hit = {
		palette = "earth",
		anchor = "feet",
		duration = 1.2,
		layers = {
			L.flash({ up = 0.8, size = { { 0, 2 }, { 0.25, 4 }, { 1, 2.6 } } }),
			L.scorch(),
			L.floorGlow({ color = "hot", life = { 0.18, 0.18 }, size = { { 0, 3 }, { 1, 8 } } }),
			L.floorRing({ r1 = 6.5, w0 = 1.5 }),
			L.dust(),
			L.debris(),
			L.smoke({ at = 0.08, up = 0.8, count = 5, speed = { 2, 5 }, spread = 50 }),
			L.light({ up = 1, peak = 3, range = 12 }),
		},
	},
	-- a heal: soft, no white flash; slow rings up the body, slow streaks, drifting lights
	heal = {
		palette = "heal",
		anchor = "feet",
		duration = 1.6,
		layers = {
			L.floorGlow({ life = { 0.35, 0.35 }, size = { { 0, 3 }, { 1, 7 } } }),
			L.floorRing({ r1 = 3.8, w0 = 0.7, dur = 0.35, twin = false, color = { "hot", "mid" } }),
			L.riseRing({ dur = 0.8, color = { "hot", "mid" } }),
			L.riseRing({ name = "RiseRing2", at = 0.45, dur = 0.8, color = { "hot", "mid" } }),
			L.motes({ rate = 40, speed = { 6, 10 }, to = 1.1 }),
			L.wisps({ rate = 16, to = 1.2 }),
			L.pops({ at = 0.7, up = 4.5, count = 5, speed = { 1, 4 }, spread = 180, life = { 0.3, 0.35 } }),
			L.light({ up = 2.5, peak = 2, range = 10, dur = 1.2, hold = true }),
		},
	},
	-- appearing (a spawn, a teleport in): a column, a ring that scans down the body, a floor ring, sparks up
	spawn_in = {
		palette = "electric",
		anchor = "feet",
		duration = 1.0,
		layers = {
			L.pillar({ at = 0, size = { { 0, 2.5 }, { 1, 4 } }, squash = { { 0, 1.4 }, { 1, 2.2 } } }),
			L.riseRing({ at = 0, dur = 0.3, y0 = 5.6, y1 = 0.3, r0 = 2, r1 = 2.4 }),
			L.flash({ at = 0.12, up = 3 }),
			L.floorRing({ at = 0.25, r1 = 4.5 }),
			L.floorGlow({ at = 0.25 }),
			L.debris({ at = 0.27, count = 12, accel = { 0, -30, 0 }, speed = { 12, 22 }, spread = 55 }),
			L.pops({ at = 0.4, up = 3, count = 5, spread = 180 }),
			L.light({ up = 3, peak = 3.5, range = 12, dur = 0.4 }),
		},
	},
	-- vanishing (a defeat, a despawn): a puff in every direction, a small flash, a few stars
	poof = {
		palette = "shadow",
		anchor = "up",
		duration = 1.1,
		layers = {
			L.flash({ size = { { 0, 1 }, { 0.25, 2.2 }, { 1, 1.4 } } }),
			L.body({ size = { { 0, 1.5 }, { 1, 4 } } }),
			L.smoke({ at = 0.02, count = 11, speed = { 4, 9 }, spread = 180, drag = 5, life = { 0.5, 0.8 }, size = { { 0, 1.2, 0.2 }, { 1, 3.4, 0.4 } } }),
			L.ring({ r1 = 2.6, w0 = 0.6, twin = false }),
			L.pops({ at = 0.12, count = 6, spread = 180 }),
			L.light({ peak = 2, range = 8 }),
		},
	},
	-- an explosion at a point: a bigger flash, a fireball, sparks every way, a wide ring, heavy smoke, embers
	explosion = {
		palette = "fire",
		anchor = "up",
		duration = 1.5,
		layers = {
			L.flash({ size = { { 0, 3 }, { 0.25, 6.5 }, { 1, 4.2 } } }),
			L.under({ size = { { 0, 5 }, { 1, 10 } } }),
			L.fireball(),
			L.core({ count = 3, size = { { 0, 1.5 }, { 0.25, 4 }, { 1, 0 } } }),
			L.sparks({ count = 30, speed = { 30, 60 }, spread = 180, drag = 7, accel = { 0, -20, 0 } }),
			L.ring({ r1 = 7, w0 = 1.4, dur = 0.26 }),
			L.smoke({ count = 10, speed = { 4, 9 }, spread = 180, life = { 0.6, 1.0 }, size = { { 0, 2.5, 0.4 }, { 1, 6.5, 0.8 } } }),
			L.embers({ rate = 55, spread = 180, speed = { 6, 14 } }),
			L.light({ peak = 5, range = 18, dur = 0.3 }),
		},
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
	if l.disc then
		props.EmissionDirection = Enum.NormalId.Top
		props.Shape = Enum.ParticleEmitterShape.Disc
		props.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		props.ShapePartial = l.disc[2] or 1
	end
	if l.flat then
		-- a particle is drawn across its velocity: a tiny upward speed lays it on the floor
		props.EmissionDirection = Enum.NormalId.Top
		props.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		props.Speed = NumberRange.new(0.01)
		props.Rotation = NumberRange.new(l.rotation or 0)
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
	local anchor = recipe.anchor or "hit"
	local duration = opts.duration or recipe.duration
	local clock = FxClock.new(recipe.name or "FxRecipe", duration)
	local smooth, lerp = FxClock.smooth, FxClock.lerp
	local spray = -d
	if anchor ~= "hit" then
		spray = Vector3.yAxis
		if anchor == "feet" and model then
			local cf, size = model:GetBoundingBox()
			p = cf.Position - Vector3.new(0, size.Y / 2, 0)
		elseif model then
			p = model:GetPivot().Position
		end
	end
	local side = (math.abs(spray.Y) < 0.9 and spray:Cross(Vector3.yAxis) or spray:Cross(Vector3.xAxis)).Unit
	local atts = {
		hit = clock:attachment(CFrame.fromMatrix(p, side, spray)),
		front = clock:attachment(CFrame.new(p + spray * 0.4 * s)),
	}

	for _, l in recipe.layers do
		if l.kind == "burst" or l.kind == "stream" then
			local parent = atts[l.where or "hit"]
			local at = parent.WorldPosition + spray * (l.up or 0) * s
			if l.disc then
				local r = l.disc[1] * s
				parent = clock:part({ Size = Vector3.new(r * 2, 0.2, r * 2), CFrame = CFrame.fromMatrix(at, side, spray) })
			elseif l.up then
				parent = clock:attachment(CFrame.fromMatrix(at, side, spray))
			end
			local e = clock:emitter(parent, emitterProps(l, pal, s))
			FxTextures.apply(e, l.slot)
			if l.kind == "burst" then
				clock:at(l.at, function()
					e:Emit(l.count)
				end)
			else
				-- the rate ramps in and out over 15% of the span, so the stream has no seam
				local to = if l.to == "end" then duration - 0.35 else l.to
				clock:stream(e, l.from, to, function(t)
					local u = (t - l.from) / (to - l.from)
					return l.rate * smooth(0, 0.15, u) * (1 - smooth(0.85, 1, u))
				end)
			end
		elseif l.kind == "ring" then
			local cam = workspace.CurrentCamera
			local toCam = if cam then (cam.CFrame.Position - p).Unit else spray
			local n = if l.plane == "floor" then Vector3.yAxis else (spray + toCam).Unit
			local y0, y1 = (l.y0 or (l.plane == "floor" and 0.15 or 0)) * s, (l.y1 or l.y0 or (l.plane == "floor" and 0.15 or 0)) * s
			local b1 = (math.abs(n.Y) < 0.9 and n:Cross(Vector3.yAxis) or n:Cross(Vector3.xAxis)).Unit
			local b2 = n:Cross(b1).Unit
			local segs = l.segments or 12
			local function joint(j, r, w, a, col, y)
				local ang = (j - 1) / segs * math.pi * 2
				local radial = b1 * math.cos(ang) + b2 * math.sin(ang)
				local tan = -b1 * math.sin(ang) + b2 * math.cos(ang)
				return { cf = CFrame.fromMatrix(p + n * y + radial * r, tan, radial), width = w, alpha = a, color = col }
			end
			local c0, c1, dark = key(pal, l.color[1]), key(pal, l.color[2]), key(pal, "dark")
			local r0, r1, w0, w1 = l.r0 * s, l.r1 * s, l.w0 * s, l.w1 * s
			local ring = clock:ribbon(segs, { LightEmission = l.emission or 0.8, Brightness = l.brightness or 2.5, ZOffset = l.z or 0.5 })
			local twin = l.twin and clock:ribbon(segs, { LightEmission = 0, Brightness = 1, ZOffset = -0.3 })
			local dur = if l.dur == "end" then duration - l.at - 0.1 else l.dur
			clock:span(l.at, l.at + dur, function(u)
				local e = FxClock.outQuart(u)
				local col = c0:Lerp(c1, smooth(0, 0.25, u))
				local y = lerp(y0, y1, u)
				ring.update(function(j)
					return joint(j, lerp(r0, r1, e), lerp(w0, w1, e), smooth(0.35, 1, u), col, y)
				end)
				if twin then
					local u2 = math.max(u - 0.08, 0)
					local e2 = FxClock.outQuart(u2)
					twin.update(function(j)
						return joint(j, lerp(r0, r1 * 0.92, e2), lerp(w0 * 1.6, w1 * 1.67, e2), 0.5 + 0.5 * smooth(0.3, 1, u2), dark, lerp(y0, y1, u2))
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
			local holder = if l.up then clock:attachment(CFrame.new(p + spray * l.up * s)) else atts.front
			local light = clock:light(holder, { Range = l.range * s, Color = key(pal, "light") })
			local dur = if l.dur == "end" then duration - l.at - 0.1 else l.dur
			clock:span(l.at, l.at + dur, function(u)
				light.Brightness = if l.hold then l.peak * smooth(0, 0.15, u) * (1 - smooth(0.75, 1, u)) else l.peak * (1 - u) ^ 2
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
