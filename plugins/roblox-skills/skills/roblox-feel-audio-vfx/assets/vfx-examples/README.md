# VFX example strips

Freeze-frame captures of the three served effects of `roblox-feel-audio-vfx` section 3d (`scripts/fire_slash.luau`, `scripts/hit_impact.luau`, `scripts/level_up_aura.luau`), captured with `scripts/fx_capture.luau` and laid out with `scripts/fx_strip.py`. Every frame of a strip comes from one run of the served code; no frame was edited.

- Date and engine: 2026-11-17, Roblox Studio 0.747, Play, client view, Studio MCP `screen_capture`.
- Stage: grey daylight baseplate (`ClockTime` 14.5, default Studio lighting), two R15 dummies 7 studs apart facing each other, a 4.2-stud sword part welded to the hero's right hand. The player character was parked out of view. Play was restarted between the slash run and the hit run.
- Camera: fixed, FOV 70, about 22 studs away. Slash and hit: from the midpoint of the two dummies plus (20, 6.5, 5) studs. Aura: from the hero plus (17, 7, -12) studs.
- Method: the effect clock stops on each beat time, every emitter's `TimeScale` goes to 0, the frame is captured, the clock runs on to the next beat. Frames are cropped around the action; the label is the clock time in seconds.

| File | Shows | Beat times (s) |
|---|---|---|
| `fire_slash_strip.jpg` | wind-up, swing with crescent, edge and trail, flames, smoke, return | 0.08, 0.14, 0.165, 0.19, 0.21, 0.23, 0.26, 0.31, 0.38, 0.5, 0.7, 0.95 |
| `hit_impact_strip.jpg` | flash, core and bolts, shock ring with its dark ring, sparks, smoke, star pops | 0, 0.017, 0.033, 0.05, 0.075, 0.1, 0.14, 0.2, 0.28, 0.4, 0.6, 0.85 |
| `level_up_aura_strip.jpg` | ground ring, core flash, pillar, burst stars, sustain risers and ground circle, fade | 0.02, 0.05, 0.1, 0.18, 0.3, 0.5, 0.9, 1.5, 2.2, 2.9, 3.2, 3.7 |
| `galaxy_a06_key_frames.jpg` | one key frame per effect in Studio's Device Simulator, Samsung Galaxy A06 preset (viewport 705 x 338), with the touch controls | slash 0.21, hit 0.1, aura 0.18 |

Weak points visible on the strips (also in section 3d, Known limits): embers are nearly invisible; flames float above the arc early and stay at the hero's hip to about 0.5 s; the hit smoke is a dark blob on the target and the white glow covers its upper body at 0.017-0.033 s; the aura core flash hides the hero at 0.1 s and the sustain is thin; after the slash the hero's arm keeps the swing pose (no animation plays on the dummy). Not checked on a real phone or in a published game.

## Clip-built effects (section 3f)

Freeze-frame captures of `scripts/formation_seal.luau` and `scripts/void_pillar.luau`, captured the same way from one run of the served code each; no frame was edited.

- Date and engine: 2026-11-18, Roblox Studio 0.748, Play, client view, desktop window capture (2616 x 1412 px viewport), frames uncropped.
- Seal stage: night (black sky, dark floor), camera fixed at the centre plus (0, 13.2, 10.8) studs looking at the centre plus (0, 4.6, -0.6), FOV 70, so the horizon stays out of frame.
- Pillar stage: grey fog with a far wall in the haze colour, camera fixed at the centre plus (0, 5, 25) studs looking at the centre plus (0, 8, 0), FOV 70.
- No character on either stage: the seal's default radius is 6 studs and the pillar's core half-width 3.2 studs.

| File | Shows | Beat times (s) |
|---|---|---|
| `formation_seal_strip.jpg` | 3 sides, hue 0.6: seed stars, orbiting crescents, spike and flare, birth flash, orb, blades falling to the corners, wind-up turn, corner stars, edges snapping in, walls and flames through the hold, afterglow outline | 0.05, 0.5, 0.95, 1.08, 1.2, 1.4, 1.8, 2.05, 2.16, 2.8, 3.8, 4.7 |
| `formation_seal_variants.jpg` | columns: 4 sides (hue 0.08), 5 sides (0.36), 6 sides (0.96), 4 sides with `reducedMotion` (0.6) | 2.3, 3.0 |
| `void_pillar_strip.jpg` | hue 0.76: warning line and floor glow, strike flash, pillar landing, sustain with sashes, rings, rays and lens streak, collapse to a line | 0.26, 0.31, 0.34, 0.5, 0.7, 1.0, 1.5, 3.0, 4.0, 4.9, 5.1, 5.4 |

Weak points visible on the strips (also in section 3f, Known limits): the seal's fill shows wedge facets and its last frame is a plain thin outline; the pillar's strike is a full white frame at 0.31 s; its sashes are flat ribbons that read as paper at 1.5 s and 4.0 s; the lightning arcs are easy to miss. No character for scale, no sound. Not checked on a real phone or in a published game.
