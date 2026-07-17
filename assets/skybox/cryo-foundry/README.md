# Cryo Foundry skybox source

Six cube faces (`SkyboxFt/Bk/Lf/Rt/Up/Dn.png`, 1024²) for the Cryo Foundry sky,
plus the `equirect-source.png` panorama they were derived from and the
`skybox_convert.py` converter.

See `docs/art-direction/skybox.md` for the Roblox `Sky` property mapping and
upload steps.

## Regenerate the faces

```sh
python skybox_convert.py equirect-source.png <out_dir> 1024
```

Produces the six faces and a `skybox-preview-cross.png` (a 4×3 cross layout to
eyeball horizon continuity). The side-face convention keeps the horizon
continuous Ft→Rt→Bk→Lf; Roblox axes are Front=−Z, Back=+Z, Right=+X, Left=−X,
Up=+Y, Down=−Y.

## Provenance

`equirect-source.png` generated with codex's built-in `image_gen` tool
(ChatGPT auth) from an ice-world panorama prompt. Stylized first pass; see the
limitations note in the art-direction doc.
