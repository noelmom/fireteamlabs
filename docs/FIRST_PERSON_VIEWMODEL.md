# First-Person Viewmodel

The first-person viewmodel is a **top priority** of the visual pivot. It replaces the procedural
blocky `ViewmodelController` with a real gloved arm rig + weapon meshes and a proper animation and
procedural-motion system. **All hit detection stays server-authoritative** — the viewmodel is
presentation; the server (`WeaponService`) decides every shot.

## Assets

- **Arms:** built on the **CC0 Blender Studio Human Base Meshes** (realistic, clean topology,
  sourced in `TECHNICAL_ART_PIPELINE.md`). Extract a right forearm+hand, glove it (hard-surface
  glove detailing via codex/Blender), rig, and skin. Arms are always gloved (matches the art
  direction and hides fine anatomy).
- **Weapons:** hard-surface meshes from codex/Blender (hero carbine done, see PoC), with a
  weapon-specific grip pose. `WeaponConfig` gains mesh + animation references alongside the
  existing stats.
- Separate LODs for viewmodel vs. world model are allowed; the viewmodel stays highest fidelity
  (last to scale by quality tier).

## System (client)

A dedicated first-person system, replacing the procedural viewmodel:

- **Rig:** arms + weapon parented to the camera; ADS alignment moves the sight to screen center.
- **Animation set:** idle breathing, walk sway, sprint (weapon lowered), landing response, fire,
  reload, empty reload, weapon inspect, equip/holster, grenade + equipment interactions.
- **Procedural layer (on top of animations):** recoil kick + recovery, camera recoil, movement/
  aim sway with lag, weapon lowering near walls. Weighted and believable — no nauseating
  over-movement; aiming stays comfortable.
- **Feedback:** muzzle flash + light, subtle muzzle smoke, shell ejection and chamber/bolt motion
  where appropriate (tier-scaled via `QualityController`).

## Authority boundary

- The client sends fire/reload/equip intent and plays all viewmodel motion locally.
- The **server** validates fire rate, ammo, origin, spread, range, and applies damage — unchanged
  from the current `WeaponService`. The viewmodel never determines hits.
- World-model animations (what other players see) are separate from the viewmodel and are also
  server-gated for state (alive, firing, reloading).

## Migration

Keep the existing `WeaponController` signal contract (`ShotFired`, `StateUpdated`, `AimChanged`,
`HitConfirmed`, `EmptyTriggered`) — the new viewmodel consumes the same signals, so the firing
pipeline and audio/HUD are untouched. Replace only the *rendering* (procedural blocks → rigged
meshes + animation state machine).

## Acceptance (viewmodel slice)

Believable gloved arms + hero weapon at correct scale; fire/reload/grenade animations read as
weighted; ADS aligns the sight; recoil/sway feel controlled; muzzle flash + shell eject present;
runs at all quality tiers with the viewmodel preserved; hit detection remains 100% server-side.
