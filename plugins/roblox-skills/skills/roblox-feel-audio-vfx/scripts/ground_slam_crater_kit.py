"""ground_slam_crater_kit: the slab kit of ground_slam (roblox-feel-audio-vfx section 3h), Blender headless.

  blender -b --python ground_slam_crater_kit.py -- <out.fbx> [seed] [cells]

A disc of floor pre-broken into convex polygon slabs (Voronoi cells, small in the middle, larger outward, uneven
on purpose: even cells read as a football pattern), one mesh object per slab. Unit radius 1 = the crater's
radius; the cells reach about 1.68 and the game scales the kit.
  * each slab is a prism: top face on z = 0, 0.1 thick, the underside a little smaller (the walls lean in), origin
    at the centroid of its top face, so the game can tilt and lift every slab round its own centre
  * slabs are inset from their cell by 0.004-0.011 (hairline 0.0015 beyond radius 1.2): a dark disc under the
    tops shows through the gaps as crack lines
  * corner colours: tops white, walls 0.5 at the top edge and 0.2 at the bottom, so walls are dark without a
    second material (they arrive in Roblox with colors_type SRGB: read back 0.2-1.0)
  * a planar UV (u, v = the kit's x, y), unused by ground_slam: a Texture instance on a MeshPart is laid from the
    part's centre in studs, not from the mesh UVs (measured)
Object names S00, S01, ... With the export call below Blender (x, y, z) arrives in Roblox as (-x, z, y).
The example was made with seed 11 and 76 cells (1500 triangles).

Template, once per game (uploads are permanent: ask the user first):
  1. upload the FBX as a Model to the account or group that owns the game and insert it in Studio Edit mode into a
     Folder named FxMeshTemplates in ReplicatedStorage; name the Model CraterKit
  2. run in the command bar:
       local kit = game.ReplicatedStorage.FxMeshTemplates.CraterKit
       local link = kit:FindFirstChildOfClass("PackageLink") if link then link:Destroy() end
       local centre = kit:GetBoundingBox().Position
       for _, s in kit:GetChildren() do
           if s:IsA("MeshPart") then
               s.Anchored = true s.CanCollide = false s.CanQuery = false s.CanTouch = false
               s.CollisionFidelity = Enum.CollisionFidelity.Box
               local p = s:GetPivot()
               s:PivotTo(CFrame.new(p.Position.X - centre.X, 0, p.Position.Z - centre.Z) * p.Rotation)
           end
       end
     (every slab's pivot is then on its top centroid at y = 0, and the kit is centred on the origin)
  3. save the place
"""
import bpy, bmesh, math, random, sys

args = sys.argv[sys.argv.index("--") + 1:]
out = args[0]
seed = int(args[1]) if len(args) > 1 else 11
want = int(args[2]) if len(args) > 2 else 76
rnd = random.Random(seed)
R_OUT = 1.5        # sites reach this far; the outer cells are large and barely move in the game
THICK = 0.10

# sites: denser toward the middle, a minimum spacing that grows with the radius
sites = [(0.0, 0.0)]
tries = 0
while len(sites) < want and tries < 20000:
    tries += 1
    rho = R_OUT * rnd.random() ** 0.66
    a = rnd.uniform(0, 2 * math.pi)
    p = (rho * math.cos(a), rho * math.sin(a))
    dmin = (0.05 + 0.2 * rho) * rnd.uniform(0.45, 1.0)
    if all((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 > dmin * dmin for q in sites):
        sites.append(p)


def clip(poly, m, n):
    """Keep the part of a convex polygon where (p - m) . n <= 0."""
    res = []
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        da = (a[0] - m[0]) * n[0] + (a[1] - m[1]) * n[1]
        db = (b[0] - m[0]) * n[0] + (b[1] - m[1]) * n[1]
        if da <= 0:
            res.append(a)
        if (da < 0) != (db < 0) and da != db:
            t = da / (da - db)
            res.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return res


def convex_hull_clip(poly, hull):
    """Clip a convex polygon by a (roughly convex) outline: by each edge's inner half-plane."""
    for i in range(len(hull)):
        a, b = hull[i], hull[(i + 1) % len(hull)]
        n = (b[1] - a[1], -(b[0] - a[0]))  # outward normal for a counter-clockwise outline
        poly = clip(poly, a, n)
        if len(poly) < 3:
            return []
    return poly


BIG = [(-3, -3), (3, -3), (3, 3), (-3, 3)]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.unit_settings.system = 'NONE'
made, tris = 0, 0
for i, s in enumerate(sites):
    poly = BIG
    for j, q in enumerate(sites):
        if i == j:
            continue
        m = ((s[0] + q[0]) / 2, (s[1] + q[1]) / 2)
        poly = clip(poly, m, (q[0] - s[0], q[1] - s[1]))
        if len(poly) < 3:
            break
    # bound the outer cells by a 24-sided ring a little outside the sites
    ring = [(R_OUT * 1.12 * math.cos(k / 24 * 2 * math.pi), R_OUT * 1.12 * math.sin(k / 24 * 2 * math.pi)) for k in range(24)]
    poly = convex_hull_clip(poly, ring)
    if len(poly) < 3:
        continue
    # drop near-duplicate corners
    pts = []
    for p in poly:
        if not pts or (p[0] - pts[-1][0]) ** 2 + (p[1] - pts[-1][1]) ** 2 > 1e-6:
            pts.append(p)
    if len(pts) < 3:
        continue
    area = 0.5 * sum(pts[k][0] * pts[(k + 1) % len(pts)][1] - pts[(k + 1) % len(pts)][0] * pts[k][1] for k in range(len(pts)))
    if abs(area) < 2e-4:
        continue
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    rho = math.hypot(cx, cy)
    # inset: wider gaps in the middle (deep cracks), hairlines outside
    gap = 0.004 + 0.007 * max(0.0, 1 - rho) if rho < 1.2 else 0.0015
    size = math.sqrt(abs(area))
    k_in = max(0.7, 1 - gap / max(size * 0.5, 1e-3))
    loc = [((p[0] - cx) * k_in, (p[1] - cy) * k_in) for p in pts]
    if area < 0:
        loc.reverse()
    bm = bmesh.new()
    top = [bm.verts.new((x, y, 0.0)) for x, y in loc]
    # the underside is a little smaller: the walls lean in, so a tilted slab shows a wedge of wall, not a box side
    bot = [bm.verts.new((x * 0.86, y * 0.86, -THICK)) for x, y in loc]
    ftop = bm.faces.new(top)
    bm.faces.new(list(reversed(bot)))
    n = len(top)
    for k in range(n):
        bm.faces.new([top[k], bot[k], bot[(k + 1) % n], top[(k + 1) % n]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    assert bm.calc_volume(signed=True) > 0
    uvl = bm.loops.layers.uv.new("UVMap")
    col = bm.loops.layers.color.new("Col")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uvl].uv = (co.x + cx, co.y + cy)
            if face is ftop:
                c = 1.0
            else:
                c = 0.5 if co.z > -1e-6 else 0.2
            loop[col] = (c, c, c, 1.0)
    me = bpy.data.meshes.new("S%02d" % made)
    bm.to_mesh(me)
    tris += sum(len(f.verts) - 2 for f in bm.faces)
    bm.free()
    ob = bpy.data.objects.new("S%02d" % made, me)
    ob.location = (cx, cy, 0.0)
    bpy.context.scene.collection.objects.link(ob)
    ob.select_set(True)
    made += 1
bpy.context.view_layer.objects.active = bpy.context.scene.collection.objects[0]
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={'MESH'},
    global_scale=1.0, apply_unit_scale=True, apply_scale_options='FBX_SCALE_UNITS',
    axis_forward='-Z', axis_up='Y', bake_space_transform=True, use_mesh_modifiers=True,
    mesh_smooth_type='FACE', use_triangles=True, colors_type='SRGB', add_leaf_bones=False,
    bake_anim=False, path_mode='COPY', embed_textures=False)
print("slabs", made, "tris", tris)
