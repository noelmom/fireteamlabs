# Iceworld Facility — modular environment kit

The first modular hard-surface kit for the realistic Island X research facility
(see `docs/MAP_01_ICEWORLD_FACILITY.md`). 18 pieces across three batches, one
shared PBR material palette, 2 m module grid, real-world meter scale.

Generated with codex-authored Blender `bpy` scripts (in `scripts/`), run through
the headless bpy pipeline and previewed with `tools/blender/render_glb.py`
(see `docs/TECHNICAL_ART_PIPELINE.md`).

## Contents

| File | Pieces |
| --- | --- |
| `kit_structural.glb` | wall panel, half wall, doorway, floor slab, floor grate, ceiling panel, pillar |
| `kit_utility.glb` | duct, pipe run, cable tray, junction panel (emissive), fluorescent, emergency light, EXIT sign, greeble trim |
| `kit_special.glb` | blast door (hazard/emissive), wire shelving, frosted observation window |

`previews/*.png` are reference render sheets.

## Status

Blockout+ quality — correct forms, consistent style, working PBR + emissive
materials. A **texture pass** (`SurfaceAppearance` color/normal/roughness/metal
maps) is still to come, like the hero weapon.

## Regenerate

```sh
SCRATCH=<scratch> bpyvenv/bin/python scripts/gen_kit_<batch>.py     # models + exports glb
bpyvenv/bin/python tools/blender/render_glb.py kit_<batch>.glb out.png 1280   # preview
```

## Studio import (yours)

Import each `.glb` (Studio → 3D Importer / Asset Manager). Verify scale against
the character rig (kit is metric; ~3 m ceilings). Apply `SurfaceAppearance`
materials. **Author simple invisible collision separate from the render meshes**
(never collide on the render mesh). Record uploaded asset ids in
`ASSET_MANIFEST.md`.
