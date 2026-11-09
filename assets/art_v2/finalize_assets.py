"""Validate rendered transparent sprites and generate delivery metadata + preview.

Run after generate_assets.py, using Python with Pillow installed.
All outputs remain within this directory.
"""

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
ASSETS = [
    ("kitchen_cottage", "Rumah / dapur", 160),
    ("village_barn", "Gudang hasil panen", 165),
    ("apple_tree", "Pohon apel", 145),
    ("soil_plot_empty", "Petak tanah kosong", 158),
    ("wheat_plot_ready", "Petak gandum siap panen", 158),
    ("flower_garden", "Taman bunga", 154),
]


def checkerboard(width, height, size=22):
    tile = Image.new("RGB", (width, height), "#f5f0e2")
    draw = ImageDraw.Draw(tile)
    for y in range(0, height, size):
        for x in range(0, width, size):
            if (x // size + y // size) % 2:
                draw.rectangle((x, y, x + size - 1, y + size - 1), fill="#e9e4d5")
    return tile


def main():
    anchors = json.loads((ROOT / "anchors.json").read_text(encoding="utf-8"))
    sheet = Image.new("RGB", (1200, 1160), "#eff4e6")
    label_draw = ImageDraw.Draw(sheet)
    entries = []

    for idx, (name, purpose, display_width) in enumerate(ASSETS):
        path = ROOT / f"{name}.png"
        with Image.open(path) as input_image:
            input_image.load()
            if input_image.format != "PNG" or input_image.mode != "RGBA":
                raise ValueError(f"{path.name}: expected RGBA PNG")
            if input_image.size != (1024, 1024):
                raise ValueError(f"{path.name}: expected 1024x1024")
            image = input_image.copy()

        alpha = image.getchannel("A")
        amin, amax = alpha.getextrema()
        bounds = alpha.getbbox()
        if amin != 0 or amax != 255 or bounds is None:
            raise ValueError(f"{name}: no valid transparent/opaque sprite pixels")
        anchor = anchors[name]
        if len(anchor) != 2 or any(not 0 <= coord < 1024 for coord in anchor):
            raise ValueError(f"{name}: invalid ground anchor {anchor}")

        # Review image is composited on a checkerboard; delivered PNGs stay transparent.
        col, row = idx % 2, idx // 2
        tile = checkerboard(548, 346)
        resized = image.copy()
        resized.thumbnail((530, 340), Image.Resampling.LANCZOS)
        place_x = (tile.width - resized.width) // 2
        place_y = (tile.height - resized.height) // 2
        tile.paste(resized, (place_x, place_y), resized)
        sheet.paste(tile, (24 + col * 600, 17 + row * 382))
        label_draw.text((30 + col * 600, 366 + row * 382), f"{name}  |  {purpose}", fill="#3a4636")

        entry = {
            "id": name,
            "file": path.name,
            "description_id": purpose,
            "dimensions_px": [1024, 1024],
            "mode": "RGBA",
            "transparent": True,
            "foot_anchor_px": anchor,
            "nontransparent_bounds_px": list(bounds),
            "suggested_width_px_at_450_viewport": display_width,
            "suggested_godot_scale": round(display_width / 1024, 4),
            "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }
        entries.append(entry)
        print(f"QA_PASS {name} {image.width}x{image.height} RGBA alpha={amin}..{amax} anchor={anchor} bbox={bounds}")

    manifest = {
        "version": "2.0.0",
        "collection": "Kebun Ceria original farm art",
        "camera": "shared orthographic 3/4 isometric-like view, facing +Y",
        "source": "generate_assets.py (Blender 5.2) + finalize_assets.py (Pillow)",
        "projection_anchor": "pixel of world origin projected on each image; used as object ground/pivot",
        "coordinate_system": "PNG upper-left origin, x positive right, y positive down",
        "assets": entries,
    }
    (ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    sheet.save(ROOT / "contact_sheet.jpg", quality=93, subsampling=0)
    print(f"QA_PASS {len(entries)} sprites; wrote manifest.json and contact_sheet.jpg")


if __name__ == "__main__":
    main()
