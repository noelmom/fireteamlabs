import bpy
import math
import os
from mathutils import Vector

# Modular cold-industrial utility/greeble kit for Blender 5.0 (headless).
OUT = "/private/tmp/claude-501/-Users-noelmomelo-Projects-fireteamlabs/ca4cb7bf-fb09-4542-90bb-dc7eeb3ff33b/scratchpad/blender_out/kit_utility.glb"

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
    if datablocks is not bpy.data.materials:
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)
if bpy.context.scene.world is None:
    bpy.context.scene.world = bpy.data.worlds.new("ColdIndustrialWorld")


def material(name, color, roughness, metallic, emission=None, strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return m


MAT = {
    "PaintedSteel": material("PaintedSteel", (0.16, 0.19, 0.22), 0.50, 0.10),
    "BareMetal": material("BareMetal", (0.25, 0.25, 0.25), 0.35, 0.90),
    "DarkTrim": material("DarkTrim", (0.03, 0.03, 0.03), 0.40, 0.85),
    "Rubber": material("Rubber", (0.02, 0.02, 0.02), 0.80, 0.00),
    "EmitWhite": material("EmitWhite", (0.82, 0.88, 0.90), 0.28, 0.00, (1.0, 1.0, 1.0), 4.0),
    "EmitGreen": material("EmitGreen", (0.02, 0.20, 0.04), 0.30, 0.00, (0.02, 1.0, 0.08), 5.0),
    "EmitRed": material("EmitRed", (0.25, 0.01, 0.01), 0.30, 0.00, (1.0, 0.01, 0.01), 5.0),
}


def finish(obj, mat, bevel=0.0):
    obj.data.materials.append(MAT[mat])
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("EdgeSoftening", 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = 'ANGLE'
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.select_set(False)
    return obj


def cube(parts, name, loc, scale, mat, bevel=0.012):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = (scale[0] / 2, scale[1] / 2, scale[2] / 2)
    parts.append(finish(o, mat, bevel))
    return o


def cyl(parts, name, loc, radius, depth, mat, rot=(0, 0, 0), vertices=16, bevel=0.006):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    parts.append(finish(o, mat, bevel))
    return o


def torus(parts, name, loc, major, minor, mat, rot=(0, 0, 0), major_segments=20, minor_segments=8):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                    major_segments=major_segments, minor_segments=minor_segments,
                                    location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    parts.append(finish(o, mat, 0.0))
    return o


def assemble(parts, name):
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    o = bpy.context.object
    o.name = name
    o.data.name = name + "_Mesh"
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.select_set(False)
    return o


objects = []

# 1: 0.6 x 0.6 x 2 m HVAC duct, length along X.
x = 0.0
p = []
cube(p, "duct_body", (x, 0, 1.05), (1.88, .60, .60), "PaintedSteel", .025)
for dx in (-.98, .98):
    cube(p, "duct_flange", (x + dx, 0, 1.05), (.06, .72, .72), "BareMetal", .012)
for dx in (-.52, 0, .52):
    cube(p, "duct_seam_top", (x + dx, 0, 1.365), (.045, .64, .035), "DarkTrim", .005)
    cube(p, "duct_seam_side", (x + dx, -.315, 1.05), (.045, .035, .64), "DarkTrim", .005)
for dx in (-.98, .98):
    for yy in (-.31, .31):
        for zz in (.74, 1.36):
            cyl(p, "flange_bolt", (x + dx, yy, zz), .025, .08, "DarkTrim", (0, math.pi/2, 0), 12, .002)
objects.append(assemble(p, "kit_duct_segment"))

# 2: parallel pipe run with two wall standoffs.
x = 2.5
p = []
for y, r in ((-.14, .055), (0, .05), (.14, .045)):
    cyl(p, "pipe", (x, y, 1.0), r, 2.0, "BareMetal", (0, math.pi/2, 0), 16, .004)
    for dx in (-.72, .72):
        torus(p, "pipe_clamp", (x + dx, y, 1.0), r + .011, .009, "DarkTrim", (0, math.pi/2, 0), 16, 6)
for dx in (-.72, .72):
    cube(p, "pipe_bracket", (x + dx, 0, .87), (.08, .48, .05), "PaintedSteel", .008)
    cube(p, "pipe_standoff", (x + dx, 0, .79), (.08, .08, .16), "DarkTrim", .006)
objects.append(assemble(p, "kit_pipe_run"))

# 3: cable tray with side rails, crossbars and bundled cables.
x = 5.0
p = []
for y in (-.15, .15):
    cube(p, "tray_rail", (x, y, .95), (2.0, .035, .16), "BareMetal", .007)
for dx in (-.88, -.55, -.22, .11, .44, .77):
    cube(p, "tray_rung", (x + dx, 0, .89), (.035, .30, .025), "BareMetal", .004)
for y, z, r in ((-.08, .94, .018), (-.025, .96, .015), (.035, .945, .02), (.09, .965, .014)):
    cyl(p, "cable", (x, y, z), r, 1.92, "Rubber", (0, math.pi/2, 0), 12, .002)
objects.append(assemble(p, "kit_cable_tray"))

# 4: junction panel, door, hinge, conduits and green pilot light.
x = 7.5
p = []
cube(p, "panel_box", (x, 0, 1.05), (.50, .15, .70), "PaintedSteel", .025)
cube(p, "panel_door", (x, -.087, 1.05), (.44, .035, .62), "BareMetal", .016)
for z in (.82, 1.28):
    cyl(p, "door_hinge", (x - .205, -.115, z), .018, .13, "DarkTrim", (math.pi/2, 0, 0), 12, .003)
cube(p, "door_latch", (x + .17, -.12, 1.04), (.035, .025, .11), "DarkTrim", .005)
cyl(p, "status_bezel", (x + .12, -.126, 1.24), .036, .025, "DarkTrim", (math.pi/2, 0, 0), 16, .003)
cyl(p, "status_green", (x + .12, -.142, 1.24), .022, .012, "EmitGreen", (math.pi/2, 0, 0), 16, .002)
for dx in (-.13, .13):
    cyl(p, "conduit_stub", (x + dx, 0, .60), .035, .20, "BareMetal", (0, 0, 0), 16, .004)
objects.append(assemble(p, "kit_junction_panel"))

# 5: recessed fluorescent fixture with bright inset panel.
x = 10.0
p = []
cube(p, "fluoro_housing", (x, 0, 1.02), (1.20, .20, .15), "PaintedSteel", .025)
cube(p, "fluoro_recess", (x, -.106, 1.02), (1.08, .018, .105), "DarkTrim", .008)
cube(p, "fluoro_diffuser", (x, -.118, 1.02), (.98, .012, .075), "EmitWhite", .012)
for dx in (-.54, .54):
    cube(p, "fluoro_endcap", (x + dx, -.12, 1.02), (.07, .025, .13), "BareMetal", .008)
objects.append(assemble(p, "kit_fluorescent"))

# 6: emergency light with twin red adjustable lamp heads.
x = 12.5
p = []
cube(p, "emergency_base", (x, 0, 1.0), (.25, .15, .20), "PaintedSteel", .022)
for dx in (-.072, .072):
    cyl(p, "lamp_neck", (x + dx, -.105, 1.07), .018, .08, "DarkTrim", (math.pi/2, 0, 0), 12, .003)
    cyl(p, "lamp_head", (x + dx, -.16, 1.07), .055, .065, "DarkTrim", (math.pi/2, 0, 0), 16, .006)
    cyl(p, "lamp_red", (x + dx, -.198, 1.07), .040, .012, "EmitRed", (math.pi/2, 0, 0), 16, .002)
objects.append(assemble(p, "kit_emergency_light"))

# 7: EXIT sign, slim dark body and luminous green face.
x = 15.0
p = []
cube(p, "exit_body", (x, 0, 1.05), (.40, .05, .20), "DarkTrim", .018)
cube(p, "exit_face", (x, -.031, 1.05), (.35, .012, .15), "EmitGreen", .008)
# Dark inset bars suggest EXIT letterforms while preserving the luminous face.
for dx, w in ((-.12, .018), (-.085, .055), (-.015, .018), (.045, .018), (.11, .018)):
    cube(p, "exit_glyph", (x + dx, -.041, 1.05), (w, .008, .095), "DarkTrim", .002)
cube(p, "exit_glyph_cross", (x - .085, -.041, 1.05), (.055, .008, .015), "DarkTrim", .001)
objects.append(assemble(p, "kit_exit_sign"))

# 8: compact mixed greeble trim: vent, bolts, and hand valve.
x = 17.5
p = []
cube(p, "greeble_backplate", (x, 0, .98), (.50, .06, .32), "PaintedSteel", .018)
cube(p, "vent_frame", (x - .11, -.045, 1.0), (.20, .025, .22), "DarkTrim", .006)
for z in (.93, .975, 1.02, 1.065):
    cube(p, "vent_louver", (x - .11, -.064, z), (.16, .018, .018), "BareMetal", .003)
for dx in (-.21, .21):
    for z in (.86, 1.10):
        cyl(p, "trim_bolt", (x + dx, -.06, z), .022, .025, "BareMetal", (math.pi/2, 0, 0), 12, .003)
cyl(p, "valve_stem", (x + .13, -.105, 1.0), .020, .15, "BareMetal", (math.pi/2, 0, 0), 12, .002)
torus(p, "valve_wheel", (x + .13, -.19, 1.0), .075, .012, "DarkTrim", (math.pi/2, 0, 0), 20, 8)
for a in (0, math.pi/2):
    cube(p, "valve_spoke", (x + .13, -.192, 1.0), (.13 if a == 0 else .018, .014, .018 if a == 0 else .13), "DarkTrim", .003)
objects.append(assemble(p, "kit_greeble_trim"))

# Ensure only the eight deliverable meshes are exported.
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.select_set(True)
    o["module_scale_m"] = 2.0
    o["kit_category"] = "utility_greeble"

os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1.0
bpy.ops.export_scene.gltf(
    filepath=OUT,
    export_format='GLB',
    use_selection=True,
    export_apply=True,
    export_materials='EXPORT',
    export_yup=True,
)
print(OUT)
