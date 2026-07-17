import os
import sys

import bpy
import mathutils

SCRATCH = os.environ["SCRATCH"]
out = sys.argv[1]
glbs = sys.argv[2:]

bpy.ops.wm.read_factory_settings(use_empty=True)
for g in glbs:
    bpy.ops.import_scene.gltf(filepath=g)

meshes = [o for o in bpy.data.objects if o.type == "MESH"]
coords = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
lo = mathutils.Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
hi = mathutils.Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))
center = (lo + hi) / 2
radius = max((hi - lo).length / 2, 0.1)

sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.samples = 96
sc.cycles.use_denoising = True
sc.cycles.device = "CPU"
sc.render.resolution_x = 900
sc.render.resolution_y = 1200
sc.render.filepath = out
sc.render.image_settings.file_format = "PNG"
sc.view_settings.view_transform = "AgX"
sc.view_settings.look = "AgX - Base Contrast"

if sc.world is None:
    sc.world = bpy.data.worlds.new("World")
sc.world.use_nodes = True
sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.055, 0.065, 1)
sc.world.node_tree.nodes["Background"].inputs[1].default_value = 0.4

bpy.ops.mesh.primitive_plane_add(size=radius * 30, location=(center.x, center.y, lo.z))
gm = bpy.data.materials.new("Ground")
gm.use_nodes = True
gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.1, 0.11, 0.13, 1)
gm.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
bpy.context.active_object.data.materials.append(gm)

cam_d = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_d)
sc.collection.objects.link(cam)
cam.location = center + mathutils.Vector((radius * 1.6, -radius * 2.6, radius * 0.6))
cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
cam_d.lens = 85
sc.camera = cam


def area(loc, energy, sz):
    ld = bpy.data.lights.new("L", "AREA")
    ld.energy = energy
    ld.size = sz
    o = bpy.data.objects.new("L", ld)
    sc.collection.objects.link(o)
    o.location = center + mathutils.Vector(loc)
    o.rotation_euler = (center - o.location).to_track_quat("-Z", "Y").to_euler()


area((radius * 3, -radius * 3, radius * 4), 70 * radius * radius, radius * 3)
area((-radius * 4, -radius * 2, radius * 1.5), 22 * radius * radius, radius * 4)
area((-radius * 1.5, radius * 4, radius * 3), 34 * radius * radius, radius * 3)

bpy.ops.render.render(write_still=True)
print("rendered", out)
