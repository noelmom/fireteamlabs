"""Reusable studio preview renderer for a glTF asset.

Usage: python render_glb.py <input.glb> <output.png> [size]

Imports the mesh, frames it, lights it with a controlled 3-point studio rig and
neutral exposure (so dark materials read as dark, not blown white), and renders
a Cycles preview. Keeps render quality independent of the modeling script.
"""

import sys

import bpy
import mathutils

glb, out = sys.argv[1], sys.argv[2]
size = int(sys.argv[3]) if len(sys.argv) > 3 else 1024

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)

meshes = [o for o in bpy.data.objects if o.type == "MESH"]
coords = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
lo = mathutils.Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
hi = mathutils.Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))
center = (lo + hi) / 2
radius = max((hi - lo).length / 2, 0.1)

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 72
scene.cycles.use_denoising = True
scene.cycles.device = "CPU"
scene.render.resolution_x = size
scene.render.resolution_y = size
scene.render.filepath = out
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Base Contrast"
scene.view_settings.exposure = 0.0

# Neutral studio world.
if scene.world is None:
    scene.world = bpy.data.worlds.new("World")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.045, 0.05, 0.06, 1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.4

# Soft ground catcher.
bpy.ops.mesh.primitive_plane_add(size=radius * 20, location=(center.x, center.y, lo.z))
ground = bpy.context.active_object
gm = bpy.data.materials.new("Ground")
gm.use_nodes = True
gb = gm.node_tree.nodes["Principled BSDF"]
gb.inputs["Base Color"].default_value = (0.12, 0.13, 0.15, 1)
gb.inputs["Roughness"].default_value = 0.85
ground.data.materials.append(gm)

# 3/4 camera.
cam_d = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_d)
scene.collection.objects.link(cam)
cam.location = center + mathutils.Vector((radius * 2.1, -radius * 2.4, radius * 1.5))
cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
cam_d.lens = 70
scene.camera = cam


def area(name, loc, energy, sz):
    ld = bpy.data.lights.new(name, "AREA")
    ld.energy = energy
    ld.size = sz
    o = bpy.data.objects.new(name, ld)
    scene.collection.objects.link(o)
    o.location = center + mathutils.Vector(loc)
    o.rotation_euler = (center - o.location).to_track_quat("-Z", "Y").to_euler()


# Key / fill / rim, scaled to the asset so exposure is stable across sizes.
area("Key", (radius * 3, -radius * 3, radius * 4), 60 * radius * radius, radius * 3)
area("Fill", (-radius * 4, -radius * 2, radius * 1.5), 18 * radius * radius, radius * 4)
area("Rim", (-radius * 1.5, radius * 4, radius * 3), 30 * radius * radius, radius * 3)

bpy.ops.render.render(write_still=True)
print("rendered", out)
