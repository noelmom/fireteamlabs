"""Meshy image-to-3D client: create a task from local image(s), poll, download.

Usage: MESHY_API_KEY=... python meshy_gen.py <out_prefix> <img1> [img2 ...]

One image -> /openapi/v1/image-to-3d ; multiple -> /openapi/v1/multi-image-to-3d.
Downloads the result GLB (+ FBX if present) to <out_prefix>.glb.
The API key is read from the env; never printed.
"""

import base64
import mimetypes
import os
import sys
import time

import requests

API = "https://api.meshy.ai/openapi/v1"
KEY = os.environ["MESHY_API_KEY"]
HDR = {"Authorization": f"Bearer {KEY}"}

prefix = sys.argv[1]
images = sys.argv[2:]


def data_uri(path):
    mime = mimetypes.guess_type(path)[0] or "image/png"
    with open(path, "rb") as f:
        return f"data:{mime};base64," + base64.b64encode(f.read()).decode()


uris = [data_uri(p) for p in images]

if len(uris) == 1:
    url = f"{API}/image-to-3d"
    body = {"image_url": uris[0]}
else:
    url = f"{API}/multi-image-to-3d"
    body = {"image_urls": uris}

body.update({
    "should_texture": True,
    "enable_pbr": True,
    "should_remesh": True,
    "topology": "triangle",
    "target_polycount": 60000,
})

r = requests.post(url, headers=HDR, json=body, timeout=60)
if r.status_code >= 300:
    print("CREATE FAILED", r.status_code, r.text[:400])
    sys.exit(1)
task_id = r.json().get("result")
print("task:", task_id, "| endpoint:", url.rsplit("/", 1)[1])

get_url = f"{url}/{task_id}"
last = None
for _ in range(180):  # up to ~15 min
    time.sleep(5)
    s = requests.get(get_url, headers=HDR, timeout=60).json()
    status, prog = s.get("status"), s.get("progress", 0)
    if (status, prog) != last:
        print(f"  {status} {prog}%")
        last = (status, prog)
    if status == "SUCCEEDED":
        model = s.get("model_urls", {})
        for fmt in ("glb", "fbx", "obj"):
            u = model.get(fmt)
            if u:
                data = requests.get(u, timeout=120).content
                out = f"{prefix}.{fmt}"
                with open(out, "wb") as f:
                    f.write(data)
                print("downloaded", out, len(data), "bytes")
        tex = s.get("texture_urls") or []
        print("textures:", len(tex), "| credits left check separately")
        sys.exit(0)
    if status in ("FAILED", "CANCELED", "EXPIRED"):
        print("TASK", status, s.get("task_error"))
        sys.exit(1)
print("TIMEOUT waiting for task")
sys.exit(1)
