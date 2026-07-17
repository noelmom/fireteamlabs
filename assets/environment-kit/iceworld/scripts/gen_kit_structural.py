import bpy
import math
import os


OUT_PATH = "/private/tmp/claude-501/-Users-noelmomelo-Projects-fireteamlabs/ca4cb7bf-fb09-4542-90bb-dc7eeb3ff33b/scratchpad/blender_out/kit_structural.glb"


# Start from a deterministic, empty scene.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for datablock in bpy.data.meshes:
    if datablock.users == 0:
        bpy.data.meshes.remove(datablock)

scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
if scene.world is None:
    scene.world = bpy.data.worlds.new("World")


def make_material(name, color, roughness, metallic):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


PAINT = make_material("PaintedSteel", (0.16, 0.19, 0.22), 0.50, 0.10)
METAL = make_material("BareMetal", (0.25, 0.25, 0.25), 0.35, 0.90)
CONCRETE = make_material("Concrete", (0.34, 0.33, 0.30), 0.90, 0.00)
TRIM = make_material("DarkTrim", (0.03, 0.03, 0.03), 0.40, 0.85)


def box(name, loc, scale, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] / 2, scale[1] / 2, scale[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel > 0:
        mod = obj.modifiers.new("EdgeSoftening", 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def cylinder(name, loc, radius, depth, mat, rotation=(math.pi / 2, 0, 0), vertices=10):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return obj


def finish(parts, name, pivot):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    obj.data.name = name + "_mesh"
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    scene.cursor.location = pivot
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    return obj


def add_panel_detail(parts, x, height, width=2.0, y_front=-0.1):
    # Three recessed fields with crisp rails, seams, and regularly spaced rivets.
    margin = 0.16
    seam_z = [height / 3, 2 * height / 3]
    for z in seam_z:
        parts.append(box("seam", (x, y_front - 0.012, z), (width - 0.10, 0.025, 0.026), TRIM))
    field_h = height / 3 - 0.12
    for row in range(3):
        if (row + 0.5) * height / 3 >= height:
            continue
        zc = (row + 0.5) * height / 3
        parts.append(box("recess", (x, y_front - 0.018, zc),
                         (width - 2 * margin, 0.022, field_h), TRIM, 0.008))
        parts.append(box("inset", (x, y_front - 0.032, zc),
                         (width - 2 * margin - 0.08, 0.025, field_h - 0.08), PAINT, 0.012))
    rows = max(3, int(height / 0.24))
    for side in (-1, 1):
        for i in range(rows + 1):
            z = 0.10 + (height - 0.20) * i / rows
            parts.append(cylinder("rivet", (x + side * (width / 2 - 0.075), y_front - 0.035, z),
                                  0.021, 0.025, METAL, vertices=8))


def build_wall(x):
    p = [box("wall_body", (x, 0, 1.5), (2.0, 0.20, 3.0), PAINT, 0.018)]
    add_panel_detail(p, x, 3.0)
    return finish(p, "kit_wall_panel", (x, 0, 0))


def build_half(x):
    p = [box("half_body", (x, 0, 0.6), (2.0, 0.20, 1.2), PAINT, 0.018)]
    # Two broad recessed bays and enough small fasteners to retain readable scale.
    for z in (0.32, 0.88):
        p.append(box("recess", (x, -0.112, z), (1.70, 0.024, 0.46), TRIM, 0.008))
        p.append(box("inset", (x, -0.128, z), (1.61, 0.025, 0.37), PAINT, 0.01))
    p.append(box("cap", (x, 0, 1.18), (2.04, 0.25, 0.08), METAL, 0.015))
    for side in (-1, 1):
        for i in range(7):
            p.append(cylinder("rivet", (x + side * 0.925, -0.135, 0.10 + i * 0.165),
                              0.021, 0.025, METAL, vertices=8))
    return finish(p, "kit_wall_half", (x, 0, 0))


def build_doorway(x):
    # Opening is genuinely empty: two jamb wall sections and a lintel.
    p = [
        box("left_wall", (x - 0.75, 0, 1.5), (0.50, 0.20, 3.0), PAINT, 0.015),
        box("right_wall", (x + 0.75, 0, 1.5), (0.50, 0.20, 3.0), PAINT, 0.015),
        box("lintel_wall", (x, 0, 2.60), (1.0, 0.20, 0.80), PAINT, 0.015),
        box("frame_l", (x - 0.535, -0.005, 1.10), (0.07, 0.28, 2.20), METAL, 0.012),
        box("frame_r", (x + 0.535, -0.005, 1.10), (0.07, 0.28, 2.20), METAL, 0.012),
        box("frame_top", (x, -0.005, 2.235), (1.14, 0.28, 0.07), METAL, 0.012),
        box("threshold", (x, -0.005, 0.025), (1.14, 0.30, 0.05), TRIM, 0.008),
    ]
    for side in (-1, 1):
        for i in range(12):
            p.append(cylinder("frame_bolt", (x + side * 0.535, -0.158, 0.12 + i * 0.18),
                              0.018, 0.025, TRIM, vertices=8))
    for z in (0.72, 1.48, 2.56):
        for side in (-1, 1):
            p.append(box("wall_seam", (x + side * 0.75, -0.112, z), (0.43, 0.025, 0.025), TRIM))
    return finish(p, "kit_doorway", (x, 0, 0))


def build_floor_solid(x):
    p = [box("floor_slab", (x, 0, 0.075), (2.0, 2.0, 0.15), CONCRETE, 0.018)]
    for offset in (-0.5, 0, 0.5):
        p.append(box("floor_seam", (x + offset, 0, 0.154), (0.018, 1.94, 0.012), TRIM))
        p.append(box("floor_seam", (x, offset, 0.154), (1.94, 0.018, 0.012), TRIM))
    for ix in range(5):
        for iy in range(5):
            p.append(cylinder("floor_fastener", (x - 0.9 + ix * 0.45, -0.9 + iy * 0.45, 0.165),
                              0.018, 0.018, METAL, rotation=(0, 0, 0), vertices=8))
    return finish(p, "kit_floor_solid", (x, 0, 0))


def build_floor_grate(x):
    p = []
    # Perimeter frame plus orthogonal inset bars leaves visible open cells.
    p += [
        box("grate_frame", (x - 0.95, 0, 0.05), (0.10, 2.0, 0.10), METAL, 0.012),
        box("grate_frame", (x + 0.95, 0, 0.05), (0.10, 2.0, 0.10), METAL, 0.012),
        box("grate_frame", (x, -0.95, 0.05), (1.80, 0.10, 0.10), METAL, 0.012),
        box("grate_frame", (x, 0.95, 0.05), (1.80, 0.10, 0.10), METAL, 0.012),
    ]
    for i in range(-9, 10):
        p.append(box("grate_bar", (x + i * 0.09, 0, 0.055), (0.025, 1.80, 0.085), METAL, 0.005))
    for i in range(-9, 10):
        p.append(box("cross_bar", (x, i * 0.09, 0.062), (1.80, 0.022, 0.045), TRIM, 0.004))
    return finish(p, "kit_floor_grate", (x, 0, 0))


def build_ceiling(x):
    p = [box("ceiling_body", (x, 0, 0.075), (2.0, 2.0, 0.15), PAINT, 0.018)]
    p.append(box("slot_recess", (x, -0.01, -0.012), (1.45, 0.46, 0.035), TRIM, 0.012))
    p.append(box("slot_insert", (x, -0.01, -0.035), (1.30, 0.32, 0.025), METAL, 0.008))
    for off in (-0.58, 0.58):
        p.append(box("rib", (x + off, 0, -0.016), (0.035, 1.86, 0.030), TRIM, 0.006))
    for ix in (-0.88, -0.58, 0.58, 0.88):
        for iy in (-0.86, -0.43, 0, 0.43, 0.86):
            p.append(cylinder("ceiling_fastener", (x + ix, iy, -0.035), 0.018, 0.018,
                              METAL, rotation=(0, 0, 0), vertices=8))
    return finish(p, "kit_ceiling_panel", (x, 0, 0))


def build_pillar(x):
    p = [box("pillar_core", (x, 0, 1.5), (0.40, 0.40, 3.0), PAINT, 0.025)]
    p += [
        box("base", (x, 0, 0.08), (0.62, 0.62, 0.16), METAL, 0.025),
        box("base_trim", (x, 0, 0.24), (0.50, 0.50, 0.10), TRIM, 0.015),
        box("cap", (x, 0, 2.92), (0.62, 0.62, 0.16), METAL, 0.025),
        box("cap_trim", (x, 0, 2.76), (0.50, 0.50, 0.10), TRIM, 0.015),
    ]
    for face_y in (-0.211, 0.211):
        for i in range(13):
            p.append(cylinder("pillar_bolt", (x, face_y, 0.22 + i * 0.215), 0.018, 0.022,
                              METAL, vertices=8))
    return finish(p, "kit_pillar", (x, 0, 0))


builders = (build_wall, build_half, build_doorway, build_floor_solid,
            build_floor_grate, build_ceiling, build_pillar)
objects = [builder(i * 4.0) for i, builder in enumerate(builders)]

# Ensure only the seven deliverable mesh objects are selected and exported.
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
    obj.select_set(True)
    obj.hide_render = False

os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=OUT_PATH,
    export_format='GLB',
    use_selection=True,
    export_apply=True,
    export_materials='EXPORT',
    export_cameras=False,
    export_lights=False,
)
print(OUT_PATH)
