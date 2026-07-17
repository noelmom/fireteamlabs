import bpy
import math
import os
from mathutils import Vector


OUTPUT_PATH = "/private/tmp/claude-501/-Users-noelmomelo-Projects-fireteamlabs/ca4cb7bf-fb09-4542-90bb-dc7eeb3ff33b/scratchpad/blender_out/kit_special.glb"


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)
    if bpy.context.scene.world is None:
        bpy.context.scene.world = bpy.data.worlds.new("ColdIndustrialWorld")


def set_socket(node, names, value):
    for name in names:
        socket = node.inputs.get(name)
        if socket is not None:
            socket.default_value = value
            return


def make_material(name, color, metallic, roughness, transmission=0.0,
                  ior=1.5, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    set_socket(bsdf, ("Base Color",), (*color, 1.0))
    set_socket(bsdf, ("Metallic",), metallic)
    set_socket(bsdf, ("Roughness",), roughness)
    set_socket(bsdf, ("Transmission Weight", "Transmission"), transmission)
    set_socket(bsdf, ("IOR",), ior)
    if emission is not None:
        set_socket(bsdf, ("Emission Color", "Emission"), (*emission, 1.0))
        set_socket(bsdf, ("Emission Strength",), emission_strength)
    if transmission > 0.0:
        mat.surface_render_method = 'DITHERED'
    return mat


def add_box(parts, name, location, scale, material, bevel=0.025):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] * 0.5, scale[1] * 0.5, scale[2] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    if bevel > 0.0:
        mod = obj.modifiers.new("EdgeSoftening", 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = 'ANGLE'
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    parts.append(obj)
    return obj


def add_cylinder(parts, name, location, radius, depth, material,
                 rotation=(0.0, 0.0, 0.0), vertices=12, bevel=0.015):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                       depth=depth, location=location,
                                       rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        mod = obj.modifiers.new("EdgeSoftening", 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = 'ANGLE'
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    parts.append(obj)
    return obj


def join_kit(parts, final_name, origin):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = final_name
    obj.data.name = final_name + "_Mesh"
    bpy.context.scene.cursor.location = origin
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR', center='MEDIAN')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return obj


def build_blast_door(x, mats):
    p = []
    # Door leaf and reinforced jamb/header frame.
    add_box(p, "BlastDoor_Leaf", (x, 0.0, 1.50), (1.72, 0.30, 2.70), mats['PaintedSteel'], 0.045)
    for sx in (-0.96, 0.96):
        add_box(p, "BlastDoor_Jamb", (x + sx, 0.0, 1.50), (0.20, 0.42, 3.00), mats['BareMetal'], 0.035)
    add_box(p, "BlastDoor_Header", (x, 0.0, 2.90), (2.00, 0.42, 0.20), mats['BareMetal'], 0.035)
    add_box(p, "BlastDoor_Sill", (x, 0.0, 0.10), (2.00, 0.42, 0.20), mats['DarkTrim'], 0.025)
    # Face reinforcement ribs and central vault boss.
    for z in (0.42, 1.05, 1.95, 2.58):
        add_box(p, "BlastDoor_Rib", (x, -0.176, z), (1.55, 0.07, 0.10), mats['DarkTrim'], 0.018)
    for sx in (-0.63, 0.63):
        add_box(p, "BlastDoor_VerticalRib", (x + sx, -0.176, 1.50), (0.10, 0.07, 2.55), mats['DarkTrim'], 0.018)
    add_cylinder(p, "BlastDoor_VaultBoss", (x, -0.235, 1.42), 0.25, 0.12,
                 mats['BareMetal'], rotation=(math.pi / 2, 0, 0), vertices=16)
    for ang in (0, math.pi / 2, math.pi, 3 * math.pi / 2):
        cx = x + math.cos(ang) * 0.34
        cz = 1.42 + math.sin(ang) * 0.34
        bar = add_box(p, "BlastDoor_LockBar", ((x + cx) / 2, -0.245, (1.42 + cz) / 2),
                      (0.10, 0.10, 0.42), mats['BareMetal'], 0.012)
        bar.rotation_euler[1] = ang
        bpy.context.view_layer.objects.active = bar
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Frosted armored slit and trim.
    add_box(p, "BlastDoor_WindowTrim", (x, -0.235, 2.20), (0.88, 0.10, 0.28), mats['DarkTrim'], 0.025)
    add_box(p, "BlastDoor_Window", (x, -0.292, 2.20), (0.68, 0.025, 0.12), mats['FrostGlass'], 0.008)
    # Paired hydraulic cylinders beside the leaf.
    for sx in (-0.78, 0.78):
        add_cylinder(p, "BlastDoor_HydraulicBody", (x + sx, -0.26, 0.73), 0.075, 0.70,
                     mats['DarkTrim'], vertices=12)
        add_cylinder(p, "BlastDoor_HydraulicRod", (x + sx, -0.26, 1.20), 0.035, 0.34,
                     mats['BareMetal'], vertices=12, bevel=0.008)
    # Hazard stripe trim across the upper face.
    add_box(p, "BlastDoor_HazardBacking", (x, -0.235, 2.76), (1.58, 0.07, 0.18), mats['DarkTrim'], 0.008)
    for i in range(-3, 4):
        stripe = add_box(p, "BlastDoor_HazardStripe", (x + i * 0.225, -0.278, 2.76),
                         (0.12, 0.025, 0.20), mats['HazardYellow'], 0.006)
        stripe.rotation_euler[1] = -math.radians(28)
        bpy.context.view_layer.objects.active = stripe
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Control panel with emissive status lamp.
    add_box(p, "BlastDoor_ControlPanel", (x + 1.16, -0.20, 1.42), (0.26, 0.18, 0.52), mats['DarkTrim'], 0.025)
    add_box(p, "BlastDoor_ControlFace", (x + 1.16, -0.302, 1.42), (0.20, 0.035, 0.42), mats['BareMetal'], 0.012)
    add_cylinder(p, "BlastDoor_AmberLamp", (x + 1.16, -0.337, 1.55), 0.045, 0.025,
                 mats['EmitAmber'], rotation=(math.pi / 2, 0, 0), vertices=12, bevel=0.006)
    return join_kit(p, "kit_blast_door", (x, 0.0, 0.0))


def build_shelving(x, mats):
    p = []
    # Four uprights, four perforation-like collars each, and four shelves.
    for sx in (-0.46, 0.46):
        for sy in (-0.21, 0.21):
            add_box(p, "Shelf_Upright", (x + sx, sy, 1.0), (0.055, 0.055, 2.0), mats['DarkTrim'], 0.012)
            for z in (0.12, 0.66, 1.20, 1.74):
                add_box(p, "Shelf_Collar", (x + sx, sy, z), (0.08, 0.08, 0.055), mats['BareMetal'], 0.008)
    for z in (0.14, 0.67, 1.20, 1.73):
        # Steel rim, then six depth-running wire slats.
        add_box(p, "Shelf_Rim", (x, 0.0, z), (0.96, 0.48, 0.055), mats['BareMetal'], 0.012)
        for sx in (-0.36, -0.22, -0.08, 0.08, 0.22, 0.36):
            add_cylinder(p, "Shelf_Wire", (x + sx, 0.0, z + 0.035), 0.009, 0.42,
                         mats['DarkTrim'], rotation=(math.pi / 2, 0, 0), vertices=8, bevel=0.003)
    # Rear cross-bracing.
    for angle in (-math.radians(25), math.radians(25)):
        brace = add_box(p, "Shelf_CrossBrace", (x, 0.245, 1.0), (0.045, 0.035, 1.92), mats['DarkTrim'], 0.008)
        brace.rotation_euler[1] = angle
        bpy.context.view_layer.objects.active = brace
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Stored boxes, with contrasting lid bands.
    add_box(p, "Shelf_BoxLarge", (x - 0.19, 0.0, 0.40), (0.48, 0.36, 0.43), mats['PaintedSteel'], 0.025)
    add_box(p, "Shelf_BoxLargeLid", (x - 0.19, 0.0, 0.61), (0.50, 0.38, 0.055), mats['HazardYellow'], 0.012)
    add_box(p, "Shelf_BoxSmall", (x + 0.20, 0.02, 0.91), (0.36, 0.32, 0.39), mats['PaintedSteel'], 0.025)
    add_box(p, "Shelf_BoxSmallBand", (x + 0.20, -0.15, 0.91), (0.22, 0.025, 0.12), mats['HazardYellow'], 0.008)
    return join_kit(p, "kit_shelving", (x, 0.0, 0.0))


def build_observation_window(x, mats):
    p = []
    # 2 x 3 m wall section constructed around a 1.5 x 1.35 m opening.
    add_box(p, "Observation_WallLeft", (x - 0.875, 0.0, 1.50), (0.25, 0.20, 3.00), mats['PaintedSteel'], 0.025)
    add_box(p, "Observation_WallRight", (x + 0.875, 0.0, 1.50), (0.25, 0.20, 3.00), mats['PaintedSteel'], 0.025)
    add_box(p, "Observation_WallBottom", (x, 0.0, 0.55), (1.50, 0.20, 1.10), mats['PaintedSteel'], 0.025)
    add_box(p, "Observation_WallTop", (x, 0.0, 2.625), (1.50, 0.20, 0.75), mats['PaintedSteel'], 0.025)
    # Deep metal frame and four corner gussets.
    for sx in (-0.79, 0.79):
        add_box(p, "Observation_FrameVertical", (x + sx, -0.015, 1.78), (0.10, 0.27, 1.58), mats['BareMetal'], 0.018)
    for z in (0.96, 2.60):
        add_box(p, "Observation_FrameHorizontal", (x, -0.015, z), (1.68, 0.27, 0.10), mats['BareMetal'], 0.018)
    for sx in (-0.70, 0.70):
        for z in (1.06, 2.50):
            add_cylinder(p, "Observation_FrameBolt", (x + sx, -0.174, z), 0.035, 0.025,
                         mats['DarkTrim'], rotation=(math.pi / 2, 0, 0), vertices=12, bevel=0.006)
    # Thick frosted pane plus dark inner gasket and center mullion.
    add_box(p, "Observation_Gasket", (x, -0.125, 1.78), (1.48, 0.035, 1.42), mats['DarkTrim'], 0.018)
    add_box(p, "Observation_FrostGlass", (x, -0.155, 1.78), (1.38, 0.035, 1.30), mats['FrostGlass'], 0.012)
    add_box(p, "Observation_Mullion", (x, -0.19, 1.78), (0.065, 0.065, 1.34), mats['BareMetal'], 0.012)
    # Lower kick plate and structural seams.
    add_box(p, "Observation_KickPlate", (x, -0.125, 0.36), (1.72, 0.055, 0.54), mats['BareMetal'], 0.018)
    for sx in (-0.55, 0.55):
        add_box(p, "Observation_LowerSeam", (x + sx, -0.16, 0.55), (0.035, 0.025, 0.92), mats['DarkTrim'], 0.006)
    return join_kit(p, "kit_observation_window", (x, 0.0, 0.0))


def main():
    clear_scene()
    mats = {
        'PaintedSteel': make_material('PaintedSteel', (0.16, 0.19, 0.22), 0.10, 0.50),
        'BareMetal': make_material('BareMetal', (0.25, 0.25, 0.25), 0.90, 0.35),
        'DarkTrim': make_material('DarkTrim', (0.03, 0.03, 0.03), 0.85, 0.40),
        'HazardYellow': make_material('HazardYellow', (0.60, 0.50, 0.05), 0.10, 0.50),
        'FrostGlass': make_material('FrostGlass', (0.82, 0.94, 1.00), 0.00, 0.35,
                                    transmission=0.90, ior=1.45),
        'EmitAmber': make_material('EmitAmber', (0.35, 0.12, 0.01), 0.00, 0.28,
                                   emission=(1.00, 0.28, 0.015), emission_strength=5.0),
    }
    build_blast_door(0.0, mats)
    build_shelving(3.5, mats)
    build_observation_window(7.0, mats)

    # Guarantee only the three assembled mesh objects are exported.
    bpy.ops.object.select_all(action='SELECT')
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            obj.select_set(True)
        else:
            obj.select_set(False)
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=OUTPUT_PATH, export_format='GLB',
                              use_selection=True, export_apply=True)
    print(OUTPUT_PATH)


if __name__ == "__main__":
    main()
