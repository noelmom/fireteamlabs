# Graphics Quality Tiers

Fireteam Labs ships **High / Medium / Low** quality tiers (plus **Auto**). Realism must not
become an unoptimized showcase — every tier stays playable and input-responsive, and **gameplay
visibility is preserved at all tiers** (enemies always render clearly; readability never scales
down).

Implemented by `GraphicsConfig` (tier settings), `QualityLogic` (pure resolution, tested), and
`QualityController` (applies global lighting + publishes settings). Presentation only — never
touches gameplay, hit detection, or server state.

## What each tier controls

| Setting | Low | Medium | High |
| --- | --- | --- | --- |
| Lighting technology | ShadowMap | Future | Future |
| Global shadows | on | on | on |
| Shadow distance (studs) | 60 | 120 | 200 |
| Small-prop shadows | off | off | on |
| Non-essential dynamic lights (budget) | 4 | 8 | 16 |
| Particle scale | 0.4 | 0.75 | 1.0 |
| Impact-decal lifetime scale | 0.5 | 0.8 | 1.0 |
| Environment render fidelity | Performance | Automatic | Precise |
| Viewmodel render fidelity | Automatic | Precise | Precise |
| Reflections | off | on | on |

**Always on, every tier (never downgraded):** enemy/character rendering and readability, the
first-person viewmodel presence, ammo/health HUD, hit feedback, and core weapon/impact audio.

## How systems consume it

`QualityController` applies the two truly-global settings itself (`Lighting.Technology`,
`Lighting.GlobalShadows`) and fires `Changed(tier, settings)`. Every other visual system is
**tier-aware by reading `QualityController:GetSettings()`** and/or subscribing to `Changed`:

- **Environment/props** — set `MeshPart.RenderFidelity` from `EnvRenderFidelity`; disable
  `CastShadow` on small props when `SmallPropShadows` is false.
- **Impact VFX** — scale emitter `Rate`/count by `ParticleScale`; scale decal lifetime by
  `DecalLifetimeScale`.
- **Authored dynamic lights** — keep the active count within `MaxDynamicLights`, prioritizing
  gameplay-relevant lights.
- **Viewmodel** — keep `ViewmodelRenderFidelity` high; the viewmodel is the last thing to scale.

## Auto and adaptive behavior

`Auto` (the default selection) resolves to `AutoFallbackTier` (**Medium** for the slice) until
device auto-detection is wired. `QualityLogic.stepTier` supports an adaptive downgrade (drop a
tier if sustained frame-time is poor) and a settings-UI stepper. A settings UI to pick
Auto/Low/Medium/High is a later task; the manager already accepts `SetSelection`.

## Rule

If a tier change would reduce **competitive visibility or input responsiveness**, it is out of
scope for that setting. Quality tiers scale *fidelity*, never *fairness*.
