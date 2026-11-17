# Cutscene example strips

Freeze-frame captures of the skill cutscene and its elements from `roblox-feel-audio-vfx` section 3e: `scripts/skill_cutscene.luau` and one demo per element from `scripts/cine_demos.luau` (camera, impact frames, overlays, lightning, energy sphere, ground burst, ink shapes, lettering, pose beats). Captured with `scripts/fx_capture.luau` and laid out with `scripts/fx_strip.py`. Every frame comes from one run of the served code; no frame was edited. Some captured beats were left out of a strip (listed below); nothing was added.

- Date and engine: 2026-11-18, Roblox Studio 0.748.0, Play, client view.
- Stage: `cine_stage.setup()` (grey tile floor, daylight) and `cine_stage.buildRigs()` (two R15 dummies 7 studs apart facing each other, dark hero and light target, joints swapped to Motor6D for code posing). The player character spawned about 70 studs away and was kept out of the strips.
- Camera: the shots of each demo and of the cutscene (`cine_camera`), never a free camera. Desktop window viewport 2618 x 1414 px, frames scaled down for the strips.
- Method: `fx_capture.run(name, play, times, { hold = 1.4, scale = 0.25, marker = true })`. The effect clock runs at 0.25x, stops on each beat time, every emitter's `TimeScale` goes to 0, the frame is held 1.4 s and grabbed by a background window capture keyed by the frame marker. The marker shows as small squares at the bottom-left of each frame. Labels are clock times in seconds.
- Output during the run: no errors and no warnings. The cutscene's flash log: 3 flashes, at most 3 in any 1 s.

| File | Shows | Beat times (s) |
|---|---|---|
| `cutscene_a_shots.jpg` | build-up: wide, charge on the fist, face ECU with speed lines, over-the-shoulder, dark beat; about one frame per shot change | 0.02, 0.6, 1.07, 1.3, 1.57, 1.7, 2.12, 2.4, 2.64, 2.9, 3.05, 3.1 |
| `cutscene_b_block_peak.jpg` | the impact block frame by frame (white, cyan field with black silhouettes, mono, blue field with white silhouettes) into the peak with lettering and speed lines | 27 consecutive frames, 3.12 to 3.55 at 1/60 s |
| `cutscene_c_peak_hold.jpg` | end of the peak, lightning on the sphere, debris, dark beat ends at 4.0, dust, hold, hand-back | 3.583 to 4.2 (16 frames), 4.5, 4.8, 5.1, 5.5, 6, 6.5, 6.8 |
| `camera_reel_strip.jpg` | `cine_camera`: low wide, face ECU push-in, hand ECU with dutch roll, orbit with roll to 0, low wide with shake, hand-back | 0.05, 0.6, 1.02, 1.1, 1.2, 1.5, 1.62, 1.75, 2.1, 2.3, 3.3, 3.45, 3.5, 3.55, 3.6, 3.65, 4, 4.5, 4.9 |
| `impact_frames_strip.jpg` | `impact_frames`: dark beat, default block (white, field, mono, field), block B (black, mono, white field, blue field), white-out with decay | 0.2, 0.45 to 0.65 (13 frames), 0.7, 1.7 to 1.9 (9 frames), 2.95 to 3.2 (6 frames), 3.3 |
| `screen_overlays_strip.jpg` | `screen_overlays`: letterbox and vignette on a face ECU, radial speed lines, parallel speed lines on the wide | 0.1, 0.3, 0.6, 0.617, 0.633, 0.65, 0.667, 0.75, 0.85, 1.3, 1.317, 1.333, 1.35, 1.7, 2.1, 2.25 |
| `lightning_strip.jpg` | `lightning`: three strikes at the target with ground glow, then an arc between the dummies | 0.1, 0.117, 0.133, 0.15, 0.4, 0.417, 0.433, 0.45, 0.467, 0.7, 0.717, 0.733, 1, 1.05, 1.1, 1.3 |
| `energy_sphere_strip.jpg` | `energy_sphere`: charge ring on the fist, white-out as the sphere opens, sphere with core, rim and inner bolts | 0.1, 0.4, 0.6, 0.617, 0.633, 0.65, 0.667, 0.7, 0.75, 0.82, 0.9, 1.1, 1.4, 1.62, 1.68, 1.75 |
| `ground_burst_strip.jpg` | `ground_burst`: ground ring, debris thrown and settling, dust cloud and its fade | 0, 0.017, 0.033, 0.05, 0.083, 0.12, 0.2, 0.3, 0.5, 0.75, 1, 1.3, 1.6, 1.9 |
| `ink_shapes_strip.jpg` | `ink_shapes`: black spikes behind (5 frames), black smear in front (3 frames), white shards in front (4 frames) | 0, 0.017, 0.033, 0.05, 0.067, 0.3, 0.317, 0.333, 0.6, 0.617, 0.633, 0.65, 0.9 |
| `lettering_strip.jpg` | `lettering`: two sound words popping in, holding and leaving | 0, 0.017, 0.033, 0.05, 0.3, 0.317, 0.333, 1, 1.42, 1.433, 1.45, 1.47 |
| `pose_beats_strip.jpg` | `pose_beats`: rest, charge, strike, target thrown and down, hero recovers | 0, 0.3, 0.8, 0.817, 0.833, 0.85, 0.867, 0.95, 1.1, 1.3, 1.6, 2.4 |
| `galaxy_a06_key_frames.jpg` | the whole cutscene in Studio's Device Simulator, Samsung Galaxy A06 preset (800 x 360 screen, viewport 705 x 338), with the top bar | 0.6, 1.3, 1.7, 2.4, 2.9, 3.12, 3.17, 3.22, 3.27, 3.367, 3.4, 3.483, 3.55, 3.683, 3.8, 3.9, 4.2, 5.1, 6, 6.8 |

Left out: the camera reel frame at 2.8 s and the cutscene frame at 7.1 s showed the player character.

Phone run: the same flash log as desktop (3 flashes, at most 3 in any 1 s). After the hand-back the touch controls were on again and the camera was back to `Custom`.

Weak points visible on the strips (also in section 3e, Known limits): the face ECU shows the blank default dummy face; the block's white frames and the energy sphere's white-out wash the whole screen; the first peak frames wash white around the sphere core; the sphere rim is beaded; debris are plain boxes; the hero's pose snaps between beats (no animation plays on the dummies). Not checked on a real phone or in a published game.
