"""Export a specific realistic base body from the CC0 bundle to a glb.

Usage: python export_body.py <name_substring> <output.glb>
"""

import os
import sys

import bpy
import mathutils

SCRATCH = os.environ["SCRATCH"]
BLEND = os.path.join(SCRATCH, "basemesh", "human_base_meshes_bundle.blend")
substr, out = sys.argv[1], sys.argv[2]

bpy.ops.wm.open_mainfile(filepath=BLEND)

# Exact body geo objects are named GEO-body_<sex>_realistic; match the sex+body.
candidates = [
    o
    for o in bpy.data.objects
    if o.type == "MESH" and o.name.startswith("GEO-body_") and substr in o.name and "eye" not in o.name.lower()
]
target = min(candidates, key=lambda o: len(o.name))  # the plain body, not sub-parts
print("PICKED", target.name)

for o in list(bpy.data.objects):
    if o is not target:
        bpy.data.objects.remove(o, do_unlink=True)

depsgraph = bpy.context.evaluated_depsgraph_get()
mesh = bpy.data.meshes.new_from_object(target.evaluated_get(depsgraph))
body = bpy.data.objects.new("BaseBody", mesh)
bpy.context.scene.collection.objects.link(body)
bpy.data.objects.remove(target, do_unlink=True)

bpy.context.view_layer.update()
coords = [body.matrix_world @ v.co for v in body.data.vertices]
minz = min(c.z for c in coords)
cx = sum(c.x for c in coords) / len(coords)
cy = sum(c.y for c in coords) / len(coords)
body.location -= mathutils.Vector((cx, cy, minz))
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)

# Density cap: some CC0 bodies carry high multires (~600k+ verts). Decimate to a
# game-usable count so the exported glb is a sane size.
CAP = 70000
if len(body.data.vertices) > CAP:
    dec = body.modifiers.new("Decimate", "DECIMATE")
    dec.decimate_type = "COLLAPSE"
    dec.ratio = CAP / len(body.data.vertices)
    bpy.ops.object.modifier_apply(modifier=dec.name)

mat = bpy.data.materials.new("Clay")
mat.use_nodes = True
b = mat.node_tree.nodes["Principled BSDF"]
b.inputs["Base Color"].default_value = (0.55, 0.55, 0.57, 1)
b.inputs["Roughness"].default_value = 0.65
body.data.materials.clear()
body.data.materials.append(mat)

bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True)
print(f"EXPORTED {out} height={max(c.z for c in coords) - minz:.2f}m verts={len(body.data.vertices)}")
