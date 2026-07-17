# Performance Budgets

**Provisional** budgets for the realistic vertical slice. These are starting targets to design
against, not measured limits — every number below is marked provisional until profiling on
representative hardware (part of the vertical-slice benchmark). Do not raise a budget without a
profiling reason.

Target: a smooth, input-responsive experience on a mid-range device at **Medium**, with **Low**
protecting responsiveness on weak hardware and **High** for capable machines.

## Triangle counts (provisional)

| Asset class | Budget (tris) |
| --- | --- |
| Hero weapon (viewmodel) | 20k–40k |
| First-person arms (pair) | 15k–25k |
| Character (world model, per operator) | 20k–35k |
| Environment kit piece (wall/floor/ceiling/door) | 0.3k–2k |
| Prop (crate, shelving, junction panel) | 0.5k–4k |
| Small prop (sign, fixture, cable) | <0.8k |
| On-screen environment total (typical view) | ≤ ~600k |

Prioritize materials, proportions, lighting, animation, and composition over polycount.

## Textures (provisional)

- Texel density: one consistent standard — provisional ~10 px/cm hero, ~5 px/cm environment.
- Max map size: 1024² environment, 2048² hero/weapon; **no** unnecessarily large textures.
- Share/atlas materials across the kit; reuse `SurfaceAppearance` sets; avoid per-instance maps.

## Runtime budgets (provisional, per tier)

| Budget | Low | Medium | High |
| --- | --- | --- | --- |
| Non-essential dynamic lights (concurrent) | 4 | 8 | 16 |
| Shadow-casting objects (view) | ~40 | ~120 | ~250 |
| Active particle emitters (view) | 6 | 12 | 24 |
| Live impact decals | 20 | 40 | 80 |
| Concurrent gameplay sounds | 16 | 24 | 32 |
| Networked cosmetic effects / sec | 20 | 30 | 40 |

Emissive/indicator lights that don't cast shadows are cheap and not counted against the dynamic-
light budget; shadow-casting lights are strictly limited.

## Structural rules (all tiers)

- **Collision never on render meshes** — author simple invisible collision (boxes/hulls); small
  props `CanCollide=false`.
- **Instance streaming** enabled; **mesh LODs** for environment; distance-based effects.
- **Disable shadows on small props**; limit shadow-casting lights.
- **Server-authoritative damage**; cosmetic effects are client-side and never gate gameplay.
- Controlled transparency; avoid overdraw-heavy stacked transparent parts.

## Benchmark

The vertical-slice benchmark walks the corridor + room + opening firing the hero weapon, on
High/Medium/Low, capturing frame time, draw calls, part/tri counts, active lights, and memory.
Budgets above are revised from those numbers and this doc updated with measured values.
