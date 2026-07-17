# Cryo Foundry skybox

A stylized ice-world cubemap for the Cryo Foundry sector. Source textures live
in `assets/skybox/cryo-foundry/`.

## Files

| File | Roblox `Sky` property |
| --- | --- |
| `SkyboxFt.png` | `SkyboxFt` (front, −Z) |
| `SkyboxBk.png` | `SkyboxBk` (back, +Z) |
| `SkyboxLf.png` | `SkyboxLf` (left, −X) |
| `SkyboxRt.png` | `SkyboxRt` (right, +X) |
| `SkyboxUp.png` | `SkyboxUp` (top, +Y) |
| `SkyboxDn.png` | `SkyboxDn` (bottom, −Y) |

`equirect-source.png` is the 360° panorama the faces were derived from;
`skybox_convert.py` regenerates the six faces from it (see the folder README).

## How to see it in Roblox

The six faces must be uploaded to Roblox to get asset IDs (this can't be done
outside Studio):

1. In Studio, open **Asset Manager → Images → Add**, and import the six
   `Skybox*.png` files. Each gets a `rbxassetid://` id.
2. Add a **`Sky`** object under **Lighting** and set each `Skybox*` property to
   the matching uploaded id (table above).
3. Set `CelestialBodiesShown = false` (the sun/aurora are baked into the
   textures) if you don't want a second sun.

### Wiring it through Rojo (optional)

Once the six ids exist, add the Sky to `default.project.json` under Lighting so
it's version-controlled:

```json
"Lighting": {
  "$className": "Lighting",
  "CryoFoundrySky": {
    "$className": "Sky",
    "$properties": {
      "SkyboxFt": "rbxassetid://<FT_ID>",
      "SkyboxBk": "rbxassetid://<BK_ID>",
      "SkyboxLf": "rbxassetid://<LF_ID>",
      "SkyboxRt": "rbxassetid://<RT_ID>",
      "SkyboxUp": "rbxassetid://<UP_ID>",
      "SkyboxDn": "rbxassetid://<DN_ID>",
      "CelestialBodiesShown": false
    }
  }
}
```

It is intentionally **not** wired in yet — placeholder ids would replace the
default sky with a blank one until the real ids are filled in.

## Notes and known limitations

- Stylized/first-pass quality. The source panorama is 3:2 rather than a true
  2:1 equirectangular, so the horizon has slight waviness at the face seams —
  acceptable for a distant backdrop, improvable by regenerating a cleaner 2:1
  source.
- If faces look mirrored or rotated in Studio, the face orientation convention
  in `skybox_convert.py` needs a per-face flip — tell me what's off and it's a
  one-line change plus a reconvert.
- Generated with codex's built-in `image_gen` tool (ChatGPT auth). Superseded
  versions go to `earlyartwork/archived/` per the asset workflow.
