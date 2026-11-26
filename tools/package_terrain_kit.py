"""Bundle generated materials, reusable sprites, native Godot helpers and previews."""
from pathlib import Path
import json
import shutil
import zipfile

project = Path(__file__).resolve().parents[1]
kit = project / "assets/terrain_kit"
catalog_path = kit / "catalog.json"
catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
props = kit / "props"
props.mkdir(exist_ok=True)
mapping = {}
for index, source in enumerate(catalog["sources"]):
    path = project / source.removeprefix("res://")
    relative = f"props/{index:03d}_{path.name}"
    shutil.copy2(path, kit / relative)
    mapping[source] = relative
for sprite in catalog["sprites"]:
    sprite["file"] = mapping[sprite["source"]]
    rect = ", ".join(str(x) for x in sprite["region"])
    anchor = ", ".join(str(x) for x in sprite["anchor"])
    resource = props / (sprite["id"] + ".tres")
    resource.write_text(
        '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Texture2D" path="res://assets/terrain_kit/{sprite["file"]}" id="1"]\n\n'
        '[resource]\natlas = ExtResource("1")\n'
        f'region = Rect2({rect})\nfilter_clip = true\n'
        f'metadata/ground_anchor = Vector2({anchor})\n', encoding="utf-8")
    sprite["resource"] = "props/" + resource.name
catalog_path.write_text(json.dumps(catalog, indent=2), encoding="utf-8")
archive = project.parent / "outputs/CheerfulGarden-Terrain-Asset-Kit.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
    for path in kit.rglob("*"):
        if path.is_file() and path.suffix not in [".import", ".uid"]:
            bundle.write(path, "assets/terrain_kit/" + path.relative_to(kit).as_posix())
    for name in ["terrain_asset_kit.gd", "terrain_kit_preview.gd"]:
        bundle.write(project / "scripts" / name, "scripts/" + name)
    bundle.write(project / "scenes/TerrainKitPreview.tscn", "scenes/TerrainKitPreview.tscn")
    for name in ["terrain-kit-preview.png", "terrain-kit-zoom-2x.png", "terrain-kit-sprites.png"]:
        path = project.parent / "outputs" / name
        if path.exists(): bundle.write(path, "previews/" + name)
print(f"PACKAGED {len(catalog['materials'])} materials and {len(catalog['sprites'])} sprites: {archive}")
