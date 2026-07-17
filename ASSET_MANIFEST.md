# Asset Manifest

Every external or imported asset must be recorded here before merge: source, license/usage rights, and where it is used. Imported assets must contain no unknown scripts.

| Asset | Source | License / Rights | Used In |
| --- | --- | --- | --- |
| `earlyartwork/map-concepts/cryo-foundry-redesign-idea2.png` | User-provided map concept | Project-owned | Cryo Foundry layout reference (#41) |
| `earlyartwork/map-concepts/cryo-foundry-skybox-concept.png` | Generated (codex `image_gen`, ChatGPT auth) | AI-generated, project-owned | Cryo Foundry sky mood reference |
| `assets/skybox/cryo-foundry/*` (6 faces + equirect source) | Generated (codex `image_gen`, ChatGPT auth) → cube faces via `skybox_convert.py` | AI-generated, project-owned | Cryo Foundry `Sky` cubemap (pending Roblox upload) |
