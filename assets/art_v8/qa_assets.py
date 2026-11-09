"""Independent release checks for the two art_v8 sprites.

Run from any directory: py assets/art_v8/qa_assets.py
Reads art_v8 only; this script makes no changes.
"""

import hashlib
import json
from pathlib import Path

from PIL import Image


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "_render_source"
EXPECTED = {"pig_pen", "goat_pen"}


def check_asset(entry, anchors, raw_anchors):
    asset_id = entry["id"]
    delivered_path = HERE / entry["file"]
    source_path = SOURCE / (asset_id + ".png")
    assert delivered_path.name == asset_id + ".png"
    assert delivered_path.is_file() and source_path.is_file()
    assert (HERE / "source_blender" / (asset_id + ".blend")).stat().st_size > 50_000
    data = delivered_path.read_bytes()
    assert entry["bytes"] == len(data)
    assert entry["sha256"] == hashlib.sha256(data).hexdigest()
    with Image.open(delivered_path) as sprite, Image.open(source_path) as original:
        sprite.load()
        original.load()
        assert sprite.mode == original.mode == "RGBA"
        assert original.size == (1024, 1024)
        assert list(sprite.size) == entry["dimensions_px"]
        assert max(sprite.size) <= 768
        assert 0 < min(sprite.size)
        alpha = sprite.getchannel("A")
        assert alpha.getextrema() == (0, 255)
        assert 0 < sum(alpha.histogram()[1:255]) == entry["antialiased_edge_pixels"]
        assert list(alpha.getbbox()) == entry["nontransparent_bounds_px"]
        assert alpha.crop((0, 0, sprite.width, 1)).getextrema()[1] == 0
        assert alpha.crop((0, sprite.height - 1, sprite.width, sprite.height)).getextrema()[1] == 0
        assert alpha.crop((0, 0, 1, sprite.height)).getextrema()[1] == 0
        assert alpha.crop((sprite.width - 1, 0, sprite.width, sprite.height)).getextrema()[1] == 0

        bounds = original.getchannel("A").getbbox()
        assert list(bounds) == entry["source_nontransparent_bounds_px"]
        crop = entry["source_crop_px"]
        assert len(crop) == 4
        assert crop[0] < bounds[0] < bounds[2] < crop[2]
        assert crop[1] < bounds[1] < bounds[3] < crop[3]
        expected_anchor = [
            round((raw_anchors[asset_id][0] - crop[0]) * sprite.width / (crop[2] - crop[0])),
            round((raw_anchors[asset_id][1] - crop[1]) * sprite.height / (crop[3] - crop[1])),
        ]
        assert entry["foot_anchor_px"] == anchors[asset_id] == expected_anchor
        assert 0 <= expected_anchor[0] < sprite.width
        assert 0 <= expected_anchor[1] < sprite.height
        print(f"PASS {asset_id}: {sprite.width}x{sprite.height} anchor={expected_anchor} "
              f"alpha=0..255 AA={entry['antialiased_edge_pixels']} SHA256=verified blend=present")


def main():
    manifest = json.loads((HERE / "manifest.json").read_text(encoding="utf-8"))
    anchors = json.loads((HERE / "anchors.json").read_text(encoding="utf-8"))
    raw_anchors = json.loads((SOURCE / "untrimmed_anchors.json").read_text(encoding="utf-8"))
    assert manifest["version"] == "8.0.0"
    entries = manifest["assets"]
    assert {entry["id"] for entry in entries} == set(anchors) == set(raw_anchors) == EXPECTED
    assert len(entries) == len(EXPECTED)
    with Image.open(HERE / "contact_sheet.jpg") as sheet:
        assert sheet.size == (1260, 640) and sheet.format == "JPEG"
    for entry in entries:
        check_asset(entry, anchors, raw_anchors)
    print("QA_COMPLETE: 2/2 assets valid; no alpha clipping; contact sheet and sources present")


if __name__ == "__main__":
    main()
