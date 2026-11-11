---
name: roblox-character-motion
description: "Use when a Roblox character must perform a custom motion: exercise loops (push-ups, squats, lifting), sitting, climbing, carrying, interacting with a machine or prop, emotes or any animation the agent would build by script. Covers which authoring path to use, keeping hands and feet on their contact points, baking, uploading so it works in live servers, and how to verify it. Also when a motion looks wrong (body floats, sinks into the floor, hands miss the bar, arms flail, feet slide), when code uses KeyframeSequenceProvider or builds Keyframes and Poses by script, when an animation plays in Studio but not in the published game, when choosing between Animation Editor, Blender, Animation Capture, IKControl and procedural joints, when a script errors with 'Unable to assign property C0', when a display rig's limbs fall off an anchored root, when a carried item is held only some of the time, or before a feel checkpoint for character motion (roblox-game-pipeline section 7a)."
last_reviewed: 2026-11-09
sources:
  - https://create.roblox.com/docs/reference/engine/classes/KeyframeSequenceProvider.md (temporary ids are Studio only)
  - https://create.roblox.com/docs/reference/engine/classes/AnimationClipProvider.md
  - https://create.roblox.com/docs/reference/engine/classes/IKControl.md
  - https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint.md
  - https://create.roblox.com/docs/reference/engine/classes/Animator.md (StepAnimations)
  - https://create.roblox.com/docs/reference/engine/enums/PoseEasingStyle.md (CubicV2)
  - https://create.roblox.com/docs/cloud/guides/usage-assets.md (Animation asset type)
  - https://create.roblox.com/docs/animation/capture (beta)
  - https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840
  - https://devforum.roblox.com/t/full-release-animation-clip-editor-improved-importing-and-gltf-support/4260501
  - https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208
  - original Studio tests 2026-11-03 (push-up loop, default R15 rig, scaled rigs)
  - original field notes (2026-10 to 2026-11)
---

# Character motion

Pair with `roblox-feel-audio-vfx` section 3a (loading, priorities, replication), `roblox-fun-effects` (what a motion should reward) and `roblox-blender-export` (rigs and FBX). Show `assets/pushup-contact.jpg` when explaining why a motion looks wrong: same rig, guessed angles against solved contacts, real Studio renders.

## 0. Rule zero: script-registered ids are Studio only

`KeyframeSequenceProvider:RegisterKeyframeSequence`, `RegisterActiveKeyframeSequence` and the `AnimationClipProvider` versions return temporary ids that "cannot be used outside of Studio" (docs). A game that builds its animations at runtime and plays these ids works in a Studio playtest and does nothing in the published game. Use them only to preview. For live servers, upload the clip (section 6) and play its `rbxassetid://`.

## 1. Pick the authoring path

| Motion | Path | Why / limits |
|---|---|---|
| Loop with fixed contacts (push-up, squat, plank, bench press, rowing, sitting on a machine) | Solve and bake by script (section 3, `scripts/ContactBake.luau` for push-ups), then upload | Exact contacts, rerunnable, no human needed until upload |
| Expressive or stylized clip (emote, celebration, finisher, idle with personality) | Human in the Animation Editor (IK posing built in) or Blender with the rig exported from Studio, imported through the Animation Clip Editor (FBX or glTF, several clips per file) | Best timing and arcs; a human publishes it |
| Motion from real footage | Animation Capture (Animation Editor, R15, one person, clip under 15 s) | Still beta; human operated; clean up after |
| Contact that must adapt (uneven ground, any avatar size, reaching a moving handle) | `IKControl` at runtime on top of a clip | Corrects contacts per body; see section 4 for measured accuracy |
| Small layered motion (breathing, bob, aim, lean) | Write `AnimationConstraint.Transform` (or `Motor6D.Transform` on old rigs) each frame in `RunService.PreSimulation` on the client | Cheap; skip when `Animator.EvaluationThrottled`. Joint rules on `AnimationConstraint` rigs: section 5 |
| Blending many clips by state | Animation Graph (full release 2026-07-15) | Visual graph with parameters; clips still need uploaded ids |
| Everyday humanoid motion described in words (limp, wave, sit down), or an R6 clip to move to R15 | Prompt to Animation or Motion Rebuilder (Studio Beta 2026-11-05: File > Beta Features > Animation Generation in Assistant; `/generate_animation` or Studio MCP `generate_animation`) | R15 only; about 20-30 s per action; complex sport and swimming moves are weak (DevForum). Prompt tips from the post: name who moves and how they feel, "then" for a sequence, "while" for two at once, put a stop in the same sentence, name the end pose, add "in place" or "loop". Untested by us; contacts still need section 3 and the clip still needs an upload with the user's yes |
| Not this | Joint angles typed by guess, root anchored in the air | Measured in section 4: body sinks 1.43 studs into the floor |

Not available yet (2026-11): shared animations across creators (early 2027), root motion (mid 2027). Animation ids follow new uploads only until 2027-03-31: after that an id without `&version=<n>` keeps the version current on that date (asset versioning, `roblox-engine-2026` section 6), so pin versions or use `AssetService:GetLatestVersionUriAsync`.

## 2. Write a motion spec first

Before any key, write five lines and show them to the user with one reference (a video frame or a sketch):

```
Motion: push-up loop on the floor mat
Contacts: toes and both palms stay on the mat top the whole rep
Pivot: body rotates about the toe line; hips stay on the shoulder-toe line
Key poses: top (arms straight), bottom (chest 0.35 studs above the mat)
Timing: 1.2 s per rep, eased down and up, first key = last key, Looped
```

The contact list and the pivot are what make it read right. "Arms bend 90 degrees" is not a spec: the elbow angle follows from the contacts.

## 3. Contact-first method (tested)

1. **Measure the rig, not your memory.** Read joint `C0`/`C1` and part sizes from the actual R15 rig (`Players:CreateHumanoidModelFromDescriptionAsync` makes one in Edit mode; we tested the older non-Async name, now deprecated). (`AnimationConstraint` rigs and rigs without `Motor6D`s: section 5.) Compute rest positions by forward kinematics: `part1 = part0 * C0 * Transform * C1:Inverse()`.
2. **Place the root from a contact.** Anchor `HumanoidRootPart` so the pivot contact (the toe tip for a push-up) sits exactly on the floor top, and move the body only through the `Root` joint: rotation about the pivot point `P` (in root space) is `Transform = C0:Inverse() * (CFrame.new(P) * rotation * CFrame.new(-P)) * C0`.
3. **Solve limbs to targets.** Fix each hand or foot target on the floor, then solve the two angles (shoulder and elbow) that put the palm on it at every key. A two-bone limb has two solutions; choose the one with the elbow toward the feet (the job a `Pole` does in `IKControl`). The wrong pick bends the elbow forward like a bird's knee.
4. **Keep the contact face flat.** Rotate the wrist (or ankle) so the palm stays level with the floor; without it the hand's corner digs in (measured 0.4 studs).
5. **Key every joint.** Give every joint a pose with `Weight` 1, identity where nothing moves, and use priority `Action` or higher. A joint left at weight 0 falls through to lower-priority tracks such as the default Animate idle or fall (the likely cause of flailing arms on an anchored character).
6. **Sample the curve.** Put 6+ keys per half rep on an eased curve with linear poses between them, or few keys with `Enum.PoseEasingStyle.CubicV2` (`Cubic` has a known direction bug). Units: CFrame angles are radians; mixing degrees into a sum broke our first wrist solve.
7. **Preview** with `RegisterKeyframeSequence` and `Animator:StepAnimations(0)` after setting `TimePosition` (works in Edit mode from the command bar or a plugin, so poses can be frozen, measured and screenshotted without Play).

`scripts/ContactBake.luau` does steps 1-6 for a push-up: `ContactBake.pushup(rig, at, floorY, opts)` returns the `KeyframeSequence`, the root `CFrame` to anchor at, and the solver error; `ContactBake.measure(rig, floorY)` returns contact heights. It uses Motor6D joints; adapt `motor()` for `AnimationConstraint` rigs. The same pattern covers squats (feet fixed, pivot at the ankles) and bench presses (back on the bench, hands on a bar target).

## 4. Measured (Studio, 2026-11-03, default R15 rig)

| Variant | How | Worst contact error over a rep |
|---|---|---|
| A. Guessed angles | Root anchored in the air at -70 degrees, angles typed by hand | Feet 1.43 studs and head 0.41 studs inside the mat at the bottom; feet 0.19 above at the top |
| B. Runtime IKControl | Body rotated about the toes, `IKControl` (Position type, `Pole` set) pulling palms to floor targets, server-created NPC | Hands 0.14-0.33 studs into the mat; server and client agreed. Edit mode `StepAnimations` does not evaluate IK |
| C. Solved and baked | Section 3 steps 1-6 | 0.02 studs; same on rigs at 0.9x and 1.2x height and three facings when baked per rig |
| C on another body | Clip baked on the default rig played on a 1.2x-height rig / a 0.9x rig | Hands 0.26 into the mat, feet 0.15 / hands 0.13 above, feet 0.08 |

What follows:
- Bake on the body the game shows most (or lock body scale during the workout), and accept about 0.1-0.3 studs on very different avatars, or add client `IKControl` on top of the baked clip to pin palms per body (untested combination).
- IKControl with Position type does not keep the palm flat; Transform type might (untested).

## 5. Character during the motion

- Anchor `HumanoidRootPart` at the baker's CFrame, play the track from the server for NPCs (the player's own client for the player character, `roblox-feel-audio-vfx` section 3a), and on stop: stop the track, move the root to a free standing spot, unanchor.
- Rep rate in the game's data must match the clip length (`period`), or rewards and motion drift apart.
- The machine or mat height comes from the built model at runtime (`floorY` = top of the mat part), never a typed constant.
- R15 only: R6 limbs are single parts and cannot bend.
- **Joints on `AnimationConstraint` rigs:** `C0`, `C1`, `Part0` and `Part1` are read-only aliases of the attachments (docs, `roblox-pitfalls` section 4), so assigning `joint.C0` fails (field observation: the error text was "Unable to assign property C0"); write `Transform` instead. The docs layer procedural motion by multiplying into the current `Transform` while an `Animator` rewrites it every frame; with no track playing nothing resets it, so the same code compounds each frame and on every run (field observation). Record the base `Transform` before the motion, write `base * delta`, and restore the base when the motion ends and when it is interrupted.
- **Rigs from the `CreateHumanoidModelFrom...` builders:** do not assume `Motor6D`s. Find joints with `FindFirstChildWhichIsA("AnimationConstraint")` first, then `Motor6D` (docs). Field observation (the docs do not say which joint class the builders return): an Edit-mode rig with catalog bundle body parts had no `Motor6D`s and its parts sat scattered; place each part from its `*RigAttachment` pair, walking out from the root (`child.CFrame = parentAttachment.WorldCFrame * childAttachment.CFrame:Inverse()`).
- **Display rig with an anchored root** (statue, podium; never a player character; field observation, the docs do not describe it): `Players:CreateHumanoidModelFromUserIdAsync` can return an R15 rig with `AnimationConstraint`s. With only the root anchored its limbs fell on the client even with `IsKinematic = true` (docs: equivalent to `Motor6D`). Replacing each `AnimationConstraint` with a `Motor6D` (`Part0`/`Part1` = the attachment parents, `C0`/`C1` = the attachment CFrames) held the rig together. Check any anchored-root rig in Play on a client, not only on the server.
- **Held items:** one source of truth per grip. A second pose that drives the same arm joints (a stance over a carry) replaces the carry pose, so the item is held only some of the time (field observation). Give each grip one owner, re-assert it every frame, and place the item from the real hand positions.

## 6. Ship it (upload)

| Route | Notes |
|---|---|
| Animation Editor, Publish to Roblox | Manual. For a group game set the Creator to the group. To hand a baked sequence to the user, save it into the place (for example `ServerStorage`) and ask them to open and publish it in the Animation Editor |
| Open Cloud Assets API, `assetType` Animation | `.rbxm` or `.rbxmx` up to 20 MB, `assets` write scope, owner in `creationContext` (user or group that owns the game), poll the operation. Docs warn that files made outside Studio may fail; a script-built sequence has not been tested by us. Ask before uploading (it creates an asset on the user's account) |
| `AssetService:CreateAssetAsync` | Does not support animations |

An animation owned by another account usually fails to load. After upload, replace the temporary id in code with the uploaded `rbxassetid://`, then test in a published place or a Team Test, not only Studio Play.

## 7. Verify before showing the user

1. Freeze at `t = 0, 0.25, 0.5, 0.75` of the rep (or every 0.05 s) and assert every contact within 0.05 studs of its surface (`ContactBake.measure`).
2. Screenshot side view and three-quarter view at top and bottom with a fixed camera: in Edit mode use `screen_capture` with `camera_position` (poses are frozen with `StepAnimations`, section 3 step 7); in Play (runtime IK) use the render-step camera in `roblox-pitfalls` section 3 ('Screenshots in Play'). Body colors must differ from the floor; a default rig is black.
3. Repeat on a 0.9x and a 1.2x height rig, and one wide body, or record the error you accept.
4. Then let the user watch it in Play (`roblox-game-pipeline` section 7a): numbers prove contact, only a person judges weight and timing.

Defects to look for: body sliding along the floor, feet or hands inside surfaces, elbows or knees bending the wrong way, a pop at the loop seam (first key differs from the last), arms or head overridden by idle or fall, motion faster than the rep reward.
