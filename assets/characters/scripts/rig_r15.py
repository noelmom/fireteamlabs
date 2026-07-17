"""First-pass R15-compatible rig + auto-skin for the base body.

Builds an armature whose bones are named to match Roblox R15, positioned by
human proportions of the body's height, parents the body with automatic weights,
test-poses an arm, renders, and exports FBX (armature + skinned mesh).

Usage: python rig_r15.py <body.glb> <out_prefix>
"""

import os
import sys

import bpy
import mathutils

body_glb, prefix = sys.argv[1], sys.argv[2]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=body_glb)
body = next(o for o in bpy.data.objects if o.type == "MESH")

# Body metrics.
co = [body.matrix_world @ v.co for v in body.data.vertices]
H = max(c.z for c in co) - min(c.z for c in co)
z0 = min(c.z for c in co)


def z(frac):
    return z0 + frac * H


sh = 0.17 * H  # shoulder half-width (approx, A-pose)
hipx = 0.09 * H  # hip half-width for leg roots
V = mathutils.Vector

# R15 bones: name -> (head, tail, parent). Positions are proportional A-pose
# estimates; refined against the mesh in Studio's Avatar Importer.
B = {
    "HumanoidRootPart": (V((0, 0, z(0.52))), V((0, 0.05, z(0.52))), None),
    "LowerTorso": (V((0, 0, z(0.52))), V((0, 0, z(0.62))), "HumanoidRootPart"),
    "UpperTorso": (V((0, 0, z(0.62))), V((0, 0, z(0.82))), "LowerTorso"),
    "Head": (V((0, 0, z(0.87))), V((0, 0, z(0.97))), "UpperTorso"),
    "LeftUpperArm": (V((sh, 0, z(0.81))), V((sh * 1.3, 0, z(0.63))), "UpperTorso"),
    "LeftLowerArm": (V((sh * 1.3, 0, z(0.63))), V((sh * 1.5, 0, z(0.47))), "LeftUpperArm"),
    "LeftHand": (V((sh * 1.5, 0, z(0.47))), V((sh * 1.6, 0, z(0.40))), "LeftLowerArm"),
    "RightUpperArm": (V((-sh, 0, z(0.81))), V((-sh * 1.3, 0, z(0.63))), "UpperTorso"),
    "RightLowerArm": (V((-sh * 1.3, 0, z(0.63))), V((-sh * 1.5, 0, z(0.47))), "RightUpperArm"),
    "RightHand": (V((-sh * 1.5, 0, z(0.47))), V((-sh * 1.6, 0, z(0.40))), "RightLowerArm"),
    "LeftUpperLeg": (V((hipx, 0, z(0.52))), V((hipx, 0, z(0.28))), "LowerTorso"),
    "LeftLowerLeg": (V((hipx, 0, z(0.28))), V((hipx, 0, z(0.05))), "LeftUpperLeg"),
    "LeftFoot": (V((hipx, 0, z(0.05))), V((hipx, -0.08 * H, z(0.01))), "LeftLowerLeg"),
    "RightUpperLeg": (V((-hipx, 0, z(0.52))), V((-hipx, 0, z(0.28))), "LowerTorso"),
    "RightLowerLeg": (V((-hipx, 0, z(0.28))), V((-hipx, 0, z(0.05))), "RightUpperLeg"),
    "RightFoot": (V((-hipx, 0, z(0.05))), V((-hipx, -0.08 * H, z(0.01))), "RightLowerLeg"),
}

arm = bpy.data.armatures.new("R15")
rig = bpy.data.objects.new("R15Rig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
order = list(B.keys())
made = {}
for name in order:
    head, tail, parent = B[name]
    eb = arm.edit_bones.new(name)
    eb.head, eb.tail = head, tail
    if parent:
        eb.parent = made[parent]
        eb.use_connect = False
    made[name] = eb
bpy.ops.object.mode_set(mode="OBJECT")

# Auto-skin.
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")

# Test pose: raise the right arm ~70 deg.
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
pb = rig.pose.bones["RightUpperArm"]
pb.rotation_mode = "XYZ"
pb.rotation_euler = (0, 0, mathutils.Euler((0, -1.2, 0)).z)
rig.pose.bones["RightLowerArm"].rotation_euler = (0.5, 0, 0)
bpy.ops.object.mode_set(mode="OBJECT")

# Render the posed result.
mat = bpy.data.materials.new("Clay")
mat.use_nodes = True
mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.55, 0.55, 0.57, 1)
body.data.materials.clear()
body.data.materials.append(mat)

sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.samples = 48
sc.cycles.device = "CPU"
sc.render.resolution_x = 800
sc.render.resolution_y = 1100
sc.render.filepath = prefix + "_pose.png"
sc.view_settings.view_transform = "AgX"
if sc.world is None:
    sc.world = bpy.data.worlds.new("World")
sc.world.use_nodes = True
sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.055, 0.065, 1)
center = V((0, 0, z(0.5)))
cam_d = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_d)
sc.collection.objects.link(cam)
cam.location = center + V((1.6, -3.2, 0.2))
cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
cam_d.lens = 60
sc.camera = cam
for loc, e in [((3, -3, 4), 900), ((-4, -2, 2), 300)]:
    ld = bpy.data.lights.new("L", "AREA")
    ld.energy = e
    ld.size = 4
    o = bpy.data.objects.new("L", ld)
    sc.collection.objects.link(o)
    o.location = center + V(loc)
    o.rotation_euler = (center - o.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.render.render(write_still=True)

# Export FBX (armature + skinned mesh) for Roblox Avatar Importer.
for o in bpy.data.objects:
    o.select_set(o in (body, rig))
bpy.ops.export_scene.fbx(
    filepath=prefix + ".fbx",
    use_selection=True,
    add_leaf_bones=False,
    bake_anim=False,
    object_types={"ARMATURE", "MESH"},
)
print("RIGGED ->", prefix + "_pose.png", "and", prefix + ".fbx")
