"""Blender 5.2: original isometric market cart and farm decorations.

Run from the project root:
  blender --background --factory-startup --python assets/art_v4/generate_assets.py
Then: py assets/art_v4/finalize_assets.py

Reads material/geometry primitives from art_v2 (read-only). Writes ONLY art_v4.
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
sys.dont_write_bytecode = True  # importing read-only v2 geometry must not create __pycache__
sys.path.insert(0, str(HERE.parent / "art_v2"))
import generate_assets as b  # existing primitive shapes and farm palette, read-only

OUT = HERE / "_render_source"
RES = 1024
RNG = random.Random(20261106)


def palette():
    b.setup_materials()
    colors = {
        "canopy_cream": "#fff0cb", "canopy_coral": "#df7462",
        "canopy_coral_deep": "#ba5a4e", "canopy_mint": "#80bbb0",
        "sunshine": "#fbd378", "aged_brass": "#d7a354",
        "apple_red": "#d65450", "apple_highlight": "#f07f63",
        "pear_green": "#aad575", "pear_dark": "#739e4f",
        "plum": "#8a739f", "produce_orange": "#ee9b4a",
        "produce_pale": "#fedb87", "fresh_olive": "#5b985e",
        "fence_warm": "#d9aa74", "fence_shadow": "#986443",
        "hedge_deep": "#4d835f", "hedge_mid": "#71ad6e",
        "hedge_light": "#a7d47f", "blossom": "#ffe4c0",
        "blossom_coral": "#f69f9a", "blossom_lilac": "#bda9d9",
        "path_beige": "#d8c9a4", "path_sun": "#ede0bc",
        "path_shade": "#b2a88a", "path_moss": "#86ac74",
        "ground_shadow": "#66774f",
    }
    b.M.update({name: b.material(name, color) for name, color in colors.items()})


def torus(name, center, major, minor, mat):
    bpy.ops.mesh.primitive_torus_add(major_segments=40, minor_segments=10,
                                     major_radius=major, minor_radius=minor,
                                     location=center, rotation=(0, math.pi / 2, 0))
    obj = bpy.context.object
    obj.name = name
    b.assign(obj, mat)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def leaf(x, y, z, angle, sx=.17, sy=.075, color="leaf"):
    obj = b.orb("leaf", (x, y, z), (sx, sy, .043), color, 12, 8)
    obj.rotation_euler[2] = angle
    return obj


def apple(x, y, z, scale=1, color="apple_red"):
    b.orb("polished apple", (x, y, z), (.137*scale, .129*scale, .133*scale), color, 16, 10)
    b.pole("apple stem", (x, y, z+.111*scale), (x+.018*scale, y, z+.207*scale), .014*scale, "wood_dark", 7)
    leaf(x+.086*scale, y+.018*scale, z+.17*scale, .35, .09*scale, .048*scale, "leaf_light")


def basket(x, y, z, width=.70, depth=.42):
    """Open low fruit tray with four slim warm wooden edges."""
    b.box("woven tray bottom", (x, y, z), (width, depth, .10), "wood_light", .04)
    for dy in (-depth/2, depth/2):
        b.box("fruit tray edging", (x, y+dy, z+.105), (width+.06,.065,.13), "wood", .025)
    for dx in (-width/2, width/2):
        b.box("fruit tray end", (x+dx, y, z+.10), (.065, depth+.04, .13), "wood", .025)


def cart_wheel(x, y):
    """Readable cartwheel in YZ plane with 8 golden spokes."""
    z = .59
    torus("handcrafted oak wheel rim", (x,y,z), .48, .080, "wood_dark")
    torus("warm tire inset", (x + (.025 if x > 0 else -.025),y,z), .36, .018, "wood_light")
    for index in range(8):
        angle = (2*math.pi*index/8) + math.pi/8
        b.pole("wheel radial spoke", (x,y,z),
               (x, y+math.cos(angle)*.43, z+math.sin(angle)*.43), .035, "aged_brass", 8)
    b.orb("oak wheel hub", (x + (.055 if x > 0 else -.055), y, z),
          (.115,.105,.105), "wood_light", 14, 8)
    b.orb("metal axle cap", (x + (.12 if x > 0 else -.12), y, z),
          (.031,.065,.065), "aged_brass", 12, 8)


def hanging_valance(x0, x1, y, top_z, material):
    """Scalloped apron cut from a soft striped canopy."""
    count = 3
    points = [(x0, y, top_z), (x1, y, top_z)]
    lower = []
    for i in range(count * 6 + 1):
        t = i / (count * 6)
        x = x0 + (x1 - x0) * t
        wave = math.sin(math.pi * (i % 6) / 6)
        lower.append((x, y, top_z - .18 - .07*wave))
    vertices = points + lower
    faces = []
    for i in range(len(lower)-1):
        faces.append((0,2+i,3+i) if i < len(lower)//2 else (1,2+i,3+i))
    b.mesh("hanging scalloped fabric", vertices, faces, material)


def cart_canopy():
    """Striped red / ivory awning with shaped drip valance on both ends."""
    left, right = -1.71, 1.71
    # A set-back sunshade leaves the colorful front produce trays visible at 3/4 view.
    yfront, yrear = -0.18, 1.24
    # Main cloth slopes gently upward toward the rear; stripes in the X direction.
    for ix in range(8):
        x0 = left + (right-left)*ix/8
        x1 = left + (right-left)*(ix+1)/8
        tone = "canopy_cream" if ix % 2 == 0 else "canopy_coral"
        b.mesh("wide striped canopy section", [
            (x0,yfront,2.52), (x1,yfront,2.52),
            (x1,yrear,2.76), (x0,yrear,2.76),
            (x0,yfront,2.465), (x1,yfront,2.465),
            (x1,yrear,2.705), (x0,yrear,2.705)],
            [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)], tone)
        hanging_valance(x0,x1,yfront-.025,2.48,tone)
        hanging_valance(x0,x1,yrear+.025,2.72,tone)
    for x in (left,right):
        b.pole("canopy side piping",(x,yfront,2.51),(x,yrear,2.75),.025,"canopy_coral_deep",8)
    b.pole("canopy red front trim",(left,yfront-.02,2.49),(right,yfront-.02,2.49),.033,"canopy_coral_deep",8)


def market_cart():
    """Standalone two-wheel market cart, vendor's red canopy and abundant fresh produce."""
    # Carriage / undercarriage: raised platform keeps all details off ground.
    b.box("market wagon undercarriage",(0,0,1.00),(2.83,1.69,.26),"wood_dark", .095)
    b.box("carriage painted panel",(0,-.83,1.22),(2.70,.105,.45),"wood_light",.055)
    b.box("front burgundy emblem board",(0,-.899,1.24),(1.18,.047,.28),"canopy_coral",.035)
    for dx in (-1.21,1.21):
        b.box("counter panel wooden upright",(dx,-.906,1.22),(.075,.07,.39),"wood",.022)
    for z in (1.03,1.44):
        b.box("counter face accent",(0,-.929,z),(2.68,.05,.047),"wood_dark",.014)
    b.box("countertop thick honey wood",(0,0,1.49),(3.03,1.84,.20),"wood_light",.06)
    b.box("upper counter inset",(0,0,1.608),(2.91,1.74,.035),"butter",.018)
    for dx in (-1.25,1.25):
        b.pole("cart foot",(dx,.15,.39),(dx,.15,.92),.115,"wood_dark",10)
    b.pole("axle beneath counter",(-1.79,.18,.59),(1.79,.18,.59),.077,"wood_dark",12)
    cart_wheel(-1.70,.18)
    cart_wheel(1.70,.18)
    # Two handles project from the back of the cart; small brass caps.
    for dx in (-.92,.92):
        b.pole("vendor push handle",(dx,.80,1.10),(dx,1.88,1.13),.075,"wood",10)
        b.orb("handle honey cap",(dx,1.91,1.13),(.095,.105,.09),"aged_brass",12,8)
    # Four slim canopy poles.
    for x in (-1.37,1.37):
        for y,z in [(-.13,2.45),(1.15,2.66)]:
            b.pole("painted market roof support",(x,y,1.49),(x,y,z),.062,"wood_light",10)
            b.orb("canopy support cap",(x,y,z),(.08,.08,.065),"aged_brass",10,7)
    cart_canopy()
    # Fruit crates placed in readable rows above the counter.
    basket(-.89,-.24,1.68,.78,.53)
    for ix,x in enumerate((-.99,-.72)):
        for iy,y in enumerate((-.35,-.17)):
            apple(x,y,1.84+(.03 if ix==iy else 0),.87, "apple_red" if ix+iy!=2 else "apple_highlight")
    basket(.02,-.24,1.68,.73,.53)
    for x,y in ((-.20,-.30),(.03,-.35),(.21,-.18),(-.02,-.10)):
        b.orb("orange harvest",(x,y,1.87),(.134,.134,.133),"produce_orange",14,10)
        b.orb("orange top",(x,y,1.996),(.055,.041,.019),"fresh_olive",9,7)
    basket(.93,-.24,1.68,.80,.53)
    for x,y in ((.71,-.25),(.93,-.33),(1.10,-.19),(.87,-.09)):
        b.orb("fresh little cabbage",(x,y,1.90),(.16,.17,.14),"hedge_mid",12,8)
        for a in range(3):
            angle=a*math.tau/3
            leaf(x+.10*math.cos(angle),y+.09*math.sin(angle),1.99,angle,.13,.085,"leaf_light")
    # Back row crates, elevated but under the awning.
    basket(-.59,.46,1.71,.89,.40)
    for x in (-.86,-.62,-.38):
        b.orb("golden pear",(x,.48,1.91),(.128,.13,.17),"pear_green",14,9)
        b.pole("pear stem",(x,.48,2.04),(x+.02,.48,2.13),.014,"wood_dark",7)
    basket(.58,.46,1.71,.98,.41)
    for x in (.30,.52,.74,.96):
        b.orb("garden purple plum",(x,.44,1.92),(.125,.125,.127),"plum",14,9)
    # Friendly painted flower badge at the center of the cart front.
    b.orb("vendor badge circle",(0,-.937,1.24),(.148,.026,.148),"canopy_cream",16,9)
    b.orb("sunflower center",(0,-.969,1.24),(.07,.012,.07),"sunshine",12,7)
    for t in range(7):
        a = t*math.tau/7
        b.orb("badge petal",(.105*math.cos(a),-.956,1.24+.105*math.sin(a)),(.03,.018,.048),"canopy_coral",10,6)


def fence_rail(a, c, z):
    b.pole("ranch split-rail timber",(a[0],a[1],z),(c[0],c[1],z),.061,"fence_warm",10)
    b.pole("rail accent shadow",(a[0],a[1]-.019,z-.035),(c[0],c[1]-.019,z-.035),.012,"fence_shadow",6)


def fence_post(x,y):
    b.box("chamfered fence post",(x,y,.60),(.178,.178,1.18),"wood_light",.037)
    b.box("post cap",(x,y,1.215),(.235,.235,.092),"butter",.042)
    b.box("post gold inlay",(x,y,1.08),(.187,.188,.045),"wood",.01)


def straight_fence():
    for x in (-1.35,0,1.35):
        fence_post(x,0)
    for z in (.50,.90):
        fence_rail((-1.35,0),(0,0),z)
        fence_rail((0,0),(1.35,0),z)
    for x in (-1.05,.92):
        b.grass_tuft(x,-.15,.70)
    b.flower(-.52,-.20,.44,"pink",.65)


def corner_fence():
    """L fence: one section to +X, one to +Y, connected at origin."""
    for x,y in ((0,0),(1.35,0),(0,1.35)):
        fence_post(x,y)
    for z in (.50,.90):
        fence_rail((0,0),(1.35,0),z)
        fence_rail((0,0),(0,1.35),z)
    b.grass_tuft(.35,-.10,.85)
    b.grass_tuft(-.16,.45,.70)
    b.flower(.20,.25,.40,"lavender",.67)


def blossom(x,y,z,tone,scale=1):
    """Tiny five-petal bloom visible from above."""
    for i in range(5):
        a=2*math.pi*i/5
        b.orb("flowering hedge petal",(x+.063*scale*math.cos(a),y+.063*scale*math.sin(a),z),
              (.06*scale,.06*scale,.035*scale),tone,9,6)
    b.orb("flower pollen",(x,y,z+.028*scale),(.045*scale,)*3,"sunshine",10,7)


def flowering_hedge():
    """Lush rounded shrub cluster with irregular silhouette and small blossoms."""
    b.orb("dark green organic hedge base",(0,0,.37),(1.30,.59,.46),"hedge_deep",20,12)
    for i in range(13):
        x=-1.17+(i%7)*.37+RNG.uniform(-.11,.11)
        y=(-.27 if i<7 else .28) + RNG.uniform(-.15,.15)
        z=.49 + (.19 if i%3==0 else .07)+RNG.uniform(-.06,.09)
        rx=.35+RNG.uniform(-.055,.07)
        b.orb("cluster of bright hedge leaves",(x,y,z),(rx,.32,.31),
              ["hedge_mid","leaf","hedge_light","grass_dark"][i%4],16,10)
    for i,(x,y,z) in enumerate([
        (-1.06,-.42,.66),(-.71,.21,.82),(-.43,-.49,.68),(-.13,.35,.79),
        (.18,-.31,.80),(.56,.27,.75),(.90,-.28,.68),(1.08,.25,.57),
        (-.76,-.24,.93),(.48,-.05,.98),(-.12,-.02,1.00)
    ]):
        blossom(x,y,z,["blossom","blossom_coral","blossom_lilac"][i%3],.85)
    for x,y in [(-1.26,-.18),(1.18,.11),(.80,-.55)]:
        b.grass_tuft(x,y,.62)


def paving_stone(x,y,z,sx,sy,color,turn=0):
    obj=b.box("softly rounded garden stepping stone",(x,y,z), (sx,sy,.11), color, .09)
    obj.rotation_euler[2] = turn
    # Low moss patches suggest weathering without baking in a grassy square.
    for side in (-1,1):
        b.orb("stone edge moss",(x+side*sx*.33,y+sy*.32,z+.042),(.09,.055,.016),"path_moss",10,6)


def stone_path_tile():
    """Loose-footprint stones: transparent spaces between cobbles, no opaque ground plate."""
    for x,y,sx,sy,color,angle in [
        (-.87,-.53,.82,.61,"path_beige",-.09),
        (.11,-.62,.80,.64,"path_sun",.08),
        (1.05,-.46,.71,.58,"path_beige",-.12),
        (-.81,.35,.77,.69,"path_sun",.06),
        (.09,.30,.79,.61,"path_shade",-.06),
        (1.02,.39,.68,.67,"path_sun",.11),
        (-.33,1.07,.79,.51,"path_beige",-.07),
        (.66,1.09,.79,.53,"path_beige",.04),
    ]:
        paving_stone(x,y,.075,sx,sy,color,angle)
    for x,y in [(-1.27,.56),(.50,-.12),(1.36,.12),(-.18,.85)]:
        b.grass_tuft(x,y,.36)


ASSETS = [
    ("market_cart", market_cart, 5.98, 1.48),
    ("fence_straight", straight_fence, 3.96, .58),
    ("fence_corner", corner_fence, 3.82, .56),
    ("flowering_hedge", flowering_hedge, 3.92, .52),
    ("stone_path_tile", stone_path_tile, 3.68, .18),
]


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    palette()
    anchors={}
    for index,(name,build,ortho,center_z) in enumerate(ASSETS):
        RNG.seed(420160+index)
        b.RNG.seed(120926+index)
        camera=b.scene_base()
        build()
        target=Vector((0,0,center_z))
        camera.location=target+Vector((7,-9,8))
        camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
        camera.data.type="ORTHO"
        camera.data.ortho_scale=ortho
        bpy.context.view_layer.update()
        projection=world_to_camera_view(bpy.context.scene,camera,Vector((0,0,.05)))
        anchors[name]=[round(projection.x*RES),round((1-projection.y)*RES)]
        bpy.context.scene.render.filepath=str(OUT/(name+".png"))
        print(f"ASSET_RENDER {name} anchor={anchors[name]}",flush=True)
        bpy.ops.render.render(write_still=True)
    (OUT/"untrimmed_anchors.json").write_text(json.dumps(anchors,indent=2)+"\n",encoding="utf-8")
    print("RENDER_COMPLETE 5 original art_v4 sprites",flush=True)


if __name__=="__main__":
    main()
