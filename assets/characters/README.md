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

## Operators

- **Specter** (`specter/`) — recon / hunter. First fully-built hero. See below.
- **Conduit** (`conduit/`) — tech / support. Built via the same pipeline; full-
  face visored helmet, chest energy-core + conduits, forearm gauntlet. See
  `conduit/README.md`.
- **Bulwark** — heavy. Not yet built; same base + rig.

## Specter (`specter/`)

The Specter recon operator is a **full geared hero character** generated with
**Meshy.ai** (multi-image-to-3D) from a front/back concept sheet, then rigged to
R15.

- `specter_operator.glb` — hero mesh, **62k tris**, single skinned-ready mesh with
  **full PBR** (albedo / metal-rough / AO / normal, 4× 2048). Real human scale
  (~1.9 m). Helmet + ballistic goggles, low-profile plate carrier with mag/side
  pouches, belt rig, knee pads, gloves, cargo pants, tactical boots, and the cyan
  **team-indicator light** on the chest. This is the unrigged hero source.
- `specter_operator_r15.fbx` — the same mesh **rigged to a Roblox R15-named
  armature** with embedded textures, for Studio's **Avatar Importer** (Rig type:
  R15). `specter_operator_r15.glb` is the skinned glTF equivalent.
- `concept_front.png` / `concept_back.png` — the reference views fed to Meshy.
  `preview_detail.png` (unlit geometry) and `preview_rigged_pose.png` (arm-raise
  deform test) show the result.
- **Status: production-quality mesh, first-pass rig.** The *mesh* clears the bar
  the codex/Blender pipeline plateaued on. The *rig* uses deterministic
  nearest-bone skinning (Blender heat-weights fail on thick fused gear), so limbs
  follow the skeleton but high-flex joints (shoulders/hips) want a weight-paint
  pass in Studio/Blender. Minor Meshy artefacts remain around some straps/fingers.
- `archive/` holds the superseded codex+Blender `specter_gear_blockout.glb`.

## Next

Import `specter/specter_operator_r15.fbx` via Studio's **Avatar Importer** (Rig
type: R15), verify the joint mapping, and weight-paint the high-flex joints.
Conduit and Bulwark are the same pipeline — a new concept sheet (shared
proportions/base look, different gear/silhouette) through Meshy, rigged the same
way — so the hitbox and rig stay identical across the three operators.

## Scripts (`scripts/`)

- `meshy_gen.py` — Meshy image/multi-image-to-3D client (create → poll →
  download GLB/FBX/OBJ). Reads `MESHY_API_KEY` from the env; never prints it.
- `rig_meshy_r15.py` — rigs a Meshy geared operator to an R15-named armature with
  deterministic nearest-bone skinning + boundary smoothing, keeps PBR textures,
  verifies the pose deforms, exports textured FBX + GLB. **This is the current
  character rigging path.**
- `export_body.py` (extract + density-cap a CC0 base body), `rig_r15.py`
  (auto-weight rig for a bare base body), `combine_character.py` (preview render).

Run with the bpy module; see `docs/TECHNICAL_ART_PIPELINE.md`.

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
