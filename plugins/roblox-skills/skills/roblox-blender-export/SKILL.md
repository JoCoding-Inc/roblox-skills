---
name: roblox-blender-export
description: "Use when making Roblox meshes in Blender (bats, props, kit pieces, voxel animals, icons) and getting them into Studio: scale, pivot, axis, FBX export call, color-as-texture, triangle budgets, collision, upload."
when_to_use: "Also when an imported mesh is the wrong size, faces the wrong way, renders white/untextured, is inside-out, too heavy, or collides badly; before scripting a Blender asset pipeline or Open Cloud upload; when driving a live Blender through MCP or sharing it between sessions."
last_reviewed: 2026-10-26
sources:
  - https://github.com/brain-xiang/grok-studio (skills/blender-assets, reference/roblox_export.py; MIT)
  - https://github.com/Crazyshermy/-Roblox (.claude/skills/roblox-blender-modelling; no license, facts re-authored)
  - https://github.com/S4US/Roqer (references/blender.md, modeling.md; AGPL/MIT mix, facts only)
  - https://github.com/scenario-labs/skills (scenario-roblox-assets gui-paths; MIT)
  - https://create.roblox.com/docs/art/modeling/specifications
---

# Blender to Roblox

Pair with `roblox-building` (placement, collisions, map) and `roblox-cloud` (Open Cloud). Run Blender headless: `blender -b --python script.py -- args`. Keep every asset as a rerunnable script, not hand edits.

## 0. Orientation test first

The sources disagree on how glTF and FBX fronts land in Roblox. Before any bulk work:
1. Export one asymmetric object (a cube with a nose on Blender -Y) through the exact path you will use: export, then importer or Open Cloud, then insert.
2. Check `LookVector` and which face the nose is on in Studio.
3. Record the result at the top of the pipeline script.

Reported (grok-studio, not yet confirmed by us) for FBX with the call below: Blender (x, y, z) arrives in Roblox as (-x, z, y), and the Blender front (-Y) faces Roblox Front (-Z). Treat it as a hypothesis until step 1-3 confirm it on your path.

## 1. Scale, pivot, structure

- Unit System None, Unit Scale 1.0, and model in studs: 1 Blender unit = 1 stud (1 stud = 28 cm). The player is about 5 studs tall.
- Pivot at the centre of the base at (0, 0, 0) for ground props. A tool's pivot goes at the grip.
- Apply all transforms before export:

  ```python
  bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
  ```

- One object = one MeshPart. Join the pieces that share a material and never move apart.
- Hard limit: 20,000 tris per mesh. Budgets:

  | Asset | Tris |
  |---|---|
  | Small prop (4 studs or less) | 50-300 |
  | Medium prop | 300-1,500 |
  | Landmark | 1,000-5,000 |
  | Hero | up to about 10,000 |

- Kit trick: model every kit piece in ONE script with one shared palette material, export ONE file, and upload ONCE (assetType Model). Each object becomes its own MeshPart named after the object.

## 2. Export call

```python
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, object_types={'MESH'},
  global_scale=1.0, apply_unit_scale=True, apply_scale_options='FBX_SCALE_UNITS',
  axis_forward='-Z', axis_up='Y', bake_space_transform=True, use_mesh_modifiers=True,
  mesh_smooth_type='FACE', use_triangles=True, colors_type='NONE', add_leaf_bones=False,
  bake_anim=False, path_mode='COPY', embed_textures=True)
```

- Apply modifiers on export, or the bevels never reach Roblox. For glTF, set `export_apply=True`.
- Keep normals outward. Run a scripted check: inside-out faces are invisible in renders and only show in Studio.

## 3. Color

- A plain Principled Base Color arrives wrong (white or mis-converted). Use one of these instead:
  1. **Palette PNG (default):** a small sRGB PNG with one swatch per color, and UVs scaled inside each swatch with a margin of 2 texels or more. Leave `MeshPart.Color` white.
  2. **Packed image texture** of 1024 px or less, for grain, logos or decals, UV-unwrapped.
  3. **Vertex colors:** reported kept for GLB uploads; untested for FBX.
- Texture density: 256 px for a prop of about 5 studs, 512 for 10, 1024 for 20.
- Studio renders brighter than EEVEE, so judge colors in Studio.
- Tint variants (rarity, tiers): white or grey palette areas plus `MeshPart.Color` at runtime, or one palette PNG per variant on the same mesh (`TextureID` swap).

## 4. Genre look (chunky cartoon)

- Flat shading, 6-12 segments around curves, a 1-3 segment bevel on every edge. Never smooth-shade hard edges.
- Visible part breakup: trims, rims, bolts or studs, plank or brick lines in geometry or palette. Avoid single smooth slabs.
- Voxel creatures (Steal An Egg / Brainrot look):
  1. Start from a CC0 low-poly source (Poly Pizza, Quaternius, Kenney).
  2. Remesh to Blocks (Voxel remesh, size about 0.15-0.25 of the height).
  3. Transfer the color to a palette.
  4. Decimate interior faces. Keep 3k tris or fewer.
- Detail under about 4 px at play distance averages away: at 15 studs and 70 FOV, 1 stud is about 36 px. Make features bigger than feels natural.

## 5. Studio import settings

- 3D Importer:
  - File Geometry: Scale Unit = Studs.
  - File Transform: World Forward Front, World Up Top.
  - File General: Anchored on (static), Add to Workspace on, Set Pivot to Scene Origin on, Upload to Roblox on.
- After import, set `CollisionFidelity` explicitly every time, because the importer is inconsistent: Box or Hull for props.
- Decor gets `CanCollide`, `CanTouch` and `CanQuery` false. A gameplay collider is an invisible primitive with the old dimensions.
- Open Cloud `POST https://apis.roblox.com/assets/v1/assets`:
  - Send multipart `request` JSON (`assetType` Model or Image, `displayName`, `creationContext.creator`) plus `fileContent`, then poll the operation.
  - The result arrives as a package: unanchored, random yaw, no preview. An update adds a version, but placed copies do not update.
  - Load at runtime with `InsertService:LoadAsset(id)` (the asset must belong to the place owner or the group), or insert in Edit with Studio MCP `insert_asset`.
- Upload under the group that owns the game. Assets owned by another account can render as nothing.
- Images: upload as Decal and use the returned `imageId`, never the `decalId`.

## 6. Renders for previews and icons

- Contact sheet of every asset (EEVEE, key plus rim light, flat background) for review at phone size before uploading.
- Icon decals: Workbench or EEVEE, `film_transparent=True`, RGBA PNG, square, 512 px.
- Review checklist: distinct silhouettes per tier, readable at 128 px, palette consistent across the family, nothing default grey.

## 7. Licensing

Record source, author and license per imported model in `assets/LICENSES.md`. Use only CC0, or CC-BY with credit. Never import an unclear license.

## 8. Live Blender through MCP (shared between sessions)

MCP for Blender (`uvx mcp-for-blender`, addon "MCP for Blender") drives the user's open Blender. Every Claude session with the server in its config talks to the same Blender on `localhost:9876`. The addon accepts several clients, but runs their commands one at a time in one shared scene.

- Start with `get_addon_status`. "Could not connect" means Blender is closed or the addon is off: ask the user to enable it (Preferences > Add-ons > MCP for Blender, Save Preferences) and press **Connect to MCP server** in the viewport sidebar (`N` > MCP for Blender tab).
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
