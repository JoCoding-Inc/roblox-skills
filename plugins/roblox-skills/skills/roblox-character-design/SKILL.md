---
name: roblox-character-design
description: "Use when designing how characters, creatures, enemies, bosses, robots, turrets, towers, units, pets or mounts look in a Roblox game: shape language, silhouette at play distance, size against the avatar, menace or cute, role and tier shown by shape, one style across a roster, parts for animation, triangle budgets for crowds and bosses, and which tool makes them."
when_to_use: "Also when a roster of units, towers or enemies looks alike, reads small or toy-like, or cannot be read at play distance; before generating or modeling a batch of characters; when choosing Roblox Cube, Blender or a paid image-to-3D service for creatures and robots; when enemies feel cute instead of threatening; when an upgrade tier only changes color. Motion is in roblox-character-motion, Blender export in roblox-blender-export, rarity effects in roblox-fun-effects."
last_reviewed: 2026-11-08
sources:
  - https://create.roblox.com/docs/studio/avatar-settings (avatar heights)
  - https://create.roblox.com/docs/reference/engine/classes/Camera (FieldOfView is vertical, default 70)
  - https://create.roblox.com/docs/reference/engine/classes/ViewportFrame (ImageColor3, Ambient, LightColor)
  - Studio MCP tool schemas `generate_mesh` and `segment_mesh` (listed 2026-11-08)
  - roblox-engine-2026 section 3 (triangle and draw-call target), roblox-blender-export sections 1 and 11 (mesh and avatar budgets)
  - J. Mitchell, M. Francke, D. Eng, "Illustrative Rendering in Team Fortress 2", NPAR 2007 (classes told apart by silhouette)
  - original field notes (a robot-turret tower defense game, 2026-11-08)
---

# Character, creature and unit design

How a character looks is decided before any tool runs. This skill covers the look; `roblox-character-motion` covers custom motions, `roblox-blender-export` meshes and rigs, `roblox-fun-effects` section 3 the tier ladder and its effects.

## 0. Roster sheet first

Before generating or modeling anything, write `docs/roster.md` with one row per unit:

```
id      | role / faction | tier | size (studs) | shape idea          | key feature seen at play distance
pellet1 | tower, player  | 1    | 7            | squat box, 3 barrels | barrel cluster
```

- Take the camera from the game (height, distance, FOV) before sizes: what reads is set by the camera (section 1).
- Get the user's yes on the sheet and on 3 pilot units of different roles before the batch (section 5).
- Every decision is in the brief as a line, like other style decisions (`roblox-game-pipeline` section 3).

## 1. Read at play distance

- Pixels per stud = viewport height in px / (2 x distance x tan(FOV / 2)). Roblox's `Camera.FieldOfView` is vertical and defaults to 70, so this is about height / (1.4 x distance).
- On a 667x375 phone (`roblox-ui-layout` section 0) at 30, 45 and 60 studs that is about 9, 6 and 4.5 px per stud. A 5-stud avatar is about 30 px tall at 45 studs, and a 7-stud unit about 42 px. On a 1080 px desktop the same unit is about 2.9x taller.
- Detail smaller than about 4 px averages away (`roblox-blender-export` section 4). At play distance only the outline, the 2-3 big masses and one key feature survive. Exaggerate the key feature (barrel, horn, claw, crest) beyond what feels natural.
- **Silhouette test:** render every unit as a black shape at the size it has in play, seen from the game's camera angle. In Studio, put each model in a `ViewportFrame` sized to the height in px from the formula, with `Ambient` and `LightColor` black over a light `BackgroundColor3` (tested 2026-11-08; `ImageColor3` black blackens the background too). Two units whose black shapes you cannot tell apart are one unit to the player. In our test a three-barrel cluster read as a stub from a high camera, so check the angle the player really sees. Team Fortress 2's art was built so each class is known by silhouette alone (Valve, NPAR 2007).
- **Value test:** a `ColorCorrectionEffect` with `Saturation` -1 in `Lighting` turns the world gray and leaves the UI in color (tested 2026-11-08); screenshot the units on the real map. Enemies must separate from the ground and the path by value (light vs dark), not only by hue. Remove the effect afterwards.

## 2. Shape language and the menace dial

- Round, soft shapes read as friendly and safe; blocks and wide bases read as sturdy; points, spikes and forward-leaning wedges read as danger and speed (common animation and game-art convention, judgment).
- Players' side and enemies' side get different shape families and palettes, so a glance tells friend from foe (for example clean blocky robots in cool colors against spiky, warm, organic invaders).
- Menace is a dial. Ask it as a decision card when the game has enemies: cute, cartoon menace (D for all-ages games with invaders) or scary.

| Lever | Cute | Cartoon menace | Scary |
|---|---|---|---|
| Head to body | big head, short limbs | small head, big shoulders, jaw or chest | hidden or no face, long limbs |
| Eyes | big, round, highlights | small, narrow, glowing | none, many, or one bright point |
| Pose | upright, still | forward lean, head low | crouched, asymmetric |
| Edges | rounded | angular plates, a few spikes | jagged, broken outline |
| Color | saturated warm or pastel | desaturated body, one hot accent (red or orange glow) | near-black body, sickly accent |
| Motion | bouncy | heavy steps, sudden lunges | still, then fast |

- Menace comes from shape, pose and motion, not gore: Roblox content maturity applies (`roblox-design-and-launch` section 4), and Roblox's generators fail on horror words such as "sharp teeth" (`roblox-pitfalls` section 5). Describe the shape instead: "angular jaw, wedge head, hunched shoulders". Cube also ignored face words such as "narrow eyes" and drew another species' parts when the prompt named a species (field notes in `roblox-pitfalls` section 5), so carry menace with head, jaw, pose and palette, and describe the shape without the name.
- A unit that reads cute (big eyes, round body) needs the shape levers, not only darker colors (judgment). In one tower defense game the owner asked for invaders, not toys (field note, 2026-11-08).

## 3. Size against the avatar

- Avatar height is not fixed: classic avatars are about 5 studs, humanoid proportions about 6-6.5 (docs, Avatar Settings), and players choose by default. Size units against about 5.5 and check next to both.
- Measure the reference: in a reference game's frame, divide the unit's height by the avatar's height in the same frame, then multiply by your avatar height. A guessed size read small in one game: 5-stud robots looked like toys next to a reference whose weapons were as tall as the avatar; the owner set about 7 studs for the first tier up to about 10 for the top tier (field note, 2026-11-08).
- Size is a tier signal: grow each tier by a step that shows at play distance, and make bosses clearly larger than everything else on screen (judgment).
- Size is also gameplay: tower footprints against the placement grid, enemy width against the path, and a separate simple hitbox (`roblox-combat-tools`). Change the visual and keep the collider stable, or tests and balance shift.

## 4. Role and tier by shape, not tint

- One shape signature per role, the same at every tier, so the player learns the role from the outline: for example rapid fire as a multi-barrel cluster, pierce as one long rail, splash as pods or a mortar tube, slow as a dish or coil, support as an antenna or ring; for enemies, tank as wide and low, fast as thin and leaning, flyer as off the ground with wings.
- Each tier adds or grows a part (more barrels, a larger core, armor plates, shoulder pods, a crest) and steps up in size; only then does it add the tier color and effects from `roblox-fun-effects` section 3. Tiers that differ only by color fail the silhouette test and fail for color-blind players.
- Keep one detail that never changes inside a line of upgrades (base shape, eye style), so the upgraded unit still reads as the same unit.

## 5. One style across a roster (30-40 units)

1. Lock a style sheet: head to body ratio, bevel size, outline or none, 3-5 base colors plus one accent per faction, material, eye style, detail density, a shared base or plinth for towers.
2. Make 3 pilot units of different roles with the chosen tool and show them in one same-camera shot with the avatar. Batch only after the user's yes.
3. Keep the tool, the reference image and the prompt template the same for the whole roster; change only the shape words. Switching tools mid-roster breaks the style.
4. **Critic pass** after every batch: one silhouette sheet and one color sheet of the whole roster at play size (section 1). List pairs that differ only by color or small detail, and units whose bevel, texture density or proportions drift. A fresh-context reviewer with the sheets and the style sheet catches what the maker misses. Fix before the next batch.

## 6. Parts for animation

- Split by what moves, before generating:

  | Kind | Parts |
  |---|---|
  | Turret or tower | base (static), head (yaw), barrel (pitch), recoil piece; an Attachment at the muzzle |
  | Robot or mech (biped) | torso, head, left and right arm, left and right upper leg, left and right lower leg (8) |
  | Creature | body, head, jaw if it bites, tail, legs |

- Roblox Cube `generate_mesh` with `segmentation = "explicit"` returns up to 8 named MeshParts (tool schema); `segment_mesh` splits an existing mesh into up to 5. Plan the list within the cap.
- Segmented parts are rigid. Good for turrets, robots and mechs: join them with `Motor6D`s under an `AnimationController` with an `Animator`, or aim them by script (`CFrame.lookAt` on the yaw and pitch joints). Legs that must bend need upper and lower parts or a skinned Blender rig: a Cube raptor came back as 7 parts on the first try but with rigid legs and no knees (field note, 2026-11-08).
- Put each joint where the part turns (head at the yaw centre, barrel at the trunnion): check where each generated part's pivot sits before building joints. Name parts by function and use those names in code.

## 7. Budgets

- Hard limit 20,000 triangles per mesh; an R15 avatar body is at most 10,742 (`roblox-blender-export` sections 1 and 11). The docs' example scene target is under 1,000 draw calls and 1,000,000 triangles (`roblox-engine-2026` section 3).
- Crowd budget per unit = (scene target - map - towers and players) / the most units on screen. With 60 enemies on screen, one game used about 3,000-6,000 triangles each (field note). Set Cube's `maxTriangles` to the budget instead of the 10,000 default.
- Reuse one mesh and texture per unit type: the same MeshId and texture batch into one draw call (`roblox-engine-2026` section 3). Tint tiers with `SurfaceAppearance.Color` on white color-map areas in a place where the SA is baked once, or with one texture per tint through `TextureID` (an SA in a file-built place uploads a texture pack in every Studio session); `MeshPart.Color` does not tint a textured mesh (both in `roblox-pitfalls` section 4).
- **Texture memory per unit type.** Every map of every unit type on screen sits in each client's memory: types x maps per type x size. Size maps for the size on screen: a 7-stud unit is about 42 px tall on a phone at 45 studs (section 1), so 1024 maps add memory that a player cannot see (judgment). One game measured client `GraphicsTexture` memory (`Stats:GetMemoryUsageMbForTag`, Studio Play on a Mac, not a phone): 90 Cube maps for 30 unit types added about 420 MB at 1024 and about 52 MB at 512 (field note, 2026-11-08). The same 512 maps through `SurfaceAppearance` templates measured 88 MB of `GraphicsTexture` against 190 MB through `MeshPart.TextureID` (one Studio session; recheck on your build), but SA templates in a Rojo-built place make Studio upload a texture pack per SA in every session (`roblox-pitfalls` section 4), so dev builds stay on `TextureID`. Smaller maps mean a re-upload, which needs the user's yes first (`roblox-dev-workflow` section 8).
- Bosses: one at a time, up to 20,000 per mesh and several meshes.
- Measure on a phone with the most units the game allows on screen (`roblox-engine-2026` section 3, tools).

## 8. Which tool

Run a bake-off before a roster: the same unit from each available tool, one same-camera shot at play distance, labeled by the tool that really made it (`roblox-game-pipeline` section 6a). Multiply the cost by the roster size before asking.

| Tool | Cost | Look and limits |
|---|---|---|
| Roblox Cube (`generate_mesh`) | No credits; at most 2 jobs at a time (`roblox-pitfalls` section 5) | Clean, a little friendly; static, up to 8 rigid parts; mild words only |
| Paid image-to-3D service (for example Tripo; Blender MCP `generate_3d` reaches several) | Credits per model (11 per model in one run, 2026-11-08) | More detailed; dense mesh and baked texture need cleanup (`roblox-blender-export` section 9); ask first |
| Blender, skinned rig from a CC0 base mesh | Free, slow | Bending limbs, creatures that walk (`roblox-blender-export`) |
| Blender, built from primitives by script | Free | Rejected for robots as "too weird" (field note, 2026-11-08); fine for exact kit pieces |
| Studio `generate_avatar` or Avatar Setup | Studio tools | Humanoid R15 NPCs only; `generate_avatar` gave a realistic human look in our run (`roblox-pitfalls` section 5) |
| Creator Store model | Free | Quarantine first; rarely matches a roster's style (`roblox-store-art-pack` section 3) |

In that bake-off the owner picked Cube over the more premium paid result for cost across a 30-40 unit roster. Primitive stand-ins are greybox only (`roblox-dev-workflow` section 1).

## 9. Done when

- The roster sheet matches what is in the game.
- The silhouette sheet and color sheet pass the critic pass, at play size.
- One same-camera screenshot per faction at play distance on a phone-size viewport, with an avatar for scale, sits next to the reference frame, and the user has given a look verdict: passing checks is not looking good (`roblox-game-pipeline` section 0, rule 5).
- Triangle counts per unit are recorded against the crowd budget.
