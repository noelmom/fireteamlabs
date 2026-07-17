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
