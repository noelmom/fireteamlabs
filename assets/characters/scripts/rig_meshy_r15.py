"""Rig the Meshy geared operator to R15 with deterministic nearest-bone skinning.

Automatic heat-weights fail on thick fused gear, so every vertex is bound to the
nearest R15 bone *segment* (rigid skin), then lightly smoothed at boundaries so
joints don't tear. Guarantees limbs follow the skeleton. Keeps PBR textures,
verifies the pose deforms, exports textured FBX + GLB.

Usage: python rig_meshy2.py <operator.glb> <out_prefix>
"""

import sys

import bpy
import mathutils

body_glb, prefix = sys.argv[1], sys.argv[2]
V = mathutils.Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=body_glb)
body = next(o for o in bpy.data.objects if o.type == "MESH")

co = [body.matrix_world @ v.co for v in body.data.vertices]
H = max(c.z for c in co) - min(c.z for c in co)
z0 = min(c.z for c in co)
cx = sum(c.x for c in co) / len(co)
cy = sum(c.y for c in co) / len(co)


def z(f):
    return z0 + f * H


sh = 0.17 * H
hipx = 0.09 * H

B = {
    "HumanoidRootPart": (V((cx, cy, z(0.52))), V((cx, cy + 0.05, z(0.52))), None),
    "LowerTorso": (V((cx, cy, z(0.48))), V((cx, cy, z(0.60))), "HumanoidRootPart"),
    "UpperTorso": (V((cx, cy, z(0.60))), V((cx, cy, z(0.82))), "LowerTorso"),
    "Head": (V((cx, cy, z(0.86))), V((cx, cy, z(0.99))), "UpperTorso"),
    "LeftUpperArm": (V((cx + sh, cy, z(0.80))), V((cx + sh * 1.35, cy, z(0.62))), "UpperTorso"),
    "LeftLowerArm": (V((cx + sh * 1.35, cy, z(0.62))), V((cx + sh * 1.55, cy, z(0.46))), "LeftUpperArm"),
    "LeftHand": (V((cx + sh * 1.55, cy, z(0.46))), V((cx + sh * 1.65, cy, z(0.38))), "LeftLowerArm"),
    "RightUpperArm": (V((cx - sh, cy, z(0.80))), V((cx - sh * 1.35, cy, z(0.62))), "UpperTorso"),
    "RightLowerArm": (V((cx - sh * 1.35, cy, z(0.62))), V((cx - sh * 1.55, cy, z(0.46))), "RightUpperArm"),
    "RightHand": (V((cx - sh * 1.55, cy, z(0.46))), V((cx - sh * 1.65, cy, z(0.38))), "RightLowerArm"),
    "LeftUpperLeg": (V((cx + hipx, cy, z(0.48))), V((cx + hipx, cy, z(0.27))), "LowerTorso"),
    "LeftLowerLeg": (V((cx + hipx, cy, z(0.27))), V((cx + hipx, cy, z(0.05))), "LeftUpperLeg"),
    "LeftFoot": (V((cx + hipx, cy, z(0.05))), V((cx + hipx, cy - 0.09 * H, z(0.01))), "LeftLowerLeg"),
    "RightUpperLeg": (V((cx - hipx, cy, z(0.48))), V((cx - hipx, cy, z(0.27))), "LowerTorso"),
    "RightLowerLeg": (V((cx - hipx, cy, z(0.27))), V((cx - hipx, cy, z(0.05))), "RightUpperLeg"),
    "RightFoot": (V((cx - hipx, cy, z(0.05))), V((cx - hipx, cy - 0.09 * H, z(0.01))), "RightLowerLeg"),
}

# Armature.
arm = bpy.data.armatures.new("R15")
rig = bpy.data.objects.new("R15Rig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
made = {}
for n in B:
    h, t, p = B[n]
    eb = arm.edit_bones.new(n)
    eb.head, eb.tail = h, t
    if p:
        eb.parent = made[p]
        eb.use_connect = False
    made[n] = eb
bpy.ops.object.mode_set(mode="OBJECT")


def dist_to_seg(pt, a, b):
    ab = b - a
    t = 0.0 if ab.length_squared == 0 else max(0.0, min(1.0, (pt - a).dot(ab) / ab.length_squared))
    return (pt - (a + ab * t)).length


segs = {n: (B[n][0], B[n][1]) for n in B}
# Skinning bones exclude the root (a positioning bone in R15, no geo of its own).
skin_names = [n for n in B if n != "HumanoidRootPart"]

# Create vertex groups.
for n in skin_names:
    body.vertex_groups.new(name=n)

# Nearest-bone rigid weights (world space; body has identity transform after import).
for v in body.data.vertices:
    p = body.matrix_world @ v.co
    best = min(skin_names, key=lambda n: dist_to_seg(p, segs[n][0], segs[n][1]))
    body.vertex_groups[best].add([v.index], 1.0, "REPLACE")

# Bind modifier.
mod = body.modifiers.new("Armature", "ARMATURE")
mod.object = rig
body.parent = rig

# Smooth the rigid seams a little so joints don't tear on bend.
bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
for _ in range(3):
    bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.5, repeat=1)
bpy.ops.object.mode_set(mode="OBJECT")

# Verify: pose the right arm and confirm the arm verts actually move.
rest = [(body.matrix_world @ v.co).copy() for v in body.data.vertices]
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
rig.pose.bones["RightUpperArm"].rotation_mode = "XYZ"
rig.pose.bones["RightUpperArm"].rotation_euler = (0, -1.0, 0)
rig.pose.bones["RightLowerArm"].rotation_mode = "XYZ"
rig.pose.bones["RightLowerArm"].rotation_euler = (0.4, 0, 0)
bpy.ops.object.mode_set(mode="OBJECT")
dg = bpy.context.evaluated_depsgraph_get()
ev = body.evaluated_get(dg)
posed = [(body.matrix_world @ v.co) for v in ev.data.vertices]
moved = sum(1 for a, b in zip(rest, posed) if (a - b).length > 0.02)
print(f"verts that moved when arm posed: {moved} / {len(rest)}")

# Render posed, with Meshy material.
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.samples = 64
sc.cycles.device = "CPU"
sc.render.resolution_x = 900
sc.render.resolution_y = 1200
sc.view_settings.view_transform = "AgX"
sc.view_settings.exposure = 1.1
if sc.world is None:
    sc.world = bpy.data.worlds.new("W")
sc.world.use_nodes = True
sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.14, 0.15, 0.17, 1)
center = V((cx, cy, z(0.55)))
cam_d = bpy.data.cameras.new("C")
cam = bpy.data.objects.new("C", cam_d)
sc.collection.objects.link(cam)
cam_d.lens = 70
cam.location = center + V((1.0, -3.4, 0.15))
cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
sc.camera = cam
R = H
for loc, e in [((2.5, -2.5, 3.5), 1400), ((-3, -1.5, 1.5), 700), ((0, 3, 2.5), 600)]:
    ld = bpy.data.lights.new("L", "AREA")
    ld.energy = e * R * R
    ld.size = 3.5
    o = bpy.data.objects.new("L", ld)
    sc.collection.objects.link(o)
    o.location = center + V(loc)
    o.rotation_euler = (center - o.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = prefix + "_rig_pose.png"
bpy.ops.render.render(write_still=True)

# Reset to rest for export.
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.select_all(action="SELECT")
bpy.ops.pose.transforms_clear()
bpy.ops.object.mode_set(mode="OBJECT")

for o in bpy.data.objects:
    o.select_set(o in (body, rig))
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.fbx(
    filepath=prefix + ".fbx",
    use_selection=True,
    add_leaf_bones=False,
    bake_anim=False,
    path_mode="COPY",
    embed_textures=True,
    object_types={"ARMATURE", "MESH"},
)
bpy.ops.export_scene.gltf(
    filepath=prefix + ".glb",
    export_format="GLB",
    use_selection=True,
    export_skins=True,
)
print("RIGGED ->", prefix + ".fbx,", prefix + ".glb,", prefix + "_rig_pose.png")
