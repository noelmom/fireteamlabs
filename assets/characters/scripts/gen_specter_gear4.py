import bpy
import math
import os
from mathutils import Vector


BODY_PATH = "/private/tmp/claude-501/-Users-noelmomelo-Projects-fireteamlabs/ca4cb7bf-fb09-4542-90bb-dc7eeb3ff33b/scratchpad/blender_out/base_body_male.glb"
OUT_PATH = "/private/tmp/claude-501/-Users-noelmomelo-Projects-fireteamlabs/ca4cb7bf-fb09-4542-90bb-dc7eeb3ff33b/scratchpad/blender_out/specter_gear4.glb"


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
        if datablocks is not bpy.data.materials:
            for block in list(datablocks):
                if block.users == 0:
                    datablocks.remove(block)
    if bpy.context.scene.world is None:
        bpy.context.scene.world = bpy.data.worlds.new("World")


def material(name, base, roughness, metallic, emission=None, strength=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None:
        emission_input = bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")
        if emission_input:
            emission_input.default_value = (*emission, 1.0)
        strength_input = bsdf.inputs.get("Emission Strength")
        if strength_input:
            strength_input.default_value = strength
    return mat


def assign(obj, mat):
    if hasattr(obj.data, "materials"):
        obj.data.materials.clear()
        obj.data.materials.append(mat)


def apply_modifier(obj, modifier):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.select_set(False)


def bevel(obj, width=0.004, segments=2):
    mod = obj.modifiers.new("Subtle bevel", 'BEVEL')
    mod.width = width
    mod.segments = segments
    mod.limit_method = 'ANGLE'
    apply_modifier(obj, mod)


def finish_mesh(obj, mat, bevel_width=0.004):
    assign(obj, mat)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.select_set(False)
    if bevel_width:
        bevel(obj, bevel_width)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def make_grid_shell(name, point_fn, u_count, v_count, body, mat, offset=0.030, thickness=0.015):
    verts = []
    faces = []
    for j in range(v_count + 1):
        v = j / v_count
        for i in range(u_count + 1):
            u = i / u_count
            verts.append(point_fn(u, v))
    row = u_count + 1
    for j in range(v_count):
        for i in range(u_count):
            a = j * row + i
            faces.append((a, a + 1, a + row + 1, a + row))
    mesh = bpy.data.meshes.new(name + "_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    shrink = obj.modifiers.new("Conform to body", 'SHRINKWRAP')
    shrink.wrap_method = 'NEAREST_SURFACEPOINT'
    shrink.target = body
    shrink.offset = offset
    apply_modifier(obj, shrink)
    solid = obj.modifiers.new("Low profile thickness", 'SOLIDIFY')
    solid.thickness = thickness
    solid.offset = 0.0
    solid.use_rim = True
    apply_modifier(obj, solid)
    return finish_mesh(obj, mat, min(0.004, thickness * 0.25))


def cube(name, location, scale, mat, bevel_width=0.004):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return finish_mesh(obj, mat, bevel_width)


def uv_sphere(name, location, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return finish_mesh(obj, mat, 0.003)


def curve_tube(name, points, radius, mat):
    # The caller supplies an already clamped, cheek-hugging polyline.
    data = bpy.data.curves.new(name + "_curve", type='CURVE')
    data.dimensions = '3D'
    data.resolution_u = 2
    data.bevel_depth = radius
    data.bevel_resolution = 2
    spline = data.splines.new('BEZIER')
    spline.bezier_points.add(len(points) - 1)
    for bp, co in zip(spline.bezier_points, points):
        bp.co = co
        bp.handle_left_type = 'AUTO'
        bp.handle_right_type = 'AUTO'
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    assign(obj, mat)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    obj = bpy.context.object
    obj.select_set(False)
    return finish_mesh(obj, mat, 0.0015)


def import_join_body():
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=BODY_PATH)
    imported = [o for o in bpy.context.scene.objects if o not in before]
    meshes = [o for o in imported if o.type == 'MESH']
    if not meshes:
        raise RuntimeError("Reference GLB contains no mesh")
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    body = bpy.context.object
    body.name = "SHRINKWRAP_TARGET_BODY"
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    body.hide_render = True
    for obj in imported:
        if obj != body and obj.name in bpy.context.scene.objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    return body


clear_scene()
body = import_join_body()

black = material("TacticalBlack", (0.02, 0.02, 0.022), 0.60, 0.05)
fabric = material("TacticalFabric", (0.05, 0.052, 0.055), 0.75, 0.0)
metal = material("DarkMetal", (0.20, 0.21, 0.22), 0.40, 0.80)
cyan = material("EmitCyan", (0.0, 0.45, 0.60), 0.28, 0.10, (0.0, 0.9, 1.0), 3.0)
gear = []

# Vest: separate front/back shells leave both sides visibly open.
def vest_panel(front):
    y = -0.185 if front else 0.155
    def fn(u, v):
        z = 1.15 + 0.30 * v
        waist = 0.235 + 0.045 * v - 0.035 * math.sin(math.pi * v)
        x = (2.0 * u - 1.0) * waist
        # Shallow curvature is close enough for nearest-surface shrinkwrap to settle reliably.
        yy = y + (0.045 if front else -0.030) * (x / max(waist, 0.001)) ** 2
        return (x, yy, z)
    return fn

gear.append(make_grid_shell("specter_plate_carrier_front", vest_panel(True), 18, 14, body, fabric, 0.028, 0.015))
gear.append(make_grid_shell("specter_plate_carrier_back", vest_panel(False), 18, 14, body, fabric, 0.028, 0.015))

# Thin shoulder straps only span the short front-to-back distance, never beyond the torso.
for side in (-1, 1):
    gear.append(cube("specter_plate_carrier_strap_L" if side < 0 else "specter_plate_carrier_strap_R",
                     (0.155 * side, -0.012, 1.445), (0.045, 0.165, 0.010), black, 0.005))

# Flat front pouches and restrained panel seams.
for x in (-0.075, 0.075):
    gear.append(cube("specter_molle_mag_pouch", (x, -0.222, 1.255), (0.060, 0.018, 0.082), fabric, 0.006))
    for z in (1.225, 1.265, 1.305):
        gear.append(cube("specter_molle_webbing", (x, -0.242, z), (0.052, 0.004, 0.006), black, 0.002))
gear.append(cube("specter_admin_pouch", (0.0, -0.220, 1.375), (0.105, 0.016, 0.043), black, 0.005))
gear.append(cube("specter_chest_indicator", (0.077, -0.240, 1.390), (0.012, 0.004, 0.009), cyan, 0.002))

# Helmet dome as a face-open rear/side/top shell. Angular range excludes the front facial quadrant.
def helmet_fn(u, v):
    theta = math.radians(-145.0 + 290.0 * u)
    phi = math.radians(8.0 + 78.0 * v)
    # Coordinate convention: front is negative Y.
    return (0.112 * math.sin(phi) * math.sin(theta),
            0.020 + 0.105 * math.sin(phi) * math.cos(theta),
            1.685 + 0.112 * math.cos(phi))

gear.append(make_grid_shell("specter_helmet", helmet_fn, 28, 12, body, black, 0.018, 0.015))
gear.append(cube("specter_helmet_top_rail", (0.0, 0.018, 1.802), (0.026, 0.040, 0.008), metal, 0.003))
gear.append(cube("specter_nvg_mount_stub", (0.0, -0.092, 1.730), (0.022, 0.011, 0.024), metal, 0.003))

# SHORT right cheek boom: total endpoint distance 0.086 m and curved path < 0.10 m.
boom_points = [(0.105, -0.020, 1.690), (0.112, -0.052, 1.675),
               (0.101, -0.082, 1.659), (0.080, -0.091, 1.651)]
assert sum((Vector(b) - Vector(a)).length for a, b in zip(boom_points, boom_points[1:])) <= 0.10
gear.append(curve_tube("specter_headset_boom_SHORT", boom_points, 0.004, metal))
gear.append(uv_sphere("specter_boom_mic", boom_points[-1], (0.008, 0.008, 0.006), black))

# Small conforming shoulder caps; each grid is hard-clamped to 0.11 m lateral width.
for side in (-1, 1):
    def shoulder_fn(u, v, side=side):
        x = side * (0.245 + 0.055 * u)
        y = -0.055 + 0.110 * v
        z = 1.410 - 0.030 * ((u - 0.25) ** 2 + (v - 0.5) ** 2)
        return (x, y, z)
    name = "specter_shoulder_pad_L" if side < 0 else "specter_shoulder_pad_R"
    gear.append(make_grid_shell(name, shoulder_fn, 8, 8, body, fabric, 0.025, 0.013))

# Waist belt: front and back conforming strips plus small side closures.
for front in (True, False):
    y0 = -0.145 if front else 0.125
    def belt_fn(u, v, y0=y0):
        x = (u * 2.0 - 1.0) * 0.275
        return (x, y0, 0.965 + 0.070 * v)
    gear.append(make_grid_shell("specter_belt_front" if front else "specter_belt_back",
                                belt_fn, 18, 4, body, black, 0.022, 0.012))
for side in (-1, 1):
    gear.append(cube("specter_belt_side", (0.278 * side, 0.0, 1.000), (0.010, 0.105, 0.030), black, 0.004))
for i, x in enumerate((-0.205, 0.0, 0.205)):
    y = 0.160 if i != 1 else -0.180
    gear.append(cube("specter_belt_pouch", (x, y, 1.005), (0.050, 0.025, 0.052), fabric, 0.006))
gear.append(cube("specter_belt_buckle", (0.0, -0.184, 1.000), (0.028, 0.009, 0.024), metal, 0.004))

# Low-profile knee shells, centered on the front of each knee.
for side in (-1, 1):
    def knee_fn(u, v, side=side):
        return (side * 0.105 + (u - 0.5) * 0.105, -0.105, 0.445 + 0.110 * v)
    name = "specter_knee_pad_L" if side < 0 else "specter_knee_pad_R"
    gear.append(make_grid_shell(name, knee_fn, 8, 8, body, fabric, 0.022, 0.012))

# Reference body is used only during construction and must never be exported.
bpy.data.objects.remove(body, do_unlink=True)

# Apply remaining transforms, select gear only, and export a model-only GLB.
bpy.ops.object.select_all(action='DESELECT')
for obj in gear:
    if obj and obj.name in bpy.context.scene.objects:
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUT_PATH, export_format='GLB', use_selection=True,
                          export_apply=True, export_animations=False, export_cameras=False,
                          export_lights=False)
print(OUT_PATH)
