# Contributing

Fireteam Labs is developed entirely through GitHub Issues and pull requests (MASTERPLAN.md section 7).

## Workflow

1. Create or select an issue with scope, out-of-scope, and acceptance criteria.
2. Branch from `develop` using the issue number:

   ```text
   feature/<issue>-short-description
   bugfix/<issue>-short-description
   security/<issue>-short-description
   balance/<issue>-short-description
   content/<issue>-short-description
   art/<issue>-short-description
   docs/<issue>-short-description
   ```

3. Implement only the scoped work. Add or update tests and docs.
4. Open a PR referencing the issue; CI must pass.

## Commits

Narrow, issue-linked commits:

```text
feat(combat): add shield damage multipliers (#42)
fix(rounds): prevent duplicate match completion (#83)
test(ranked): validate team-average ELO calculation (#124)
```

## Hard Rules

- The server is authoritative for all gameplay decisions. Clients send requests; the server validates.
- Gameplay values live in `src/ReplicatedStorage/Shared/Config/` modules, never inline.
- Cosmetics, reticles, ELO, account age, and spending must never affect gameplay.
- Class names are Specter, Conduit, and Bulwark — retired working names must not appear anywhere.
