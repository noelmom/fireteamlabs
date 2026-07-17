# Visual Vertical-Slice Plan

The pivot to realism is proven out by **one production-quality vertical slice** before any mass
asset production. This slice sets the visual + performance bar for the whole project. **Do not
expand the map or mass-produce assets until this slice hits its acceptance criteria and is
approved.**

## Scope (one slice)

A short, fully-finished play space:

- One **30–50-stud combat corridor** + one adjoining **combat room** + one **exterior/observation
  opening** (uses the existing CC0 ice skybox).
- One **complete modular environment kit** (the pieces those two spaces are built from).
- One **complete hero weapon** (mesh + `SurfaceAppearance` materials + it fires through the
  existing server-authoritative `WeaponService`).
- One **first-person arm rig** (gloved, from the CC0 base mesh) with **fire**, **reload**, and one
  **grenade interaction** animation.
- Several **surface-specific impact effects** (concrete dust, metal spark, glass).
- **Final-quality lighting** and **audio** for the space.
- **High / Medium / Low** graphics configurations that all run.
- A **performance benchmark** on representative hardware.

Everything is server-authoritative for gameplay; visuals are client-side.

## What we already have (reuse, do not rebuild)

All gameplay systems from M0–M3 are preserved: round loop, teams, damage, weapons firing
validation, abilities, movement, HUD, the map spawn/marker/overtime contract, and the CC0 ice
skybox. The slice is a **visual layer over working systems.**

## Modular environment kit (first set — "Iceworld Facility")

Wall panel, half-height wall, doorway/frame, floor grate, ceiling panel, duct segment, pipe run,
cable tray, wire shelving, crate (done — PoC), junction/electrical panel (emissive), fluorescent
fixture, EXIT sign, observation window (frosted glass), blast door. All hard-surface → codex +
Blender. See `MAP_01_ICEWORLD_FACILITY.md`.

## Phased plan

1. **Docs + architecture** (this set of docs; quality-tier + viewmodel code systems — buildable
   now without art).
2. **Hero weapon** — refine the PoC carbine (materials, detailing) → final mesh + `SurfaceAppearance`;
   wire to `WeaponService`.
3. **Modular kit** — generate the ~15 pieces above; build the corridor + room + opening.
4. **Viewmodel** — gloved arm rig from CC0 base; fire/reload/grenade animations; procedural
   recoil/sway.
5. **Lighting + effects + audio** — authored Future lighting; impact VFX; weapon + ambience audio.
6. **Quality tiers + benchmark** — wire High/Med/Low; profile; tune to budgets.

## Dependencies

- Weapon fire animation depends on the arm rig existing.
- Impact VFX depends on surface material tagging in the kit.
- Quality tiers depend on the lighting rig + effects being tier-aware from the start.
- Studio **asset uploads (yours)** gate every mesh/texture reaching the running game.

## Risks

- **Organic arm quality** — mitigated by the CC0 base mesh; rig/animation is still real work.
- **Roblox fidelity ceiling** — dynamic-light limits, no custom post; target "authored + cohesive,"
  not literal AAA parity.
- **Asset-upload bottleneck** — every asset needs your Studio import; batch these.
- **Performance** — realism must hold Med/Low tiers; enforce budgets early, profile continuously.
- **Scope creep** — the slice is small on purpose; resist expanding it.

## Acceptance criteria

The slice is done when:
- A screenshot does not immediately read as a conventional Roblox experience.
- Weapon + arms have believable scale and materials.
- The environment reads as physically constructed; lighting is authored, not default.
- Effects + audio give the weapon weight.
- Players remain clearly visible in combat; the space reads at competitive speed.
- High approaches modern-tactical-FPS polish; **Medium and Low remain playable** and responsive.
- All assets are original (except the CC0 base mesh, credited) and pass the pipeline validation.
- The benchmark meets `PERFORMANCE_BUDGETS.md` targets on representative hardware.

## Recommended first task

Refine and finalize the **hero weapon** (PoC carbine → materials + detailing pass) in parallel
with building the **quality-tier manager** (pure client code, fully testable here). Both are
unblocked and set the bar the rest of the slice measures against.
