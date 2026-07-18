# Bulwark — heavy assault operator

The Bulwark is the third and final operator, built on the **same full-body base
and R15 rig** as [Specter](../specter/README.md) and [Conduit](../conduit/README.md)
— identical hitbox and proportions, the bulk comes from **armor, not a larger
body**. Generated with **Meshy.ai** (multi-image-to-3D) from a front/back concept
sheet, then rigged to R15.

- `bulwark_operator.glb` — hero mesh, **62.3k tris**, single skinned-ready mesh
  with **full PBR** (albedo / metal-rough / AO / normal, 4× 2048), ~1.9 m. Full
  hard-shell composite plating, layered pauldrons, reinforced breastplate,
  armored gauntlets, thigh plates + reinforced shin/knee guards, fully-enclosed
  ballistic helmet with a narrow visor slit. Cyan **team-indicator** light on the
  chest plate. Unrigged hero source.
- `bulwark_operator_r15.fbx` — rigged to a Roblox **R15-named armature** with
  embedded textures, for Studio's **Avatar Importer** (Rig type: R15).
  `bulwark_operator_r15.glb` is the skinned glTF equivalent.
- `concept_front.png` / `concept_back.png` — Meshy input views (chosen concept:
  "Option A", the cleaner trooper-heavy silhouette).
  `preview_detail.png` / `preview_rigged_pose.png` show the result.
- `archive/concept_optionB_alt.png` — the rejected "Option B" hard-shell/tank
  alternate, kept for reference.

## Class read

Heaviest silhouette of the three — full plate + pauldrons vs Specter's plate
carrier and Conduit's tech-harness. Enclosed visor-slit helmet vs open/visored.
Same faction language (matte gunmetal, cyan team light) and shared rig.

## Status / caveats

Production-quality mesh, first-pass rig (deterministic nearest-bone skinning;
heat-weights fail on thick fused gear). Limbs follow the skeleton; high-flex
joints want a Studio/Blender weight pass. Meshy gave the armor a **lighter grey
tone** than intended near-black — darken the albedo if a matched tactical black
is wanted. Minor plate-edge artefacts remain (cosmetic).

## Pipeline

Same as the others: `../scripts/meshy_gen.py` then `../scripts/rig_meshy_r15.py`.
See `docs/TECHNICAL_ART_PIPELINE.md`. With Bulwark, all three operators are built.
