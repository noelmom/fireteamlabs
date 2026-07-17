# Technical Art Pipeline

How Fireteam Labs produces realistic 3D assets and gets them into Roblox. This pipeline is
**validated and running** (see the proof-of-concept results below), not aspirational.

## Asset-generation pipeline (proven)

```
codex (writes Blender bpy script)  →  headless Blender (bpy module) runs it here
   →  .glb / .fbx export  +  Cycles preview render  →  human review on the upload server
   →  YOU import/upload in Roblox Studio → asset id  →  wired via Rojo
```

- **Modeling** is authored by **codex** as Blender Python (`bpy`) scripts. codex has no native
  mesh generator; it writes scripts.
- **Execution + preview** runs locally via Blender as a **Python module** (`bpy`, installed in
  `scratchpad/bpyvenv`, Blender 5.0.x). Scripts render a Cycles preview and export glTF. This
  environment has **no GUI Blender** and **cannot upload to Roblox** — those are your Studio
  steps.
- **Review loop:** previews are served on the local upload server for fast approval before any
  Studio import.

### Proof-of-concept results (2026-07-17)

| Asset | Category | Result |
| --- | --- | --- |
| Industrial supply crate | hard-surface | **Game-ready.** Recessed panels, corner reinforcements, latches, handles, clean two-material PBR. |
| Near-future carbine | hard-surface | **Good blockout.** All components present, correct proportions; needs a detailing + material pass. |
| First-person gloved hand/arm | organic | **Placeholder only.** Recognizable but lumpy base mesh; not riggable/animatable at quality. |

**Conclusion — the capability boundary:**
- **Hard-surface (weapons, props, gear, the entire modular environment kit) → codex + Blender.**
  Strong, use it.
- **Organic anatomy (hands/arms/faces) → base mesh, not scripting.** We source a rigged base mesh
  and use codex/Blender only to add gloves/hard-surface detail and pose it (see Viewmodel doc).

### Known script pitfalls (pin these in prompts)

- This Blender build's render engines are only `CYCLES`, `BLENDER_EEVEE`, `BLENDER_WORKBENCH`
  (**not** `BLENDER_EEVEE_NEXT`). Use `CYCLES` for headless CPU renders.
- `scene.world` can be `None` — create it before setting the background.
- **Material assignment is inconsistent** in generated scripts (bodies sometimes render white).
  Verify base-color assignment; prefer having codex write *modeling only* and reusing a known-good
  render/export harness.
- Every generated script is **read + scanned for risky calls** (subprocess/network/file writes
  outside the output dir) before it is run.

## Sourced base assets

- **First-person hands/arms:** Blender Studio **Human Base Meshes** bundle — **CC0**, realistic,
  clean quad topology with UVs. Downloaded and confirmed loadable. This is the base we build the
  gloved viewmodel arms on.

## Roblox conventions (for Studio import)

- **Scale:** model in **meters**, 1 m ≈ 1 Roblox stud... verify against the character rig on
  import; keep a reference cube.
- **Pivot/origin:** at the natural attach point (grip for weapons, forearm cut for arms, base
  center for props). Apply transforms before export.
- **Export:** glTF (`.glb`) or `.fbx`; +Y up handled on import.
- **Materials → `SurfaceAppearance`:** author Color / Normal / Roughness / Metalness maps; use
  `MaterialVariant`/`SurfaceAppearance` on `MeshPart`. Emissive via a separate emissive map or a
  neon/emissive material only where justified.
- **Texel density:** target a single consistent standard (provisional: ~10 px/cm for hero,
  ~5 px/cm for environment); no unnecessarily large textures; share/atlas materials across the kit.
- **Collision:** **never** use render mesh as collision. Author simple invisible collision
  geometry (boxes/hulls); small props get `CanCollide=false` or box collision.
- **LODs:** hero (viewmodel/weapon) and world model may differ; environment meshes get LODs;
  `RenderFidelity` set appropriately.
- **Naming:** `SkyboxFt`-style for faces; assets `kit_<set>_<name>`, `wpn_<name>`, `vm_<name>`.

## Validation

Before an asset is accepted: renders match the art direction; scale correct; pivot correct;
tri-count within budget (`PERFORMANCE_BUDGETS.md`); collision authored separately; materials
use `SurfaceAppearance`; imported with no unknown scripts; recorded in `ASSET_MANIFEST.md`.
