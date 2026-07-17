# ADR 0001: Server-Authoritative Architecture

## Status

Accepted (2026-07-17)

## Context

Fireteam Labs is a competitive shooter on Roblox, where exploiters control their own client. Any gameplay decision made on the client can be forged.

## Decision

The server owns all gameplay state and decisions: damage, ammo, pickups, ability use, round outcomes, and purchases. Clients send intent through remotes named in `src/ReplicatedStorage/Remotes/RemoteNames.luau`; the server validates rate, range, line of sight, cooldowns, and ownership before acting. Server services live in `src/ServerScriptService/Services/` and are loaded by `ServerBootstrap` with a two-phase Init/Start lifecycle.

## Consequences

- Client code is presentation and prediction only; it may never be trusted for outcomes.
- Every remote handler needs validation and rate limiting from day one — retrofitting is far costlier.
- Some responsiveness must be recovered through client prediction and server reconciliation.
