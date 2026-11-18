---
name: roblox-feel-audio-vfx
description: "Use when adding or tuning game feel in Roblox: particles, beams, trails, hit feedback, screen shake, FOV kicks, hit stop, screen flash and edge tint, vibration (haptics), coin fly-to-counter and other reward feedback layered per moment, in-game animation (Animator, priorities, animation events, emotes), lighting and atmosphere for mood, with mobile budgets and a checklist. Sound effects and music: roblox-audio. Also when a game feels flat or its effects feel simple, effects are invisible or too heavy on phones or look thin and cheap next to concept art, an animation does not play, replicate or gets overridden, lighting looks washed out or too dark (also a night area that reads as a dark blob), bloom bleeds light everywhere, a night scene needs glow under a light budget or must match a concept's mood, the camera swings or shakes until players feel dizzy, when an effect needs a worked layer recipe (fire slash, hit impact, level-up aura), textures that work without uploads or a freeze-frame capture, when building a flashy skill cutscene (impact frames, dutch-angle shot list, lightning, energy sphere, debris, sound-effect lettering, flash cap), when rebuilding an effect from a reference clip (polygon seal with an orb, sky pillar), when fire or an explosion looks like pasted sprites or cotton balls, when a swirl should be a glowing mesh, or when planning the 'feel' decision cards in roblox-game-pipeline stage 4."
last_reviewed: 2026-11-18
sources:
  - https://create.roblox.com/docs/audio (objects, effects, assets)
  - https://create.roblox.com/docs/effects/particle-emitters (Rate limits, fill rate, `LightEmission` 1 hides the dark regions of a texture)
  - https://create.roblox.com/docs/environment/lighting and /atmosphere
  - https://create.roblox.com/docs/reference/engine/classes/Animator.md and AnimationTrack.md, enums/AnimationPriority.md
  - https://create.roblox.com/docs/animation/events and /characters/emotes
  - https://create.roblox.com/docs/reference/engine/classes/HapticEffect.md and GuiService.ReducedMotionEnabled (creator-docs 7cbffff, 2026-11-10)
  - Squirrel Eiserloh, "Math for Game Programmers: Juicing Your Cameras With Math", GDC 2016 slides (read 2026-11-12)
  - https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html and Xbox Accessibility Guidelines 117 and 118 (read 2026-11-12)
  - RoDesigner skill effect demos, 2026-11-15 (two builds of one sword skill in Studio 0.747, one judged by the owner on video; engine probes of beams, Neon and TimeScale) and one public VFX showcase clip read frame by frame at 50 fps (numbers and method only); relayed by RoDesigner
  - https://create.roblox.com/docs/reference/engine/classes/Beam, enums/TextureMode and classes/ParticleEmitter (TextureLength per mode, TimeScale 0 to 1, flipbook and shape enums; read 2026-11-15)
  - RoDesigner VFX demo, 2026-11-17 (fire slash, hit impact, level-up aura in Studio 0.747 Play on a daylight floor, approved by the owner in Studio; ported to scripts/ and re-captured the same day); texture ids from the Roblox docs VFX tutorials and https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597; asset owners from economy.roblox.com/v2/assets/<id>/details (read 2026-11-17)
  - RoDesigner skill cutscene demo, 2026-11-18 (nine elements and one 7.2 s cutscene in Studio 0.747 and 0.748 Play, judged well made by the owner on its captures; ported to scripts/ and re-captured the same day); target ranges read frame by frame from four public showcase clips at 30-60 fps, 2026-11-17 (numbers and method only); relayed by RoDesigner
  - RoDesigner ground blast demo, 2026-11-18 (one fire and impact effect in Studio 0.748 Play, rebuilt over 8 capture rounds next to a public showcase clip of a similar effect read at the same 16 beat times, plus real-time captures; judged good by the owner on its captures, who then set the small-units rule; engine probes of Brightness, emit placement, mesh textures, SurfaceAppearance emissive and script write access; numbers and method only from the clip); relayed by RoDesigner
  - https://create.roblox.com/docs/reference/engine/classes/ColorCorrectionEffect, classes/Highlight, classes/PostEffect (post effects do not affect GuiObjects) and classes/GuiService (TouchControlsEnabled, ReducedMotionEnabled)
  - original (feel checklist and budgets are judgment, not measured)
  - original field notes (2026-10 to 2026-11)
---

# Game feel: audio, effects, lighting

Feel is what makes the same loop satisfying. Plan it as part of the loop (stage 4 "Feel" cards), then budget it for phones.

## 1. Feedback map (planning)

For each frequent action write what the player sees, hears and feels: action, result, reward, error. Example: tap to collect -> pop sound + number rising + currency counter bump. Every repeated action needs feedback in at least two channels (sight + sound). Errors need a different, clear cue (never the same as success). For any effect longer than a short tick (reveals, auras, celebrations, finishers), first fill the fun card in `roblox-fun-effects` section 1: what it rewards, who sees it, how it escalates.

## 2. Audio

Sound effects, music and ambience live in `roblox-audio`: event sound map, mix, buses and ducking, loops, Sound vs the Audio API, phone budgets, sourcing and rights, measuring. Give every feedback-map row that makes a sound an event id there.

## 3. Effects

- `ParticleEmitter`: one emitter makes up to 400 particles per second (100 on mobile) according to the docs; keep `Rate` low and `Lifetime` short. Particle size costs GPU fill rate, so many large overlapping particles hurt phones.
- Flipbooks (`ParticleEmitter.FlipbookLayout` 2x2, 4x4, 8x8 or `Custom` with `FlipbookSizeX`/`FlipbookSizeY`) cost texture memory, and clients switch them off when low on memory (docs), so an effect must still read without its flipbook. `ParticleEmitter.TimeScale` (0-1) slows or freezes an effect for a hit stop; at 0 it held particles still for a late screen capture (section 3d, measured 2026-11-17).
- Size particles for the real camera distance: 1-1.5 stud stars all but vanished 40-100 studs away, while 1.8-3 studs by tier read (field observation, 2026-11-04); 0.9-stud star pops still showed at about 22 studs (section 3d capture, 2026-11-17), so a size floor holds for one distance only. Check in a screenshot from the player's camera, not up close.
- `ParticleEmitter.Size` is the width of each particle's square texture (docs). A shockwave ring texture ended about 1.05 x Size across, measured top-down against an 80-stud road (field note, 2026-11-11), so a splash ring of radius r needs an end Size of about 2r.
- **Particle motion, measured** (Studio, 2026-11-18, top-down captures against a 5-stud grid, `Speed` 20, `Lifetime` 3):
  - `Drag` counts halvings of speed per second: speed halves every 1 / `Drag` s, so a particle stops after about 1.44 x `Speed` / `Drag` studs. Stops measured: 36.4 studs at `Drag` 0.5 (37.3 predicted for the 3 s life), 14.5 at 2 (14.4), 2.7 at 10 (2.9). For a burst that stops at radius R, set `Drag` to 1.44 x `Speed` / R and the `Lifetime` to at least 3 / `Drag` s (87% of the way out). The docs' wording, the rate in seconds at which particles lose half their speed, reads like a half-life: larger values stop sooner.
  - `Shape` `Disc` with `ShapeStyle` `Volume`: `ShapePartial` 1 fills the disc, 0.5 leaves the inner half empty, 0 emits on the rim only, a clean ring of sparks for a shockwave. `Surface` at 1 also filled the disc.
  - `Trail.MaxLength` caps a ribbon in studs whatever the speed: at 30 studs/s with `Lifetime` 3, `MaxLength` 12 drew 12.3 studs and 0 (no cap) about 77. Set the fade with `Lifetime` and cap fast swings with `MaxLength`.
- The built-in `rbxasset://textures/particles/*` textures plus thin Trails read as a wireframe of lines on a dark sky next to concept art. A release-quality burst needs custom glow, star, streak and sparkle (flipbook) textures, dense emission along the shape, additive layers (`LightEmission` 1, `LightInfluence` 0) and a moderate `Bloom`. Dark semi-transparent layers over a night sky render brown and muddy; use fewer, brighter additive ones (field observations, 2026-11-04).
- Generated glow and energy sprites for additive use: ask for the sprite on pure black, not on a transparent background. With `LightEmission` 1 the dark regions of a texture disappear (docs), so the black needs no keying, and the soft falloff stays. A transparent background comes back as a cut-out: in one test image about 69% of the pixels were fully clear, the body almost opaque and the halo under alpha 32 of 255, so the glow lost its falloff (relayed by RoDesigner, 2026-11-14). Ask for transparency only for solid sprites with normal blend.
- House rule (owner): VFX are Blender meshes (`roblox-blender-export`) plus gradient or flipbook textures. No block tiles and no default sparkles (the `Sparkles` object or the built-in particle textures) in a release: built-in `rbxasset://` textures are prototype only, labelled as greybox, and public docs ids are a test stage (stages and ids: section 3d). The owner also approved an effect form of beams and particles with no mesh (section 3d; approved 2026-11-17). A glowing Blender mesh without a `SurfaceAppearance` (field note, 2026-11-09): model the emissive shapes as their own geometry in flat `Neon` colors (Neon on a textured MeshPart does not glow, `roblox-pitfalls` section 4), layer a dark non-Neon shade mesh for the dark parts, and put textures only on lit surfaces. When a brief forbids uploads, a portal vortex that worked without them (field note, 2026-11-09) used flat curved Beams as spiral arms around a centre: `CurveSize0` and `CurveSize1` bend a beam into a Bezier curve (docs), `FaceCamera` is false, and the built-in glow texture is stretched along each arm (section 4, "Night glow without lights"; a prototype by the stages above).
- House rule (owner, 2026-11-18): build every effect from small units, in size and in lifetime, even when that takes longer or is harder. No sprite is a picture of a whole thing (a whole flame, a whole explosion); each piece lives about 0.05-0.3 s and is replaced for as long as the effect lasts; a fire that dies shrinks, it does not thin out to one piece. Avoid a large mass of one colour wherever possible (owner, same day): a big shape needs bands, texture or pieces inside it, and a layer whose texture is missing is left out, not drawn as a flat shape. Judge an effect running at real speed as well as on frozen frames. Method, numbers and the measurements behind them: section 3g. Smoke that has to keep its place and dissolve is a flipbook whose frames carry the erosion, and a floor breaks without a hole from a kit of slabs: section 3h.
- Beams, trails, lights, highlights: use sparingly; each light source and highlight has a cost.
- **A `Highlight` skips transparent parts.** It drew no outline and no fill on parts with any `Transparency` above 0: hologram parts at 0.06 lost the whole rim and tint (toggled live in Studio, field note 2026-11-11). The docs do not say so; a Roblox staff reply says highlights on transparent parts have not worked for years, and posters there report that parts inside a model with a Humanoid still get them (DevForum t/4678843, 2026-08-20). Keep highlighted parts at `Transparency` 0 and make a hologram from a dark `Neon` colour plus the Highlight fill. Check a Highlight against a plain background before trusting a capture: a bright portal behind the model passed for a rim.
- **Curved Beams.** A Beam is a cubic Bezier: P1 sits `CurveSize0` studs along +X of `Attachment0`, P2 sits `CurveSize1` studs along -X of `Attachment1` (docs, effects/beams). For a circle of radius R from four quarter-arc beams, point each attachment's X axis along the direction of travel and set both sizes to +0.5523 R, the usual Bezier quarter-circle constant (4/3 x (sqrt 2 - 1)); a negative `CurveSize1` drew a hook at each joint (field note, 2026-11-11).
- Wind (docs `environment/global-wind`, read 2026-11-16): `Workspace.GlobalWind` is one vector for the whole game and moves terrain grass, dynamic clouds and particles. A `ParticleEmitter` follows it only with `WindAffectsDrag` on and `Drag` above 0; `Fire` and `Smoke` follow it by default. Reduce Motion slows the grass. For gusts the docs sample rewrites the vector in a loop; computing it on each client from `Workspace:GetServerTimeNow()` would give every client the same gust with nothing sent per frame (judgment, not tested).
- Burst on events, not constant emission; destroy or disable emitters when done; cap simultaneous effects per player and per server.
- Draw where the server acts: a drop, hit spark or pickup appears at the position the server uses. One game's server walked enemies on the road centre line while clients drew them fanned out, so coins fell on the centre line away from the visible death, and the owner saw it on a phone (field note, 2026-11-09). Compute such positions with one shared pure function that server and client both call.
- A hit or aura that reads as finished is a stack: a flipbook or mesh shape, a white-hot additive core grading to the effect color, an alpha smoke layer, sparks, debris and a camera kick (rules below). Quality comes from texture art and layering, not particle count (judgment from 2026 artist breakdowns). Free textures to start from: Creator Store "VFX PACK" (Euphoric Games Community, 112672322113504, +970/-30) and "Rei's Particle Pack" (10198615035, +990/-10), both free models without scripts (read 2026-11-05; contents not reviewed by us: insert, audit per `roblox-store-art-pack` section 3 and look before use).
- Hit feedback: flash/highlight + sound + small camera shake or knockback; damage numbers short and readable.
- Screen shake: small amplitude, short, with an off switch in settings (`roblox-fun-effects` section 10: "Reduce effects" also removes camera kicks; `roblox-fun-effects` section 8 sizes the kick and hit stop; section 3b has the shake model).
- Camera rules (field observation): only the object the camera follows (normally the player character) and the player's own actions shake or re-aim it; contacts from other objects (extra projectiles, NPCs, spawned copies) never do, or the screen swings until players feel dizzy. Shakes combine by max, never by sum: keep one amplitude, set it to the larger of the current and the new value, and clamp it.
- Animations: key poses readable at phone distance; 3-5 core animations first (idle, move, action, hit, reward). Attack and skill motions start from a motion sheet: a row of key poses plus a beat table (`roblox-character-motion` section 2a).

## 3a. Playing animations in game (docs)

- Load through the `Animator` under the Humanoid or `AnimationController`: `Animator:LoadAnimation(animation)` (the Humanoid's own `LoadAnimation` is deprecated). Each call makes a new track, so load once and cache it, or find it with `Animator:GetTrackByAnimationId`. The Animator must be in the Workspace.
- Replication: a player's own character animations started on that client replicate to everyone. NPC and other non-character animations must be loaded and played on the server, and the `Animator` must be created on the server, or nothing replicates.
- Priority (`AnimationTrack.Priority`, `Enum.AnimationPriority`): default and catalog animations play at `Core`; developer animations use `Idle`, `Movement`, `Action`, then `Action2`-`Action4` (highest). Higher overrides lower per joint, so an attack set to `Core` or `Idle` gets swallowed by walking.
- Timing: add event markers in the Animation Editor (settings > Show Animation Events) and connect `AnimationTrack:GetMarkerReachedSignal("Name")` for footstep sounds, VFX bursts and hit frames. Markers are presentation: the server decides damage by its own timing (`roblox-combat-tools`). `AdjustSpeed`, `AdjustWeight`, `Looped` and the `Ended` event cover the rest.
- Emotes: `HumanoidDescription:SetEmotes` then `SetEquippedEmotes` (up to 8 in the wheel); play one with `Humanoid:PlayEmoteAsync(name)` (`PlayEmote` is deprecated though the emotes guide still shows it). Hide the wheel with `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)`; chat `/e` still works.
- Ownership: for a group-owned game, publish animations with the group in the Animation Editor's Creator field (docs). An animation owned by someone else commonly fails to load in the game (C).
- Custom motions (exercise loops, sitting, climbing, interactions) and any animation built by script: `roblox-character-motion`. Ids from `KeyframeSequenceProvider:RegisterKeyframeSequence` work only in Studio; upload the clip for live servers.
- Code that finds or edits R15 joints: Avatar Joint Upgrade replaces `Motor6D` with `AnimationConstraint` (`roblox-engine-2026` section 3).

## 3b. Feedback layers and rules

This section is the guide: which layers fire per moment, and the rules they follow. Code and art are not kept in the skill. Ready client modules (camera and screen feedback, world effects, screen effects) and effect textures come from the RoDesigner MCP when it lists them (`list_kit_packs`, `get_kit_pack`); without it, build to the rules below.

The owner judged two versions of one test place in Studio (field note, 2026-11-12): one burst, one number and one shake per hit read as "simple"; the layered version below was accepted as the direction. Nothing was checked on a phone, and every number is judgment unless it carries another label.

The building blocks, by channel:

| Channel | Blocks |
|---|---|
| Camera | shake, one-sided roll kick, short FOV punch, held FOV for a state (dash, aim), hit stop |
| Screen | flash, edge tint, colour grade, bloom pulse, blur pulse, letterbox, speed lines, coin rain |
| World | layered impact (flash ball, light, streak sparks, stars, then a ring, then smoke as the tier rises), ground ring, dome, light pillar, slash arc, limb trail, highlight flash, afterimage, aura, dust, fireworks, loot that pops out, bounces and flies to the player |
| UI | pop on press and on change, count-up, fly-to-counter, floating "+N", stamp slam, ring and spray bursts, confetti, glow and rays behind a reward, shine sweep and slow breathing on a call to action, rainbow text, toast, card flip |
| Sound and touch | pitch that climbs within a run, layered sounds for big moments, vibration |

One event fires several layers across channels. What the test place fires per moment (starting values; trauma is the 0-1 shake input):

| Moment | World | Camera and screen | UI | Sound and vibration |
|---|---|---|---|---|
| Hit | white highlight flash 0.1 s, impact tier 1, squash and tilt that springs back in 0.5 s, slash arc, hand trail | trauma 0.3 | number on an arc, health bar with a late white "ghost" bar, combo count that grows and warms | hit sound, half a semitone up per combo hit; tap |
| Crit | impact tier 2 | hit stop 0.05 s, trauma 0.45, FOV +2, roll kick 1.5 degrees | bigger yellow number | crit sound; hit |
| Kill | impact tier 3, ground ring, debris, coins and orbs that pop out, bounce and fly to the player | hit stop 0.08 s, trauma 0.6, FOV +4, flash 0.16, kick 2 degrees | one "+N" per 0.25 s at the counter, count-up, counter pop, streak banner on the 2nd kill in 4 s | kill pop, coin tick one semitone up per coin; hit |
| Boss kill | dome, wide ground ring, impact tier 4, fireworks | letterbox, blur and FOV -7 during a 0.16 s stop, then trauma 0.9, FOV +7, flash 0.35, bloom, kick 4 degrees | banner slam, coin rain, confetti | layered boom; big |
| Pickup | bob, spin and sparkle while idle; impact tier 2 and a ground ring on pickup | none | "+N", counter | chime two semitones up per pickup in a run; tap |
| Level up | light pillar, ground ring, aura 2.6 s, cheer emote | edge tint, bloom, FOV +3 | banner slam, stat lines 0.28 s apart, confetti | fanfare; notify |
| Dash | dust, four afterimages | held FOV +12 for 0.22 s, speed lines | button pop | whoosh; tap |
| Hurt | red highlight flash | red edge, desaturate, blur, trauma 0.6, kick 3 degrees; low health: an edge pulse every 0.95 s | health bar pop | hurt sound; hit |

Reveals and reward popups: `roblox-fun-effects` sections 4 and 9.

Rules:

- **Shake.** One trauma value from 0 to 1, shake = trauma squared, linear decay, smoothed noise instead of random numbers, and in 3D rotate the camera only (Eiserloh, "Juicing Your Cameras With Math", GDC 2016, slides read 2026-11-12). Apply it after the camera update (`RenderPriority.Camera + 1`) and combine by max (the camera rule above). With maximum angles of 3 degrees, measured in Studio at 70 FOV: about 0.1-0.3 degrees for trauma 0.3, 1 degree for 0.6, 1.6 degrees for 0.9; one degree is about 1.4% of the screen height. A `Scriptable` camera must set its `CFrame` every frame before that step, or the offsets add up. On stop, undo only your own last offset, and only if the camera still holds it; never write back a `CFrame` saved at the start, which is stale by then and can leave a standing offset when the stop lands mid-shake (judgment).
- **Springs that look the same at any frame rate** (`scripts/spring.luau`): step springs in closed form, not with `v += a * dt; x += v * dt`. Measured in Studio (2026-11-18), a 2 Hz spring from 0 to 1: the closed form gave the same value after 0.5 s at 30, 60 and 240 steps per second and on a run of uneven steps, while a hand-written Euler spring with the same settings peaked at 1.12 at 30 fps and 1.16 at 240 fps (damping 0.5), and an 8 Hz spring at damping 0.3 blew up at 30 fps. So a phone that drops frames sees a different, or a broken, motion. Pick the damping by the overshoot you want: 0.5 gives 16% (a bouncy pop), 0.7 about 5% (a camera or panel that settles), 1 none (measured peaks 1.163 and 1.046). Use it for camera follow, UI pops, recoil and lean; `impulse` adds velocity for a kick.
- **Ownership.** A feedback module tags what it creates (an attribute or a tag), saves a borrowed property's old value once, at the first change, removes only its own instances on stop and puts the saved values back. On start it sweeps what a crashed run left behind. Test it: an emitter, a `Beam` reference or an attribute that other code put on the same `Attachment` is still there after stop (judgment; the same first-save rule as the camera in `roblox-cinematics` section 5).
- **FOV has one owner.** Read the resting FOV only while no punch or held offset runs, and let other code change it through that owner. Two game sessions report that a kick still running when another script read "the base" became the new base (field notes, 2026-11-12, not re-tested here). Clamp the summed offset (10 degrees in the test place).
- **Hit stop has a budget:** at most 0.25 s of freeze in any second; cut a longer request. Count overlapping stops per animation track and restore the speed once. One tower-defence session ended at no stop for ordinary kills because a lane of small enemies stuttered (field note, 2026-11-12, not re-tested here).
- **Hit stop that grows with the hit, and a victim that shakes** (`scripts/hit_stop.luau`, tested in Studio 2026-11-19 on R15 rigs with `AnimationConstraint` joints). The freeze grows with damage: 0.04 s plus 0.004 s per point, capped at 0.2 s, our starting curve inside the tiers of `roblox-fun-effects` section 8 (for comparison, one fighting-game series freezes floor(damage x 0.65 + 6) frames in its latest entry and floor(damage + 3) in an early one, capped at 30 and 20 frames: community data from the game files, SmashWiki "Hitlag", read 2026-11-18). During the freeze the victim vibrates around its frozen pose, 0.08 studs to each side, flipping every drawn frame, sideways on the ground and up and down in the air, so the stop reads as the blow landing and not as lag. Measured: every playing track held its `TimePosition` and came back at its own speed (a 1.3x track resumed at 1.3), and a second hit during a stop held the tracks until the later stop ended. The shake shows only when written in `RunService.PreSimulation` (`roblox-character-motion` section 1). Two traps found while building it: `PreSimulation` runs once per physics step, four times per drawn frame on a 15 fps client, so a side that flipped per call looked the same in every drawn frame (the module counts `PreRender` frames); and a rig with an anchored root reads `Humanoid.FloorMaterial` Air on the floor, so the module tests the ground with a ray. Before judging a frame-based effect through an agent, read the client's frame time: one Studio window ran its Play client at 60 fps in one run and at 15 in a later one. Curve and amplitude are not judged in the hands yet: tune them in Play (`roblox-game-pipeline` section 7a).
- **Flashes.** Full-screen brightness changes stay under three per second: "no more than three general flashes and / or no more than three red flashes within any one-second period" (WCAG 2.3.1); Xbox Accessibility Guideline 118 counts a 10% luminance change as a flash and fails flashing over about 20% of the screen (both read 2026-11-12). The test place allows 2 starts per second across flash and edge tint, caps a flash at 0.5 opacity and drops the rest, so a pulse that repeats (low health) keeps its period near 1 s.
- **Motion options.** Xbox Accessibility Guideline 117 asks for a way to turn off camera shake, bob and motion blur (read 2026-11-12); `GuiService.ReducedMotionEnabled` is the Roblox Reduce Motion setting (docs). With reduced motion: no shake, kicks, FOV changes, blur, pops, flights or confetti; sound, colour, numbers and vibration stay. Give each channel its own switch in settings too.
- **Vibration.** `HapticEffect` runs on Android and iOS phones that support haptics, PlayStation and Xbox gamepads and Quest Touch; `Type` is `UIClick`, `UINotification`, `GameplayCollision`, `GameplayExplosion` or `Custom` with `SetWaveformKeys` (`FloatCurveKey` time in ms, value 0 to 1); the docs sample parents it to Workspace and plays it on the client; `HapticService` is the older API (docs, read 2026-11-10). The calls ran without errors in Studio, where nothing can be felt: tune strength on a real phone (not done).
- **Screen layers.** Flash, edge tint, letterbox, coin rain and speed lines live in a `ScreenInsets = None` ScreenGui (`roblox-ui-layout` section 3). Mark effect elements `KitTransient` so the device sweep leaves them out of the HUD budgets. Their text and tap targets still meet the phone floors at full size, and a `UIScale` on or under the marked root is the way to animate them (`roblox-ui-layout` section 4).
- **Edge washes on wide screens.** A Radial `UIGradient` is a circle as tall as its frame, not an ellipse of the frame's size: on a 2:1 phone a full-screen red edge wash built with one covered the thirds beside the middle instead of fading at the edges. Build danger and damage edges from side bands with linear gradients (top and bottom bands if wanted) and check them on a phone preset (field note, 2026-11-16).
- **Counters rise on every pickup.** Update a currency readout per pickup, not after the last pickup of a run. In one game the readout waited for the 0.85 s fly-in and each new pickup cancelled the pending roll-up, so the number froze through a run of pickups (up to 7.25 s with an auto-collect pass). A short count-up per change (0.15 s) let it climb coin by coin (field note, 2026-11-15).
- **Streak sparks** are particles stretched along their velocity: a soft dot texture reads as a speed line. With `Orientation = VelocityParallel` the stretch follows `Rotation`: at `Rotation` 0 a negative `Squash` stretches along the path and a positive one makes a bar across it; at `Rotation` 90 a positive `Squash` stretches along the path (measured top-down and side-on with a star and with the docs ember texture 17581858560, Studio 2026-11-18). The recipe scripts pair `Rotation` 90 with a positive `Squash`; keep the two together, and never leave a streak's `Rotation` random (`FxClock:emitter` defaults to 0-360). Under `FacingCamera` and `FacingCameraWorldUp` a positive `Squash` stretches up the screen or up the world, which suits sparks that rise. A ring that lies on the ground is one particle with `Orientation = VelocityPerpendicular`, emitted upward at almost no speed (tested in Studio, 2026-11-12).
- **Textures.** The test place ran on built-in textures so it needed no uploads. That is a prototype state: the house rule above holds, so a release uses the game's own star, soft glow, smoke, ring and soft-edged band textures. Public ids that rendered without uploads, with their blend settings: section 3d.
- **Cost.** Creating a few instances per event and cleaning them up suits the local player's own effects. Pool and cap effects of other players and crowds (section 3).

Checking effects from an agent:

- `screen_capture` came back 1-2 s after the call, so a 0.3 s effect is gone. Read state per frame instead (camera angle against `Camera.Focus`, `FieldOfView`, instance counts) with a render-step probe, run the effect with a long duration for the capture, or capture a beat that holds (a reveal's show beat) (field note, 2026-11-12).
- Keep an "all effects off" switch in dev builds and play the same 30 s with it off and on. A channel nobody misses is noise (judgment).
- A tween on a `NumberValue` that was never parented left the value at its start; drive such values from `RenderStepped` with `TweenService:GetValue` (field note, 2026-11-12; cause not isolated).

## 3c. Skill and attack effects (slash, flurry, burst)

How to build a skill effect that reads at game speed. Evidence (2026-11-15, relayed by RoDesigner): two demos of one sword skill built by two agents (a flurry of cuts that ends in a ground burst, about 2.4 s), one of them accepted by the owner on video for its effect animation and its method; and one public VFX showcase clip read frame by frame at 50 fps, the source of the density numbers. One clip is a lead, not a norm. The demo values were tuned by eye on a dark stage; nothing ran on a phone or in a game.

Method:

1. **One clock for every layer.** Schedule all layers on one virtual clock: events at a time, curves over a span, one step per frame, and no chains of `task.wait`. Multiply `ParticleEmitter.TimeScale` and `Beam.TextureSpeed` by the clock's scale, so the same code runs at 0.1x for a capture and at 1x in play. `TimeScale` takes 0 to 1 (docs), so the clock slows an effect and never runs it faster than 1x. Measured: `TimeScale` 0.25 stretched a 1 s particle to about 4 s, and the beam and light curves of a 0.25x run matched the 1x run within one 60 Hz frame.
2. **Beat table first.** Write the times before any layer: wind-up, each hit, charge, burst, recover. Motion and effects read the same table, so a hit, its ribbon, its sparks and its light land on one frame (`roblox-character-motion` sections 2a and 2b).
3. **Check in slow motion.** Capture one cast at about 0.1x from a fixed front camera and a pure side camera, lay the frames in a row at the beat times, fix the worst frame and capture again. An agent cannot judge a 0.07 s swing at 1x (section 3b, "Checking effects from an agent").
4. **Build order:** stage and light, the motion with no effects, the slash ribbons, the burst, smoke and stars, then the screen response. Add one layer per round and look at it alone.

Rules that made the accepted demo read; each one is a check on a capture:

| Rule | Value in the demo | Why |
|---|---|---|
| One hue family per skill | white-hot, a body colour, a deep colour and neutral grey smoke; one accent hue for 1-3 frames at most | five hues at once read as noise |
| Value ladder with a dark step | a dark soft layer under every ribbon (`LightEmission` 0, alpha 0.45), the body (`LightEmission` 0.35, `Brightness` 1.7), a hot edge (`LightEmission` 1, `Brightness` 3) | bright reads bright only next to dark; a fully additive stack washes out |
| The white core is short | 2-3 frames (0.04-0.07 s), then gone | a long white-out hides everything else |
| Nothing covers the character | smoke low and behind (`ZOffset` -3), the largest layer about 2 character heights, no full-screen layer | the pose and the hit must stay visible |
| Bright layers are short, the aftermath is long | ribbons 0.24 s, burst layers under 0.35 s; smoke, embers and star pops for 0.6-1 s after | a bright layer that stays 1.5 s smears the next hit |
| Every layer scales in and out | sweep, grow, fade; only the core pops | a layer that starts at full size looks pasted on |
| Cut planes face the camera | cut directions built in the camera's view plane, or a second arc tilted against the first so one of them reads from any side | a flat beam ribbon vanishes edge-on (measured, below) |
| The world answers | a `PointLight` pulse per hit (range 13, 0.13 s) and on the burst (range 30, 0.34 s), a camera shake on the burst, FOV +3.2 degrees for 0.26 s, a small world dim during the charge (`ColorCorrectionEffect.Brightness` -0.04) | an effect with no light on the ground looks detached |
| Stage contrast | dark floor, dusk light, `BloomEffect.Threshold` about 1.2 so only layers with `Brightness` above 1 bloom | on a bright daylight floor additive layers have nothing to stand out from: keep the dark underlayers and dim the world at the charge and the burst |

- The demo shook the camera by position (0.36 studs, decaying over 0.22 s). In a game use the shake model and tiers of section 3b (rotation only, trauma, the big hit only) with its flash, hit-stop and reduced-motion rules.
- A coloured `PointLight` on a ground effect tints the floor, not only the effect: a fire-coloured light on a slam lit one game's green floor yellow-lime. Removing it and using a white-hot core ball (2 to 7 studs over 0.07 s) kept the ground's mean luminance over the slam frames at 0.40-0.46 against 0.445 before, with no lime cast. Capture the floor with the light on and off, and keep effect lights neutral or low in saturation (field note, 2026-11-15).
- The dark step does not undo the night-sky note of section 3: there dark layers hung in front of a dark sky; here a dark layer sits right under a bright ribbon over a lit floor (judgment). Check it on a capture of your own stage.

Density: what makes an effect look rich. It is not longer or bigger: it is many short-lived elements stacked in a small volume, with a different picture on every frame.

| Property | The clip (one sample) | Target (judgment) |
|---|---|---|
| Lifetime of one arc | 2-4 frames at 50 fps (0.04-0.08 s) | keep the main ribbons (0.24 s) and add thin arcs of 0.05-0.1 s |
| Arcs visible at once | 4-6, a new one almost every frame | 4-6 through the flurry |
| Volume | a ball about 3.4 character heights wide around the hit point, arcs at every angle | secondary arcs inside a ball 2-3 character heights wide at the hit point, on random planes |
| Layer kinds in one frame at the peak | 4-6 of: core flash, needle rays, crescents, lightning strands, sparks, smoke, stars, ground ring | 5 or more at each hit |
| Order inside one hit | flash and rays at frame 0, crescents at +1 to +4 frames, smoke at +3, stars at +10 | stagger each hit's layers by 1-3 frames |
| Value range | white, yellow, orange, amber-brown smoke, thin black rays in the first 2 frames | a dark smoke layer, and 1-2 frames of dark rays at the big hit |
| Accent | one deep red-orange flat crescent for 2-3 frames | one accent shape for 1-3 frames per big hit |
| Aftermath | smoke to +0.6 s, 2-4 stars per hit at +0.2-0.4 s | small per hit, large on the burst |

- The accepted demo sits below these targets (1-2 arcs at once, one every 0.11 s, 2-3 layer kinds per frame). The targets are the next step, not a tested result.
- More elements without the rules above is clutter: keep one hue family, the dark step and the small volume.
- Cost: the second demo peaked at 42 live particles, 13 emitters with live particles, 108 drawn beams and 4 `PointLight`s in one cast (counted by its client each frame), every emitter with `Enabled` false and `Emit` bursts only. Not checked on a phone: the budgets of section 5 still decide, and other players' casts get a cheaper version (section 3b, Cost).

Engine notes (measured in Studio 0.747 by the demo builds on 2026-11-15 unless marked docs):

- A flipbook played once: `FlipbookLayout` Grid4x4, `FlipbookMode` OneShot, then `Emit(1)` with a speed of about 0.01.
- A converging charge: an emitter with `Shape` Sphere, `ShapeStyle` Surface and `ShapeInOut` Inward, so particles start on the sphere and fly in.
- An arc ribbon is a chain of curved flat Beams (`FaceCamera` false) along the arc, each attachment's X axis along the tangent, with `CurveSize0 = CurveSize1 = 4/3 x tan(angle / 4) x R` for a beam that spans `angle` of a circle of radius R (the quarter-arc constant of section 3 is this at 90 degrees). One demo used 12 beams per arc.
- A beam texture is laid along the beam. With `TextureMode` Stretch the texture repeats `TextureLength` times over each beam (docs), and a soft band texture then made every beam of a multi-beam arc a bright block with dark joints. Wrap with a `TextureLength` of 0.02, or no texture, gave an even band; with Wrap the repeats are the beam's length divided by `TextureLength` (docs).
- A flat beam spreads its width along its attachments' Y axis and vanishes exactly edge-on; a higher `Brightness` did not bring it back.
- Fully additive warm beams (`LightEmission` 1) on a dark ground washed to cream; `LightEmission` 0.55-0.65 kept gold and orange saturated.
- A beam at `Brightness` 3 was visibly brighter than at 1 but bloomed weakly; particles with `LightEmission` 1 and `Brightness` 4 bloomed with a halo.
- An untextured `Neon` MeshPart crescent glowed strongly with bloom; a textured one rendered faint and did not glow (the same finding as section 3).

The attack motion under the effect (the body leads the arm, the blade lags and whips, each stroke starts where the last ended): `roblox-character-motion` section 2b.

Three worked effects built with this method, layer by layer, with served scripts and capture strips: section 3d.

## 3d. Building an effect from layers (fire slash, hit impact, level-up aura)

How three served effects are built, so one of the same quality can be built without seeing them. Evidence: a demo built in Studio 0.747 on a grey daylight floor (`ClockTime` 14.5), 3-4 capture-and-fix rounds per effect, played and approved by the owner in Studio as the form to build in (2026-11-17), then ported unchanged and captured again. Numbers are read from the code: chosen by eye, not measured optima. No real phone, no published game, no frame-cost measurement.

Files: `scripts/fx_clock.luau` (the clock of section 3c), `scripts/fx_textures.luau`, `scripts/fire_slash.luau`, `scripts/hit_impact.luau`, `scripts/level_up_aura.luau`, `scripts/fx_capture.luau`, `scripts/fx_strip.py`; strips in `assets/vfx-examples/`. Copy the six `.luau` files as ModuleScripts of the same names into one folder (`ReplicatedStorage.Fx`) and require them from a LocalScript; `play(character or CFrame)` returns the clock (the hit also takes `{ direction = d }`). Client only; others' casts follow section 3b, Cost.

**Layer anatomy.** The fire slash has 9 layers, the hit 11, the level-up 9 (rows of the cards below; a ring's dark twin shares its row).

| Layer kind | Built with | What it adds |
|---|---|---|
| Motion | clock-posed part plus `IKControl`, or `Motor6D.C0` | the body sells the hit |
| White core | one soft glow, `LightEmission` 1, life 0.05-0.1 s | the contact frame |
| Body shape | ribbon of curved flat Beams (3c) or a camera-facing Beam | silhouette: crescent, ring, pillar |
| Hot edge | a thin ribbon on the outer rim, `LightEmission` 1 | bright reads bright next to the body |
| Dark underlayer | same shape wider, `LightEmission` 0, dark hue, `ZOffset` below | contrast on a lit floor |
| Texture detail | flipbook or textured particles along the shape | breaks a flat band |
| Streaks | streak texture, `VelocityParallel`, `Rotation` 90 | speed and direction |
| Stars and dots | short star pops | aftermath sparkle |
| Smoke | soft puff, normal blend, `ZOffset` -2 | the dark end of the value range, aftermath |
| Light | one `PointLight` pulse | the world answers |
| Sustain | clock streams that ramp in and out | a hold without a seam |

**Texture slots.** `fx_textures.luau` maps slots to ranked ids; each effect asks for a slot, never an id.

| Slot | The texture | Back | `LightEmission` | Id that rendered (source) |
|---|---|---|---|---|
| glow, band | white soft ball | alpha | any: 0 for dark layers | 3845808160 (docs custom particle effects tutorial) |
| flare | ring and rays (unused by the three) | black | 1 only | 8983307836 (docs core curriculum, basic visual effects) |
| smoke | soft grey puff | alpha | 0 | 16830673704 (docs volcano tutorial); 16830667309 (docs waterfall tutorial) |
| star | small spark | alpha (inferred: no box at 0.7) | 0.7-1 | 5833323391 (docs artist curriculum) |
| streak | long thin ember, long axis on X | black | 1 only | 17581858560 (docs volcano tutorial) |
| fire | explosion flipbook, 8x8, played OneShot | alpha | 0.35 | 17040521870 (free sheet, https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597) |
| electric | lightning bolt | not checked | 1 | 6101261905 (docs explosions tutorial) |

- Black or alpha decides the blend: a black-backed texture needs `LightEmission` 1 (the black disappears, docs); an alpha texture can take any value, so it can also be a dark layer.
- Status of these ids: every one rendered in Studio 0.747 Play (2026-11-17); none was checked in a published game. Three (16830673704, 16830667309, 17581858560) belong to the verified Roblox Resources group; the other docs ids and the flipbook are user uploads (economy API, read 2026-11-17), so they can change or vanish. A game moves to its own textures before release: put them first in each slot.
- Stages: **prototype** may use built-in `rbxasset://` textures, labelled greybox (the slot table's fallbacks; `allowBuiltins = false` drops them); **test** may use the public ids above; **release** uses the game's own uploads. Built-ins stay prototype only (house rule, section 3).

**Recipe card: fire slash** (`fire_slash.luau`). Beats: wind-up 0-0.12 s, swing 0.12-0.24 s (205 degrees, fast start), follow-through to 0.50, return to rest by 0.85, cleanup 1.30. Ribbons are 14 beams; each joint is born as the blade passes it and fades over its life, so the tail erodes first; widths taper to 0.35 at the ends.

| Layer | Type | Slot | Start s | Life s | Size studs | Colour (RGB) | LE | Count | Note |
|---|---|---|---|---|---|---|---|---|---|
| Swing | sword part + IKControl | - | 0 | 0.85 | blade 4.2 | - | - | - | pivot at right chest, tilt 55 degrees |
| Trail | ribbon | none | 0.12 | 0.08 | radius 3.6, width 2.6 | 255,150,50 to 200,60,20 | 0.6 | 1 | starts 70% transparent, `ZOffset` -0.6 |
| Dark under | ribbon | none | 0.12 | 0.20 | r 4.4, w 1.9 | 60,10,4 | 0 | 1 | 50% transparent, `ZOffset` -0.3 |
| Body | ribbon | none | 0.12 | 0.16 | r 4.4, w 1.4 | 255,225,120 to 255,110,25 (0.06 s) to 140,20,8 | 0.35 | 1 | `Brightness` 2 |
| Hot edge | ribbon | none | 0.12 | 0.12 | r 4.95, w 0.35 | 255,252,240 to 255,190,80 | 1 | 1 | `Brightness` 5 |
| Flames | emitter on a box moved with the blade | fire | 0.13 | 0.3-0.5 | 1 to 2.1 to 0.9 | 255,245,220 to 160,60,30 | 0.35 | 110/s to 0.27, 12/s to 0.33 | fade in over 12% of life, rise |
| Embers | emitter | glow | 0.20, 0.23 | 0.5-0.9 | 0.55 to 0.15 | 255,235,150 to 200,50,10 | 0.5 | 2 x 18 | from 3 points on the arc, 6-12 studs/s |
| Smoke | emitter | smoke | 0.26 | 0.7-1.0 | 1.4 to 3.4 | 55,40,35 to 95,90,85 | 0 | 6 | along the arc |
| Light | PointLight | - | 0.14 | to 0.50 | range 12 | 255,150,60 | - | 1 | peak 3.5 at 0.20 |

**Recipe card: hit impact** (`hit_impact.luau`). Beats: flash 0 s, core 0.017, sparks 0.033, ring 0.05, smoke 0.067, star pops 0.18, cleanup 1.0 (one 60 fps frame apart at the start). Flash, core, bolts, body and light sit 0.4 studs toward the attacker.

| Layer | Type | Slot | Start s | Life s | Size studs | Colour (RGB) | LE | Count | Note |
|---|---|---|---|---|---|---|---|---|---|
| Flash | emitter | glow | 0 | 0.05 | 1.5 to 3 | white | 1 | 1 | `Brightness` 5 |
| Dark under | emitter | glow | 0.017 | 0.16 | 3.5 to 6 | 10,28,70 | 0 | 1 | 45% transparent at start |
| Core stars | emitter | star | 0.017 | 0.12-0.15 | 1 to 2.6 to 0 | white to 110,200,255 to 40,105,255 | 1 | 2 | |
| Bolts | emitter | electric | 0.017 | 0.06-0.1 | 2.2 to 3.4 | white to 110,200,255 | 1 | 3 | accent, 3-6 frames |
| Blue body | emitter | glow | 0.017 | 0.16 | 2 to 5.5 | 40,105,255 | 0.5 | 1 | keeps the hit blue on a lit floor |
| Sparks | emitter | streak | 0.033 | 0.12-0.32 | 0.9 to 0.2 | white to cyan to blue | 1 | 22 | 25-45 studs/s toward the attacker, drag 8 |
| Ring + dark ring | 2 ribbons of 12, untextured | - | 0.05 | 0.21 | radius 0.5 to 3.4, width 0.9 to 0.12 | white to cyan; 10,28,70 | 0.8; 0 | 1 | faces between attacker and camera: never edge-on |
| Smoke | emitter | smoke | 0.067 | 0.5-0.8 | 1.4 to 4 | 55,65,85 to 100,108,120 | 0 | 6 | 3-7 studs/s |
| Star pops | emitter | star | 0.18 | 0.25-0.35 | 0 to 0.9 to 0 | white to cyan | 1 | 4 | |
| Light | PointLight | - | 0 | 0.2 | range 10 | 160,220,255 | - | 1 | 4 to 0 |
| Recoil | root `Motor6D.C0` | - | 0 | 0.4 | 9 degrees | - | - | - | peak at 0.05, springs back |

**Recipe card: level-up aura** (`level_up_aura.luau`). Phases: burst 0-0.75 s (ring, flash, pillar, stars), sustain 0.25-2.85 (rates ramp in over 0.2 s and out over 0.3 s), fade 2.8-3.3, cleanup 4.2. Follows the character every frame.

| Layer | Type | Slot | Start s | Life s | Size studs | Colour (RGB) | LE | Count | Note |
|---|---|---|---|---|---|---|---|---|---|
| Ground ring + dark ring | 2 flat ribbons of 16 | - | 0 | 0.4 | radius 0.8 to 6.5, width 1.4 to 0.15 | 255,253,240 to 255,190,50; 90,50,10 | 0.8; 0 | 1 | dark ring 1.7x wider |
| Core flash | emitter at the chest | glow | 0.03 | 0.1 | 1.2 to 3.5 to 2.5 | 255,235,150 | 1 | 1 | `Brightness` 5 |
| Pillar | camera-facing Beam, 0.9 below the feet to 13 above | band, Stretch, `TextureLength` 1 | 0.05 | 0.70 | width 0 to 5 (0.15 s) to 1.5 | 255,190,50 | 0.55 | 1 | fades from 0.3 s |
| Pillar core | camera-facing Beam | band | 0.05 | 0.40 | 0.35 x the pillar width | 255,253,240 | 1 | 1 | |
| Burst stars | emitter at the feet | star | 0.08 | 0.7-1.1 | 0.9 to 0 | 255,235,150 to 220,120,20 | 0.7 | 32 | 18-32 studs/s up a 22 degree cone, fall back |
| Risers | emitter on a 4.6-stud box at the feet | streak | 0.25 | 0.9-1.3 | 0.3 to 0.7 to 0 | pale to gold to amber | 1 | up to 26/s, about 60 | `Squash` 1.5, 5-9 studs/s |
| Glow column | emitter on a 3.4-stud box 1.8 up | glow | 0.25 | 0.9-1.2 | 2.4 to 3.6 | 255,190,50 | 0.6 | up to 7/s | 75% transparent at best |
| Ground circle + dark ring | 2 flat ribbons of 16 | - | 0.2 | to 3.3 | radius 2.2 to 3, 3.6 at the fade; width 0.45 | gold; 90,50,10 | 0.8; 0 | 1 | transparency pulses at 1.1 Hz; dark ring 0.95 wide |
| Light | PointLight at the chest | - | 0 | 3.3 | range 12 | 255,205,110 | - | 1 | 5 at 0.06, 1.8 sustain |

**Rings as broken arcs.** The two ring rows above are clean circles. In a later game the owner rejected a level-up's flat clean circles; what passed (field note, 2026-11-18; slow-motion Studio checks, no phone): 4-6 broken arcs with pointed ends, each with its own start angle, length (0.55-1.15 of its share of the turn), radius (0.95-1.05 x), life (0.65-1 x) and a turn of up to 0.8 rad/s as it runs out; a soft glow 1.5 x the width under a thin hot line 0.5 x, and no dark twin; low sparks thrown outward and motes rising off the front, about 20 + 7 per stud of final radius per second (at most 150). A camera-facing hit ring got the same treatment with four arcs.

**Measured while building** (Studio 0.747 Play, 2026-11-17):

| Fact | Consequence |
|---|---|
| Black-backed textures (17581858560, 8983307836) show grey bars below `LightEmission` 1 | black back: `LightEmission` 1, no exceptions |
| 17581858560 is long on X: under `VelocityParallel` at `Rotation` 0 every streak lay across its path | `Rotation` 90 for that sprite |
| `ContentProvider:PreloadAsync` reported Failure for ids that rendered | judge textures on a capture (`fx_capture.textureBoard`) |
| A beam with the soft circle at Wrap, `TextureLength` 0.05 showed moire stripes; Stretch, `TextureLength` 1 gave a soft pillar | ribbons untextured; one beam at Stretch 1 (3c saw an even band at Wrap 0.02: check a capture) |
| A `Disc` emitter shape emitted sideways | `Box` with `EmissionDirection` Top for risers |
| Glows over 4 studs swallowed a dummy seen from 20-25 studs (a 6-stud aura core did) | cores at 3-3.5 studs |
| On the daylight floor `LightEmission` 1 with `Brightness` 3+ washed to white (also the aura stars) | body layers at 0.5-0.7, `Brightness` 1.5 |
| `TimeScale` 0 plus the stopped clock held each beat for a late `screen_capture` (every frame of the strips) | freeze-frame capture works without slow-motion video |

**What looked wrong and what fixed it** (capture rounds of the demo):

| Looked wrong | Fix in the code |
|---|---|
| The slash read as a flat paper fan | joints born where the blade passes, tail erodes first |
| Flames appeared as red balls (frame 0 of the sheet) | flames fade in over the first 12% of life |
| Flames trailed into the follow-through and burned at the hip | main stream stops at 0.27, tail at 0.33 |
| Embers vanished (`VelocityParallel`), the additive streak was lost on the lit floor | soft alpha dots from three arc points, outward and up |
| The hit read white on the lit floor; the 4.5-stud flash hid the target | flash 3 studs plus a saturated blue body |
| The aura pillar looked like a striped slab | Stretch, `TextureLength` 1, one camera-facing beam |
| The sword snapped back to the hand on frozen frames (server-owned part moved on the client) | a local copy swings, the original hidden by `LocalTransparencyModifier` |

**Verify.** With every layer on the clock, `fx_capture.begin(tag, playFn, times, cameraCFrame)` freezes on the first beat; `screen_capture`, then `step()` to the next beat; `fx_strip.py` lays the frames in a grid. The strips used each script's `CAPTURE_TIMES` (12 beats), a fixed camera about 22 studs away at FOV 70 and two R15 dummies 7 studs apart. Start plays only from your own call and drop any frame with a play you did not start (a stray key press). Check on the strip: white core gone by about 0.07 s (3c); a dark layer under every bright one; the character readable at the contact frame; layer kinds at the peak against the 3c target (5 or more); nothing edge-on; smoke and stars outlast the bright layers. Peak live counts per cast: slash 3 emitters, 52 beams, 1 light; hit 8, 24, 1; aura 4, 66, 1.

**Known limits.** No mesh layers (the mesh path of section 3 is untested here). Embers are nearly invisible on the strip; flames still float above the arc early and linger on the hero to about 0.5 s. The hit smoke reads as a dark blob on the target, the white glow at 0.017-0.033 s covers its upper body, and the recoil is not visible at this distance. The aura core flash still hides the hero at 0.1 s and the sustain stars are thin. After `fire_slash` on a rig with no animation playing, the arm keeps the swing pose (the IK leaves `Motor6D.Transform` set); a character with its Animate script is reset by its idle. Section 5 budgets still decide.

## 3e. Skill cutscene from elements (camera, impact frames, energy, debris, lettering)

A flashy skill cutscene (a charged punch, 7.2 s) built from nine element modules on one clock. Evidence: a demo built in Studio 0.747 and 0.748 Play on R15 dummies over a grey tiled floor, 3-7 capture rounds per element; the owner judged the cutscene well made, camera moves and effects good (2026-11-18); ported to `scripts/` with the code unchanged apart from module names, an opt-in capture marker and `cine_stage.buildRigs`, and the port captured again in Studio 0.748 Play (2026-11-18: every element and the cutscene with no Output errors or warnings, the same flash log and live counts as the demo, the 3d effects run once on the merged clock). Target ranges ("clips") were read frame by frame from four public showcase clips at 30-60 fps (2026-11-17): a lead from four samples, not a norm. Our values were chosen by eye. No real phone, no published game, no frame-cost measurement.

Files: `scripts/skill_cutscene.luau` (the timeline), `cine_camera`, `impact_frames`, `flash_safety`, `screen_overlays`, `lightning`, `energy_sphere`, `ground_burst`, `ink_shapes`, `lettering`, `pose_beats`, plus `fx_clock`, `fx_textures`, `fx_capture` of 3d, `cine_stage` (palette, test stage, dummies) and `cine_demos` (one demo per element, setup in its header). Each module runs alone or, with `opts.clock` and `opts.at`, inside the cutscene clock. Comments r1-r4 name the capture round that found a problem. Strips: `assets/cutscene-examples/`.

**Anatomy** (ours in 60 fps frames in brackets; clip frame counts are at each clip's own rate, 30 or 60 fps):

| Beat | Time s | Ours | Clips |
|---|---|---|---|
| Build-up | 0-2.62 | low wide dolly 1.05 [63], then 3 close-ups of 30-33 f: fist, target face from below, over the shoulder; charge ball and crackle grow on the fist; letterbox and vignette in | 2-4 close-ups of 10-36 f |
| Dark beat | 2.62-3.12 | 0.5 [30]: world near black, silhouettes, only the energy glows; a glint grows on the fist over the last 7 f | 0.25-0.7 s |
| Impact block | 3.12-3.33 | 0.21 [13], 4 states of 3-4 f; the strike pose snaps in inside it (the move is never shown); the sphere bursts | 3-5 states, 0.15-0.25 s |
| Peak | 3.33-4.00 | 6 shots of 4-8 f, 8 cuts in 0.88 s (9.1 per s), 8 layers at 3.4 s, world kept dark | shots 1-8 f, 6-9 cuts per s, 5-6 layers |
| Hold | 4.00-6.60 | 2.6 [156]: one low wide, pull-out 18 f, finish pose, debris and dust; sphere pops at 4.64 into smoke and a second, smaller burst; lettering gone by 5.4 | 92-168 f, 1-3 layers |
| Hand-back | 6.60-7.20 | 0.6 ease to a view behind the player, letterbox out | - |

Peak position: block start at 43 % of 7.2 s, burst frames at 46-56 % (clips 30-75 %). Whole scene 12 cuts (1.7 per s; clips 0.5-3.2). One hue (electric cyan, `cine_stage` `HUE`) on a near-grey stage; clips used 1-2 hues on stages of saturation 0.05-0.10.

**Impact frame states** (`impact_frames.luau`; L is the screen value `flash_safety` counts):

| State | Built with | L |
|---|---|---|
| White / black | `ColorCorrectionEffect` under the Camera, `Brightness` +1 / -1 | 1 / 0.03 |
| Colour field, flat silhouettes | Neon plane 0.6 studs in front of the camera, re-placed every frame; `Highlight` per character, `DepthMode` AlwaysOnTop, fill only (cyan field + black figures, blue field + white figures) | 0.85 x field + 0.15 x figures |
| Invert | CC `Contrast` -2, `Saturation` -1, `Brightness` -0.15 | 0.45 |
| World desaturated, one hue kept | CC `Saturation` -1, `Contrast` 3; the kept subject's Highlight keeps its fill hue | 0.6 |
| Dark beat | `Lighting.Brightness` 0, ambients and fog to near black, `ExposureCompensation` -1.2 (fade-in 0.08 s); navy Highlights, Occluded; Neon, beams and additive particles keep glowing | 0.08 |
| White-out | CC `Brightness` +1 for 0.1 s, out-cubic decay over 0.17 s (10 f) | 1 |

The cutscene block: white 0.05, cyan field 0.05, invert 0.05, blue field 0.06 s; it hands over to a planned peak dim (the dark beat with no fade and no silhouettes, 3.33-4.00) so the peak cuts stay at one level. Failed: invert with a cyan tint read as a flat light-blue card; `Saturation` -1 alone turned the cyan Neon pink-white; `Brightness` +1 with a tint gave a flat field but tinted the figures too; a field plane 15 studs ahead was cut by the floor. Weakest: silhouettes are the blocky rig outline with no inner lines; the invert of a grey stage is mostly grey.

**Elements:**

| Element | Built with | Numbers | Failed, then | Weakest |
|---|---|---|---|---|
| Overlays | one ScreenGui `CineScreen` (`IgnoreGuiInset`, `ScreenInsets` None, `ZIndexBehavior` Sibling): letterbox Frames, 4 edge `UIGradient`s, speed lines = thin Frames rotated toward a focus with a transparency taper | bars 11 % of the height, in 0.25 s, out 0.3 s; 56 lines for 16 f, re-shaped every 1.5 f, clear radius 0.3 of the height, 1.5-6 px at 360 px high | white lines lost on the light floor: navy 1.5 px edge | uniform straight tapers |
| Lightning | midpoint-displaced polyline (depth 4-5, 1-3 branches at 25-45 deg); 3 untextured camera-facing Beams per segment: core (LE 1, `Brightness` 6), body 2.6x, halo 8x at 0.62 | bolt 0.1-0.12 s + restrike after 0.04 s; re-shaped every 1.5 f; ground strikes from 40-48 studs up with flash, 18 sparks, light; crackle bolts 2-6 f on the fist | pooled bolts hidden by an older timer: owner token | thin and pale on a light floor |
| Energy sphere | Neon core and body balls, 2 ForceField shells, 3 inner arcs, rim of 28 points plus 7 spikes in Beams, navy halo particle behind, light | charge 2.07 s at r 0.5 on the fist; burst to R 5.5 in 0.22 s (out-quart); hold 1.3 s; blink on 2 f, off 2 f; 16 smoke puffs | core 0.45r washed close shots white: 0.3r after the burst | rim reads beaded |
| Ground burst | flat ring + navy dark ring + upright wall (beam ribbons of 20); 9 slabs; 18 debris parts moved by the clock (gravity 120, bounce); dust particles; light | ring radius 1 to 13 in 0.32 s; debris 0.45-3 studs, life 70-120 f, shrink in the last 0.35 s; dust 30-70 f, 2.5 to 7 studs, `LightInfluence` 0; floor `Material` and `Color` by raycast | box pile and black dust ball: smaller pieces, lighter dust | plain boxes, darker than the floor |
| Ink shapes | triangles of two Neon WedgeParts each, laid in screen units on a camera-facing plane, re-laid every frame | 2-5 f; spikes behind the figures, smears and white shards in front; under about 35 % of the frame | shards behind were cut by the floor | straight edges |
| Lettering | TextLabel (`Bangers`, `TextScaled`), `UIStroke` 7 % of the height, white-cyan `UIGradient`, navy drop copy, `UIScale` pop | 0.14-0.23 of the screen height, tilt -12 / +9 deg; pop 1.25 to 1 in 2 f; jitter 0.4 % and 0.6 deg every frame; fade in 2 f, out 3 f; hold 1.6-2.06 s | opaque first frame; 1.6 deg jitter read as wobble | no inner white edge |
| Poses | `Motor6D.Transform` per frame from key poses (`snap`, `out`, `inout`), re-applied on PreSimulation | holds of 18-140 f; strike snaps in inside the block; knock-back 0.35 s | no posing on AnimationConstraint joints (facts) | rigid, no follow-through |

**Camera** (`cine_camera.luau`). One row per shot: `{ t, len, subject, from = { offset, look }, to, fov, roll, move = { t0, t1, ease }, shake = { amp, roll, len, step } }`, offsets in the subject's space; `cine_camera.anchor(part, root)` follows a head or fist without turning with it. Hard cuts only.

| Framing | Used | FOV |
|---|---|---|
| Low wide | camera about 0.6 studs over the floor, looking up | 50-62 |
| ECU face or fist | 2-3 studs from the part, often from below | 40-42 |
| Over the shoulder, medium side, reverse wide | 5-29 studs from the hero's root | 48-55 |

- Roll (dutch) -20 to +25 deg per shot, a new sign on most cuts (clips 8-25, up to about 30). Push-ins 12 and 10 f, pull-out 18 f (clips 4-18 f).
- Shake: rotation only, trauma squared over the shot, a new uniform random pose every 0.05 s (0.033 in the hold); peak shots 2.5-3 deg plus 10-12 deg roll, hold 1.2 deg plus 3 deg roll (clips: 5-10 % of the frame, roll swings every 2-4 f). Smooth noise used a third of its range (facts). Gameplay shakes keep section 3b.
- `CameraType` Scriptable and the `CFrame` are written every frame. Hand-back: 0.6 s ease to 12 studs behind the player's root, then `CameraType`, `CameraSubject` and `FieldOfView` restored from the values saved at the start.
- Phones: `GuiService.TouchControlsEnabled` false while it plays, restored at the end (the thumbstick and jump button sat over every shot). Skip, death exit and movement lock: `roblox-cinematics` sections 3a and 5.

**Safety** (`flash_safety.luau`). At most 3 screen-wide flashes in any second (WCAG 2.3.1, section 3b), counted and enforced in code: each screen-wide state asks with its L; a change of 0.2 or more is a transition, two opposite transitions are one flash; a state that would be the 4th in any 1.0 s of clock time is refused (the previous one stays) and a block drops states from its end until it fits. Counted: the states of the impact table and the end of the peak dim. Not counted: local glows, lettering, ink under about 35 % of the frame, hard cuts (so the peak stays dark across its cuts). Logged by the cutscene: flashes at 3.12, 3.17 and 4.00 s, max 3 per second. With `GuiService.ReducedMotionEnabled`: every block, dark beat and white-out becomes one soft dim (CC `Brightness` -0.25 in 0.08 s, back in about 0.3 s), no shake, no lettering jitter, speed lines drawn once. Gameplay flashes keep the 2-per-second limit of section 3b.

**Measured while building** (Studio 0.747 Play, 2026-11-18):

| Fact | Consequence |
|---|---|
| CC under the Camera recolours parts, particles, Neon, beams and BillboardGuis, not ScreenGuis and not Highlight fills | silhouettes and kept hues use Highlights; overlays and lettering stay black and white through every state |
| A Highlight with AlwaysOnTop draws through a part in front of the camera | field = Neon plane + Highlights |
| CC `Brightness` +1 / -1 gives pure white / black; `Contrast` -2 inverts (cyan to red-orange) | white, black and invert states |
| `Saturation` -1 turned cyan Neon pink-white; with `Contrast` 3 the world goes hard black and white and Highlights keep their hue | the one-hue-kept state |
| `Brightness` +1 with a cyan `TintColor` gives a flat field with no silhouettes | not used for fields |
| A Neon plane 15 studs ahead was cut by the floor in a low shot; 0.6 studs ahead covers the frame | plane at 0.6 |
| A dense Atmosphere fades distance to the sky's colour; legacy fog works only with no Atmosphere; `EnvironmentDiffuseScale` 0 removed the sky's blue tint on figures | grey stage: walls, ceiling and fog |
| Floor grout under 0.5 studs vanished 30-60 studs away in low wides | 0.5-stud grout |
| `CreateHumanoidModelFromDescription` rigs use AnimationConstraint joints: `Transform` writes do nothing, `C0` errors (read only) | `cine_stage.buildRigs` swaps them for Motor6Ds |
| A new ScreenGui's `ZIndexBehavior` is Global: a later layer drew over the letterbox | Sibling |
| `execute_luau` resets a changed camera to Custom | drive the camera every frame |
| Smooth `math.noise` at 0.05 s steps stayed within about +-0.3 of its range | stepped uniform random shake |
| Debris lit only by `Ambient` 110 went near black next to the same-coloured floor | Ambient 135, OutdoorAmbient 148 |
| Peak live counts: 10 emitters, 399 beams (most hidden pool beams), 5 lights, 152 parts, 4 Highlights, 68 GuiObjects | the phone risk is the beam pools |

**Verify.** `fx_capture.run(tag, play, times, { hold = 1.8, scale = 0.25, marker = true })` slows the clock to 0.25x and stops on each beat; a background capture of the Studio window saves a frame when the bottom-left marker shows the beat's index. Capture each shot boundary, the block and the peak as consecutive 60 fps frames (0.017 s apart), and the hold every 0.3-0.5 s, from the real cutscene camera, never a free camera; start every play from your own call. Check: each close-up shows its subject (not a shoulder, a body or the sphere from inside); the dark beat reads as silhouettes plus glow; every block state is full-screen; 5 or more layers at the peak; the hold has moving debris or dust to its end; the `CUTSCENE|flashes=...` line says max 3; camera, FOV and touch controls are back after the end; then one run in the Device Simulator (Galaxy A06, viewport 705 x 338): letterbox full width, lettering readable, no touch controls over a shot.

**Known limits.** Code poses are rigid (no follow-through or smear pose); debris are plain boxes; the sphere rim is beaded; ink edges are straight; silhouettes are the rig outline; R15 dummies limit every close-up (a face close-up reads as a dark block). 399 beams at the peak with no real-phone measurement. Elements and facts: Studio 0.747; cutscene and phone pass: 0.748; nothing checked in a published game or with several players. Uploaded art would raise it: drawn full-screen impact frames as ImageLabels, a spiky-ring texture or flipbook for the rim, a sphere mesh with scrolling noise, a bolt flipbook, 4-6 low-poly rock meshes and a crater decal, a dust flipbook, brush-stroke ink images, per-word lettering images with an inner edge, and keyframed attack and hit-reaction animations (`roblox-character-motion`).

## 3f. An effect built from a reference clip (formation seal, sky pillar)

Two served effects that were built by reading a reference clip of a similar effect frame by frame and rebuilding its timing and layer structure with our own shapes: a polygon seal with a floating orb (5.2 s) and a pillar that drops from the sky and holds (5.7 s). Nothing of the clips is used: no frame, texture or design. Evidence: built in Studio 0.748 Play, 3 capture-and-fix rounds for the seal and 2 for the pillar, then ported to `scripts/` with only the module names changed and captured again (2026-11-18: no Output errors or warnings; the seal's live counts matched the demo, the pillar peaked at 113 beams against 118 in the demo because its sashes re-form on a random timer); the owner compared the seal with a second build of the same clip and preferred this one. Numbers are read from the code: chosen by eye, not measured optima. No real phone, no published game, no frame-cost measurement.

Files: `scripts/fx_kit.luau`, `scripts/formation_seal.luau`, `scripts/void_pillar.luau`, on `scripts/fx_clock.luau` and `scripts/fx_textures.luau` (section 3d); strips in `assets/vfx-examples/`. Copy the five as ModuleScripts of the same names into one folder and require them from a LocalScript. `Formation.play(cframe, { sides = 3..6, hue, radius, hold, timeScale, reducedMotion })` and `VoidPillar.play(cframe, { hue, width, height, hold, timeScale, reducedMotion })` return the clock. Client only; others' casts follow section 3b, Cost.

**Reading the clip.** Do this before any code; it is the brief.

| Step | How | Output |
|---|---|---|
| 1. Beats | step the clip in 2-5 frame steps and write down every frame where something starts, peaks or ends | a beat table with times (the header of each script) |
| 2. Layers per beat | for each beat list what is on screen as shapes: line, crescent, disc, ring, pillar, wall, star, particle kind, light, screen grade | the layer list |
| 3. Sizes as ratios | measure against the effect's own radius or the character, never in pixels | orb diameter 0.74 of the radius, orb height 1.5, first orbit 0.42 |
| 4. Speeds | count frames per turn or per sweep | 1.5 turns/s on the inner orbit; an edge draws in 0.05 s |
| 5. Order | what leads what: the anticipation frame, the snap, what lingers | corner stars swell 0.1 s before the edges draw |
| 6. Build, freeze, compare | build on `fx_clock`, capture the same beat times with `fx_capture`, read your strip against your notes | 2-3 rounds |

Take timing, order and layer structure. Make the shapes, colours and textures your own.

**Seal anatomy** (beats in the script header): seed stars on the inner circle; one crescent per corner orbiting, with a thin dotted thread; the crescents spiral up into one spike with a flare; a wide soft flash from which the orb grows (overshoot 1.2, settled by 1.30 s); a blade per corner falls from the orb to its corner; a wind-up turn on the outer circle; corner stars swell (anticipation, 0.1 s); the edges draw corner to corner (0.05 s each, 0.015 s apart) with corner pillars, a tether and a floor fill; walls of rising cloud and flame wisps on every edge through the hold; release (the orb sinks and shrinks, walls fall) and a faint afterglow outline.

**Pillar anatomy:** a floor glow and a hair-thin flickering line (0.30 s of warning); the strike (one flash, the pillar's lower end travels from the sky to the floor in 0.05 s at 1.7 times its width); the sustain: nine camera-facing vertical beams (wide sheath with a rising scroll, soft glow, dark core, hot band beside the core, thin hot line, two electric skins), a floor disc, a shock ring every 0.42 s, flickering floor rays, seven broad sashes that spiral up around the base and re-form every 0.55-1.05 s (dark, glowing and streaked kinds), short lightning arcs re-rolled every 0.08 s, a horizontal lens streak, floor mist, dark shards, rising sparks, grey smoke behind; the collapse (the pillar thins to a line in 0.3 s, one last ring).

**Measured while building** (Studio 0.748 Play; each row cost a capture round):

| Fact | Consequence |
|---|---|
| `fx_clock:ribbon` curves each beam from its joints' X axes; a chain whose joints run head to tail while X is the travel direction kinked at every joint (crescents looked like armour plates, arcs like polygons) | X points from joint j to joint j+1: order the joints tail to head, or flip the tangent |
| A chain of additive beams shows a brighter seam at every joint | a crescent is ONE curved beam (`ribbon(1, ...)`, `Segments` 16) with the soft circle at `TextureMode.Stretch`, `TextureLength` 1; keep one arc under about 100 degrees |
| A Beam reads its `Transparency` sequence at the segment rows: with `Segments` 1 only the two ends count, so a ray with clear ends and an opaque middle was invisible | `Segments` at least the number of keys (10 for a 5-key ray) |
| The soft circle wrapped along a beam at 0.3 studs showed ladder stripes from 25 studs; at 0.05-0.07 studs it was an even soft-edged band on these captures (section 3d saw moire at 0.05 on another camera) | check the band on a capture at play distance |
| A star's long ray along world up leaned outward at the sides of a wide view | stars in screen space: rays along the camera's up and right (`fx_kit.glint`) |
| Upright wall strips with opaque tops read as blocks | fade every wall strip to transparency 1 at the top |
| The explosion flipbook tinted blue gave brown blotches (its own colours multiply) | flame wisps from the smoke slot, tinted, `Squash` 1.4, `LightEmission` 1 |
| A hard white Neon ball as the orb's centre read as a pasted-on dot; layers offset toward the camera drift apart off the screen centre | the centre is a soft camera-facing disc at the balls' own centre; concentric Parts for the body and shell |
| The first cast of a session drew squares for a few frames (textures not in memory); a 1 px ImageLabel plus a tiny Beam per texture at start made it rare, not zero | `fx_kit.warm()` at start; do not open a session with the hero effect |
| Removing the Sky brings the default skybox back above the haze | a far wall in the haze colour for a flat backdrop |

**Peak live counts** (`fx_capture`, per frame): seal 63 beams, 5 emitters, 9 parts, 2 lights at 3 sides (79, 95, 111 beams at 4, 5, 6 sides); pillar 113-118 beams over two runs, 4 emitters, 5 parts, 1 light; a 4-sided seal with `reducedMotion` 69 beams. Reduced motion: the seal drops the runners and the orb arcs; the pillar drops the white-out to a grade brightness of 0.12, halves the ring rate and runs 4 sashes and 2 arcs.

**Known limits.** No sound. The seal's fill shows faint wedge facets and its release is plain. The pillar's sashes are flat ribbons and read as paper from some angles; its strike is one full-screen flash (count it in the flash budget of section 3b). Six-sided seals and the pillar are over 100 beams: measure on a phone before shipping. The phone check is the Galaxy A06 Device Simulator preset only (viewport 705 x 338, same counts), run on the demo before the port.

## 3g. Fire and impact from small short-lived pieces (ground blast)

House rule (owner, 2026-11-18): every effect is built from small units, in size and in lifetime, even when that takes longer or is harder. This section is the method that reached that bar on one effect, an area explosion on the floor that leaves cracks and small fires (4.1 s).

Evidence: built in Studio 0.748 Play on 2026-11-18. Three earlier builds were rejected by the owner (stretched soft circles; flat drawn shapes; pale lumps with one whole-flame sprite standing alone). The fourth was rebuilt over 8 capture rounds, each read next to a reference clip of a similar effect at the same 16 beat times, then checked in real-time captures; the owner judged it good on its captures. Timing, layer order and staging come from the clip; every texture, mesh and shape was made for this build. Numbers are chosen by eye, not measured optima. No real phone, no published game, no frame-cost measurement. The effect was then ported to `scripts/` with the module and texture names changed and captured again the same day: the 16 beats match the demo's, no Output errors or warnings, nothing left in Workspace after the end.

Files: `scripts/ground_blast.luau` on `scripts/fx_clock.luau`, `scripts/fx_textures.luau` and `scripts/fx_kit.luau`; `scripts/ground_blast_textures.py` (the 15 textures; numpy, scipy, Pillow), `scripts/fx_own_textures.luau` (the ids table to fill), `scripts/ground_blast_swirl.py` (the swirl mesh, Blender headless); strips in `assets/vfx-examples/`. `GroundBlast.play(cframe, { hue, radius, timeScale, reducedMotion, seed })` returns the clock; call `GroundBlast.preload()` once first. Client only; others' casts follow section 3b, Cost.

Setup, once per game:

1. Run `ground_blast_textures.py <outDir> --preview` and look at `preview.jpg`: yellow only in the hottest parts, red at the rims.
2. Upload the PNG files as Images to the account or group that owns the game (asset uploads are permanent: ask the user first) and write the ids into `fx_own_textures`. No texture id ships with this skill, and there is no stand-in: while an id is missing `play` raises an error that lists the missing names (public textures stretched over these layers gave large one-colour shapes that read as pasted images).
3. Optional, the swirl as a mesh: run `ground_blast_swirl.py`, upload the FBX as a Model, and build the template its header describes (a MeshPart named Swirl in a folder FxMeshTemplates in ReplicatedStorage, with a SurfaceAppearance whose two maps are the `swirl_streaks` texture). Without the template streak beams draw the swirl.

**Six rules.**

| # | Rule | Without it |
|---|---|---|
| 1 | Colour bands come from one greyscale sprite: a wide luminance range in the texture, one deep saturated tint, `Brightness` 3-6 | flat single-colour shapes or pale yellow balls |
| 2 | The mass is layers, back to front: tinted smoke, banded fire lumps, tongues, thin hot crack lines, chips, embers, small black smoke bits | one layer of fire sprites reads as a cotton ball |
| 3 | Every piece lives 0.05-0.3 s and is replaced for as long as the effect burns | a sprite that stays for many frames reads as a slow, soft puff |
| 4 | No sprite is a picture of a whole thing. A flame is 5-8 tongue pieces alive at once; a dying fire shrinks and then stops | one sprite seen alone is a pasted image; fading by darkening leaves a flat dark cut-out |
| 5 | Judge on a dark stage that is not black; keep the mass low and wide; let the floor cut it straight | additive colour washes out on a bright floor; black smoke and the scorch vanish on a black one |
| 6 | Capture your build at the reference's beat times and read the two side by side every round | two builds made from text notes alone came out as a different look |

The same rules held in another game (field notes, 2026-11-18): a fan of spikes on a slam, first two hard beams per spike, read better (the owner's pick in a side-by-side) as 28 dashes and 16 points per spike, thrown fast out of the root and braking (`Drag` 7), so each spike is a spray of short lines that breaks into points. When the game caps particles per effect, give each piece a share of the cap: one boss hit of about 25 eruptions ran its three jets at shares of 0.34, 0.2 and 0.16, after a first build with full jets at nine points per lane starved every lane past the first.

**Colour bands from one sprite (measured).** `ParticleEmitter.Brightness` and `Beam.Brightness` scale the emitted colour before it is clipped per channel: shown = clip(tint x texture luminance x Brightness). With tint (1, 0.22, 0.03) and `Brightness` 4:

| Texture luminance | Shown |
|---|---|
| 1.0 | (1, 0.88, 0.12) yellow |
| 0.5 | (1, 0.44, 0.06) orange |
| 0.25 | (1, 0.22, 0.03) red-orange |
| 0.1 | (0.4, 0.09, 0.01) dark red |

- The texture decides where the bands sit; `Brightness` slides them. Animating it from 6 down to 2 took the same sprites from yellow-white to red.
- A sheet whose luminance is nearly even inside (0.6-1) turned into one flat yellow shape with a thin red rim at `Brightness` 4. The range has to be in the texture: about 0.08 at the cool rim, 1 only in the hottest patches.
- Tint for a hue h: `Color3.fromHSV(h - 0.037, 0.97, 1)`. Orange fire used h = 0.07; h = 0.75 gave violet with a pink inside (flatter: its second channel never rises).
- `LightEmission` 0.7-1 for fire, 0.3 for the tinted smoke behind it. Keep the tint's weakest channel near 0, or a stack of sprites goes white. Fully additive ribbons over a bright sky washed to white; 0.55 kept their colour.
- Two sprites in step (a body sheet and a core sheet) and a per-sprite colour sequence were both tried first and gave pale lumps.

**Layers** (R = effect radius, 8 studs in the build; rates are particles per second at the peak):

| Layer | Texture | Numbers |
|---|---|---|
| Swirl, 0.01-0.17 s | streaks on a swirl mesh (below) | 3 clones, each alive 0.12-0.15 s, 8-12 rad/s, tilted up to 20 degrees, growing 0.7 to 1.35 of its size |
| Flash, 0.12-0.27 s | one fan of 6 fat bent blades | a white fan over a tint fan at `Brightness` 6, on a soft glow; 0.7 R to 1.6 R tall |
| Fire lumps, 0.19-0.66 s | 4x4 flipbook from a fluid simulation | two box volumes (a low wide slab and a smaller crest): 60-90 per s, life 0.14-0.26 s, size 3.4 to 6 studs, `Brightness` 6 to 2 over 0.6 s |
| Tongues | 16 different single tongues, one random cell each | 46 per s, life 0.1-0.18 s, upright within 28 degrees |
| Red smoke | simulated smoke, tinted | 50-60 per s, life 0.22-0.4 s, transparency 0.45, `LightEmission` 0.3 |
| Crack lines, 0.3-1.0 s | 4 webs of thin broken lines | 50-60 per s, life 0.05-0.1 s, speed 0, inside the middle of the mass |
| Chips, 0.48-1.2 s | 4 scatters of small chips | 60-70 per s, life 0.06-0.13 s |
| Black smoke bits | simulated smoke, near black | 26 per s, life 0.28-0.5 s, size 1.1 to 2.1 studs, low round the foot |
| Embers | soft dot | size 0.2 down to 0.04 studs, tint to red, never white |
| Ejecta | soft trail | 4 arcs, one curved beam each: flight 0.48-0.58 s, apex 0.9-1.35 R, trail 0.28 s long, `Brightness` 2.2 |
| Small fires | the tongue sheet | 55 tongues per s per spot, life 0.1-0.2 s; the tongue size follows the spot's strength and the spot stops below 30 percent |
| Floor | scorch, forked radial cracks | crack `Brightness` 3.2 to 0.6 as it cools |

The mass is about 1.9 R wide and 0.8 R tall. A first version heaped 7-stud lumps into a ball as tall as it was wide and read as a balloon.

**Textures.**

- White on alpha, greyscale: luminance carries heat, alpha carries the shape.
- Fire and smoke flipbooks from a small 2D fluid simulation (stable fluids with vorticity confinement, 256 px cells): the lump rolls, splits into lobes and tears. Drawn or noise-built puffs kept one outline that only swelled.
- Start recording two frames into the simulation: the first frames are smooth round blobs and read as bubbles in the engine.
- Late frames lose area from their cool parts; they do not fade as a whole.
- A crisper alpha edge than a soft sheet (smoothstep 0.07 to 0.36 on density).
- Piece sheets hold different pieces, not an animation: `FlipbookMode` Loop, `FlipbookStartRandom` true, `FlipbookFramerate` 0 gave each particle one random cell.
- A preview that draws clip(tint x luminance x Brightness) over the stage colour shows a sheet's bands before any upload.

**A swirl as a mesh (measured).** The swirl is a band modelled in Blender that winds 290 degrees round the centre, flares and rises, with UV U across the band and V along the flow, uploaded as a Model and textured through a `SurfaceAppearance`.

| Question | Result |
|---|---|
| `MeshPart.TextureID` with an alpha texture | the alpha shows; `MeshPart.Color` does not tint it; `Neon` adds no glow |
| `SurfaceAppearance`, `AlphaMode` Transparency, part `Transparency` 0.02 | the alpha shows and `SurfaceAppearance.Color` tints |
| Glow | a textured mesh is drawn with the scene's light and looks dull; an emissive mask with `EmissiveStrength` makes it glow and bloom, and strength 8-12 pushed red toward orange-yellow, the same banding as `Brightness` |
| What the emissive mask reads | the colour channels, not alpha: with a white-RGB texture the whole surface glowed and the streaks merged into a solid bowl. The mesh texture carries the pattern in RGB too |
| Dark texels | a streak whose colour map was near black drew as a black band; luminance stays at 0.5 or more and the tail leaves through alpha |
| What a LocalScript may write | `Color`, `EmissiveStrength`, `EmissiveTint`, `AlphaMode`, part `Size`, `DoubleSided`, `TextureID`, and `AssetService:CreateMeshPartAsync` ran. `ColorMap` and `EmissiveMaskContent` failed with "lacking capability Plugin" |
| So | the maps go into a template in the place (set in Studio Edit mode) and the effect clones it and drives colour, strength, size and transparency |
| Pivot | the part's CFrame is its bounding-box centre; the swirl's axis is the template's `PivotOffset`. When scaling by `Size`, shift the part by minus `PivotOffset.Position` times the scale |

A `Texture` instance on a mesh: section 3h. Not tested: `Decal` instances on a mesh, UV scrolling on a mesh.

**Measured on the way** (Studio 0.748 Play):

| Fact | Consequence |
|---|---|
| `ParticleEmitter:Emit()` put its particles where the attachment was when the frame was drawn: several emits in one frame from one moving attachment all landed at its last position (a burst of lumps became one white ball) | emit from a Part volume, or one attachment per emitter and one emit per frame |
| A beam that was just switched on drew flat and untextured in one capture frame | keep it fully transparent for its first 0.025 s |
| The stage floor's Part colour (107, 115, 120) drew as about (38, 44, 62) under the dim stage light | set the floor from a screenshot, not from the colour picker |
| A paused-clock capture shows each beat exactly, but pieces looked longer-lived than in play | add a real-time burst of screenshots before judging lifetimes, and check that no piece is ever seen alone |

**Counts** (one cast): 19 beams, 21 emitters, 18 helper parts, 3 mesh parts, 1 light; with `reducedMotion` 17, 17, 14, 2, 1; nothing left in Workspace after the end. Live at once at the 16 beats of the served code: at most 15 beams and 21 emitters. A second hue, a 5-stud radius, and a cast without the mesh template ran.

**Known limits.** No sound. The swirl needs its own mesh upload and a template in the place. The violet variant is flatter than the orange one. The reference's first frame (a crown of blades and a ring wall) is only hinted. No phone preset and no frame cost were measured: the fire peak holds about 20 live sprites of 3-6 studs, which is fill rate (section 3, first bullet).

## 3h. A floor that breaks and smoke that erodes (ground slam)

Two things a ParticleEmitter and a Part cannot do by themselves: a smoke puff that keeps its place and is eaten away from inside, and a floor that breaks into slabs with no hole cut in it. This section is the method that gave both on one effect, a ground slam in white, grey and black (2.25 s).

Evidence: built in Studio 0.748 Play on 2026-11-18 next to a reference clip of a similar move, read frame by frame (timing, layer order and staging come from the clip; every texture and the slab kit were made for this build). Judged on real-time window captures: a paused clock does not show long-lived flipbook particles correctly. The owner watched it running in Studio and judged it good; the impact frame, spikes, shake and a reworked plume sheet were added after that. The code was then ported to `scripts/` and captured again the same day: no Output errors, nothing left in Workspace or Lighting after the end, the camera back in place. Numbers are chosen by eye. No real phone, no phone preset, no published game, no frame-cost measurement, flat floors only. Whether the clip's creator built it this way is not known: this is a method that reproduces the behaviour.

Files: `scripts/ground_slam.luau` on `scripts/fx_clock.luau` and `scripts/fx_textures.luau`; `scripts/ground_slam_textures.py` (the 5 smoke flipbooks; numpy, scipy, Pillow), `scripts/ground_slam_crater_kit.py` (the slab kit, Blender headless), `scripts/fx_own_textures.luau` (the ids table to fill); sheets in `assets/vfx-examples/`. `GroundSlam.play(cframe, { radius, timeScale, seed, ignore, layers, reducedMotion })` returns the clock; call `GroundSlam.preload()` once first. Client only; others' casts follow section 3b, Cost.

Setup, once per game (uploads are permanent: ask the user first):

1. Run `ground_slam_textures.py <outDir> --preview` and look at `preview.jpg`: whole clouds first, holes in the middle frames, thin curls last. Upload the five PNG files as Images to the account or group that owns the game and write the ids into `fx_own_textures`.
2. Run `ground_slam_crater_kit.py` in Blender, upload the FBX as a Model and build the template its header describes (a Model named CraterKit in a folder FxMeshTemplates in ReplicatedStorage).
3. No id and no mesh ships with this skill, and there is no stand-in: `play` raises an error that names what is missing, unless that layer is switched off (`layers = { smoke = false, haze = false }` or `{ crater = false }`).

**Smoke that erodes.**

| Part | How |
|---|---|
| Why a flipbook | `Transparency` fades a whole sprite; nothing on a ParticleEmitter opens holes in it. The dissolve is drawn into 16 frames played once over the particle's life (`FlipbookLayout` Grid4x4, `FlipbookMode` OneShot, `FlipbookBlendFrames` true) |
| Silhouette | a smooth union of 10-14 round lobes (p-norm of radial falloffs): one cloud outline with no inner outlines |
| Shading | the union's height lit from the upper left, darker low down and at the edge being eaten; greyscale, tinted by the emitter |
| Erosion | survival = a ridged smooth noise (high along closed curves), rank-normalised inside the silhouette; alpha = step(threshold, survival) and the threshold sweeps 0 to 1 from frame 3 to the last. The ridges last longest, so the puff ends as curls and rings |
| Cell edge | alpha fades to 0 before the cell border; a sheet that reached it drew hard rectangle edges |
| Emission | each puff is ONE particle on its own attachment, placed round a ring; `Speed` 9-30 with `Drag` 3.4-5.5 stops it within about 0.2 s, and from then on only the flipbook changes it |
| Layers | 9 dark puffs (size 4-7 studs, life 0.8-1.05 s), 4 plume particles straight up (7-12.5 studs, a taller sheet that thins from the top), 12 pale haze particles (7-14 studs, transparency 0.5-0.9, life 0.55-0.9 s) |
| Tint | mid greys (100-180) at `Transparency` 0.2-0.5, `LightEmission` 0, `LightInfluence` 0 |

These particles live 0.55-1.05 s, longer than the 0.05-0.3 s of section 3g. What changes every 0.05-0.07 s here is the flipbook frame, and the sheets are five different clouds (our reading of why it still passed, not an owner ruling); use it for smoke that has to keep its place, not for fire.

Failed first: lobes with thin outlines and hand-placed round holes read as soap bubbles; one emitter with a Disc shape put all 5-10 particles on one side in a cast; near-black tints stacked into one black mass; a plume built from three or four big lobes opened as plain balls until small lobes were added on their rims.

**A floor that breaks without a hole.**

| Part | How |
|---|---|
| Kit | one upload: a disc pre-broken into 76 convex slabs (Voronoi cells, small in the middle, larger outward, uneven sizes), each a MeshPart with its pivot on its top centroid; unit radius 1, scaled per cast |
| On the floor | slabs are cloned 0.03 studs above the floor with its `Color` and `Material` from a raycast: a flat slab cannot be told from the floor. A dark disc (36, 41, 56) under the tops shows through the gaps as crack lines |
| Zones | by distance from the centre in kit radii: under 0.34 a bowl (faces lean to the centre 10-26 degrees); to 0.95 a rim (inner edge up 10-24 degrees, less further out); beyond it flat, with about a third of the slabs tipping 3-7 degrees |
| Resting | a tilted slab is lifted by the drop of its low edge, so it rests on the floor instead of sinking into it; slabs that dipped under a black underlay left large black wedges |
| Walls | corner colours in the mesh (tops white, walls 0.5 down to 0.2) arrive with FBX `colors_type` SRGB and darken the walls without a second material |
| Timing | up in the impact frame: overshoot 1.3 in 0.04 s, settled 0.2 s later, 0.04 s later per kit radius outward; hold 1.7 s; flatten over 0.3 s; the crack lines fade over 0.15 s |
| Floor texture | if the floor Part has a `Texture` on its Top face, every slab gets a clone with its offsets set, and the pattern continues across the tops |

**Measured on the way** (Studio 0.748):

| Fact | Consequence |
|---|---|
| A `Texture` instance on a MeshPart is laid from the part's centre in studs: `StudsPerTileU/V` are honoured and the mesh UVs are not used; `OffsetStudsU/V` move its origin by that many studs along +X and +Z | per slab: offset = (floor half size - slab centre in the floor's space) mod `StudsPerTile` |
| A Part's Top-face `Texture` grid starts at the part's +X +Z corner | the same formula lines the slab up with the floor |
| Both checked with a symmetric 8-stud checker on an unrotated floor | a rotated floor or a texture that is not symmetric is not checked |
| Kit v1 had even cells and 0.25-0.5 stud gaps | it read as a football pattern with thick lines; v2 has uneven cells and 0.08-0.22 stud gaps |
| The first cast showed the dark disc for several frames before the slabs | `preload()` passes the kit to `ContentProvider:PreloadAsync` |
| A paused-clock capture showed 1 s flipbook particles about 60 percent through at clock age 1.35 s | judge flipbook smoke on real-time screenshots, or on a cast at `timeScale` 0.2 |

**Other layers** (each can be switched off through `layers`): a pillar flash (a thin white beam up for 0.1 s, a thinner one 0.1 s later), 7 tapered white spike beams for 0.09 s, a white line across the floor for 0.07 s, 5 wind arcs (curved beams whose ends ride a circle, 0.3-0.55 s each), an impact frame (a `ColorCorrectionEffect` at saturation -1 and contrast 0.85 for 0.05 s, back over 0.06 s) and a camera shake (0.2 s, at most 0.3 studs and 0.5 degrees, falling off). The impact frame is a full-screen flash and the shake moves the camera: `reducedMotion = true` skips both, and section 3b's rules apply (at most two flashes a second; only the player's own cast moves the camera).

**Counts** (one cast): 76 slab MeshParts for 2.25 s, moved with `PivotTo` every frame for about 0.3 s at the start and 0.3 s at the end; 22 emitters with 25 particles in total; 15 beams; 1 `ColorCorrectionEffect`.

**Known limits.** No sound. Flat floors only: the kit lies level at the raycast height, so slopes, steps and props inside the radius are not handled. The reference's white dome is not built. The slabs are thinner and the middle is shallower than in the reference. Building the slabs at run time as one EditableMesh was not tried (it needs the experience's mesh API setting). Frame cost on a phone is not measured: 76 moving MeshParts and 25 sprites of 4-14 studs.

## 4. Lighting and atmosphere (docs)

- Choosing a mood or an effect style: show the same spot in each option as an image (and a short clip only for motion) before building it (`roblox-game-pipeline` section 10a: greybox screenshots first, or images from a generator the user has connected).
- `Lighting.LightingStyle`: `Realistic` is the most advanced look, `Soft` is the flat retro look; pick with the style board lane (`roblox-game-pipeline` stage 3).
- Set colors on `Ambient`/`OutdoorAmbient`, intensity on `Brightness`/`ExposureCompensation`, time on `ClockTime`; `GlobalShadows` toggles shadows; `PrioritizeLightingQuality` decides whether quality or view distance scales down first on weak devices.
- `Atmosphere` adds haze and depth (density, offset, color); post effects (bloom, color correction, depth of field) in small amounts. Judge colors in Studio, not in renders.
- Bright daylight simulator look: `roblox-store-art-pack` section 1. Horror or night: lower brightness, fog and a few small lights instead of global brightness, except where the player must read the ground (next bullet).
- Space or night area the player must read: keep the black sky (`ClockTime` 0) and no haze over objects (`Atmosphere.Density` 0; the docs say Density does not directly affect the skybox) but do not dim the surfaces. Starting values from one test scene, not a docs rule: `Brightness` about 3 with mid-grey `Ambient` (RGB about 125) and `OutdoorAmbient` (RGB about 165) read well; `Brightness` 0.6 with a dark `Ambient` made the area one unreadable blob. `OutdoorAmbient` is clamped to at least `Ambient` in every channel (docs). Separate the surfaces by value too, not only by light: under an indigo night every mid-tone surface merged into one flat lavender until the floors went warm and light and the stage pads dark (field observation, 2026-11-04).
- **Night glow without lights.** Additive Beams (`LightEmission` 1) with the client's built-in radial texture `rbxasset://textures/shadowblurmask.png` made lamp pools, wet-road streaks and floodlight shafts with no lights and no parts, and they still showed at graphics quality 2 with the SpotLights off (field note, 2026-11-08; the texture is not documented, loaded in the Studio client only, and about 350 such beams were not measured for phone FPS). Measured in Studio by the same lane: a flat beam (`FaceCamera` false) spreads its width along the attachments' Y axis; the texture's U runs from Attachment0 to Attachment1; `TextureMode.Wrap` with `TextureLength` = 2 x the beam length puts the texture centre on Attachment1, so a ray is brightest at the lamp; `rbxasset://textures/gradient.png` fades along the beam, not across it, so its edges stay hard. Flat strips do not mirror: a concept's wet-road highlights that move with the view stayed out of reach.
- Small parts at night (field note, 2026-11-09): `ForceField` material on small crystals rendered almost invisible, and `Glass` and `SmoothPlastic` looked alike. `CorrodedMetal` showed bright orange rust under floodlights, even on near-black parts. Judge a material choice in the night lighting it will ship in.
- Dark palettes (field note, 2026-11-11): a dark albedo palette stays dark under any global light, and raising Ambient and Brightness alone turned the scene grey; lift the structure albedo first, then the light. At dusk the sky's environment light tinted surfaces grey-navy, and `Lighting.EnvironmentDiffuseScale` 0.2 kept them warm.
- **Endless spin with no Luau per frame:** one TweenService tween of a part's `CFrame` by the model's symmetry angle (90 degrees for a four-armed fan, 360/n for n arms, under 180 so the direction is unambiguous), `EasingStyle.Linear`, `RepeatCount` -1 (repeats indefinitely, docs), on the client. Each loop ends on a pose that looks the same as the start, so the spin reads as seamless (field note, 2026-11-09). A full 360-degree target would not work: it is the same CFrame as the start.
- A night `Atmosphere` rendered bluer than its `Color`: matching a violet-blue mockup sky took a Color leaned to violet (176, 120, 140 with Density 0.38 and Haze 2.4; field note, 2026-11-08).
- Bloom the owner called light bleeding everywhere: Intensity 0.8, Size 26, Threshold 1.15 with `Lighting.Brightness` 2.2 and Neon on every edge. Intensity 0.25, Size 10, Threshold 2, Brightness 1.2 and no Neon in the play area fixed it (field note, 2026-11-08).
- **Match a mood by numbers.** Shoot the concept's framing in-game, then measure both images per region (sky, walls, ground): luminance mean, p50 and p95, the share above 0.85 and below 0.1, and saturation. Set target ranges from the concept, change one group of values, re-shoot and re-measure until each region is inside. One game took a frame the owner called too bright and busy from mean luminance 0.41 with 9.9% highlights to 0.25 with 2.3% this way (field note, 2026-11-08). The user still gives the look verdict (`roblox-game-pipeline` section 0, rule 5).
- **World dim for a skill** (field notes, 2026-11-17, one game measured by eye in Studio): `Lighting.Brightness` at 60% of the day's value barely showed; 0.4 of it was the first share that read as dim, 0.25 as dusk, 0.15 as evening, and 0.1 hid the monsters. Ease every area toward one floor value instead of multiplying, or an already dim area goes black. Neon, and Beams and particles at `LightInfluence` 0, do not take the world light, so effects stay bright while the world dims. A grade that follows another starts from the current depth, or the world pops to full day for a frame; a dark grade tint turned the sky charcoal until the sky took the tint's hue at about 0.42 brightness.
- **Contrast clips.** A `ColorCorrectionEffect` with `Contrast` 0.25 and `Brightness` -0.04 crushed everything under about 0.1 luminance to black in one night scene; no contrast and `Saturation` -0.3 kept the darks readable (field note, 2026-11-15).
- **Indoor look.** Under an outdoor night set (`Ambient` 170, 195, 255 and haze density 0.7) a small room read evenly grey (luminance p50 0.078, p95 0.099). Tween `Ambient`, haze density and exposure to an indoor set (there `Ambient` 78, 92, 135, density 0.3, exposure 0.8, over 0.6 s) while the camera is inside the room's box and back outside, and light the room from its own sources (p95 0.23 after) (field note, 2026-11-16).
- **Big parts take local light coarsely.** One Part wider than about 160 studs is lit only coarsely by a `SpotLight` or `PointLight`: a flashlight 5 studs above a one-piece ground left it black while the fences beside it lit. Plates of 12-160 studs lit, 200 and 500 did not (Play, 2026-11-17). Build big floors and roads in tiles of 110 studs or less before blaming a light's range or brightness.
- **Local lights at night** (field notes, 2026-11-16): a lamp at `Brightness` 3 made no pool under a night exposure where a hand torch ran at 75, and about 45 worked; a glow part right under a lamp cast its shadow over the whole pool until its `CastShadow` was off; round-log walls leaked point light through their seams until each log row got a box core; and with no local-light shadows at low quality (`roblox-engine-2026` section 3) a room lamp with range 18 lit the outside of its wall, where 8.5 stayed in.
- **First-person flashlight.** A view model drawn life-size 5-6 studs in front of the eye puts the light inside near walls and the floor, and a hard wedge of light shows behind the hand. Sliding the light back toward the eye dragged the cone sprites over the hand, and a light at the eye burned the hand white. What held: draw the view model at 0.1 scale about the eye (the same picture) and keep the light at the lens; checked on a phone preset against a fence at 2 and 4 studs and the road at 7-70 degrees of pitch (field note, 2026-11-17).
- **Test plate for one lighting change.** To see what a single property does, shoot fixed objects instead of the map: a grey, a white and a black sphere, a white wall and a coloured wall, a pinned camera, the HUD hidden. Change one value per pair of captures and capture each state twice, so a difference between the two repeats shows how much is noise. In a real place, save the terrain under the plate with `Terrain:CopyRegion` and put it back with `Terrain:PasteRegion`, and remove the plate, so the place is left as found (method, judgment; not run by us). It explains a property; the region measurement above still decides whether the scene matches.

## 5. Budgets and checklist

| Check | Pass |
|---|---|
| Every frequent action has 2-channel feedback | yes |
| Every effect longer than a tick has a fun card (`roblox-fun-effects` section 1) | yes |
| Error cue differs from success cue | yes |
| Sound set under about 20 unique sounds for the first release (judgment) | yes |
| Emitter `Rate` low, bursts short, mobile cap known | yes |
| Action animations at `Action` priority or higher; tracks cached, not reloaded per use; NPC animations play from the server | yes |
| Screen shake has an off switch, combines by max, and only the object the camera follows (normally the player character) or the player's own actions move the camera | yes |
| Full-screen flashes and edge pulses start at most twice a second; Reduce Motion and the game's own switches are honoured (section 3b); a cutscene counts its flashes in code, at most 3 in any second (section 3e) | yes |
| Effects are built from small short-lived pieces: no sprite shows a whole flame or explosion, pieces live about 0.05-0.3 s, a real-time capture shows no piece alone, and no large shape is one flat colour (section 3g) | yes |
| The same 30 s played with all effects off, then on: every channel is missed when off | yes |
| Test on a low-end phone profile: FPS stable during the busiest effect moment | yes |
| Mute and volume settings exist; music loops without gaps | yes |
| Mood readable in the first screenshot (matches the style lane) | yes |
| The user played the busiest feel moment and the mix for 5+ minutes; notes in `docs/playtests.md` (`roblox-game-pipeline` section 7a) | yes |
