# Fireteam Labs — Art Direction

Fireteam Labs is a **grounded, high-fidelity tactical science-fiction arena FPS**. The
presentation target is a believable, engineered near-future combat-testing program on
Island X — *not* stylized Roblox and *not* exaggerated fantasy. Quality benchmark: modern
Roblox tactical shooters (e.g. TTK) as a *reference for perceived polish only* — no assets,
maps, UI, weapons, animations, audio, or branding are copied from any existing game.

Gameplay is unchanged by this pivot (see the Visual Direction Amendment in `MASTERPLAN.md`).

## Visual pillars

1. **Engineered, not magical.** Sci-fi tech looks manufactured, serviceable, powered — panels,
   fasteners, cabling, indicator lights. No glowing-everything, no arcane energy.
2. **Physically believable, lived-in.** Surfaces show use: wear, grime, scuffs, condensation,
   frost. Spaces read as built and operated.
3. **Cold industrial atmosphere.** A classified research installation in an extreme-cold
   environment: refrigerated halls, concrete service corridors, exterior frozen courtyards.
4. **Competitive readability above all.** Realism never costs clarity. Enemies stay visible,
   silhouettes stay clean, important spaces stay predictably lit.
5. **Authored, cohesive lighting and materials** do the heavy lifting — not polycount.

## Environment references (from the benchmark corridor)

Painted-metal wall panels with seams; exposed ceiling ductwork, pipes, cable trays; grated
metal floors; wire storage shelving; labelled crates; wall junction panels with cabling and
indicator lights; glowing EXIT signage; recessed fluorescent fixtures; frosted/dirty glass
observation windows; blast doors; decontamination airlocks. Palette: desaturated steel-blue
and grey with cold cyan practicals, warm sodium light only in select service areas.

## Character presentation

Three classes are **cosmetic tactical-operator identities** with **identical gameplay stats**
(health, shield, movement, hitbox, weapon access, grenade count). Silhouette differences are
visual only and must fit inside the shared competitive hitbox.

- **Specter** — recon / rapid-response: lightweight plate carrier, compact helmet/headset,
  streamlined panels, recon kit, low-profile.
- **Conduit** — experimental-energy systems: technical harness, insulated gear, diagnostic
  modules, restrained illuminated indicators, protective gloves.
- **Bulwark** — hardened entry/containment: heavier-looking shell, reinforced shoulders/chest,
  breaching tools — **all designed inside the shared hitbox; no gameplay advantage.**

## Weapon presentation

Original near-future firearms that look manufactured and functional: correct proportions,
convincing material separation (polymer body vs. gunmetal), functional moving parts, realistic
sight alignment, restrained illuminated elements, readable silhouettes. Do not reproduce
weapons from Destiny, TTK, Call of Duty, Ready or Not, or any existing game.

## Lighting

Roblox **Future** lighting as the high target, with scalable fallbacks. Authored practical
sources (fluorescents, emergency lights, equipment indicators, EXIT signs), cold natural light
near exterior openings, warm utility light in select service areas, subtle specular response,
deliberate contrast between safe and dangerous spaces. **Avoid:** excessive bloom,
visibility-killing fog, pitch-black corners, constant blur, heavy grade, competitive-unsafe
flashing. Cold color correction that preserves enemy visibility.

## Materials

A deliberate PBR system via `SurfaceAppearance` (color / normal / roughness / metalness, plus
emissive where justified). Reusable materials: painted metal, bare/brushed metal, concrete,
rubber, polymer, tactical fabric, frosted glass, dirty glass, cardboard, ice/snow, industrial
flooring, emissive panels. Consistent texel-density standard; no oversized textures. See
`TECHNICAL_ART_PIPELINE.md`.

## Color palette (provisional)

| Role | Approx. |
| --- | --- |
| Base structure | desaturated steel-blue / grey `#4a545e`–`#8a96a2` |
| Concrete | warm-grey `#9a968e` |
| Cold practicals / ice | cyan `#5ab0ff` |
| Warm service light | sodium `#e0a860` |
| Hazard / power | amber `#e6a83c` / red `#ff5c5c` |
| Team A / Team B | (readability-first, high-contrast; TBD) |

## Prohibited

Excess neon; oversized fantasy armor; glowing surfaces everywhere; cartoon proportions;
toy-like weapons; default/generic Roblox materials; highly reflective, all-black, or
camouflage-heavy characters that vanish into the environment.

## Competitive-readability requirements

Distinct team identification; consistent enemy readability; controlled background contrast;
clean silhouettes; optional team-colored indicators; restrained outlines only when necessary;
predictable lighting around key combat areas. If a realism choice hurts readability, readability
wins.
