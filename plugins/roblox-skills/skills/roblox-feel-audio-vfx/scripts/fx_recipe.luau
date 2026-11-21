--!nonstrict
-- fx_recipe: an effect written as data. A recipe is a list of layers; each layer is one of a few kinds (burst,
-- stream, ring, light, column, helix, mark, spikes, tail) with plain numbers and palette keys, so a new effect is a new table, not new code
-- (roblox-feel-audio-vfx section 3i). Needs fx_clock and fx_textures. Client only.
--
-- local FxRecipe = require(folder.fx_recipe)
-- FxRecipe.preload() -- once on the client before the first cast (it yields while the textures load)
-- FxRecipe.play("hit_electric", targetModel | impactCFrame, { scale = 1, direction = d }) -> clock
-- FxRecipe.play(myRecipeTable, impactCFrame, { palette = "fire" })
-- FxRecipe.play("aura", characterModel, { duration = 6 })
--
-- impactCFrame.LookVector = the direction the hit travels; sparks fly back against it. opts.scale multiplies
-- sizes, speeds and radii, and a light's range by its square root (times stay; a range grown with the scale lit the
-- whole floor as one flat oval at scale 4); opts.palette overrides the recipe's palette (a name in
-- FxRecipe.palettes or a table with the same keys); opts.duration replaces the recipe's duration (how long an aura
-- holds); opts.noPlay returns the clock unstarted.
--
-- Palette keys: white (the contact frame), hot (bright edge), mid (the saturated body), dark (the underlayer),
-- smoke0 -> smoke1 (smoke over its life), light (the PointLight). A layer names keys, never colours.
--
-- Layer fields (every size, speed, radius and z is in studs at scale 1; z is the ZOffset toward the camera, so a
-- glow with z above the radius of a moving body is drawn over it, and one with z under it shows only round its
-- outline, as a rim):
--   burst : at, count, slot, where ("front" | "hit"), life {min, max}, size {{t, v, envelope?}, ...},
--           alpha {{t, transparency}, ...}, color (key | {{t, key}, ...}), emission, brightness, z,
--           speed {min, max}, spread (deg), drag, accel {x, y, z}, rotation (deg or {min, max}), rotSpeed {min, max},
--           along (true: stretched along its velocity), squash {{t, v}, ...}
--   stream: the burst fields with from, to (s) and rate (per s) in place of at and count
--   ring  : at, dur, r0, r1, w0, w1, segments, color {from key, to key}, emission, brightness, z,
--           twin (true: a dark ring under it, a little behind in time), arcs (n: n broken arcs with pointed ends
--           and soft edges instead of a clean circle, each with its own start, length, radius, life and turn; no twin)
--   light : at, dur, peak, range, hold (true: ramps in, holds and ramps out, for an aura), shape ({{u, share of
--           peak}, ...}: any curve over its span), flicker (0-0.5: the brightness jitters like a flame), color (a
--           palette key, or a ramp {{u, key}, ...} read over its span; default "light"), soft (true: three lights
--           in one, so a big light fades across a floor instead of drawing a flat oval)
--   spikes: at, dur, arms, len, w (width at the centre), long ({1, 0.42}: arm lengths in turn, so 4 arms make a
--           four-point star), turn (deg), spin (deg per s), jitter (deg), vary (0-1, length), stagger (0-1, share of
--           the span an arm may start late), fly (the arm leaves the centre and travels that many lengths: shards),
--           open, close (shares of its span: opens by `open`, shrinks from `close`), plane ("floor"), color {from, to},
--           alpha, emission, brightness, z, up. Pointed rays drawn as tapered beams, no texture
--   tail  : at, to (s or "end"), w, life (s of path it keeps), taper (1 = straight taper), segments, color {head, end}, alpha,
--           emission, brightness, z, up. A ribbon along the path a followed anchor flew (opts.follow), on the clock
-- More fields: a burst or stream takes up (studs above the anchor; on a "trail" anchor it runs back along the
-- flight, so a negative up sits ahead of the body), disc {radius, partial} (emit from a flat disc
-- at the anchor: partial 1 fills it, 0 is the rim only) and flat (true: the particle lies on the floor); a ring
-- takes plane ("floor": it lies flat) and y0, y1 (it travels from y0 to y1 studs above the anchor); a stream's
-- `to` may be "end" (runs until 0.35 s before the clock ends, so opts.duration sets how long an aura holds);
-- a ring's or a light's dur may be "end" too (a ring with r0 = r1 then holds its size and fades out).
-- Skill-size fields: a burst or stream takes gather (radius: emitted on a sphere of that radius and thrown at its
-- centre, for a charge) and dir ("down": thrown down, for rain inside a column); any layer takes times and every
-- (played `times` times, `every` seconds apart; times = "end" repeats until the effect ends); a fifth kind:
--   column: at, dur, y0, y1, w0, w1, color {from key, to key}, alpha, slot ("band" | "electric" | "smoke"),
--           length, speed, emission, brightness, z, hold (true: opens, holds its width and closes; dur may be "end")
--           one camera-facing vertical beam; without hold it widens from w0 to w1 and fades (a strike);
--           flicker (0-0.5: the width jitters), drop (s: the beam's lower end comes down from the top in that time)
--   helix : at, dur, r, y0, y1, turns, w, spin (turns per s; negative scrolls down), phase (0-1), segments,
--           color {from key, to key}, alpha: a band wound around the vertical axis that keeps turning, so a
--           column moves for as long as it holds
-- A burst or stream also takes tube {radius, height}: emitted anywhere in a box that tall above the anchor.
-- recipe.anchor: "hit" (default: the contact point, sparks go back at the attacker), "up" (the same point, up is
-- world up: pickups, explosions) or "feet" (the floor under a model, or the CFrame's position: auras, level-ups,
-- ground hits).
-- "front" sits 0.4 studs toward the attacker so glow layers do not sink into the target; "hit" is the contact
-- point with its up axis pointing back at the attacker (speed and spread fan out from there).
-- Defaults of a layer written by hand: where "hit", emission 1, brightness 1, z 0, no motion; a ring: 12 segments,
-- emission 0.8, brightness 2.5, z 0.5. rotation is a fixed start angle in degrees, or {min, max} for a random one in
-- that range (without it each particle starts at a random angle). A template override replaces the whole field (a
-- new size table, not one key of it). duration is when the clock destroys everything: the last death plus a margin.
-- One ring is `segments` beams, and its twin as many again. An effect that is not a hit sets recipe.anchor ("up" or
-- "feet"), so speed and spread fan out from world up; spread 180 sends particles every way.
--
-- Targets: a character model (above), a CFrame, or a part, an attachment or another model (its own frame; a hit
-- travels into its front unless opts.direction says otherwise).
-- Moving things: opts.follow = true moves the whole effect with its target every frame; opts.follow = function(t)
-- -> Vector3 | CFrame moves it along a path in clock time. Emitter parents move with it; rings, columns, helices and
-- lights move by the same shift. recipe.anchor "trail": spray points back along the motion and turns with it.
-- A burst or stream takes path (width in studs): it is emitted from a box over the distance its anchor moved this
-- step, so a fast trail has no gaps between frames. opts.emitUntil (s): "end" streams, rings, columns, helices and
-- lights stop there while the clock runs on to opts.duration, so the last pieces finish their lives.
-- A stream takes density (particles per stud the anchor moved, on top of rate, while following: a trail stays as
-- full at any speed; alive per layer = rate x life + density x speed / scale x life, so mind it on fast things), ramp {in,
-- out} (shares of its span; default 0.15 each), len (studs at scale 1: each piece lives as long as the anchor takes
-- to move that far, within life {min, max} and never longer than the stream has run, so a tail keeps its shape at
-- any speed and a growing one ends in a faded point; opts.tail multiplies it), cut (s: when an "end" stream stops at
-- opts.emitUntil, its live pieces go out from the far end toward the anchor in that time, so a trail's tail does not
-- hang in the air after the impact) and grow (true: it builds toward its end and stops there at full
-- rate); a light takes grow (rises to its peak at the end, then goes out) and, with hold,
-- ramp; a ring takes ease ("out" default, "in": slow then fast, closing on a beat, "linear") and alpha {{u,
-- transparency}, ...} over its span (default: fades over the last 65%).
-- FxRecipe.travel(from, to, opts) -> clock: something flies from `from` to `to` (Vector3, CFrame, part, attachment
-- or model; a moving `to` is chased) in opts.time s (default 0.6), opts.arc studs high at the middle, opts.ease
-- "linear" (default), "in" (already moving, then faster: a fall) or "out". opts.body (an anchored part or model) is
-- moved along the path facing it, or turned by opts.spin (Vector3, turns per second about its own axes), arrives
-- when its front reaches `to` (its path ends opts.reach studs short; default half its longest side), and is
-- destroyed on arrival unless opts.keepBody. opts.trail (recipe; default "trail", false for none) follows it;
-- opts.tell (recipe) plays at `to` for the flight; opts.impact (a recipe or a list) plays on arrival with LookVector
-- along the flight (a recipe whose anchor is not "feet" is set back opts.impactLift studs, default 1, along the
-- flight); opts.palette, opts.scale, opts.tellScale, opts.impactScale, opts.tail (multiplies the trail's len);
-- opts.onArrive(position, direction).
-- A burst or stream takes locked (true: its particles move with their anchor: a glow that rides on a moving body).
-- A locked stream takes clear (true: while following, it shrinks once a surface below or ahead of the anchor is
-- nearer than its radius, so the floor never cuts a big glow in a straight line; a particle has no soft edge where
-- it crosses a surface). The rays skip the effect's own parts and opts.ignore (travel passes its body). A light
-- takes clear too: riding ahead of a moving body it dims as it nears a surface and is out when it gets there.
-- A kind for what an effect leaves behind:
--   mark : at, dur, r0, r1 (radius at birth and after `grow` s), grow, alpha {{u, transparency}, ...} over dur,
--          color (key | {{u, key}, ...} over dur), glow (true: lit by itself, so it reads on a dark floor; a colour
--          ramp hot -> dark makes it cool), brightness, slot (default "glow": a soft disc), y (studs above the anchor)
--          an image lying flat at the anchor that stays where it was put and fades: a scorch, a stain, frost. For
--          a "feet" recipe (the anchor on the floor).
--
-- hit_electric reproduces scripts/hit_impact.luau layer for layer: built side by side in Studio 0.748 Play on
-- 2026-11-20, all 8 emitters had the same 19 properties and the beam and light counts matched. The six element
-- hits were judged good by the owner at real speed in Studio on a desktop (2026-11-20). hit_water and the recipes
-- that are not hits ran with no errors in Studio Play and were looked at frozen at 0.08, 0.3 and 0.7 s (level_up,
-- aura, heal and spawn_in once more at 0.6 s after their streaks and dots were made smaller); the last size changes
-- to wisps, debris and embers were not captured again; the owner watched them at real speed and called them good
-- (2026-11-20). The four skill recipes ran with no errors in Studio 0.748 Play, were looked at frozen at 0.3, 0.62,
-- 1.0, 1.2 and 1.6 s and seen running at real speed from 34 studs. The owner rejected the first pillar at real
-- speed (a held beam: a still picture); its hold was rebuilt from moving pieces (helix, glowfall, falling rings)
-- and looked at frozen at 0.56, 1.0 and 1.35 s; the owner then watched it at real speed and called it fairly
-- satisfying (2026-11-20). Nova, zone and eruption have no owner verdict yet. Nothing here was checked on a phone
-- or in a published game.
-- Moving things (2026-11-20, Studio 0.748 Play, desktop view, slow motion at 0.04 and 0.2 and frozen frames):
-- travel with trail (scale 3), tell (1.5) and impacts over 94 studs in 1 s ("in" ease, about 38 to 150 studs/s),
-- a lobbed fireball of particles only (arc 10) and a holy bolt at 131 studs/s into a wall. Fixed on the way: a
-- core 4.5 studs wide read as a white disc over the body (now under the body's size, white only at birth); fire
-- cards laid along their velocity read as paper scraps (flames now face the camera); a rate per second left gaps
-- at high speed and the bolt's glow read as a string of dots (now density per stud); explosion at a floor point
-- was cut by the floor into a white dome and a half ring (travel now sets non-"feet" impacts back along the flight;
-- on a floor, play a "feet" recipe). All 22 recipes then played with no errors, and part, attachment and moving
-- part targets (one destroyed while followed) worked. No owner verdict yet.

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local FxRecipe = {}

local C = Color3.fromRGB

FxRecipe.palettes = {
	electric = { white = C(255, 255, 255), hot = C(110, 200, 255), mid = C(40, 105, 255), deep = C(25, 45, 200), dark = C(10, 28, 70), smoke0 = C(55, 65, 85), smoke1 = C(100, 108, 120), light = C(160, 220, 255) },
	fire = { white = C(255, 250, 225), hot = C(255, 190, 70), mid = C(255, 95, 20), deep = C(170, 30, 10), dark = C(60, 14, 6), smoke0 = C(40, 34, 32), smoke1 = C(95, 88, 84), light = C(255, 170, 90) },
	ice = { white = C(255, 255, 255), hot = C(190, 240, 255), mid = C(90, 190, 235), deep = C(30, 100, 190), dark = C(14, 44, 70), smoke0 = C(150, 175, 195), smoke1 = C(215, 230, 240), light = C(190, 235, 255) },
	holy = { white = C(255, 255, 245), hot = C(255, 240, 170), mid = C(255, 200, 60), deep = C(210, 120, 15), dark = C(80, 50, 8), smoke0 = C(120, 105, 70), smoke1 = C(200, 190, 160), light = C(255, 235, 170) },
	shadow = { white = C(240, 220, 255), hot = C(200, 130, 255), mid = C(120, 40, 220), deep = C(85, 15, 165), dark = C(20, 6, 40), smoke0 = C(30, 22, 44), smoke1 = C(70, 58, 90), light = C(190, 130, 255) },
	poison = { white = C(245, 255, 220), hot = C(170, 255, 90), mid = C(60, 200, 60), deep = C(25, 130, 25), dark = C(10, 50, 16), smoke0 = C(40, 60, 40), smoke1 = C(100, 125, 95), light = C(170, 255, 120) },
	water = { white = C(245, 252, 255), hot = C(150, 225, 255), mid = C(30, 150, 235), deep = C(15, 80, 185), dark = C(8, 40, 78), smoke0 = C(110, 150, 185), smoke1 = C(200, 225, 240), light = C(150, 215, 255) },
	gold = { white = C(255, 255, 240), hot = C(255, 225, 110), mid = C(255, 170, 20), deep = C(195, 95, 5), dark = C(70, 38, 4), smoke0 = C(120, 100, 60), smoke1 = C(205, 190, 150), light = C(255, 215, 120) },
	heal = { white = C(250, 255, 245), hot = C(170, 255, 190), mid = C(60, 220, 130), deep = C(20, 145, 75), dark = C(8, 54, 34), smoke0 = C(90, 130, 110), smoke1 = C(190, 225, 205), light = C(170, 255, 200) },
	earth = { white = C(255, 248, 230), hot = C(240, 205, 150), mid = C(190, 130, 70), deep = C(140, 70, 30), dark = C(48, 32, 20), smoke0 = C(92, 80, 68), smoke1 = C(165, 152, 138), light = C(255, 215, 160) },
}

-- Layer templates: each returns a fresh layer table; pass a table of fields to override. A layer keeps one start,
-- from for a stream and at for every other kind: a stream made from a burst template drops the template's at (and a
-- burst made from a stream template its from), so code that reads a layer's start (l.from or l.at) gets the real one
local function layer(base)
	return function(over)
		local l = table.clone(base)
		for k, v in over or {} do
			l[k] = v
		end
		if l.kind == "stream" then
			if not (over and over.at) then
				l.at = nil
			end
		elseif not (over and over.from) then
			l.from = nil
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
-- a four-point star drawn with tapered beams: two long arms, two short
L.star = layer({ kind = "spikes", name = "Star", at = 0, dur = 0.5, arms = 4, long = { 1, 0.42 }, turn = 90, len = 3, w = 0.34, color = { "white", "hot" }, emission = 1, brightness = 4, z = 1 })
-- a ribbon behind a moving anchor that tapers to nothing
L.tail = layer({ kind = "tail", name = "Tail", at = 0, to = "end", w = 0.5, life = 0.45, taper = 1.2, color = { "white", "hot" }, alpha = 0, emission = 1, brightness = 3, z = 0.4 })
-- pointed shards thrown out of the centre
L.shards = layer({ kind = "spikes", name = "Shards", at = 0, dur = 0.45, arms = 12, long = { 1, 0.6, 0.8 }, jitter = 10, vary = 0.25, stagger = 0.15, fly = 1.4, len = 1.6, w = 0.36, open = 0.3, close = 0.5, color = { "white", "hot" }, emission = 1, brightness = 3.5, z = 0.8 })

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
-- a mark on the floor that stays where it was put and fades (a scorch); not a particle, so it can last seconds
L.mark = layer({ kind = "mark", name = "Mark", at = 0.03, dur = 3, r0 = 2, r1 = 4.5, grow = 0.12, alpha = { { 0, 0.25 }, { 0.6, 0.35 }, { 1, 1 } }, color = "dark", y = 0.04 })
-- the same mark lit by itself, cooling from hot to dark, so it reads on a dark floor
L.hotMark = layer({ kind = "mark", name = "HotMark", at = 0.03, dur = 2.4, r0 = 1, r1 = 2.6, grow = 0.1, glow = true, brightness = 1.5, alpha = { { 0, 0.15 }, { 0.5, 0.45 }, { 1, 1 } }, color = { { 0, "hot" }, { 0.3, "mid" }, { 1, "dark" } }, y = 0.05 })

-- Skill-size layers (2-4 s effects over 8-12 studs; every piece is still small and short-lived) ------------------
-- streaks pulled in to one point: the charge before a release
L.gather = layer({ kind = "stream", name = "Gather", from = 0, to = 0.5, rate = 160, slot = "streak", where = "hit", up = 3, gather = 8, life = { 0.24, 0.3 }, speed = { 24, 30 }, along = true, rotation = 90, squash = { { 0, 1.6 }, { 1, 0.8 } }, size = { { 0, 0.4, 0.08 }, { 1, 0.55, 0.1 } }, alpha = { { 0, 1 }, { 0.3, 0.1 }, { 1, 0 } }, color = { { 0, "mid" }, { 0.5, "hot" }, { 1, "white" } }, emission = 1, brightness = 3.5, z = 0.6 })
-- a vertical beam that strikes: its end comes down from the sky in 0.06 s, then it widens and fades
L.strike = layer({ kind = "column", name = "Strike", at = 0, dur = 0.3, y0 = 0, y1 = 40, w0 = 0.8, w1 = 3.2, drop = 0.06, color = { "white", "hot" }, alpha = 0.3, emission = 1, brightness = 3, z = 0.2 })
-- a vertical beam that holds: opens, keeps its width, closes
L.column = layer({ kind = "column", name = "Column", at = 0, dur = 1.2, y0 = 0, y1 = 40, w0 = 0, w1 = 2.2, hold = true, color = { "hot", "mid" }, alpha = 0.45, emission = 1, brightness = 2.5, z = 0.1 })
-- a band wound around the column that keeps turning: the motion of a held column
L.helix = layer({ kind = "helix", name = "Helix", at = 0, dur = 1.2, r = 1.5, y0 = 0.3, y1 = 30, turns = 2.5, w = 0.7, spin = -1.6, segments = 24, color = { "white", "hot" }, alpha = 0.15, emission = 1, brightness = 3, z = 0.3 })
-- soft pieces that fall down the column: its glowing body, redrawn every 0.15 s instead of one held beam
L.glowfall = layer({ kind = "stream", name = "Glowfall", from = 0, to = 1, rate = 90, slot = "glow", where = "hit", up = 1, tube = { 0.9, 27 }, dir = "down", life = { 0.12, 0.2 }, speed = { 35, 55 }, rotation = 0, squash = { { 0, 1.8 }, { 1, 2.6 } }, size = { { 0, 1.5, 0.3 }, { 1, 0.9, 0.2 } }, alpha = { { 0, 1 }, { 0.3, 0.55 }, { 1, 1 } }, color = { { 0, "white" }, { 0.4, "hot" }, { 1, "mid" } }, emission = 0.9, brightness = 2.5, z = 0.2 })
-- bolts that crackle at random places over a floor disc
L.crackle = layer({ kind = "stream", name = "Crackle", from = 0, to = 1, rate = 60, slot = "electric", where = "hit", up = 0.8, disc = { 8, 1 }, life = { 0.06, 0.1 }, size = { { 0, 3.5, 1 }, { 1, 5.5, 1 } }, alpha = { { 0, 0 }, { 1, 0.6 } }, color = { { 0, "white" }, { 1, "hot" } }, emission = 1, brightness = 4, z = 0.8 })
-- streaks that fall inside a column, born at every height of it
L.rain = layer({ kind = "stream", name = "Rain", from = 0, to = 1, rate = 240, slot = "streak", where = "hit", up = 5, tube = { 1.9, 27 }, dir = "down", life = { 0.14, 0.2 }, speed = { 60, 90 }, spread = 2, along = true, rotation = 90, squash = { { 0, 2 }, { 1, 1.2 } }, size = { { 0, 0.45, 0.1 }, { 1, 0.2 } }, alpha = { { 0, 0.5 }, { 0.2, 0 }, { 1, 1 } }, color = { { 0, "white" }, { 0.5, "hot" }, { 1, "mid" } }, emission = 1, brightness = 4, z = 0.5 })
-- small lumps of fire that rise from a floor disc: a column of fire built from short-lived pieces
L.flames = layer({ kind = "stream", name = "Flames", from = 0, to = 0.9, rate = 50, slot = "fire", where = "hit", up = 0.6, disc = { 2.4, 1 }, life = { 0.25, 0.34 }, speed = { 30, 52 }, spread = 10, drag = 1.5, size = { { 0, 1.6, 0.3 }, { 1, 4.2, 0.5 } }, alpha = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } }, color = { { 0, "white" }, { 0.35, "hot" }, { 1, "mid" } }, emission = 0.7, brightness = 2.5, z = 0.4 })

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

	-- Skills: 2-4 s, 8-12 studs. Each has a tell (the player reads what is coming), a release and a tail. -----------
	-- a nova: streaks gather for half a second, then rings and sparks burst out and bolts crackle over the floor
	skill_nova = {
		palette = "electric",
		anchor = "feet",
		duration = 2.4,
		layers = {
			-- tell 0-0.55
			L.gather(),
			L.floorRing({ name = "Closing", at = 0, dur = 0.5, r0 = 10, r1 = 1.5, w0 = 0.15, w1 = 0.5, twin = false }),
			L.bolts({ kind = "stream", name = "CoreBolts", from = 0.1, to = 0.55, rate = 16, up = 3, size = { { 0, 1.4, 0.5 }, { 1, 2.4, 0.5 } } }),
			L.wisps({ name = "CoreGlow", from = 0.05, to = 0.55, rate = 20, up = 3, disc = { 0.6, 1 }, speed = { 0, 1 }, size = { { 0, 0 }, { 0.3, 1.1, 0.3 }, { 1, 0 } }, life = { 0.12, 0.18 } }),
			L.light({ name = "ChargeLight", at = 0, dur = 0.55, up = 3, peak = 2.5, range = 14, hold = true }),
			-- release 0.55
			L.flash({ at = 0.55, up = 3, size = { { 0, 4 }, { 0.25, 9 }, { 1, 6 } } }),
			L.core({ at = 0.57, up = 3, count = 4, size = { { 0, 2 }, { 0.25, 6 }, { 1, 0 } } }),
			L.bolts({ name = "BigBolts", at = 0.57, up = 3, count = 6, size = { { 0, 4, 1 }, { 1, 7, 1 } }, life = { 0.08, 0.14 } }),
			L.scorch({ at = 0.57, size = { { 0, 8 }, { 0.2, 13 }, { 1, 14 } }, life = { 0.9, 0.9 } }),
			L.floorGlow({ at = 0.56, size = { { 0, 6 }, { 1, 19 } } }),
			L.floorRing({ at = 0.56, dur = 0.42, r0 = 1, r1 = 12, w0 = 1.6, w1 = 0.15, segments = 20, times = 3, every = 0.12 }),
			L.sparks({ at = 0.57, up = 3, count = 44, speed = { 40, 70 }, spread = 180, drag = 6, accel = { 0, -18, 0 }, life = { 0.2, 0.35 } }),
			L.light({ at = 0.55, up = 3, peak = 6, range = 26, dur = 0.35 }),
			-- tail 0.6-1.9
			L.crackle({ from = 0.62, to = 1.8 }),
			L.floorGlow({ kind = "stream", name = "Arcs", from = 0.62, to = 1.7, rate = 12, disc = { 7, 1 }, life = { 0.2, 0.3 }, size = { { 0, 2 }, { 1, 5 } }, color = "hot", alpha = { { 0, 1 }, { 0.4, 0.45 }, { 1, 1 } } }),
			L.floorRing({ name = "Aftershock", at = 1.0, dur = 0.36, r0 = 1, r1 = 10, w0 = 0.9, w1 = 0.1, segments = 20, twin = false, times = 2, every = 0.4 }),
			L.sparks({ name = "AfterSparks", at = 1.0, up = 2, count = 18, speed = { 28, 48 }, spread = 180, drag = 6, life = { 0.2, 0.32 }, times = 2, every = 0.4 }),
			L.flash({ name = "AfterFlash", at = 1.0, up = 2.5, size = { { 0, 2 }, { 0.25, 5 }, { 1, 3 } }, times = 2, every = 0.4 }),
			L.pops({ kind = "stream", name = "Glints", from = 0.65, to = 1.9, rate = 30, up = 1.2, disc = { 8, 1 }, speed = { 1, 4 }, spread = 60, life = { 0.25, 0.35 } }),
			L.motes({ name = "RimMotes", from = 0.62, to = 1.6, rate = 110, disc = { 8, 0 }, speed = { 8, 14 } }),
			L.light({ name = "TailLight", at = 0.9, up = 2, peak = 1.5, range = 16, dur = 1.0, hold = true }),
		},
	},
	-- a strike from the sky: a thin aiming line and a closing ring, a beam that slams down, then a held column
	-- with light raining inside it and rings pulsing out
	skill_pillar = {
		palette = "holy",
		anchor = "feet",
		duration = 2.7,
		layers = {
			-- tell 0-0.5
			L.column({ name = "AimLine", at = 0, dur = 0.5, w1 = 0.18, alpha = 0.2, color = { "hot", "hot" } }),
			L.floorRing({ name = "Mark", at = 0, dur = 0.5, r0 = 5, r1 = 5, w0 = 0.22, w1 = 0.22, twin = false }),
			L.floorRing({ name = "Closing", at = 0, dur = 0.5, r0 = 5, r1 = 0.8, w0 = 0.12, w1 = 0.5, twin = false }),
			L.motes({ name = "TellMotes", from = 0, to = 0.5, rate = 40, disc = { 5, 0 }, speed = { 6, 10 } }),
			-- strike 0.5
			L.strike({ at = 0.5 }),
			L.strike({ name = "StrikeCore", at = 0.5, w0 = 0.4, w1 = 1.3, color = { "white", "white" }, alpha = 0, brightness = 4, z = 0.3 }),
			L.glowfall({ kind = "burst", name = "StrikeBody", at = 0.52, count = 36, tube = { 1.4, 27 }, size = { { 0, 2.2, 0.4 }, { 1, 1.2, 0.3 } } }),
			L.flash({ at = 0.5, up = 2.2, size = { { 0, 4 }, { 0.25, 8 }, { 1, 5 } } }),
			L.scorch({ at = 0.52, size = { { 0, 6 }, { 0.2, 10 }, { 1, 11 } }, life = { 0.9, 0.9 } }),
			L.floorGlow({ at = 0.51, size = { { 0, 5 }, { 1, 15 } } }),
			L.floorRing({ at = 0.51, dur = 0.38, r0 = 1, r1 = 9.5, w0 = 1.5, w1 = 0.15, segments = 20, times = 2, every = 0.1 }),
			L.debris({ at = 0.52, count = 30, speed = { 30, 55 }, spread = 50, accel = { 0, -60, 0 } }),
			L.light({ at = 0.5, up = 2, peak = 6, range = 26, dur = 0.35 }),
			-- hold 0.6-1.9
			-- nothing here is a held picture: a thin core that flickers, bands that turn, rings and pieces that fall
			L.column({ name = "CoreLine", at = 0.58, dur = 1.37, w1 = 0.5, color = { "white", "white" }, alpha = 0.05, brightness = 4, flicker = 0.35, z = 0.3 }),
			L.helix({ at = 0.6, dur = 1.32 }),
			L.helix({ name = "Helix2", at = 0.6, dur = 1.32, phase = 0.5, color = { "hot", "mid" }, brightness = 2.2 }),
			L.helix({ name = "HelixOuter", at = 0.66, dur = 1.24, r = 2.5, turns = 1.5, w = 0.22, spin = 1.1, segments = 16, color = { "hot", "mid" }, alpha = 0.3 }),
			L.glowfall({ from = 0.6, to = 1.88 }),
			L.rain({ from = 0.6, to = 1.88 }),
			L.riseRing({ name = "Descend", at = 0.62, dur = 0.34, y0 = 24, y1 = 0.4, r0 = 2.1, r1 = 2.7, w0 = 0.3, w1 = 0.1, segments = 12, times = 6, every = 0.2, color = { "white", "mid" } }),
			L.sparks({ kind = "stream", name = "Splash", from = 0.6, to = 1.88, rate = 70, up = 0.3, speed = { 18, 34 }, spread = 80, drag = 4, accel = { 0, -40, 0 }, life = { 0.18, 0.3 }, size = { { 0, 0.6, 0.12 }, { 1, 0.15 } } }),
			L.floorGlow({ kind = "stream", name = "BaseFlicker", from = 0.6, to = 1.88, rate = 14, disc = { 2.4, 1 }, life = { 0.15, 0.25 }, size = { { 0, 2 }, { 1, 4.5 } }, color = "hot", alpha = { { 0, 1 }, { 0.4, 0.4 }, { 1, 1 } } }),
			L.floorRing({ name = "Pulse", at = 0.9, dur = 0.4, r0 = 1.5, r1 = 7.5, w0 = 0.8, w1 = 0.1, twin = false, times = 2, every = 0.45 }),
			L.motes({ from = 0.6, to = 1.85, rate = 100, disc = { 3.4, 0 }, speed = { 10, 16 } }),
			L.wisps({ from = 0.6, to = 1.9, rate = 50, disc = { 4.5, 1 } }),
			L.light({ name = "HoldLight", at = 0.8, up = 3, peak = 3, range = 20, dur = 1.2, hold = true }),
			-- end 1.9-2.4
			L.riseRing({ at = 1.85, dur = 0.5, r0 = 3, r1 = 2.2, y0 = 0.3, y1 = 12, times = 2, every = 0.15 }),
			L.pops({ at = 1.95, up = 5, count = 12, speed = { 3, 9 }, spread = 180, life = { 0.3, 0.35 } }),
		},
	},
	-- a zone that stays on the floor for opts.duration (default 4 s): a held border, pulses from the centre,
	-- small pieces drifting up all over it
	skill_zone = {
		palette = "poison",
		anchor = "feet",
		duration = 4,
		layers = {
			-- open
			L.flash({ up = 0.8, size = { { 0, 2 }, { 0.25, 4.5 }, { 1, 3 } } }),
			L.floorGlow({ size = { { 0, 5 }, { 1, 17 } } }),
			L.floorRing({ dur = 0.35, r0 = 1, r1 = 8, w0 = 1.4, w1 = 0.3, segments = 20 }),
			-- held
			L.floorRing({ name = "Border", at = 0.3, dur = "end", r0 = 8, r1 = 8, w0 = 0.32, w1 = 0.32, segments = 20, twin = false, color = { "white", "mid" } }),
			L.floorRing({ name = "Inner", at = 0.35, dur = "end", r0 = 5.6, r1 = 5.6, w0 = 0.1, w1 = 0.1, segments = 20, twin = false, color = { "hot", "mid" } }),
			L.floorRing({ name = "Pulse", at = 0.6, dur = 0.55, r0 = 0.8, r1 = 8, w0 = 0.7, w1 = 0.1, segments = 20, twin = false, color = { "hot", "mid" }, times = "end", every = 0.6 }),
			L.floorGlow({ kind = "stream", name = "Patches", from = 0.2, to = "end", rate = 14, disc = { 6.5, 1 }, life = { 0.3, 0.35 }, size = { { 0, 2.5 }, { 1, 5.5 } }, alpha = { { 0, 1 }, { 0.4, 0.35 }, { 1, 1 } } }),
			L.wisps({ from = 0.2, to = "end", rate = 70, disc = { 8, 1 }, up = 1, size = { { 0, 0 }, { 0.3, 0.4, 0.1 }, { 1, 0 } } }),
			L.motes({ from = 0.2, to = "end", rate = 90, disc = { 8, 1 }, speed = { 5, 9 }, life = { 0.28, 0.35 } }),
			L.motes({ name = "Wall", from = 0.3, to = "end", rate = 90, disc = { 8, 0 }, speed = { 9, 14 } }),
			L.pops({ kind = "stream", name = "Bubbles", from = 0.3, to = "end", rate = 18, up = 0.8, disc = { 7.5, 1 }, speed = { 2, 5 }, spread = 20, accel = { 0, 8, 0 }, life = { 0.28, 0.35 } }),
			L.smoke({ kind = "stream", name = "Haze", from = 0.2, to = "end", rate = 5, up = 0.6, disc = { 6.5, 1 }, speed = { 0.5, 2 }, spread = 60, life = { 0.6, 0.9 }, size = { { 0, 2, 0.3 }, { 1, 4.5, 0.5 } }, alpha = { { 0, 1 }, { 0.3, 0.6 }, { 1, 1 } } }),
			L.light({ up = 2, peak = 2, range = 18, dur = "end", hold = true }),
		},
	},
	-- an eruption from the floor: the ground glows and spits embers, then a fountain of fire lumps and chips,
	-- rings and dust along the floor, smoke and embers after
	skill_eruption = {
		palette = "fire",
		anchor = "feet",
		duration = 3.9,
		layers = {
			-- tell 0-0.4
			L.floorRing({ name = "Closing", at = 0, dur = 0.4, r0 = 7, r1 = 2, w0 = 0.15, w1 = 0.5, twin = false }),
			L.floorGlow({ kind = "stream", name = "Heat", from = 0, to = 0.42, rate = 14, disc = { 3, 1 }, life = { 0.2, 0.3 }, size = { { 0, 1.5 }, { 1, 4 } }, color = "hot", alpha = { { 0, 1 }, { 0.4, 0.4 }, { 1, 1 } } }),
			L.embers({ name = "TellEmbers", from = 0, to = 0.42, rate = 45, slot = "glow", along = false, squash = false, rotation = 0, disc = { 3.5, 1 }, up = 0.3, speed = { 8, 16 }, spread = 25, size = { { 0, 0.2, 0.06 }, { 1, 0.05 } } }),
			L.light({ name = "TellLight", at = 0, dur = 0.42, up = 1, peak = 2.5, range = 7.7, hold = true, color = "mid" }),
			-- burst 0.4: the floor answers on the same frame as the flash (the hot spot's spike, floor glow)
			L.flash({ at = 0.4, up = 2, size = { { 0, 1.5 }, { 0.25, 3 }, { 1, 2 } }, color = { { 0, "white" }, { 0.5, "hot" }, { 1, "hot" } }, brightness = 3 }),
			L.core({ at = 0.4, up = 1.5, count = 3 }),
			-- a hot spot on the floor: bright on the contact frame, then down to a tenth within 0.13 s (held brighter, it drew a
			-- white disc inside the rings), flickering under the fire and cooling with it
			L.light({ name = "HotSpot", at = 0.4, up = 0.5, peak = 8, range = 7, dur = 3.2, shape = { { 0, 1 }, { 0.017, 0.3 }, { 0.039, 0.1 }, { 0.338, 0.14 }, { 0.569, 0.07 }, { 1, 0 } }, flicker = 0.35, color = { { 0, "hot" }, { 0.084, "hot" }, { 0.281, "mid" }, { 0.563, "mid" }, { 1, "deep" } } }),
			-- no flat glow or scorch under the release: 15-40 studs wide at scale 2.6, their soft-circle texture showed its
			-- square edge as a flat card on the contact frame; the lights draw the floor's answer
			-- fire lumps over the upper half only (spread 80, lifted): thrown every way, half went into the floor and the fire's
			-- base was cut flat, a box
			L.fireball({ at = 0.42, up = 2, count = 7, spread = 80, emission = 1, size = { { 0, 3, 0.5 }, { 1, 7, 0.8 } } }),
			-- no floor rings: drawn flat on the floor they read as a UI ring or a target, and broken arcs as a decal; the dust
			-- thrown out along the floor carries the shock. Chips in a wide cone, hot not white (40 white streaks in a 28 degree
			-- cone read as a bundle of needles), as glowing dots (streaks that cooled to red read as thin red needles). Sparks
			-- on the flash's own frame, so the contact reads as a burst of spikes and not as a soft white ball; fast, with no
			-- drag or gravity, hot to the end and gone in 0.14 s (slowed and cooled, the template's streaks stood as tan sticks)
			L.debris({ at = 0.43, count = 26, slot = "glow", along = false, squash = false, rotation = 0, speed = { 30, 75 }, spread = 45, accel = { 0, -95, 0 }, size = { { 0, 0.3, 0.08 }, { 1, 0.1 } }, color = { { 0, "hot" }, { 0.5, "mid" }, { 1, "deep" } } }),
			L.sparks({ at = 0.4, up = 1, count = 30, speed = { 35, 75 }, spread = 75, drag = 0, accel = { 0, 0, 0 }, life = { 0.08, 0.14 }, size = { { 0, 1.2, 0.2 }, { 1, 0.5 } }, color = "hot" }),
			-- dust lifted (big puffs centred low were cut by the floor in a straight line) and drawn under the fire: pulled
			-- toward the camera, dark dust covered the burst as a black blob
			L.dust({ at = 0.45, count = 28, speed = { 18, 30 }, up = 0.8, z = 0 }),
			-- the flash's light as a soft pool: one light this bright lit the floor as a flat yellow oval with a hard edge
			L.light({ at = 0.4, up = 2, peak = 7, range = 15.4, dur = 0.4, soft = true, color = { { 0, "hot" }, { 1, "mid" } } }),
			-- fountain 0.42-1.4
			L.flames({ from = 0.42, to = 1.35, emission = 1, settle = 0.4 }),
			L.flames({ name = "FlamesWide", from = 0.45, to = 1.1, rate = 22, disc = { 4.5, 1 }, speed = { 10, 18 }, emission = 1, size = { { 0, 1.2, 0.3 }, { 1, 3, 0.5 } } }),
			-- the fountain spits chips as glowing dots too: streaks thrown up and slowed by gravity stood in the fire as
			-- white sticks
			L.debris({ name = "Spit", kind = "stream", from = 0.5, to = 1.3, rate = 45, slot = "glow", along = false, squash = false, rotation = 0, disc = { 2, 1 }, speed = { 30, 55 }, spread = 22, accel = { 0, -80, 0 }, size = { { 0, 0.3, 0.08 }, { 1, 0.1 } }, color = { { 0, "hot" }, { 0.5, "mid" }, { 1, "deep" } } }),
			-- amber over the fountain: from hot to the fire's mid as it dies, flickering, out with the last flames
			L.light({ name = "FountainLight", at = 0.6, up = 3, peak = 3.5, range = 12.1, dur = 1.6, hold = true, ramp = { 0.15, 0.45 }, flicker = 0.15, soft = true, color = { { 0, "hot" }, { 1, "mid" } } }),
			-- tail: the fountain sinks to its base (settle) and a bed of low flames outlasts it; coals cool on the floor and the
			-- hot spot dies after the fire, so it ends in steps (everything gone in one tenth of a second read as a cut)
			L.flames({ name = "Dying", from = 0.9, to = 1.95, rate = 22, disc = { 2.4, 1 }, up = 0.3, speed = { 3, 8 }, life = { 0.3, 0.45 }, emission = 1, size = { { 0, 1.1, 0.2 }, { 1, 2, 0.3 } }, settle = 0.5, ramp = { 0.2, 0.45 } }),
			L.smoke({ kind = "stream", name = "Plume", from = 0.6, to = 2.5, rate = 6, up = 2, disc = { 2.5, 1 }, speed = { 6, 11 }, spread = 14, life = { 0.7, 1.3 }, size = { { 0, 2, 0.4 }, { 1, 5, 0.8 } }, alpha = { { 0, 1 }, { 0.15, 0.5 }, { 1, 1 } }, settle = 0.45, ramp = { 0.15, 0.5 } }),
			-- coals lying level: wider than tall (negative squash), unturned; round they read as beads, turned at random as petals
			L.embers({ kind = "stream", name = "Coals", from = 0.5, to = 1.8, rate = 22, slot = "glow", along = false, squash = { { 0, -0.6 }, { 1, -0.4 } }, rotation = 0, up = 0.2, disc = { 3.2, 1 }, life = { 1.2, 2.0 }, speed = { 0.05, 0.1 }, spread = 0, drag = 0, accel = { 0, 0, 0 }, size = { { 0, 0.26, 0.08 }, { 0.7, 0.2 }, { 1, 0.1 } }, alpha = { { 0, 0.15 }, { 0.75, 0.35 }, { 1, 1 } }, color = { { 0, "mid" }, { 0.45, "deep" }, { 1, "deep" } }, brightness = 2, z = 0.3 }),
			-- embers as small round dots: streaks rising slowly read as sticks standing on the floor
			L.embers({ from = 0.5, to = 1.85, rate = 70, slot = "glow", along = false, squash = false, rotation = 0, disc = { 5, 1 }, up = 0.5, speed = { 8, 18 }, spread = 25, size = { { 0, 0.2, 0.06 }, { 1, 0.05 } }, color = { { 0, "hot" }, { 1, "mid" } }, brightness = 3 }),
		},
	},

	-- Moving things: play them with opts.follow, or through FxRecipe.travel. "end" streams run until opts.emitUntil
	-- at full rate (ramp out 0: the impact covers the cut). Sizes are for a projectile of 1-2 studs at scale 1. -----
	-- a glint: one four-point star that opens, turns a little and closes (a sparkle on a reward, a star in the dark)
	star_glint = {
		palette = "holy",
		anchor = "up",
		duration = 0.9,
		layers = {
			L.star({ dur = 0.7, spin = 40, open = 0.25, close = 0.55 }),
			L.star({ name = "Cross", turn = 45, len = 1.1, w = 0.2, dur = 0.5, at = 0.05, long = { 1 } }),
			L.flash({ size = { { 0, 0.6 }, { 0.25, 1.4 }, { 1, 0.9 } } }),
			L.light({ peak = 2, range = 8, dur = 0.5 }),
		},
	},
	-- a burst of pointed shards with a star at its heart and one ring (a reveal's beat, an unlock, a crystal breaking)
	shard_burst = {
		palette = "ice",
		anchor = "up",
		duration = 1.1,
		layers = {
			L.flash({ size = { { 0, 1.5 }, { 0.25, 3.4 }, { 1, 2.2 } } }),
			L.star({ len = 4.2, w = 0.5, dur = 0.45, open = 0.18, close = 0.4 }),
			L.shards({ at = 0.03 }),
			L.shards({ name = "Shards2", at = 0.1, arms = 9, len = 1.1, w = 0.26, fly = 2.4, dur = 0.55, turn = 20, color = { "hot", "mid" } }),
			L.ring({ at = 0.04, r0 = 0.6, r1 = 5.2, w0 = 0.5, w1 = 0.05, dur = 0.4, twin = false }),
			L.pops({ at = 0.12, count = 10, speed = { 4, 10 }, spread = 180, life = { 0.3, 0.45 } }),
			L.light({ peak = 3.5, range = 14, dur = 0.35 }),
		},
	},
	-- the big star of a reveal: long thin cross rays, a second star turned 45 degrees, two rings, held for a second
	reveal_star = {
		palette = "gold",
		anchor = "up",
		duration = 2.2,
		layers = {
			L.flash({ size = { { 0, 2 }, { 0.25, 5 }, { 1, 3 } } }),
			L.star({ len = 14, w = 0.7, dur = 1.8, long = { 1, 0.55 }, open = 0.12, close = 0.75, spin = 6 }),
			L.star({ name = "Cross", turn = 45, len = 5, w = 0.5, dur = 1.6, long = { 1 }, open = 0.15, close = 0.7, spin = 6, color = { "white", "mid" } }),
			L.shards({ at = 0.02, arms = 16, len = 2.2, fly = 2, dur = 0.6 }),
			L.ring({ at = 0.03, r0 = 1, r1 = 9, w0 = 0.6, w1 = 0.08, dur = 0.6, twin = false }),
			L.ring({ name = "Ring2", at = 0.18, r0 = 1, r1 = 13, w0 = 0.35, w1 = 0.05, dur = 0.8, twin = false }),
			L.pops({ at = 0.2, count = 14, speed = { 5, 12 }, spread = 180, life = { 0.4, 0.6 } }),
			L.light({ peak = 4, range = 22, dur = 1.6, hold = true }),
		},
	},
	-- a ribbon with a star at its head: follows a moving part (opts.follow = true), tapers to nothing behind it
	trail_star = {
		palette = "holy",
		anchor = "trail",
		duration = 3,
		layers = {
			L.tail({ name = "Glow", w = 1.3, life = 0.5, alpha = 0.55, color = { "hot", "mid" }, z = 0.2 }),
			L.tail(),
			{ kind = "spikes", name = "Head", at = 0, dur = "end", arms = 4, long = { 1, 0.5 }, turn = 90, spin = 120, len = 2, w = 0.3, open = 0.03, close = 0.97, color = { "white", "hot" }, emission = 1, brightness = 4, z = 0.9 },
			L.embers({ from = 0, to = "end", rate = 14, slot = "glow", along = false, squash = false, rotation = 0, speed = { 0.5, 2 }, accel = { 0, 0, 0 }, life = { 0.3, 0.5 }, size = { { 0, 0.22, 0.06 }, { 1, 0 } } }),
			L.light({ dur = "end", peak = 1.5, range = 7, hold = true }),
		},
	},
	-- a fire trail: a haze round the head, an orange glow drawn over the front half of the body and a hot one on its
	-- leading edge (locked, z above the body's radius; the haze and the front glow shrink near a surface, so the floor
	-- never cuts them; no white point: a dot, flame cards or a light there all read as pasted on), a tail in len layers
	-- like a flame (a narrow core white only at its start, a band of fire cards, a wide glow laid per stud about 8 deep
	-- that cools from orange to deep red, red billows of smoke texture over its back; one comet tail at any speed; on
	-- arrival the fire goes out from the tip toward the impact, `cut`), sparks thrown back that shrink out, embers that
	-- fall away behind (per stud, so they thicken into an impact), smoke that carries on past the red tip and stays as a
	-- column, a light ahead of the body that lights the floor fire-orange before the impact
	trail = {
		palette = "fire",
		anchor = "trail",
		duration = 1.5,
		layers = {
			L.body({ kind = "stream", name = "Haze", from = 0, to = "end", rate = 24, ramp = { 0.05, 0 }, where = "hit", locked = true, clear = true, life = { 0.14, 0.18 }, size = { { 0, 3.6, 0.2 }, { 1, 3 } }, alpha = { { 0, 1 }, { 0.3, 0.72 }, { 1, 1 } }, color = "mid", emission = 1, brightness = 1.3, z = 0 }),
			L.body({ kind = "stream", name = "Halo", from = 0, to = "end", rate = 40, ramp = { 0.05, 0 }, where = "hit", up = -0.3, locked = true, clear = true, life = { 0.12, 0.16 }, size = { { 0, 1.6, 0.15 }, { 1, 1.45 } }, alpha = { { 0, 1 }, { 0.25, 0.8 }, { 1, 1 } }, color = "mid", emission = 1, brightness = 1.2, z = 1.2 }),
			L.body({ kind = "stream", name = "Bow", from = 0, to = "end", rate = 40, ramp = { 0.05, 0 }, where = "hit", up = -0.85, locked = true, life = { 0.08, 0.12 }, size = { { 0, 0.55, 0.06 }, { 1, 0.46 } }, alpha = { { 0, 1 }, { 0.2, 0.45 }, { 1, 1 } }, color = { { 0, "hot" }, { 1, "mid" } }, emission = 1, brightness = 1.4, z = 1.3 }),
			L.body({ kind = "stream", name = "Core", from = 0, to = "end", rate = 0, density = 4, ramp = { 0.05, 0 }, path = 0.2, where = "hit", up = 0.3, len = 3.5, cut = 0.15, life = { 0.06, 0.3 }, size = { { 0, 0.75, 0.05 }, { 0.5, 0.55 }, { 1, 0.2 } }, alpha = { { 0, 0.35 }, { 0.5, 0.5 }, { 1, 1 } }, color = { { 0, "white" }, { 0.2, "hot" }, { 1, "hot" } }, emission = 1, brightness = 1.2, z = 0 }),
			L.body({ kind = "stream", name = "Tail", from = 0, to = "end", rate = 0, density = 4, ramp = { 0.05, 0 }, path = 0.3, where = "hit", len = 20, cut = 0.3, life = { 0.3, 1.0 }, speed = { 0, 0.2 }, spread = 180, size = { { 0, 2.2, 0.25 }, { 0.35, 1.55 }, { 0.6, 1.05 }, { 0.8, 0.7 }, { 1, 0.3 } }, alpha = { { 0, 0.8, 0.05 }, { 0.35, 0.7, 0.05 }, { 0.55, 0.68 }, { 0.75, 0.74 }, { 0.88, 0.86 }, { 1, 1 } }, color = { { 0, "mid" }, { 0.25, "mid" }, { 0.5, "deep" }, { 1, "deep" } }, emission = 1, brightness = 0.9, z = 0.2 }),
			L.body({ kind = "stream", name = "Billow", slot = "smoke", from = 0, to = "end", rate = 0, density = 2, ramp = { 0.05, 0 }, path = 0.3, where = "hit", len = 20, cut = 0.4, life = { 0.3, 1.0 }, speed = { 0, 0.3 }, spread = 180, rotSpeed = { -40, 40 }, size = { { 0, 1.2, 0.2 }, { 0.4, 1.2, 0.2 }, { 0.7, 0.9 }, { 1, 0.4 } }, alpha = { { 0, 1 }, { 0.35, 1 }, { 0.45, 0.55, 0.05 }, { 0.8, 0.65 }, { 1, 1 } }, color = "deep", emission = 1, brightness = 0.9, z = 0.25 }),
			L.fireball({ kind = "stream", name = "Flames", from = 0, to = "end", rate = 0, density = 2, ramp = { 0.05, 0 }, path = 0.3, len = 6, cut = 0.2, life = { 0.2, 0.6 }, speed = { 0.5, 2 }, spread = 180, drag = 2, rotSpeed = { -90, 90 }, size = { { 0, 1.1, 0.3 }, { 0.5, 1.2, 0.3 }, { 1, 0.6 } }, alpha = { { 0, 0.35, 0.1 }, { 0.5, 0.45, 0.1 }, { 1, 1 } }, color = { { 0, "hot" }, { 0.55, "hot" }, { 1, "mid" } }, emission = 1, brightness = 0.6, z = 0.35 }),
			L.sparks({ kind = "stream", name = "Sparks", from = 0, to = "end", rate = 10, density = 3, ramp = { 0.05, 0 }, path = 0.5, life = { 0.2, 0.35 }, speed = { 6, 14 }, spread = 30, drag = 1, accel = { 0, -6, 0 }, size = { { 0, 0.35, 0.1 }, { 1, 0 } }, alpha = { { 0, 1 }, { 0.1, 1 }, { 0.14, 0 }, { 1, 0 } }, color = { { 0, "white" }, { 0.3, "hot" }, { 1, "hot" } }, emission = 1, brightness = 3 }),
			L.wisps({ name = "Embers", from = 0, to = "end", rate = 20, density = 2.5, ramp = { 0.05, 0 }, path = 0.8, up = 0, disc = false, life = { 0.5, 0.9 }, speed = { 5, 12 }, spread = 180, drag = 1.5, accel = { 0, -8, 0 }, size = { { 0, 0.2, 0.05 }, { 1, 0 } }, color = { { 0, "hot" }, { 1, "mid" } }, alpha = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } }, emission = 1, brightness = 3 }),
			L.smoke({ kind = "stream", name = "Smoke", from = 0, to = "end", rate = 0, density = 1.2, ramp = { 0.05, 0 }, path = 0.6, up = 1.2, len = 34, life = { 0.6, 2.0 }, speed = { 0.5, 1.5 }, spread = 30, drag = 2, accel = { 0, 0.5, 0 }, size = { { 0, 1, 0.2 }, { 1, 3, 0.4 } }, alpha = { { 0, 1 }, { 0.25, 1 }, { 0.4, 0.45 }, { 0.8, 0.6 }, { 1, 1 } }, color = "smoke1", z = 0 }),
			L.light({ at = 0, up = -1.6, dur = "end", peak = 3, range = 9, hold = true, ramp = { 0.05, 0 }, clear = true, color = "mid" }),
		},
	},
	-- an energy trail (a bolt, a magic missile): a white-hot core, a saturated glow around it, sparks and glints;
	-- no fire and no smoke. Change the colour with opts.palette.
	trail_glow = {
		palette = "electric",
		anchor = "trail",
		duration = 1.5,
		layers = {
			L.body({ kind = "stream", name = "Core", from = 0, to = "end", rate = 20, density = 3, ramp = { 0.05, 0 }, path = 0.3, where = "hit", life = { 0.06, 0.1 }, size = { { 0, 1.0, 0.15 }, { 1, 0.3 } }, alpha = { { 0, 0.1 }, { 1, 1 } }, color = { { 0, "white" }, { 0.2, "hot" }, { 1, "mid" } }, emission = 1, brightness = 3, z = 0.5 }),
			L.body({ kind = "stream", name = "Glow", from = 0, to = "end", rate = 10, density = 2.5, ramp = { 0.05, 0 }, path = 0.6, where = "hit", life = { 0.1, 0.16 }, size = { { 0, 1.5, 0.2 }, { 1, 0.5 } }, alpha = { { 0, 0.5 }, { 1, 1 } } }),
			L.sparks({ kind = "stream", name = "Sparks", from = 0, to = "end", rate = 24, density = 0.1, ramp = { 0.05, 0 }, path = 0.4, life = { 0.1, 0.2 }, speed = { 6, 14 }, spread = 90, drag = 5, accel = { 0, 0, 0 }, size = { { 0, 0.4, 0.08 }, { 1, 0.1 } }, color = { { 0, "hot" }, { 1, "mid" } } }),
			L.pops({ kind = "stream", name = "Glints", from = 0, to = "end", rate = 10, ramp = { 0.05, 0 }, path = 1, speed = { 1, 3 }, spread = 90, life = { 0.18, 0.28 }, size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } } }),
			L.light({ at = 0, dur = "end", peak = 2.5, range = 12, hold = true, ramp = { 0.05, 0 } }),
		},
	},
	-- a tell on the floor where something will land, for the flight time (opts.emitUntil): broken arcs that close on
	-- the point and are gone at the impact (a clean ring read as a UI ring), a mark that flickers and builds, heat
	-- spots, round motes rising from the rim (streaks rising slowly read as sticks), a light that grows. The impact
	-- itself is another recipe.
	tell = {
		palette = "fire",
		anchor = "feet",
		duration = 1.3,
		layers = {
			L.floorRing({ name = "Closing", at = 0, dur = "end", r0 = 6, r1 = 0.6, w0 = 0.22, w1 = 0.5, segments = 24, ease = "in", alpha = { { 0, 1 }, { 0.12, 0.15 }, { 1, 0 } }, color = { "hot", "mid" }, arcs = 4 }),
			L.floorGlow({ kind = "stream", name = "Mark", from = 0, to = "end", rate = 14, grow = true, life = { 0.2, 0.3 }, size = { { 0, 3.5 }, { 1, 4.2 } }, alpha = { { 0, 1 }, { 0.3, 0.5 }, { 1, 1 } } }),
			L.floorGlow({ kind = "stream", name = "Heat", from = 0, to = "end", rate = 18, grow = true, disc = { 3, 1 }, life = { 0.15, 0.25 }, size = { { 0, 0.6 }, { 1, 1.6 } }, color = "hot", alpha = { { 0, 1 }, { 0.4, 0.3 }, { 1, 1 } } }),
			L.motes({ name = "RimMotes", from = 0, to = "end", rate = 40, grow = true, disc = { 5, 0 }, speed = { 6, 12 }, slot = "glow", along = false, squash = false, rotation = 0, size = { { 0, 0.2, 0.06 }, { 1, 0.05 } } }),
			L.light({ at = 0, up = 1, dur = "end", peak = 3, range = 16, grow = true }),
		},
	},
}

local function key(pal, k)
	local c = pal[k]
	if not c and k == "deep" and pal.mid and pal.dark then
		c = pal.mid:Lerp(pal.dark, 0.4) -- a palette made before `deep` existed
	end
	if not c then
		error(`fx_recipe: palette has no key "{k}"`, 3)
	end
	return c
end

-- a palette key, or a ramp {{u, key}, ...} read at u
local function keyAt(pal, c, u)
	if type(c) == "string" then
		return key(pal, c)
	end
	for i = 2, #c do
		local a, b = c[i - 1], c[i]
		if u <= b[1] then
			return key(pal, a[2]):Lerp(key(pal, b[2]), math.clamp((u - a[1]) / math.max(b[1] - a[1], 1e-6), 0, 1))
		end
	end
	return key(pal, c[#c][2])
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

-- half the widest size a layer reaches (with its random envelope), at scale 1
local function halfOf(points)
	local w = 0
	for _, p in points do
		w = math.max(w, p[2] + (p[3] or 0))
	end
	return w / 2
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
		Lifetime = if l.len then NumberRange.new(l.life[2] * 0.85, l.life[2]) else NumberRange.new(l.life[1], l.life[2]),
		Size = sized(l.size, s),
		Transparency = FxClock.ns(l.alpha),
		Color = colorOf(pal, l.color),
		LightEmission = l.emission or 1,
		Brightness = l.brightness or 1,
		ZOffset = (l.z or 0) * s,
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
		-- a number, or {min, max} for a random turn per piece
		props.Rotation = if type(l.rotation) == "table" then NumberRange.new(l.rotation[1], l.rotation[2]) else NumberRange.new(l.rotation)
	end
	if l.rotSpeed then
		props.RotSpeed = NumberRange.new(l.rotSpeed[1], l.rotSpeed[2])
	end
	if l.along then
		props.Orientation = Enum.ParticleOrientation.VelocityParallel
	end
	if l.locked then
		props.LockedToPart = true
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
	if l.gather then
		props.Shape = Enum.ParticleEmitterShape.Sphere
		props.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		props.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	end
	if l.dir == "down" then
		props.EmissionDirection = Enum.NormalId.Bottom
	end
	if l.path then
		props.Shape = Enum.ParticleEmitterShape.Box
		props.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end
	if l.flat then
		-- a particle is drawn across its velocity: a tiny upward speed lays it on the floor
		props.EmissionDirection = Enum.NormalId.Top
		props.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		props.Speed = NumberRange.new(0.01)
		props.Rotation = if type(l.rotation) == "table" then NumberRange.new(l.rotation[1], l.rotation[2]) else NumberRange.new(l.rotation or 0)
	end
	return props
end

-- The frame of a target: a CFrame, a Vector3, an attachment, a part or a model (its pivot).
local function frameOf(target)
	if typeof(target) == "CFrame" then
		return target
	elseif typeof(target) == "Vector3" then
		return CFrame.new(target)
	elseif target:IsA("Attachment") then
		return target.WorldCFrame
	elseif target:IsA("BasePart") then
		return target.CFrame
	end
	return target:GetPivot()
end

-- p (the anchor point), d (the direction the hit travels) and the instance the effect is on
local function resolve(target, opts)
	if typeof(target) == "CFrame" then
		return target.Position, target.LookVector, nil
	end
	local root = target:FindFirstChild("HumanoidRootPart")
	if not root then
		-- a part, an attachment or a model without a humanoid: its own frame, hit from the front
		local cf = frameOf(target)
		return cf.Position, (opts.direction or -cf.LookVector).Unit, target
	end
	local torso = target:FindFirstChild("UpperTorso") or root
	local d = (opts.direction or -root.CFrame.LookVector).Unit
	return torso.Position - d * 0.6, d, target
end

local function recipeOf(recipe)
	if type(recipe) == "string" then
		return FxRecipe.recipes[recipe] or error(`fx_recipe: no recipe "{recipe}"`, 3)
	end
	return recipe
end

-- a unit vector at right angles to v
local function across(v)
	return (if math.abs(v.Y) < 0.9 then v:Cross(Vector3.yAxis) else v:Cross(Vector3.xAxis)).Unit
end

-- the box a path layer emits from: it spans a -> b plus `width` each way, its Y axis is `up` (the emission direction)
local function pathBox(part, a, b, up, side, width)
	local m = b - a
	local along = m:Dot(up)
	local perp = m - up * along
	local x = if perp.Magnitude > 1e-3 then perp.Unit else side
	part.Size = Vector3.new(perp.Magnitude + width, math.abs(along) + width, width)
	part.CFrame = CFrame.fromMatrix((a + b) / 2, x, up)
end

-- a piecewise-linear curve {{u, v}, ...} read at u
local function curve(points, u)
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		if u <= b[1] then
			return FxClock.lerp(a[2], b[2], math.clamp((u - a[1]) / math.max(b[1] - a[1], 1e-6), 0, 1))
		end
	end
	return points[#points][2]
end

-- how far a stream's rate or a held light is open at u: in over ramp[1] of its span, out over ramp[2]
local function rampAt(ramp, u, out)
	local r0 = if ramp then ramp[1] else 0.15
	local r1 = if ramp then ramp[2] else out
	local k = if r0 > 0 then FxClock.smooth(0, r0, u) else 1
	if r1 > 0 then
		k *= 1 - FxClock.smooth(1 - r1, 1, u)
	end
	return k
end

function FxRecipe.play(recipe, target, opts)
	opts = opts or {}
	recipe = recipeOf(recipe)
	local pal = opts.palette or recipe.palette
	if type(pal) == "string" then
		pal = FxRecipe.palettes[pal] or error(`fx_recipe: no palette "{pal}"`, 2)
	end
	local s = opts.scale or 1
	local p, d, model = resolve(target, opts)
	local anchor = recipe.anchor or "hit"
	local duration = opts.duration or recipe.duration
	-- "end" streams stop at stopAt; "end" rings, columns, helices and lights end at endAt
	local stopAt = opts.emitUntil or duration - 0.35
	local endAt = opts.emitUntil or duration - 0.1
	local clock = FxClock.new(recipe.name or "FxRecipe", duration)
	local smooth, lerp = FxClock.smooth, FxClock.lerp
	local spray = -d
	if anchor == "trail" then
		-- back along the motion; a CFrame, part or model moves along its LookVector unless opts.direction says
		spray = -(opts.direction or frameOf(target).LookVector).Unit
	elseif anchor ~= "hit" then
		spray = Vector3.yAxis
		if anchor == "feet" and model and model:IsA("Model") then
			local cf, size = model:GetBoundingBox()
			p = cf.Position - Vector3.new(0, size.Y / 2, 0)
		elseif anchor == "feet" and model and model:IsA("BasePart") then
			p = model.Position - Vector3.new(0, model.Size.Y / 2, 0)
		elseif model then
			p = frameOf(model).Position
		end
	end
	local side = across(spray)
	local frame0 = CFrame.fromMatrix(p, side, spray)

	-- follow: the effect moves with its target (opts.follow = true) or along opts.follow(t) (clock time -> Vector3 or
	-- CFrame). Emitter parents move with it, rings, columns, helices and lights by the same shift; with anchor
	-- "trail" the parents also turn so spray keeps pointing back along the motion.
	local follow = opts.follow
	if follow == true and typeof(target) == "CFrame" then
		error("fx_recipe: follow = true needs a part, an attachment or a model", 2)
	end
	local function track(t)
		if type(follow) == "function" then
			local v = follow(t)
			return if typeof(v) == "CFrame" then v.Position else v
		end
		return if target.Parent then frameOf(target).Position else nil
	end
	local track0 = if follow then track(0) else nil
	local shift = Vector3.zero
	local movers = {}
	local syncedAt = nil
	local speed = 0 -- studs per clock second, for density streams
	local accel = 0 -- studs per clock second squared, smoothed, for len tails
	-- clear layers: room is the distance from the anchor to the nearest surface below or ahead, up to reach
	local reach = 0
	for _, l in recipe.layers do
		if l.clear then
			-- a light needs room for its lead ahead of the anchor and for its fade
			reach = math.max(reach, if l.kind == "light" then math.max(-(l.up or 0), 0) * s + l.range * math.sqrt(s) * 0.5 else halfOf(l.size) * s)
		end
	end
	local rays = if reach > 0 and follow then RaycastParams.new() else nil
	if rays then
		local skip = opts.ignore or (if typeof(target) == "Instance" then target else nil)
		rays.FilterDescendantsInstances = if skip then { skip } else {}
	end
	local room = math.huge
	local function sync(t)
		if not follow or t == syncedAt then
			return
		end
		local pos = track(t)
		if not pos then
			syncedAt, speed = t, 0
			return -- the target is gone: the effect stays where it was
		end
		local moved = pos - track0 - shift
		if syncedAt and t > syncedAt then
			local v = moved.Magnitude / (t - syncedAt)
			if speed > 0 then
				accel += ((v - speed) / (t - syncedAt) - accel) * 0.3
			end
			speed = v
		end
		syncedAt = t
		shift = pos - track0
		if anchor == "trail" and moved.Magnitude > 1e-3 then
			spray = -moved.Unit
			side = across(spray)
		end
		if rays then
			local here = p + shift
			room = reach
			local down = workspace:Raycast(here, Vector3.new(0, -reach, 0), rays)
			if down then
				room = here.Y - down.Position.Y
			end
			local ahead = workspace:Raycast(here, -spray * reach, rays)
			if ahead then
				room = math.min(room, (here - ahead.Position):Dot(ahead.Normal))
			end
		end
		local frame = CFrame.fromMatrix(p + shift, side, spray)
		for _, m in movers do
			local cf = frame * m.rel
			if m.path then
				pathBox(m.inst, m.last or cf.Position, cf.Position, spray, side, m.path)
				m.last = cf.Position
			elseif m.inst:IsA("Attachment") then
				m.inst.WorldCFrame = cf
			else
				m.inst.CFrame = cf
			end
		end
	end
	local function moves(inst, path)
		if follow then
			local cf = if inst:IsA("Attachment") then inst.WorldCFrame else inst.CFrame
			table.insert(movers, { inst = inst, rel = frame0:ToObjectSpace(cf), path = path })
		end
		return inst
	end
	if follow then
		-- the first span, so it runs before every layer's span and stream in a step (bursts call sync themselves)
		clock:span(0, duration, function(_, t)
			sync(t)
		end)
	end

	local atts = {
		hit = moves(clock:attachment(frame0)),
		front = moves(clock:attachment(CFrame.new(p + spray * 0.4 * s))),
	}

	-- times / every: a burst reuses its emitter; every other kind is played as copies shifted in time
	local function repeats(l)
		if not l.times then
			return 1
		end
		if l.times == "end" then
			return math.max(1, math.floor((stopAt - (l.at or l.from or 0)) / l.every))
		end
		return l.times
	end
	local layers = {}
	for _, l in recipe.layers do
		table.insert(layers, l)
		if l.kind ~= "burst" then
			for i = 1, repeats(l) - 1 do
				local c = table.clone(l)
				c.times = nil
				if c.at then
					c.at += i * l.every
				end
				if c.from then
					c.from += i * l.every
					if type(c.to) == "number" then
						c.to += i * l.every
					end
				end
				table.insert(layers, c)
			end
		end
	end

	for _, l in layers do
		if l.kind == "burst" or l.kind == "stream" then
			local parent = atts[l.where or "hit"]
			local at = parent.WorldPosition + spray * (l.up or 0) * s
			if l.path then
				-- emitted over the distance the anchor moved this step, so a fast trail has no gaps between frames
				local w = l.path * s
				parent = moves(clock:part({ Size = Vector3.new(w, w, w), CFrame = CFrame.fromMatrix(at, side, spray) }), w)
			elseif l.tube then
				local r, h = l.tube[1] * s, l.tube[2] * s
				parent = moves(clock:part({ Size = Vector3.new(r * 2, h, r * 2), CFrame = CFrame.new(at + Vector3.yAxis * h / 2) }))
			elseif l.gather then
				local r = l.gather * s
				parent = moves(clock:part({ Size = Vector3.new(r * 2, r * 2, r * 2), CFrame = CFrame.new(at) }))
			elseif l.disc then
				local r = l.disc[1] * s
				parent = moves(clock:part({ Size = Vector3.new(r * 2, 0.2, r * 2), CFrame = CFrame.fromMatrix(at, side, spray) }))
			elseif l.up then
				parent = moves(clock:attachment(CFrame.fromMatrix(at, side, spray)))
			end
			local e = clock:emitter(parent, emitterProps(l, pal, s))
			local lead = FxTextures.apply(e, l.slot).lead
			local function setAlpha(seq)
				e.Transparency = if lead then FxTextures.hideLead(seq, lead) else seq
			end
			setAlpha(e.Transparency)
			if l.kind == "burst" then
				for i = 0, repeats(l) - 1 do
					clock:at(l.at + i * (l.every or 0), function()
						sync(clock.t)
						e:Emit(l.count)
					end)
				end
			else
				-- the rate ramps in and out (ramp {in, out}: shares of the span, default 0.15 each), so the stream has no
				-- seam; grow: it builds toward its end and stops there at full rate (a tell, a charge). density: more
				-- per stud the anchor moved (while following), so a trail is as full at any speed
				local to = if l.to == "end" then stopAt else l.to
				local tailLen = if l.len then l.len * s * (opts.tail or 1) else nil
				local half = if l.clear and rays then halfOf(l.size) * s else nil
				local fit = 1
				clock:stream(e, l.from, to, function(t)
					local u = (t - l.from) / (to - l.from)
					if half then
						-- clear: every live piece shrinks with the room left (an emitter's Size applies to them all)
						local k = math.floor(math.clamp(room / half, 0, 1) * 50 + 0.5) / 50
						if k ~= fit then
							fit = k
							e.Size = sized(l.size, s * k)
						end
					end
					if tailLen then
						-- len: a tail measured in studs, so its shape holds at any speed: each piece lives as long as the
						-- anchor takes to move that far at its current speed and acceleration (within life), and no longer
						-- than the stream has run, so a tail that is still growing ends in a faded point, not a round cap
						-- where it started. With the speed alone, the pieces born while a fall was still slow outlived its
						-- tail and bunched into a round bulb at the tip
						local disc = speed * speed + 2 * accel * tailLen
						local byLen = if disc > 0 and speed + math.sqrt(disc) > 0 then 2 * tailLen / (speed + math.sqrt(disc)) else math.huge
						local life = math.clamp(math.min(byLen, t - l.from + l.life[1]), l.life[1], l.life[2])
						e.Lifetime = NumberRange.new(life * 0.85, life)
					end
					if l.settle then
						-- settle: new pieces leave slower toward the end of the span (down to this share of their speed), so
						-- a fountain sinks to its base as it dies instead of leaving its last pieces floating high
						local k = 1 - (1 - l.settle) * smooth(0.3, 1, u)
						e.Speed = NumberRange.new(l.speed[1] * s * k, l.speed[2] * s * k)
					end
					local rate = (l.rate or 0) + (l.density or 0) * speed / s
					if l.grow then
						return rate * rampAt(l.ramp, u, 0) * (0.2 + 0.8 * u * u)
					end
					return rate * rampAt(l.ramp, u, 0.15)
				end)
				if l.cut and l.to == "end" and opts.emitUntil then
					-- cut (s): when the stream stops at opts.emitUntil (a trail on arrival), its live pieces go out from
					-- the far end toward the anchor in that time (the alpha curve is squeezed toward birth), so the tail
					-- does not hang in the air after the impact
					clock:span(to, to + l.cut, function(u)
						local k = 1 - u
						if k <= 0.001 then
							e.Transparency = NumberSequence.new(1)
							return
						end
						local pts = {}
						for _, q in l.alpha do
							table.insert(pts, { q[1] * k, q[2], q[3] })
						end
						if k < 0.999 then
							table.insert(pts, { 1, 1 })
						end
						setAlpha(FxClock.ns(pts))
					end)
				end
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
				return { cf = CFrame.fromMatrix(p + shift + n * y + radial * r, tan, radial), width = w, alpha = a, color = col }
			end
			local c0, c1, dark = key(pal, l.color[1]), key(pal, l.color[2]), key(pal, "dark")
			local r0, r1, w0, w1 = l.r0 * s, l.r1 * s, l.w0 * s, l.w1 * s
			if l.arcs then
				-- arcs: broken arcs instead of a clean circle, each with its own start, length (0.55-1.15 of its share of
				-- the turn), radius (0.95-1.05), life (0.65-1) and turn (up to 0.8 rad/s), pointed ends and the soft band
				-- texture across its width; no twin
				local rng = Random.new()
				local share = math.pi * 2 / l.arcs
				local per = math.max(3, math.ceil(segs / l.arcs * 1.15))
				local dur = if l.dur == "end" then endAt - l.at else l.dur
				local ease = if l.ease == "in" then function(u) return u * u end elseif l.ease == "linear" then function(u) return u end else FxClock.outQuart
				for k = 1, l.arcs do
					local start = (k - 1 + rng:NextNumber(-0.3, 0.3)) * share
					local len = share * rng:NextNumber(0.55, 1.15)
					-- "end" arcs (a tell) all last until the arrival, which covers their cut
					local rk, turn = rng:NextNumber(0.95, 1.05), rng:NextNumber(-0.8, 0.8)
					local life = if l.dur == "end" then dur else dur * rng:NextNumber(0.65, 1)
					local arc = clock:ribbon(per, { LightEmission = l.emission or 0.8, Brightness = l.brightness or 2.5, ZOffset = (l.z or 0.5) * s, TextureMode = Enum.TextureMode.Wrap, TextureLength = 0.07 })
					for _, b in arc.beams do
						FxTextures.apply(b, "band")
					end
					clock:span(l.at, l.at + life, function(u)
						local e = ease(u)
						local r, w = lerp(r0, r1, e) * rk, lerp(w0, w1, e)
						local col, y = c0:Lerp(c1, smooth(0, 0.25, u)), lerp(y0, y1, u)
						local a = if l.alpha then curve(l.alpha, u) else smooth(0.35, 1, u)
						local from = start + turn * u * life
						arc.update(function(j)
							local v = (j - 1) / per
							local ang = from + v * len
							local radial = b1 * math.cos(ang) + b2 * math.sin(ang)
							local tan = -b1 * math.sin(ang) + b2 * math.cos(ang)
							return { cf = CFrame.fromMatrix(p + shift + n * y + radial * r, tan, radial), width = w * math.sin(math.pi * v) ^ 0.6, alpha = a, color = col }
						end)
						if u >= 1 then
							arc.hide()
						end
					end)
				end
				continue
			end
			local ring = clock:ribbon(segs, { LightEmission = l.emission or 0.8, Brightness = l.brightness or 2.5, ZOffset = (l.z or 0.5) * s })
			local twin = l.twin and clock:ribbon(segs, { LightEmission = 0, Brightness = 1, ZOffset = -0.3 * s })
			local dur = if l.dur == "end" then endAt - l.at else l.dur
			-- ease: "out" (default) fast then slow, "in" slow then fast (closes on a beat), "linear"
			local ease = if l.ease == "in" then function(u) return u * u end elseif l.ease == "linear" then function(u) return u end else FxClock.outQuart
			clock:span(l.at, l.at + dur, function(u)
				local e = ease(u)
				local col = c0:Lerp(c1, smooth(0, 0.25, u))
				local y = lerp(y0, y1, u)
				ring.update(function(j)
					return joint(j, lerp(r0, r1, e), lerp(w0, w1, e), if l.alpha then curve(l.alpha, u) else smooth(0.35, 1, u), col, y)
				end)
				if twin then
					local u2 = math.max(u - 0.08, 0)
					local e2 = ease(u2)
					local a2 = if l.alpha then curve(l.alpha, u2) else smooth(0.3, 1, u2)
					twin.update(function(j)
						return joint(j, lerp(r0, r1 * 0.92, e2), lerp(w0 * 1.6, w1 * 1.67, e2), 0.5 + 0.5 * a2, dark, lerp(y0, y1, u2))
					end)
				end
				if u >= 1 then
					ring.hide()
					if twin then
						twin.hide()
					end
				end
			end)
		elseif l.kind == "column" then
			local a0 = clock:attachment(CFrame.new(p + Vector3.yAxis * (l.y0 or 0) * s))
			local a1 = clock:attachment(CFrame.new(p + Vector3.yAxis * l.y1 * s))
			local slot = l.slot or "band"
			local beam = clock:beam(a0, a1, {
				FaceCamera = true,
				Segments = 1,
				LightEmission = l.emission or 1,
				Brightness = l.brightness or 3,
				ZOffset = (l.z or 0.2) * s,
				TextureMode = Enum.TextureMode.Wrap,
				TextureLength = l.length or (if slot == "band" then 0.07 else 16 * s),
				TextureSpeed = l.speed or 0,
				Enabled = false,
			})
			FxTextures.apply(beam, slot)
			local c0, c1 = key(pal, l.color[1]), key(pal, l.color[2])
			local w0, w1, base = l.w0 * s, l.w1 * s, l.alpha or 0.15
			local dur = if l.dur == "end" then endAt - l.at else l.dur
			local bottom, top = a0.WorldPosition, a1.WorldPosition
			clock:span(l.at, l.at + dur, function(u, t)
				local w, a
				a1.WorldPosition = top + shift
				a0.WorldPosition = (if l.drop then top:Lerp(bottom, math.clamp((t - l.at) / l.drop, 0, 1)) else bottom) + shift
				if l.hold then
					-- opens in the first 12%, closes in the last 20% by narrowing, not by fading
					w, a = w1 * smooth(0, 0.12, u) * (1 - smooth(0.8, 1, u)), base
				else
					w, a = lerp(w0, w1, FxClock.outQuart(u)), base + (1 - base) * smooth(0.35, 1, u)
				end
				if l.flicker then
					w *= 1 + 2 * l.flicker * math.noise(t * 31, l.at * 7.3)
				end
				beam.Width0, beam.Width1 = w, w
				beam.Color = ColorSequence.new(c0:Lerp(c1, smooth(0, 0.3, u)))
				-- the top fades out so the beam has no cut end
				beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(0.7, a), NumberSequenceKeypoint.new(1, 1) })
				beam.Enabled = u < 1 and w > 0.01
			end)
		elseif l.kind == "helix" then
			local segs = l.segments or 24
			local c0, c1 = key(pal, l.color[1]), key(pal, l.color[2])
			local y0, y1, r, w = (l.y0 or 0) * s, l.y1 * s, l.r * s, l.w * s
			local turns, spin, phase, base = l.turns or 2, l.spin or -1.5, l.phase or 0, l.alpha or 0.15
			local ribbon = clock:ribbon(segs, { LightEmission = l.emission or 1, Brightness = l.brightness or 3, ZOffset = (l.z or 0.3) * s })
			local dur = if l.dur == "end" then endAt - l.at else l.dur
			local function point(f, turn)
				local ang = (turns * f + turn) * math.pi * 2
				local radial = Vector3.new(math.cos(ang), 0, math.sin(ang))
				return p + shift + radial * r + Vector3.yAxis * lerp(y0, y1, f), radial
			end
			clock:span(l.at, l.at + dur, function(u, t)
				-- opens and closes by width; the whole band turns about the axis, which reads as stripes that travel
				local open = smooth(0, 0.12, u) * (1 - smooth(0.8, 1, u))
				local turn = phase + spin * (t - l.at)
				local col = c0:Lerp(c1, smooth(0, 0.3, u))
				ribbon.update(function(j)
					local f = (j - 1) / segs
					local pos, radial = point(f, turn)
					local tan = (point(f + 0.01, turn) - pos).Unit
					-- the band lies on the cylinder: its width runs across the path, its face looks outward
					local across = radial:Cross(tan).Unit
					local ends = math.min(1, math.sin(math.pi * f) * 3)
					return { cf = CFrame.fromMatrix(pos, tan, across), width = w * open, alpha = 1 - (1 - base) * ends, color = col }
				end)
				if u >= 1 then
					ribbon.hide()
				end
			end)
		elseif l.kind == "spikes" then
			-- pointed rays out of one centre, each a camera-facing beam that tapers from its width to nothing, so the
			-- shape is drawn, not a texture: arms 4 with long { 1, 0.45 } is a four-point star, arms 10-16 with
			-- jitter and fly a burst of shards. It opens fast, holds and closes by shrinking, never by fading alone
			local arms = l.arms or 4
			local long = l.long or { 1 }
			local rng = Random.new(l.seed or math.floor(p.X * 7 + p.Z * 13 + (l.at or 0) * 1000) % 100000)
			local c0, c1 = key(pal, l.color[1]), key(pal, l.color[2])
			local dur = if l.dur == "end" then endAt - l.at else l.dur
			local len, w = l.len * s, (l.w or l.len * 0.12) * s
			local list = {}
			for k = 1, arms do
				local base, tip = clock:attachment(CFrame.new(p)), clock:attachment(CFrame.new(p))
				local beam = clock:beam(base, tip, {
					FaceCamera = true,
					Segments = 1,
					Width1 = 0,
					LightEmission = l.emission or 1,
					Brightness = l.brightness or 3,
					ZOffset = (l.z or 0.6) * s,
					Enabled = false,
				})
				list[k] = {
					base = base,
					tip = tip,
					beam = beam,
					ang = math.rad(l.turn or 0) + (k - 1) / arms * math.pi * 2 + rng:NextNumber(-1, 1) * math.rad(l.jitter or 0),
					len = len * long[(k - 1) % #long + 1] * (1 + rng:NextNumber(-1, 1) * (l.vary or 0)),
					wait = rng:NextNumber(0, l.stagger or 0),
				}
			end
			local openBy, closeFrom = l.open or 0.2, l.close or 0.6
			clock:span(l.at, l.at + dur, function(u, t)
				local cam = workspace.CurrentCamera
				local here = p + shift + spray * (l.up or 0) * s
				-- the plane faces the camera every frame, or lies on the floor
				local right, top = Vector3.xAxis, Vector3.zAxis
				if l.plane ~= "floor" and cam then
					right, top = cam.CFrame.RightVector, cam.CFrame.UpVector
				end
				local turn = math.rad(l.spin or 0) * (t - l.at)
				local col = c0:Lerp(c1, smooth(0, 0.5, u))
				for _, arm in list do
					local v = math.clamp((u - arm.wait) / (1 - arm.wait), 0, 1)
					local open = FxClock.outQuart(math.min(v / openBy, 1)) * (1 - smooth(closeFrom, 1, v))
					local dir = right * math.cos(arm.ang + turn) + top * math.sin(arm.ang + turn)
					-- fly: the shard leaves the centre and travels that many times its own length
					local out = arm.len * (l.fly or 0) * FxClock.outQuart(v)
					arm.base.WorldPosition = here + dir * out
					arm.tip.WorldPosition = here + dir * (out + arm.len * open)
					arm.beam.Width0 = w * (0.35 + 0.65 * open)
					arm.beam.Color = ColorSequence.new(col)
					arm.beam.Transparency = NumberSequence.new(l.alpha or 0)
					arm.beam.Enabled = u < 1 and open > 0.01
				end
			end)
		elseif l.kind == "tail" then
			-- a ribbon behind a moving anchor (opts.follow): the path it flew as a band that tapers to nothing. It runs
			-- on the effect's clock (a Trail runs in real time, so it cannot be frozen or slowed with the rest)
			local segs = l.segments or 10
			local c0, c1 = key(pal, l.color[1]), key(pal, l.color[2])
			local w, life = l.w * s, l.life or 0.4
			local ribbon = clock:ribbon(segs, { FaceCamera = true, LightEmission = l.emission or 1, Brightness = l.brightness or 3, ZOffset = (l.z or 0.4) * s })
			local hist = {} -- { clock time, position }, newest last
			local to = if l.to == "end" then stopAt else l.to
			local function posAt(time)
				for i = #hist, 2, -1 do
					local a, b = hist[i - 1], hist[i]
					if time >= a[1] then
						return a[2]:Lerp(b[2], if b[1] > a[1] then math.clamp((time - a[1]) / (b[1] - a[1]), 0, 1) else 0)
					end
				end
				return hist[1][2]
			end
			clock:span(l.at, to + life, function(_, t)
				if t <= to then
					table.insert(hist, { t, p + shift + spray * (l.up or 0) * s })
				end
				while #hist > 2 and hist[2][1] < t - life do
					table.remove(hist, 1)
				end
				local newest = if #hist > 0 then hist[#hist][1] else t
				local span = newest - math.max(if #hist > 0 then hist[1][1] else t, t - life)
				if #hist < 2 or span <= 0.01 then
					ribbon.hide()
					return
				end
				ribbon.update(function(j)
					local f = (j - 1) / segs
					local time = newest - f * span
					local pos = posAt(time)
					local back = posAt(time - span / segs) - posAt(time + span / segs)
					local tan = if back.Magnitude > 1e-4 then back.Unit else spray
					return {
						cf = CFrame.fromMatrix(pos, tan, across(tan)),
						width = w * (1 - f) ^ (l.taper or 1),
						alpha = (l.alpha or 0) + (1 - (l.alpha or 0)) * f * f,
						color = c0:Lerp(c1, f),
					}
				end)
			end)
		elseif l.kind == "mark" then
			-- an image on a thin part at the anchor, placed once at `at` (it does not follow); a SurfaceGui rather than a
			-- Decal so that glow = true can light it by itself
			local part = clock:part({ Name = l.name or "Mark", Size = Vector3.new(1, 0.05, 1), CFrame = CFrame.new(p) })
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Top
			gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			gui.CanvasSize = Vector2.new(256, 256)
			gui.LightInfluence = if l.glow then 0 else 1
			gui.Brightness = l.brightness or 1
			gui.Enabled = false
			gui.Parent = part
			local img = Instance.new("ImageLabel")
			img.Size = UDim2.fromScale(1, 1)
			img.BackgroundTransparency = 1
			img.Image = FxTextures.get(l.slot or "glow").id
			img.ImageTransparency = 1
			img.Parent = gui
			local dur = if l.dur == "end" then endAt - l.at else l.dur
			local spot = nil
			clock:span(l.at, l.at + dur, function(u, t)
				spot = spot or p + shift + Vector3.yAxis * (l.y or 0.04) * s
				local r = lerp(l.r0, l.r1, FxClock.outCubic(math.clamp((t - l.at) / math.max(l.grow or 0.1, 1e-3), 0, 1))) * s
				part.Size = Vector3.new(r * 2, 0.05, r * 2)
				part.CFrame = CFrame.new(spot)
				img.ImageColor3 = keyAt(pal, l.color, u)
				img.ImageTransparency = if u >= 1 then 1 else curve(l.alpha, u)
				gui.Enabled = u < 1
			end)
		elseif l.kind == "light" then
			local holder = if l.up then moves(clock:attachment(CFrame.new(p + spray * l.up * s))) else atts.front
			-- soft: one bright light lights a floor as a flat oval with an edge (its falloff is flat over most of its
			-- range and the centre clips), so the light is three at one point, ranges 0.4, 0.65 and 1 of range with
			-- 0.55, 0.3 and 0.15 of the brightness: the floor fades from the centre out, same peak in the middle
			local tiers = if l.soft then { { 0.4, 0.55 }, { 0.65, 0.3 }, { 1, 0.15 } } else { { 1, 1 } }
			local lights = {}
			for _, tier in tiers do
				local pl = clock:light(holder, { Range = l.range * math.sqrt(s) * tier[1], Color = keyAt(pal, l.color or "light", 0) })
				table.insert(lights, { pl, tier[2] })
			end
			local dur = if l.dur == "end" then endAt - l.at else l.dur
			-- hold: ramps in, holds and ramps out (ramp {in, out}, default 0.15 and 0.25); grow: rises to its peak at
			-- the end of its span, then goes out (a tell); shape {{u, share of peak}, ...}: any curve over the span;
			-- otherwise it starts at its peak and falls. flicker (0-0.5): the brightness jitters like a flame; a colour
			-- ramp {{u, key}, ...} is read over the span (a fire light that cools as it dies)
			local cools = type(l.color) == "table"
			clock:span(l.at, l.at + dur, function(u, t)
				local b = if u >= 1 then 0
					elseif l.shape then l.peak * curve(l.shape, u)
					elseif l.hold then l.peak * rampAt(l.ramp, u, 0.25)
					elseif l.grow then l.peak * u * u
					else l.peak * (1 - u) ^ 2
				if l.flicker then
					b *= math.max(0, 1 + 2 * l.flicker * math.noise(t * 11, l.at * 7.3 + 0.5))
				end
				if l.clear and rays then
					-- clear: it dims as it nears a surface below or ahead of it and is out when it gets there (a light that
					-- rode into the floor lit it as a red band with a hard edge on the contact frame)
					local at, here, fade = holder.WorldPosition, p + shift, l.range * math.sqrt(s) * 0.5
					local k = 0
					if not workspace:Raycast(here, at - here, rays) then
						local near = fade
						local down = workspace:Raycast(at, Vector3.new(0, -fade, 0), rays)
						if down then
							near = at.Y - down.Position.Y
						end
						local ahead = workspace:Raycast(at, -spray * fade, rays)
						if ahead then
							near = math.min(near, (at - ahead.Position):Dot(ahead.Normal))
						end
						k = math.clamp(near / fade, 0, 1)
					end
					b *= k * k
				end
				for _, x in lights do
					x[1].Brightness = b * x[2]
					if cools then
						x[1].Color = keyAt(pal, l.color, u)
					end
				end
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

-- Travel ----------------------------------------------------------------------------------------------------
local EASE = {
	linear = function(u)
		return u
	end,
	-- already moving at the start (0.4x the mean speed) and 1.6x at the end: a fall, a dive
	["in"] = function(u)
		return 0.4 * u + 0.6 * u * u
	end,
	out = function(u)
		return 1 - (0.4 * (1 - u) + 0.6 * (1 - u) ^ 2)
	end,
}

local function posOf(x)
	return if typeof(x) == "Vector3" then x else frameOf(x).Position
end

local function facing(pos, dir)
	return CFrame.lookAt(pos, pos + dir, if math.abs(dir.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis)
end

local function longestLife(r)
	local m = 0
	for _, l in r.layers do
		if l.life then
			m = math.max(m, if type(l.life) == "table" then l.life[2] else l.life)
		end
	end
	return m
end

-- Something flies from `from` to `to` (a moving `to` is chased): the trail follows it, the tell waits at `to`,
-- the impact plays on arrival. Returns the flight's clock (clock.tell is the tell's clock).
function FxRecipe.travel(from, to, opts)
	opts = opts or {}
	local time = opts.time or 0.6
	local arc = opts.arc or 0
	local ease = EASE[opts.ease or "linear"] or error(`fx_recipe: no ease "{opts.ease}"`, 2)
	local s = opts.scale or 1
	local a = posOf(from)
	-- a body arrives when its front reaches `to`, not its centre: its path ends opts.reach studs short (default half
	-- its longest side). With the centre sent to a floor point, a 7-stud rock sank half into the floor for 0.04 s
	-- before its impact played, which read as the flash coming early (2026-11-21)
	local reach = opts.reach or 0
	if not opts.reach and opts.body then
		local size = if opts.body:IsA("Model") then opts.body:GetExtentsSize() else opts.body.Size
		reach = math.max(size.X, size.Y, size.Z) / 2
	end
	local function path(t)
		local u = ease(math.clamp(t / time, 0, 1))
		local b = posOf(to)
		if reach > 0 then
			b -= (b - a).Unit * math.min(reach, (b - a).Magnitude / 2)
		end
		return a:Lerp(b, u) + Vector3.yAxis * arc * 4 * u * (1 - u)
	end
	local function dirAt(t)
		local v = path(math.min(t + 0.01, time)) - path(math.max(t - 0.01, 0))
		return if v.Magnitude > 1e-4 then v.Unit else (posOf(to) - a).Unit
	end

	local trail = if opts.trail == nil then "trail" else opts.trail
	local clock
	if trail then
		local r = recipeOf(trail)
		clock = FxRecipe.play(r, facing(a, dirAt(0)), {
			follow = path,
			emitUntil = time,
			duration = time + longestLife(r) + 0.1,
			scale = s,
			palette = opts.palette,
			tail = opts.tail,
			ignore = opts.body,
			noPlay = true,
		})
	else
		clock = FxClock.new("Travel", time + 0.05)
	end

	local body = opts.body
	if body then
		local rot0 = body:GetPivot().Rotation
		clock:every(function(t)
			if t >= time or not body.Parent then
				return
			end
			local turn = if opts.spin then opts.spin * (t * math.pi * 2) else nil
			local rot = if turn then rot0 * CFrame.Angles(turn.X, turn.Y, turn.Z) else facing(Vector3.zero, dirAt(t))
			body:PivotTo(CFrame.new(path(t)) * rot)
		end)
		if not opts.keepBody then
			clock:onCleanup(function()
				if body.Parent then
					body:Destroy()
				end
			end)
		end
	end

	if opts.tell then
		local r = recipeOf(opts.tell)
		local chase = typeof(to) == "Instance"
		clock.tell = FxRecipe.play(r, if chase then to else CFrame.new(posOf(to)), {
			follow = if chase then true else nil,
			emitUntil = time,
			duration = time + longestLife(r) + 0.1,
			scale = opts.tellScale or s,
			palette = opts.palette,
		})
	end

	local impacts = opts.impact
	if type(impacts) == "string" or (type(impacts) == "table" and impacts.layers) then
		impacts = { impacts }
	end
	clock:at(time, function()
		local land, dir = posOf(to), dirAt(time)
		if body and not opts.keepBody and body.Parent then
			body:Destroy()
		end
		local is = opts.impactScale or s
		for _, imp in impacts or {} do
			-- a "feet" recipe sits on the landing point; any other is set back along the flight (opts.impactLift
			-- studs at scale 1, default 1), so its glows are not cut in half by the surface it hit
			local r = recipeOf(imp)
			local at = if r.anchor == "feet" then land else land - dir * (opts.impactLift or 1) * is
			FxRecipe.play(r, facing(at, dir), { scale = is, palette = opts.palette })
		end
		if opts.onArrive then
			opts.onArrive(land, dir)
		end
	end)
	return clock:play()
end

-- Loads every texture the recipes use (FxTextures.resolve, ContentProvider:PreloadAsync); it yields. Call it once on
-- the client before the first cast: without it the first cast froze the client for about 1 s while its textures
-- loaded, then the effect jumped ahead and left a blob where it started.
function FxRecipe.preload()
	return FxTextures.resolve()
end

return FxRecipe
