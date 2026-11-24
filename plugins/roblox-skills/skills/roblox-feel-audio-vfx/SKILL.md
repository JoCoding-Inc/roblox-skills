---
name: roblox-feel-audio-vfx
description: "Use when adding or tuning game feel in Roblox: particles, beams, trails, hit feedback, screen shake, FOV kicks, hit stop, screen flash and edge tint, vibration (haptics), coin fly-to-counter and other reward feedback layered per moment, in-game animation (Animator, priorities, animation events, emotes), lighting and atmosphere for mood, with mobile budgets and a checklist. Sound effects and music: roblox-audio. Also when a game feels flat or its effects feel simple, effects are invisible or too heavy on phones or look thin and cheap next to concept art, an animation does not play, replicate or gets overridden, lighting looks washed out or too dark (also a night area that reads as a dark blob), bloom bleeds light everywhere, a night scene needs glow under a light budget or must match a concept's mood, the camera swings or shakes until players feel dizzy, when an effect needs a worked layer recipe (fire slash, hit impact, level-up aura), textures that work without uploads or a freeze-frame capture, when building a flashy skill cutscene (impact frames, dutch-angle shot list, lightning, energy sphere, debris, sound-effect lettering, flash cap), when rebuilding an effect from a reference clip (polygon seal with an orb, sky pillar), when fire or an explosion looks like pasted sprites or cotton balls, when a swirl should be a glowing mesh, when a fast sword cut's trail looks like a polygon, waves or a white blob, when something that flies (an arrow, a fireball, a magic bolt, a thrown item, something falling from the sky) needs a trail, a warning on the floor and an impact, when a trail breaks into dots at speed or an effect stays behind while its object moves, when an existing game needs a feel audit (every button, prompt, pickup, reward and refusal listed, scored and sorted by impact before anything is built), or when planning the 'feel' decision cards in roblox-game-pipeline stage 4."
last_reviewed: 2026-11-25
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
  - RoDesigner blade trail demo, 2026-11-20 (a dual-blade combo in Studio 0.748 Play; the band trail first built for a greatsword in another game of ours; judged in two blind rounds and approved by the owner on video; ported to scripts/ and run from per-frame records at 60 and 30 fps; interpolation errors and update cost measured in Studio against the demo's exact poses)
  - RoDesigner moving-things lab, 2026-11-20 (follow, path emission, density and travel added to the recipe module; a fall from the sky, a lob and an energy bolt in Studio 0.748 Play, slow-motion and frozen-frame captures, instance counts; not judged by the owner) and a smaller model's skill-effect build from this guide alone the same day (its report's guesses and defects feed section 3k)
  - RoDesigner comet trail lab, 2026-11-21 (a smaller model's meteor rebuilt in its own place with only the recipe module changed, sixty versions in Studio 0.748 Play at 0.25 speed, twenty-one blind rounds by a separate judge model on still frames aligned on the impact, and Neon colour swatches sampled from a screenshot; not judged by the owner)
  - RoDesigner reveal cutscene builds, 2026-11-21 to 2026-11-22 (one reveal brief built sixteen times by a smaller model from this guide, each judged blind against a VFX artist's posted cut by two judges a sitting; module changes checked on Studio 0.748 Play stills and recordings; the record is references/cutscene-builds.md)
  - RoDesigner strike flurry lab, 2026-11-25 (a punch flurry in Studio Play built by hand three times against a public showcase clip of a similar skill read frame by frame, numbers and method only; shapes painted in code into EditableImages, beams and particles; the third build's heavy contact called much better by the owner; engine probes of billboards, Highlight fills, emit placement and background frame rate; section 3m)
  - original (feel checklist and budgets are judgment, not measured)
  - original field notes (2026-10 to 2026-11)
---

# Game feel: audio, effects, lighting

Feel is what makes the same loop satisfying. Plan it as part of the loop (stage 4 "Feel" cards), then budget it for phones.

## 1. Feedback map (planning)

For each frequent action write what the player sees, hears and feels: action, result, reward, error. Example: tap to collect -> pop sound + number rising + currency counter bump. Every repeated action needs feedback in at least two channels (sight + sound). Errors need a different, clear cue (never the same as success). For any effect longer than a short tick (reveals, auras, celebrations, finishers), first fill the fun card in `roblox-fun-effects` section 1: what it rewards, who sees it, how it escalates. For a game that already exists, start from the audit in 1a.

## 1a. Feel audit of an existing game

For a game that already runs and "feels flat": find every place the player does or gets something, score what answers it, and fix the rows that cost the most first. A procedure (judgment: the order and the scores are ours). It was run once, read-only, on a live simulator of ours (2026-11-24: 106 rows; that run's notes changed the row kinds, the score scale and the checks below); nothing built from it has been judged yet. The layers, numbers and limits it points at are measured or sourced in their own sections. Change nothing during the audit, and stop for the owner's yes before building.

**Step 0: channels and cues, before any row.** Two passes that no single row shows:

- Channels: for each of sight on the UI, sight in the world, camera, sound, vibration, note whether the game uses it anywhere, and whether the player can reach the off switches (volume, reduce effects). A channel absent everywhere, or a switch with no UI, is its own line in the output.
- The sound map: each cue id against the number of different events that play it. A few cues carrying most of the rewards is a finding (`roblox-audio` section 1: one cue per event).

**Step 1: list every interaction.** Search the scripts and the UI; one row per place the player acts or receives:

| Kind | Where to look |
|---|---|
| Presses | every `TextButton` and `ImageButton` (`Activated`, `MouseButton1Click`), tabs, sliders, panels that open and close |
| World actions | `ProximityPrompt.Triggered`, `ClickDetector.MouseClick`, `Touched` on pickups and pads, `Tool.Activated`; gates and zones the server checks by position (no prompt and no `Touched`: search the server for distance and region checks) |
| Requests | every `RemoteEvent:FireServer` and `RemoteFunction:InvokeServer` on the client, and what the server answers with |
| Server events nobody pressed for | every event kind the server sends (`FireClient`, `FireAllClients`, replicated attributes and values) matched against the client's handlers: auto attacks, kills, drops, world events. An event kind with no listener is a score 0 row that no search for buttons finds |
| State edges with no input | a cooldown ending, a quest becoming ready, a timer running out, low health, a buff ending |
| Results | currency and XP changes, level-ups, unlocks, purchases, rolls and hatches, wins, damage taken, deaths, respawns |
| Refusals | not enough currency, a cooldown, a locked item, a full inventory: every `if not ... then return end` behind a press |
| Dropped presses | a press the client throws away inside a rate guard or debounce: it needs a queued press or a visible "busy" state, not a refusal cue |

Refusals are the row audits miss: a press that silently does nothing is the worst score in the table. Group identical controls (ten list buttons that share one handler) into one row with their count. UI still in the client whose opener is gone is listed once at the end as dead, not scored.

**Step 2: score each row** from what the code does now (file and line, the trigger, each channel that answers):

| Score | Means |
|---|---|
| 0 | nothing answers within 0.5 s, or the state just changes |
| 1 | one channel (a sound, or a number that changes) |
| 2a | sight and sound at once, but the same answer for every size of result |
| 2b | sight and sound sized to the result, but late: it waits for the server, or sits in a queue |
| 3 | sight and sound within a frame of the trigger and sized to the result |

- "Late" counts every source of delay, not only the server: a HUD message queue that shows toasts one after another, a typewriter gate, a tween that must finish first. For a row nobody pressed (a server event, a state edge) the trigger is the frame the client learns of it.
- A separate yes / no / n.a. column says whether the row has its own refusal cue (n.a. when it cannot be refused).
- A 3 read from code is provisional: "the layers are called" is not "it reads at the camera distance on a phone". Mark each row seen in Play or not; a 3 is final only after step 5.
- Per row also note how often it happens in 10 minutes of a named session (the first 10 minutes, a mid-game grind, one run of a mode), since a row can be constant in one mode and absent in another, and which tier it is (a tick, a reward, a rare moment: `roblox-fun-effects` section 3).

**Step 3: propose from what the guides already hold**, not from a blank page. A game that already has its own feedback module maps each row to that module's calls first; the kit calls below are in `scripts/window_kit.luau` of `roblox-ui-mobile` (served with its section 4), for a game that has none:

| Row | Use | Where |
|---|---|---|
| A button, a tab, a panel | press squash and rebound, the open and close order, the HUD that gives way | `roblox-ui-mobile` section 4 (`Kit.press`, `Kit.open`, `Kit.dock`) and 4a for measured timings |
| Currency or XP gained or spent | pieces that fly to the counter, a count-up, a "+N" at the counter, red for a spend | `Kit.fly`, `Kit.count`; a counter rises on every pickup (3b) |
| A refusal | a shake on the button and the `warn` colour on the counter, its own sound | `Kit.shake`; `error` and `not_enough` in `roblox-audio` section 1 |
| A hit, a pickup, a level-up, a heal, a spawn | a recipe, at the scale for the camera distance | 3i, 3k |
| A pickup or a chest waiting in the world | bob, spin and sparkle while idle; a burst and a ring on collect | the Pickup row of 3b |
| Loot that collects itself (an auto-collect grinder) | the flight is the pickup: orbs fly to the player and the counter takes one merged "+N" per 0.25 s | the Kill row of 3b |
| A hit taken or given, a kill, a dash | the layer table per moment: world, camera, screen, UI, sound | 3b |
| A server event or a state edge | a cue at the place the player is looking (the HUD element it changes, or the world spot), sized by tier; a ready state breathes until used | 3b; `roblox-ui-mobile` section 4a |
| A roll, a hatch, a crate, an unlock | a reveal sized by tier | `roblox-fun-effects` sections 3, 4 and 9; a cutscene for the top tier: 3e |
| A character action (collect, interact, swing) | an animation through the `Animator` at `Action` priority; flag every one that needs a new animation asset, because one the game's owner does not own does not load | 3a, `roblox-character-motion` |
| Any row that makes a sound | an event id in the sound map, a cue the game may play | `roblox-audio` sections 1 and 7 |

Size the answer to the row: something that happens every second gets a tick under 0.3 s and the smallest budget; camera kicks, hit stop and screen flashes are for the rows that happen a few times a session. For each proposal longer than a tick fill the fun card (`roblox-fun-effects` section 1); a row with no "Rewards" line stays a tick.

**Step 4: rules for the build.**

- Presentation only, on the client: no change to gameplay logic, remotes or saved data. The answer to a press starts on the press, before the server replies; when the server refuses, play the refusal and put the counter back.
- One feedback module that the other scripts call, which owns the camera's FOV and shake, tags what it creates and restores what it borrowed (the ownership, FOV and shake rules of 3b).
- Hover effects are for a mouse; a touch screen gets the press only.
- `GuiService.ReducedMotionEnabled` and the game's own "reduce effects" switch are honoured from the first build: no shake, kicks, flights or confetti with them on; sound, colour and numbers stay (3b).
- Full-screen flashes at most twice a second in play (3b). Shakes combine by max, never by sum (section 3).
- Sounds come from the licensed catalog or the owner's own uploads: an id the game may not play is silent in the live game (`roblox-audio` section 7).

**Output: the step 0 findings, then one table sorted by impact** (how often x how much it matters, highest first):

```
interaction | file:line | now (score, channels) | refusal cue y/n/n.a. | seen in Play y/n | per 10 min (which session) | tier | proposed (guide section or call) | files to change | effort S/M/L | new asset needed
```

Then stop. With the owner's yes, build the top five rows first.

**Step 5: verify what was built**, row by row:

- In Play on the smallest phone preset (`roblox-ui-mobile` section 1): each built row fired by hand, read on a recording or on per-frame state, since a screenshot arrives after a 0.3 s effect is over (3b, "Checking effects from an agent").
- The same 30 s with the module's "all effects off" switch off and on: a channel nobody misses comes out again.
- With Reduce Motion on: every row still answers in sound, colour and numbers.
- Count the busiest moment against the budgets (section 5), then score the rows again and put the new scores beside the old ones in the table. This is where a 3 becomes final.

## 2. Audio

Sound effects, music and ambience live in `roblox-audio`: event sound map, mix, buses and ducking, loops, Sound vs the Audio API, phone budgets, sourcing and rights, measuring. Give every feedback-map row that makes a sound an event id there.

## 3. Effects

- Before building any effect, read 3k: the bar every effect is judged by, which section fits it, sizes for the camera distance, budgets, and the defects that keep coming back.
- `ParticleEmitter`: one emitter makes up to 400 particles per second (100 on mobile) according to the docs; keep `Rate` low and `Lifetime` short. Particle size costs GPU fill rate, so many large overlapping particles hurt phones.
- Flipbooks (`ParticleEmitter.FlipbookLayout` 2x2, 4x4, 8x8 or `Custom` with `FlipbookSizeX`/`FlipbookSizeY`) cost texture memory, and clients switch them off when low on memory (docs), so an effect must still read without its flipbook. `ParticleEmitter.TimeScale` (0-1) slows or freezes an effect for a hit stop; at 0 it held particles still for a late screen capture (section 3d, measured 2026-11-17).
- **UI particles.** `ParticleEmitter2D` is a native 2D emitter for any `GuiObject`, a Studio beta since 2026-11-19 (DevForum t/4996850): places that use it cannot be published until Roblox ships it to the client. It mirrors `ParticleEmitter` with offset px as units (speed, acceleration, drag, spread, colour, transparency and size over the lifetime, squash, flipbooks, a 0-1 `TimeScale`), and a `Blend` from normal (0) to additive (1) takes the place of `LightEmission` (docs). Until it is live, UI bursts and sparkle stay pooled ImageLabels under the phone budget in `roblox-ui-mobile` section 4a, which lists its units, limits and defaults. With the beta off the class exists but draws nothing. With it on, `Emit(n)` drew nothing in our build, so a burst is a short `Rate` pulse; `roblox-ui-mobile` section 4a has the pulse, the spawn area, the angles and how `UIScale` acts (measured in Studio 0.748, 2026-11-20). Its cost on a phone is not measured.
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
| Kill | impact tier 3, ground ring, debris, coins and orbs that pop out, bounce and fly to the player | hit stop 0.08 s, trauma 0.6, FOV +4, screen flash at 0.16 opacity, kick 2 degrees | one "+N" per 0.25 s at the counter, count-up, counter pop, streak banner on the 2nd kill in 4 s | kill pop, coin tick one semitone up per coin; hit |
| Boss kill | dome, wide ground ring, impact tier 4, fireworks | letterbox, blur and FOV -7 during a 0.16 s stop, then trauma 0.9, FOV +7, screen flash at 0.35 opacity (on a lit floor; over a dark scene 0.15 at most, 3k), bloom, kick 4 degrees | banner slam, coin rain, confetti | layered boom; big |
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
- A `FaceCamera` beam turns to face the camera's position, not the screen, so a wide soft quad off to the side of the view reaches back by up to half its width. Soft clouds 26-42 studs wide on a backdrop plate 2 studs behind them were each cut along a straight vertical line where they went into the plate, and read as hard-edged panels; with the plate moved 12 studs further back the same frame showed whole soft clouds (Studio Play, 2026-11-22). Keep an opaque part behind soft quads by more than half their width.
- Fully additive warm beams (`LightEmission` 1) on a dark ground washed to cream; `LightEmission` 0.55-0.65 kept gold and orange saturated.
- A beam at `Brightness` 3 was visibly brighter than at 1 but bloomed weakly; particles with `LightEmission` 1 and `Brightness` 4 bloomed with a halo.
- An untextured `Neon` MeshPart crescent glowed strongly with bloom; a textured one rendered faint and did not glow (the same finding as section 3).

The attack motion under the effect (the body leads the arm, the blade lags and whips, each stroke starts where the last ended): `roblox-character-motion` section 2b.

Three worked effects built with this method, layer by layer, with served scripts and capture strips: section 3d. A trail for very fast cuts, a fan of bands built from the blade's own frames: section 3j.

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
- Look at a flipbook's first frames before using it: this explosion sheet opens on three frames of a smooth pink-red ball (frames 0-2 of 64, the first 5% of each particle's life), so every flame was born as a pink dot; with a white tint it read as a pink or magenta dot in the fire to two blind judges (Studio, 2026-11-21). Its slot carries `lead = 0.05`, and `fx_recipe` hides that share of each particle's life; for your own emitter, `emitter.Transparency = FxTextures.hideLead(emitter.Transparency, 0.05)`, or start its transparency at 1 as `fire_slash` does.
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

**Rings as broken arcs.** The two ring rows above are clean circles (`fx_recipe` draws broken arcs with a ring layer's `arcs`, 3i). In a later game the owner rejected a level-up's flat clean circles; what passed (field note, 2026-11-18; slow-motion Studio checks, no phone): 4-6 broken arcs with pointed ends, each with its own start angle, length (0.55-1.15 of its share of the turn), radius (0.95-1.05 x), life (0.65-1 x) and a turn of up to 0.8 rad/s as it runs out; a soft glow 1.5 x the width under a thin hot line 0.5 x, and no dark twin; low sparks thrown outward and motes rising off the front, about 20 + 7 per stud of final radius per second (at most 150). A camera-facing hit ring got the same treatment with four arcs.

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

Two kinds: a reveal (a rare roll, an unlock, 10-15 s: build order, rules and modules first, below) and a strike (a charged punch, 7.2 s: its anatomy, impact frames and elements at the end). Both run on one clock from the modules listed here.

Files: `scripts/skill_cutscene.luau` (the timeline), `cine_camera`, `impact_frames`, `flash_safety`, `screen_overlays`, `lightning`, `energy_sphere`, `ground_burst`, `ink_shapes`, `lettering`, `pose_beats`, plus `fx_clock`, `fx_textures`, `fx_capture` of 3d, `cine_stage` (palette, test stage, dummies) and `cine_demos` (one demo per element, setup in its header). Each module runs alone or, with `opts.clock` and `opts.at`, inside the cutscene clock. Comments r1-r4 name the capture round that found a problem. Strips: `assets/cutscene-examples/`.

**A reveal cutscene (a rare roll, an unlock, 10-15 s).** A reveal runs longer than the strike at the end of this section and travels. Sixteen builds of one reveal brief by a smaller model with this guide, each judged blind against a VFX artist's posted 15 s roll reveal (two judges a sitting), took it from 50 against 69 to 74 against 71 (sums out of 100; the table at the end of this part). The rules below are what those judges named, as they stand after the last build; the build-by-build record with the judges' words is `references/cutscene-builds.md`.

**Build order** (each step names its module; every module is in the file list above):

1. Write the shot list first, 12-14 s to full black: a dark start with two angles (0-1.2 s), a whip-out into the sky (a cut from the face to the widest shot), a travel of 3-4 shots that each step one thing up, a first burst, a mark at the middle, a peak of its own (1.2-1.5 s), the name, the fade. The artist's cut is the shape to beat:

| Shot | Time s | What |
|---|---|---|
| Dark start | 0-1.2 | black screen, one thin four-point star that grows, turns and changes hue (green, blue, violet); the odds counter already runs |
| Whip out | 1.2-2.1 | a cut to an extreme close-up of the face behind the star, then a fast pull-back into a wide sunset sky, the character spread out and small props drifting round it |
| Drift | 2.1-3.2 | two wide shots from above and beside, the character small, the camera turning |
| Energy arrives | 3.2-5.3 | ribbons with a star at the head come in one, then three, then four or five run parallel behind the flying character in a side shot, then wind round the body |
| First burst | 5.3-6.4 | crystal stars open beside the character, one white four-point flash that fills a third of the frame for 2 frames |
| Hover | 6.4-7.4 | a calm wide shot, the character glowing, small arcs round it |
| Bloom | 7.4-8.7 | crystal bursts open outward on turning ribbon arms, each bigger than the last |
| Peak | 8.8-10.7 | a full white frame, then a held close-up (1.6 s): the face ringed by crystal stars over a radial speed-line background, a slow push-in |
| Exit | 10.9-13.4 | a cut to a streak that shoots to the horizon, then a golden cross-star with thin rays and two rings over the sky; the counter lands on its last number about 1 s into this shot |
| Out | 13.6-14.2 | white-out, then a fade through grey |

2. The stage: `Sky.enter("void")` for the dark start, `sky:stage(character)`, `sky:sea()` once, `sky:drift()` for things between the lens and the horizon, `sky:portrait(character)` on the face in the dark (`cine_sky`).
3. The character: `PoseBeats.prepare(character)`, then every key of the scene in one `PoseBeats.play` with `sway` and `follow`; `PoseBeats.face(character)` for the expressions (`pose_beats`).
4. The camera: the shot list as a `CineCamera.play` table with the character (its root or head) as the subject (`cine_camera`). In Studio, `play` runs `CineCamera.audit` once per shot list and warns while it plays; fix every line before the first capture.
5. The shapes: recipes of `fx_recipe` (3i): `star_glint` in the dark, `trail_star` ribbons or `FxRecipe.orbit` comets on the travel, `shard_burst` for the middle mark, `FxRecipe.crown(3)`, `(6)`, `(12)` as the motif that grows, `reveal_star` behind the name. Pass `owner = clock` to each.
6. The peak: `sky:tunnel` and an `emblem` ring (the code at "A peak of its own" below).
7. The landing: `ScreenOverlays.counter`, `ScreenOverlays.title` and `ScreenOverlays.flash` on one beat; `ScreenOverlays.fade` for the way out (`screen_overlays`).
8. Sound: the `rare_reveal` cue of `roblox-audio` section 1. Skip: `roblox-cinematics` section 3a; `master:stop()` ends every effect and overlay made with `clock = master` or `owner = master`.
9. Check: record one whole cycle at 1x from a fresh start (lights and timing are wrong in slow motion), then read stills at every cut, the peak and the name; the rules below are the list.

**Rules.** "(audit)" marks what `CineCamera.audit` names before the run, "(run)" what `CineCamera` or `ScreenOverlays` warns while it plays; the rest is checked by eye.

*The character and its face*

- The character is in every shot: head, torso and hands not all out of the picture for 40% of a shot (run). A shot where it is under a tenth of the frame height lasts under a second; in travel it fills 15-35% of the frame height; a run of shots over 1.2 s under 25% is named (audit). A wide is 1 s or less or carries effects and movement.
- The head fills 40% of the frame height or less on every frame (run, with the distance to keep). Two close shots of 0.4-1.2 s with the head at 25-40%: the face reacting near the start (held about 0.8 s), and head and raised arms at the peak while the last digits run (audit names a list with none).
- The face shows in the shots that matter. A burst is shot from within about 60 degrees of the front (audit: over 110 degrees at both ends; run: a burst or the last shot that shows the face under 40% of its time, or the body over it). The first shot opens on the face, three-quarter front (audit: over 110 degrees round). A face close-up sits within about 10 degrees of eye level or above it (audit: from more than 15 degrees below), never looks down from more than about 50 degrees (audit) and never sees the crown (run). No shot shows the soles (run): a flying hero is shot from the front three-quarter or the side.
- An avatar's face reads only lit and at 25-40% of the frame: the `gaze` pose (chin up), the camera 5-8 studs away, `sky:portrait`; colour on the rim only, a neutral or warm key.
- Never the default pose: every held shot has an authored pose (an overshoot and settle of about 0.3 s, then a small idle); `fly` and `bank` alternate between the cuts of a flight. The opening reacts to the flares (surprise, a hand reaching up); one expression until the peak; the peak's first frame already smiles (change the face 0.1 s or more before the cut). The smile is spent once: the reaction close-up before the peak is not the name shot.

*The camera*

- Every held shot moves: a 5-10% push-in or a 10-15 degree orbit (audit: a shot over 0.5 s whose frame does not move; `hold = true` marks one held on purpose).
- The cold open has two angles cut at about 0.6 s: the face, then a closer face, the raised hand or the star (audit: an opening of 1 s or more in one framing).
- Cut from close to wide: the extreme close-up that whips out to the widest shot was the strongest cut of the artist's piece, and an over-the-shoulder whip-out into the sky was a judge's best transition (whip-outs are exempt from the burst-from-behind lines).
- A cut inside a travel changes the side by 60 degrees or more or the size by half, every 0.6-0.9 s, and steps one thing up: nearer, faster, more trails, a new colour (audit: a run of shots over 1.6 s from within 30 degrees at a like distance).
- The beat after a burst opens as close or closer and pushes in, with the pose still rising (audit: a pull-out over 8%, or a shot that opens more than 20% smaller than the burst ended).
- No setup holds the same face over about 0.8 s in the climb without a new event: split it, with a flare beat between.
- The sea is a floor to look across: the camera within about 15 degrees of level, the horizon in the frame. Keep the low sun behind the character or out of a calm shot (`Sky.enter` guards the bloom while the camera looks near the sun). A sky change on a cut is at once or under a flash (`sky:to` warns when it leaves `void` in under 0.6 s).

*The effects*

- Designed shapes, not soft dots: thin four-point stars, pointed crystals and shards, ribbons that taper to nothing with a star at the head, all from `fx_recipe`. A soft round sprite is a fill light behind a shape, under a fifth of what is on screen. No untextured particle (flat squares read as bare parts). Do not use the `star` slot of `fx_textures` for a designed star.
- The effects belong to the character: they arrive at it, run behind it, wind round it and open from it. An orbit passes beside the body and behind it, never between the lens and it; one to three ribbons with star heads, not five side by side.
- One motif that grows: `FxRecipe.crown(3)` at the first beat, `(6)` at the middle, `(12)` behind the name, in place of a different loose burst every time.
- One burst at one place at a time: 0.4 s and 3 studs apart, or one larger one; a burst over the body goes behind it (`depth = -(1.2 + scale)`). The burst under the name is the largest of the film; the earlier ones are 50-60% of it.
- Two palettes, one for the build and one for the peak, checked against the sky: a saturated one in travel (the pale `ice` and `holy` wash out on a sunset sky); white only for the heart of a shape. The colour story is carried by the effects, the rim light and the counter; keep the clouds in one family (no whole-sky tint).
- Never one flat colour over the whole frame for more than 2 frames. A flash is `ScreenOverlays.flash` (an exposure jump in the world, 2 frames, gone in 0.14 s), never a white cover of your own; at most 3 screen-wide flashes in any second (`flash_safety` counts them).
- Depth: two or three layers pass the camera at different speeds (near wisps or `sky:drift()` crystals, props, far clouds), each whole in the frame or not in it.

*The counter, the name and the way out*

- The counter never passes its last number: it reaches the last digits by the flash, ticks them, and lands with a punch.
- The number, the flash and the name are one beat, within 0.15 s of each other, on the cut out of the peak (run: `ScreenOverlays` names the gap and the nearest big flash). The name lands opaque on that first frame (`ScreenOverlays.title` lands by scale alone).
- The name shot is waist-up, the head at 20-25% of the frame, the raised hands inside the letterbox (audit: a last shot starting under 75% of the frame height; run: a raised hand outside the picture for 30% of the last shot). The name's lowest edge clears the top of the hair by 20 px or more (run).
- The name holds about 2 s (audit: a last shot under 2 s or over 2.9 s) with a slow push-in or a 10-15 degree orbit and one more pulse of the motif about 1 s in; end on that shot, no wider shot after it.
- Leave through a fade: `ScreenOverlays.fade` raises the black over 0.5 s with the bars, the name and the counter still on, and the game comes back under it. Count the runtime to full black against the brief. Nothing outlives the cutscene (`owner = clock`).
- Skip sits in the top bar at the right, inside the safe area; a vignette, if any, stays at `strength` 0.25 or under.

**Modules for a cutscene above the map** (Studio 0.748 Play captures with an avatar on the stage, 2026-11-21 and 22):

| Need | Module | Use |
|---|---|---|
| A sky with shapes | `cine_sky.luau` | `local sky = Sky.enter("sunset", { focus = root.Position })` lifts the stage 1,200 studs over the map (`sky.origin`); `sky:stage(character)` anchors the root, moves the character there and hides its ForceField, and `sky:leave()` puts all three back. Up there the engine's own cloud deck (a `Clouds` object, `Cover` 0.62, `Density` 0.8), a low sun (`ClockTime` 17.5) and an `Atmosphere` of `Density` 0.3 give cloud shapes with a lit and a shaded side, a horizon and a sun to frame against. Presets: `void` (the black start), `sunset`, `gold` (the peak), `day`, `night`. `sky:to(name, seconds)` crosses between two, `sky:wind({ dir, speed })` streams thin wind streaks past in a travel shot, `sky:leave()` puts the game's Lighting, Atmosphere, Sky, Clouds and post effects back. Measured: `Density` 0.42 with `Haze` 2.2 and a warm colour turned the same view into flat pink with teal patches, the look both judges marked down |
| A sea under the stage | `cine_sky.luau` | `sky:sea()`, once after `Sky.enter`: about 35 cloud towers with lilac feet and warm lit heads in three bands of distance over a floor in the shadow tone (`shade`, default the preset's `Atmosphere.Decay`; pick it off the hue of the hero effect: a violet floor swallowed a violet burst), about 1,600 particles, and a far bank of soft cloud 440-500 studs out that rises to about 10 degrees (1,160 more; `horizon = false` leaves it out) and covers the stepped slabs the engine's cloud deck draws near the horizon on low graphics (3k). It follows the preset, hides under `void` and is renewed by `Emit` every 18 s. `density = 0.5` halves the counts; the frame cost on a phone is not measured. `style = "clear"` lost to the default in both of its sittings |
| Depth | `cine_sky.luau` | `sky:drift()` floats clusters of crystals round the stage at three depths (14-40, 50-120 and 140-300 studs), lit on the sun's side, drawn with Beams, hazed with distance; `{ along = dir, length = 200 }` for a flight. A piece fades out inside 2 heights + 4 studs of the camera. The game's own props (coins, crates, the item) are better where it has them |
| Lights on the stage | `cine_sky.luau` | After the jump up there PointLights light nothing for 6.5-10 s (measured, below), so while a sky is entered every `fx_recipe` light is added to the ambient light for its frames (`Sky.enter(preset, { lights = "local" })` keeps PointLights). `local face = sky:portrait(character)` puts a warm key and two coloured rims on the head for a close-up in the dark (`face.stop(0.3)`; options `key`, `rim`, `rim2`, `strength`) |
| Poses | `pose_beats.luau` | `PoseBeats.prepare(character)` makes a live avatar posable (a Motor6D twin for every AnimationConstraint joint, the Animate script and playing tracks stopped) and returns the function that undoes it. `PoseBeats.POSES`: `stand`, `gaze`, `rise`, `fly`, `bank`, `coil`, `burst`, `hover`, `reach`, `hero`, `cheer`, `fall`; `PoseBeats.mirror(pose)` gives the other side. Key them (`{ t = 5.7, pose = "burst", ease = "outExpo" }`), pass `sway = 2.5` so a held pose breathes (in flight the legs kick and the arms trim) and `follow = 1` so the limbs arrive after the chest (each joint on a spring, looser down the limbs). One `play` with every key of the scene, or `keep = true` on each: between two plays without it the rig stood in its rest pose. Anchor the root and move it yourself |
| A face | `pose_beats.luau` | `local face = PoseBeats.face(character)`, `face.set("joy", 0.2)` at the peak, `face.stop()` on the way out. `PoseBeats.FACES`: `neutral`, `smile`, `joy`, `awe`, `grim`, `shut`. It writes `FaceControls` weights every frame; a classic head with a face decal has none (`face.has` is false) |
| A counter and a title | `screen_overlays.luau` | `ScreenOverlays.counter({ to, land })` climbs in log space, never passes its last value, holds five closing values over its last 0.9 s (`stretch`, `steps`) and lands white for two frames with a 1.2x punch and two glints (`flare = false`: none); it is 0.085 of the screen height, centred in the bottom bar, and pulses at each power of ten. `ScreenOverlays.title(name, { sub })` is opaque from its first frame, lands by scale (1.3 to 1) over a soft dark band (`band = false`), 0.1 of the screen height. Both warn when they land more than 0.15 s apart or away from a big flash |
| A flash | `screen_overlays.luau` | `ScreenOverlays.flash()`: an exposure jump in the world under a thin cover, under the bars, the counter and the title, 2 frames up and an ease-out fall, counted by `flash_safety` |
| A way out | `screen_overlays.luau` | `ScreenOverlays.fade({ onCovered })` raises the black over 0.5 s with the bars, the title and the counter kept on, calls `onCovered` (undo the pose, `sky:leave()`, give the camera back) and fades the game in over 0.45 s. Give the title and the counter a `dur` that ends when the black is full; it warns when either is already fading |
| Sharp shapes without uploads | `fx_recipe.luau` | The kind `spikes` draws pointed rays as tapered beams. `star_glint` (one four-point star that opens, turns and closes), `shard_burst` (12 pointed crystals thrown out of a star with one ring), `reveal_star` (level long arms, a cross, twelve thin rays of four lengths, a shockwave ring and an inner echo ring), `trail_star` (a tapering ribbon with a turning star at its head: play it on an invisible part you move, `{ follow = true }`), `FxRecipe.crown(count)` (crystals in a ring round the anchor, dealt one after another, a thin ring through their tails; it lies flat to the camera, so start it after the cut to the shot that shows it). A ray runs from a white heart to the palette's colour at its point over a wider rim in that colour; change it with `palette` |
| A peak of its own | `cine_sky.luau`, `fx_recipe.luau` | `sky:tunnel({ subject, dur = 1.3, owner = clock })` puts a dark plate behind the subject on the camera's line, with a pulsing core, 20 still rays, streaks and two layers of stars rushing out, soft clouds turning in two rings, all placed from the camera every frame; clouds, sea, drift and haze go while it runs. It leaves in a burst (the core swells to a white disc behind the hero) that asks `flash_safety` and fades instead when it would be a fourth flash in a second (`exit = "fade"` or `"cut"`); it ends on the first frame at or past its start plus `dur`. `FxRecipe.orbit(character, { recipe = "emblem", ... })` deals a ring of gold four-point stars round the hero; without `recipe`, comets: ribbons with a star at the head on rings that lean different ways and close in steps `every` 0.8 s (`wrap = true` keeps them in the body's own space so they wind round it). Phones: `count = 22` (frame cost not measured) |

The lab's peak shot (2026-11-22): the hero in the `hero` pose, the camera 12 studs above and 5 behind it turning 50 degrees round it, the ring filling about two thirds of the frame height:

```lua
-- one shot in the cutscene's list
{ t = peakAt, len = 1.3, subject = character, name = "peak",
	from = { offset = Vector3.new(0, 12, 5), look = Vector3.new(0, 0.5, 0) }, orbit = 50 },
-- on the cutscene's clock
clock:at(peakAt, function()
	sky:tunnel({ subject = character, dur = 1.3, owner = clock })
	FxRecipe.orbit(character, { recipe = "emblem", count = 9, dur = 1.3, turns = 0.12, tilt = 0, every = 0, r0 = 6, r1 = 5, palette = "gold", owner = clock })
end)
```

The burst out of the tunnel is one of the three flashes a second allows: land the counter and the name on it and leave `ScreenOverlays.flash` off its frames. Since build 16 the audit names this shot: it looks down from about 67 degrees, and a judge of that build, whose peak was shot from above, marked "the peak burst shot sees the top and back of the head; the face is hidden at the most important moment" and asked to aim it "at the character's front at chest height". A front peak is not built in the lab yet: the emblem ring lies level round the body (`tilt = 0`), so seen from chest height it is a line of stars edge on; lean it toward the camera with `tilt` and check the face and the ring on stills before using it.

**What the modules do for you** (Studio Play stills and recordings, 2026-11-21 and 22):

- A star is never bigger than the frame it is seen in: `FxRecipe.play` fits a recipe's stars, rings, bursts and trails to the camera every frame (`opts.fit`, default 2.6: the longest arm as a share of half the frame height at the anchor's depth; within 6 studs of the lens the share falls; `fit = false` turns it off). A trail is at most 8% of the frame height and goes out where it passes within 4 studs of the lens or runs near the line of sight. A gather sphere ends short of the lens.
- Shapes in the near part of the gap between the lens and the framed subject fade out (from a fifth of the gap, gone at 0.45: `FxClock.frontAt`), so an orbit shows its sides and far half in a close shot. Without `opts.depth`, an effect the camera sees in front of a kept-clear head goes behind it; `cine_camera` keeps the framed head clear (`shot.clear = false` for a shot that wants the cover; `FxRecipe.keepClear(part, radius)` for a camera of your own).
- `opts.owner = clock` stops an effect when that clock stops; an element without `at` starts at the clock's current time, and a past `at` warns (`FxClock.attach`). Clock events run at their scheduled time.
- Recipe lights are set for a body seen from 10 studs and more: next to a face in a close-up pass `{ light = 0.4 }` (0 for none).

**Lights after a jump** (measured 2026-11-21, a blank place, Studio Play, brightness read per frame from recordings). A builder's face "2 studs from the camera stayed dark brown with every point-light setting":

| What moved (camera, Focus, subject and lights together) | PointLights dark for |
|---|---|
| 40 or 80 studs up; 350 or 450 studs sideways | no gap |
| 200 studs up | 6.5 s |
| 300 studs up | 8.5 s |
| 900 studs sideways | 7.5 s |
| 1,200 studs up in 15 steps of 80 over 1.5 s | 10 s |

Then every light comes on in one frame; sun, ambient light and post effects are right from the first frame. One exception: with the camera within 8 studs of the subject and `Camera.Focus` within 3 studs of it, the lights drew at once at about two thirds of their later strength. A slow-motion check gives the lights real seconds to arrive, which is why it misjudged them. On a stage of your own, keep it within 80 studs of height and 450 of distance of where the camera was, move there 10 s early, or light the subject with ambient light and the sun. About 8 s after the entry `sky:portrait` gains about half again, so it is for the opening shots.

Found by a builder, not measured by us: a black void is `Atmosphere` `Density` 1 and `Offset` 1 with black colours, `ClockTime` 0 and `Lighting.Brightness` 0 (blank sky textures still drew the default sky); a `BillboardGui` drawn about 1,900 px wide did not render while 100 px ones did, so large flat shapes go in a `ScreenGui` placed with `WorldToViewportPoint` (or as `spikes`, which are beams); a `CanvasGroup` did not draw inside a `BillboardGui`.

**The builds** (the same brief; each sitting two judges, sums out of 100; build 11 was made while Studio was signed out, so the served textures drew nothing, and was not judged; the record of each sitting is `references/cutscene-builds.md`):

| Build | Score | Artist's cut | What decided it |
|---|---|---|---|
| 1 | 50 | 69 | level on structure and the counter; lost on the shapes of its effects (4 against 8 of 10), its last shot and its sky |
| 2 | 63 | 76 | the first rules; flat untextured particles, haze, a burst that blew the frame white |
| 3 | 58 | 68 | flat pink haze, a T-pose, soft spheres, the title 2 s before the counter: each became a module |
| 4 | 62 | 72 | sky, poses, faces, counter and fade named as strengths; soft round glows carried the start and end |
| 5 | 69 | 81 | `fx_recipe` and the audit used; effects almost all white |
| 6 | 65 | 77 | colours separated; a flat fog floor, flat cones, a blank white frame |
| 7 | 66 | 76 | lit face and designed shapes; a star across the face, ribbons as slabs |
| 8 | 60 | 71 | no close shot at all: the medium-close rule followed to the letter |
| 9 | 67 | 80 | face first, head and arms at the peak; a near-lens wedge, a flat peak star |
| 10 | 60 | 74 | ribbons crossed the lens; ended on a wider shot after the name |
| 12 | 61 | 78 | the peak tunnel; a black frame on a sky change, a dead shot after the burst |
| 13 | 76 | 72 | first build over the artist's cut (which a recording of a live game marks down for its HUD) |
| 14 | 73 | 72 | a ghosted title on the cut, a burst from behind, bursts all one size |
| 15 | 70 | 68 | black frames without the hero, the camera in the hair, a slack stretch before the burst |
| 16 | 74 | 71 | the peak seen from above, soles, the title over the hair, the landing 0.8 s after the flash |

**A strike cutscene (7.2 s).** A flashy skill cutscene (a charged punch, 7.2 s) built from nine element modules on one clock. Evidence: a demo built in Studio 0.747 and 0.748 Play on R15 dummies over a grey tiled floor, 3-7 capture rounds per element; the owner judged the cutscene well made, camera moves and effects good (2026-11-18); ported to `scripts/` with the code unchanged apart from module names, an opt-in capture marker and `cine_stage.buildRigs`, and the port captured again in Studio 0.748 Play (2026-11-18: every element and the cutscene with no Output errors or warnings, the same flash log and live counts as the demo, the 3d effects run once on the merged clock). Target ranges ("clips") were read frame by frame from four public showcase clips at 30-60 fps (2026-11-17): a lead from four samples, not a norm. Our values were chosen by eye. No real phone, no published game, no frame-cost measurement.

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

**Camera** (`cine_camera.luau`). One row per shot: `{ t, len, subject, from = { offset, look }, to, fov, roll, move = { t0, t1, ease }, shake = { amp, roll, len, step } }`, offsets in the subject's space; `cine_camera.anchor(part, root)` follows a head or fist without turning with it. Hard cuts only. It sets `Camera.Focus` to the shot's subject on every frame (a Scriptable camera does not move Focus by itself, and the engine draws local lights by their distance to it); a camera of your own must do the same.

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
| `ParticleEmitter:Emit()` put its particles where the attachment was when the frame was drawn: several emits in one frame from one moving attachment all landed at its last position (a burst of lumps became one white ball). Measured again on 2026-11-22: the same with a moved Part and with `Attachment.Position`; the pieces take the emitter's properties of that moment too (a `Lifetime` set right after `Emit` was the one they got); and a Studio window drew 15 frames a second while `Heartbeat` ran 60 times, so five emits on five `Heartbeat`s from one moving attachment landed at two places | `clock:emitAt(e, cf, count, props)` (`fx_clock`) gives each place in a step its own copy of the emitter, and `clock:stream`'s `before` uses it; or emit from a Part volume, or one attachment per emitter and one emit per drawn frame (`PreRender`, which the clock runs on) |
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

## 3i. An effect as a recipe (data, not code)

For the short effects a game needs in dozens: a hit per element, a pickup, a level-up, an aura, a ground hit, a heal, a spawn, a puff, an explosion. Each is a stack of a few bursts, streams, rings and one light, so it is written as a table and played by one module. Skill-size effects (2-4 s over 8-12 studs: a nova, a strike from the sky, a zone, an eruption) are recipes too, see "Skill-size recipes" below. Anything that flies or moves carries its effect with `follow` and `FxRecipe.travel`, see "Moving things" below. Slashes, a floor that breaks and cutscenes stay code (3d-3h). Read 3k first.

Files: `scripts/fx_recipe.luau` with `scripts/fx_clock.luau` and `scripts/fx_textures.luau`, copied as ModuleScripts into one folder. Call `FxRecipe.preload()` once on the client before the first cast (it yields while the textures load): without it the first cast of a meteor froze the client for about 1 s while its textures loaded (the 8x8 fire flipbook is the largest), then the flight jumped ahead and left a round blob where it started; with it the first cast ran smooth (2026-11-21). `FxRecipe.play("hit_fire", targetModel or impactCFrame, { scale = 1, direction = d })` returns the clock; a CFrame's LookVector is the direction the hit travels, and sparks fly back against it. `FxRecipe.play("aura", characterModel, { duration = 6 })` holds an aura for 6 s. Client only.

Evidence: `hit_electric` is `scripts/hit_impact.luau` (owner-approved form, 3d) as data: built side by side in Studio 0.748 Play on 2026-11-20, all 8 emitters matched on 19 properties and the beam and light counts matched. The six element hits were judged good by the owner at real speed in Studio on a desktop (2026-11-20). `hit_water` and the nine recipes that are not hits ran with no errors in Studio Play and were looked at frozen at 0.08, 0.3 and 0.7 s (`level_up`, `aura`, `heal` and `spawn_in` once more at 0.6 s after their streaks and dots were made smaller); the last size changes to `wisps`, `debris` and `embers` were not captured again, and the owner then watched them at real speed and called them good (2026-11-20). The four skill recipes ran with no errors in Studio 0.748 Play, were looked at frozen at 0.3, 0.62, 1.0, 1.2 and 1.6 s and seen running at real speed from 34 studs. The owner rejected the first pillar at real speed (a held beam read as a still picture); its hold was rebuilt from moving pieces and looked at frozen at 0.56, 1.0 and 1.35 s; the owner then watched it at real speed and called it fairly satisfying (2026-11-20). Nova, zone and eruption have no owner verdict yet. Nothing was checked on a phone or in a published game.

**Five layer kinds.** Sizes, speeds and radii are studs at scale 1; `opts.scale` multiplies them and leaves the times alone.

| Kind | Fields | Use |
|---|---|---|
| `burst` | `at`, `count`, `slot`, `where`, `life`, `size`, `alpha`, `color`, `emission`, `brightness`, `z`; motion: `speed`, `spread`, `drag`, `accel`, `rotSpeed`, `along`, `squash`; placing: `up` (studs above the anchor), `disc` {radius, partial} (emit from a flat disc: partial 1 fills it, 0 is the rim), `flat` (the particle lies on the floor) | Everything that appears at one moment |
| `stream` | the burst fields with `from`, `to`, `rate` in place of `at`, `count`; `to = "end"` runs until the effect ends; `settle` (0-1): new pieces leave slower toward the end of the span, down to that share of their speed, so a fountain sinks to its base as it dies | Embers, rising streaks, an aura: anything that keeps coming, ramped in and out |
| `ring` | `at`, `dur`, `r0`, `r1`, `w0`, `w1`, `segments`, `color` {from, to}, `twin`; `arcs = n` draws n broken arcs with pointed ends and soft edges instead of a clean circle (no twin; with `dur = "end"` every arc lasts until the arrival); `plane = "floor"` lays it flat, `y0`, `y1` move it up or down the body, `dur = "end"` with `r0 = r1` holds it | The shock ring with a dark twin under it, a floor ring, a ring that climbs the body |
| `light` | `at`, `dur`, `peak`, `range`, `up`; `hold = true` ramps in, holds and ramps out; `dur = "end"`; `shape` {{u, share of peak}, ...} any curve over its span; `flicker` (0-0.5) jitters it like a flame; `color` a key, or {{u, key}, ...} read over its span; `soft = true` makes it three lights at one point (ranges 0.4, 0.65 and 1 of `range`, brightness 0.55, 0.3 and 0.15 of `peak`), so a big light fades across a floor instead of drawing a flat oval (3k); `clear = true` on a light that rides ahead of a moving body dims it as it nears a surface below or ahead of it and puts it out when it gets there ("Moving things") | One PointLight (three with `soft`): a pulse, held for an aura, or a firelight that flares and cools |
| `column` | `at`, `dur`, `y0`, `y1`, `w0`, `w1`, `color` {from, to}, `alpha`, `slot` (`band` soft beam, `electric` or `smoke` with `length` and `speed` for a moving skin); `hold = true` opens, holds its width and closes by narrowing; `flicker` (0-0.5) jitters the width; `drop` (seconds) brings the lower end down from the top | One camera-facing vertical beam: without `hold` it widens and fades (a strike). Keep a held one thin: it is a still picture |
| `helix` | `at`, `dur`, `r`, `y0`, `y1`, `turns`, `w`, `spin` (turns per second; negative travels down), `phase` (0-1), `segments`, `color` {from, to}, `alpha` | A band wound around the vertical axis that keeps turning: the motion of anything that holds (a column, a charge) |
| `spikes` | `at`, `dur`, `arms`, `len`, `w` (width at the centre), `long` ({1, 0.42}: arm lengths in turn), `turn` (deg), `spin` (deg per s), `jitter`, `vary`, `stagger`, `fly` (the arm leaves the centre and travels that many lengths), `open`, `close` (shares of its span), `plane` ("floor"), `color` {from, to}, `up` | Pointed rays out of one centre, each a camera-facing beam that tapers from `w` to nothing: 4 arms with `long` {1, 0.42} draw a four-point star, 10-16 with `jitter` and `fly` a burst of shards. A drawn shape, no texture; it opens fast, holds and closes by shrinking |
| `tail` | `at`, `to` (s or "end"), `w`, `life` (seconds of path kept), `taper`, `segments`, `color` {head, end}, `alpha`, `up` | A ribbon along the path a followed anchor flew (`opts.follow`), full width at the head and tapering to nothing, on the effect's clock (a `Trail` runs in real time and cannot be frozen or slowed with the rest) |

Every kind also takes `times` and `every`: the layer plays `times` times, `every` seconds apart (`times = "end"` repeats until the effect ends). A layer keeps one start, `from` for a stream and `at` for every other kind: a template called with another `kind` (`L.debris({ kind = "stream", from = 0.5, ... })`) drops the start it does not use, so code that cuts or shifts a recipe can read `l.from or l.at`. A burst or stream also takes `tube = {radius, height}` (born anywhere in a box that tall above the anchor: the inside of a column) and `gather = radius` (emitted on a sphere of that radius and thrown at its centre: a charge; give it a speed of about radius / life) and `dir = "down"` (thrown down: rain inside a column).

**Anchor** (`recipe.anchor`): `"hit"` (default) is the contact point, and sparks go back at the attacker; `"up"` is the same point with world up as the spray direction (pickups, puffs, explosions); `"feet"` is the floor under a model, or the CFrame's position (auras, level-ups, ground hits, heals); `"trail"` sprays back along the motion (trails, see "Moving things"). `opts.duration` replaces the recipe's duration, which is how long an aura holds. The target may be a character model, a CFrame, or a part, an attachment or another model (its own frame; a hit travels into its front unless `opts.direction` says otherwise).

**Shipped recipes.**

| Recipe | Anchor | Palette | What plays | Length |
|---|---|---|---|---|
| `hit_electric`, `hit_fire`, `hit_ice`, `hit_holy`, `hit_shadow`, `hit_poison`, `hit_water` | hit | its element | the contact frame, a core, one colour mass, sparks, a ring, the element's accent | 1.0-1.1 s |
| `pickup` | up | gold | a small pop, a fountain of sparks that fall back, a thin ring, stars | 0.8 s |
| `level_up` | feet | holy | a floor ring, a column of light, two rings that climb the body, rising streaks, stars at the top | 1.7 s |
| `aura` | feet | electric | a floor pulse, a held floor ring, rising streaks and drifting dots for as long as `opts.duration` | 3 s by default |
| `ground_hit` | feet | earth | a flash, a dark mark on the floor, a wide floor ring, dust along the floor, chips that fall back | 1.2 s |
| `heal` | feet | heal | no white flash: slow rings up the body, slow streaks, drifting dots | 1.6 s |
| `spawn_in` | feet | electric | a column, a ring that scans down the body, then a floor ring and sparks | 1.0 s |
| `poof` | up | shadow | a puff of smoke every way, a small flash, a few stars | 1.1 s |
| `explosion` | up | fire | a big flash, a fireball flipbook, sparks every way, a wide ring, heavy smoke, embers | 1.5 s |

Any recipe plays in any palette: `FxRecipe.play("aura", model, { palette = "fire" })`.

**Skill-size recipes** (anchor feet; pass the caster's model or a floor CFrame). Each has three parts: a tell the player can read (0.4-0.55 s: a closing ring, a thin line, embers), a release, and a tail made of streams.

| Recipe | Palette | Tell | Release | Tail | Length | Counted in Studio |
|---|---|---|---|---|---|---|
| `skill_nova` | electric | streaks gather to chest height, a ring closes from 10 studs | flash, big bolts, three floor rings to 12 studs, 44 sparks every way | bolts crackle over an 8-stud disc, two smaller aftershocks | 2.4 s | 15 emitters, 176 beams, 3 lights |
| `skill_pillar` | holy | a thin line from the sky, a 5-stud mark, a closing ring | a beam slams down (0.3 s), two floor rings, chips | a column made of moving pieces: two bands wound around it that keep turning, a thin core that flickers, soft pieces and streaks falling inside it, a ring travelling down every 0.2 s, a splash at the base; then two rings that climb | 2.7 s | 13 emitters, 316 beams, 2 lights |
| `skill_zone` | poison | none: it opens at once | a ring out to 8 studs | a held border, a pulse ring every 0.6 s, patches, dots and streaks all over the disc, for as long as `opts.duration` | 4 s by default | 8 emitters, 180 beams, 1 light |
| `skill_eruption` | fire | the floor glows and spits embers, a ring closes from 7 studs | a small flash that turns from white to `hot`, white-hot stars, a hot spot on the floor that flares on the same frame and drops to a flicker, sparks on the flash's own frame that are gone in 0.14 s, fire lumps thrown over the upper half only, 26 hot chips as glowing dots thrown 10+ studs up in a wide cone, dust thrown out along the floor; no floor rings, floor glow or scorch, the floor's answer is the lights, `soft` | a fountain of small fire lumps about 10 studs tall that spits glowing chips and sinks to its base before it stops (`settle`), a bed of low, slow flames that outlasts it, embers as small round dots, an amber light that cools and goes out with the last flames, coals lying level on the floor (wider than tall) that cool from `mid` to `deep` and go out one by one until about 3.4 s after the release, the hot spot cooling to `deep` over 3.2 s, a thin plume that slows | 3.9 s | 15 emitters, 16 beams, 8 lights (7 lit at once at 0.6-0.8 s) |

Rules found while building them (2026-11-20, judgment from frozen frames):
- Size comes from count, radius and time, not from bigger pieces: every piece keeps its 0.06-0.35 s life and its small size, and the rates go up 2-4 times (a crackle at 60 per second, rising streaks at 90-110 per second). A first pass with hit-size rates left the tails nearly empty.
- A long effect is several short ones in a row: repeat rings and small bursts with `times` and `every` (aftershocks 0.4 s apart, pulse rings 0.3-0.6 s apart) instead of stretching one layer.
- Nothing that holds may be a still picture. The first pillar held a 2.2-stud beam with a white inner beam and an `electric` skin for 1.3 s, and the owner rejected it at real speed: a picture pasted on, with no motion for the length of the effect (2026-11-20). The rebuilt hold has no held beam wider than 0.5 studs: two `helix` bands that turn at 1.6 turns a second (the stripes read as travelling down), a third thin band turning the other way, `glowfall` pieces that live 0.12-0.2 s, streaks born at every height, rings that travel down the column every 0.2 s, and a core line 0.5 studs wide whose width flickers. Ask of every layer that lasts over 0.3 s: what moves in it?
- Keep a strike brief and let it arrive: its lower end comes down from the sky in 0.06 s, it is 3.2 studs wide at most and gone in 0.3 s, with a burst of `glowfall` pieces as its body. A 7-stud beam read as a flat white slab.
- A fire that ends sinks first: its fountain's new pieces leave slower as it dies (`settle`), and a bed of low, slow flames on the floor, from half the fountain's run to 0.6 s after it, is the last fire seen (same rule as 3g).
- Keep dark smoke thin at this size (5-6 puffs per second, at least half transparent): ten opaque puffs read as one black mass.
- The floor answers the release on its own frame, and its light is the fire's colour and size (`skill_eruption` at `scale` 2 on a dark dusk floor, slow motion at 0.25, two blind judges per round, 2026-11-21). The lights in the palette's pale `light` read as sand under a stage spotlight; in `mid` at the same range as red paint four times the fire's width; in `mid` at 0.55 of the range, with the flash cut from 9 to 4 studs and lifted to `up` 2, as a soft glow round the fire (sums of two judges: 74, against 60 and 53). Then a `hot` contact light for 0.15 s and the floor glow on the flash's frame, with three white-hot `core` stars: 71 against 65, the floor no longer dark under a white ball on the contact frame. The fire layers at `emission` 1 instead of 0.7 on top: 76, measured brighter with half the brown pixels (at 0.7 its lumps read crimson and muddy under brown caps). On a bright day keep fire at 0.4-0.5 (3k). Still named then: the floor light a flat red disc that does not flicker, the chips thin straight streaks, a white ball on the contact frame.
- Light that lives with the fire, and an arrival that clears the sky (same stage and method, two more rounds, 2026-11-21). The changes to the build above: the trail's fire layers go out from the tip toward the impact on arrival (`cut`, "Moving things"); the flash 3 studs wide at its widest, white for half its life, then `hot`; the short contact light became a hot spot (`shape` flares to its peak on the contact frame and drops to a tenth within 0.13 s, `flicker` 0.35, `color` from `hot` to `mid` as it dies); the light over the fountain fades out with the last flames and cools from `hot` to `mid` (`ramp`, `flicker` 0.15); the embers end with the flames; the floor rings `hot` to `mid` with no dark twin. Sums of two judges: 69 against 49 for the build above. What they named in the build above and not in this one: the tail still standing in the sky into the fire 0.25-0.4 s after the impact, the rings' dark band reading as a target decal and leaving a grey ring outline, the floor light a flat red disc that does not change, then cut off while fire and sparks still hung over a dark floor. The same build plus a cooling lit patch under the fire (`L.hotMark`) and a shimmering white point on the head: 62 (the patch read as a yellow decal disc and a red smear left on the floor; the point still read as pasted on). In the round before, two builds with more changes lost to the build above (59.5 and 56 against 61), and the judges named these changes in them: the trail's light 3 times the scale ahead of the body (a second, offset ellipse on the floor), a dark rim round the head (a helmet with a visor), smoke-textured chips (confetti, and dark specks in the sky), the hot spot held at 0.4 of its peak (a white disc inside the rings), the rings' twin removed in their old colours (whiter, a stronger target). Still named: the flash a frame before the contact, a few long straight spark needles at +0.12 s, a pink dot in the fire at +0.4-0.6 s, thin sticks standing on the floor from +0.5 s, the head's white point pasted on, no crater or scorch.
- Every defect named in the build above traced to a general cause (same stage and method, one more round, 2026-11-21): the flash "a frame early" was the rock sinking half into the floor for 0.04 s before its impact (`travel` sent its centre to the floor point; it now arrives when its front does); the pink dots were the explosion flipbook's first frames (3d texture slots); the sticks standing on the floor were embers drawn as streaks rising slowly (now round dots under half a stud); the needles were 40 white streaks in a 28-degree cone (now 26 `hot` chips in a 45-degree cone); the UI rings were clean circles (now five broken arcs, `arcs`). Sums of two judges: 69 against 52 for the build above; the same with the head's point drawn as small flame cards 58 (they reached the floor before the impact and were cut into two flat slabs, and the point still read as a blob). Named in the build above and not in this one: the rock sinking before the flash, target rings, needles, sticks, pink blobs. Still named: the head's white point pasted on and the body's crack strokes painted on, the tell's ring a UI ring with thin sticks round it (its rim motes), the fire column splitting into lobes at +0.6-0.85 s and a last puff floating with nothing under it at +1.5 s, and everything gone at once by +1.9 s with no scorch, crater or embers left.
- An ending in steps and a fire that stays on the floor (same stage and method, one more round, 2026-11-21). The changes to the build above: the fountain's speed falls to 0.4 of itself by its end (`settle`); the last flames are a bed of low flames (speed 3-8, sizes 1.1 to 2) from 0.9 to 1.95 s that slows to half its speed; 26 coals lie on the floor (round glow dots of 0.26 studs at scale 1, `mid` to `deep`, each living 1-1.7 s); the hot spot cools to `deep` over 2.6 s; the plume runs to 2.5 s and slows; the release arcs start half transparent (bright inside the floor flash, they read as drawn strokes); the `tell`'s closing ring is four broken arcs and its rim motes round dots. Sums of two judges: 66 against 53 for the build above. Named in the build above and not in this one: fire splitting into clumps and then lifting off the floor as puffs with no source at +0.85-1.5 s, everything gone at once by +1.9 s, a UI ring with thin needles standing round it in the tell. The same build with the head's white point replaced by a strong light just ahead of its face: 63 (both judges read the head as a soft glow, not a sticker, but the light lit one flat face of a block lump as a pale bar, and on the contact frame it reached the floor as two offset flat sheets). Still named: the head's point and the body's painted cracks, the shock arcs at +0.12-0.25 s as a floor decal, a flat floor flash with a hard lower edge on the contact frame, no scorch left, coals as perfectly round beads.
- No cards on the floor and no point on the head (same stage and method, one more round, 2026-11-21). Each floor defect was traced by freezing the contact frame and turning layers off one at a time: the scorch alone drew a lit hard rectangle, the floor glow a band with a straight top edge, and the flat yellow plate the judges had named in four rounds was the release light (peak 7, 5 studs over the floor at `scale` 2.6), not a particle. The changes to the build above: no floor rings, floor glow or scorch in the release; the release light and the fountain's light `soft`; the dust lifted (`up` 0.8) and kept under the fire (`z` 0: drawn toward the camera at 0.5, it covered the burst as a black blob); coals squashed and turned at random; the hot spot cooling over 3.2 s; 3.9 s in all. Sums of two judges: 61 against 54 for the build above, and 66 for the same with the `trail`'s white point removed, which both judges put first (its contact frame read as a spiky starburst, the other's as a soft white ball). Named in the build above and not in these: the flat yellow floor plate with stepped edges, the crescent rings on the floor, the floor glow wider than the fire. Still named: the head's hot glow as a flat yellow disc over the rock's edge (one judge), a red band with a hard top edge on the floor beside the contact (the `trail`'s light at the floor on the contact frame), thin red chips high over the burst at +0.12 s read as needles, the fire's base cut flat by the floor at +0.25 s (a box), a dark red puff loose over the column, a pink smoke ghost at +1.15 s, and the coals as flat red petals.
- Dots for what slows, a stage that plays every layer, and sheets aligned on the flash (same stage and method, one more round, 2026-11-21). Two of `skill_eruption`'s streams, the fountain's chips and the plume, had never played on the test stage: it cut the recipe by `l.at or l.from`, and a stream made from a burst template carried the template's `at`. In the game the chips were there, as streaks that stood in the fire as white sticks; with the stage fixed both judges named them as the clearest defect of the round (from +0.25 to +0.85 s). The changes to the build above: a layer keeps one start; the fountain's chips and the release's chips as glowing dots; the release's sparks on the flash's own frame, fast, with no drag or gravity, gone in 0.14 s; fire lumps thrown over the upper half only from 2 studs up; coals lying level; the `trail`'s light `clear`. The sheets are now aligned on the flash's first frame (the count of near-white pixels at the landing point jumps): the floor's brightness, used before, rose 0 to 3 captured frames after the flash (0.25 speed, 20 frames a second), which had put one build's contact tile on the flash's ball and another's on its burst. Sums of two judges: 59 against 55 for the build above with its two missing layers back; the same with thin, short sparks 60 (one judge put it first for a burst with no needles, the other put the build with the bigger sparks first for the sharpest contact). Named in the build above and not in these: sticks standing in the fireball, a fan of needles at +0.12 s, flat dashes thrown out at +0.25 s, the red band beside the contact (one judge missed its glow on the contact frame). Still named: a few pale or olive shards at +0.12 s, the floor's light with a straight edge at +0.05 s and weak on the contact frame, a fire lump beside the flash with no source at +0.05 s, the fire's base cut straight at +0.25 s, the fire in two masses at +0.40 s, coals as flat coins in a ring (the turned ones read as hot debris to one judge), no scorch left, and on the stage's own rock a glow disc and a crack that read as painted.
- Beams add up: a 20-segment ring with its twin is 40 beams, and `times = 3` makes 120. One skill is 100-200 beams; that is fine for one caster's skill and too much for something every player has running.

**Templates** (`FxRecipe.layers`): call one with a table of the fields to change, for example `L.sparks({ count = 16 })`.

| Template | What it adds | Life |
|---|---|---|
| `flash` | the white contact frame | 0.05 s |
| `under` | a dark soft disc for contrast on a lit floor | 0.16 s |
| `core` | stars that grow and collapse, white to hot to mid | 0.12-0.15 s |
| `body` | the one saturated colour mass; without it the hit reads white | 0.16 s |
| `bolts` | electric accent | 0.06-0.1 s |
| `rays` | a disc of rays behind the core | 0.14 s |
| `sparks` | streaks thrown back at the attacker, stopped by drag | 0.12-0.32 s |
| `embers` | a stream of small streaks that rise | 0.2-0.45 s each, 0.4 s long |
| `smoke` | a few puffs behind everything, the dark end of the value range | 0.5-0.8 s |
| `pops` | small stars after the hit | 0.25-0.35 s |
| `ring` | the shock ring, radius 0.5 to 3.4 in 0.21 s | 0.21 s |
| `light` | the world answers | 0.2 s |
| `floorRing` | a shock ring lying on the floor, radius 0.6 to 5 | 0.3 s |
| `riseRing` | a thin ring that travels up the body (swap `y0`, `y1` to scan down) | 0.55 s |
| `floorGlow` | a soft colour disc lying on the floor | 0.3 s |
| `scorch` | a dark mark left on the floor, the underlayer of a ground hit | 0.7 s |
| `pillar` | a column of light on the body: one soft glow squashed tall | 0.3 s |
| `motes` | thin streaks that rise from a ring at the feet | 0.25-0.35 s each, 0.9 s long |
| `wisps` | small bright dots that drift up around the body | 0.3-0.35 s each, 0.9 s long |
| `dust` | smoke thrown out along the floor | 0.5-0.8 s |
| `debris` | chips thrown up that fall back | 0.28-0.35 s |
| `fireball` | lumps of the explosion flipbook | 0.28-0.35 s |
| `gather` | streaks pulled in to one point from 8 studs: the charge before a release | 0.24-0.3 s each, 0.5 s long |
| `strike` | a vertical beam whose end comes down from the sky in 0.06 s, widens to 3.2 studs and fades | 0.3 s |
| `column` | a vertical beam that opens, holds 2.2 studs and closes (thin it to 0.5 with `flicker` when it holds) | 1.2 s |
| `helix` | a band 0.7 studs wide wound 2.5 turns around a 30-stud column, turning 1.6 times a second | 1.2 s |
| `glowfall` | soft pieces that fall down a column: its glowing body, redrawn all the time | 0.12-0.2 s each |
| `crackle` | bolts at random places over a floor disc | 0.06-0.1 s each |
| `rain` | streaks born at every height of a column that fall 8-18 studs | 0.14-0.2 s each |
| `flames` | small lumps of fire that rise from a floor disc: a fire column built from short-lived pieces | 0.25-0.34 s each |

**Palette.** A layer names keys, never colours, so one recipe plays in any palette (`opts.palette`). Eight keys: `white` (the contact frame, near white), `hot` (a light tint, the bright edge), `mid` (the saturated body), `deep` (the same hue darker and saturated: what an additive glow cools to before it fades), `dark` (the same hue, almost black: smoke, stains and scorches; under additive blending it vanishes before it reads red), `smoke0` to `smoke1` (smoke over its life), `light` (the PointLight). A palette table made before `deep` existed gets `mid` blended 40 % toward `dark`. Shipped: electric, fire, ice, holy, shadow, poison, water, gold, heal, earth.

**Writing a new one.**
1. Start from the nearest shipped recipe and its palette; copy the table.
2. New element: write the seven palette keys first. Keep `white` within a few percent of white, `mid` fully saturated, `dark` below about 30% value.
3. Change the character with accent layers, not with colour alone:

| Character | Add | Drop or change |
|---|---|---|
| Electric | `bolts` | |
| Fire | `embers`, more `smoke` | fewer `sparks` with weaker gravity |
| Ice | more `pops`, a third `core` star | faster `sparks` with more drag; short pale `smoke` |
| Holy | `rays`, more and slower `pops` | no `smoke`; `sparks` that rise |
| Shadow | two `bolts`, longer `smoke` | a tinted `flash`, a wider `under` |
| Poison | `pops` that float up | slow `sparks`; `smoke` that lingers and rises |

4. Tune in this order: `count`, then `speed` and `drag` (a spark stops after about 1.44 x speed / drag studs, section 3), then `life`. Keep every life at 0.35 s or less except smoke (house rule: small, short-lived pieces).
5. Verify as in 3d: freeze with `fx_capture` at 0.05, 0.1, 0.2 and 0.45 s from the player's camera, then watch it at real speed. Checks: a white frame of at most 3 frames; one saturated mass, not a white blob; the ring reads against the floor; nothing left on screen after 1 s.

**Details an author needs** (each one was a guess for a smaller model writing recipes from this section alone, 2026-11-20):
- Slots: `glow` a soft round ball; `star` a 4-point spark; `streak` an elongated ember (set `along = true`, `rotation = 90`); `flare` a ring with rays, additive only; `smoke` a thick puff; `electric` a lightning bolt; `fire` an 8x8 explosion flipbook; `band` is for beams. Round drops, bubbles and drifting dots: `glow` at about 0.3 studs with `emission` 0.3-0.6; at 0.6 studs and more they read as lumps (owner, on a water hit at real speed, 2026-11-20).
- `flare` reads as a large translucent bubble above about 6 studs, and two of them stacked on the core washed a critical hit out to white: keep `rays` at 7 studs or less, use one, and make a bigger hit bigger with the ring radius, the spark count and the light, not with more additive discs on the centre.
- Defaults of a hand-written layer: `where` "hit", `emission` 1, `brightness` 1, `z` 0, no motion; a ring defaults to 12 segments. `rotation` is a fixed start angle, or `{ min, max }` for a random one in that range (random over the full turn without it). An override replaces the whole field.
- `duration` is when everything is destroyed: the last particle's death plus a margin (1.0 s for the shipped hits).
- The 0.35 s life limit wins over the drag rule: a spark with low drag fades out on its way instead of stopping, which is fine. Use drag of about 3 / life or more only for pieces that must visibly stop.
- A pickup or any effect that is not a hit: set `anchor = "up"` (or `"feet"`) so the sparks go up, widen `spread` (180 sends them every way), leave out `recoilDeg`, `smoke` and the ring's `twin`. `spread` 180 ran in Studio.
- A `streak` needs `along = true`, `rotation = 90` and a `squash` above 1 at the start (the shipped ones use 1.2-1.6), with a start size of 0.35-0.5 studs: without the squash, rising streaks drew as white squares in Studio.
- An aura reads as a state only with something that holds: keep the held floor ring (`dur = "end"`, `r0 = r1`) under the streams, or it looks like scattered sparks.
- Body effects keep the body visible: rings, streaks and dots around it, and at most one soft `pillar` for 0.3 s. Do not fill the silhouette with glow.
- Keep `under` wherever the background is bright (a lit floor, the sky); drop it in dark scenes.
- A second element must differ from its neighbours in hue (`mid` about 30 degrees of hue apart or more) and in at least one accent layer, or players cannot tell them apart in a fight (judgment).
- Fill all seven palette keys even when a recipe uses no smoke: another recipe may be played in that palette.
- A recipe's `palette` may be a name or a table of the seven keys; `opts.palette` takes the same two forms.
- `disc`, `tube`, `life`, `speed` and `rotSpeed` are positional pairs (`disc = { 8, 1 }` is radius 8, partial 1).
- A recipe with anchor `"feet"` or `"up"` played at a CFrame uses the CFrame's position as given: pass a point on the floor for `"feet"`, the object's centre for `"up"`.
- Smoke may live up to about 1 s; everything else stays at 0.35 s or less. Set `duration` to the last death plus at least 0.3 s.
- A `column` or `strike` shorter than the default 40 studs works (`y1 = 14` ran in Studio); its top fifth always fades out.

**Own textures.** The slots ship with public ids for prototypes; a release uses the game's own. `FxTextures.use(slot, id, pieces?)` pins a slot (or a new slot name a layer asks for) to one texture, before any `FxRecipe.play`. For a sheet of variants pass its grid, `"Grid2x2"` or `"Grid4x4"`: every particle then shows one random cell for its whole life (`FlipbookMode` Loop, `FlipbookStartRandom` true, `FlipbookFramerate` 0; OneShot would play the cells as frames).

| Slot | What a replacement sheet holds | Look |
|---|---|---|
| `streak` | spark streaks or embers, each pointing up | light: white on alpha, tinted by the palette |
| `star` | small stars or glints | light |
| `glow` | soft dots | light |
| `fire` | single flame tongues, upright (never a whole fire) | light |
| a new name (`shard`, `leaf`, `coin`) | solid pieces in the game's colours | full colour; set the layer's `emission` to 0 and its colours to white |

Light sheets must be white with the brightness in alpha and no crop edge inside a cell: under additive blending any faint box shows. Measured on generated sheets, 2026-11-20: the largest alpha step next to a clear pixel was 2-3 of 255, and three sheets (a 2x2 spark set, a 4x4 flame set, a 4x4 solid ice set) rendered one cell per particle on a `ParticleEmitter` in Studio 0.748; `skill_eruption` ran with the flame sheet in its `fire` slot and the spark sheet in `streak`. A design service that generates such sheets (4 or 16 variants of one particle on an exact 1024 px grid) saves the drawing; hand-made sheets follow the same rules. Not judged by the owner; UI particles (`ParticleEmitter2D`) take the same sheets and were not tried (beta off in this Studio).

Test through the service (2026-11-20): a smaller model in a fresh session with one tool, the service's guide reader, and no other source found this section from the topic's first page in 2 calls, read it and its three scripts in 6 more, and wrote a frost skill, a pink pickup and a lava hit as recipes; all three played with no errors on the first run in Studio 0.748 and read as intended at the contact frame, and the lava hit then turned into a dark smoke blob (10 opaque puffs: see the smoke rule above). The five bullets above this paragraph answer what it listed as guesses. It had to retype the three scripts from the quoted text, 68,661 bytes, which took most of its 5.5 minutes; the copies were byte-identical.

Test of this section (2026-11-20): a smaller model given only this section and the module wrote three new recipes (a water hit, a reward pickup, a critical hit) without running Studio; all three played with no errors on the first run. Looked at frozen at 0.06, 0.15 and 0.4 s: the water hit and the pickup read as intended; the critical hit was washed out by two large `flare` discs, which the flare bullet above now covers. At real speed the owner judged the pickup and the critical hit good and the water hit odd for its large round drops (2026-11-20); the shipped `hit_water` uses 0.3-stud drops and has not been judged at real speed.

Cost of one hit (counted in Studio, not a frame-cost measurement): 8-10 emitters, 24 beams (a 12-segment ring and its twin), 1 light; a second ring adds 12 or 24 beams; cap hits on screen at once on phones (section 5). Read from the recipe tables, not counted in Studio: `level_up` is 7 emitters, 64 beams (four 16-segment rings) and 1 light; `aura` is 4 emitters, 32 beams and 1 light for as long as it holds, so give it to the local player and a few nearby characters, not to a crowd.

**Moving things.** `play` reads its target's position once, so by default an effect stays where it started. Three additions let anything that moves carry its effect:
- `opts.follow = true` moves the whole effect with its target (a part, an attachment or a model) every frame; `opts.follow = function(t)` (clock time, returns a Vector3 or CFrame) moves it along any path. Rings, columns, helices and lights move with it; a target that is destroyed leaves the effect where it was.
- `recipe.anchor = "trail"`: the spray points back along the motion and turns as the path turns. A stream with `path = width` is emitted over the distance its anchor moved in the frame, and `density` adds pieces per stud moved, so a trail is as full at 40 studs/s as at 150. Rate per second alone left gaps at speed. A tail reads as one shape only when its pieces overlap: pieces per stud x birth size of about 8 or more (the `trail`'s outer glow: 4 x 2.2). At 3.6 the same tail read short and patchy beside a hand-built one at about 10 (2026-11-21). The overlap must hold over the whole life, not only at birth: keep pieces per stud x size at about 3 or more while a piece is still over a fifth visible, and fade it by transparency after that, or the tip beads into a string of puffs. Keep the `path` width under the piece size late in its life (the `trail`'s outer glow: 0.3 against about 0.6 at 85 % of its life): a box of 0.8 against 0.4 scattered the pieces sideways and the tail's edge went lumpy. A layer that leaves pieces behind (tail, smoke) takes `rate = 0`, pieces per stud only: any rate per second piles pieces where the anchor starts slow, and they showed as a blob or loose puffs at the tip.
- `opts.emitUntil` stops the `"end"` layers there while the clock runs on, so the last pieces finish their lives. A stream with `cut` (seconds) does not let them: when it stops there, its live pieces go out from the far end toward the anchor in that time (its alpha curve is squeezed toward birth). The `trail`'s fire layers take 0.15-0.4 s, so on arrival the tail runs into the impact instead of hanging in the sky for up to a second; its smoke has none and stays as a column.
- A glow that rides on the body: `locked = true` on a stream (its particles move with their anchor). Particles inside a solid body are hidden by it: a head glow centred in a 6-stud rock showed only as a ring round it. `z` is scaled like a size, so a glow whose `z` is above the body's radius at scale 1 is drawn over the body: the `trail` lays an orange glow over the front half of the body (`up = -0.3`, ahead of the centre along the flight, about 0.2 opaque at its peak) and a `hot` one a third of the body wide on its leading edge (`up = -0.85`), so a dark rock reads hot in front and dark behind. A white spot there half the body wide, and then a quarter, read as a headlight stuck on the rock in three blind rounds, and one an eighth of the body wide as a pasted dot in the rounds after (so did small flame cards and a strong light put in its place); with no white at all the head read cooler than its tail in an early round, but once the impact was fixed the build without the point won 66 to 61 (two judges) and the point was removed; a hot glow three quarters of the body wide, with the front-half glow `hot` too, turned the rock amber, and two judges read it as soft and blending into its tail (2026-11-21).
- The body itself, when it is built from Parts (no mesh allowed): a dark lumpy rock whose cracks are thin Neon strips laid flush in its faces, never bars or balls that cross its outline. Neon renders brighter and more saturated than its `Color3`, the same by day and at dusk (Studio 0.748, flat swatches facing the camera, no post effects): (255,140,30) came out lemon (254,243,3), (255,120,30) yellow (254,222,1), (255,95,20) orange (254,164,1), (255,70,0) red-orange (254,76,1), (230,50,0) and every darker red pure red (255,25,1), (255,220,150) white. A test body's cracks of (255,110-170,30) read to every blind judge as lime-yellow bars like UI dashes, and its half-buried Neon ball as a flat yellow sticker: for molten cracks use about (255,95,20) and (255,70,0). What the judges asked of the body in four rounds: a dark crust on its trailing side, three to five thin glowing cracks, and the leading face as its hottest part, which the `trail` draws (2026-11-21). The lab body they read as the cleanest rock: a `Slate` ball in (46,34,30), 3.2 studs at scale 1; seven `Block` lumps 0.35-0.55 of its width, centred 0.38 of its width out in random directions and turned at random, tinted up to (80,60,50); eight cracks of three short Neon strips each, 0.14 x 0.12 studs at scale 1, laid on the ball's surface. Put the lumps all round: a build with its lumps on the trailing side only left the leading half a smooth ball, and two judges read it as a glossy marble or an orb (2026-11-21). The scales every lab round used with that body at 2.2 (7 studs wide): `trail` at 3.96 (1.8 times the body's scale), `tell` at 1.32, `skill_eruption`'s release (its layers from 0.4 s, moved to 0) as the impact at 2.6, a fall of 1.15 s with `ease = "in"` from 62 studs up and 38 back, the body turning at `spin = Vector3.new(0.35, 0.2, 0.3)`.
- The light that rides with a burning body goes ahead of it, outside its leading face: the `trail`'s light sits 1.6 times the scale ahead of the centre along the flight (`up = -1.6`). A light inside a solid body lights none of it: 0.4 behind the centre, the `trail`'s light sat inside a 9-stud rock. Ahead of it, it lights the floor below as the body comes in, a warm pool that grows until the impact; two blind judges named that pool as a reason the build won (2026-11-21). A light layer takes `color` (a palette key, default `light`): the `trail`'s is `mid` at range 9. In the palette's pale `light` colour the pool read as peach-tan sand to two judges; in `mid` it read as firelight, and at range 12 as too large.
- A big glow round a moving head is cut by the floor in a straight line in its last frames: a particle has no soft edge where it crosses a surface (named by two blind judges). `clear = true` on a locked stream shrinks it, and every piece it has out, with the room left between its anchor and the nearest surface below or ahead of it (two rays a frame, which skip the effect's own parts and the body `travel` moves; pass `opts.ignore` when your own code moves the body). The `trail`'s haze and its front-half glow take it. A light takes `clear` too: riding ahead of the body (`up` negative) it dims with the room left to the surface below or ahead of it, over half its range and squared, and is out when it gets there (three rays a frame). Without it the `trail`'s light rode into the floor ahead of the rock and lit it as a red band with a hard top edge beside the contact for about 0.1 s (two blind judges, 2026-11-21); with it the pool still grows as the body comes in and is gone on the contact frame, where the impact's own lights take over.
- A tail measured in studs: a stream with `len` (studs at scale 1) gives each piece the life its anchor needs to move that far at its current speed and acceleration, within `life` (then a min and max), and never longer than the stream has run plus the min, so the tail keeps its shape at any speed, a tail that is still growing ends in a faded point instead of a round cap where it started, and it costs `density x len` pieces alive. With a fixed life the same tail was a good comet behind a meteor at 110 studs/s and a uniform bar 15 bodies long behind a 1.5-stud fireball thrown at 75 studs/s; with the speed alone, the pieces born while a fall was still slow outlived its tail and bunched into a round bulb with a waist at the tip. `opts.tail` multiplies every `len`: 0.5 for a short tail on a small thrown thing, 1.5 for a long comet tail.
- A tail built like a flame, in `len` layers: one glow layer in the hot colour about 8 deep clips to one flat white-yellow area wherever its pieces overlap. Keep each layer's sum at the centre (pieces overlapping x opacity x brightness) near 1 to 1.5 times its colour, so only the innermost clips to white: a narrow core over the first sixth of the tail, a quarter to a third of its width (`len` 3.5, 0.75 wide), white only in its first fifth; a band of fire flipbook cards in the `hot` colour over its first 30 % (`len` 6, 1.1 wide, facing the camera, brightness 0.6), whose ragged edges give the body inner variation; a wide glow in `mid` that turns `deep` from 25 to 50 % of its life and is dimmer over its back half, so its sum there stays near 1.3 times `deep` (`len` 20, 2.2 wide); and red billows over its back 60 %: pieces with the smoke texture in `deep` (`len` 20, 2 per stud, 1.2 wide, hidden for their first 40 %), which give the red part an uneven edge. The tail then reads white-yellow at the head, orange to about half its length, then red to a deep red tip. The core starts 0.3 behind the centre with `z` 0: a `z` above 0 draws a glow emitted inside a body over the body's back edge, and the white hid the rock's outline. Judges in every round still read the rock as cooler than the trail right behind it, with one small white spot as its only hot part: a burning body needs heat of its own (molten cracks flush with its surface, a darker back), which the trail cannot add. The wide glow itself drawn with the smoke texture read as separate puffs and lumpy red blobs with a blunt end (two judges): keep the main glow soft and lay a texture over it thinly. One hot layer read as a flat white-yellow sausage, and one that cooled to `dark` stopped at orange: the dark pieces vanished before they looked red. Watch the sums in the middle of the tail too: red clips first, so a band summing to 1.3 times `hot` read lemon (green as high as red) and the wide glow at twice `mid` read yellow; with the cards over 70 % of the tail and `deep` only in its last quarter, two judges measured red in the last tenth only and pale yellow to white from a quarter to 85 % of the length (blind rounds, 2026-11-21).
- Smoke behind a fire trail must outlive the fire, or it dies hidden under it: the `trail`'s smoke has its own `len` (34 against the tail's 20), is hidden for its first quarter (it starts inside the fire), is drawn behind the tail (`z` under the tail's) in the palette's lighter smoke colour and barely rises, so it shows past the deep red tip, on the tail's line. Drawn in front of the tail in the dark smoke colour it darkened the tip and read as a dirty smudge cut off from the trail (two blind judges, 2026-11-21).
- Embers laid per stud (`density` 2.5 on top of a rate of 20 in the `trail`) thicken as the body speeds up into the impact; at 1.2 a judge counted 5 to 8 near the impact.
- Start a flight out of view, or far enough back that the tail (speed x its life) has grown before it is seen: a fall that starts in view shows a round ball with no tail for its first 0.2 s (both builds of the blind test in 3k).

`FxRecipe.travel(from, to, opts)` flies something from `from` to `to` (a Vector3, CFrame, part, attachment or model each) and returns the flight's clock:

```lua
FxRecipe.travel(handAttachment, enemyModel, { time = 0.4, trail = "trail_glow", palette = "holy", impact = "hit_holy" })
FxRecipe.travel(skyPoint, floorPoint, { time = 1, ease = "in", body = rockModel, spin = Vector3.new(0.5, 0.2, 0.35),
	trail = "trail", tell = "tell", impact = { "ground_hit" }, scale = 3, tellScale = 1.5, impactScale = 2.5 })
```

| Option | Default | What it does |
|---|---|---|
| `time` | 0.6 | flight time in seconds |
| `arc` | 0 | studs of height at the middle of the flight: a lob |
| `ease` | `"linear"` | `"in"`: already moving at 0.4 of the mean speed, 1.6 of it at the end (a fall, a dive); `"out"`: the reverse |
| `body` | none | an anchored part or model moved along the path, facing it; `spin` (a Vector3 of turns per second about its own axes) tumbles it instead; it arrives when its front reaches `to`: its path ends `reach` studs short (default half its longest side; with its centre sent to a floor point, a 7-stud rock sank half into the floor for 0.04 s before the impact, and two judges read the flash as early); destroyed on arrival unless `keepBody` |
| `trail` | `"trail"` | a recipe that follows the flight; `false` for none |
| `tail` | 1 | multiplies the trail's tail length (its `len` layers; the `trail`'s tail is 20 studs at scale 1) |
| `tell` | none | a recipe played at `to` for the whole flight |
| `impact` | none | a recipe (a name or your own recipe table) or a list of them played on arrival with LookVector along the flight; one whose anchor is not `"feet"` is set back `impactLift` studs (default 1, times its scale) so the surface it hit does not cut it |
| `palette`, `scale`, `tellScale`, `impactScale` | the recipes' own, 1 | |
| `onArrive(position, direction)` | none | damage, a sound or a camera kick on the beat |

A `to` that moves is chased, and the tell follows it. The flight is drawn on this client; the server decides the hit (`roblox-combat-tools`). A bolt of energy needs no body (its core is the body); a rock, an arrow or a missile is a mesh (house rule, section 3).

| Recipe | Anchor | Palette | What plays |
|---|---|---|---|
| `trail` | trail | fire | an orange glow drawn over the front half of the body and a hot one on its leading edge (no white point), a soft haze round the head, a tail in four layers (a core white at its start, a band of fire cards, a wide glow that cools from orange to deep red, red billows over its back; one comet tail 20 studs long at scale 1, at any speed), sparks thrown back that shrink out, embers that fall away behind (laid per stud, so they thicken into an impact), smoke that carries on past the red tip, a light ahead of the body that lights the floor fire-orange before the impact; near a surface the head's glows shrink and its light dims out (`clear`) |
| `trail_glow` | trail | electric | a white-hot core and a saturated glow that taper, sparks and glints; no fire or smoke (energy bolts, magic; set the colour with `palette`) |
| `trail_star` | trail | holy | a white ribbon that tapers to nothing over a wider glow ribbon, a four-point star turning at its head, a few glow dots (energy that arrives at a character, orbits it, flies with it; play it on a moving part with `follow = true`) |
| `tell` | feet | fire | a floor ring of four broken arcs that closes on the point and is gone at the impact, a mark that flickers and builds, heat spots, small round motes rising from the rim, a light that grows |

Fields added for them, usable in any recipe: a stream takes `path`, `density`, `ramp = { in, out }` (shares of its span; the trails use `{ 0.05, 0 }` so they end at full rate under the impact) and `grow` (builds toward its end and stops there: a tell, a charge); a light takes `grow`, `color` (a palette key; default `light`), and `ramp` with `hold`; a ring takes `ease` (`"in"` closes slowly, then fast, onto a beat) and `alpha` `{ { u, transparency }, ... }` over its span; a burst or stream takes `locked`, and a locked stream `clear`. A `mark` layer (`at`, `dur`, `r0`, `r1`, `grow`, `alpha`, `color`, `glow`, `brightness`, `y`) lies flat at a `"feet"` anchor and stays where it was put while it fades: a scorch, a stain, frost. It is an image on the floor, not a particle, so it may last seconds; `L.mark` (dark) and `L.hotMark` (lit by itself, cooling from hot to dark) are its templates. A light's range grows with the square root of `scale`: grown with the scale, the trail's light lit the whole floor as one flat oval at scale 4.

Evidence (2026-11-20, Studio 0.748 Play on a desktop, slow motion at 0.04 and 0.2 and frozen frames): a fall from the sky over 94 studs in 1 s (`trail` at scale 3, `tell` at 1.5, impacts at 2-2.5, about 38-150 studs/s), a lobbed fireball of particles only (arc 10) and a holy bolt at 131 studs/s into a wall. Fixed on the way, each now a row of the 3k defect table: a core 4.5 studs wide read as a white disc over the body; fire cards laid along their velocity read as paper scraps; a rate per second left gaps at speed and the bolt's glow read as a string of dots; `explosion` at a floor point was cut into a white dome and a half ring. All 22 recipes then played with no errors, and part, attachment and moving-part targets (one destroyed while followed) worked. No owner verdict yet; not checked on a phone.

Evidence (2026-11-21, Studio 0.748 Play on a desktop, slow motion at 0.25, still frames aligned on the impact): a smaller model's meteor built with the `trail` recipe lost a blind test of its fall 5 vs 8 to the same model's earlier hand-built comet (the recipe's tail was a thin line of dots at scale 4 seen from 80 studs). The trail was rebuilt in that model's own place with only `fx_recipe` changed, over twenty-one versions, and judged in nine blind rounds by a separate judge model on unnamed builds, three at a time from the third round on, the last by two judges with the labels shuffled apart. Release 1.34.0 shipped the sixth round's winner (44, against 42 for the best earlier version and 32 for the hand-built comet; sums of six scores out of 10). Its judge then named a flat white-yellow tail body, a white spot that read as a headlight and a tip that stopped at orange: the three-layer tail, `deep`, the glow over the front half of the body with a small white-hot point and `len` with acceleration fixed them over five more versions. In the last round both judges put this `trail` first (42 and 42), the layered version without the head and tip fixes second (41 and 39) and the hand-built comet last (26 and 23). Each rule added to this section that day (the overlap over the whole life, the `path` width, `rate = 0` on layers that leave pieces behind, `len` capped by the time its stream has run and set from the acceleration, the three-layer tail, `deep`, the body glow, sparks hidden for their first tenth, `FxRecipe.preload()`) fixed one defect seen in those frames, each now a row of the 3k table. `mark` (dark, lit, both) at scale 3 on a dark floor read as intended, and the `trail` at scale 1 on a 1.5-stud ball thrown 34 studs in 0.45 s read as a comet with `len` and as a bar 15 bodies long without it. Then still named by its judges: the head reads cooler than the tail behind it, the tail reads as one smooth tube with few flame tongues, embers thin out just before the impact, and the big glow round the head is cut by the floor in the last frames.

Evidence (2026-11-21, evening, same place and method): five more versions on those asks, judged in two more rounds of two judges with the labels shuffled apart. The light ahead of the body, `clear`, more embers and smoke past the tip, with a hotter and wider head glow, split the first round (42 against 39 for the previous release, then 41 against 43: the rock read amber and soft). With the head as before and the smoke behind the tail in the lighter colour, both judges put it first (43 and 43, against 39 and 40 for the previous release and 29 and 28 for the hand-built comet), and both named the floor pool, the embers and the smoke as the difference. A 1.5-stud ball thrown at scale 1 reads as a comet whose red tip runs on into a grey smoke line. Two more versions then moved the colours: the cards over the first 40 % at brightness 0.6, `deep` from 30 % of the wide glow's life and the smoke shown from its first quarter. Both judges of the next round put that first (45 and 43, against 41 and 39 for the version above and 26 and 25 for the hand-built comet); one counted 15 to 30 % more red pixels, a quarter to a third fewer yellow ones and a smoke trail about 30 times larger. Still named: a white core that runs into the back of the rock and hides its outline, a tail about 1.7 times the rock's width right behind it, a smooth tube with no flame licks, the yellow bars on the rock (the test body's own Neon parts) and a ball with no tail where the fall starts in view. Not judged by the owner yet; not checked on a phone.

Evidence (2026-11-21, night, same place and method): seven more versions on those asks, in two more rounds of two judges with the labels shuffled apart. The wide glow drawn with the smoke texture, narrower at the head, lost to the previous release (42 and 43 against 44 and 45): both read its back half as separate puffs and lumpy red blobs, though one found its red floor pool more believable than the peach one. A camera-facing crescent band on the rock's leading edge read as a pale plastic arc and was dropped before judging. Back to the soft glow, with `deep` from a quarter of its life and dimmer over its back half, red billows of smoke texture laid thinly over its back 60 %, the core white only at its start and drawn behind the body, a white point a little larger and brighter, and the light in `mid` at range 9: both judges put it first (43 and 44.5, against 39 and 43 for the previous release and 22 and 27 for the hand-built comet), and one sampled deep red (196,39,27), orange, yellow and white-hot from the tail to the head. A 1.5-stud ball thrown at scale 1 reads white and yellow in front, red behind, then grey smoke. Still named: the rock reads cooler than the trail right behind it; a smooth cone with no flame licks on its edges; a red floor pool with no hot centre; smoke that sits as a separate puff above the red tip in some frames; the test body's yellow bars and half-buried Neon ball; no tail where the fall starts in view. Not judged by the owner yet; not checked on a phone.

Evidence (2026-11-21, late night, same place and method): six more versions on those asks, in two more rounds of two judges with four builds each. A second, smaller light in `hot` for a hot pool centre and the smoke shown earlier did not move the scores (79 against 80 for this release). A leading-edge glow half the body wide, white at its start, won one round (84 against 80) and tied the next (87 against 88): the head read hottest, but the glow ate the rock's outline on that side, and moved outside the leading face it read as a light stuck on the rock. A thinner, more transparent tail end with dimmer billows and a lighter smoke lost (79 against 88): the tip turned salmon where the light smoke crossed the red. The `trail` is unchanged: the builds now sit within the judges' noise of each other (one build scored 39-41 in one round and 43-45 in the next), the hand-built comet stays about 20 points behind, and every judge's first asks were about the body (its Neon bars and ball, a rock darker than the trail behind it) and a fall that starts in view.

Evidence (2026-11-21, after 1.39.0, same place and method): the test body rebuilt by the Parts rule above (eight short polylines of Neon strips flush in its ball, (255,95,20) and (255,70,0), no Neon ball) against the same recipe on the old body: both judges put the clean body above the old one (85 and 86 for two clean bodies against 78, two judges summed), the head scoring 6 and 6 against 5 and 4; cracks 0.2 of the scale wide read as a golden bar and a glyph, 0.12 wide as clean. Then, on the clean body, the core shortened from `len` 5 to 3.5 and the cards from 8 to 6: about half as many near-white pixels in the crops on the meteor, and both judges put it first or level-first (86.5 against 84). Still named: the rock darker than the trail right behind it, no tail where the fall starts in view, smoke as one puff at the tip, embers as round dots. Not judged by the owner yet; not checked on a phone.

## 3j. A blade trail as a fan of bands (fast sword cuts)

A fast sword cut sweeps 150-200 degrees in 0.035-0.05 s, two or three drawn frames at 60 fps. This is a trail for such cuts that reads as one sheet ending in pointed tails, with a served module that builds it from the blade's own past frames.

Evidence: built in Studio 0.748 Play on 2026-11-20 on a dual-blade combo demo of ours (4.4 s, 15 strike windows on two blades: single cuts, double cuts, a spin and a crossed finisher), first as a pure function of time on the demo's exact poses. The band build was made earlier for a greatsword in another game of ours and approved by the owner there; here its times were scaled to the faster cuts. Fresh judges in two blind rounds (clip order flipped) named its defects: the fixes are the measured rows below, the rest is under Known limits. The owner watched the demo at real speed and asked for it in the product (2026-11-20). It was then ported to `scripts/blade_fan.luau`, which sees only the blade's guard and tip once per drawn frame, and run on the demo's body with 60 and 30 fps game frames emulated in a 0.2x capture and at real speed: no Output errors. At 60 fps it drew the same fans as the approved render at the beats compared (nine cut beats, the spin and the finisher) except the first cut, seen nearly edge-on, and over the whole clip its white and pink pixel shares were within 6 % and 9 % of the approved render's. Numbers are chosen by eye unless marked measured. No real phone, no published game.

Files: `scripts/blade_fan.luau`, one ModuleScript; strip in `assets/vfx-examples/blade_fan_strip.jpg`. Client only.

```lua
local BladeFan = require(ReplicatedStorage.Fx.BladeFan)
-- two Attachments on the blade: where the trail starts (just past the guard) and ends (the tip)
local fan = BladeFan.new(blade.TrailStart, blade.TrailEnd)
slashTrack:GetMarkerReachedSignal("Cut"):Connect(function()
	fan:swing(0.1) -- points cut from just before now to 0.1 s on draw; a spin: fan:swing(0.25, 0.6)
end)
-- on a hit, hold the fan as long as the tracks (scripts/hit_stop.luau)
local seconds = HitStop.play(character, victim, damage)
fan:setSpeed(0)
task.delay(seconds, function() fan:setSpeed(1) end)
```

Options are the fields of `BladeFan.defaults`: `bands` 7, `life` 0.15, `coreLife` 0.014, `grid` 1/150 s, `color` and `tail` (crimson by default), `lightEmission` 0.45, `brightness` 1.25, `minSpeed` 40 and `fullSpeed` 110 studs/s, `near` 5 studs, `light` true. One `RenderPriority.Last` binding updates every fan; set `BladeFan.autoStep = false` before the first `new` to call `BladeFan.step(dt)` yourself (a replay, a fixed-step capture).

**Anatomy.**

| Part | Numbers | Why |
|---|---|---|
| Bands | 7 along the blade, guard to tip, each overlapping its neighbours by 1.2 % of the blade; each band a chain of flat beams through its middle at the blade now and every 1/150 s back | one sheet; without the overlap a hairline shows between bands |
| Band life | the tip band lives `life`, the guard band 0.55 of it, every other band 0.78 of its own | tails of unequal length: the fan ends in a row of points, not one straight edge |
| Shape | full width for 55 % of a band's life, then narrowing to a point; the oldest live point is pulled back to where the life ends | each tail ends in a point exactly at its life |
| Colour | white to 4 % of the life, the body colour from 14 %, the tail colour (the same hue, darker) at the end; transparency 0.06 at birth, 0.12 at half life, 0.3 at the end | one hue family with a white-hot edge (section 3c) |
| Light | `LightEmission` 0.45, `Brightness` 1.25 | 1 burnt the fan white; 0.6 with 1.4 turned the crimson pale pink on a night floor |
| Core | the outer half of the blade, white, `LightEmission` 1, `Brightness` 2, for `coreLife` | the white-hot line right behind the edge |
| Gates | a band draws only for points cut inside a swing window and only where the tip crosses the blade's line faster than `minSpeed` (full at `fullSpeed`); within `near` studs of the camera it fades, gone at half of it | wind-ups, counterweight moves and holds leave nothing; a blade sliding along itself drew planks |
| Tip light | a `PointLight`, range 5, brightness 0.9 x the gate | the floor answers the cut |

**Times and the sweep.** The core scales with the sweep; the trail life does not.

| Cut | Sweep time | Trail life (tip band) | Core life |
|---|---|---|---|
| Greatsword, another game of ours | 0.16 s | 0.2 s | 0.05 s |
| Dual-blade cuts (the defaults) | 0.035-0.05 s | 0.15 s | 0.014 s |

Copied unchanged onto the fast cuts, the greatsword's numbers turned the whole fan white (a 0.05 s core covers a 0.04 s sweep), and at 0.2 s the bands piled into solid discs. Set `coreLife` to about a third of your sweep time and keep `life` near 0.15-0.2 s.

**Beams that curve without waves** (Studio 0.748, 2026-11-20):

| Fact | Consequence |
|---|---|
| Each beam spans 1/150 s, up to 30 degrees of a fast sweep; drawn with `Segments` 3 it showed as corners on the fan's edge (a judge named faceted edges) | `Segments` 10 |
| Straight beams showed a corner at every joint | curve each beam through its joints: `CurveSize0 = CurveSize1 = -length / 3`, each attachment's X pointing to the newer end (P1 sits along +X of `Attachment0`, P2 along -X of `Attachment1`, docs); the other sign drew S-curves |
| With X forced square to the blade every segment bulged into a wave, whether all bands shared one direction or each had its own: the hand moves, so the blade also slides along itself, and X sat up to 45 degrees off the band's path | X is each band's own path direction at that point (its two neighbours, the closer one weighted more); the width axis Y is the blade made square to X |
| Where the path runs almost along the blade (just before a cut) the width turned with it and twisted the ribbon; letting X tilt 35 degrees out of the blade's square plane left hatched teeth at the tails | cap the tilt at 20 degrees |

**From the blade's frames** (the module). It records the guard and tip every drawn frame and reads that record back on the 1/150 s grid. Measured against the demo's exact poses over the fast parts of all its cuts, error of the interpolated tip:

| Between two drawn frames | Mean at 60 fps | Mean at 30 fps |
|---|---|---|
| The grip frame's rotation (`CFrame:Lerp`) | 0.38 studs | 1.35 |
| Blade direction on the shortest arc, guard on a straight line | 0.35 | 1.27 |
| Blade direction on the shortest arc, guard turned with it about the point that move implies (served) | 0.29 | 1.25 |

- The blade turned up to 132 degrees between two frames at 60 fps and up to 231 at 30 (worst frame phase). Past 180 degrees the shortest arc runs the wrong way: a turn of more than 115 degrees whose next frame turns clearly the other way is redrawn the long way round from that next frame on. The next frame decides because a follow-through keeps the cut's sense; the frame before a cut is often the wind-up, which turns the other way (judgment).
- Cuts this fast keep their shape at 60 fps and lose it at 30, where most fans came out smaller. Give the fast part of a cut 3-4 frames of the frame rate it must hold: about 0.05 s at 60 fps, 0.1 s at 30.
- Hit-stop: `setSpeed(0)` stops the fan's clock. A hit lands between two frames, so the first held frame still shows the blade moved; the module counts that frame at full speed. Without it, that motion aged 0 s and the held frames showed a mostly white fan (white 10-12 % of the frame against 6-7 % on the approved render; 4-5 % after the fix).

**Feel around it** (the demo; chosen by eye, checked by the judges):

- The finisher holds 0.083 s (5 frames at 60 fps) on the second blade's landing, with a camera kick over 0.24 s: a 0.9-stud push, a 0.2-0.3 stud shake and the view 6 degrees narrower, decaying with the square. A 0.05 s hold with a 0.18 s kick went unnoticed by a judge. The demo shook the camera by position; a game uses the shake model of section 3b.
- A spin keeps its bands at 0.6 of their life (`fan:swing(0.25, 0.6)`): at full life the turns piled into one blob.
- One trail per blade. The demo's contact star at the end of each cut used a texture and stays out of the module: build impact flashes from sections 3c and 3d.

**Cost** (measured: Studio 0.748 Play on a desktop, the client at 15 fps, both blades, `os.clock` around the update of frames with a trail on screen):

| Setting | Instances per blade | Drawn at once, both blades | Update per frame, both blades |
|---|---|---|---|
| defaults | 172 beams, 181 attachments, 1 light | up to 204 beams | 1.11 ms mean, 2.27 ms max |
| `bands = 4, grid = 1 / 90` | 63 beams, 69 attachments, 1 light | up to 72 beams | 0.51 ms mean, 1.17 ms max |

An idle fan draws nothing and only records two positions a frame. Use the defaults for the player's own blades and the lighter setting with `light = false` for other players. Not measured on a phone.

**Known limits.** Two frames carry no bulge: a cut whose sheet curves out of its plane, seen nearly edge-on, drew a thinner sheet from 60 fps frames than from the exact poses. The judges still named these on the approved demo, and the owner kept the look: on overhead cuts and the finisher the fans are large and opaque enough to hide the head and torso for a few frames, and thin rings show between bands for 4-6 frames as the tails part. Judged on a dark stage only. No sound, no phone, no published game.

## 3k. Read first: what every effect is judged by

The rules that the owner's verdicts and our test builds keep coming back to, in one place, for any effect (sources: the owner's verdicts in 3g, 3i and 3j; a smaller model that built a skill effect from this guide alone on 2026-11-20 and listed ten guesses in its report; the moving-things lab in 3i, 2026-11-20; a smaller model's meteor built from this guide and blind tests of its fall against a hand-built one, 2026-11-21; a frost aura on a held sword built from this guide and stills of a finished fire aura, and the owner's verdict on its frames, 2026-11-24). Every row of the defect table is something one of those builds got wrong or had to guess.

**The bar.** Check each from the player's camera, on frozen frames and at real speed:

| Check | Fails when |
|---|---|
| Small units | one sprite shows a whole flame, explosion or trail; a piece lives over 0.35 s (smoke over about 1 s; a trail's tail glows up to about 1 s, as they shrink and cool to deep red) |
| Brief white | white lasts past a contact flash of 3 frames or the first 15% of a piece's life (a trail's core line, a quarter of its width, may stay white over its first half); a white ball or disc holds on screen |
| No big one-colour mass | a large shape is one flat colour: a disc, a dome, a slab, one black smoke mass |
| No picture pieces | a visible piece is one image of a whole thing: a star or lens-flare burst, a fan of spikes, a ring, a crescent, a snowflake, a gem; or a solid mesh (a copy of a prop, a flat diamond) floats beside the object as part of the effect. In an always-on or looping effect none of these is used as a piece the eye reads as itself. A glint (a point with short thin rays) may twinkle there only as a speck: about a tenth of the object's width, alive under 0.2 s, many at once and never one alone (judgment, from a weapon aura the owner set as a target; no build of it has been judged yet). In a one-shot burst one may flash at the contact (a star for 3 frames, the ground blast's fan for under 0.3 s, 3g) and is gone |
| No light bigger than its source | a soft glow is seen as a ball or a halo: wider than the thing it lights and not covered by denser pieces. On a blade 0.76 studs wide, glow dots of 1.1-1.6 studs at 30% opacity and of 0.5-0.65 studs at 45% read as a large light and were rejected |
| Specks stay specks | round dots that drift or fall are big enough to be seen as balls. Watched from 16.5 studs, white dots of 0.13-0.24 studs falling like snow were rejected; embers of 0.07 studs that shrink to 0.02 passed. Specks are a twinkle, not a piece that must read: for more presence use more of them, not larger ones |
| Something moves | a layer holds over 0.3 s with nothing moving in it (a still picture) |
| Fire shrinks as it ends | a fire stops dead or thins out to one piece |
| Reads at its distance | its pieces are under about 4 px on a phone (size table below) |
| Nothing left behind | the effect stays where its object was while the object moves on |

**Which section.**

| The effect | Start from |
|---|---|
| A hit, pickup, level-up, aura, ground hit, heal, spawn, puff, explosion | 3i, a shipped recipe |
| A 2-4 s skill on the floor: a nova, a strike from the sky, a zone, an eruption | 3i, the skill recipes |
| Anything that flies: an arrow, a fireball, a magic bolt, a thrown item, something falling from the sky | 3i "Moving things": `FxRecipe.travel` with a trail, a tell and impact recipes |
| An effect on something that moves (an aura on a running player, fire on a cart) | `FxRecipe.play` with `follow` (3i) |
| An always-on aura on a held item (a sword, a staff, a tool) | 3l |
| Picking pieces for smoke, vapor, grainy points, glints or a little electricity, on an item or elsewhere | 3l, the "Ingredients" table |
| The contacts of a strike skill (a punch or cut flurry, a heavy hit): splashes, shards, needles, flares | 3m |
| A sword cut | 3j for fast cuts, 3d for a fire slash |
| A game that already runs and feels flat: which interactions to fix first | 1a, the feel audit |
| A skill with camera work, a cutscene | 3c for the beats, then 3e |
| A reveal cutscene (a rare roll, an unlock, a title card) | 3e: its build order and rules come first |
| Fire, an explosion or smoke at large size | 3g |
| A floor that breaks, smoke that erodes | 3h |
| Copying a reference clip | 3f |
| Camera shake, screen flash, hit stop, FOV | 3b |

**Build order.**
1. What it rewards and how big it is: the fun card (`roblox-fun-effects` section 1).
2. A beat table: the tell (what the player reads first), the release, the tail, each with its time; the impact lands on a beat (3c).
3. The camera distance it is watched from, and the scale from the size table.
4. The nearest recipe: change data, not code. Anything that moves gets `follow` or `travel`.
5. Run it in Play from the player's camera; look at a contact sheet of a slow run, then at real speed; fix against the defect table.
6. Count it against the budget.

**Size for the camera.** The default `FieldOfView` is 70 degrees (vertical), so 1 stud at distance D covers H / (1.4 x D) px on a screen H px tall. Detail under about 4 px averages away (`roblox-blender-export` section 4). The phone row is the 360 px height of the Samsung Galaxy A06 preset.

| Camera distance | px per stud, phone | px per stud, desktop 1080 px | Smallest piece that reads on the phone | Recipe `scale` (judgment) |
|---|---|---|---|---|
| 15 studs | 17 | 51 | 0.25 studs | 1 |
| 30 studs | 8.6 | 26 | 0.5 studs | 1 |
| 60 studs | 4.3 | 13 | 0.9 studs | 2 |
| 100 studs | 2.6 | 7.7 | 1.6 studs | 3 |

At another field of view F, 1 stud at distance D covers H / (2 x D x tan(F / 2)) px: a stage at 16.5 studs with a field of view of 40 gives about 90 px per stud on a 1080 px screen and 30 on the phone.

The recipes are sized for about 15-35 studs. Something watched from 60-100 studs takes `scale` 2-3, which grows sizes, speeds and radii together and keeps the times. Never enlarge one layer instead: it turns into a mass.

**Budget per effect** (instances counted in Studio 0.748, not a frame-cost measurement; who may run it is judgment). Particles alive in one stream: rate x life, plus density x speed / scale x life on a trail. From the recipe tables (not counted in Studio): the `trail` keeps about 285 alive at scale 4 and 100 studs/s (a meteor) and about 380 at scale 1 and 60 studs/s, of which its five `len` layers (core, tail, flames, billows, smoke) keep about 190 at any speed; `trail_glow` about 45 at scale 1 and 60 studs/s. When many things fly at once, use `trail_glow` or a copy of `trail` with a shorter tail.

| Effect | Emitters | Beams | Lights | Parts | Who may run it |
|---|---|---|---|---|---|
| A hit (3i) | 8-10 | 24 | 1 | 1 | many on screen; cap hits at once on phones |
| A trail in flight (3i) | 11 | 0 | 1 | 8 | the `trail` on a hero projectile; see the alive counts above for many |
| A fall from the sky: trail, tell and `ground_hit` at the landing (3i) | 13 in flight, 19 at the landing | 48, then 80 | 2, then 3 | 11-12 plus the body | the local player's own skill |
| A skill recipe (3i) | 8-16 | 96-316 | 1-4 | 7-9 | one caster at a time |

Frame cost on a phone is not measured for any of these: play the busiest moment on a low-end phone profile (section 5).

**Defects we keep seeing.**

| What you see | Cause | Fix |
|---|---|---|
| A white ball or disc over a moving thing | a core glow wider than the body and white for most of its life | the core under the body's size, white only in its first 15%, plus a saturated `mid` layer |
| A string of dots behind something fast | pieces emitted at one point per frame, at a rate per second | `path` (emitted over the distance moved) and `density` (pieces per stud moved), with pieces per stud x birth size of 8 or more on a tail |
| A tail burned to one white sausage, or one flat white-yellow area | eight or more additive glows in one hot colour overlapping (at brightness 2.4 a sausage; at 0.6 still flat) | three layers whose sums at the centre stay near 1 to 1.5 times their colour: a narrow white core, a band of fire cards in `hot`, a wide glow in `mid` (3i) |
| Grey, olive or brown lumps inside a bright glow | a half-lit layer (`emission` 0.5) inside additive glows darkens what is behind it | `emission` 1 for every layer inside a glow, or put the half-lit layer behind (lower `z`) |
| Dark brown twigs or rods at the end of a trail | streaks that fade by transparency or end in a dark colour: additive yellow at low opacity reads brown on a night sky | streaks stay `hot` and opaque to the end of their life and shrink to nothing |
| A tail tip that beads into a string of puffs | pieces too far apart for their size late in their life, or scattered sideways by an emission box as wide as they are | overlap of about 3 or more while a piece is over a fifth visible, fade by transparency after that, `path` under the piece size late in its life (3i) |
| A round blob or loose puffs at a tail's tip early in a flight | a rate per second on a tail or smoke layer piles pieces where the anchor starts slow; a tail still growing ended in a round cap where it started | `rate = 0` on layers that leave pieces behind; `len` caps each piece's life at the time its stream has run (3i) |
| The first cast freezes for about 1 s, then the effect jumps ahead and leaves a blob where it started | its textures load on first use (the 8x8 fire flipbook is the largest) | `FxRecipe.preload()` once on the client before the first cast |
| A ring of glow round a dark body, or a head that sinks into its flame | glows centred inside a solid body are hidden by it; one even glow over it turns it the fire's colour | a glow locked over the front half of the body with `z` above its radius, and a small `hot` one on its leading edge (3i) |
| A white ball like a headlight stuck on a burning body | a white glow a quarter to half the body wide on its face | a `hot` to `mid` glow a third of the body wide on its leading edge with a white point an eighth wide inside it, all inside the glow over the front half (3i); with no white the head reads cooler than its tail. Open: three later rounds still named that point a small white dot pasted on; a dark rim round the head (a helmet with a visor), a shimmering point and small flame cards in its place (a soft blob, and without `clear` the floor cut them into two flat slabs at the contact) did not fix it (2026-11-21) |
| Pale slabs or streaks drawn across a moving body | sparks thrown back from inside it cross it in their first frames | hide them for the first tenth of their life (transparency 1, then 0) |
| A tail pale yellow to white over most of its length, red only at its tip | additive layers summing to 1.3-2 times a warm colour in the middle of the tail: red clips first, so the colour drifts to lemon and white | the core over the first sixth and the hot band over the first 30 % only and dimmer, the wide glow turning `deep` from 25 to 50 % of its life and dimmer over its back half (3i) |
| A tail that stops at orange, with no red end | additive pieces cooling to `dark` (nearly black) vanish before they look red | cool from `mid` to `deep` over the last third, then fade (3i) |
| A round bulb with a waist at the tip of a tail behind something speeding up | each piece's life was set from the speed alone, so the pieces born while it was slow outlived the tail | `len` sets the life from the speed and the acceleration (the module does it) |
| A big glow round a falling head cut off in a straight line where it meets the floor | a camera-facing particle has no soft edge where it crosses a surface | `clear = true` on the head's locked glows: they shrink with the room left to the surface (3i) |
| The floor stays dark under a falling fireball until it lands | its light rides inside the body | the light ahead of the body, outside its leading face: a warm pool grows into the impact (3i) |
| A beam left standing in the sky after an impact | a trail's tail pieces live out their life after the body has landed (still there 0.25-0.4 s after the contact, two blind judges, 2026-11-21) | `cut` on the tail's fire layers: they go out from the tip toward the impact (the `trail`: 0.15-0.4 s); smoke without it stays as a column (3i) |
| Firelight on the floor that reads as sand or peach | the palette's pale `light` colour on a grey floor | `color = "mid"` on the light layer at about half the range (3i); `mid` at the old range read as red paint four times the fire's width |
| A flat red disc of light on the floor that does not change, then gone while the fire still burns | one light at one colour and level, ended before the fire (two blind judges, 2026-11-21) | a hot spot that flares on the contact frame and drops to a tenth within 0.13 s, flickering and cooling `hot` to `mid` (`shape`, `flicker`, a `color` ramp), and the light over the fire fading out with its last flames (3i); held at 0.4 of its peak it drew a white disc inside the rings |
| A white core that runs into the back of a moving body and hides its outline | a glow emitted inside the body with `z` above 0 is drawn over the body's back edge | `z` 0 on glows emitted inside a body, the core starting behind its centre and white only at its start (3i) |
| A tail of separate puffs, or lumpy red blobs with a blunt end | the main tail glow drawn with a smoke texture: the holes in each piece show where few overlap (two judges, 2026-11-21) | keep the main glow soft; lay the texture thinly as its own layer in `deep` over the back of the tail (3i) |
| Star flares, spike fans or flat diamonds on an aura that read as clip art | a sprite that is a picture of a whole thing held as a standing piece, or a prop's mesh cloned and floated as decoration (the frost aura, 2026-11-24: the owner rejected each of them, and two blind judges called them "stock-looking sprites") | build the shape from many small short pieces: crack lines and scatters of chips that flash for 0.1-0.3 s, thin streaks that shoot out and brake; no mesh in an aura |
| A large soft light on the object, a halo that swells | soft dots wider than the object at 30-45% opacity with nothing denser over them (the same build) | a glow sits under a denser layer and stays near the object's width; if its outline can be found on a frozen frame, cut its size or its opacity |
| Snowballs: round white dots falling beside the effect | soft dots of 0.13-0.24 studs used as flakes (the same build) | specks of about 0.07 studs that shrink, and more of them; or one random cell of a sheet of fine chips (`flecks`) |
| A pale arc stuck on a moving body | a camera-facing crescent band on its leading edge, tried for a heat rim (2026-11-21) | keep the heat in glows drawn over the body's front (3i) |
| No smoke behind a fire trail, or a dirty smudge cut off past its tip | smoke that dies with the fire, hidden under it, or drawn over the tip in a dark colour | smoke with its own `len` about 1.7 times the tail's, hidden for its first quarter, behind the tail in the lighter smoke colour (3i) |
| A burning rock that reads amber and soft, blending into its tail | the glows over its front too wide or too hot | the front-half glow `mid` at about 0.2 opaque, the hot leading-edge glow a third of the body wide (3i) |
| A flat bright oval on the floor under a big effect | a light's range grown with `scale` | range by the square root of the scale (the recipes do this); `L.hotMark` for a lit patch |
| Sticks or a ring of dashes round a glowing body, or a flat yellow crescent on it | bright Neon bars poking out of it, a Neon ball half inside it (blind judges, 2026-11-20 and -21) | cracks flush with the surface in Neon (255,95,20) or (255,70,0), which render orange and red-orange: Neon (255,110-170,30) renders lemon (3i); the glow drawn over the body does the rest |
| Laser lines or a decal round a crater | glowing floor cracks drawn as straight, even Neon strips out from the centre (two blind judges, 2026-11-21) | leave the cracks out and let the floor light carry the impact: a hot spot that flares on the contact frame and cools with the fire (3i). A cooling lit patch (`L.hotMark`) under the fire read as a yellow decal disc and left a red smear (two blind judges, 2026-11-21); short jagged pieces that taper and are gone by about 0.5 s are untested |
| A target on the floor, or a grey ring outline left after the rings | floor rings with their dark twin: a dark band between bright ones (two blind judges, 2026-11-21); without the twin in their old colours they read whiter, a stronger target | floor rings `hot` to `mid` as broken arcs (`arcs = 5`): two judges read them as a ground wave, one still as drawn strokes while wide and bright inside the floor glow; in the next two rounds the arcs still read as a floor decal or UI rings, and the build with no floor rings won (2026-11-21): on a floor let dust thrown out along it carry the shock (`skill_eruption`, 3i) |
| Flat black squares flying out of an impact | dark debris Parts seen from 80 studs and more, lit by nothing (two blind judges, 2026-11-21) | chips that glow while they fly and cool as they land, few and small, or the `debris` streak layer |
| Cubes, cracks or rocks still lying there seconds after | Parts the effect made with no fade (seen at 3.6 s in a 2-4 s effect) | fade or sink every Part the effect makes by its end; a `mark` for what should stay a while |
| The effect stays where its object was | the position was read once | `follow` or `travel` |
| A white dome or a half ring at a landing point | a camera-facing glow or ring centred on the floor; a big flash low over it (`skill_eruption`'s flash was 9 wide at `up` 1.5 until 1.41.0: at `scale` 2 an 18-stud white dome, copied into a meteor's impact) | on a floor play a `"feet"` recipe (`ground_hit`, `skill_eruption`); keep its flash small and lifted (`skill_eruption`: 3 wide at its widest at `up` 2, white for half its life and then `hot`, three white-hot `core` stars, the floor lit on the same frame); an `"up"` recipe sits at least half its glow's size above the floor |
| Fire like paper scraps, or a stray card sticking out of a moving head | flipbook cards laid along their velocity (a stretched one stuck out of a falling rock at the start of its fall, 2026-11-21) | flames face the camera; lay only streaks along the velocity |
| Fire that reads pink on a bright sky | strong additive orange over blue | `emission` 0.4-0.5 on fire layers in daylight |
| Every textured effect draws nothing in Studio, or squares while it loads; Output says "Authentication required to access Asset" for every asset | Studio's sign-in has expired: it refuses every asset, the default animations too (seen 2026-11-21; `roblox-pitfalls` section 3) | ask the user to sign in again, then capture again. Do not swap texture ids or paint textures of your own for it (a builder did, and its build was judged on those) |
| An effect's light does nothing right after a teleport or at the start of a cutscene on a far stage | the camera and the scene jumped more than about 100 studs up or 500 sideways: PointLights stay dark for 6.5-10 s (measured 2026-11-21; section 3e) | stay within 80 studs of height and 450 of distance, arrive 10 s early, or carry the light with ambient light (`cine_sky` does it for recipes) |
| A camera-facing backdrop or plate stands at an angle across the next shot for one frame, as a slab with a hard diagonal edge, on the frame of a cut | two `FxClock`s step on their own `PreRender` connections, and the one that places the piece from the camera stepped before the one that moves the camera, so on the cut frame it used the old camera (15 fps Studio recording, 2026-11-22: `sky:tunnel`'s plate after its last shot; judges named it "a hard diagonal wipe edge") | place camera-relative pieces in the clock that moves the camera, after it (`sky:tunnel` does this with `owner`), or in a render step bound after `Enum.RenderPriority.Camera`. `sky:portrait` (its lights), `sky:drift` (its near fade) and `ScreenOverlays.speedLines` (their focus) also read the camera on their own loop: one frame behind on a cut, not seen as a defect so far |
| Thin stepped slabs of cloud near the horizon: a "pixelated" or "low-res" sky | the engine's cloud deck (`Clouds`) at graphics quality 10 of 21 and under: Studio's `settings().Rendering.QualityLevel` drew the slabs at levels 1, 9 and 10 and a smooth deck at 11, 12, 14 and 21, and Studio was on level 10 in our runs, so every capture showed them. A lower `Cover` (0.5) or `Density` (0.45) and more `Atmosphere` haze (2.4) left them (measured 2026-11-22; not checked on a phone) | in a sky stage `sky:sea()` puts a far bank of cloud in front of that band (on by default); in a scene of your own keep the band out of the frame or behind something. Judge a sky at level 10 and at 21, and put Studio's level back |
| A far set, island or cloud bank missing from the frame | the engine draws nothing past a view distance that falls with the graphics quality, parts and particles alike: about 525 studs at level 1, 1,700 at levels 4-12, 3,000-4,000 at 14 and over 8,000 at 21 (Studio Play, 2026-11-22). Not the `Atmosphere`: `Density` 0.15 and 0.30 cut at the same distance | keep what a shot must show within about 500 studs of the camera: a first far bank for `sky:sea()`, 1,800-2,300 studs out, was not drawn at level 10 |
| A ring, arc or sphere of puffs or sparks that comes out as one clump | one emitter moved between `Emit` calls in one step: its pieces leave from where its host is when the frame is drawn, all from the last place (3g, "Measured on the way"). `ground_burst`'s ring of 28 dust puffs went out as one white clump (Studio Play capture, 2026-11-22), and `fire_slash`'s embers and smoke, `energy_sphere`'s inward streaks and `void_pillar`'s floor mist were written the same way, until 1.77.0 | `clock:emitAt(e, cf, count, props)` for each place (`fx_clock`): each place in a step gets its own copy of the emitter |
| A field of particles that thins out after a minute, or whose gaps jump in one frame when it is renewed | a particle lives at most 20 s (`Lifetime` takes 25 or 40, and those pieces were gone by 22 s); a `Rate` refill fell behind in a Studio window drawing 15 frames a second (`cine_sky`'s sea thinned to loose puffs in about a minute); and an `Emit` refill from one emitter, as its old set began to fade, made the old set of the sea's floor vanish in one frame (cause not known: the same fade worked on a lone emitter). Measured 2026-11-22 | renew it with `Emit` from two emitters that take turns: the new set fades in, the old one is faded out by script and cleared before its life ends (`sky:sea()` does this; a 30 s recording at 15 fps showed no jump) |
| Fire like a row of separate explosions | big flipbook lumps that live long, far apart | smaller, shorter, denser pieces that shrink (3g) |
| Pink or magenta dots in a fire | the explosion flipbook's first three frames are a smooth pink-red ball, shown for the first 5% of every flame's life (two judges, 2026-11-21) | its slot's `lead` (3d texture slots): `fx_recipe` hides that share of each particle's life |
| A bundle of white needles or a broom out of an impact | many white streaks thrown in a narrow cone: 40 in 28 degrees (two judges, 2026-11-21); 26 streak chips that cooled to red still read as thin red needles high over the burst | fewer chips (26) in a wider cone (45 degrees), drawn as glowing dots (`slot = "glow"`, `along = false`, `squash = false`, `rotation = 0`, 0.3 studs) from `hot` to `deep` (`skill_eruption`) |
| The body sinks into the floor and the flash comes late | the body's centre flown to the floor point: half of it under the floor before the impact (two judges, 2026-11-21) | `travel` ends a body's path `reach` studs short (default half its longest side), so the impact plays as its front arrives |
| White or yellow sticks hanging in the air, or standing on the floor | streaks with a long life and little speed (embers drawn as streaks that rise slowly stood round a fire's base for over a second, and a tell's rim motes round its ring, two judges, 2026-11-21); a 0.35 s `Trail` on each thrown chunk drew 10-20-stud yellow bars in a meteor draft (2026-11-21); streaks thrown up and slowed by drag or gravity (a fountain's chips stood in the fire as white sticks, an impact's sparks as tan ones) | a streak keeps its speed and its hot colour to the end and is gone in 0.08-0.14 s (no `drag`, no `accel`), a chunk's `Trail` too; glowing round dots for everything that slows, falls or cools: embers, chips, a fountain's spit |
| A fire column that splits into lobes, or a last puff floating with no fire under it | the fountain's pieces leave at full speed until it stops, so the last ones are high up when nothing burns below them (two blind judges, 2026-11-21) | `settle` on the fountain, and a bed of low, slow flames that outlasts it (3i) |
| Everything gone at once, nothing left | every layer ending in the same tenth of a second: fire, floor light, embers and smoke all gone by +1.9 s (two blind judges, 2026-11-21) | end in steps: the fountain, then the bed of flames, then the floor light cooling to `deep`, coals on the floor last (3i) |
| A pale flat bar on a moving body, or a floor flash broken into offset flat sheets | a strong light with a short range just ahead of the body: it lit one flat face of a block lump, and on the contact frame it reached the floor (two blind judges, 2026-11-21) | keep strong lights a body's width or more from its faces; the head's heat comes from the `trail`'s glows |
| A flat yellow plate or oval on the floor with a hard rim, under a flash or a fire | one bright `PointLight` near a floor: its falloff is flat over most of its range and the centre clips, so the floor is lit evenly almost to the range and then drops (`skill_eruption`'s release light, peak 7 five studs over the floor at `scale` 2.6, named as a flat card or plate in four blind rounds; found by freezing the contact frame and turning each light off, 2026-11-21) | `soft = true` on any light that reaches a floor: three lights at one point, the floor fades from the centre out (3i) |
| A flat card or band on the floor with a straight edge | a big flat particle (`flat = true`, `glow` slot) 15-40 studs wide: the soft circle's square edge shows (the release's floor glow and scorch at `scale` 2.6, each frozen alone, 2026-11-21) | keep flat glows under about 10 studs wide and let `soft` lights draw a big floor answer |
| A black blob over a burst | a dark layer (dust, smoke) drawn toward the camera over bright fire: `skill_eruption`'s dust at `z` 0.5 (2026-11-21) | dark layers' `z` under the fire's; lift them with `up` so the floor does not cut them |
| A red band with a hard top edge on the floor beside a landing | a light that rides ahead of a falling body reaches the floor before the body does (the `trail`'s light, two blind judges, 2026-11-21) | `clear = true` on that light: it dims with the room left and is out at the surface (3i) |
| A fire's base cut flat by the floor, a box of fire | fire lumps thrown every way (`spread` 180) from a point on the floor: half of them go into it, and a camera-facing card is cut in a straight line where it crosses a surface | throw them over the upper half only (`spread` 80-90) from a point lifted off the floor (`up`) |
| Coals on a floor that read as beads, or as petals | round glow dots; the same dots squashed and turned at random | lying level: wider than tall (`squash` negative), `rotation` 0 |
| An impact whose first frames are a soft white ball | the flash alone: the sparks started 0.03 s after it | sparks on the flash's own frame (the same `at`), so the contact has spikes from its first frame |
| A layer that plays in the game but is missing from a test stage's captures | the stage cut the recipe by `l.at or l.from`, and a stream made from a burst template carried the template's `at`: two stream layers of `skill_eruption` (the fountain's chips and the plume) were missing from the lab meteor's captures for over twenty rounds, and the chips were white sticks nobody had judged (2026-11-21) | since 1.46.0 a layer keeps one start (`from` for a stream, `at` otherwise); before judging, count the stage's emitters by name against the recipe's layer list |
| One black smoke mass | many opaque puffs | thin smoke, at least half transparent (3i) |
| A still picture | a held beam or glow with nothing moving in it | moving pieces (3i) |
| A grey veil or a brown wash over a dark scene | a full-screen tint: white at 0.3-0.4 read grey in one test build, a warm tint at 0.26 for 0.22 s read brown in another, white at 0.35 for 0.14 s (8 frames) over a night scene in a third; white at 0.16 with a bloom pulse still lifted a dusk sky to olive-grey for about 0.12 s (two blind judges, 2026-11-21) | over a dark scene leave the full-screen flash out and let the floor answer instead: a hot spot light that flares on the contact frame and the floor glow (`skill_eruption`, 3i); if a tint stays, 0.15 or less for 3 frames (0.05 s) or less (limits in 3b) |
| The screen washes out for 2 frames | a flash too long or too opaque | at most 3 frames and 0.5 opacity (3b) |

**Watching an effect from an agent.**
- Hold the camera every frame: Studio puts `CameraType` back to `Custom` after an `execute_luau` call that changed it (its console says so, 2026-11-20). Bind a step at `RenderPriority.Camera + 1` that sets `CameraType` to `Scriptable` and the `CFrame` each frame.
- The Play client may run at 15 fps (3b), so a real-speed video shows a 0.16 s flash in 2 frames. Slow the effect instead: `FxClock.defaultScale = 0.2` slows every clock made after it, with its emitters' `TimeScale` and its beams' texture speed, so the look does not change. Record with `video_capture`, then `ffmpeg -i in.mp4 -vf "setpts=(PTS-STARTPTS)/5,fps=60" out.mp4` plays it at real speed with five times the frames. A screenshot of a run at 0.04 is a frozen frame.
- One image of the whole run: `ffmpeg -i slow.mp4 -vf "fps=3,scale=480:-1,tile=6x4" -frames:v 1 sheet.png`. Read it beat by beat against the bar and the defect table, then watch it at real speed.
- Anything not made by a clock keeps real speed in a slow run: a `Trail` instance, a tween, a body moved by your own code. Slow it by the same factor (a `Trail`'s `Lifetime` divided by it, your own waits multiplied), or leave it out of the slow run.
- Pause a demo loop for a slow run with an attribute (`workspace:SetAttribute("DemoPaused", true)`, read by the loop before each cast), then cast once from `execute_luau`. A flag in `shared` set from `execute_luau` never reached the demo's LocalScript (2026-11-21): treat `execute_luau` as having its own `require` cache, so `FxClock.defaultScale` set there slows the clocks of casts made from that call, not the demo's. To slow the demo's own casts, set `defaultScale` in the `fx_clock` source in Edit mode before Play, and put it back.
- A dusk stage every lab round was judged on (Studio 0.748): `ClockTime` 18.4, `Brightness` 2, `Ambient` and `OutdoorAmbient` (127,127,127), no post effects: a dark blue sky and a grey floor. `ClockTime` 17.2 still read as bright day and 18.5 as near black in another build; a colour grade and bloom on top turned its horizon olive-brown.
- If `start_stop_play` times out and every later call answers "Start play hasn't finished yet" or "Target is not reachable", read the Output. `Failed to load plugin ... in datamodel PlayServer` (and `PlayClient`) means the plugin that answers these calls did not load into Play: the game runs, but no tool can reach it, and retrying does not help (25 minutes of retries in one run, 2026-11-21). Ask the user to stop Play and reopen Studio; a fresh window of the same place started Play through MCP at once.
- Frame the demo so the effect reads: a fall seen from 80 studs (a 6-stud rock) was marked down for readability against one seen from about 70 studs and lower (blind judge, 2026-11-20). Judgment: the peak fills about a third of the frame height, and the whole path stays in frame. A still camera side-on to the path keeps it there: the lab's fall (73 studs of path, from 62 up and 38 back) seen from 80 studs at `FieldOfView` 62, aimed 12 studs short of the landing and 20 up. A camera that moved during the fall cut the start of the path and the top of the impact at the frame's edges in one build (two blind judges, 2026-11-21).

**Getting the scripts into Studio.** The guide reader serves each script with `raw_url`, `sha256` and `bytes`: download the file and check both. Studio refused a script `Source` over 200,000 characters in our runs; the effect scripts are under 75,000. Two ways in without retyping: a Rojo project that syncs the folder, or a file server on 127.0.0.1 and one Edit-mode `execute_luau` that sets each ModuleScript's `Source` from `HttpService:GetAsync` (worked in Edit mode with `HttpEnabled` off, not from Play). Retyping the three scripts took a smaller model most of a 5.5-minute run (3i).

## 3l. An aura on a held item (sword, staff, tool)

An effect that is always on while an item is held: at rest, through a slow sway and through fast swings, at dusk and against a bright sky. Read 3k first; this section is what 3k does not say about an effect that lives on a moving item.

Evidence (2026-11-24, Studio Play on a desktop, a lab stage: camera 16.5 studs away at a field of view of 40, the sword leaning, a dusk wall and a daylight sky, a loop of rest, sway and two swings of 70 degrees in 0.22 s; recordings cut into sheets of consecutive frames). A fire aura on a greatsword was built by hand over six builds. Two frost auras for a second sword were then built by a smaller model, one from stills of the fire, one from a design document written from the fire plus the fire's engine; the owner picked the document build as clearly the better one, while two blind judges reading frame sheets scored the stills build higher on quality (61 against 56 of 100) and the document build higher on "same game as the fire" (14 against 9 of 20). A glitter aura was built by a smaller model from this guide alone; two more were then built with this section and the kit pack, one for each of two targets from a reference clip (the first target again, and a second one). By our own reading of the recordings the pack builds are a clear step up from the guide-only one (crisp chips in place of round dots, the blade still readable, a blue body under the glitter); the owner then judged all of them as too far from the target, and our "step up" reading was wrong: no capture had been set beside the target at the target's own scale ("Read the target first" and "Check it" say what that hid). Their rows below are marked as rejected with their build; the piece in a row was not judged alone. The target was then rebuilt by hand three times on a stand-in of the right item, a thin dark wire: a dense spark cluster was rejected as "an electric sword", and pale vapor with very small points on it was called much better by the owner. The "Ingredients" table is from that build. The effects lane of a second game of ours reviewed stills of the earlier builds; its points are under "Limits". Nothing was measured on a phone.

**Ready parts.** The RoDesigner kit pack `fx` (`list_kit_packs`, `get_kit_pack`) has the engine that draws an aura from a theme table (`ItemAura`), three worked themes (a fire that flows off the blade, a glitter that rides it, and pale vapor with points in it on a thin item), the textures with their image ids, and the full rules with numbers (`docs/ITEM-AURA.md`). With the pack, a new aura is a new theme table, started from the nearer of the three themes. Without it, build to the rules below.

**Read the target first.** From a reference clip or the brief, write a table before any emitter: each piece (what it is, where on the item it sits, how big against the item's width), and what changes between two frames 1/30 s apart (which pieces are new, which drift, which hold). Parts that belong to the item's model (fins, rings, a glowing gem) are not the effect. The aura is that table, not "glow plus sparkles".

Read it large. Draw single frames at 3 times the clip's size or more and zoom again on the effect, frame by frame, and note for each piece: a soft or a hard edge; a point, a line or a sheet; how many frames it lasts. On sheets at 1.3 times the clip's size, pale vapor with small points on it and a cluster of sparks looked the same, and the build that followed was the wrong element (the "electric sword" above). Also build on the target's kind of item: the same pieces on a wide pale blade and on a thin dark wire read as two different effects.

**Structure** (seen on the fire):

- Two places, not one: the main mass on the upper half of the blade and a second, small, different effect at the guard's gem. Between them the blade is clean. An aura spread evenly from guard to tip hid the sword and had no focus (first build, rejected).
- Back to front: a soft underlay near the blade's width, the element's dark side as paint (low `LightEmission`), the body, a brightest middle that gets its white from clipping (3g), then the few pieces that leave (sparks, specks).
- The body is a pair: each piece once as paint (`LightEmission` 0.3-0.45) and once lit (0.8-1). The lit one glows at dusk; the paint one keeps colour and mass against a bright sky, where the lit one alone turned pale and thin. How little light the paint may carry depends on the sky: red held at 0.2; a cold colour has only value contrast with a blue sky and needed 0.08 and darker colours.
- Gaps are part of the look: rates were lowered until the background showed between pieces. At about twice those rates the fire was one solid shape.
- The item stays readable: the fire at rest is 1.3-1.6 blade widths thick. Wider, and the sword disappears inside it.

**Where pieces are born.** Unseen, non-colliding parts inside the item's model, sized from the blade (length, width, thickness measured once in the grip frame), one per zone: the upper blade (about 0.7 of the width, the upper half), a narrow core inside it, thin strips on the edges, the tip, a small box on the gem. One emitter per layer per zone. Read the gem's position from the model: on one sword it sat 0.31 studs below the blade's base, and an effect placed at the base floated on the blade.

**What rides the item and what stays in the world.**

| Piece | Setting | Seen |
|---|---|---|
| Mass that flows fast (flames, strands: 3.5-9 studs a second, alive 0.1-0.4 s) | in the world (`LockedToPart` off) | in a swing it stays behind and draws the arc; at rest it re-forms in under 0.3 s |
| Anything slow, or that belongs to the steel (a sheen, frost lines, glints, a slow vapour) | `LockedToPart` on, short lives | an unlocked mist stood in empty sky for about 0.7 s after a swing (the glitter build) |
| The few pieces that leave (sparks, specks) | in the world, with `Drag` | a short wake that is gone within about 0.35 s |

**Pieces that worked.**

| Need | Build | Source |
|---|---|---|
| A body that changes shape through its life | an eroding wisp flipbook played once over the life, laid along its velocity and stretched (`VelocityParallel`, `Squash` -0.5 to -0.9, no free rotation). Slow and turning freely the same wisp reads as a round puff | the fire; the first frost build |
| Flow lines | single thin tongues, one random cell each, along their velocity, `Squash` -0.7 to -1.1. A positive `Squash` made needles lying across the flow | the fire |
| The element's own pull | a world-space `Acceleration` (fire: up 12-20), so on a leaning blade the fire leans up off the steel. Without it the aura was a straight torch along the blade | the fire |
| A slow cold vapour | eroding wisps with little light of their own, born on the blade and sinking; the owner called it well expressed | first frost build, owner's verdict |
| A thin lit edge line | soft dots on an edge strip, `VelocityParallel` at almost no speed, `Squash` about -1.6, `Rotation` 0, size 0.14-0.3, life 0.2-0.3 s, many alive so they overlap into one line. With a random `Rotation` they read as stars | the glitter build, rejected with its build |
| A twinkle | size 0 at birth, full at about 20% of life, 0 at death, life 0.06-0.2 s, locked. On a soft dot at 0.1 studs they read up close as small round dots, not sharp points: use a crisp piece (a sheet of fine chips, one random cell) for glitter and keep the soft dot for light | the glitter build, rejected with its build |

**Ingredients: what to reach for, by what the target shows.** From the hand builds above (the fire, and the vapor on a wire 2.9 studs long seen from 9.5 studs; sizes in studs). Textures named in code style are in the kit pack `fx`; "the public spark" is the small four-point spark of 3d's texture table.

| The target shows | Reach for | Numbers that worked | The wrong pick, as seen |
|---|---|---|---|
| Pale smoke, steam or mist sitting on the item | a soft smoke sheet flipbook played once over the life (`dust_smoke`), lit: `LightEmission` 0.6-0.85, white to a tinted end colour, free rotation | 0.3-0.75 studs, life 0.28-0.5 s, about 11 a second per box, transparency 0.35 at its fullest; in the world, so a moving item leaves a little behind | a puff flipbook with a drawn outline: cartoon clouds. Twice the rate at transparency 0.15: one white mass like a flame |
| Grey smoke | the same sheet, grey, `LightEmission` 0.35 | 0.4-0.9 studs, life 0.6-0.9 s | |
| Soft streaks that rise or stream off one side | an eroding wisp flipbook (`dust_wisp`) thrown out of the item's side, along its velocity and stretched (`Squash` -0.3 to -0.7), with the element's world pull | 0.4-0.75 studs, life 0.18-0.3 s, 12 a second per box | thin tongue pieces: petals |
| Very small bright points, grainy, new each frame | the public spark so small that its arms are not read, as a twinkle, locked to the item | 0.15-0.17 studs at its fullest, life 0.07-0.18 s, about 170 alive on the wire | the same spark at 0.25-0.3 studs: an electric crackle. Soft dots: balls. Sliver chips: commas |
| A few bright glints | the public spark, larger and rare | 0.34-0.75 studs, life 0.14-0.24 s, 1.5-14 a second | many of them: a field of stars |
| Electricity | thin forked line pieces, one random cell each (`crackle`), any rotation | life 0.05-0.09 s, 0.3-0.4 studs; a few a second is "a little electricity", from about 80 a second per box the lines are the whole look | lines used to add density to a cluster: the element changes |
| A colour cast behind a pale body | the smoke sheet in the colour, behind (`ZOffset` -1), transparency 0.7 | 0.9-1.5 studs, 6 a second | a soft dot of any size from 0.13 to 0.5 studs: a ball or a balloon |
| A coloured fringe round a white body | points in the colour in a wider box, `LightEmission` about 0.35 | 0.24 studs, 110 a second per box | fully additive: white-lilac on a pale backdrop |
| Something that leaves the tip | the smoke sheet, a few a second, in the world, a longer life | life 0.5-0.8 s, speed 0.8-1.6 | |
| Flames, flow lines, sparks that fall | the fire's pieces: "Pieces that worked" below | | |

A cloud along an item is boxes of equal length, wider toward the tip and pushed to one side: an emitter's rate is per box, so an extra short box where the cloud should be widest made a ball there. On an item thinner than about a twelfth of its length, size the boxes from the cloud's width, not from the steel's.

**What was rejected** (the owner's verdicts on the frost builds; blade 0.76 studs wide, seen from 16.5 studs): a star-burst sprite and flat gem meshes beside the blade; soft glow dots of 0.5-1.6 studs on the blade (a large light); white dots of 0.13-0.24 studs falling beside it (snowballs); thin needles standing out of the blade's top. They are rows of the bar in 3k. From the glitter build (rejected with its build): an edge sheen dense enough to be a steady line (170 pieces a second per edge at `Brightness` 2) whitened the whole blade, so the item's own colour and shape were lost; keep a sheen to the edge's width and let the faces show.

**Limits** (from that review; numbers marked judgment are that lane's, not measured here). Work in single steps: a row per layer before code, then after every change six consecutive frames and one swing beside the target's sheet, the single worst difference written down, and only that changed. Check limits, not adjectives:

| Limit | How to check |
|---|---|
| Every life 0.35 s or less, the exceptions named and few | from the theme's data (the pack's `ItemAura.audit`) |
| No piece wider than the item allows (the fire: 1.5 blade widths); pieces alive in a stated range | the same |
| The item's own surface shows on at least half the blade | the blade's mean colour with the aura off and on. Three of the first four builds whitened the whole blade; treat it as a failed limit |
| One focus, three values: one bright place, a second small one at most, quiet between; white, a saturated body, a dark rim | a frame: white on no more than about 15% of the effect's pixels (judgment); density about 3 to 1 toward the focus |
| A piece is never seen alone | the swing frames: no lone dot left in empty air |
| The element is its own | its pull and body written down before a worked theme is opened: a frost aura with a torn body rising off the blade is the fire in another colour |

A game adds checks the lab stage does not have: bloom off or weak (the stage's bloom is far stronger than that second game's, and an aura tuned on it looks thinner there; points are tuned with bloom off); a pale floor in daylight seen from 30 to 45 degrees above (additive pieces vanish over snow and sand, only the paint layers carry the shape); the game's own play camera; the game's own swing effect (while it plays, lower the aura's world-space layers so one effect owns the arc: draft, not tried in a game); and a budget per screen instead of per item (twelve players' auras at once; a distance beyond which an item keeps two or three layers; no PointLight on other players' items).

**Sharp points.** A soft circle is a ball at any size. A glint needs a texture with a hard core and a steep falloff (optionally thin arms), shown briefly and rarely: that lane's blade uses a four-point star of up to 0.8 studs, alive 0.16-0.28 s, 0.8 to 3.2 a second along the whole blade. On a phone a 0.1-stud speck is 3 px and reads only by contrast and brevity (full size in the first fifth of its life, dead in 2-4 frames, a darker neighbourhood). Where the area around a point is already white, no point reads.

**Time.** No fixed period anywhere: every stream's rate breathes (x 0.7 to 1.0 by smooth noise, each layer on its own phase), a gust comes every 1.3-2.8 s for 0.3 s (body rates x 1.4-1.6), bursts of 3-7 sparks every 0.3-0.9 s, and the one PointLight flickers by noise. Anything that pulses on a beat reads as a heartbeat.

Working in Studio: a script's `Source` cannot be fetched from a Play client, so each round is stop Play, set the `Source` in Edit, start Play. A Studio window covered by another window rendered and recorded at 15 frames a second in our runs: bring it to the front before a recording that is read frame by frame.

**Check it** against the target at the target's own scale first: rotate and scale a capture so the item has the same length and angle as in the target frame, crop both alike and set them side by side, with a copy of yours shrunk to the clip's pixel size and blown up again (what a compressed clip keeps). Close captures were 4-6 times larger than the target and hid a density of about a quarter of it. Then **check it** on the stage above: at rest, in a close view of the upper blade and one of the guard, against the daylight sky, and through the sway and the swings; read sheets of consecutive frames next to the target's, and then watch it at real speed. A still can look wrong where the motion looks right, and the other way round.

**Cost** (one item, computed as rate x mean life, not profiled): the fire is 15 emitters and about 75 pieces alive; the glitter build 16 emitters and about 270; the vapor theme 27 emitters and about 264, of which about 170 are points. Other players' items run at a share of the rates (0.4 intended, not checked on a second client) and without the light.

## 3m. Contacts of a strike skill: painted pieces, beams and grain (flurry, heavy hit)

What a fist, a blade or a bolt throws up where it lands, when the skill is a run of contacts a few frames apart and each one must read as a drawn shape, not as a cloud. Read 3k first, and 3c for the clock and the beat table; this section is the pieces of one contact and how they were checked.

Evidence (2026-11-25, Studio Play on a desktop, a lab stage: two block figures, a camera about 19 studs from the contact at a field of view of 60, bloom on; a punch flurry of 3.6 s with a start, light taps every 0.075 s, heavy contacts every 0.066 s, a wind-up, an impact frame of 0.1 s and a last hit). It was built by hand three times against a public showcase clip of a similar skill, read frame by frame (numbers and method only; our own moves and pieces). The owner called the first build, particles and stretched sprites only, far below the target; of the second, whose heavy contact was one painted splat with a single outline, he said that scene was very poor and asked for a finer read of the frames; the third, this section, he called much better. That verdict is for the heavy contact; the other phases are our own reading. Nothing ran on a phone or in a published game.

**Ready parts.** The RoDesigner kit pack `fx` (`list_kit_packs`, `get_kit_pack`) has the painter (`FxPaint`), the piece engine (`SkillFx`: a sprite pool, needles and arcs from beams, emitters as data, a timeline), the flurry as a worked example to start from (`SkillFxExamples`), and the rules with every number (`docs/SKILL-FX.md`). Without the pack, build to what follows.

**Read the target first.** In a flurry every frame differs, so four frames of a phase tell little: read every frame of each phase, two at a time, at 4 times the clip's size or more, and write per frame which pieces are there (shape, edge soft or hard, colour steps inside, how far each reaches against a body). Then compare your build at the target's full frame, beat for beat, and at one crop of the contact cut the same way from both. Two mistakes cost us a build each: comparing against zoomed crops of the target made every size half or less, and a list of "what still differs" was taken for a pass.

**Three kinds of piece**, each new on every contact:

| The target shows | Piece | What failed in its place |
|---|---|---|
| A shape with points, lobes, a dark inside: a splash, a burst, thrown shards | a picture painted in code into an `EditableImage` and shown on a `BillboardGui` for 0.05-0.13 s | particle sprites from a texture pack: confetti and cloud at any rate; several flat pieces of one colour at 5 studs: one mass |
| Anything long and thin with a point at each end: needles, speed lines, crescents | Beams: a needle is two Beams back to back sharing a middle attachment (width 0 to w, w to 0); an arc is one curved Beam | a particle stretched along its velocity keeps square ends; a painted picture of spikes stretched over 13-19 studs showed stair steps (256 px) |
| Grain: specks, dots, mist, short dashes | particle emitters, emitted by count | |

A published game needs "Allow Mesh / Image APIs" on in its settings for `EditableImage`. Painted pieces are one-shot contact flashes, the case 3k's "No picture pieces" row allows: they live 3 to 8 frames, a new picture and a new turn on every contact, never in a loop or an always-on effect.

**Painting a shape.** Build it as a union of primitives, not as one outline round a centre: a shard (a base point, a direction, a length, a half-width that narrows to a point by a power, a sideways bend) and a blob (a circle whose radius wobbles by noise). One outline gave a symmetric leaf with lobes of one length (the second build); a union gives groups of shards with a long and a short side, a fan thrown one way, drips with round ends and loose chips, in one picture. Colour comes from three things:

- The distance to the edge (two chamfer passes over the mask): a dark line 1-3 px wide all round. A shard thinner than the line comes out dark all through, so thin tips and long thin spikes go dark by themselves, as drawn splashes do.
- A second, smaller shape inside: the burn (near black, a darker band of the body colour round it) and thin veins along some shards. Off-centre.
- Noise: the body colour turns toward a deeper tone in patches and toward the burn.

Paint 4-5 pictures per kind once at start (256 px each, one a frame; about 0.13 s each in a plain Luau runner, not timed in Studio) and pick one at random with a random turn per contact. Kinds that made the heavy contact: a crown (shards all round a small body), a fan (everything thrown to one side from a root a quarter of the picture off the middle, so the root sits on the contact and the fan points where you turn it), a spear (a pointed lens with a barb, flown point first), a handful of torn chips (mostly dark), a white flare (a lumpy body with thick rays). Write colours for the brightness the billboard is shown at: at `Brightness` 1.7 a stored 255 red clips flat, and we stored the dark tones at 1 / 1.7 of what the screen should show (set by eye, the brightness curve was not measured). A palette table (body, deep tone, band, burn, line, mark) makes the same shapes another element.

**One heavy contact** (sizes in studs on avatar-sized block figures, lives in seconds):

| Piece | Count | Size | Life | Notes |
|---|---|---|---|---|
| Crown | 1 | 8.5-12 | 0.085 | on the contact, `Brightness` 1.7 |
| Fan | 1-2 | 6.5-11.5 | 0.075-0.08 | root on the contact, each pointing its own way |
| A darker crown | every other contact | 4.5-7 | 0.07 | `Brightness` 1: a crimson piece on the red |
| Spears | 3 | 3-5.5 | 0.09-0.13 | start 4-7.5 from the contact, move out at 18-40 a second |
| Chips | 2 handfuls | 3-5 | 0.1 | start 3.5-7 out, 8-18 a second |
| White flares | 2 | 5-8 and 2.4-4 | 0.06-0.065 | `Brightness` 3.4 |
| Thin dark lines | 5 | 12-30 long, 0.07-0.15 wide | 0.06-0.1 | Beams through the contact, any direction in the picture plane |
| Thin white arcs | 4 | radius 1.8-5.5, width 0.12-0.5 | 0.08 | parts of rings on random planes |
| Needles | 2 white, 3 body colour, 2 stray, 5 dark dashes | 10-22 long; white 0.3-0.62 wide, body colour 0.55-1.15 | 0.1-0.19 | a flat fan to one side of the frame; they stay near their start and stretch |
| Grain | 10 sparkles, 6 dots | under 0.35 | 0.1-0.55 | plus 1-2 clusters of chip specks of 2-3.5 studs |

Pieces grow from 0.78 to 1.12 of their size over their life and are cut off, not faded. Most point up and to the struck body's side (two in three between 55 and 200 degrees on screen with the striker on the right of the frame, one in seven downward), so the floor stays clear. A light tap is a white dot of 1.1 studs for 0.05 s, a soft colour dot and 5 specks, on a steady cloud of chips and specks (about 300 pieces a second) that thins to almost nothing under the heavy flurry. The bodies must read through that cloud: its pieces run 30-66% transparent; at 0-10% the same stream was one opaque ball over the struck body.

**Depth.** The painted pieces sit 0.45-0.75 studs toward the camera from the contact (the white flares 1.3): in front of the struck body, behind the striker, each kind at its own offset so that they sort the same way every time. Left on the contact they stood behind both bodies and read as a backdrop. The offset belongs to one camera and one pair of bodies: at 0.9-1.3 the splash covered the striker's arms and chest on the same stage. Set it on a recording, looking at the striker's arms.

**White.** A billboard does not bloom however high its `Brightness`, so the flare is a hard white picture and the glow is a separate soft additive dot behind it. Three traps, all seen: a soft edge 14 px wide (of 256) left the flare half see-through over most of its body and it read pink on the red (5 px keeps it white); a glow dot at `Brightness` 4.5-7 read as a solid ball 3 studs across (now one dot of 1.8-2.3 studs at transparency 0.66; widened to 2.4-3.2 it was a pink disc on the red again); a wide pale glow disc behind a white star read as a sticker on a plate.

**Engine facts** (measured in Studio Play while building):

- `Emit` after moving one attachment twice in a frame puts both bursts at the second place: keep 3 attachment copies per emitter and use them in turn.
- A `BillboardGui` under an `Attachment` drew nothing until its `Adornee` was set to that attachment.
- A `Rate` written from a script every frame emitted nothing: emit by count from an accumulator (`Emit(n)`).
- A `Highlight` fill (`DepthMode` Occluded) is also drawn over billboards that stand in front of its model: a hit pulse on the struck body painted that body's outline on the splash and tinted the white flares. Keep such a pulse to moments with no billboard in front, or use the outline only.
- Painted pictures did not show in Edit-mode screenshots, only in Play.
- At a low frame rate one step is longer than a short life: at 15 frames a second a piece that lives 0.065 s was never drawn. Draw every piece once at age 0 before it starts to age.
- A frozen skill clock shows no painted piece: a piece is drawn when the clock crosses its event with a step above 0, so a paused frame or a jump to a time is empty. Check on slow recordings.

**Recording and checking.** A Studio window in the background ran at 15 frames a second, and at 7.5 while a capture ran, so a "real time" clip of a flurry misses most contacts. Run the skill clock at 0.25 (3c) and play the recording back 4 times as fast: 30 distinct frames per second of skill time. A capture stopped at 30 s with no warning, so one loop at 0.25 fits and one at 0.125 does not. Find the loop start by a value only the start sets (ours: the start beat's blue tint); the contrast alone also rose on the wind-up. Cut frames of the heavy flurry at the crop used for the target, set them side by side, and read: is the splash lopsided, does it have a line and a dark inside, are loose pieces thrown clear, is the white white, does it cover the struck body. Judge new shapes before Studio is touched: the painter is plain Luau and renders offline in a few seconds with any Luau runner when the engine calls are stubbed.

**Another element is its own shapes, not a palette.** The same flurry painted and tinted blue was the same explosion in blue (seen). A second builder, working only from this section and the kit, made a frost skill of the same structure by keeping the piece engine and writing a shape table first: what the body is cut like (faceted crystals in three tones with a pale cut core, where the red had lobed splashes), what replaces the burn (zigzag cracks), how the loose pieces move (splinters that fall and turn), what the impact frame does to the struck body (frozen pale, not lit). It kept the dark line, the sizes, lives and counts above, the white flares and the needle fan. Where the element's colours are the stage's (blue on a navy floor), the thin pieces go first: move them to the pale end and keep the line (seen, not judged by an owner).

**Still different from the target** (fourth build): ours is hard-edged where the target is soft and blooms; our crowns have more and thinner spikes than the target's broad lobes; the light flurry's cloud is thinner than the target's haze. Not measured: cost on a phone, the piece counts under several players' skills at once.

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
| Every effect passes the bar of section 3k from the player's camera at its real distance, and is counted against the 3k budget | yes |
| Anything that moves carries its effect (`follow` or `travel`, 3i): its trail has no gaps at full speed and nothing stays where it started | yes |
| The same 30 s played with all effects off, then on: every channel is missed when off | yes |
| Test on a low-end phone profile: FPS stable during the busiest effect moment | yes |
| Mute and volume settings exist; music loops without gaps | yes |
| Mood readable in the first screenshot (matches the style lane) | yes |
| The user played the busiest feel moment and the mix for 5+ minutes; notes in `docs/playtests.md` (`roblox-game-pipeline` section 7a) | yes |
