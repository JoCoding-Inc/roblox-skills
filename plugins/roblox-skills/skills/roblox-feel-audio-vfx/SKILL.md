---
name: roblox-feel-audio-vfx
description: "Use when adding or tuning game feel in Roblox: sound effects and music, particles, beams, trails, hit feedback, screen shake, in-game animation (Animator, priorities, animation events, emotes), lighting and atmosphere for mood, with mobile budgets and a checklist."
when_to_use: "Also when a game feels flat or silent, effects are invisible or too heavy on phones or look thin and cheap next to concept art, audio is too loud, overlaps or loops wrongly, an animation does not play, replicate or gets overridden, lighting looks washed out or too dark (also a night area that reads as a dark blob), the camera swings or shakes until players feel dizzy, or when planning the 'feel' decision cards in roblox-game-pipeline stage 4."
last_reviewed: 2026-11-04
sources:
  - https://create.roblox.com/docs/audio (objects, effects, assets)
  - https://create.roblox.com/docs/effects/particle-emitters (Rate limits, fill rate)
  - https://create.roblox.com/docs/environment/lighting and /atmosphere
  - https://create.roblox.com/docs/reference/engine/classes/Animator.md and AnimationTrack.md, enums/AnimationPriority.md
  - https://create.roblox.com/docs/animation/events and /characters/emotes
  - original (feel checklist and budgets are judgment, not measured)
  - original field notes (2026-10 to 2026-11)
---

# Game feel: audio, effects, lighting

Feel is what makes the same loop satisfying. Plan it as part of the loop (stage 4 "Feel" cards), then budget it for phones.

## 1. Feedback map (planning)

For each frequent action write what the player sees, hears and feels: action, result, reward, error. Example: tap to collect -> pop sound + number rising + currency counter bump. Every repeated action needs feedback in at least two channels (sight + sound). Errors need a different, clear cue (never the same as success). For any effect longer than a short tick (reveals, auras, celebrations, finishers), first fill the fun card in `roblox-fun-effects` section 1: what it rewards, who sees it, how it escalates.

## 2. Audio (docs)

- Objects: `AudioPlayer` plays an asset id, `AudioEmitter` is a virtual speaker in the 3D world, `AudioListener` a virtual microphone, `AudioDeviceOutput` the real output; `Wire`s carry audio between them. Effects (`AudioEqualizer`, `AudioCompressor`, `AudioReverb`, ...) modify a stream without changing the asset.
- Use positional audio (emitter) for world sounds and non-positional for UI and music.
- Assets: upload only audio you have rights to, or pick from the Creator Store (100,000+ free effects and tracks). Record source and license in `assets/LICENSES.md`.
- Plan a small set: UI click, success, error, reward, ambient loop, one music track per mood. Reuse; do not stack ten variants.
- Mix: music lower than effects, loudest cues are rare cues. Test with the device volume low and on phone speakers.
- Memory: do not load every sound at join; load per area or on demand (`roblox-store-art-pack` section 7, loading tiers).
- Provide a mute/volume setting and keep music from restarting on every respawn.

## 3. Effects

- `ParticleEmitter`: one emitter makes up to 400 particles per second (100 on mobile) according to the docs; keep `Rate` low and `Lifetime` short. Particle size costs GPU fill rate, so many large overlapping particles hurt phones.
- Flipbooks (`ParticleEmitter.FlipbookLayout` 2x2, 4x4, 8x8 or `Custom` with `FlipbookSizeX`/`FlipbookSizeY`) cost texture memory, and clients switch them off when low on memory (docs), so an effect must still read without its flipbook. `ParticleEmitter.TimeScale` (0-1) slows or freezes an effect for a hit stop.
- Size particles for the real camera distance: 1-1.5 stud stars all but vanished 40-100 studs away, while 1.8-3 studs by tier read (field observation, 2026-11-04). Check in a screenshot from the player's camera, not up close.
- The built-in `rbxasset://textures/particles/*` textures plus thin Trails read as a wireframe of lines on a dark sky next to concept art. A release-quality burst needs custom glow, star, streak and sparkle (flipbook) textures, dense emission along the shape, additive layers (`LightEmission` 1, `LightInfluence` 0) and a moderate `Bloom`. Dark semi-transparent layers over a night sky render brown and muddy; use fewer, brighter additive ones (field observations, 2026-11-04).
- Beams, trails, lights, highlights: use sparingly; each light source and highlight has a cost.
- Burst on events, not constant emission; destroy or disable emitters when done; cap simultaneous effects per player and per server.
- A hit or aura that reads as finished is a stack: a flipbook or mesh shape, a white-hot additive core grading to the effect color, an alpha smoke layer, sparks, debris and a camera kick (rules below). Quality comes from texture art and layering, not particle count (judgment from 2026 artist breakdowns). Free textures to start from: Creator Store "VFX PACK" (Euphoric Games Community, 112672322113504, +970/-30) and "Rei's Particle Pack" (10198615035, +990/-10), both free models without scripts (read 2026-11-05; contents not reviewed by us: insert, audit per `roblox-store-art-pack` section 3 and look before use).
- Hit feedback: flash/highlight + sound + small camera shake or knockback; damage numbers short and readable.
- Screen shake: small amplitude, short, with an off switch in settings (`roblox-fun-effects` section 10: "Reduce effects" also removes camera kicks; `roblox-fun-effects` section 8 sizes the kick and hit stop).
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

## 4. Lighting and atmosphere (docs)

- Choosing a mood or an effect style: show the same spot in each option as an image (and a short clip only for motion) before building it (`roblox-game-pipeline` section 10a: greybox screenshots first, or images from a generator the user has connected).
- `Lighting.LightingStyle`: `Realistic` is the most advanced look, `Soft` is the flat retro look; pick with the style board lane (`roblox-game-pipeline` stage 3).
- Set colors on `Ambient`/`OutdoorAmbient`, intensity on `Brightness`/`ExposureCompensation`, time on `ClockTime`; `GlobalShadows` toggles shadows; `PrioritizeLightingQuality` decides whether quality or view distance scales down first on weak devices.
- `Atmosphere` adds haze and depth (density, offset, color); post effects (bloom, color correction, depth of field) in small amounts. Judge colors in Studio, not in renders.
- Bright daylight simulator look: `roblox-store-art-pack` section 1. Horror or night: lower brightness, fog and a few small lights instead of global brightness, except where the player must read the ground (next bullet).
- Space or night area the player must read: keep the black sky (`ClockTime` 0) and no haze over objects (`Atmosphere.Density` 0; the docs say Density does not directly affect the skybox) but do not dim the surfaces. Starting values from one test scene, not a docs rule: `Brightness` about 3 with mid-grey `Ambient` (RGB about 125) and `OutdoorAmbient` (RGB about 165) read well; `Brightness` 0.6 with a dark `Ambient` made the area one unreadable blob. `OutdoorAmbient` is clamped to at least `Ambient` in every channel (docs). Separate the surfaces by value too, not only by light: under an indigo night every mid-tone surface merged into one flat lavender until the floors went warm and light and the stage pads dark (field observation, 2026-11-04).

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
| Test on a low-end phone profile: FPS stable during the busiest effect moment | yes |
| Mute and volume settings exist; music loops without gaps | yes |
| Mood readable in the first screenshot (matches the style lane) | yes |
| The user played the busiest feel moment and the mix for 5+ minutes; notes in `docs/playtests.md` (`roblox-game-pipeline` section 7a) | yes |
