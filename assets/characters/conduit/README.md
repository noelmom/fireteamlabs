# Conduit — tech / support operator

The Conduit is the second of three operators, built on the **same full-body base
and R15 rig** as [Specter](../specter/README.md) so the hitbox and proportions
are identical — only the silhouette and kit differ. Generated with **Meshy.ai**
(multi-image-to-3D) from a front/back concept sheet, then rigged to R15.

- `conduit_operator.glb` — hero mesh, **62.5k tris**, single skinned-ready mesh
  with **full PBR** (albedo / metal-rough / AO / normal, 4× 2048), ~1.9 m. Full-
  face helmet with wraparound cyan visor, slim tech-harness with a chest
  **energy-core** and exposed conduit lines, forearm tech gauntlet, thigh pouch,
  articulated knee pads, gloves, cargo pants, tactical boots. Cyan
  **team-indicator** core on the chest. Unrigged hero source.
- `conduit_operator_r15.fbx` — rigged to a Roblox **R15-named armature** with
  embedded textures, for Studio's **Avatar Importer** (Rig type: R15).
  `conduit_operator_r15.glb` is the skinned glTF equivalent.
- `concept_front.png` / `concept_back.png` — Meshy input views.
  `preview_detail.png` (unlit geometry) and `preview_rigged_pose.png` (arm-raise
  deform test) show the result.

## Class read vs Specter

Full-face visored helmet (vs open helmet + goggles), tech-harness with glowing
core + conduits (vs plate carrier + mag pouches), forearm gauntlet, lighter kit —
so the two classes are distinguishable at a glance while sharing the faction look.

## Status / caveats

Production-quality mesh, first-pass rig (deterministic nearest-bone skinning;
heat-weights fail on thick fused gear). Limbs follow the skeleton; high-flex
joints want a Studio/Blender weight pass. Meshy gave the suit a **lighter grey
tone** than Specter's near-black — darken the albedo if a matched tactical black
is wanted. Minor strap-edge artefacts remain (cosmetic).

## Pipeline

Same as Specter: `../scripts/meshy_gen.py` (concept → 3D) then
`../scripts/rig_meshy_r15.py` (R15 rig). See `docs/TECHNICAL_ART_PIPELINE.md`.
Bulwark (the heavy) is the third and final operator on this base.
