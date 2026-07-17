# Characters — shared full-body operator base

The realistic operators (Specter / Conduit / Bulwark) are **one shared full-body
base** with gear/clothing layers, so the hitbox and proportions are identical and
one rig drives both first-person and third-person (see `docs/FIRST_PERSON_VIEWMODEL.md`).

## Base bodies (`base/`)

- `base_body_male.glb`, `base_body_female.glb` — realistic full bodies extracted
  from the **Blender Studio Human Base Meshes** bundle (**CC0**, credit Blender
  Studio). Feet at origin, metric scale (~1.80 m / ~1.64 m), density-capped to
  ~70k verts. These are the character base — pick either or support both (they
  share the rig).

## Specter (`specter/`)

- `specter_gear_blockout.glb` — **BLOCKOUT** recon gear layer (plate carrier,
  helmet + headset, shoulder/knee pads, belt), generated via codex + Blender and
  fitted to the body with a shrinkwrap technique. `preview.png` shows it on the
  male body.
- **Status: blockout, not final.** The forms read as a low-profile tactical
  operator within the silhouette, but character *gear polish* is the frontier the
  automated pipeline oscillates on (belt/strap refinement, cleaner conforming) —
  this is where an **artist pass** is needed. Hard-surface *world* assets
  (weapons, environment kit) reach much higher quality via the same pipeline.

## Next

Rig the base body as an **R15-compatible skinned character** (bone names matching
Roblox R15) so it imports via Studio's Avatar Importer and drives FP + TP +
animation. Gear layers skin to the same rig. Conduit and Bulwark are gear-layer
variants on the identical base.

## Scripts (`scripts/`)

`export_body.py` (extract + density-cap a base body), `gen_specter_gear4.py`
(shrinkwrap gear), `combine_character.py` (preview render). Run with the bpy
module; see `docs/TECHNICAL_ART_PIPELINE.md`.

## Rigging (R15)

`scripts/rig_r15.py` builds a Roblox **R15-named armature** on a base body by
human proportions, auto-skins it (Blender automatic weights), and exports FBX.
First result: clean deformation (A-pose → natural), skin weights hold at
shoulders/elbows/hips without artifacts.

- `base/base_body_male_r15.fbx` — rigged male body (armature + skinned mesh),
  ready for Studio's **Avatar Importer** (Rig type: R15). `r15_rig_test.png`
  shows the deform test.

**Next (Studio + iteration):** import via Avatar Importer, verify the R15 joint
mapping, tune weights at high-flex joints, then skin the gear layers to the same
rig and add animations. Bone positions are proportional estimates — refine to the
mesh in Studio.
