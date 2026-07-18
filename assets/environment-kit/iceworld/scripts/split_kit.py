import bpy, os, sys, mathutils
KIT="/Users/noelmomelo/Projects/fireteamlabs/assets/environment-kit/iceworld/kit_structural.glb"
OUT="kit_pieces"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=KIT)
meshes=[o for o in bpy.data.objects if o.type=="MESH"]
for o in meshes:
    # isolate: hide all others by unlinking later; here select just o
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active=o
    # center at origin: XY centered, base at Z=0 (so placement by base is easy)
    o.location=(0,0,0)
    bpy.context.view_layer.update()
    verts=[o.matrix_world@v.co for v in o.data.vertices]
    cx=sum(v.x for v in verts)/len(verts); cy=sum(v.y for v in verts)/len(verts)
    minz=min(v.z for v in verts)
    o.location-=mathutils.Vector((cx,cy,minz))
    bpy.context.view_layer.update()
    out=os.path.join(OUT, o.name+".fbx")
    bpy.ops.export_scene.fbx(filepath=out, use_selection=True, add_leaf_bones=False,
        bake_anim=False, path_mode="COPY", embed_textures=True)
    d=o.dimensions
    print(f"EXPORT {o.name} dims_m=({d.x:.2f},{d.y:.2f},{d.z:.2f})")
