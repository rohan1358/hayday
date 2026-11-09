"""Crop Blender renders, validate alpha and anchors, prepare art_v5 delivery.

Run from anywhere: py assets/art_v5/finalize_assets.py
Requires Pillow; reads only art_v5/_render_source, writes only art_v5.
"""

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "_render_source"
PADDING = 28
MAX_EDGE_PX = 768  # keep GPU upload and decoded RGBA memory modest on Android
ASSETS = [
    ("wooden_crates", "Peti kayu isi panen", 194),
    ("hay_stack", "Tumpukan jerami panen", 178),
    ("flower_patch", "Hamparan bunga kebun", 173),
    ("decorative_pond", "Kolam kecil teratai", 204),
    ("rustic_lamp", "Lampu lentera pedesaan", 150),
]


def font(size):
    candidates = [
        Path("C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def checkerboard(width, height, square=20):
    output = Image.new("RGBA", (width, height), (246, 247, 240, 255))
    d = ImageDraw.Draw(output)
    for y in range(0, height, square):
        for x in range(0, width, square):
            if (x // square + y // square) % 2:
                d.rectangle((x, y, min(x + square - 1, width - 1), min(y + square - 1, height - 1)), fill=(227, 235, 218, 255))
    return output


def main():
    raw_anchors = json.loads((SOURCE / "untrimmed_anchors.json").read_text(encoding="utf-8"))
    anchors = {}
    entries = []
    canvas_w, canvas_h = 1260, 1570
    sheet = Image.new("RGB", (canvas_w, canvas_h), (248, 250, 239))
    draw = ImageDraw.Draw(sheet)
    draw.text((35, 24), "KEBUN CERIA  /  ART V5", font=font(36), fill=(53, 83, 52))
    draw.text((36, 72), "Five decorative farm props | transparent sprite + ground pivot QA", font=font(18), fill=(92, 107, 83))

    for index, (asset_id, description, desired_width) in enumerate(ASSETS):
        source_path = SOURCE / (asset_id + ".png")
        with Image.open(source_path) as original:
            original.load()
            if original.format != "PNG" or original.mode != "RGBA" or original.size != (1024, 1024):
                raise ValueError(f"{source_path}: expected 1024x1024 RGBA PNG")
            image = original.copy()

        alpha = image.getchannel("A")
        low, high = alpha.getextrema()
        bounds = alpha.getbbox()
        if low != 0 or high != 255 or not bounds:
            raise ValueError(f"{asset_id}: full-alpha PNG with transparent margin required, got {low}..{high}, {bounds}")
        if not sum(alpha.histogram()[1:255]):
            raise ValueError(f"{asset_id}: no partially transparent anti-aliased edge pixels")
        if bounds[0] < 2 or bounds[1] < 2 or bounds[2] > 1022 or bounds[3] > 1022:
            raise ValueError(f"{asset_id}: render clipped by 1024px camera canvas: {bounds}")
        if asset_id not in raw_anchors or len(raw_anchors[asset_id]) != 2:
            raise ValueError(f"{asset_id}: missing untrimmed foot anchor")

        crop = (
            max(0, bounds[0] - PADDING),
            max(0, bounds[1] - PADDING),
            min(image.width, bounds[2] + PADDING),
            min(image.height, bounds[3] + PADDING),
        )
        sprite = image.crop(crop)
        foot = [int(raw_anchors[asset_id][0]) - crop[0], int(raw_anchors[asset_id][1]) - crop[1]]
        uncapped_size = list(sprite.size)
        if max(sprite.size) > MAX_EDGE_PX:
            factor = MAX_EDGE_PX / max(sprite.size)
            size = (round(sprite.width * factor), round(sprite.height * factor))
            sprite = sprite.resize(size, Image.Resampling.LANCZOS)
            foot = [round(foot[0] * size[0] / uncapped_size[0]), round(foot[1] * size[1] / uncapped_size[1])]
        if not (0 <= foot[0] < sprite.width and 0 <= foot[1] < sprite.height):
            raise ValueError(f"{asset_id}: foot anchor outside cropped image {foot}, {sprite.size}")
        if sprite.getchannel("A").getextrema() != (0, 255):
            raise ValueError(f"{asset_id}: cropped PNG lost transparency or opacity")
        sa = sprite.getchannel("A")
        if sa.crop((0,0,sprite.width,1)).getextrema()[1] or sa.crop((0,sprite.height-1,sprite.width,sprite.height)).getextrema()[1]:
            raise ValueError(f"{asset_id}: image top/bottom edge is clipped")
        if sa.crop((0,0,1,sprite.height)).getextrema()[1] or sa.crop((sprite.width-1,0,sprite.width,sprite.height)).getextrema()[1]:
            raise ValueError(f"{asset_id}: image left/right edge is clipped")

        dest = ROOT / (asset_id + ".png")
        sprite.save(dest, format="PNG", optimize=True, compress_level=9)
        with Image.open(dest) as check:
            check.load()
            if check.size != sprite.size or check.mode != "RGBA" or check.getchannel("A").getextrema() != (0, 255):
                raise ValueError(f"{asset_id}: exported file did not pass round-trip alpha QA")

        anchors[asset_id] = foot
        entries.append({
            "id": asset_id,
            "file": dest.name,
            "description_id": description,
            "dimensions_px": [sprite.width, sprite.height],
            "mode": "RGBA",
            "transparent": True,
            "antialiased_edge_pixels": sum(sa.histogram()[1:255]),
            "foot_anchor_px": foot,
            "source_size_px": [1024, 1024],
            "source_nontransparent_bounds_px": list(bounds),
            "source_crop_px": list(crop),
            "cropped_source_dimensions_px": uncapped_size,
            "nontransparent_bounds_px": list(sprite.getchannel("A").getbbox()),
            "suggested_width_px_at_450_viewport": desired_width,
            "suggested_godot_scale": round(desired_width / sprite.width, 4),
            "bytes": dest.stat().st_size,
            "sha256": hashlib.sha256(dest.read_bytes()).hexdigest(),
        })

        col, row = index % 2, index // 2
        tx, ty = 34 + col * 624, 132 + row * 468
        tile = checkerboard(594, 396)
        preview = sprite.copy()
        preview.thumbnail((554, 352), Image.Resampling.LANCZOS)
        left, top = (594 - preview.width) // 2, (396 - preview.height) // 2
        tile.alpha_composite(preview, (left, top))
        ax = left + round(foot[0] * preview.width / sprite.width)
        ay = top + round(foot[1] * preview.height / sprite.height)
        td = ImageDraw.Draw(tile)
        td.ellipse((ax - 6, ay - 6, ax + 6, ay + 6), fill=(255, 249, 247, 255), outline=(192, 66, 52, 255), width=3)
        sheet.paste(tile.convert("RGB"), (tx, ty))
        draw.text((tx + 5, ty + 403), description, font=font(22), fill=(49, 77, 52))
        draw.text((tx + 5, ty + 433), f"{asset_id}.png   {sprite.width}x{sprite.height}   anchor {foot}", font=font(16), fill=(99, 105, 87))
        print(f"QA_PASS {asset_id} {sprite.width}x{sprite.height} alpha=0..255 bbox={bounds} anchor={foot} bytes={dest.stat().st_size}")

    (ROOT / "anchors.json").write_text(json.dumps(anchors, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (ROOT / "manifest.json").write_text(json.dumps({
        "version": "5.0.0",
        "collection": "Kebun Ceria original isometric farm art",
        "render": "Blender 5.2 EEVEE orthographic 3/4, transparent RGBA, 1024x1024 source",
        "crop_padding_px": PADDING,
        "max_export_edge_px": MAX_EDGE_PX,
        "anchor_definition": "pixels from top-left of the trimmed PNG to the ground contact point",
        "license_note": "Original procedural assets; no Supercell artwork used.",
        "assets": entries,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    sheet.save(ROOT / "contact_sheet.jpg", quality=93, optimize=True, subsampling=0)
    print(f"DELIVERY_COMPLETE {len(entries)} PNGs, anchors.json, manifest.json, contact_sheet.jpg")


if __name__ == "__main__":
    main()
