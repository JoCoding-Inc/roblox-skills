"""Swirl mesh for ground_blast.luau (roblox-feel-audio-vfx section 3g): a band that winds 290 degrees round the
centre, flares outward and rises. 672 triangles. UV: U across the band, V along the flow (V = 1 at the tail, 0 at
the head), so a streak texture drawn top to bottom runs along the swirl.

  blender -b --python ground_blast_swirl.py -- <out.fbx>

Then, once per place:
  1. Upload the FBX as a Model (Studio 3D Importer or Open Cloud) and insert it: one MeshPart.
  2. Name it Swirl and put it in a Folder named FxMeshTemplates in ReplicatedStorage. Anchored on, CanCollide,
     CanTouch, CanQuery and CastShadow off, DoubleSided on, Transparency 0.02.
  3. Add a SurfaceAppearance: AlphaMode Transparency, ColorMap and EmissiveMask both the swirl_streaks texture
     (ground_blast_textures.py). Set the maps in Studio Edit mode: a game script cannot write them.
The effect clones the template and drives its Size, CFrame, Transparency, SurfaceAppearance.Color and
EmissiveStrength. It turns the mesh round the template's PivotOffset, which has to be the swirl's axis (the Blender
origin): an Open Cloud upload of this FBX kept it there (measured); in the Studio 3D Importer keep "Set Pivot to
Scene Origin" on (not tested with this mesh).
Blender (x, y, z) arrives in Roblox as (-x, z, y) with the export call below (roblox-blender-export section 0).
Ran with Blender 5.2 headless.
"""
import bpy, bmesh, math, sys
out = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.unit_settings.system = 'NONE'
NU, NV = 56, 6
bm = bmesh.new()
uvl = bm.loops.layers.uv.new("UVMap")
grid = []
for i in range(NU + 1):
    u = i / NU
    th = u * math.radians(290)
    row = []
    for j in range(NV + 1):
        v = j / NV
        width = 0.75 * (0.35 + 0.65 * math.sin(math.pi * min(u * 1.15, 1)) ** 0.6)  # narrow tail, wide body
        tilt = math.radians(38 + 22 * u)                                            # flares more toward the head
        r = 0.55 + 0.35 * u + v * width * math.cos(tilt)
        z = 0.04 + 0.22 * u + v * width * math.sin(tilt)
        row.append((bm.verts.new((r * math.cos(th), r * math.sin(th), z)), u, v))
    grid.append(row)
for i in range(NU):
    for j in range(NV):
        quad = [grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]
        f = bm.faces.new([q[0] for q in quad])
        for loop, q in zip(f.loops, quad):
            loop[uvl].uv = (q[2], 1 - q[1])  # V = 1 at the tail, 0 at the head
me = bpy.data.meshes.new("Swirl")
bm.to_mesh(me); bm.free()
ob = bpy.data.objects.new("Swirl", me)
bpy.context.scene.collection.objects.link(ob)
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={'MESH'},
    global_scale=1.0, apply_unit_scale=True, apply_scale_options='FBX_SCALE_UNITS',
    axis_forward='-Z', axis_up='Y', bake_space_transform=True, use_mesh_modifiers=True,
    mesh_smooth_type='FACE', use_triangles=True, colors_type='NONE', add_leaf_bones=False,
    bake_anim=False, path_mode='COPY', embed_textures=False)
print("tris", NU * NV * 2)
