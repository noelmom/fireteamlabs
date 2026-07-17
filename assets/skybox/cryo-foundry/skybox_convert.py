#!/usr/bin/env python3
"""Convert an equirectangular panorama into 6 Roblox skybox cube faces.

Usage: python skybox_convert.py <equirect.png> <out_dir> [face_size]

Emits SkyboxFt/Bk/Lf/Rt/Up/Dn.png plus a cross-layout preview. The side-face
direction convention makes the horizon wrap continuously (Ft->Rt->Bk->Lf).
Roblox axes: Front=-Z, Back=+Z, Right=+X, Left=-X, Up=+Y, Down=-Y.
"""

import math
import sys

import numpy as np
from PIL import Image

FACES = ["Ft", "Bk", "Lf", "Rt", "Up", "Dn"]


def sample_equirect(equi: np.ndarray, dirs: np.ndarray) -> np.ndarray:
    h, w, _ = equi.shape
    x, y, z = dirs[..., 0], dirs[..., 1], dirs[..., 2]
    r = np.sqrt(x * x + y * y + z * z)
    lon = np.arctan2(x, -z)  # [-pi, pi]
    lat = np.arcsin(np.clip(y / r, -1.0, 1.0))  # [-pi/2, pi/2]
    u = (lon / (2 * math.pi) + 0.5) * w
    v = (0.5 - lat / math.pi) * h
    ui = np.clip(u.astype(np.int64), 0, w - 1)
    vi = np.clip(v.astype(np.int64), 0, h - 1)
    return equi[vi, ui]


def face_dirs(face: str, n: int) -> np.ndarray:
    a = np.linspace(-1, 1, n)  # texture left -> right
    b = np.linspace(-1, 1, n)  # texture top -> bottom
    aa, bb = np.meshgrid(a, b)
    one = np.ones_like(aa)
    if face == "Ft":  # -Z
        return np.stack([aa, -bb, -one], -1)
    if face == "Bk":  # +Z
        return np.stack([-aa, -bb, one], -1)
    if face == "Rt":  # +X
        return np.stack([one, -bb, aa], -1)
    if face == "Lf":  # -X
        return np.stack([-one, -bb, -aa], -1)
    if face == "Up":  # +Y
        return np.stack([aa, one, bb], -1)
    return np.stack([aa, -one, -bb], -1)  # Dn, -Y


def main() -> None:
    src, out_dir = sys.argv[1], sys.argv[2]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 1024

    equi = np.asarray(Image.open(src).convert("RGB"))
    faces = {}
    for face in FACES:
        img = sample_equirect(equi, face_dirs(face, n)).astype(np.uint8)
        faces[face] = img
        Image.fromarray(img).save(f"{out_dir}/Skybox{face}.png")

    blank = np.zeros((n, n, 3), np.uint8)
    cross = np.concatenate(
        [
            np.concatenate([blank, faces["Up"], blank, blank], 1),
            np.concatenate([faces["Lf"], faces["Ft"], faces["Rt"], faces["Bk"]], 1),
            np.concatenate([blank, faces["Dn"], blank, blank], 1),
        ],
        0,
    )
    Image.fromarray(cross).save(f"{out_dir}/skybox-preview-cross.png")
    print(f"wrote 6 faces + preview to {out_dir}")


if __name__ == "__main__":
    main()
