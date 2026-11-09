"""Original production buildings for Kebun Ceria / Art V7.

Reproduce with Blender 5.2:
  blender --background --factory-startup --python assets/art_v7/generate_assets.py

Only writes into art_v7/_render_source. Shared art_v2 primitives are read only.
"""

import json
import math
import random
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "_render_source"
sys.dont_write_bytecode = True
sys.path.insert(0, str(HERE.parent / "art_v2"))
import generate_assets as b

RES = 1024
RNG = random.Random(715070)


def materials():
    b.setup_materials()
    colors = {
        "bakery_wall": "#f8ddb0", "bakery_light": "#fff0c9",
        "bakery_shadow": "#d9ad7b", "bakery_roof": "#ca6954",
        "bakery_tile": "#e99069", "bakery_tile2": "#eeac7b",
        "bakery_dark": "#98534b", "cocoa": "#694434",
        "bun": "#eeb56a", "bun_glow": "#ffda92", "pastry": "#cd8d58",
        "milk_wall": "#f3eacb", "milk_light": "#fff7e0",
        "milk_shadow": "#d4d5b7", "teal_roof": "#5fa29c",
        "teal_tile": "#8fc4bb", "teal_dark": "#477e7a",
        "sea_blue": "#7bb7be", "porcelain": "#f9f6e5",
        "milk_blue": "#81b7be", "milk_copper": "#cd9d65",
        "feed_wall": "#dfb777", "feed_light": "#f5d28c",
        "feed_shadow": "#b78c59", "sage_roof": "#708d6f",
        "sage_tile": "#a1b48a", "sage_dark": "#536b52",
        "grain_gold": "#e7b961", "grain_high": "#ffe19a",
        "grain_dark": "#a77442", "silo_stave": "#d29b5b",
        "silo_light": "#e9b774", "silo_dark": "#936746",
        "oak": "#b7824e", "oak_light": "#e4b579",
        "oak_dark": "#79513a", "oak_deep": "#593d31",
        "iron": "#565e5a", "iron_sun": "#8b9290",
        "copper": "#ce9760", "copper_light": "#efba7d",
        "stone": "#b8b39e", "stone_light": "#e1d6b8",
        "stone_dark": "#8d9785", "pot": "#c6765c",
        "leaf": "#62a36f", "leaf_light": "#a0c87d",
        "berry": "#e58a91", "marigold": "#f0c36a",
        "glass": "#8fbdba", "glass_dark": "#56949a",
    }
    b.M.update({name: b.material(name, col) for name, col in colors.items()})


def box(name, xyz, dims, col, bevel=.025):
    return b.box(name, xyz, dims, col, bevel)


def ball(name, xyz, radii, col, seg=16):
    return b.orb(name, xyz, radii, col, seg, 9)


def beam(name, start, end, r, col, verts=9):
    return b.pole(name, start, end, r, col, verts)


def cylinder(name, xyz, r, h, col, vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=r, depth=h, location=xyz)
    obj = bpy.context.object
    obj.name = name
    b.assign(obj, col)
    return obj


def torus(name, xyz, radius, width, col, tilt=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=32, minor_segments=8,
                                     major_radius=radius, minor_radius=width, location=xyz)
    ob = bpy.context.object
    ob.name = name
    if tilt:
        ob.rotation_euler = tilt
    b.assign(ob, col)
    return ob


def text_front(label, xyz, size, col):
    curve = bpy.data.curves.new("carved label " + label, "FONT")
    curve.body = label
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = size
    curve.extrude = .004
    curve.bevel_depth = .001
    obj = bpy.data.objects.new("painted lettering " + label, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = xyz
    obj.rotation_euler[0] = math.pi / 2
    b.assign(obj, col)


def base(width, depth, theme):
    box("polished irregular stone foundation", (0, 0, .17), (width + .13, depth + .13, .32), "stone_dark", .11)
    box("sun warmed stone skirting", (0, 0, .32), (width + .19, depth + .19, .11), "stone_light", .045)
    for side in (-1, 1):
        for i in range(6):
            xx = -width / 2 + .26 + i * (width - .52) / 5
            box("offset masonry plinth stone", (xx, side * (depth / 2 + .094), .13),
                ((width - .28) / 5.5, .065, .18), "stone" if i % 3 else "stone_light", .027)
    for x, y in [(-width / 2-.14, -.5), (width / 2 + .13, .7), (-.7, depth / 2+.2)]:
        b.grass_tuft(x, y, .8)


def stucco(width, depth, height, wall, edge, trim):
    box("rounded production house plaster", (0, 0, .34+height/2), (width, depth, height), wall, .085)
    for x in (-width/2+.045, width/2-.045):
        box("front carved corner pilaster", (x, -depth/2-.033, .38+height/2), (.16, .08, height-.13), edge, .029)
    for z in (.52, .34+height-.07):
        box("front oak accent band", (0, -depth/2-.071, z), (width-.20, .09, .095), trim, .025)
    for z in (.58, .34+height-.09):
        box("right side oak accent band", (width/2+.047, 0, z), (.075, depth-.22, .08), trim, .019)


def gables(width, depth, eave, peak, col):
    b.gable_walls(width, depth, eave, peak, col)


def crafted_roof(width, depth, eave, peak, main, ridge, tile_a, tile_b):
    # This follows the shared pitched roof silhouette, with asymmetric handmade tiles.
    b.roof(width, depth, eave, peak, main, ridge)
    w = width/2 + .15
    d = depth/2 + .16
    incline = math.atan2(peak-eave, w)
    for side in (-1, 1):
        for row in range(5):
            fraction = (row + .58) / 5.5
            x = side*w*fraction
            z = peak - (peak-eave)*fraction + .028
            for col in range(7):
                y = -d+.19+(col+.22*(row%2))*(2*d-.32)/6.65
                shingle = box("hand glazed individual roof tile", (x,y,z),
                              (.28, .30, .035), tile_a if (row+col)%4 else tile_b, .026)
                shingle.rotation_euler[1] = -side*incline
                if row%2==0 and col%3==0:
                    ball("reflected tile highlight", (x,y-.035,z+.029),
                         (.060,.10,.016), tile_b, 9)
    beam("trimmed roof spine", (0,-d,peak+.045), (0,d,peak+.045), .068, ridge)


def door(x, front_y, bottom, width, height, col, trim, twin=False):
    mid = bottom + height/2
    box("deep arched doorway trim", (x,front_y-.045,mid),
        (width+.20, .16, height+.20), trim, .075)
    box("inner door dark reveal", (x,front_y-.135,mid),
        (width+.045,.062,height+.055), "oak_deep", .055)
    box("solid vertical board door", (x,front_y-.184,mid),
        (width-.035,.07,height-.035),col,.039)
    for j in range(1, 5):
        xx = x-width/2 + j*width/5
        beam("fine door board joint", (xx,front_y-.226,bottom+.12),
             (xx,front_y-.226,bottom+height-.10), .010, "oak_dark", 6)
    if twin:
        beam("double door center seam", (x,front_y-.233,bottom+.055),
             (x,front_y-.233,bottom+height-.06), .025, trim, 7)
        for dx in (-.085,.085):
            ball("pair of brass door knobs", (x+dx,front_y-.270,mid),(.038,.027,.042),"copper_light")
    else:
        ball("hand turned golden doorknob", (x+width*.29,front_y-.266,mid),
             (.050,.030,.050),"copper_light")
    box("doorstep stone", (x,front_y-.32,bottom+.055),
        (width+.38,.55,.14), "stone_light", .055)


def window(x, y, z, width=.62, height=.66, side=False):
    if not side:
        box("rounded glazed window frame", (x,y-.025,z), (width+.16,.105,height+.16),"oak_light",.044)
        box("soft reflective shop glass", (x,y-.100,z), (width,.042,height),"glass_dark",.026)
        box("window sky highlight", (x-width*.16,y-.124,z+height*.13),
            (width*.11,.017,height*.40),"glass",.011)
        beam("cross pane wooden mullion",(x,y-.136,z-height/2),(x,y-.136,z+height/2),.023,"bakery_light",7)
        beam("cross pane wooden sill",(x-width/2,y-.137,z),(x+width/2,y-.137,z),.023,"bakery_light",7)
        box("warm window planter shelf",(x,y-.185,z-height/2-.07),(width+.30,.26,.105),"oak",.023)
    else:
        box("right wall window frame",(x+.03,y,z),(.11,width+.16,height+.16),"oak_light",.042)
        box("reflective right wall glass",(x+.106,y,z),(.036,width,height),"glass",.023)
        beam("side window middle bar",(x+.13,y-width/2,z),(x+.13,y+width/2,z),.024,"bakery_light",7)
        beam("side window vertical bar",(x+.133,y,z-height/2),(x+.133,y,z+height/2),.023,"bakery_light",7)


def badge(label, y, z, color, frame, size=.24, width=1.40):
    box("raised hanging shop sign", (0,y,z), (width,.11,.41), frame, .075)
    box("beveled painted sign inset", (0,y-.065,z), (width-.11,.035,.31), color, .048)
    for x in (-width/2+.15,width/2-.15):
        ball("polished sign bolt",(x,y-.087,z),(.034,.018,.035),"copper_light",9)
    text_front(label,(0,y-.090,z-.01),size,"bakery_light")


def blossoms(x, y, tint="berry"):
    b.flower(x,y,.47,tint,.57)
    b.grass_tuft(x+.15,y+.08,.60)


def bread_loaf(x,y,z,scale=1.0):
    ball("fresh oven baked oval loaf",(x,y,z),(.27*scale,.18*scale,.15*scale),"bun",18)
    for k in (-1,0,1):
        xline=x+k*.07*scale
        beam("three decorative bread score cuts",(xline-.035*scale,y-.072*scale,z+.11*scale),
             (xline+.055*scale,y+.055*scale,z+.11*scale),.012*scale,"pastry",6)


def baking_shop():
    w,d,wh,roofpeak=3.12,2.51,2.06,3.38
    base(w,d,"stone")
    stucco(w,d,wh,"bakery_wall","bakery_light","oak_light")
    gables(w,d,2.40,roofpeak,"bakery_shadow")
    # Robust exposed bakehouse chimney behind the ridge.
    box("warm brick bakehouse oven chimney",(-.88,.40,3.20),(.48,.52,1.36),"bakery_dark",.045)
    for z in (2.70,2.98,3.26,3.51):
        beam("chimney cream lime mortar",(-1.135,.125,z),(-.625,.125,z),.015,"bakery_shadow",7)
    box("overhanging pale stone chimney rim",(-.88,.40,3.92),(.66,.67,.17),"stone_light",.048)
    box("dark oven flue opening",(-.88,.40,4.03),(.39,.40,.045),"oak_deep",.024)
    crafted_roof(w+.12,d+.13,2.43,3.47,"bakery_roof","bakery_dark","bakery_tile","bakery_tile2")
    front=-d/2
    door(-.96,front,.37,.68,1.45,"oak","oak_light")
    window(.62,front,1.43,.92,.77)
    badge("ROTI",front-.10,2.70,"bakery_dark","oak_dark",.285,1.42)
    # Copper-and-cream striped cloth awning directly above the display window.
    for stripe in range(7):
        ax=.12+(stripe+.5)*.154
        b.mesh("stretched scalloped bakery awning stripe",
               [(ax-.076,-1.40,2.05),(ax+.076,-1.40,2.05),
                (ax+.076,-2.09,1.81),(ax-.076,-2.09,1.81)],
               [(0,1,2,3)],"bakery_tile" if stripe%2 else "bakery_light")
        ball("soft scalloped bakery valance",(ax,-2.09,1.79),(.078,.06,.085),
             "bakery_tile" if stripe%2 else "bakery_light",10)
    beam("oak cloth awning supporting rod",(.10,-2.10,1.83),(1.22,-2.10,1.83),.028,"copper",8)
    window(w/2,.33,1.39,.53,.63,True)
    # Bread trolley and products create an instantly recognizable silhouette.
    box("front baked goods market shelf",(1.00,-2.18,.48),(1.09,.55,.15),"oak_light",.045)
    for side_x in (.58,1.42):
        box("baker table square legs",(side_x,-2.18,.25),(.09,.09,.43),"oak_dark",.015)
    for xx,yy in [(.68,-2.22),(.97,-2.20),(1.28,-2.18)]:
        bread_loaf(xx,yy,.66,.78)
    # Exterior flower pots and sweet rolls.
    for px,py in [(-1.55,-1.38),(1.50,-1.37)]:
        cylinder("clay pastry shop flower planter",(px,py,.24),.16,.29,"pot",12)
        ball("rounded blooming planter",(px,py,.48),(.21,.19,.18),"leaf",12)
        for dx in (-.12,.11):
            ball("rose planter blossom",(px+dx,py-.06,.57),(.055,.055,.05),"berry",10)
    blossoms(-1.66,.71)
    b.grass_tuft(1.65,.96,.72)


def milk_bottle(x,y,z,scale=1.0):
    cylinder("small cream milk bottle",(x,y,z+.115*scale),.081*scale,.23*scale,"porcelain",12)
    cylinder("milk bottle teal cap",(x,y,z+.247*scale),.071*scale,.035*scale,"teal_dark",12)
    box("milk bottle pastel label",(x,y-.082*scale,z+.115*scale),(.115*scale,.018,.10*scale),"milk_blue",.014)


def dairy_shop():
    w,d,wh,peak=3.06,2.56,2.08,3.48
    base(w,d,"stone")
    stucco(w,d,wh,"milk_wall","milk_light","teal_dark")
    gables(w,d,2.42,peak,"milk_shadow")
    crafted_roof(w+.12,d+.10,2.45,3.56,"teal_roof","teal_dark","teal_tile","milk_blue")
    front=-d/2
    door(.42,front,.37,1.17,1.58,"teal_dark","oak_light",twin=True)
    # Substantial wooden braces and inset panels mark it as a working dairy.
    for side in (-1,1):
        x=.42+side*.285
        beam("dairy barn door diagonal",(x-.22,front-.237,.54),
             (x+.22,front-.237,1.63),.038,"milk_light",7)
    window(-.94,front,1.54,.58,.63)
    badge("SUSU",front-.105,2.75,"teal_dark","oak_light",.275,1.40)
    window(w/2,.40,1.54,.64,.68,True)
    # Tall stainless cooling tank at the right face, distinctly different from bakery.
    tx,ty=1.90,.55
    cylinder("rounded bright milk cooling vat",(tx,ty,1.12),.54,1.51,"porcelain",28)
    cylinder("cooling tank lower rim",(tx,ty,.41),.56,.17,"stone_dark",28)
    cylinder("cooling tank upper lip",(tx,ty,1.91),.58,.16,"milk_blue",28)
    ball("domed chiller lid",(tx,ty,2.01),(.52,.52,.18),"milk_light",28)
    for band_h in (.66,1.44,1.79):
        torus("polished cooling vat horizontal band",(tx,ty,band_h),.54,.040,"milk_copper")
    for a in (.45,1.62,2.82,4.02,5.24):
        x=tx+.545*math.cos(a)
        y=ty+.545*math.sin(a)
        beam("fine metal condenser rivet line",(x,y,.69),(x,y,1.73),.012,"iron_sun",6)
    beam("cream tank drain tap",(tx+.15,ty-.51,.85),(tx+.15,ty-.82,.85),.063,"milk_copper")
    beam("short downward spout",(tx+.15,ty-.82,.85),(tx+.15,ty-.82,.66),.052,"milk_copper")
    # Milk crates and churns positioned in front of the doors.
    box("dairy blue delivery tray",(-.78,-1.92,.32),(.93,.52,.23),"teal_dark",.055)
    for xx in (-1.07,-.80,-.53):
        milk_bottle(xx,-1.95,.47,.90)
    for i,(xx,yy) in enumerate([(1.54,-1.52),(1.91,-1.68)]):
        cylinder("small milk churn metal can",(xx,yy,.42),.16,.57,"porcelain",16)
        cylinder("milk churn fitted lid",(xx,yy,.73),.18,.07,"teal_tile",16)
        torus("milk churn carrying ring",(xx,yy,.80),.082,.020,"iron_sun")
    blossoms(-1.58,.68,"marigold")
    b.grass_tuft(1.54,1.18,.8)


def grain_sack(x,y,z,orientation=0):
    ob=ball("bulging tied feed grain sack",(x,y,z+.26),(.24,.21,.34),"milk_wall",14)
    ob.rotation_euler[1]=orientation
    beam("bag linen tie",(x-.09,y-.04,z+.48),(x+.09,y+.04,z+.49),.024,"grain_dark",7)
    ball("sack oat pictogram",(x,y-.205,z+.26),(.09,.014,.13),"grain_gold",10)


def animal_feed_mill():
    w,d,wh,peak=3.12,2.60,2.18,3.63
    base(w,d,"stone")
    stucco(w,d,wh,"feed_wall","feed_light","oak_dark")
    gables(w,d,2.52,peak,"feed_shadow")
    crafted_roof(w+.17,d+.16,2.55,3.70,"sage_roof","sage_dark","sage_tile","sage_roof")
    front=-d/2
    door(-.28,front,.38,1.31,1.63,"oak","grain_dark",twin=True)
    badge("PAKAN",front-.105,2.87,"sage_dark","oak_dark",.23,1.55)
    window(1.02,front,1.46,.51,.63)
    window(w/2,-.22,1.45,.62,.65,True)
    # Exposed right-side hopper silo for grain. It has cedar staves and steel bands.
    sx,sy=1.95,.73
    cylinder("side grain silo circular body",(sx,sy,1.69),.64,2.43,"silo_stave",24)
    for k in range(20):
        a=math.tau*k/20
        x=sx+.637*math.cos(a)
        y=sy+.637*math.sin(a)
        beam("hand assembled vertical silo stave",(x,y,.62),(x,y,2.82),.014,
             "silo_light" if k%3==0 else "silo_dark",6)
    for zh in (.74,1.61,2.62):
        torus("silo reinforced riveted band",(sx,sy,zh),.65,.045,"iron_sun")
    bpy.ops.mesh.primitive_cone_add(vertices=20,radius1=.80,radius2=.035,depth=.72,
                                    location=(sx,sy,3.24))
    b.assign(bpy.context.object,"sage_roof")
    for k in range(20):
        a=math.tau*k/20
        beam("radial grain silo green shingles",
             (sx+.79*math.cos(a),sy+.79*math.sin(a),2.88),
             (sx+.028*math.cos(a),sy+.028*math.sin(a),3.60),
             .012,"sage_dark",6)
    ball("copper silo roof finial",(sx,sy,3.62),(.13,.13,.13),"copper_light")
    # Visible grain auger and cast-iron wheel supply the production narrative.
    beam("angled meal delivery chute",(sx-.22,sy-.49,1.48),
         (1.50,-1.45,.87),.18,"iron_sun",12)
    beam("rim of auger grain spout",(1.50,-1.45,.87),
         (1.41,-1.60,.82),.20,"sage_dark",12)
    # Vertical cogwheel readable on visible right side, with spokes.
    wx,wy,wz=2.62,-.46,1.11
    torus("large iron milling flywheel",(wx,wy,wz),.43,.067,"iron",(0,math.pi/2,0))
    cylinder_ax=beam("cast iron wheel shaft",(wx-.22,wy,wz),(wx+.22,wy,wz),.085,"copper",10)
    for i in range(8):
        a=math.tau*i/8
        beam("radial wheel steel arm",(wx,wy,wz),
             (wx,wy+.40*math.cos(a),wz+.40*math.sin(a)),.028,"iron_sun",7)
    ball("brass wheel hub",(wx+.055,wy,wz),(.09,.10,.10),"copper_light",12)
    # Stacked feed sacks, trough and grains spilling onto the stone threshold.
    grain_sack(-1.30,-1.73,.10,-.14)
    grain_sack(-1.01,-1.80,.12,.19)
    box("grain feed oak trough",(1.25,-1.90,.38),(.75,.54,.46),"oak_dark",.045)
    box("golden oat meal full feed trough",(1.25,-1.90,.63),(.62,.44,.09),"grain_gold",.035)
    for i in range(15):
        a=math.tau*i/15
        x=1.25+.24*math.cos(a)
        y=-1.90+.15*math.sin(a)
        ball("grain kernels in feeder",(x,y,.70),(.036,.055,.029),
             "grain_high" if i%3 else "grain_dark",8)
    blossoms(-1.61,.72,"marigold")
    b.grass_tuft(1.39,1.28,.85)


ASSETS = [
    ("bakery_building",baking_shop,7.28,2.01),
    ("dairy_building",dairy_shop,7.48,1.93),
    ("feed_mill_building",animal_feed_mill,8.17,2.02),
]


def main():
    SOURCE.mkdir(exist_ok=True,parents=True)
    materials()
    anchors={}
    for i,(name,maker,ortho,zcenter) in enumerate(ASSETS):
        RNG.seed(771500+i)
        b.RNG.seed(881500+i)
        cam=b.scene_base()
        maker()
        target=Vector((0,0,zcenter))
        cam.location=target+Vector((7,-9,8))
        cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler()
        cam.data.type="ORTHO"
        cam.data.ortho_scale=ortho
        bpy.context.view_layer.update()
        ground=world_to_camera_view(bpy.context.scene,cam,Vector((0,0,.05)))
        anchors[name]=[round(ground.x*RES),round((1-ground.y)*RES)]
        bpy.context.scene.render.filepath=str(SOURCE/(name+".png"))
        print(f"ASSET_RENDER {name} anchor={anchors[name]}",flush=True)
        bpy.ops.render.render(write_still=True)
    (SOURCE/"untrimmed_anchors.json").write_text(json.dumps(anchors,indent=2)+"\n",encoding="utf-8")
    print("RENDER_COMPLETE three independent art_v7 production buildings",flush=True)


if __name__=="__main__":
    main()
