# FIRETEAM LABS — MASTER PROJECT PLAN

## One-Shot Build and Development Prompt

You are the lead Roblox gameplay engineer, FPS systems designer, networking engineer, UI/UX designer, technical artist, environment artist, DevOps engineer, monetization engineer, security engineer, QA lead, and technical producer for a competitive Roblox arena shooter currently titled **Fireteam Labs**.

Build Fireteam Labs as a complete, playable, Rojo-compatible Roblox project using:

* Roblox Studio.
* Luau.
* Rojo.
* GitHub.
* GitHub Issues.
* Pull requests.
* Automated validation.
* Modular, server-authoritative architecture.

The entire project must be planned, implemented, tested, balanced, and documented through **GitHub Issues and pull requests**.

Do not return only a design document, issue list, roadmap, pseudocode, or collection of incomplete scripts. Create the actual project structure, GitHub workflow files, issues, milestones, source code, UI, maps, tests, documentation, and playable vertical slice.

Do not pause for approval between development phases. Resolve reasonable ambiguities independently and expose important gameplay values through configuration modules.

---

# 1. Project Identity

## Working Title

**Fireteam Labs**

This is the working public and repository-facing title until a future branding issue changes it.

Recommended repository name:

```text
fireteamlabs
```

Recommended Roblox experience name:

```text
Fireteam Labs
```

The word “Labs” should influence the product presentation:

* Experimental combat arenas.
* Simulated battle environments.
* Weapon testing chambers.
* Competitive combat trials.
* Holographic map selection.
* Sci-fi research-facility presentation.
* Seasonal “Lab Experiments” for testing temporary modes and balance changes.

The title does not mean the game should feel unfinished. The visual identity should communicate a polished, secretive, high-tech combat program.

---

# 2. Core Product Vision

Fireteam Labs is a first-person competitive arena shooter combining:

* Fast, responsive, weighty sci-fi FPS movement.
* Precise first-person gunplay.
* Counter-Strike-style elimination rounds.
* Small-team competitive matches.
* Contested special and heavy ammunition.
* Persistent ammunition rewards for surviving a round.
* Character classes with one distinct charged melee ability.
* No super or ultimate abilities.
* Cosmetic-first monetization.
* Strong social expression through emotes and visual communication.

Supported team sizes:

* 1v1.
* 3v3.
* 5v5.

Supported playlists:

* Casual 1v1.
* Casual 3v3.
* Casual 5v5.
* Ranked 1v1.
* Ranked 3v3.
* Ranked 5v5.
* Custom matches.
* Private testing matches.

The intended feel is:

* Easy to understand.
* Difficult to master.
* Fast without becoming chaotic.
* Competitive without becoming overly tactical or slow.
* Visually premium while remaining readable.
* Familiar to experienced FPS players while still feeling original.

---

# 3. Intellectual Property and Originality Requirements

Fireteam Labs may take inspiration from the pace, combat rhythm, movement responsiveness, and arena design principles of established shooters.

However, the final project must use:

* Original branding.
* Original names.
* Original UI.
* Original weapon models.
* Original sounds or properly licensed sounds.
* Original map art.
* Original environmental assets.
* Original armor designs.
* Original class presentation.
* Original animations.
* Original icons.
* Original visual effects.

Do not copy or extract:

* Commercial game assets.
* Proprietary map files.
* Weapon models.
* Character models.
* Logos.
* UI layouts.
* Sound effects.
* Animations.
* Textures.
* Voice lines.

## fy_iceworld Reference

The first map is intended to be a modern Roblox sci-fi reimagining of the classic combat rhythm associated with **fy_iceworld**.

Treat fy_iceworld as gameplay and layout inspiration only.

Do not:

* Import the original map.
* Extract its geometry.
* Copy textures or branded assets.
* Recreate every measurement exactly.
* Present the map as an official Counter-Strike map.

Instead, create a clean-room, original reimagining that retains the high-level qualities the project values:

* Compact symmetrical combat.
* Immediate engagement.
* Clear left, center, and right routes.
* Strong visibility.
* Simple navigation.
* Short rotation times.
* Central conflict.
* Minimal hiding locations.
* High replayability.

The working name for the Fireteam Labs version is:

**Cryo Foundry**

Internal documentation may describe it as:

```text
Cryo Foundry — Iceworld-inspired arena
```

The public-facing map name must remain original.

---

# 4. Repository Artwork and Visual Direction

The repository root will contain:

```text
masterplan.md
earlyartwork/
```

The `earlyartwork` directory will contain early renders, sketches, moodboards, map concepts, character concepts, weapons, cosmetics, and world images supplied by the project owner.

Example repository structure:

```text
fireteam-labs/
├── masterplan.md
├── earlyartwork/
│   ├── map-concepts/
│   ├── world-concepts/
│   ├── character-concepts/
│   ├── weapon-concepts/
│   ├── cosmetic-concepts/
│   └── miscellaneous/
├── docs/
├── src/
├── tests/
└── .github/
```

The artwork folders may initially contain unorganized image files. Do not require the owner to manually reorganize them before development begins.

## 4.1 Required Artwork Review Process

Before finalizing the game’s visual architecture:

1. Inspect every supported image in `earlyartwork/`.
2. Record each filename.
3. Identify what each image is useful for:

   * World direction.
   * Map direction.
   * Lighting.
   * Materials.
   * Character silhouettes.
   * Armor.
   * Weapons.
   * Cosmetics.
   * UI.
   * Emotes.
4. Identify elements that are not appropriate for the actual game.
5. Separate achievable Roblox targets from purely cinematic concept art.
6. Create an art-direction summary.
7. Link artwork-related implementation issues to the relevant reference images.

Create:

```text
docs/art-direction/ART_DIRECTION.md
docs/art-direction/EARLY_ARTWORK_INDEX.md
docs/art-direction/ROBLOX_VISUAL_TARGETS.md
```

## 4.2 Artwork Handling Rules

The files in `earlyartwork/` are inspiration and direction—not automatic production assets.

Do not assume that an image:

* Is properly licensed for direct use.
* Represents final gameplay.
* Represents final map scale.
* Represents final character proportions.
* Is technically achievable at full fidelity.
* Should be reproduced literally.

Do not modify, overwrite, rename, move, or delete original artwork unless a dedicated GitHub Issue explicitly authorizes it.

Derived notes, paintovers, diagrams, annotations, and optimized copies must be stored outside the original folder.

Recommended derived-art directory:

```text
docs/art-direction/derived/
```

## 4.3 Artwork Source-of-Truth Rules

When the artwork conflicts with this master plan:

1. Gameplay requirements in `masterplan.md` take priority.
2. Competitive visibility takes priority.
3. Performance takes priority.
4. Originality and licensing take priority.
5. The artwork remains directional inspiration.

When artwork presents multiple visual options, document the selected direction in an Architecture Decision Record or art-direction decision document.

Every production asset inspired by early artwork must have:

* A related GitHub Issue.
* A source or inspiration reference.
* A licensing status.
* A performance budget.
* A first-person and third-person visibility review where applicable.

---

# 5. Island X — The World of Fireteam Labs

The game takes place on a world currently called:

# **Island X**

Island X is the narrative and visual wrapper connecting all Fireteam Labs arenas.

It is not initially an open-world game or battle royale.

Instead, Island X is a large world divided into distinct regions. Each region contains one or more compact competitive arenas.

The island artwork should be used for:

* World-building.
* Main-menu presentation.
* Map selection.
* Matchmaking visualization.
* Seasonal content.
* Narrative progression.
* Environmental identity.
* Future map planning.
* Cosmetic collections.
* Limited-time events.

## 5.1 Island X Presentation

The main lobby or map-selection experience should include a stylized holographic or tactical view of Island X.

Players should see:

* Named regions.
* Available arenas.
* Locked or future locations.
* Current playlists.
* Featured map.
* Rotating experiments.
* Seasonal activity.
* Matchmaking status.

Selecting a region should reveal:

* Arena name.
* Arena preview.
* Recommended player count.
* Available playlists.
* Region description.
* Environmental conditions.
* Relevant cosmetic collections.
* Match history or personal performance where appropriate.

Island X should make the game feel larger than a collection of disconnected arenas while allowing each actual match to remain small, optimized, and competitive.

## 5.2 Initial Island X Regions

Use the early artwork to confirm final names, but begin with these working regions:

### Frostbite Peaks

Environment:

* Frozen mountains.
* Ice.
* Snow.
* Cryogenic facilities.
* Dark industrial structures.
* Blue-white lighting.

Initial arena:

* **Cryo Foundry**

### Neon City

Environment:

* Dense futuristic city.
* Night setting.
* Neon signage.
* Rain.
* Rooftops.
* Interior combat spaces.

Potential arena:

* **Neon Divide**

### Stormwall Dam

Environment:

* Massive hydroelectric structure.
* Water channels.
* Concrete.
* Turbines.
* Maintenance corridors.
* Exterior bridges.

Potential arena:

* **Overflow**

### Crashed Satellite

Environment:

* Destroyed orbital technology.
* Desert or frozen impact zone.
* Broken energy cores.
* Uneven sci-fi structures.
* Long and short sightline combinations.

Potential arena:

* **Impact Site**

### Tidal Port

Environment:

* Futuristic shipping terminal.
* Water.
* Cargo platforms.
* Industrial cranes.
* Containers.
* Interior and exterior routes.

Potential arena:

* **Blackwater Terminal**

Additional future regions may include:

* Echo Valley.
* Sandstrike Wastes.
* Sunken Ruins.
* Crimson City.
* Outlaw Oasis.

These are working names and must remain configurable through content data.

---

# 6. Public Beta Map Requirements

Fireteam Labs must not enter public beta with only one map.

## Minimum Requirement

A public beta requires at least:

* **Three complete, tested, production-ready maps.**

## Target Requirement

The preferred public beta target is:

* **Five complete maps.**

## Public Beta Map Plan

### Map 1 — Cryo Foundry

Region:

* Frostbite Peaks.

Purpose:

* First vertical-slice map.
* Compact symmetrical combat.
* Inspired by the high-level combat rhythm of fy_iceworld.
* Primary map for early movement, weapon, ammo, and visibility testing.

### Map 2 — Neon Divide

Region:

* Neon City.

Purpose:

* Close-to-medium urban combat.
* Strong vertical-looking presentation without unsafe competitive verticality.
* Interior and exterior lanes.
* Rain and neon lighting optimized for visibility.

### Map 3 — Overflow

Region:

* Stormwall Dam.

Purpose:

* Medium-range lane control.
* Central objective pressure.
* Water and industrial environment.
* Distinct audio and surface materials.

These three maps are mandatory before public beta.

### Map 4 — Impact Site

Region:

* Crashed Satellite.

Purpose:

* Asymmetrical-looking but competitively balanced geometry.
* Broken technology.
* One long-range route.
* Strong central wreckage.

### Map 5 — Blackwater Terminal

Region:

* Tidal Port.

Purpose:

* Cargo and port combat.
* Multiple rotation routes.
* Strong close-range spaces.
* Outdoor central heavy-ammo contest.

Maps four and five are the preferred public-beta stretch target.

## 6.1 Shared Map Requirements

Every public-beta map must support:

* 1v1.
* 3v3.
* 5v5.
* Casual.
* Ranked.
* Custom matches.
* Spectating.
* Overtime capture.
* Special-ammo pickups.
* Heavy-ammo pickup.
* Symmetrical or competitively equivalent spawns.
* Spawn safety.
* Clear navigation.
* Accessible traversal.
* Strong player visibility.
* Competitive low-effects mode.

Every map needs:

* A gameplay graybox issue.
* A sightline review issue.
* A spawn review issue.
* An ammo-placement issue.
* An optimization issue.
* An art-pass epic.
* An audio-pass issue.
* A lighting issue.
* A QA test-plan issue.
* A final competitive-readiness review.

## 6.2 Map Acceptance Criteria

A map is not production-ready until:

* Players cannot see directly into the opposing spawn at round start.
* Spawn positions support five players without collision.
* Both teams have competitively equivalent route timing.
* Players cannot escape intended boundaries.
* No location allows indefinite hiding.
* Ammo pickups are contestable.
* Heavy ammo is placed in a high-risk area.
* Special ammo does not unfairly favor one team.
* All routes have identifiable visual landmarks.
* Footstep materials are correctly configured.
* Lighting does not hide character silhouettes.
* Cosmetic wings and capes do not obstruct navigation.
* The map performs within the established frame and memory budgets.
* It passes multiplayer testing in all supported team sizes.
* Ranked playtesting does not reveal a consistent spawn-side advantage.

---

# 7. Mandatory GitHub Issue-Driven Development

All development must be performed through GitHub Issues, branches, commits, tests, and pull requests.

GitHub Issues are the source of truth.

This applies to:

* Gameplay.
* Maps.
* Weapons.
* Character classes.
* Cosmetics.
* UI.
* Audio.
* Infrastructure.
* Documentation.
* Balancing.
* Bugs.
* Security.
* Performance.
* Analytics.
* Monetization.
* Art.
* Narrative.
* Technical debt.

No undocumented development should be merged into `main` or `develop`.

## 7.1 Required Workflow

For every unit of work:

1. Create or select a GitHub Issue.
2. Define the scope.
3. Define what is out of scope.
4. Add acceptance criteria.
5. Identify dependencies.
6. Assign labels.
7. Assign a milestone.
8. Add it to the project board.
9. Create a dedicated branch.
10. Implement the scoped work.
11. Add or update tests.
12. Update documentation.
13. Open a pull request referencing the issue.
14. Run validation.
15. Review acceptance criteria.
16. Merge after approval.
17. Automatically close the issue where appropriate.

No feature should be merged without an issue.

No issue should close without:

* Implementation evidence.
* Test evidence.
* Documentation evidence.
* A documented reason when no implementation is required.

## 7.2 Branch Strategy

Use:

```text
main
develop
feature/<issue-number>-short-description
bugfix/<issue-number>-short-description
security/<issue-number>-short-description
balance/<issue-number>-short-description
content/<issue-number>-short-description
art/<issue-number>-short-description
docs/<issue-number>-short-description
release/<version>
```

Examples:

```text
feature/42-specter-flechette
content/76-cryo-foundry-graybox
art/81-cryo-foundry-ice-materials
feature/104-cosmetic-inventory
balance/151-shotgun-falloff
security/182-fire-rate-validation
```

## 7.3 Commit Convention

Use narrow, issue-linked commits:

```text
feat(combat): add shield damage multipliers (#42)
feat(world): add Island X region registry (#51)
content(map): add Cryo Foundry center route (#76)
art(map): add Frostbite Peaks lighting pass (#81)
fix(rounds): prevent duplicate match completion (#83)
test(ranked): validate team-average ELO calculation (#124)
docs(art): index early concept artwork (#152)
```

## 7.4 Required Labels

### Work Type

* `feature`
* `enhancement`
* `bug`
* `security`
* `performance`
* `refactor`
* `documentation`
* `testing`
* `balancing`
* `accessibility`
* `content`
* `art`
* `monetization`
* `analytics`
* `infrastructure`
* `technical-debt`

### Game System

* `combat`
* `movement`
* `weapons`
* `classes`
* `abilities`
* `grenades`
* `ammo`
* `round-system`
* `matchmaking`
* `ranked`
* `elo`
* `world`
* `island-x`
* `map`
* `audio`
* `ui-ux`
* `cosmetics`
* `store`
* `inventory`
* `emotes`
* `social`
* `data-storage`
* `networking`
* `anti-cheat`
* `mobile`
* `gamepad`

### Map Labels

* `map-cryo-foundry`
* `map-neon-divide`
* `map-overflow`
* `map-impact-site`
* `map-blackwater-terminal`

### Priority

* `priority-critical`
* `priority-high`
* `priority-medium`
* `priority-low`

### Status

* `status-triage`
* `status-ready`
* `status-in-progress`
* `status-blocked`
* `status-review`
* `status-testing`
* `status-done`

### Complexity

* `size-xs`
* `size-s`
* `size-m`
* `size-l`
* `size-xl`

### Release

* `release-blocker`
* `public-beta`
* `post-launch`
* `experimental`

## 7.5 Required Milestones

Create:

1. `M0 — Repository and Architecture`
2. `M1 — Cryo Foundry Combat Prototype`
3. `M2 — Complete Round Loop`
4. `M3 — Initial Arsenal and Classes`
5. `M4 — Cryo Foundry Vertical Slice`
6. `M5 — Island X and Multi-Map Framework`
7. `M6 — Ranked and Persistence`
8. `M7 — Cosmetics and Monetization`
9. `M8 — Three-Map Alpha`
10. `M9 — Public Beta Readiness`
11. `M10 — Five-Map Public Beta`
12. `M11 — Version 1.0`

Public beta cannot be approved before the three-map milestone is complete.

## 7.6 GitHub Project Board

Use columns:

* Backlog.
* Triage.
* Ready.
* In Progress.
* Blocked.
* Review.
* QA.
* Ready to Merge.
* Done.

Use fields:

* Status.
* Priority.
* Milestone.
* System.
* Map.
* Island X region.
* Complexity.
* Owner.
* Estimated effort.
* Target release.
* Blocked by.
* Blocking.
* Testing status.
* Documentation status.
* Monetization impact.
* Security impact.
* Performance impact.
* Artwork reference.

Create views for:

* Current milestone.
* Parallel workstreams.
* Cryo Foundry.
* Public-beta maps.
* Island X.
* Weapons.
* Ranked.
* Monetization.
* Cosmetics.
* Art production.
* Security.
* Critical bugs.
* Issues without acceptance criteria.
* Issues missing tests.
* Issues missing documentation.
* Public-beta blockers.

## 7.7 Issue Templates

Create templates for:

* Feature request.
* Gameplay system.
* Weapon.
* Weapon balancing.
* Class ability.
* Map graybox.
* Map art pass.
* Map lighting.
* World and Island X.
* Cosmetic item.
* Monetization.
* Bug.
* Security.
* Performance.
* Technical debt.
* Documentation.
* QA test plan.
* Audio request.
* Art asset request.

Every implementation issue must include:

* Summary.
* Player value.
* Scope.
* Out of scope.
* Technical approach.
* Dependencies.
* Blocking issues.
* Artwork references.
* Security considerations.
* Networking considerations.
* Persistence considerations.
* Monetization considerations.
* Analytics requirements.
* Accessibility requirements.
* Performance budget.
* Acceptance criteria.
* Testing instructions.
* Documentation changes.
* Screenshots or recordings where applicable.

## 7.8 Parallel Development

Split work so multiple developers or AI agents can work simultaneously.

Recommended parallel workstreams:

* Repository and CI.
* Shared types and configuration.
* Movement and camera.
* Weapon framework.
* Health and shield.
* Match and round services.
* Cryo Foundry graybox.
* Island X world presentation.
* HUD and menus.
* Character classes.
* Audio.
* Persistence.
* Ranked system.
* Cosmetics.
* Store and purchases.
* Emotes and communication.
* Anti-cheat.
* Automated tests.
* Second-map preproduction.
* Third-map preproduction.

Use stable interfaces and mock implementations to prevent one incomplete system from blocking all other work.

---

# 8. Match Structure

Implement elimination-based rounds.

Default settings:

* Two teams.
* No respawns during active rounds.
* Eight-second pre-round countdown.
* Ninety-second round timer.
* First team to seven round wins.
* Short post-round phase.
* Full post-match results.

Make configurable:

* Round duration.
* Round-win target.
* Countdown duration.
* Post-round duration.
* Match-point rules.
* Team-side rotation.
* Draw behavior.
* Overtime behavior.

When the normal timer expires and both teams still have living players:

* Activate a central overtime capture zone.
* Allow both teams to contest it.
* Award the round to the first team that completes capture.

A round ends when:

* One team is fully eliminated.
* One team captures overtime.
* One team forfeits.
* A team loses all eligible connected players.
* An administrator invalidates the round.

Include:

* Reconnect handling.
* Abandonment handling.
* Ranked grace period.
* Match identifiers.
* Duplicate result protection.

---

# 9. Health and Shield

Every player has:

* 100 shield.
* 100 health.
* 200 total effective durability.

Damage normally applies to shields before health.

The HUD must clearly separate shield and health.

Configure:

* Shield regeneration delay.
* Shield regeneration rate.
* Health regeneration delay.
* Health regeneration rate.
* Ability to disable health regeneration.
* Shield-break sound.
* Shield-break effect.
* Low-health audio.
* Low-health visual treatment.

Classes must not change:

* Maximum health.
* Maximum shield.
* Base movement.
* Hitbox size.
* Weapon damage.
* Weapon accuracy.
* Reload speed.

---

# 10. Movement and Controls

Required controls:

* `WASD`: Move.
* `Mouse`: Camera and aim.
* `Space`: Jump.
* `Left Shift`: Sprint.
* `Left Control`: Crouch.
* `Left Mouse Button`: Fire or knife attack.
* `Right Mouse Button`: ADS.
* `R`: Reload.
* `1`: Primary.
* `2`: Secondary or special.
* `3`: Heavy.
* `4`: Knife.
* `G`: Grenade.
* `F`: Class melee ability.
* `E`: Interact and collect ammo.
* `B`: Emote and communication wheel.
* `Tab`: Scoreboard.
* `Escape`: Menu and settings.

Use a centralized input abstraction to support future:

* Gamepad.
* Mobile.
* Input rebinding.

Movement must include:

* Responsive acceleration and deceleration.
* Sprint.
* Crouch.
* Tuned air control.
* Sprint FOV.
* Weapon lowering during sprint.
* Crouch camera movement.
* Weapon sway.
* Camera bob.
* Jump and landing feedback.
* Material-based footsteps.
* Camera recoil.
* Viewmodel recoil.
* Smooth equip transitions.

Suggested baseline:

* Walk speed: 16.
* Sprint speed: 22.
* Crouch speed: 10.
* Normal FOV: 80.
* Sprint FOV: 88.

Do not add supers, wall running, unrestricted flight, or teleportation.

An experimental slide may exist behind a disabled feature flag.

---

# 11. Weapons and Loadouts

Each player has:

1. Primary weapon.
2. Secondary or special weapon.
3. Heavy weapon.
4. Knife.

Every firearm must support:

* Hip fire.
* ADS.
* Reloading.
* Magazine ammo.
* Reserve ammo.
* Fire-rate enforcement.
* Damage falloff.
* Precision multipliers.
* Camera recoil.
* Viewmodel recoil.
* Spread.
* Movement spread.
* Airborne spread.
* Muzzle flash.
* Tracers where appropriate.
* Impact effects.
* Shield-hit feedback.
* Health-hit feedback.
* Hit markers.
* Shield-break feedback.
* Elimination feedback.
* Equip animations.
* Reload animations.
* Fire animations.
* Proper audio.

Damage depends on:

* Weapon archetype.
* Distance.
* Hit location.
* Shield or health state.
* Weapon configuration.

Damage must never depend on:

* Paid skin.
* Reticle.
* Gloves.
* Helmet.
* Cape.
* Wings.
* ELO.
* Account age.
* Robux spending.

## Initial Primary Weapons

* Auto rifle.
* Burst rifle.
* Precision hand cannon.

## Initial Special Weapons

* Shotgun.
* Sniper rifle.
* Charged energy rifle.

## Initial Heavy Weapons

* Rocket launcher.
* Heavy machine gun.

## Knife

The standard knife must:

* Have unlimited use.
* Use server-validated range.
* Have swing and recovery delays.
* Include hit and miss audio.
* Remain separate from the class ability.

---

# 12. Shield Damage Rules

Suggested starting shield multipliers:

* Primary: 1.0x.
* Special: 1.25x.
* Heavy: 1.5x.
* Knife: 1.0x.
* Grenades: Configurable.
* Class abilities: Configurable.

Store these values in centralized combat configuration.

---

# 13. Special and Heavy Ammo

## Special Ammo

* Two competitively equivalent map locations.
* First spawn approximately 20 seconds after round start.
* Respawn approximately every 30 seconds.
* In-world timer.
* Pre-spawn cue.
* Server-authoritative pickup.
* Configurable granted ammunition.

## Heavy Ammo

* One central high-risk location.
* Spawn approximately 45 seconds after round start.
* Normally one spawn per round.
* Prominent countdown.
* Map-wide warning.
* Server-authoritative pickup.

## Survivor Retention

Players who survive retain remaining special and heavy ammo.

Players who are eliminated receive the configured reset amount.

Add configurable maximum carry limits.

Primary ammo resets based on weapon configuration.

Grenades do not carry between rounds.

---

# 14. Grenades

Each player begins a round with one grenade.

Requirements:

* One grenade maximum.
* No in-round regeneration.
* Server-authoritative use.
* Projectile trajectory.
* Bounce physics.
* Fuse.
* Explosion radius.
* Damage falloff.
* Obstruction checks.
* Proper sound.
* HUD indicator.

Initial grenade:

* Fragmentation-style grenade.

Future grenade skins must not change gameplay.

---

# 15. Classes

Initial classes:

* Specter — agile skirmisher.
* Conduit — energy specialist.
* Bulwark — heavy breacher.

All classes have identical:

* Health.
* Shield.
* Movement.
* Hitboxes.
* Weapon access.
* Grenade count.

The initial difference is the charged melee ability.

Use `F`.

Suggested cooldown:

* 25 seconds.

## Specter — Flechette

A charged mono-edge throwing blade.

* Physical projectile.
* Travel time.
* Body and precision damage.
* Configurable projectile drop.
* Suggested body damage: 80.
* Suggested precision damage: 120.

## Conduit — Surge Bolt

A charged superheated plasma bolt.

* Short-to-medium projectile.
* Direct damage.
* Temporary burn.
* Suggested direct damage: 70.
* Suggested burn: four ticks of five damage.

## Bulwark — Kinetic Ram

A charged forward slam.

* Forward lunge.
* Approximately 12 studs.
* Server-validated collision.
* Suggested damage: 100.
* Recovery delay after a miss.
* Cannot pass through walls.

Do not add supers during the initial release.

---

# 16. Island X and Map Framework

Create a data-driven map and region registry.

Example:

```lua
IslandXRegions = {
    FrostbitePeaks = {
        DisplayName = "Frostbite Peaks",
        Arenas = { "CryoFoundry" },
    },

    NeonCity = {
        DisplayName = "Neon City",
        Arenas = { "NeonDivide" },
    },

    StormwallDam = {
        DisplayName = "Stormwall Dam",
        Arenas = { "Overflow" },
    },
}
```

Each arena definition should include:

* Unique ID.
* Display name.
* Region.
* Description.
* Thumbnail.
* Supported team sizes.
* Supported playlists.
* Spawn references.
* Special-ammo points.
* Heavy-ammo point.
* Overtime point.
* Lighting profile.
* Audio profile.
* Environment profile.
* Release status.
* Feature flag.
* Version.
* Competitive approval status.

The system must allow new Island X maps to be added without rewriting matchmaking or round logic.

---

# 17. ELO Ranking

Maintain separate ratings for:

* Ranked 1v1.
* Ranked 3v3.
* Ranked 5v5.

Use standard expected-score calculations and team-average rating for team modes.

Persist:

* Rating.
* Placement progress.
* Wins.
* Losses.
* Matches.
* Round wins.
* Round losses.
* Kills.
* Deaths.
* Assists.
* Damage.
* Highest rating.
* Win streak.
* Abandonments.

Requirements:

* Server-only calculations.
* Unique match IDs.
* Duplicate protection.
* DataStore retry handling.
* Abandonment penalties.
* Invalid-match protection.
* Post-match rating screen.

---

# 18. Monetization and Cosmetics

Monetization must be part of the architecture from the beginning.

It must remain cosmetic and non-pay-to-win.

Support:

* Weapon skins.
* Knife skins.
* Gloves.
* Helmets.
* Masks.
* Clothing.
* Armor.
* Boots.
* Wings.
* Capes.
* Back accessories.
* Weapon charms.
* Reticles.
* Banners.
* Titles.
* Spawn effects.
* Elimination effects.
* Victory poses.
* Emotes.
* Communication emojis.
* Announcer packs.
* Cosmetic grenade appearances.
* Cosmetic class-ability effects.

## 18.1 Competitive Restrictions

Cosmetics must not change:

* Damage.
* Accuracy.
* Recoil.
* Fire rate.
* Reload timing.
* ADS timing.
* Movement.
* Hitboxes.
* Collision.
* Projectile behavior.
* Audio detection distance.
* Enemy visibility.
* Player durability.

Wings and capes must:

* Be hidden or reduced in first person.
* Have no gameplay collision.
* Use optimized animation.
* Not block the owner’s view.
* Not obscure enemy or teammate identification.
* Be reducible in competitive performance mode.

## 18.2 Reticles

Paid reticles must remain cosmetic.

They cannot provide:

* More accurate center information.
* Enemy outlines.
* Range calculations.
* Aim assistance.
* Movement prediction.
* Head tracking.
* Additional zoom.
* Spread reduction.

The default reticle must remain competitively complete.

## 18.3 Store and Purchases

Create:

* Catalog.
* Inventory.
* Locker.
* Preview system.
* Featured items.
* Collections.
* Bundles.
* Robux purchase abstractions.
* Soft currency.
* Receipt processing.
* Purchase reconciliation.
* Ownership persistence.
* Purchase analytics.

Use server-authoritative, idempotent receipt processing.

Do not permit the client to control:

* Price.
* Product mapping.
* Ownership.
* Currency.
* Item grants.

Every cosmetic item must have its own GitHub Issue.

---

# 19. Emotes and Communication Emojis

Players can equip and use:

* Wave.
* Salute.
* Point.
* Celebrate.
* Bow.
* Thumbs up.
* Team rally.
* Victory pose.
* GG presentation.
* Other original expressions.

Communication emoji examples:

* GG.
* Nice shot.
* Well played.
* Thanks.
* Sorry.
* Group up.
* Defend.
* Attack.
* Heavy ammo.
* Special ammo.
* Enemy spotted.
* Retreat.
* Ready.
* Heart.
* Celebration.

Characters may briefly hold, throw, project, or display an original visual message such as “GG.”

Requirements:

* Server validation.
* Rate limiting.
* Spam prevention.
* Mute controls.
* Team-only and global options.
* Localization readiness.
* No arbitrary player image uploads.
* No obstruction of another player’s view.
* No enemy detection through walls.
* No competitive advantage.

Restrict disruptive full-body emotes during active ranked rounds.

---

# 20. Networking and Security

The server is authoritative for:

* Damage.
* Ammo.
* Reloading.
* Fire rate.
* Equipped weapon.
* Weapon ownership.
* Pickups.
* Grenades.
* Ability charge.
* Ability hits.
* Health.
* Shield.
* Round state.
* Match results.
* ELO.
* Cosmetics.
* Currency.
* Purchases.
* Emote permissions.
* Communication cooldowns.
* Persistence.

Validate:

* Remote frequency.
* Fire timing.
* Ammo state.
* Reload state.
* Player state.
* Round state.
* Shot origin.
* Shot direction.
* Firing angle.
* Melee distance.
* Ability cooldown.
* Pickup distance.
* Movement speed.
* Cosmetic ownership.
* Purchase receipt.
* Communication spam.
* Duplicate match results.

Create centralized rate limiting and structured security logs.

---

# 21. Recommended Project Structure

```text
.github/
├── ISSUE_TEMPLATE/
├── workflows/
├── pull_request_template.md
└── CODEOWNERS

earlyartwork/
├── map-concepts/
├── world-concepts/
├── character-concepts/
├── weapon-concepts/
├── cosmetic-concepts/
└── miscellaneous/

docs/
├── adr/
├── architecture/
├── art-direction/
├── gameplay/
├── maps/
├── monetization/
├── security/
├── testing/
└── project-management/

src/
├── ReplicatedStorage/
│   ├── Shared/
│   │   ├── Config/
│   │   ├── Types/
│   │   ├── Utility/
│   │   └── Constants/
│   ├── Remotes/
│   ├── Weapons/
│   ├── Abilities/
│   ├── Cosmetics/
│   ├── Emotes/
│   ├── Maps/
│   └── IslandX/
├── ServerScriptService/
│   ├── ServerBootstrap
│   ├── Services/
│   └── Tests/
├── StarterPlayer/
│   └── StarterPlayerScripts/
├── StarterGui/
└── Workspace/

tests/
scripts/
masterplan.md
README.md
CONTRIBUTING.md
ROADMAP.md
BALANCING.md
SECURITY.md
MONETIZATION.md
ANALYTICS.md
ASSET_MANIFEST.md
```

Required services should include:

* MatchService.
* RoundService.
* MapService.
* IslandXService.
* CombatService.
* WeaponService.
* AmmoService.
* AbilityService.
* GrenadeService.
* PlayerStateService.
* DataService.
* RankedService.
* QueueService.
* CosmeticService.
* InventoryService.
* CatalogService.
* StoreService.
* PurchaseService.
* CurrencyService.
* EmoteService.
* CommunicationService.
* AntiCheatService.
* AnalyticsService.
* TelemetryService.

---

# 22. Testing

Create automated or repeatable tests for:

* Shield-before-health.
* Shield multipliers.
* Damage falloff.
* Precision hits.
* Fire-rate validation.
* Reloading.
* Special-ammo collection.
* Heavy-ammo collection.
* Survivor ammo retention.
* Eliminated-player ammo reset.
* One grenade per round.
* Class cooldowns.
* Round completion.
* Overtime.
* Match completion.
* ELO calculations.
* Duplicate match results.
* Cosmetic ownership.
* Cosmetic neutrality.
* Wings and capes not changing collision.
* Reticles not changing accuracy.
* Receipt idempotency.
* Duplicate purchase prevention.
* Currency spending.
* Emote interruption.
* Communication rate limits.
* Data migration.
* Map spawn safety.
* Map-side timing equality.
* Map boundary enforcement.
* Three-map rotation.
* Five-map rotation when available.

Every test must reference a GitHub Issue.

---

# 23. Public Beta Definition of Done

Fireteam Labs is ready for public beta only when:

* At least three complete maps are available.
* Cryo Foundry is complete.
* Neon Divide is complete.
* Overflow is complete.
* All three maps support 1v1, 3v3, and 5v5.
* Map rotation works.
* Island X map selection works.
* A complete match can be played without manual resets.
* Health and shields work.
* Sprint and crouch work.
* Hip fire and ADS work.
* Primary, special, heavy, and knife slots work.
* Grenades work.
* Ammo pickups work.
* Survivors retain special and heavy ammo.
* Classes work.
* Overtime works.
* Ranked ELO works.
* Persistence works.
* Cosmetics persist.
* Store architecture works.
* Receipt processing is secure and idempotent.
* Weapon skins are cosmetic.
* Gloves render properly.
* Helmets and clothing equip properly.
* Wings and capes do not affect gameplay.
* Emotes function.
* GG and communication expressions function.
* Players can mute communication expressions.
* Major actions have proper audio.
* Invalid requests are rejected.
* Imported assets contain no unknown scripts.
* Performance targets are met.
* Required tests pass.
* Public-beta blockers are closed.
* Documentation is complete.
* External assets are recorded in the asset manifest.

The preferred public-beta release should contain five maps, but three maps are the mandatory minimum.

---

# 24. Required Deliverables

Produce:

1. Complete Rojo-compatible project.
2. Complete Luau source files.
3. GitHub labels.
4. GitHub milestones.
5. GitHub Project configuration.
6. Issue templates.
7. Pull request template.
8. CODEOWNERS.
9. Architecture Decision Records.
10. Initial epics.
11. Small implementation issues.
12. Dependency relationships.
13. Parallel workstream plan.
14. Early artwork index.
15. Art-direction document.
16. Roblox visual-target document.
17. Island X region system.
18. Holographic or tactical Island X map-selection concept.
19. Cryo Foundry.
20. Neon Divide.
21. Overflow.
22. Impact Site when pursuing the five-map target.
23. Blackwater Terminal when pursuing the five-map target.
24. Three primary weapons.
25. Three special weapons.
26. Two heavy weapons.
27. Knife.
28. Grenade.
29. Three classes.
30. Casual modes.
31. Ranked modes.
32. ELO persistence.
33. Cosmetics inventory.
34. Locker.
35. Store.
36. Secure purchases.
37. Soft currency.
38. Weapon skins.
39. Gloves.
40. Helmets.
41. Clothing.
42. Wings.
43. Capes.
44. Emotes.
45. Communication emojis.
46. Cosmetic reticles.
47. Audio coverage.
48. Automated tests.
49. Documentation.

---

# 25. Execution Order

Begin by inspecting:

```text
masterplan.md
earlyartwork/
```

Then:

1. Index all early artwork.
2. Produce the art-direction documents.
3. Create the GitHub labels.
4. Create the milestones.
5. Create the project board.
6. Create issue and pull request templates.
7. Create Architecture Decision Records.
8. Create the Island X world and map registry architecture.
9. Break the project into epics.
10. Break epics into small implementation issues.
11. Link dependencies.
12. Identify parallel workstreams.
13. Implement the shared project foundation.
14. Implement Cryo Foundry as the first playable arena.
15. Implement the complete combat and round loop.
16. Implement weapons and classes.
17. Implement ranked and persistence.
18. Implement cosmetics and monetization.
19. Implement the Island X map-selection presentation.
20. Develop Neon Divide and Overflow in parallel where possible.
21. Reach the required three-map alpha.
22. Complete public-beta security, balance, and performance reviews.
23. Develop Impact Site and Blackwater Terminal for the preferred five-map beta.
24. Produce the final implementation and readiness report.

Do not stop after:

* Reading the artwork.
* Creating issues.
* Creating documentation.
* Creating one map.
* Creating a graybox.
* Creating one weapon.
* Creating placeholder UI.
* Creating store mockups.

Continue until the best complete, playable version possible exists in the workspace.

---

# 26. Final Implementation Report

At the end of the execution, provide:

* Milestones completed.
* Issues completed.
* Issues still open.
* Pull-request-ready change groups.
* Maps completed.
* Maps in progress.
* Island X regions implemented.
* Gameplay systems implemented.
* Tests completed.
* Known limitations.
* Security considerations.
* Performance considerations.
* Monetization systems completed.
* Artwork references used.
* Artwork references rejected and why.
* Placeholder asset IDs.
* Public-beta blockers.
* Recommended next issues.
* Instructions for running the project.
* Instructions for syncing with Rojo.
* Instructions for multiplayer testing.
* Instructions for adding Island X regions.
* Instructions for adding maps.
* Instructions for adding cosmetics.
* Instructions for configuring store items.
* Instructions for publishing a public-beta build.


# SEASONAL PROGRESSION AMENDMENT

## Update to Core Product Vision

Add the following items to the core product vision:

* A persistent seasonal progression system.
* A free and premium seasonal reward track.
* High-value, season-themed cosmetic rewards.
* Playlist XP earned through normal gameplay.
* A modest XP advantage for ranked play.
* No seasonal XP from private or custom matches.
* A predictable path allowing active players to complete the entire season.
* Optional late-season progression purchases.
* No gameplay power, weapons, ammunition, statistics, or competitive advantages in seasonal rewards.

Seasonal progression is an MVP requirement and must be functional before Fireteam Labs enters public beta.

---

# Seasonal Progression System

Fireteam Labs must include a configurable seasonal progression system similar in structure to a battle pass.

The internal system name should be:

**Season Pass**

The player-facing name may later be changed through a branding GitHub Issue.

Each season should provide a progression path containing unique cosmetic rewards connected to:

* Island X.
* The current season’s featured regions.
* New maps.
* Character classes.
* Weapons.
* Seasonal events.
* Fireteam Labs experiments.
* Seasonal narrative and visual themes.

The first implementation should be internally referred to as:

**Season 0**

Season 0 may use placeholder rewards while the progression, purchasing, claiming, persistence, and rollover systems are tested.

## Seasonal Design Goals

The seasonal system must:

* Reward active participation.
* Encourage players to complete matches.
* Give ranked players a modest XP advantage.
* Keep casual playlists fully viable for progression.
* Prevent private-match and custom-match farming.
* Provide a predictable completion target.
* Respect the player’s time.
* Avoid requiring daily play.
* Allow players who join late to catch up.
* Allow optional progression purchases later in the season.
* Never provide gameplay power.
* Never affect ranked matchmaking or ELO.
* Never require a specific character class or weapon to progress.

The system must not rely exclusively on daily challenges, login streaks, or fear-based mechanics.

A player should be able to make meaningful progress by simply playing eligible Fireteam Labs playlists.

---

# Season Structure

Each season definition must support:

* Unique season ID.
* Display name.
* Description.
* Theme.
* Island X region focus.
* Start date.
* End date.
* Grace period.
* Reward-claim deadline.
* Total number of tiers.
* XP required per tier.
* Total season XP.
* Target completion hours.
* Target completion match count.
* Free reward track.
* Premium reward track.
* Featured cosmetic collection.
* Season artwork.
* Season color and UI theme.
* Premium pass product reference.
* Tier-purchase product references.
* Catch-up configuration.
* Ranked XP multiplier.
* Event XP multiplier.
* Season status.
* Feature flag.
* Data schema version.

All season values must be data-driven.

Do not hardcode an individual season’s dates, rewards, prices, or XP requirements into gameplay scripts.

---

# Initial Progression Target

Use the following as the initial balancing model:

* 100 tiers.
* 1,000 XP per tier.
* 100,000 total XP.
* Approximately 100 hours for a consistent player to complete the pass.
* Approximately 400–550 completed matches, depending on playlist, team size, round count, and match duration.
* A player with a reasonable win ratio should complete the pass within the target playtime.
* Ranked players should complete slightly faster, but ranked must not be required.

The exact values must remain configurable.

Create progression simulation tools that allow the development team to test:

* Total completion hours.
* Total matches required.
* Different win ratios.
* Casual-only progression.
* Ranked-only progression.
* Mixed-playlist progression.
* Different match durations.
* Different team sizes.
* Early-season players.
* Late-season players.
* Players purchasing limited tier progression.

The project must not finalize the XP economy based only on assumptions. It must be adjusted through playtest data and GitHub balancing issues.

## Recommended Completion Targets

Initial design targets:

* Casual player with approximately a 50% win ratio: 90–100 hours.
* Ranked player with approximately a 50% win ratio: 80–90 hours.
* Mixed-playlist player: approximately 85–95 hours.
* Lower-win-rate player who consistently completes matches: still capable of completing within approximately 100–115 hours.
* High-skill player: faster completion, but not dramatically faster.
* AFK or low-participation player: little or no XP.

These are starting targets rather than permanent promises.

---

# Eligible Playlists

Seasonal XP may be earned from:

* Casual 1v1.
* Casual 3v3.
* Casual 5v5.
* Ranked 1v1.
* Ranked 3v3.
* Ranked 5v5.
* Official limited-time playlists.
* Official seasonal experiments explicitly marked as XP eligible.

Seasonal XP must not be earned from:

* Private matches.
* Custom matches.
* Developer test matches.
* Local Studio matches unless a development override is active.
* Matches involving only bots unless explicitly authorized for testing.
* Invalidated matches.
* Matches identified as farming or exploitation.
* Matches below the minimum participation threshold.

Private and custom matches must return an XP multiplier of exactly zero.

---

# Match XP Formula

Use a server-authoritative, configurable XP formula.

Recommended structure:

```text
Base Match XP
+ Time Played XP
+ Completed Round XP
+ Match Completion Bonus
+ Victory Bonus
+ Capped Performance XP
+ Optional Playlist Bonus
= Subtotal XP

Subtotal XP
× Ranked Multiplier
× Event Multiplier
× Catch-Up Multiplier
= Final Season XP
```

The client must never calculate or submit its own XP total.

## XP Components

### Match Completion XP

Award XP for completing a valid match.

This should be a meaningful portion of the reward so players are encouraged to finish matches.

### Time Played XP

Award XP based on active time spent in a valid match.

Requirements:

* Use active participation time rather than total server connection time.
* Apply a reasonable per-match maximum.
* Do not count extended spectating caused by joining late.
* Do not reward AFK time.
* Normalize the design so short 1v1 matches and longer 5v5 matches have reasonably comparable XP per hour.

### Round Participation XP

Award a small amount for participating in completed rounds.

Do not allow round XP to be farmed through intentionally extending matches.

### Victory XP

Award a clear but not overwhelming win bonus.

Winning should matter, but losing a competitive match after meaningful participation must still provide useful progress.

### Performance XP

Performance XP may consider:

* Kills.
* Assists.
* Damage dealt.
* Objective captures.
* Special-ammo contests.
* Heavy-ammo contests.
* Team contribution.
* Round survival.
* Supportive actions added in the future.

Performance XP must be capped.

It should not exceed approximately 20–25% of normal match XP without an explicitly approved balancing change.

This prevents:

* Kill farming.
* Stat padding.
* Team-role punishment.
* Excessive progression gaps between skill levels.
* Players ignoring round objectives.

### Ranked Multiplier

Ranked playlists should provide more XP than casual playlists.

Suggested initial ranked multiplier:

```text
1.15x
```

The allowed initial balancing range should be:

```text
1.10x to 1.20x
```

Ranked must provide a noticeable advantage without becoming the only reasonable progression method.

Do not grant additional XP based directly on a player’s ELO rating.

High-rated players should not automatically receive more seasonal XP than lower-rated players for the same eligible match outcome.

---

# Anti-Farming and Participation Validation

XP must only be granted after the server validates the match result.

Validation should include:

* Valid playlist.
* Valid match identifier.
* Valid round history.
* Minimum active participation.
* Minimum match duration where appropriate.
* Player was not AFK for most of the match.
* Player did not repeatedly damage only cooperating accounts.
* Match was not invalidated.
* Match result has not already been processed.
* Player did not receive XP for the same match previously.
* Player was not using a private or custom playlist.
* Player did not leave before the eligibility threshold.

Create anti-farming detection for:

* Repeated matches against the same small account group.
* Alternating intentional wins.
* Accounts with extremely low movement or combat activity.
* Repeated self-elimination patterns.
* Match duration manipulation.
* Multi-account XP farming.
* Automated input or AFK behavior.
* Suspiciously identical match histories.

Do not automatically punish players solely because they frequently play legitimate friends in public matchmaking. Suspicious patterns should be recorded for review and evaluated with multiple signals.

---

# Leaving and Abandonment

Recommended behavior:

* Ranked abandonment grants no completion or victory XP.
* Ranked abandonment may grant only validated XP earned before departure, or zero XP, based on configuration.
* Casual early departure grants reduced or no completion XP.
* Reconnecting within the allowed grace period preserves eligibility.
* Players disconnected by a server problem should not be unfairly penalized.
* Invalidated matches should not grant normal progression.
* Administratively terminated matches should follow a configurable XP policy.

All abandonment rules must be server-authoritative and documented in the player-facing season information.

---

# Free and Premium Tracks

The system must support two parallel reward tracks:

## Free Track

Available to all players.

May contain:

* Soft currency.
* Basic weapon skins.
* Emotes.
* Communication emojis.
* Banners.
* Titles.
* Profile frames.
* Seasonal collectibles.
* Occasional high-value cosmetics.

## Premium Track

Unlocked through a Robux-backed seasonal purchase.

May contain:

* Premium weapon skins.
* Unique gloves.
* Helmets.
* Armor.
* Clothing.
* Capes.
* Wings.
* Knife skins.
* Elimination effects.
* Spawn effects.
* Animated emotes.
* Premium communication emojis.
* Cosmetic reticles.
* Seasonal collection sets.
* Final-tier prestige cosmetic.

Premium rewards must remain cosmetic.

Purchasing the premium track later in the season must retroactively unlock all premium rewards associated with tiers the player has already reached.

Players must not need to repeat progression after purchasing the premium track.

---

# Seasonal Reward Exclusivity

Seasonal rewards may be:

* Season exclusive.
* Vaulted after the season.
* Eligible to return.
* Eligible only for an anniversary event.
* Eligible only as a recolor.
* Permanently retired.

Every reward must declare a transparent return policy.

Recommended item field:

```text
ReturnPolicy
```

Supported values:

```text
NeverReturn
MayReturn
VaultedIndefinitely
AnniversaryEligible
RecolorOnly
PromotionalReturn
```

Do not describe an item as permanently exclusive unless its configuration is `NeverReturn`.

If an item might return, communicate that clearly.

High-value final-tier rewards should normally use either:

* `NeverReturn`
* `VaultedIndefinitely`
* `RecolorOnly`

The original version of a `NeverReturn` cosmetic must never be sold or granted again after its season ends.

A future recolor must be visibly distinct and must use a separate item ID.

---

# Reward Claiming

Support:

* Automatic reward granting.
* Manual reward claiming.
* Claim-all functionality.
* Retroactive premium reward claiming.
* End-of-season grace period.
* Ownership reconciliation.
* Duplicate-grant prevention.
* Reward delivery retries.
* Clear unclaimed-reward indicators.

The server must validate:

* Season.
* Tier.
* Track ownership.
* Reward ownership.
* Claim state.
* Reward definition.
* Season status.
* Grace-period status.

A client may request a claim but cannot determine whether the reward is valid.

---

# Late-Season Catch-Up

The progression system must allow players who begin later in the season to have a reasonable opportunity to complete it.

Support configurable catch-up methods such as:

* Increased XP after a percentage of the season has elapsed.
* Weekly XP boosts.
* Accumulated rest XP.
* End-of-season bonus weekends.
* Seasonal challenges.
* Limited purchased progression.
* Retroactive premium reward access.

Catch-up bonuses must not make early participation feel wasted.

A player who consistently plays throughout the season should retain an efficiency advantage over a player who begins at the last moment.

---

# Purchased Season Progression

Players may be allowed to purchase season tiers or season XP later in the season.

This feature must be configurable and may remain disabled during early testing.

Recommended configuration:

* Tier purchasing disabled at season launch.
* Tier purchasing becomes available after a configured percentage of the season has elapsed.
* Suggested initial unlock point: 50–70% of the season.
* Players may purchase individual tiers or approved tier bundles.
* A maximum purchasable tier count may be configured.
* Purchases cannot advance beyond the final tier.
* Purchased tiers do not grant ELO.
* Purchased tiers do not grant gameplay statistics.
* Purchased tiers do not count as matches played.
* Purchased tiers do not affect matchmaking.
* Purchased tiers only unlock seasonal reward eligibility.

Use secure, idempotent `MarketplaceService` receipt processing.

The client must never control:

* Tier price.
* XP price.
* Product ID mapping.
* Number of tiers granted.
* Season eligibility.
* Final tier calculation.
* Purchase completion state.

All purchased progression must be recorded separately from earned progression for analytics and support.

Recommended tracked values:

* Earned XP.
* Purchased XP.
* Earned tiers.
* Purchased tiers.
* Premium pass ownership.
* Purchase transaction IDs.

---

# Season Rollover

At the end of a season:

* Stop granting normal XP for the expired season.
* Preserve the player’s final tier and XP.
* Preserve claimed rewards.
* Preserve ownership of earned cosmetics.
* Allow claims during the configured grace period.
* Prevent new progression purchases after the configured purchase cutoff.
* Archive the season definition.
* Initialize the next season independently.
* Do not convert old season XP into new season XP unless explicitly configured.
* Produce a final season summary for the player.

Season rollover must not overwrite or corrupt previous season data.

Use versioned seasonal profile records.

---

# Recommended Data Model

```lua
SeasonProgress = {
    SeasonId = "season-0",

    EarnedXP = 0,
    PurchasedXP = 0,
    TotalXP = 0,

    CurrentTier = 0,
    EarnedTierCount = 0,
    PurchasedTierCount = 0,

    PremiumOwned = false,

    ClaimedFreeRewards = {},
    ClaimedPremiumRewards = {},

    ProcessedMatchIds = {},
    ProcessedReceiptIds = {},

    MatchesCompleted = 0,
    RankedMatchesCompleted = 0,
    CasualMatchesCompleted = 0,

    SeasonWins = 0,
    SeasonLosses = 0,

    LastXPGrantAt = 0,
    LastClaimAt = 0,

    SchemaVersion = 1,
}
```

Do not allow `ProcessedMatchIds` or receipt history to grow without bounds.

Use a safe deduplication strategy with:

* Limited recent history.
* Persistent match-result records.
* Expiration where appropriate.
* Unique transaction IDs.
* Idempotent profile updates.

---

# Required Architecture

Add the following modules and services:

```text
src/ReplicatedStorage/Shared/Config/SeasonConfig.lua
src/ReplicatedStorage/Shared/Config/XPConfig.lua
src/ReplicatedStorage/Shared/Seasons/SeasonDefinitions.lua
src/ReplicatedStorage/Shared/Types/SeasonTypes.lua

src/ServerScriptService/Services/SeasonService.lua
src/ServerScriptService/Services/XPService.lua
src/ServerScriptService/Services/SeasonRewardService.lua
src/ServerScriptService/Services/SeasonPurchaseService.lua

src/StarterPlayer/StarterPlayerScripts/Controllers/SeasonController.lua
src/StarterGui/SeasonPassMenu/
src/StarterGui/SeasonResults/
```

Responsibilities:

## SeasonService

* Current season state.
* Season start and end.
* Tier calculation.
* Season rollover.
* Premium ownership.
* Player season profile.
* Season configuration validation.

## XPService

* Match XP calculation.
* Playlist eligibility.
* Participation validation.
* Ranked multiplier.
* Catch-up multiplier.
* Match-result deduplication.
* Anti-farming signals.
* XP audit logging.

## SeasonRewardService

* Reward definitions.
* Free and premium tracks.
* Reward claiming.
* Claim-all.
* Retroactive premium rewards.
* Duplicate-grant prevention.
* Grace-period claims.

## SeasonPurchaseService

* Premium pass purchases.
* Tier purchases.
* Receipt processing.
* Idempotency.
* Product mapping.
* Ownership reconciliation.
* Purchase audit records.

---

# Season Pass User Interface

Create a complete season interface containing:

* Season name.
* Season artwork.
* Island X region theme.
* Season end date.
* Remaining time.
* Current tier.
* Current XP.
* XP required for next tier.
* Overall progress.
* Free track.
* Premium track.
* Claimed rewards.
* Unclaimed rewards.
* Locked rewards.
* Item previews.
* Premium ownership status.
* Premium upgrade option.
* Tier-purchase option when available.
* Catch-up bonus status.
* XP source explanation.
* Claim-all button.
* Final-tier preview.

Post-match results must show:

* Base match XP.
* Time XP.
* Round XP.
* Victory XP.
* Performance XP.
* Ranked bonus.
* Event bonus.
* Catch-up bonus.
* Total XP earned.
* Previous tier.
* New tier.
* Rewards unlocked.
* Progress toward the next tier.

The breakdown must be understandable and must not display fake or hidden bonuses.

---

# Seasonal Analytics

Track:

* Season menu opened.
* Reward previewed.
* Free reward claimed.
* Premium reward claimed.
* Premium pass viewed.
* Premium pass purchased.
* Tier purchase viewed.
* Tier purchased.
* Match XP granted.
* XP grant rejected.
* XP source breakdown.
* Tier reached.
* Pass completed.
* Final reward claimed.
* Catch-up multiplier applied.
* Season joined late.
* Season completion time.
* Season completion match count.
* Casual XP earned.
* Ranked XP earned.
* Purchased XP.
* Earned XP.
* Unclaimed rewards at season end.

Do not log unnecessary sensitive player data.

Create:

```text
docs/progression/SEASON_SYSTEM.md
docs/progression/XP_ECONOMY.md
docs/progression/SEASON_ROLLOVER.md
docs/progression/SEASON_OPERATIONS.md
docs/progression/REWARD_EXCLUSIVITY.md
```

---

# GitHub Labels

Add:

* `season-progression`
* `battle-pass`
* `season-content`
* `xp-economy`
* `season-rewards`
* `season-purchases`
* `season-operations`

---

# Seasonal Progression Epic

Create a GitHub Epic:

```text
EPIC — Implement Season 0 Progression
```

Break it into separate issues for:

1. Define season data contract.
2. Implement season configuration validation.
3. Implement XP formula.
4. Implement playlist eligibility.
5. Block XP in private and custom matches.
6. Implement ranked XP multiplier.
7. Implement participation validation.
8. Implement AFK detection.
9. Implement match-result deduplication.
10. Implement anti-farming signals.
11. Implement seasonal player persistence.
12. Implement tier calculation.
13. Implement free reward track.
14. Implement premium reward track.
15. Implement reward claiming.
16. Implement claim-all.
17. Implement retroactive premium rewards.
18. Implement season-pass UI.
19. Implement post-match XP breakdown.
20. Implement premium-pass purchasing.
21. Implement late-season tier purchases.
22. Implement receipt idempotency.
23. Implement catch-up configuration.
24. Implement season rollover.
25. Implement season grace period.
26. Implement progression analytics.
27. Implement progression simulation tool.
28. Implement admin XP testing commands.
29. Implement Season 0 placeholder rewards.
30. Complete seasonal security review.
31. Complete seasonal economy review.
32. Complete progression QA plan.
33. Complete progression documentation.

These issues should be assigned dependencies so persistence, XP calculation, UI, rewards, purchases, and analytics can be developed in parallel after the core data contracts are approved.

---

# Milestone Updates

Replace the current milestones with:

1. `M0 — Repository and Architecture`
2. `M1 — Cryo Foundry Combat Prototype`
3. `M2 — Complete Round Loop`
4. `M3 — Initial Arsenal and Classes`
5. `M4 — Cryo Foundry Vertical Slice`
6. `M5 — Island X and Multi-Map Framework`
7. `M6 — Ranked and Persistence`
8. `M7 — Season 0 Progression MVP`
9. `M8 — Cosmetics and Monetization`
10. `M9 — Three-Map Alpha`
11. `M10 — Public Beta Readiness`
12. `M11 — Five-Map Public Beta`
13. `M12 — Version 1.0`

`M7 — Season 0 Progression MVP` must be complete before the three-map alpha is approved.

---

# Persistence Updates

Add these values to persistent player profiles:

* Current season ID.
* Earned season XP.
* Purchased season XP.
* Current season tier.
* Premium pass ownership.
* Claimed free rewards.
* Claimed premium rewards.
* Season matches completed.
* Casual season XP.
* Ranked season XP.
* Purchased tier count.
* Season completion status.
* Highest tier reached.
* Historical season summaries.
* Seasonal profile schema version.

---

# Developer Tools

Add administrator and development commands for:

* Grant season XP.
* Remove test season XP.
* Set player tier.
* Grant premium pass in Studio.
* Revoke premium pass in Studio.
* Claim a reward.
* Claim all rewards.
* Simulate a completed casual match.
* Simulate a completed ranked match.
* Simulate different win ratios.
* Simulate tier purchase.
* Simulate premium purchase.
* Simulate season expiration.
* Simulate grace period.
* Run season rollover.
* Reset Season 0 data in Studio.
* Export progression simulation results.

Development commands must not be available to normal production players.

---

# Required Tests

Create automated or repeatable tests for:

* No XP from private matches.
* No XP from custom matches.
* XP from eligible casual playlists.
* XP from eligible ranked playlists.
* Ranked XP is higher than comparable casual XP.
* Casual progression remains viable.
* XP is not granted twice for the same match.
* Match completion XP.
* Victory XP.
* Time-played XP.
* Performance XP cap.
* AFK XP rejection.
* Early-leave XP reduction.
* Ranked abandonment behavior.
* Reconnect grace behavior.
* Tier calculation.
* Maximum tier handling.
* Free reward claims.
* Premium reward claims.
* Premium rewards rejected without ownership.
* Retroactive premium rewards.
* Duplicate reward prevention.
* Claim-all behavior.
* Purchased tier calculation.
* Duplicate receipt prevention.
* Purchase after cutoff rejection.
* Purchase beyond final tier rejection.
* Season expiration.
* Grace-period claims.
* Season rollover.
* Historical season preservation.
* Reward exclusivity metadata.
* XP simulation for 100-hour completion.
* Casual-only completion simulation.
* Ranked-only completion simulation.
* Mixed-playlist completion simulation.

---

# Public Beta Definition of Done Update

Add the following public-beta requirements:

* Season 0 progression is operational.
* Eligible casual playlists grant XP.
* Eligible ranked playlists grant a modest XP bonus.
* Private and custom matches grant no XP.
* Seasonal XP is server-authoritative.
* XP grants cannot be duplicated.
* AFK and low-participation farming protections are active.
* The free seasonal track works.
* The premium seasonal track works.
* Premium ownership persists.
* Premium rewards unlock retroactively.
* Reward claiming works.
* Duplicate rewards are prevented.
* Late-season tier-purchase architecture is functional or safely feature-flagged.
* Purchase receipt handling is idempotent.
* Season rollover is tested.
* The progression simulation demonstrates that a reasonably active player can complete the pass within the approved target.
* Casual-only progression remains viable.
* Ranked provides an advantage without becoming mandatory.
* Season rewards are cosmetic only.
* Every seasonal reward declares its return policy.
* Season progression documentation is complete.

---

# Required Deliverables Update

Add:

* Season 0 definition.
* Season configuration system.
* XP configuration system.
* XP calculation service.
* Playlist eligibility rules.
* Ranked XP multiplier.
* Participation validation.
* Anti-farming protections.
* Seasonal persistence.
* Free reward track.
* Premium reward track.
* Season-pass UI.
* Post-match XP breakdown.
* Reward claiming.
* Premium-pass purchasing.
* Late-season tier-purchase architecture.
* Catch-up configuration.
* Season rollover.
* Progression simulation tool.
* Seasonal analytics.
* Seasonal QA plan.
* Seasonal operations documentation.
* Placeholder Season 0 reward manifest.

---

# Final Seasonal Requirement

The exact Season 0 rewards may be designed later.

The progression architecture must not wait for final cosmetic designs.

Use placeholder reward IDs and clearly labeled temporary assets so the full system can be implemented, tested, balanced, and documented before the final rewards are available.

Seasonal reward production should proceed through separate GitHub Issues after the item-definition and reward-track contracts are stable.

---

# VERTICAL SLICE AMENDMENT

Decisions recorded 2026-07-17. This amendment overrides earlier sections where they conflict.

## Milestone 0 — Vertical Slice

Before any other milestone, build a playable vertical slice containing only:

* One complete map (one Island X sector).
* 1v1 and 3v3 casual matches.
* One primary weapon, one special weapon, one heavy weapon, and the knife.
* Movement, gunplay, health and shields, and the full round loop with win conditions and overtime.
* The three classes with their charged melee abilities.

Explicitly deferred past the vertical slice:

* 5v5 (a configuration change once 3v3 works).
* Ranked playlists and ELO.
* Store, purchases, currency, and all cosmetics.
* Emotes and communication emojis.
* Seasonal progression.
* Additional maps and weapons.

The vertical slice must still follow the server-authoritative architecture, configuration modules, and issue-driven workflow defined in this document, so deferred systems can be added without rework.

## Island X Framing

Fireteam Labs is an arena shooter. Island X is the persistent world fiction: every arena map is a named sector of Island X, and map selection presents the island. A battle-royale mode on the full island is a possible far-future direction and must not influence current match structure, ammo economy, or map design. The existing battle-royale-flavored concept art is directional mood reference only.

## Class Identity

The classes are Specter (Flechette), Conduit (Surge Bolt), and Bulwark (Kinetic Ram), as defined in Section 15. Earlier working names referencing other games' classes are retired and must not appear in code, assets, issues, or player-facing text.
