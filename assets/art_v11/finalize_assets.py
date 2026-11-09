"""Validate and finalize original art_v11 Blender renders for Godot.

Run: py assets/art_v11/finalize_assets.py
Outputs are confined to assets/art_v11; reads the v9 depot sprite for context.
"""

import hashlib
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "_render_source"
PADDING = 28
MAX_EDGE = 768
ASSETS = [
    ("pollinator_house", "Rumah Penyerbuk / Pollinator Lodge", 142),
    ("herb_drying_rack", "Rak Herba / Herb Drying Rack", 152),
    ("rainwater_collector", "Penampung Hujan / Rainwater Collector", 144),
    ("wildflower_crescent", "Taman Bunga Liar / Wildflower Border", 174),
]


def font(size):
    for path in ["C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"]:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def checkerboard(w, h, cell=24):
    image = Image.new("RGBA",(w,h),(246,247,239,255))
    d = ImageDraw.Draw(image)
    for y in range(0,h,cell):
        for x in range(0,w,cell):
            if ((x//cell)+(y//cell))%2:
                d.rectangle((x,y,x+cell-1,y+cell-1),fill=(227,235,219,255))
    return image


def prepare():
    raw = json.loads((RAW/"untrimmed_anchors.json").read_text(encoding="utf-8"))
    entries,anchors = [],{}
    for asset_id,description,display_width in ASSETS:
        path = RAW/(asset_id+".png")
        with Image.open(path) as original:
            original.load()
            if original.format!="PNG" or original.size!=(1024,1024) or original.mode!="RGBA":
                raise ValueError(f"{asset_id}: expected 1024x1024 RGBA Blender source")
            src=original.copy()
        a=src.getchannel("A")
        bounds=a.getbbox()
        if a.getextrema()!=(0,255) or not bounds:
            raise ValueError(f"{asset_id}: missing full alpha channel")
        if sum(a.histogram()[1:255])<100:
            raise ValueError(f"{asset_id}: missing anti-aliased alpha edge")
        if min(bounds[0],bounds[1],1024-bounds[2],1024-bounds[3])<=2:
            raise ValueError(f"{asset_id}: Blender canvas clipped at {bounds}")
        crop=(max(0,bounds[0]-PADDING),max(0,bounds[1]-PADDING),
              min(1024,bounds[2]+PADDING),min(1024,bounds[3]+PADDING))
        sprite=src.crop(crop)
        fullsize=sprite.size
        foot=[int(raw[asset_id][0])-crop[0],int(raw[asset_id][1])-crop[1]]
        if max(sprite.size)>MAX_EDGE:
            f=MAX_EDGE/max(sprite.size)
            outputsize=(round(sprite.width*f),round(sprite.height*f))
            sprite=sprite.resize(outputsize,Image.Resampling.LANCZOS)
            foot=[round(foot[0]*outputsize[0]/fullsize[0]),
                  round(foot[1]*outputsize[1]/fullsize[1])]
        if not (0<=foot[0]<sprite.width and 0<=foot[1]<sprite.height):
            raise ValueError(f"{asset_id}: anchor outside sprite: {foot}")
        a=sprite.getchannel("A")
        if a.getextrema()!=(0,255) or sum(a.histogram()[1:255])<50:
            raise ValueError(f"{asset_id}: exported alpha unexpectedly corrupted")
        for border in ((0,0,sprite.width,1),(0,sprite.height-1,sprite.width,sprite.height),
                       (0,0,1,sprite.height),(sprite.width-1,0,sprite.width,sprite.height)):
            if a.crop(border).getextrema()[1]!=0:
                raise ValueError(f"{asset_id}: crop edge cuts sprite {border}")
        dest=ROOT/(asset_id+".png")
        sprite.save(dest,format="PNG",optimize=True,compress_level=9)
        with Image.open(dest) as check:
            check.load()
            if check.mode!="RGBA" or check.size!=sprite.size:
                raise ValueError(f"{asset_id}: failed PNG roundtrip")
        anchors[asset_id]=foot
        entries.append({
            "id":asset_id,"file":dest.name,"description_id":description,
            "dimensions_px":list(sprite.size),"mode":"RGBA","transparent":True,
            "antialiased_edge_pixels":sum(a.histogram()[1:255]),
            "foot_anchor_px":foot,"source_size_px":[1024,1024],
            "source_nontransparent_bounds_px":list(bounds),
            "source_crop_px":list(crop),"cropped_source_dimensions_px":list(fullsize),
            "nontransparent_bounds_px":list(a.getbbox()),
            "suggested_width_px_at_450_viewport":display_width,
            "suggested_godot_scale":round(display_width/sprite.width,4),
            "bytes":dest.stat().st_size,
            "sha256":hashlib.sha256(dest.read_bytes()).hexdigest()
        })
        print("QA_PASS",asset_id,sprite.size,"foot",foot,
              "antialias",entries[-1]["antialiased_edge_pixels"],flush=True)
    (ROOT/"anchors.json").write_text(json.dumps(anchors,indent=2)+"\n",encoding="utf-8")
    (ROOT/"manifest.json").write_text(json.dumps({
        "version":"11.0.0",
        "collection":"Kebun Ceria - original decorative farm series",
        "camera":"Blender 5.2 EEVEE, orthographic 3/4 at (7,-9,8); 1024x1024 RGBA",
        "source":"Procedural meshes created specifically for this project",
        "license_note":"Original geometry and materials. No Supercell assets or logos.",
        "crop_padding_px":PADDING,"max_export_edge_px":MAX_EDGE,
        "anchor_definition":"Pixel from top-left of cropped PNG to model ground origin",
        "use":"Static decorative drawables; integration left to farm-view programmer.",
        "assets":entries
    },ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    return entries


def contact_sheet(entries):
    canvas=Image.new("RGB",(1540,1270),(250,249,237))
    draw=ImageDraw.Draw(canvas)
    draw.text((40,25),"KEBUN CERIA   /   ART V11",font=font(43),fill=(48,88,61))
    draw.text((42,81),"Original farm-world decorations   |   identical isometric camera   |   alpha + anchor QA",
              font=font(19),fill=(93,107,86))
    for index,entry in enumerate(entries):
        tile=checkerboard(714,472)
        with Image.open(ROOT/entry["file"]) as img:
            spr=img.convert("RGBA")
        spr.thumbnail((645,416),Image.Resampling.LANCZOS)
        left=(714-spr.width)//2
        top=(472-spr.height)//2
        tile.alpha_composite(spr,(left,top))
        foot=entry["foot_anchor_px"]
        fx=left+round(foot[0]*spr.width/entry["dimensions_px"][0])
        fy=top+round(foot[1]*spr.height/entry["dimensions_px"][1])
        ImageDraw.Draw(tile).ellipse((fx-5,fy-5,fx+5,fy+5),
                                   fill="white",outline="#d36347",width=3)
        x=30+(index%2)*755
        y=132+(index//2)*554
        canvas.paste(tile.convert("RGB"),(x,y))
        draw.text((x+7,y+484),entry["description_id"],font=font(23),fill=(48,86,58))
        draw.text((x+7,y+519),
                  f'{entry["file"]}  {entry["dimensions_px"]}  anchor {foot}',
                  font=font(17),fill=(94,108,89))
    canvas.save(ROOT/"contact_sheet.jpg",quality=93,optimize=True,subsampling=0)


def anchored_overlay(background, asset_path, center, width):
    with Image.open(asset_path) as source:
        sprite=source.convert("RGBA")
    manifest=json.loads((asset_path.parent/"manifest.json").read_text(encoding="utf-8"))
    match=next(x for x in manifest["assets"] if x["file"]==asset_path.name)
    anchor=match["foot_anchor_px"]
    factor=width/sprite.width
    newsize=(round(sprite.width*factor),round(sprite.height*factor))
    sprite=sprite.resize(newsize,Image.Resampling.LANCZOS)
    x=center[0]-round(anchor[0]*factor)
    y=center[1]-round(anchor[1]*factor)
    shadow=Image.new("RGBA",background.size,(0,0,0,0))
    ImageDraw.Draw(shadow).ellipse((center[0]-width*.40,center[1]-14,
                                  center[0]+width*.40,center[1]+18),
                                 fill=(41,87,58,29))
    background.alpha_composite(shadow)
    background.alpha_composite(sprite,(x,y))


def world_preview(entries):
    """Representative farm composition with readable sprite size and foot anchors."""
    rng=random.Random(210611)
    world=Image.new("RGBA",(1440,910),(161,214,126,255))
    d=ImageDraw.Draw(world)
    for i in range(150):
        x,y=rng.randrange(15,1430),rng.randrange(30,890)
        if 445<y<685 and 420<x<1400:
            continue
        c="#91c97d" if i%3 else "#b7d894"
        d.line((x,y,x-3,y-10),fill=c,width=2)
        d.line((x,y,x+4,y-8),fill=c,width=2)
    # Forked sandy lane / stonework in gameplay's pale terracotta palette.
    d.polygon([(110,750),(345,630),(690,570),(1110,580),(1410,690),
               (1440,826),(1070,707),(650,696),(320,765),(150,872)],
              fill=(223,192,143,255))
    d.line([(108,752),(345,633),(690,575),(1110,584),(1400,694)],
           fill=(246,217,166,255),width=8,joint="curve")
    for i in range(38):
        x=370+(i%19)*42
        y=642+(i//19)*33+int(12*math.sin(i))
        d.polygon([(x,y),(x+28,y-9),(x+44,y+3),(x+15,y+14)],
                  fill=(235,215,176,255),outline=(204,173,134,255))
    d.ellipse((80,110,470,430),fill=(153,206,114,255),outline=(139,193,102,255),width=12)
    d.ellipse((660,100,970,400),fill=(149,206,124,255),outline=(130,190,102,255),width=11)
    d.ellipse((950,290,1310,510),fill=(151,205,121,255),outline=(130,188,102,255),width=10)
    anchored_overlay(world,ROOT/"pollinator_house.png",(280,490),274)
    anchored_overlay(world,ROOT/"herb_drying_rack.png",(600,510),265)
    anchored_overlay(world,ROOT/"rainwater_collector.png",(930,490),270)
    anchored_overlay(world,ROOT/"wildflower_crescent.png",(560,815),280)
    depot=ROOT.parent/"art_v9"/"delivery_depot.png"
    if depot.exists():
        anchored_overlay(world,depot,(1180,732),356)
    d=ImageDraw.Draw(world)
    d.rounded_rectangle((32,24,482,119),radius=26,fill=(255,247,221,244))
    d.text((58,44),"KEBUN CERIA  •  ART V11",font=font(30),fill=(47,100,70))
    d.text((60,83),"COMPOSITE / SCALE REFERENCE",font=font(16),fill=(91,107,82))
    world.convert("RGB").save(ROOT/"farm_composite_preview.jpg",quality=95,subsampling=0)


def main():
    entries=prepare()
    contact_sheet(entries)
    world_preview(entries)
    print("ART_V11_COMPLETE",len(entries),"sprites, Blender sources, alpha+anchors, contact sheet, farm composite")


if __name__=="__main__":
    main()
