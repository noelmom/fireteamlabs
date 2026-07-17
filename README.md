# Fireteam Labs

A competitive first-person arena shooter for Roblox: CS-style elimination rounds, small-team matches (1v1 / 3v3 / 5v5), contested special and heavy ammo, and three classes that differ only by one charged melee ability — Specter (Flechette), Conduit (Surge Bolt), and Bulwark (Kinetic Ram).

Every arena is a sector of **Island X**, the persistent world of the Labs.

The full design source of truth is [MASTERPLAN.md](MASTERPLAN.md). Current focus is **Milestone 0 — Vertical Slice** (see the Vertical Slice Amendment at the end of the masterplan): one map, casual 1v1 and 3v3, one weapon per slot, full round loop.

## Getting Started

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then from the repo root:

   ```sh
   rokit install
   ```

2. Serve the project to Roblox Studio (with the Rojo plugin installed):

   ```sh
   rojo serve
   ```

3. Validate before pushing:

   ```sh
   rojo build default.project.json --output build.rbxlx
   selene src
   stylua --check src
   ```

## Repository Layout

| Path | Purpose |
| --- | --- |
| `src/ReplicatedStorage/Shared/Config/` | All gameplay tuning values — nothing gameplay-affecting is hardcoded elsewhere |
| `src/ServerScriptService/Services/` | Server-authoritative game services (loaded by `ServerBootstrap`) |
| `src/StarterPlayer/StarterPlayerScripts/` | Client bootstrap, input, camera, HUD |
| `docs/` | ADRs, architecture, gameplay, map, and security docs |
| `earlyartwork/` | Concept art (directional mood reference only) |

## Contributing

All work is issue-driven — see [CONTRIBUTING.md](CONTRIBUTING.md). No feature merges without an issue.
