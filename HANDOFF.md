# Fireteam Labs — Handoff

_Last updated: 2026-07-18_

This is a running snapshot for whoever (person or agent) picks up the project next. `MASTERPLAN.md` is the design source of truth; this doc is the "where things actually stand" companion.

## What this is

A first-person competitive arena shooter for Roblox (Luau + Rojo): CS-style elimination rounds, small teams (1v1 / 3v3 / 5v5), three classes differing only by a charged melee ability. Every arena is a sector of the persistent world **Island X**. Battle royale is explicitly far-future, not current scope.

Current focus is **Milestone 0 / the vertical slice**: one map (Cryo Foundry), casual 1v1 + 3v3, one weapon per slot + knife, movement, gunplay, the full round loop, and the three class abilities. See the Vertical Slice Amendment at the end of `MASTERPLAN.md`.

## Current state (branch `develop`)

The vertical slice is playable end-to-end: with 2+ players a 1v1/3v3 match auto-starts — scored rounds (ALPHA/BRAVO scoreboard), round timer, pre-round class select (locks when the round begins), overtime zone contest on timeout, side rotation, and free-roam respawn while waiting. Verified live in a 2-player Server & Clients session on 2026-07-18. Players spawn as their class's operator rig (Meshy-generated, Avatar-Auto-Setup-rigged R15 characters), the map is clad with the structural kit + engine PBR materials, the ice skybox and cryo atmosphere are wired, and the suspended reactor centerpiece lights the overtime pit.

### Done and merged
- **Repo scaffold** — Rojo project, rokit toolchain (rojo/selene/stylua/lune), CI, issue/PR templates, docs, ADR 0001. (#1)
- **#5** Health + shield — server-authoritative shield-before-health damage, multipliers, regen, elimination.
- **#6** Input abstraction + movement — sprint/crouch/walk, sprint FOV, server speed validation.
- **#7** Weapon framework + Auto Rifle — server-validated firing (fire rate, ammo, spread, falloff, precision), reload.
- **#11** Cryo Foundry graybox + MapService — mirrored graybox, team spawns, kill volume.
- **#18** First-person camera lock (bug: third-person shots were being rejected).
- **#20** Procedural first-person viewmodel — poses, recoil, muzzle flash, sway.
- **#22 / #23** Placeholder combat audio + auto-reload on empty.

### Backlog (open issues)
| # | Milestone | Item |
|---|---|---|
| 25 | M1 | Fire-while-sprinting: cut sprint, level weapon, then fire |

Everything else in the old backlog (#2, #3, #4, #8, #9, #10, #12, #26) shipped and closed — the round loop, teams, overtime, HUD, weapons, knife, and all three class abilities are live.

**Recommended next:** the kit texture pass (bake real PBR maps for the environment kit in Blender and re-upload — the kit currently uses engine materials over untextured geometry), a graphics-tier re-tune against Voxel lighting (Roblox sunset Compatibility lighting and auto-migrated the place), and #25 whenever.

## How to work on it

### Build / validate (local)
```sh
export PATH="$HOME/.rokit/bin:$PATH"   # rokit tools aren't on PATH by default in this shell
rojo build default.project.json --output /tmp/build.rbxlx   # structure check
lune run tests/run.luau                # unit tests (pure-logic modules)
selene src                             # lint
stylua --check src tests               # format check
```
CI (`.github/workflows/ci.yml`) runs exactly these on every PR.

### Playtest
`rojo serve`, connect from Studio with the Rojo plugin, then **Test → Clients and Servers → 2 players → Start**. The two clients land on opposite teams on opposite sides of Cryo Foundry. Controls: WASD, Shift sprint, Ctrl crouch, LMB fire, RMB ADS, R reload. Restart `rojo serve` (not just resync) after editing `default.project.json`.

### Workflow (from MASTERPLAN.md §7, and it's been followed strictly)
1. Every change gets a GitHub issue with scope + acceptance criteria.
2. Branch off `develop`: `feature/<#>-slug`, `bugfix/<#>-slug`, `content/<#>-slug`, etc.
3. Commit convention: `type(scope): summary (#issue)`.
4. Open a PR to `develop`; CI must pass; squash-merge; close the issue referencing the commit.
5. Commits co-authored `Claude Fable 5 <noreply@anthropic.com>` (adjust to whoever/whatever is working).

**Merge gotcha (learned the hard way):** don't stack PRs. When a stacked base branch is squash-merged and deleted, GitHub auto-closes the child PR and its history conflicts. Branch each issue directly off the latest `develop` and merge sequentially. If you must recover a closed-by-base-deletion PR, recreate it fresh (can't reopen + retarget a closed PR whose base is gone).

## Architecture cheat-sheet

- **Server-authoritative** (ADR 0001): clients send intent via remotes; the server validates rate, range, origin, ownership, and decides outcomes. Never trust the client for gameplay.
- **Server services** — `src/ServerScriptService/Services/*.luau`, loaded by `ServerBootstrap` with a two-phase `Init()` then `Start()` lifecycle. Current: `PlayerStateService` (the single damage entry point — never touch `Humanoid.Health` elsewhere), `WeaponService`, `MovementValidationService`, `MapService`.
- **Client controllers** — `src/StarterPlayer/StarterPlayerScripts/Controllers/*.luau`, same Init/Start lifecycle via `ClientBootstrap`. `InputController` is the ONLY module allowed to touch `UserInputService` (everything binds named actions). Others: `MovementController`, `CameraController` (single owner of FOV; ADS beats sprint), `WeaponController`, `ViewmodelController`, `WeaponAudioController`.
- **Config-driven** — all tuning lives in `src/ReplicatedStorage/Shared/Config/` (`GameConfig`, `CombatConfig`, `WeaponConfig`, `ClassConfig`, `AmmoConfig`, `GrenadeConfig`, `AudioConfig`). Gameplay values are never hardcoded elsewhere; balance changes are one-line edits here.
- **Pure logic in `Shared/Utility`** — `DamageMath`, `WeaponMath` have no Roblox APIs so they run under lune in CI. Put new testable rules here.
- **Remotes** — names centralized in `src/ReplicatedStorage/Remotes/RemoteNames.luau`; created by the server, waited on by clients via `RemoteUtil`.

## Known limitations / deferred
- **No round system** — biggest gap; that's all of M2.
- **Placeholder audio** — engine-shipped `rbxasset://` sounds only (retro-sounding), swappable in `AudioConfig`. No marketplace assets are used anywhere yet; record any in `ASSET_MANIFEST.md`.
- **No character arms / weapon meshes** — viewmodel is procedural blocks; no keyframe reload/equip animations.
- **Team assignment is a join-order stopgap** in `MapService` (`TODO(#3)`), to be replaced by real assignment in #3/#2.
- **ADS state is client-claimed** and only affects spread; acceptable for the slice.
- Classes, extra weapons, ammo pickups, grenades, ranked, cosmetics, seasons — all later milestones (see `ROADMAP.md`).

## Class identity (locked)
Specter — Flechette (charged throwing blade), Conduit — Surge Bolt (charged plasma bolt), Bulwark — Kinetic Ram (charged forward slam). The old Hunter/Warlock/Titan names are retired and must not reappear.
