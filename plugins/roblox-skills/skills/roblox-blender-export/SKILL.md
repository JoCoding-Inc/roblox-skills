---
name: roblox-blender-export
description: "Use when making Roblox meshes in Blender (weapons, props, kit pieces, voxel animals, icons) and getting them into Studio: scale, pivot, axis, FBX export call, color-as-texture, triangle budgets, collision, upload."
when_to_use: "Also when an imported mesh is the wrong size, faces the wrong way, renders white/untextured, is inside-out, too heavy, or collides badly; before scripting a Blender asset pipeline or Open Cloud upload; when driving a live Blender through MCP or sharing it between sessions; when tiers or variants in a batch look alike."
last_reviewed: 2026-11-09
sources:
  - https://github.com/brain-xiang/grok-studio (skills/blender-assets, reference/roblox_export.py; MIT)
  - https://github.com/Crazyshermy/-Roblox (.claude/skills/roblox-blender-modelling; no license, facts re-authored)
  - https://github.com/S4US/Roqer (references/blender.md, modeling.md; AGPL/MIT mix, facts only)
  - https://github.com/scenario-labs/skills (scenario-roblox-assets gui-paths; MIT)
  - https://create.roblox.com/docs/art/modeling/specifications
  - https://create.roblox.com/docs/art/modeling/export-requirements
  - https://create.roblox.com/docs/art/modeling/texture-specifications
  - https://create.roblox.com/docs/art/modeling/roblox-blender-plugin
  - https://create.roblox.com/docs/art/modeling/gltf-export
  - https://create.roblox.com/docs/art/blender
  - https://github.com/ahujasid/blender-mcp (renamed MCP for Blender)
  - original field notes (2026-10 to 2026-11)
---

# Blender to Roblox

Pair with `roblox-store-art-pack` (map composition) and `roblox-release-automation` (Open Cloud). Run Blender headless: `blender -b --python script.py -- args`. Keep every asset as a rerunnable script, not hand edits.

Blender or Roblox Cube? Static props, furniture, vehicles and simple weapons are often faster and better looking from Cube (Studio MCP `generate_mesh`, see `roblox-pitfalls` section 5). Anything that must animate (monsters, quadrupeds, spiders) still comes from Blender: Cube returns one static mesh with no rig. A stylized humanoid body can start in Cube and be cut into R15 parts (section 12). Go cheap first: Cube, then Blender edits, and a paid AI 3D service only after asking. Before building any pipeline, put the user's reference image next to your first result and judge silhouette and proportions before detail.

## Official rules at a glance (creator-docs, 2026-10-29)

- Geometry: at most **20,000 triangles per mesh**; watertight (no holes or backfaces); quads where possible, no n-gons; no zero-thickness meshes. Avatar items have their own, stricter budgets.
- Rigs: bones/joints frozen (scale 1,1,1, rotation 0,0,0), root at 0,0,0, **max 4 bone influences per vertex**, no influence on the root, keep symmetry. The Animation Clip Editor importer reads FBX and glTF with several clips per file (full release 2026-03-31); older guides say one animation track per FBX. Character animation choices: `roblox-character-motion`.
- Textures: PNG, JPG, TGA or BMP, up to 4096x4096 (the engine streams low resolution first). One material per mesh. Suggested size by object width: 5 studs 256, 10 studs 512, 20 studs 1024. PBR via `SurfaceAppearance` (colour, normal in OpenGL tangent space, metalness, roughness and emissive-mask maps; an emissive mask on an avatar item adds a 500 Robux upload fee; `SurfaceAppearance` properties cannot be changed by script at runtime) overrides `TextureID`.
- Cages: `<Name>_InnerCage` and `<Name>_OuterCage` meshes for layered clothing; never delete cage vertices or alter their UVs. Characters need an outer cage.
- Blender setup: Scene > Units > Unit System **None**, rotation Degrees. Blender is Z-up, Studio is Y-up.
- Formats: FBX is the recommended path (keeps rig and skin weights). The Studio Importer also accepts `.gltf` and `.obj`. glTF export from Studio is in beta (meshes, textures, rigs, vertex colours, cages; no animation).
- **Roblox Blender plugin** (open source, built on Open Cloud) sends objects straight from Blender to a Studio session after linking your account; try it before hand-rolling export and upload scripts. Fall back to the scripted FBX path below for headless or batch work.

The Blender guide says to export with Forward Z, Up Y for FBX and import with World Forward Front, World Up Top, Scale Unit Studs; our call below uses `-Z`/`Y` as a hypothesis, so run the orientation test below once and trust the result. 1 stud is 28 cm.

## 0. Orientation test first

The sources disagree on how glTF and FBX fronts land in Roblox. Before any bulk work:
1. Export one asymmetric object (a cube with a nose on Blender -Y) through the exact path you will use: export, then importer or Open Cloud, then insert.
2. Check `LookVector` and which face the nose is on in Studio.
3. Record the result at the top of the pipeline script.

Confirmed 2026-11-02 for FBX with the call below, headless Blender export then the Studio 3D Importer (Scale Unit Studs, Forward Front, Up Top): Blender (x, y, z) arrives in Roblox as (-x, z, y). The Blender front (-Y) faces Roblox Front (-Z), Blender +X lands on Roblox -X, and Blender Z is Roblox up. The mapping is a proper rotation (determinant +1), so nothing is mirrored. The test mesh was a 4-stud cube with a nose on Blender -Y and a post on Blender +X; the imported size was 5, 4, 5 (X, Y, Z) with `PivotOffset` at the Blender origin. Re-run steps 1-3 if you change the export path (glTF, Open Cloud, other axis settings).

Measuring it without eyeballing: read the vertices from the imported MeshPart (`AssetService:CreateEditableMeshAsync(Content.fromUri(part.MeshId))`, then `GetVertices` and `GetPosition`). Do not use raycasts for this: they hit the collision shape, and with the default `CollisionFidelity` that is a box or hull, not the visible mesh. In Studio MCP `execute_luau`, `datamodel_type` is `Edit` (capital E) and the result must be `return`ed, since `print` output is not shown.

## 1. Scale, pivot, structure

- Unit System None, Unit Scale 1.0, and model in studs: 1 Blender unit = 1 stud (1 stud = 28 cm). The player is about 5 studs tall.
- Pivot at the centre of the base at (0, 0, 0) for ground props. A tool's pivot goes at the grip.
- Apply all transforms before export:

  ```python
  bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
  ```

  With `location=True` a piece built away from the origin keeps its geometry there and its origin moves to world (0, 0, 0) (Blender 5.2.2 round trip). Build each piece at the origin; lay pieces out only for the contact sheet.

- One object = one MeshPart. Join the pieces that share a material and never move apart.
- Hard limit: 20,000 tris per mesh. Budgets:

  | Asset | Tris |
  |---|---|
  | Small prop (4 studs or less) | 50-300 |
  | Medium prop | 300-1,500 |
  | Landmark | 1,000-5,000 |
  | Hero | up to about 10,000 |

- Kit trick: model every kit piece in ONE script with one shared palette material, export ONE file, and upload ONCE (assetType Model). Each object becomes its own MeshPart named after the object.
- Sets with tiers or variants: the one driver script also validates a per-tier size contract (size range per axis, tris, no floating parts; a violation fails the run) and writes per-asset meta that game code reads, for example a `meta.json` with the grip or contact height (Blender Z is Roblox Y, section 0).

## 2. Export call

```python
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, object_types={'MESH'},
  global_scale=1.0, apply_unit_scale=True, apply_scale_options='FBX_SCALE_UNITS',
  axis_forward='-Z', axis_up='Y', bake_space_transform=True, use_mesh_modifiers=True,
  mesh_smooth_type='FACE', use_triangles=True, colors_type='NONE', add_leaf_bones=False,
  bake_anim=False, path_mode='COPY', embed_textures=True)
```

- Official Blender FBX checklist: Path Mode **Copy** + **Embed Textures**; Apply Scalings **FBX Unit Scale** (see the Blender FBX scaling guide if size is wrong); Armature > **Add Leaf Bones** off; **Bake Animation** off unless exporting keyframes (walk cycle, facial data). The call above already encodes these and runs without errors on Blender 5.2.2 (tested 2026-11-03, 0.07 s for a 3-piece kit). Keep `colors_type`, `use_triangles`, `bake_space_transform`, `add_leaf_bones`, `bake_anim` and `embed_textures` explicit: their defaults differ.
- Apply modifiers on export, or the bevels never reach Roblox (measured: 268 tris with `use_mesh_modifiers=True`, 60 without). For glTF, set `export_apply=True`.
- Keep normals outward. Run a scripted check: inside-out faces are invisible in renders and only show in Studio.

## 3. Color

- A plain Principled Base Color arrives wrong (white or mis-converted). Use one of these instead:
  1. **Palette PNG (default):** a small sRGB PNG with one swatch per color, and UVs scaled inside each swatch with a margin of 2 texels or more. Leave `MeshPart.Color` white.
  2. **Packed image texture** of 1024 px or less, for grain, logos or decals, UV-unwrapped.
  3. **Vertex colors:** a Blender round trip keeps them with FBX `colors_type='SRGB'`; the section 2 call (`'NONE'`) drops them. For GLB use `export_vertex_color='ACTIVE', export_all_vertex_colors=False`; the default `'MATERIAL'` writes a white `COLOR_0` and puts the real colors in `COLOR_1`. The Roblox side is untested.
- Texture density: 256 px for a prop of about 5 studs, 512 for 10, 1024 for 20 (official guidance). Roblox accepts up to 4096 for general textures (marketplace avatar items are capped at 2048, makeup at 1K), and PBR maps are budgeted at 256 per 2x2x2 studs up to 1024 for 8x8x8 studs. Our client test of a 2048 colour map on a `MeshPart` stayed grey, so upload colour at 1024 and test larger maps in a Play client first.
- Studio renders brighter than EEVEE, so judge colors in Studio.
- A bake through an Emission shader writes linear values. Convert sRGB colors with `c ** 2.2` before baking, or colors come out grey or white in Roblox (field observation).
- Tint variants (rarity, colorways): white or grey areas in a `SurfaceAppearance` color map plus `SurfaceAppearance.Color` at runtime (`MeshPart.Color` does not tint a textured mesh, tested 2026-11-08, and an SA in a Rojo-built place uploads a texture pack in every Studio session: both in `roblox-pitfalls` section 4), or one palette PNG per variant on the same mesh (`TextureID` swap). Distinct tiers need distinct silhouettes, not tints (section 6).

## 4. Genre look (chunky cartoon)

- Flat shading, 6-12 segments around curves, a 1-3 segment bevel on every edge. Never smooth-shade hard edges.
- Visible part breakup: trims, rims, bolts or studs, plank or brick lines in geometry or palette. Avoid single smooth slabs.
- Voxel creatures (Steal An Egg / Brainrot look; lane card `roblox-game-pipeline/assets/lanes/voxel.jpg`):
  1. Start from a CC0 low-poly source (Poly Pizza, Quaternius, Kenney), or build the body from ellipsoids.
  2. Remesh modifier, mode **Blocks** (Voxel mode gives a smooth surface), `scale` 0.99. `octree_depth` sets the density; measured on a 4-unit creature, 2026-11-04:

     | Look | Depth | Blocks tall | Tris |
     |---|---|---|---|
     | Low-res (big blocks, flat color per part) | 4 | 15 | about 1,200 |
     | High-res (small blocks, per-block shading) | 5 | 29 | about 5,900 |
     | Too fine | 6 | 59 | about 26,000, over the 20,000 mesh limit |

     The depth works on the longest side, so a long tail or wings lower the blocks tall.
  3. Color each block from the source part it sits in. Low-res: one flat color per part, and grow small parts (eyes, spikes) by half a block or they vanish. High-res: add plus or minus 10-15 percent brightness per block for the hand-shaded look.
  4. Use the same density for every model in the game (creatures, trees, rocks).
- Detail under about 4 px at play distance averages away: at 15 studs and 70 FOV, 1 stud is about 36 px. Make features bigger than feels natural.

## 5. Studio import settings

- With the Studio MCP, the built-in skill `rbx-import-asset` (2026-11-04) exports, uploads and inserts a GLB or FBX, then compares it with the source and fixes scale, rotation, dropped textures, grey parts, anchoring and ground placement. It needs MCP Permissions Publish & manage assets and the approved export folder (`roblox-studio-ai-tools` section 1a). Uploads are permanent, so it asks first. Still check orientation (section 0) and collision (below) on the result.
- 3D Importer:
  - File Geometry: Scale Unit = Studs.
  - File Transform: World Forward Front, World Up Top.
  - File General: Anchored on (static), Add to Workspace on, Set Pivot to Scene Origin on, Upload to Roblox on.
- After import, set `CollisionFidelity` explicitly every time, because the importer is inconsistent: Box or Hull for props.
- Decor gets `CanCollide`, `CanTouch` and `CanQuery` false, except decor the camera can enter (walls, ceilings, stair treads): the default camera ignores parts with `CanCollide` false (`roblox-pitfalls` section 4). A gameplay collider is an invisible primitive with the old dimensions.
- Open Cloud `POST https://apis.roblox.com/assets/v1/assets`:
  - Send multipart `request` JSON (`assetType` Model or Image, `displayName`, `creationContext.creator`) plus `fileContent`, then poll the operation (`GET /assets/v1/operations/{id}` until `done`; 300 per minute). One asset per call, files up to 20 MB, 120 creates per minute. Scopes `asset:read` and `asset:write`. Models accept fbx, gltf, glb, rbxm, rbxmx and become a package; images accept png, jpeg, bmp, tga under 8000x8000 px; audio mp3/ogg/wav/flac up to 7 minutes (100 uploads per month if ID-verified, 10 if not). `creationContext.expectedPrice` makes the call fail instead of charging more than you expect.
  - The result arrives as a package: unanchored, random yaw, no preview. An update adds a version, but placed copies do not update.
  - Load at runtime with `InsertService:LoadAsset(id)` (the asset must belong to the place owner or the group), or insert in Edit with Studio MCP `insert_asset`.
  - Read the MeshIds of an uploaded FBX with `InsertService:LoadAsset(id)` in an Edit-mode `execute_luau`. Every upload makes new ids, so keep one `ids.json` per asset set and regenerate the game's data module from it.
- Upload under the group that owns the game. Assets owned by another account can render as nothing.
- Images: upload as Decal and use the returned `imageId`, never the `decalId`.

## 6. Renders for previews and icons

- Contact sheet of every asset (EEVEE, key plus rim light, flat background) for review at phone size before uploading. Make one per batch and label each cell with its asset id.
- Icon decals: Workbench or EEVEE, `film_transparent=True`, RGBA PNG, square, 512 px.
- Headless `-b` renders on Apple Silicon (tested Blender 5.2.2, M4 Pro). Engine ids on 5.x: `BLENDER_EEVEE`, `BLENDER_WORKBENCH`, `CYCLES` (`BLENDER_EEVEE_NEXT` raises `TypeError`). Measured: 512 px icon 0.85 s on EEVEE, 0.14 s on Workbench; a 1536x512 three-object sheet 0.3 s on EEVEE, 7.5 s on Cycles (CPU).
- Review checklist: distinct silhouettes per tier, readable at 128 px, palette consistent across the family, nothing default grey. For characters and units, size the test to play distance (`roblox-character-design` section 1).
- Critic pass on every batch: a reviewer other than the builder reads the labeled sheet and lists near-identical silhouettes by asset id. Reject them and redo one of each pair with a different form, not a recolor (field observation).

## 7. Licensing

Record source, author and license per imported model in `assets/LICENSES.md`. Use only CC0, or CC-BY with credit. Never import an unclear license.

## 8. Live Blender through MCP (shared between sessions)

Headless script or live window?

| | Headless (`blender -b --python script.py -- args`) | Live window + MCP |
|---|---|---|
| How it runs | New process per run; exits when the script ends | Commands go to the user's open Blender; the scene stays between calls |
| Seeing the result | Render a PNG and read it | `look` captures the viewport at once |
| Parallel work | Each run is separate, so several subagents can work at once | Every session shares one scene; own collection only, or a second Blender on another port |
| Reproducible | The script is the asset: rerun gives the same result | Edits pile up in the chat; save them back into a script |
| Extras | Full `bpy` (model, export, render) | Plus Poly Haven, Sketchfab and Poly Pizza import, `generate_3d`, `look` |
| Speed and memory | 0.6 s start and about 230 MB for an empty run; 0.35-0.45 GB while rendering EEVEE or Workbench, up to 1 GB on Cycles (measured, Blender 5.2.2) | The window stays open (one measured at 830 MB after 2 days) |
| User | Nothing to do | Keeps Blender open and presses Connect |

Produce and export assets headless (subagents especially). Use the live window to explore with the user, import library assets or try `generate_3d`, then move the result into a script. The MCP add-on cannot run under `blender -b` (tested 2026-11-03, add-on v1.8 on Blender 5.2.2): it refuses to start in background mode, and `bpy.app.timers`, which drain its command queue, never fire there, so commands time out. MCP tools therefore always need a window.

Quality does not depend on the route: one bench brief built headless and through MCP came out near identical (3.8 min each, 9.4k and 10.0k tris), and `look` is a viewport capture, not a render (field note, 2026-11-09). Earlier props of the same game looked cheap because of the recipe: about 1.5k tris on a bench seen up close (the medium-prop band in section 1; budget props the player inspects like a landmark), primitives, no bevels and flat swatches (sections 1, 3 and 4). In the same test, free CC0 and CC-BY gym models were rare and crude, and Poly Haven had none.

MCP for Blender (`uvx mcp-for-blender`, addon "MCP for Blender") drives the user's open Blender. Every Claude session with the server in its config talks to the same Blender on `localhost:9876`. The addon accepts several clients, but runs their commands one at a time in one shared scene.

Setup (the user does steps 2-3 in Blender; every MCP tool fails until the add-on is on and connected):
1. `uvx mcp-for-blender install-addon` installs the add-on files.
2. In Blender: **Edit > Preferences > Add-ons**, search "MCP for Blender", tick its checkbox to turn it on, then Save Preferences so it stays on after a restart.
3. In the 3D viewport press `N`, open the **MCP for Blender** tab and press **Connect to MCP server**. Repeat this step every time Blender starts.
4. `claude mcp add blender uvx mcp-for-blender`, then restart Claude Code.

- Start with `get_addon_status`. "Could not connect" means Blender is closed, the add-on is off, or Connect was not pressed: walk the user through setup steps 2-3 (name the exact menu path) and call again.
- Library toggles (Poly Haven, Sketchfab, Poly Pizza) are scene properties: `bpy.context.scene.blendermcp_use_polyhaven = True`. Poly Haven needs no key. Sketchfab and Poly Pizza need a key that the user types into the addon preferences, never into chat.
- Work only inside your own collection, named after the project (for example `mannequin-heist_assets`). Never delete, select or export another session's objects or the user's own objects. Export with `use_selection=True` on your collection only.
- Before starting, list the scene's collections. If another project's collection is there and changing, another session is using this Blender: tell the user and ask before you go on.
- For real parallel work, run one Blender per session:
  1. The user opens a second Blender (`open -n -a Blender` on macOS), sets the port in its MCP tab (for example 9877) and presses Connect.
  2. Point that project's session at it with a project-scoped `.mcp.json`, which overrides the user-scoped server of the same name:

     ```json
     { "mcpServers": { "blender": { "command": "uvx", "args": ["mcp-for-blender"], "env": { "BLENDER_PORT": "9877" } } } }
     ```

  3. Restart that Claude session (MCP servers start with the session) and approve the project server once.

## 9. Blender MCP: tools, AI 3D services and safety

Check the installed version's tool list first (`claude mcp list`, then ask the server); the names below are from the project's current README and may be consolidated or renamed again. The community server was renamed to **MCP for Blender** (PyPI `mcp-for-blender`, old name `blender-mcp`): update old configs.

- Install: setup steps 1-4 in section 8 (the add-on must be turned on under Edit > Preferences > Add-ons). Needs Blender 3.0+ and `uv`.
- Tools: `execute_blender_code` (arbitrary Python), `get_scene_info`, `look` (viewport/camera/render capture), `search_assets` + `import_asset` (Poly Haven CC0, Sketchfab, Poly Pizza), `generate_3d` (Tripo, Hunyuan3D, Hyper3D Rodin, Meshy), `get_addon_status`, `disable_telemetry`.
- There is also an official Blender Lab MCP server (needs Blender 5.1+ and its own add-on). Both default to port 9876: install one, or change a port.
- Ask the user before enabling any paid 3D generation key; keys go into add-on preferences, never into chat.
- Safety: `execute_blender_code` runs arbitrary code and the socket has no auth. Save the .blend first, keep the port on localhost, set `BLENDER_MCP_SAFE_MODE=1` if available, `DISABLE_TELEMETRY=true` for privacy, pin versions, and review the project before upgrading.
- Large requests and Poly Haven downloads can block Blender's main thread: split work, use 1k-2k textures.

### AI-generated 3D (Hyper3D, Hunyuan3D, Meshy, Tripo) for Roblox

This is about the raw output of the generators inside Blender MCP (`generate_3d`). For Roblox props, first compare Roblox Cube (`generate_mesh`, free), which already targets Roblox limits (`roblox-game-pipeline` section 6a). The Blender MCP generators make dense, untidy meshes with baked textures. Use them for reference or hero props, then in Blender: decimate or retopo to budget (under 20,000 and usually under 3,000 for props), fix normals and scale, rebake the colour to one 1024 map or a palette, remove interior faces, check licence and moderation risk, then export with section 2. Never upload raw output. For characters, rig and skin by hand (4 influences max) or via Studio Avatar Auto Setup.

## 10. Upload paths summary

| Path | When |
|---|---|
| Roblox Blender plugin | Interactive work, one asset at a time |
| Studio 3D Importer (FBX) | Manual import with preview and settings |
| Open Cloud Assets API (`POST /assets/v1/assets`) | Scripted batch uploads, kits |
| Studio MCP `upload_image`, `insert_asset` | Images and inserting uploaded assets |

## 11. Avatars, accessories and characters (official limits)

Use Studio **Avatar Setup** (auto setup) before hand-rigging a character. It rigs, skins, adds face rig, cages, partitions into 15 parts and attachments. Presets: Platform Avatar (strict, Marketplace) and Development Avatar (loose, NPCs and starter characters). Input rules: humanoid in A or T pose, front facing -Z, watertight, distinct neck, two half-sphere eyes plus upper teeth, lower teeth and tongue with no shared vertices, at most 10,742 triangles, textures included, no accessories. Turn **Upload To Roblox** off in the importer first; imported models enter the moderation queue.

| Asset | Key limits |
|---|---|
| Avatar body (R15) | 15 meshes named `<Part>_Geo`; DynamicHead 4,000 tris, torso 1,750, each arm and leg 1,248, total 10,742; texture up to 2048; 15 joints (advanced R15 up to 37 more); attachments end in `_Att`; parts opaque and filling at least 50 percent of their bounding box |
| Rigid accessory | one mesh, at most 4,000 tris, watertight, at least 1 attachment, texture up to 2048, size capped by type and body scale |
| Layered accessory | one mesh, at most 4,000 tris, clothing up to 8x8x8 studs, inner and outer cage, bound to R15, 4 influences max |
| Dynamic head | outer cage with eye and mouth landmarks; 17 minimum FACS poses (eye closes, JawDrop, Pucker, lip corners, chin raiser, cheek raisers, brow raisers, lip depressors); must pass blink L/R, mouth open, happy, sad |
| Emote / animation | emotes under 10 s from a CurveAnimation; animation editor runs at 30 fps with priorities Core < Idle < Movement < Action < Action2 < Action3 < Action4 |
| Classic clothing | 512x512 T-shirt; shirt and pants templates; 80 Robux upload fee |

Marketplace publishing needs ID verification or a linked parental account plus Roblox Plus or Premium; upload fee 80 Robux per submission (updates too), plus a refundable publishing advance by type (for example hats 1,500, hair 1,000, clothing 600, body 2,500). In-game NPC and starter characters can use the loose Development preset.

## 12. Cube body into Blender and R15 parts

Field notes (2026-11): a headless Cube body cut into R15 parts in Blender. Try Avatar Setup (section 11) first; cut by hand when it does not fit.

1. Get the mesh out of Studio:
   - Geometry: `AssetService:CreateEditableMeshAsync(Content.fromUri(part.MeshId))`, then `GetVertices`, `GetPosition`, `GetFaces`, `GetFaceVertices`, `GetFaceUVs` and `GetUV`. Send it as JSON with `HttpService:PostAsync` to a receiver bound to 127.0.0.1 (MCP Permissions > Connect to the internet with `127.0.0.1` in the HTTP allowlist, `roblox-studio-ai-tools` section 1a). Run the receiver in the background and stop it by PID.
   - One POST over 1024 KB fails ("Post data too large. Limit: 1024 KB"; the docs state no limit), so send chunks.
   - If the execute_luau call turns `HttpService.HttpEnabled` on, restore it in the same call (`roblox-pitfalls` section 3); never publish with it changed.
   - Texture: `AssetService:CreateEditableImageAsync` on the colour map, `ReadPixelsBuffer`, hex in 400 KB chunks, decode with Pillow as RGBA with the origin at the top left.
   - Cube meshes are not welded: run `remove_doubles` before any cut.
2. Cut:
   - A vertical plane at the armpit separates arms from torso. Bound the arm selection in height too, or it also takes the clothing hem and the feet. A slanted shoulder plane left thin flaps on both parts.
   - Horizontal planes at waist, hips, elbows, wrists, knees and ankles, each part overlapping the next by 0.04 units.
   - Keep only the largest connected piece per part.
   - Cap every open boundary with `bmesh.ops.holes_fill` and put the cap faces' UVs on a skin-coloured texel, or the joints show see-through holes as soon as they rotate.
3. Export with section 2 and give every part one shared 1024 colour map as `MeshPart.TextureID`, which scripts can set (`SurfaceAppearance` maps cannot: `roblox-pitfalls` section 4).
