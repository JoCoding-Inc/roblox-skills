---
name: roblox-feel-audio-vfx
description: "Use when adding or tuning game feel in Roblox: particles, beams, trails, hit feedback, screen shake, FOV kicks, hit stop, screen flash and edge tint, vibration (haptics), coin fly-to-counter and other reward feedback with ready client scripts (camera, world and screen effects), in-game animation (Animator, priorities, animation events, emotes), lighting and atmosphere for mood, with mobile budgets and a checklist. Sound effects and music: roblox-audio. Also when a game feels flat or its effects feel simple, effects are invisible or too heavy on phones or look thin and cheap next to concept art, an animation does not play, replicate or gets overridden, lighting looks washed out or too dark (also a night area that reads as a dark blob), bloom bleeds light everywhere, a night scene needs glow under a light budget or must match a concept's mood, the camera swings or shakes until players feel dizzy, or when planning the 'feel' decision cards in roblox-game-pipeline stage 4."
last_reviewed: 2026-11-12
sources:
  - https://create.roblox.com/docs/audio (objects, effects, assets)
  - https://create.roblox.com/docs/effects/particle-emitters (Rate limits, fill rate)
  - https://create.roblox.com/docs/environment/lighting and /atmosphere
  - https://create.roblox.com/docs/reference/engine/classes/Animator.md and AnimationTrack.md, enums/AnimationPriority.md
  - https://create.roblox.com/docs/animation/events and /characters/emotes
  - https://create.roblox.com/docs/reference/engine/classes/HapticEffect.md and GuiService.ReducedMotionEnabled (creator-docs 7cbffff, 2026-11-10)
  - Squirrel Eiserloh, "Math for Game Programmers: Juicing Your Cameras With Math", GDC 2016 slides (read 2026-11-12)
  - https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html and Xbox Accessibility Guidelines 117 and 118 (read 2026-11-12)
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
- House rule (owner): VFX are Blender meshes (`roblox-blender-export`) plus gradient or flipbook textures. No block tiles and no default sparkles (the `Sparkles` object or the built-in particle textures). A glowing Blender mesh without a `SurfaceAppearance` (field note, 2026-11-09): model the emissive shapes as their own geometry in flat `Neon` colors (Neon on a textured MeshPart does not glow, `roblox-pitfalls` section 4), layer a dark non-Neon shade mesh for the dark parts, and put textures only on lit surfaces. When a brief forbids uploads, a portal vortex that worked without them (field note, 2026-11-09) used flat curved Beams as spiral arms around a centre: `CurveSize0` and `CurveSize1` bend a beam into a Bezier curve (docs), `FaceCamera` is false, and the built-in glow texture is stretched along each arm (section 4, "Night glow without lights").
- Beams, trails, lights, highlights: use sparingly; each light source and highlight has a cost.
- **A `Highlight` skips transparent parts.** It drew no outline and no fill on parts with any `Transparency` above 0: hologram parts at 0.06 lost the whole rim and tint (toggled live in Studio, field note 2026-11-11). The docs do not say so; a Roblox staff reply says highlights on transparent parts have not worked for years, and posters there report that parts inside a model with a Humanoid still get them (DevForum t/4678843, 2026-08-20). Keep highlighted parts at `Transparency` 0 and make a hologram from a dark `Neon` colour plus the Highlight fill. Check a Highlight against a plain background before trusting a capture: a bright portal behind the model passed for a rim.
- **Curved Beams.** A Beam is a cubic Bezier: P1 sits `CurveSize0` studs along +X of `Attachment0`, P2 sits `CurveSize1` studs along -X of `Attachment1` (docs, effects/beams). For a circle of radius R from four quarter-arc beams, point each attachment's X axis along the direction of travel and set both sizes to +0.5523 R, the usual Bezier quarter-circle constant (4/3 x (sqrt 2 - 1)); a negative `CurveSize1` drew a hook at each joint (field note, 2026-11-11).
- Burst on events, not constant emission; destroy or disable emitters when done; cap simultaneous effects per player and per server.
- Draw where the server acts: a drop, hit spark or pickup appears at the position the server uses. One game's server walked enemies on the road centre line while clients drew them fanned out, so coins fell on the centre line away from the visible death, and the owner saw it on a phone (field note, 2026-11-09). Compute such positions with one shared pure function that server and client both call.
- A hit or aura that reads as finished is a stack: a flipbook or mesh shape, a white-hot additive core grading to the effect color, an alpha smoke layer, sparks, debris and a camera kick (rules below). Quality comes from texture art and layering, not particle count (judgment from 2026 artist breakdowns). Free textures to start from: Creator Store "VFX PACK" (Euphoric Games Community, 112672322113504, +970/-30) and "Rei's Particle Pack" (10198615035, +990/-10), both free models without scripts (read 2026-11-05; contents not reviewed by us: insert, audit per `roblox-store-art-pack` section 3 and look before use).
- Hit feedback: flash/highlight + sound + small camera shake or knockback; damage numbers short and readable.
- Screen shake: small amplitude, short, with an off switch in settings (`roblox-fun-effects` section 10: "Reduce effects" also removes camera kicks; `roblox-fun-effects` section 8 sizes the kick and hit stop; section 3b has the shake model and a script).
- Camera rules (field observation): only the object the camera follows (normally the player character) and the player's own actions shake or re-aim it; contacts from other objects (extra projectiles, NPCs, spawned copies) never do, or the screen swings until players feel dizzy. Shakes combine by max, never by sum: keep one amplitude, set it to the larger of the current and the new value, and clamp it.
- Animations: key poses readable at phone distance; 3-5 core animations first (idle, move, action, hit, reward).

## 3a. Playing animations in game (docs)

- Load through the `Animator` under the Humanoid or `AnimationController`: `Animator:LoadAnimation(animation)` (the Humanoid's own `LoadAnimation` is deprecated). Each call makes a new track, so load once and cache it, or find it with `Animator:GetTrackByAnimationId`. The Animator must be in the Workspace.
- Replication: a player's own character animations started on that client replicate to everyone. NPC and other non-character animations must be loaded and played on the server, and the `Animator` must be created on the server, or nothing replicates.
- Priority (`AnimationTrack.Priority`, `Enum.AnimationPriority`): default and catalog animations play at `Core`; developer animations use `Idle`, `Movement`, `Action`, then `Action2`-`Action4` (highest). Higher overrides lower per joint, so an attack set to `Core` or `Idle` gets swallowed by walking.
- Timing: add event markers in the Animation Editor (settings > Show Animation Events) and connect `AnimationTrack:GetMarkerReachedSignal("Name")` for footstep sounds, VFX bursts and hit frames. Markers are presentation: the server decides damage by its own timing (`roblox-combat-tools`). `AdjustSpeed`, `AdjustWeight`, `Looped` and the `Ended` event cover the rest.
- Emotes: `HumanoidDescription:SetEmotes` then `SetEquippedEmotes` (up to 8 in the wheel); play one with `Humanoid:PlayEmoteAsync(name)` (`PlayEmote` is deprecated though the emotes guide still shows it). Hide the wheel with `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)`; chat `/e` still works.
- Ownership: for a group-owned game, publish animations with the group in the Animation Editor's Creator field (docs). An animation owned by someone else commonly fails to load in the game (C).
- Custom motions (exercise loops, sitting, climbing, interactions) and any animation built by script: `roblox-character-motion`. Ids from `KeyframeSequenceProvider:RegisterKeyframeSequence` work only in Studio; upload the clip for live servers.
- Code that finds or edits R15 joints: Avatar Joint Upgrade replaces `Motor6D` with `AnimationConstraint` (`roblox-engine-2026` section 3).

## 3b. Feedback kit (scripts)

Three client ModuleScripts in `scripts/`, tuned together in one playable test place. The owner judged two versions in Studio (field note, 2026-11-12): one burst, one number and one shake per hit read as "simple"; the layered version below was accepted as the direction. Nothing was checked on a phone, and every number is judgment unless it carries another label.

| Script | Gives |
|---|---|
| `scripts/juice.luau` | camera shake, roll kick, FOV punch and held FOV, hit stop, screen flash, edge tint, colour grade, bloom and blur pulses, vibration, UI pop, count-up, fly-to-counter, behind one settings table |
| `scripts/vfx.luau` | world recipes: layered impact in 4 tiers, ground ring, dome, light pillar, slash arc, limb trail, highlight flash, afterimage, aura, dust, fireworks, loot that pops out and flies to the player |
| `scripts/uifx.luau` | screen recipes with no image assets: breathing and shine on buttons, ring, spray, confetti, coin rain, glow, rays, floating "+N", stamp slam, rainbow text, toast, letterbox, speed lines, card flip |

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

Rules the scripts encode:

- **Shake.** One trauma value from 0 to 1, shake = trauma squared, linear decay, smoothed noise instead of random numbers, and in 3D rotate the camera only (Eiserloh, "Juicing Your Cameras With Math", GDC 2016, slides read 2026-11-12). The script applies it after the camera update (`RenderPriority.Camera + 1`) and combines by max (the camera rule above). Measured in Studio at 70 FOV: about 0.1-0.3 degrees for trauma 0.3, 1 degree for 0.6, 1.6 degrees for 0.9; one degree is about 1.4% of the screen height. A `Scriptable` camera must set its `CFrame` every frame before that step, or the offsets add up.
- **FOV has one owner.** The script reads the resting FOV only while no punch or held offset runs, and other code changes it through `Juice.setBaseFov`. Two game sessions report that a kick still running when another script read "the base" became the new base (field notes, 2026-11-12, not re-tested here).
- **Hit stop has a budget:** at most 0.25 s of freeze in any second; a longer request is cut. Tracks frozen by overlapping stops are restored once. One tower-defence session ended at no stop for ordinary kills because a lane of small enemies stuttered (field note, 2026-11-12, not re-tested here).
- **Flashes.** Full-screen brightness changes stay under three per second: "no more than three general flashes and / or no more than three red flashes within any one-second period" (WCAG 2.3.1); Xbox Accessibility Guideline 118 counts a 10% luminance change as a flash and fails flashing over about 20% of the screen (both read 2026-11-12). The script allows 2 starts per second across flash and edge tint, caps a flash at 0.5 opacity and drops the rest, so a pulse that repeats (low health) keeps its period near 1 s.
- **Motion options.** Xbox Accessibility Guideline 117 asks for a way to turn off camera shake, bob and motion blur (read 2026-11-12); `GuiService.ReducedMotionEnabled` is the Roblox Reduce Motion setting (docs). `Juice.motionOn()` gates shake, kicks, FOV, blur, pops, flights and confetti; sound, colour, numbers and vibration stay. `Juice.settings` gives each channel its own switch.
- **Vibration.** `HapticEffect` runs on Android and iOS phones that support haptics, PlayStation and Xbox gamepads and Quest Touch; `Type` is `UIClick`, `UINotification`, `GameplayCollision`, `GameplayExplosion` or `Custom` with `SetWaveformKeys` (`FloatCurveKey` time in ms, value 0 to 1); the docs sample parents it to Workspace and plays it on the client; `HapticService` is the older API (docs, read 2026-11-10). The calls ran without errors in Studio, where nothing can be felt: tune strength on a real phone (not done).
- **Screen layers.** Flash, edge tint, letterbox, coin rain and speed lines live in a `ScreenInsets = None` ScreenGui (`roblox-ui-layout` section 3). Mark effect elements `KitTransient` so the device sweep leaves them out of the HUD budgets.
- **Textures.** `Vfx.TEX` points at built-in textures so the kit runs with no uploads. That is a prototype state: the house rule above still holds, so swap in the game's own star, soft glow, smoke, ring and soft-edged band textures before release. `rbxasset://textures/gradient.png` (the beam band) was checked in Studio only.
- **Cost.** Each call creates a few instances and cleans them up; that suits the local player's own effects. Pool and cap effects of other players and crowds (section 3).

Checking effects from an agent:

- `screen_capture` came back 1-2 s after the call, so a 0.3 s effect is gone. Read state per frame instead (camera angle against `Camera.Focus`, `FieldOfView`, instance counts) with a render-step probe, call the recipe with a long duration for the capture, or capture a beat that holds (a reveal's show beat) (field note, 2026-11-12).
- Keep an "all effects off" switch in dev builds and play the same 30 s with it off and on. A channel nobody misses is noise (judgment).
- A tween on a `NumberValue` that was never parented left the value at its start; drive such values from `RenderStepped` with `TweenService:GetValue` (field note, 2026-11-12; cause not isolated).

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
