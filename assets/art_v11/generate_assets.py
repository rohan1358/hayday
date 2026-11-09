"""Kebun Ceria art_v11: four original farm-detail props.

Blender 5.2: blender --background --factory-startup --python assets/art_v11/generate_assets.py
Writes solely under assets/art_v11; reads shared geometry helpers from art_v2.
"""

import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
RAW = ROOT / "_render_source"
BLENDS = ROOT / "source_blender"
sys.path.insert(0, str(ROOT.parent / "art_v2"))
import generate_assets as b


def palette():
    b.setup_materials()
    colors = {
        "cedar": "#b7825c", "cedar_light": "#e0b482", "cedar_dark": "#805742",
        "sage": "#6ea68a", "sage_dark": "#356f67", "sage_light": "#9ec8a6",
        "honey": "#efbd64", "honey_light": "#ffe0a0", "amber": "#d98e54",
        "pale": "#f5e5b9", "cream": "#fff2d5", "terracotta": "#cb8263",
        "stone": "#b8baa2", "stone_light": "#e0d8b4", "stone_dark": "#858f82",
        "grass": "#70ac70", "leaf": "#4f9469", "leaf_light": "#96c979",
        "lavender": "#a99bc9", "lilac": "#d5b9da", "pink": "#ed9caa",
        "sky": "#8bc4c1", "water": "#65ada6", "iron": "#405e5d",
        "soil": "#705543", "reed": "#dccb83", "chamomile": "#fff0c8",
    }
    b.M.update({name: b.material(name, hexc) for name, hexc in colors.items()})


def box(name, where, size, color, bevel=.035):
    return b.box(name, where, size, color, bevel)


def pole(name, a, c, radius, color, sides=10):
    return b.pole(name, a, c, radius, color, sides)


def ball(name, where, size, color, seg=12):
    return b.orb(name, where, size, color, seg, 9)


def cylinder(name, center, radius1, radius2, depth, color, vertices=16):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1,
                                   radius2=radius2, depth=depth, location=center)
    obj = bpy.context.object
    obj.name = name
    b.assign(obj, color)
    return obj


def rosette(x, y, z, color, size=1.0):
    pole("flower stem", (x, y, .08), (x, y, z), .021*size, "leaf", 6)
    for n in range(3):
        az = n * math.tau / 3 + .4
        ball("leaf blade", (x + math.cos(az)*.13*size,
                            y + math.sin(az)*.1*size, z*.55),
             (.15*size, .07*size, .06*size), "leaf_light")
    for n in range(5):
        ang = n * math.tau / 5
        ball("five-petal flower", (x+math.cos(ang)*.104*size,
                                   y+math.sin(ang)*.102*size,z),
             (.094*size, .086*size, .047*size), color)
    ball("nectar center", (x,y,z+.052*size), (.064*size,)*3,"honey")


def grass_tip(x, y, z, color="leaf"):
    for i in (-1,0,1):
        pole("wild grass blade", (x+i*.075,y,.03),
             (x+i*.13,y+(.1 if i==0 else -.035),z+(.075 if i==0 else -.055)),
             .035,color,6)


def ground_stones(radius_x, radius_y, start=0, count=11):
    for i in range(count):
        t = start + i * math.tau / count
        x,y = math.cos(t)*radius_x,math.sin(t)*radius_y
        pebble=ball("naturally irregular edging pebble",(x,y,.12),
                    (.22,.16,.14),"stone" if i%3 else "stone_light",10)
        pebble.rotation_euler[2] = t*1.2


def bumblebee(x, y, z, size=.7):
    ball("plump garden bee",(x,y,z),(.16*size,.11*size,.105*size),"honey")
    for dx in (-.035,.055):
        ball("bee dark stripe",(x+dx*size,y-.003*size,z),
             (.026*size,.114*size,.106*size),"iron")
    for dx in (-.07,.06):
        wing=ball("translucent-looking bee wing",(x+dx*size,y+.01*size,z+.095*size),
                  (.11*size,.10*size,.028*size),"cream")
        wing.rotation_euler[2]= dx * 2


def pollinator_house():
    """Bee/butterfly nesting lodge with a wildflower apron and sage tile gable."""
    for x,y in [(-.99,-.61),(1.01,.62),(-1.03,.57),(1.00,-.56)]:
        ball("sandstone foundation stone",(x,y,.095),(.31,.20,.16),"stone")
    box("floating pale stone sill",(0,0,.18),(2.49,1.26,.24),"stone_light",.15)
    box("cedar lodging body",(0,.1,1.37),(2.17,.73,1.70),"cedar",.06)
    box("inset amber hotel front",(0,-.294,1.42),(1.86,.075,1.39),"honey_light",.075)
    for x in (-1.01,1.01):
        box("lodge timber corner",(x,-.32,1.41),(.15,.13,1.71),"cedar_dark",.025)
    for z in (.70,2.14):
        box("top and bottom nesting frame",(0,-.347,z),(2.06,.15,.13),"cedar_light",.035)
    # Open bamboo nesting holes: dark centers contrast at typical 120px sprite scale.
    for row in range(3):
        for col in range(5):
            x = -.70 + col*.35 + (row%2)*.012
            z = .91 + row*.43
            pole("cut bamboo tube",(x,-.40,z),(x,-.24,z),.142,
                 "reed" if (row+col)%3 else "cedar_light",16)
            pole("deep opening",(x,-.423,z),(x,-.410,z),.088,"cedar_dark",16)
            if (row*5+col)%4==0:
                pole("reed pith center",(x-.02,-.433,z+.017),
                     (x-.02,-.421,z+.017),.032,"honey",10)
    # The little shed roof echoes the village architecture without reusing its models.
    b.roof(2.33,1.15,2.26,2.81,"sage","sage_dark",tile_color="sage_light")
    ball("sun medallion",(0,-.375,2.26),(.19,.038,.19),"honey")
    for x,y,z,tone in [(-1.13,-.42,.42,"lavender"),(1.15,-.38,.54,"pink"),
                       (-1.05,.53,.51,"cream"),(1.07,.50,.46,"lilac")]:
        rosette(x,y,z,tone,.75)
    for x,y in [(-1.35,-.13),(1.37,.14)]:
        grass_tip(x,y,.35)
    bumblebee(-1.08,-.90,1.99,.9)


def woven_basket(x,y,z,s=.8):
    cylinder("lidded shallow woven tray",(x,y,z+.14*s),.36*s,.42*s,.24*s,
             "cedar_dark",12)
    cylinder("woven upper braid",(x,y,z+.27*s),.44*s,.44*s,.09*s,
             "cedar_light",12)
    for a in range(8):
        t=a*math.tau/8
        ball("basket weave accent",(x+math.cos(t)*.37*s,
                                    y+math.sin(t)*.37*s,z+.16*s),
             (.038*s, .045*s, .08*s),"honey",9)


def herb_bundle(x, y, z, color, s=1.):
    pole("twine tied hanging cord",(x,y,z+.40*s),(x,y,z+.07*s),
         .026*s,"honey_light",8)
    for n in range(5):
        dx = (n-2)*.086*s
        lower=z-.40*s+(n%2)*.06*s
        pole("dried bouquet stem",(x+dx,y,lower),(x,y,z+.05*s),.019*s,"leaf",7)
        for m in range(2):
            ball("herb fronds",(x+dx,y+(m-.5)*.09*s,lower+.15*s+m*.13*s),
                 (.12*s,.10*s,.19*s),color)
    box("reusable cord tie",(x,y,z+.10*s),(.20*s,.17*s,.055*s),"honey",.012)


def herb_drying_rack():
    """Breezy A-frame drying rack, dried leaves, linen tags, herb trays."""
    for x in (-1.12,1.12):
        for y in (-.67,.67):
            pole("four splayed legs",(x*.86,y*.87,.16),
                 (x,.08,2.67),.095,"cedar_dark")
    for x in (-1.1,1.1):
        box("cedar side bracing",(x,-.01,.73),(.085,1.18,.115),"cedar",.025)
    pole("dried-herb suspension beam",(-1.35,-.38,2.38),
         (1.35,-.38,2.38),.105,"cedar_light")
    pole("roof crest",(-1.32,.08,2.71),(1.32,.08,2.71),.090,"cedar_dark")
    # Small linen pennants provide a distinct silhouette while keeping herbs
    # visible; the rack intentionally has an open roof for air circulation.
    for n,tone in enumerate(("pale","sage_light","lilac","pale","pink","sage_light")):
        x=-1.08+n*.43
        b.mesh("hand-cut linen pennant",
               [(x-.15,-.47,2.34),(x+.15,-.47,2.34),
                (x,-.49,2.10)],[(0,2,1)],tone)
    for x,c in [(-.97,"sage_light"),(-.49,"lavender"),(0,"grass"),
                (.48,"lilac"),(.94,"sage")]:
        herb_bundle(x,-.38,1.80,c,.86)
    box("bottom solid sorting shelf",(0,.17,.53),(2.22,1.21,.13),
        "cedar",.055)
    for x in (-.7,-.31,.08,.49):
        box("individual wooden shelf plank",(x,.16,.60),(.06,1.13,.018),
            "cedar_dark",.005)
    woven_basket(-.61,-.33,.65,.76)
    woven_basket(.57,.27,.65,.62)
    for x,y in [(-.74,-.34),(-.60,-.23),(.47,.27),(.62,.24)]:
        ball("freshly gathered herb heap",(x,y,.87),(.13,.14,.11),"sage_light")
    box("tiny parchment harvest note",(.07,-.50,.73),(.35,.025,.34),
        "pale",.015)
    for x,y in [(-1.45,-.68),(1.38,.72)]:
        grass_tip(x,y,.35,"grass")


def rainwater_collector():
    """Copper-and-cedar rain collector, roof-fed cistern, spout and basin."""
    ground_stones(1.14,.85,.18,12)
    cylinder("wide stave-built rain barrel",(0,.12,.94),.68,.77,1.34,"cedar",18)
    for n in range(18):
        a=n*math.tau/18
        x=math.cos(a)*.735
        y=.12+math.sin(a)*.735
        pole("individual stave grain",(x,y,.35),(x,y,1.51),.018,
             "cedar_dark",6)
    for h in (.55,1.20,1.54):
        cylinder("aged jade iron barrel hoop",(0,.12,h),.787,.787,
                 .105,"sage_dark",20)
    cylinder("wide raised rim",(0,.12,1.61),.79,.79,.16,
             "cedar_dark",20)
    cylinder("glimmering rainwater surface",(0,.12,1.705),.66,.66,.024,
             "water",22)
    for x,y in [(-.25,-.05),(.16,.36),(.38,-.02)]:
        ball("scattered water sheen",(x,y,1.727),(.14,.045,.012),
             "sky")
    # Slanted teal collection canopy on a pair of tall weathered posts.
    for x in (-.73,.73):
        pole("rain-catching roof timber",(x,.78,.08),(x,.78,2.69),
             .086,"cedar_dark")
    b.mesh("angled turquoise rain shield",
        [(-1.14,-.87,2.39),(1.14,-.87,2.39),
         (1.04,.97,2.92),(-1.04,.97,2.92)],
        [(0,1,2,3)],"sage")
    for x in (-1.06,-.54,0,.54,1.06):
        pole("roof standing seam",(x,-.81,2.42),(x,.93,2.87),
             .025,"sage_dark",7)
    pole("cast brass gutter",(-1.19,-.92,2.40),(1.19,-.92,2.40),
         .090,"honey",12)
    pole("rainwater downpipe",(.90,-.91,2.41),
         (.90,-.91,1.24),.071,"sage_dark",12)
    pole("downpipe return elbow",(.90,-.91,1.25),
         (.58,-.59,1.29),.071,"sage_dark",12)
    # Faucet is legible from the camera-facing (-Y) side.
    pole("brass tap spindle",(0,-.65,.85),(0,-1.00,.85),
         .08,"honey",12)
    box("cross tap lever",(.0,-1.00,.98),(.38,.10,.058),
        "cedar_dark",.018)
    ball("tap handle cap",(0,-1.02,1.02),(.07,.055,.07),"honey")
    cylinder("low catchment bucket",(.18,-1.17,.32),.43,.48,.41,
             "stone_light",16)
    cylinder("water in catchment bucket",(.18,-1.17,.54),.38,.38,.03,
             "water",16)
    for x,y in [(-1.13,.27),(1.19,.52)]:
        rosette(x,y,.43,"pink",.64)


def wildflower_crescent():
    """Low, freely repeatable meadow border with a crescent of fieldstones."""
    for j in range(9):
        t = -.08 + (j/8)*math.pi*1.08
        x=-1.35+2.7*j/8
        y=.35*math.sin(t)+.06*(j%2)
        stone = ball("organic paving-edge fieldstone",(x,y,.105),
                     (.19,.16,.135),"stone_light" if j%3==0 else "stone",10)
        stone.rotation_euler[2]= t*.6
    positions=[
        (-1.02,-.17,.53,"lavender",.83),(-.68,-.28,.76,"lilac",.94),
        (-.33,-.16,.57,"cream",.74),(.08,-.34,.77,"pink",.88),
        (.47,-.20,.66,"lilac",.87),(.86,-.14,.75,"cream",.87),
        (1.19,-.06,.47,"pink",.71),(-.87,.36,.56,"cream",.73),
        (-.17,.41,.68,"lavender",.83),(.60,.41,.47,"pink",.67)]
    for x,y,z,c,s in positions:
        rosette(x,y,z,c,s)
    for x,y in [(-1.21,.15),(-.47,.15),(.32,.10),(1.22,.21),
                (-.99,-.49),(.85,-.50)]:
        grass_tip(x,y,.48,"grass")
    for x,y in [(-.53,.49),(.72,.19)]:
        cylinder("little wild mushroom stalk",(x,y,.19),.045,.05,.28,
                 "cream",10)
        ball("plump blush mushroom cap",(x,y,.37),(.15,.14,.085),
             "terracotta")
    # Butterflies give life without relying on gameplay animation.
    for dx,color in [(-.13,"pink"),(.13,"lavender")]:
        wing=ball("fluttering butterfly wing",(.40+dx,-.18,1.03),
                  (.17,.035,.135),color)
        wing.rotation_euler[1]= dx*1.8
    pole("butterfly body",(.40,-.19,.90),(.40,-.19,1.14),.029,
         "cedar_dark",8)


ASSETS = [
    ("pollinator_house", pollinator_house, 4.60, 1.48),
    ("herb_drying_rack", herb_drying_rack, 4.55, 1.46),
    ("rainwater_collector", rainwater_collector, 4.40, 1.45),
    ("wildflower_crescent", wildflower_crescent, 3.76, .62),
]


def render(asset_id, builder, ortho, focus):
    camera = b.scene_base()
    builder()
    target = Vector((0,0,focus))
    camera.location = target + Vector((7,-9,8))
    camera.rotation_euler = (target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type="ORTHO"
    camera.data.ortho_scale=ortho
    bpy.context.view_layer.update()
    pos=world_to_camera_view(bpy.context.scene,camera,Vector((0,0,.05)))
    anchor=[round(pos.x*1024),round((1-pos.y)*1024)]
    bpy.context.scene.render.filepath=str(RAW/(asset_id+".png"))
    print("V11_RENDER_START",asset_id,"objects",len(bpy.context.scene.objects),
          "anchor",anchor,flush=True)
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLENDS/(asset_id+".blend")),
                               compress=True)
    print("V11_RENDER_DONE",asset_id,flush=True)
    return anchor


def main():
    for folder in (RAW,BLENDS):
        folder.mkdir(exist_ok=True,parents=True)
        (folder / ".gdignore").touch()
    palette()
    anchors={}
    for name,builder,ortho,focus in ASSETS:
        anchors[name]=render(name,builder,ortho,focus)
    (RAW/"untrimmed_anchors.json").write_text(json.dumps(anchors,indent=2)+"\n",
                                              encoding="utf-8")
    print("ART_V11_BLENDER_COMPLETE",anchors,flush=True)


if __name__=="__main__":
    main()
