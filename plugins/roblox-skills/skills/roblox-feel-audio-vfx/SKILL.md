---
name: roblox-feel-audio-vfx
description: "Use when adding or tuning game feel in Roblox: particles, beams, trails, hit feedback, screen shake, FOV kicks, hit stop, screen flash and edge tint, vibration (haptics), coin fly-to-counter and other reward feedback layered per moment, in-game animation (Animator, priorities, animation events, emotes), lighting and atmosphere for mood, with mobile budgets and a checklist. Sound effects and music: roblox-audio. Also when a game feels flat or its effects feel simple, effects are invisible or too heavy on phones or look thin and cheap next to concept art, an animation does not play, replicate or gets overridden, lighting looks washed out or too dark (also a night area that reads as a dark blob), bloom bleeds light everywhere, a night scene needs glow under a light budget or must match a concept's mood, the camera swings or shakes until players feel dizzy, or when planning the 'feel' decision cards in roblox-game-pipeline stage 4."
last_reviewed: 2026-11-15
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
- Flipbooks (`ParticleEmitter.FlipbookLayout` 2x2, 4x4, 8x8 or `Custom` with `FlipbookSizeX`/`FlipbookSizeY`) cost texture memory, and clients switch them off when low on memory (docs), so an effect must still read without its flipbook. `ParticleEmitter.TimeScale` (0-1) slows or freezes an effect for a hit stop.
- Size particles for the real camera distance: 1-1.5 stud stars all but vanished 40-100 studs away, while 1.8-3 studs by tier read (field observation, 2026-11-04). Check in a screenshot from the player's camera, not up close.
- `ParticleEmitter.Size` is the width of each particle's square texture (docs). A shockwave ring texture ended about 1.05 x Size across, measured top-down against an 80-stud road (field note, 2026-11-11), so a splash ring of radius r needs an end Size of about 2r.
- The built-in `rbxasset://textures/particles/*` textures plus thin Trails read as a wireframe of lines on a dark sky next to concept art. A release-quality burst needs custom glow, star, streak and sparkle (flipbook) textures, dense emission along the shape, additive layers (`LightEmission` 1, `LightInfluence` 0) and a moderate `Bloom`. Dark semi-transparent layers over a night sky render brown and muddy; use fewer, brighter additive ones (field observations, 2026-11-04).
- Generated glow and energy sprites for additive use: ask for the sprite on pure black, not on a transparent background. With `LightEmission` 1 the dark regions of a texture disappear (docs), so the black needs no keying, and the soft falloff stays. A transparent background comes back as a cut-out: in one test image about 69% of the pixels were fully clear, the body almost opaque and the halo under alpha 32 of 255, so the glow lost its falloff (relayed by RoDesigner, 2026-11-14). Ask for transparency only for solid sprites with normal blend.
- House rule (owner): VFX are Blender meshes (`roblox-blender-export`) plus gradient or flipbook textures. No block tiles and no default sparkles (the `Sparkles` object or the built-in particle textures). A glowing Blender mesh without a `SurfaceAppearance` (field note, 2026-11-09): model the emissive shapes as their own geometry in flat `Neon` colors (Neon on a textured MeshPart does not glow, `roblox-pitfalls` section 4), layer a dark non-Neon shade mesh for the dark parts, and put textures only on lit surfaces. When a brief forbids uploads, a portal vortex that worked without them (field note, 2026-11-09) used flat curved Beams as spiral arms around a centre: `CurveSize0` and `CurveSize1` bend a beam into a Bezier curve (docs), `FaceCamera` is false, and the built-in glow texture is stretched along each arm (section 4, "Night glow without lights").
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
- **Ownership.** A feedback module tags what it creates (an attribute or a tag), saves a borrowed property's old value once, at the first change, removes only its own instances on stop and puts the saved values back. On start it sweeps what a crashed run left behind. Test it: an emitter, a `Beam` reference or an attribute that other code put on the same `Attachment` is still there after stop (judgment; the same first-save rule as the camera in `roblox-cinematics` section 5).
- **FOV has one owner.** Read the resting FOV only while no punch or held offset runs, and let other code change it through that owner. Two game sessions report that a kick still running when another script read "the base" became the new base (field notes, 2026-11-12, not re-tested here). Clamp the summed offset (10 degrees in the test place).
- **Hit stop has a budget:** at most 0.25 s of freeze in any second; cut a longer request. Count overlapping stops per animation track and restore the speed once. One tower-defence session ended at no stop for ordinary kills because a lane of small enemies stuttered (field note, 2026-11-12, not re-tested here).
- **Flashes.** Full-screen brightness changes stay under three per second: "no more than three general flashes and / or no more than three red flashes within any one-second period" (WCAG 2.3.1); Xbox Accessibility Guideline 118 counts a 10% luminance change as a flash and fails flashing over about 20% of the screen (both read 2026-11-12). The test place allows 2 starts per second across flash and edge tint, caps a flash at 0.5 opacity and drops the rest, so a pulse that repeats (low health) keeps its period near 1 s.
- **Motion options.** Xbox Accessibility Guideline 117 asks for a way to turn off camera shake, bob and motion blur (read 2026-11-12); `GuiService.ReducedMotionEnabled` is the Roblox Reduce Motion setting (docs). With reduced motion: no shake, kicks, FOV changes, blur, pops, flights or confetti; sound, colour, numbers and vibration stay. Give each channel its own switch in settings too.
- **Vibration.** `HapticEffect` runs on Android and iOS phones that support haptics, PlayStation and Xbox gamepads and Quest Touch; `Type` is `UIClick`, `UINotification`, `GameplayCollision`, `GameplayExplosion` or `Custom` with `SetWaveformKeys` (`FloatCurveKey` time in ms, value 0 to 1); the docs sample parents it to Workspace and plays it on the client; `HapticService` is the older API (docs, read 2026-11-10). The calls ran without errors in Studio, where nothing can be felt: tune strength on a real phone (not done).
- **Screen layers.** Flash, edge tint, letterbox, coin rain and speed lines live in a `ScreenInsets = None` ScreenGui (`roblox-ui-layout` section 3). Mark effect elements `KitTransient` so the device sweep leaves them out of the HUD budgets. Their text and tap targets still meet the phone floors at full size, and a `UIScale` on or under the marked root is the way to animate them (`roblox-ui-layout` section 4).
- **Streak sparks** are particles stretched along their velocity (`Orientation = VelocityParallel` with a positive `Squash`): a soft dot texture reads as a speed line. A ring that lies on the ground is one particle with `Orientation = VelocityPerpendicular`, emitted upward at almost no speed (tested in Studio, 2026-11-12).
- **Textures.** The test place ran on built-in textures so it needed no uploads. That is a prototype state: the house rule above holds, so a release uses the game's own star, soft glow, smoke, ring and soft-edged band textures.
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
| Full-screen flashes and edge pulses start at most twice a second; Reduce Motion and the game's own switches are honoured (section 3b) | yes |
| The same 30 s played with all effects off, then on: every channel is missed when off | yes |
| Test on a low-end phone profile: FPS stable during the busiest effect moment | yes |
| Mute and volume settings exist; music loops without gaps | yes |
| Mood readable in the first screenshot (matches the style lane) | yes |
| The user played the busiest feel moment and the mix for 5+ minutes; notes in `docs/playtests.md` (`roblox-game-pipeline` section 7a) | yes |
