# Asset Manifest

Every external or imported asset must be recorded here before merge: source, license/usage rights, and where it is used. Imported assets must contain no unknown scripts.

| Asset | Source | License / Rights | Used In |
| --- | --- | --- | --- |
| `earlyartwork/map-concepts/cryo-foundry-redesign-idea2.png` | User-provided map concept | Project-owned | Cryo Foundry layout reference (#41) |
| `earlyartwork/map-concepts/cryo-foundry-skybox-concept.png` | Generated (codex `image_gen`, ChatGPT auth) | AI-generated, project-owned | Cryo Foundry sky mood reference |
| `assets/skybox/cryo-foundry/*` (6 faces + equirect source) | Generated (codex `image_gen`, ChatGPT auth) → cube faces via `skybox_convert.py` | AI-generated, project-owned | Cryo Foundry `Sky` cubemap (pending Roblox upload) |
| `assets/environment-kit/iceworld/*.glb` (18 pieces, 3 batches) | Generated (codex-authored Blender `bpy` scripts) | AI-generated, project-owned | Iceworld Facility modular environment kit (pending Roblox upload) |
| `assets/characters/base/base_body_{male,female}.glb` | Blender Studio Human Base Meshes (extracted + density-capped) | **CC0** (credit Blender Studio) | Shared full-body character base (Specter/Conduit/Bulwark) |
| `assets/characters/specter/specter_gear_blockout.glb` | Generated (codex + Blender, shrinkwrap-fitted) | AI-generated, project-owned | Specter gear layer — **blockout**, pending artist polish + rig |
