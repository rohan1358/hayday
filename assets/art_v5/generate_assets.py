"""Original farm decorations, rendered from Blender 5.2 into art_v5 only.

Run: blender --background --factory-startup --python assets/art_v5/generate_assets.py
Reads the geometry helpers in art_v2 without creating files there.
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
OUT = HERE / "_render_source"
sys.dont_write_bytecode = True
sys.path.insert(0, str(HERE.parent / "art_v2"))
import generate_assets as b

RES = 1024
RNG = random.Random(12026)


def palette():
    b.setup_materials()
    extras = {
        "honey_wood": "#e1a866", "crate_face": "#c38a50", "crate_shadow": "#885439",
        "crate_gold": "#f0c389", "iron": "#6f594d", "grain": "#a76e41",
        "apple_red": "#e15f53", "apple_pink": "#f28b70", "pear": "#bcd978",
        "hay_yellow": "#f8c668", "hay_light": "#ffe4a0", "hay_shade": "#dca14d",
        "twine": "#a07d4a", "twine_light": "#f5e1ab", "earth_edge": "#74503c",
        "earth_mid": "#996e50", "meadow": "#80b56c", "meadow_light": "#b9d58b",
        "pearl": "#ffefcb", "salmon": "#fa9f92", "petal_rose": "#e7869b",
        "lilac": "#c6b1e8", "coral": "#f6ae78", "gold_petal": "#f8d279",
        "pond_deep": "#498f93", "pond_mid": "#62b8b7", "pond_water": "#86cfcd",
        "pond_glimmer": "#d2ebda", "rim_sand": "#d8c9a6", "rim_dark": "#a9aa91",
        "reeds": "#71985a", "reed_dark": "#4b7853", "lily": "#629f68",
        "lamp_brass": "#b98247", "lamp_bright": "#efc37a", "lamp_dark": "#695044",
        "lantern_glass": "#fcd58a", "lantern_glow": "#ffe9ab", "lantern_top": "#6f6853",
    }
    b.M.update({n: b.material(n, c) for n, c in extras.items()})
    material = b.M["lantern_glow"]
    surface = material.node_tree.nodes.get("Principled BSDF")
    if surface and surface.inputs.get("Emission Color"):
        surface.inputs["Emission Color"].default_value = (1.0, .60, .22, 1.0)
        surface.inputs["Emission Strength"].default_value = .85


def oval(name, x, y, z, rx, ry, height, tone):
    return b.orb(name, (x, y, z), (rx, ry, height), tone, 40, 14)


def leaf(name, x, y, z, angle, sx=.16, sy=.075, mat="leaf_light"):
    o = oval(name, x, y, z, sx, sy, .035, mat)
    o.rotation_euler[2] = angle


def pebble(x, y, z, size=.1, tone="stone_light"):
    o = b.orb("smooth garden pebble", (x, y, z),
              (size, size * RNG.uniform(.8, 1.3), size * RNG.uniform(.42, .65)),
              tone, 10, 6)
    o.rotation_euler[2] = RNG.random() * 6.28


def flower_head(x, y, z, tone="petal_rose", size=.9):
    for k in range(5):
        a = math.tau * k / 5
        oval("round flower petal", x + math.cos(a) * .094 * size,
             y + math.sin(a) * .094 * size, z + .016 * size,
             .096 * size, .082 * size, .031 * size, tone)
    b.orb("flower pollen center", (x, y, z + .055 * size),
          (.052 * size,) * 3, "gold", 12, 7)


def berry(x, y, z, color="apple_red", radius=.14):
    b.orb("fresh harvest apple", (x, y, z), (radius, radius * .97, radius * .95), color, 16, 10)
    b.pole("fruit stem", (x, y, z + radius * .83),
           (x + .02, y, z + radius * 1.4), .013, "wood_dark", 7)
    leaf("apple leaf", x + .07, y + .015, z + radius * 1.24, .35, .075, .036)


def wooden_crate(x, y, base_z, w=1.2, d=1.04, h=.93, decorated=False):
    top = base_z + h
    b.box("crate lower shelf", (x, y, base_z + .09), (w + .06, d + .04, .16), "wood_dark", .055)
    b.box("dark inside crate", (x, y, top - .22), (w - .16, d - .16, .10), "crate_shadow", .015)
    for side in (-1, 1):
        xx = x + side * (w / 2 - .075)
        for yy in (y - d/2 + .075, y + d/2 - .075):
            b.box("solid crate corner", (xx, yy, base_z + h/2), (.115, .125, h), "wood_dark", .025)
    for i in range(3):
        zz = base_z + .22 + i * .235
        tone = "honey_wood" if i % 2 == 0 else "crate_face"
        for yy in (y - d/2, y + d/2):
            b.box("horizontal wood slat", (x, yy, zz), (w - .08, .09, .195), tone, .024)
        for xx in (x - w/2, x + w/2):
            b.box("horizontal side slat", (xx, y, zz), (.09, d - .08, .195),
                  "crate_face" if i % 2 == 0 else "honey_wood", .025)
    for yy in (y - d/2, y + d/2):
        b.box("crate smooth top ledge", (x, yy, top - .035), (w + .06, .12, .095), "crate_gold", .028)
    for xx in (x - w/2, x + w/2):
        b.box("crate top rim", (xx, y, top - .035), (.12, d + .08, .095), "crate_gold", .028)
    front_y = y - d/2 - .058
    b.pole("X brace front rising", (x - .43*w, front_y, base_z + .16),
           (x + .43*w, front_y, top - .13), .028, "wood_dark", 7)
    b.pole("X brace front falling", (x + .43*w, front_y-.012, base_z + .16),
           (x - .43*w, front_y-.012, top - .13), .024, "crate_face", 7)
    for xx in (x - w/2 + .11, x + w/2 - .11):
        for zz in (base_z + .20, base_z + .66):
            b.orb("round iron fastener", (xx, front_y - .015, zz), (.028, .012, .028), "iron", 9, 6)
    if decorated:
        for dx, dy, typ in [(-.33,-.23,"apple_red"), (-.08,-.29,"apple_pink"),
                             (.19,-.26,"apple_red"), (.34,.06,"pear"),
                             (-.20,.16,"pear"), (.09,.22,"apple_red")]:
            berry(x+dx, y+dy, top-.075, typ, .15)


def wooden_crates():
    wooden_crate(-.69, -.12, .055, 1.20, 1.03, .94, True)
    wooden_crate(.62, .08, .055, 1.20, 1.03, .94, True)
    wooden_crate(-.10, .18, .995, 1.16, 1.03, .90, True)
    # Flour sack and fallen fruit soften the composition.
    sack = oval("linen sack", 1.13, -.66, .24, .37, .30, .25, "ivory")
    sack.rotation_euler[2] = -.38
    b.pole("sack tie", (1.10,-.66,.40),(1.10,-.66,.52), .042, "twine", 9)
    berry(-1.39, -.50, .16, "apple_red", .13)
    for x, y in [(-1.47,.03),(-.82,-.79),(.97,.76)]:
        b.grass_tuft(x, y, .7)


def bale(x, y, base_z, w=1.6, d=1.0, h=.72):
    zz = base_z + h / 2
    b.box("gold straw bale", (x, y, zz), (w, d, h), "hay_yellow", .16)
    b.box("sun-warmed bale top", (x, y, base_z + h - .075),
          (w - .13, d - .10, .07), "hay_light", .04)
    # Two complete visible rope runs, one across each end of the bale.
    for xx in (x - .32*w, x + .32*w):
        yfront, yrear = y - d/2 -.018, y + d/2 + .018
        zlow, zhigh = base_z + .09, base_z + h - .038
        for a, c in [((xx,yfront,zlow),(xx,yfront,zhigh)),
                     ((xx,yfront,zhigh),(xx,yrear,zhigh)),
                     ((xx,yrear,zhigh),(xx,yrear,zlow))]:
            b.pole("straw bale natural twine", a, c, .019, "twine", 7)
        b.orb("twine knot", (xx,yfront-.016,base_z+.40*h),
              (.041,.025,.038), "twine_light", 9, 6)
    for _ in range(35):
        px = x + RNG.uniform(-.46,.46)*w
        py = y + RNG.uniform(-.42,.42)*d
        z = base_z + h - .024
        a = RNG.uniform(-.6,.6)
        length = RNG.uniform(.12,.42)
        b.pole("loose top straw fiber", (px,py,z),
               (px + math.cos(a)*length,py + math.sin(a)*length,z+.022),
               .008, "hay_light" if RNG.random()<.55 else "hay_shade", 5)
    for _ in range(26):
        px = x + RNG.uniform(-.48,.48)*w
        pz = base_z + RNG.uniform(.13,.87)*h
        py = y - d/2 -.04
        ln = RNG.uniform(.07,.24)
        b.pole("woven front straw strands", (px,py,pz), (px+ln,py,pz+.008),
               .008, "hay_shade" if RNG.random()<.6 else "hay_light", 5)


def hay_stack():
    bale(-.75, -.08, .08, 1.48, 1.02, .74)
    bale(.76, .05, .08, 1.48, 1.02, .74)
    bale(.03, .11, .81, 1.63, 1.02, .77)
    # A few hay wisps spill in front, at the ground contact plane.
    for i in range(32):
        x = RNG.uniform(-1.55,1.60)
        y = RNG.uniform(-.95,-.48)
        angle = RNG.uniform(-2.6,.6)
        length = RNG.uniform(.12,.40)
        b.pole("scattered loose straw", (x,y,.06),
               (x + length*math.cos(angle),y + length*math.sin(angle),.06),
               .012, "straw_light" if i%3 else "hay_shade", 6)
    for x,y in [(-1.59,.12),(1.60,.14),(-1.12,-.95)]:
        b.grass_tuft(x,y,.65)


def flower_patch():
    # Oval living soil plot, no opaque rectangular footprint.
    oval("rounded earth berm", 0,0,.13, 1.72,1.18,.17,"earth_edge")
    oval("soft fertile soil", 0,0,.23,1.58,1.07,.16,"earth_mid")
    oval("fine short meadow",0,0,.315,1.45,.95,.13,"meadow")
    oval("sunlit patch edge",-.13,-.08,.355,1.22,.75,.055,"meadow_light")
    for k in range(36):
        theta = math.tau * k/36 + RNG.uniform(-.05,.05)
        x = 1.63*math.cos(theta)
        y = 1.08*math.sin(theta)
        pebble(x,y,.14, RNG.uniform(.08,.14), "rim_sand" if k%3 else "rim_dark")
    tones = ["salmon","petal_rose","pearl","lilac","coral","gold_petal"]
    # Spaced irregularly; the tall blossoms cast small soft shadows on the bed.
    sites = []
    attempts = 0
    while len(sites)<45 and attempts<1000:
        attempts += 1
        x,y = RNG.uniform(-1.32,1.32), RNG.uniform(-.85,.85)
        if (x/1.38)**2+(y/.87)**2 > 1: continue
        if any((x-x0)**2+(y-y0)**2<.075 for x0,y0 in sites): continue
        sites.append((x,y))
    for i,(x,y) in enumerate(sites):
        h = RNG.uniform(.28,.52)
        b.pole("delicate stem", (x,y,.34), (x,y,.34+h), .018, "stem",6)
        leaf("lower garden leaf",x-.07,y,.39+h*.42,-.4,.13,.047,"leaf")
        leaf("upper garden leaf",x+.06,y,.40+h*.68,.55,.11,.044,"leaf_light")
        flower_head(x,y,.34+h,tones[(i+int(abs(x)*5))%len(tones)],RNG.uniform(.58,.82))
    for i in range(20):
        a = math.tau * i / 20
        b.grass_tuft(math.cos(a)*1.62, math.sin(a)*1.03, RNG.uniform(.34,.56))


def pond_lily(x,y,scale=.95,bloom=False):
    z=.247
    pad=oval("floating lily pad",x,y,z,.27*scale,.22*scale,.023,"lily")
    pad.rotation_euler[2] = RNG.uniform(-.5,.5)
    leaf("lily bright leaf patch",x-.075*scale,y+.015*scale,z+.023,.35,.11*scale,.08*scale,"leaf_light")
    if bloom:
        flower_head(x+.05,y-.018,z+.09,"pearl",.54)


def decorative_pond():
    oval("pond outer earth lip", 0,0,.077,2.13,1.50,.085,"earth_edge")
    oval("smooth stone bank", 0,0,.126,2.02,1.39,.093,"rim_sand")
    oval("deep pool underlayer",0,0,.172,1.89,1.26,.047,"pond_deep")
    oval("turquoise open water",0,0,.205,1.80,1.18,.024,"pond_water")
    oval("soft turquoise water center",-.14,-.04,.227,1.39,.87,.009,"pond_mid")
    # Separate silvery ripple strokes over the surface.
    for cx,cy,rx,ry in [(-.71,.17,.37,.14),(.38,-.21,.47,.17),(.70,.42,.32,.11)]:
        for j in range(21):
            a1 = .3 + j * (math.pi * 1.28) / 21
            a2 = .3 + (j + 1) * (math.pi * 1.28) / 21
            b.pole("light water ripple",(cx+rx*math.cos(a1),cy+ry*math.sin(a1),.239),
                   (cx+rx*math.cos(a2),cy+ry*math.sin(a2),.239),.008,"pond_glimmer",5)
    # Hand-rounded cobbles around the contour, spaced to read clearly in game.
    for k in range(39):
        a = math.tau*k/39
        rx,ry=2.02,1.38
        pebble(rx*math.cos(a),ry*math.sin(a),.17,
               RNG.uniform(.17,.22),"stone_light" if k%4 else "rim_dark")
    pond_lily(-.65,-.38,1.0,True)
    pond_lily(.65,.16,.87,False)
    pond_lily(.14,.50,.75,True)
    # Reeds and cotton-brown cattails on the far bank.
    for j,(x,y,h) in enumerate([(-1.38,.96,.83),(-1.21,1.02,.99),(-1.03,1.06,.74),
                                 (1.42,.89,.80),(1.58,.81,.95),(1.28,.93,.66)]):
        b.pole("marsh reed stem",(x,y,.13),(x+.08,y+.03,h),.024,"reed_dark",8)
        b.orb("velvety cattail",(x+.07,y+.03,h-.055),(.064,.06,.20),"wood_dark",12,8)
        leaf("marsh reed blade",x-.12,y,.40,-.7,.30,.052,"reeds")
    for x,y in [(-1.84,-.34),(-1.27,-1.01),(1.81,-.45),(1.35,1.18)]:
        b.grass_tuft(x,y,.68)


def tapered_roof(name, x, y, z, lower, upper, height, color):
    # Four sloped brass panels: a little roof with readable thickness.
    v = [(x+dx*lower,y+dy*lower,z) for dx,dy in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    v += [(x+dx*upper,y+dy*upper,z+height) for dx,dy in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    return b.mesh(name, v, [(0,3,2,1),(4,5,6,7),
                            (0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],color)


def rustic_lamp():
    # Oak post, collar, and suspended brass lantern at eye height.
    post_x,post_y=-.24,.24
    b.box("old oak upright post",(post_x,post_y,1.43),(.26,.28,2.76),"wood_dark",.065)
    for zz in (.30,1.31,2.45):
        b.box("engraved light oak band",(post_x,post_y-.151,zz),(.215,.025,.074),"wood_light",.015)
    b.box("carved wooden cap",(post_x,post_y,2.85),(.41,.41,.16),"honey_wood",.04)
    b.box("upright ornament",(post_x,post_y,2.977),(.245,.24,.14),"wood_dark",.04)
    # Lantern hangs to the right in front of the post; angled brace supports weight.
    b.pole("upper curved arm",(-.18,post_y,2.72),(.78,post_y,2.72),.092,"wood_dark",10)
    b.pole("diagonal oak brace",(-.21,post_y,2.28),(.46,post_y,2.71),.062,"crate_face",9)
    b.orb("bronze arm terminal",(.79,post_y,2.73),(.10,.10,.10),"lamp_brass",12,8)
    b.pole("lantern iron chain",(.74,post_y,2.72),(.74,post_y,2.54),.026,"iron",8)
    lx,ly,lz=.74,post_y,2.16
    b.box("lantern inset floor",(lx,ly,lz-.24),(.49,.45,.10),"lamp_dark",.045)
    b.box("glowing golden glass",(lx,ly,lz),(.37,.36,.43),"lantern_glass",.032)
    b.orb("warm lamp flame",(lx,ly-.09,lz-.02),(.10,.075,.16),"lantern_glow",16,10)
    for dx in (-.22,.22):
        for dy in (-.22,.22):
            b.pole("aged lantern frame",(lx+dx,ly+dy,lz-.29),
                   (lx+dx,ly+dy,lz+.26),.031,"lamp_brass",8)
    for zz in (lz-.28,lz+.25):
        for dy in (-.22,.22):
            b.pole("lantern thin horizontal trim",(lx-.24,ly+dy,zz),
                   (lx+.24,ly+dy,zz),.027,"lamp_brass",7)
    tapered_roof("tapered lantern roof",lx,ly,lz+.26,.35,.15,.20,"lamp_dark")
    b.orb("brass lantern finial",(lx,ly,lz+.50),(.082,.082,.075),"lamp_bright",10,7)
    # Stone foot and clover blossoms anchor this into the farm environment.
    b.box("chiseled old stone plinth",(post_x,post_y,.18),(.67,.68,.31),"stone",.10)
    for dx,dy,ss in [(-.48,-.13,.19),(.34,-.20,.16),(.31,.31,.14),(-.24,.48,.13)]:
        pebble(post_x+dx,post_y+dy,.10,ss,"stone_light")
    for x,y in [(-.79,.01),(.19,-.37),(.28,.58),(-.59,.67)]:
        b.grass_tuft(x,y,.68)
    b.flower(-.67,-.26,.39,"pink",.70)
    b.flower(.28,-.21,.35,"lavender",.62)


ASSETS = [
    ("wooden_crates", wooden_crates, 5.14, 1.05),
    ("hay_stack", hay_stack, 4.82, .82),
    ("flower_patch", flower_patch, 4.66, .50),
    ("decorative_pond", decorative_pond, 5.54, .45),
    ("rustic_lamp", rustic_lamp, 5.30, 1.56),
]


def main():
    OUT.mkdir(exist_ok=True, parents=True)
    palette()
    anchors={}
    for i,(asset,build,scale,height) in enumerate(ASSETS):
        RNG.seed(818001+i)
        b.RNG.seed(110982+i)
        camera=b.scene_base()
        build()
        target=Vector((0,0,height))
        camera.location=target+Vector((7,-9,8))
        camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
        camera.data.type="ORTHO"
        camera.data.ortho_scale=scale
        bpy.context.view_layer.update()
        projection=world_to_camera_view(bpy.context.scene,camera,Vector((0,0,.05)))
        anchors[asset]=[round(projection.x*RES),round((1-projection.y)*RES)]
        bpy.context.scene.render.filepath=str(OUT/(asset+".png"))
        print(f"ASSET_RENDER {asset} anchor={anchors[asset]}",flush=True)
        bpy.ops.render.render(write_still=True)
    (OUT/"untrimmed_anchors.json").write_text(json.dumps(anchors,indent=2)+"\n",encoding="utf-8")
    print("RENDER_COMPLETE art_v5 five decorative props",flush=True)


if __name__=="__main__":
    main()
