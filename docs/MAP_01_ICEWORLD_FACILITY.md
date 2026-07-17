# Map 01 — Iceworld Facility

The first map: a realistic **Island X cold research facility** — a classified combat-testing
installation in an extreme-cold environment. It preserves the fast, symmetrical competitive
structure that makes fy_iceworld useful, but is an **original facility layout**, not a visual
remake, and reuses the existing spawn / marker / overtime **contract** from `MapService`.

## Fiction / spaces

A refrigerated weapons-testing installation. Spaces to draw from: refrigerated testing halls,
concrete service corridors, equipment storage rooms, decontamination chambers, observation
windows, loading areas, maintenance tunnels, exterior frozen courtyards, power/ventilation rooms,
experimental weapon-testing spaces.

## Competitive layout (preserve fy_iceworld's virtues)

- **Two mirrored deployment areas** (spawns) — symmetric so side rotation stays fair (reuses the
  Alpha=North / Bravo=South contract; side rotation unchanged).
- A **readable central engagement zone** — the contested heart and the **overtime capture zone**
  (`OvertimeZoneMarker`), holding the single **Heavy** pickup.
- **Two primary side routes** with the **two Special** pickups (equidistant, contested).
- **One or two controlled elevation opportunities** — high ground with counterplay, not
  oppressive.
- **Short rotation paths**, **strong cover landmarks**, predictable-but-not-overly-exposed
  sightlines.
- **Scales 1v1 → 5v5** on the same footprint.

Spawn safety, side-timing equality, and boundaries follow the existing map acceptance rules; the
current graybox (`CryoFoundry.luau`) already encodes this contract and can guide the realistic
build's metrics.

## Modular kit (first set)

Built entirely from a reusable, hard-surface kit (codex + Blender). Kit pieces:

wall panel · half-height wall · doorway + frame · blast door · floor grate · solid floor · ceiling
panel · duct segment · pipe run · cable tray · wire shelving · crate (done) · junction/electrical
panel (emissive) · fluorescent fixture · emergency light · EXIT sign · observation window (frosted
glass) · pillar/column · trim/greeble set.

Each piece: real meter scale, snapping-friendly dimensions (module grid — provisional 4-stud), a
`SurfaceAppearance` PBR material, and **simple invisible collision separate from the render mesh**.
The kit is designed for reuse across later Island X maps.

## Lighting

Authored per `ART_DIRECTION.md`: cold cyan practicals (fluorescents, indicators, EXIT signs),
cold natural light at exterior openings (the existing CC0 ice skybox shows through observation
windows / the frozen courtyard), warm sodium in select service rooms, deliberate light/dark
contrast between safe and dangerous spaces — while keeping every combat area predictably lit for
readability. Tier-scaled by `QualityController`.

## Build order (within the vertical slice)

The slice builds **one corridor + one adjoining room + one exterior/observation opening** from
this kit — not the full map. The full symmetrical layout is authored only after the slice proves
the kit, lighting, and performance. See `VERTICAL_SLICE_PLAN.md`.

## Contract preserved

`MapService` still decides *when/where* players spawn and exposes `GetOvertimeCenter` /
`SetZoneActive` / spawn markers; the realistic map is a **visual replacement** for the graybox
geometry that keeps the same marker names (`SpawnAlpha*`/`SpawnBravo*`, `SpecialAmmoSpawnA/B`,
`HeavyAmmoSpawn`, `OvertimeZoneMarker`, `KillVolume`) so the round loop is untouched.
