# Asset Manifest

Every external or imported asset must be recorded here before merge: source, license/usage rights, and where it is used. Imported assets must contain no unknown scripts.

| Asset | Source | License / Rights | Used In |
| --- | --- | --- | --- |
| `earlyartwork/map-concepts/cryo-foundry-redesign-idea2.png` | User-provided map concept | Project-owned | Cryo Foundry layout reference (#41) |
| `earlyartwork/map-concepts/cryo-foundry-skybox-concept.png` | Generated (codex `image_gen`, ChatGPT auth) | AI-generated, project-owned | Cryo Foundry sky mood reference |
| `assets/skybox/cryo-foundry/*` (6 faces + equirect source) | Generated (codex `image_gen`, ChatGPT auth) → cube faces via `skybox_convert.py` | AI-generated, project-owned | Cryo Foundry `Sky` cubemap (pending Roblox upload) |
| `assets/environment-kit/iceworld/*.glb` (18 pieces, 3 batches) | Generated (codex-authored Blender `bpy` scripts) | AI-generated, project-owned | Iceworld Facility modular environment kit (pending Roblox upload) |
| `assets/characters/base/base_body_{male,female}.glb` | Blender Studio Human Base Meshes (extracted + density-capped) | **CC0** (credit Blender Studio) | Shared full-body character base (Specter/Conduit/Bulwark) |
| `assets/characters/specter/specter_operator.glb` | Generated (Meshy.ai multi-image-to-3D from an AI concept sheet) | AI-generated, project-owned | Specter operator hero mesh (62k tris, PBR 2K), pending Roblox upload |
| `assets/characters/specter/specter_operator_r15.{fbx,glb}` | `specter_operator.glb` rigged to R15 (`rig_meshy_r15.py`) | AI-generated, project-owned | Specter rigged character for Studio Avatar Importer |
| `assets/characters/specter/concept_{front,back}.png` | Generated (codex `image_gen`, ChatGPT auth) | AI-generated, project-owned | Specter concept reference fed to Meshy |
| `assets/characters/specter/archive/specter_gear_blockout.*` | Generated (codex + Blender, shrinkwrap-fitted) | AI-generated, project-owned | Superseded Specter gear blockout (archived) |
