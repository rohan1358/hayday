"""Kebun Ceria: five original isometric farm sprites.

Requires Blender 5.2 and the existing art_v2 generator (read-only dependency).
Run: blender --background --factory-startup --python assets/art_v3/generate_assets.py
Then run: py assets/art_v3/finalize_assets.py
Only files inside art_v3 are written.
"""

import bpy
import json
import math
import random
import sys
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "art_v2"))
import generate_assets as b  # shared geometry, materials and camera, never writes to art_v2

OUT = HERE / "_render_source"
SIZE = 1024
R = random.Random(20261106)


def new_palette():
    b.setup_materials()
    extra = {
        "hen_gold": "#ebae4f", "hen_light": "#f8e1a1", "comb": "#d65c49",
        "beak": "#f3bc56", "tiny_eye": "#392b31", "wood_sun": "#f3c58a",
        "cow_white": "#f6e6ca", "cow_spot": "#a87055", "cow_shadow": "#d6bfa8",
        "cow_nose": "#e6a99f", "corn_dark": "#477a4b", "corn_leaf": "#5caa54",
        "corn_yellow": "#f1bc50", "corn_gold": "#f9d17a", "corn_husk": "#9bb75c",
        "carrot": "#e98435", "carrot_light": "#f5a74d", "seedling": "#8dc66d",
        "pasture": "#a1c579", "pasture_edge": "#71a264", "trough": "#7aaeb0",
    }
    b.M.update({k: b.material(k, v) for k, v in extra.items()})


def moved_new(before, dx, dy, dz=0):
    for obj in set(bpy.context.scene.objects) - before:
        obj.location += Vector((dx, dy, dz))


def gable_hut(cx, cy, w, depth, height, peak, wall_color, roof_color, door_color):
    """Warm timber hut with red tile roof, moved as one set from the origin."""
    before = set(bpy.context.scene.objects)
    b.box("raised stone plinth", (0, 0, .29), (w+.17, depth+.16, .30), "stone_light", .08)
    b.box("painted timber walls", (0, 0, (height+.35)/2), (w,depth,height-.35), wall_color,.045)
    b.gable_walls(w, depth, height, peak, wall_color)
    b.roof(w,depth,height+.03,peak+.04,roof_color,"roof_deep",tile_color="roof_light")
    for x in (-w/2+.10,w/2-.10):
        b.box("hut ivory trim",(x,-depth/2-.04,(height+.3)/2),(.11,.08,height-.3),"ivory",.017)
    b.box("threshold",(0,-depth/2-.18,.35),(.88,.37,.15),"wood_light",.035)
    b.box("dark door frame",(0,-depth/2-.07,.80),(.83,.14,.99),"wood_dark",.05)
    b.box("hut wooden door",(0,-depth/2-.16,.81),(.67,.06,.87),door_color,.034)
    for x in (-.22,0,.22):
        b.pole("door timber groove",(x,-depth/2-.20,.47),(x,-depth/2-.20,1.20),.010,"wood_dark",6)
    b.orb("door knob",(.23,-depth/2-.218,.79),(.034,.028,.034),"straw_light",10,6)
    # round loft hatch at the front gable
    b.orb("round loft trim",(0,-depth/2-.035,height+.26),(.19,.055,.19),"wood_light",20,9)
    b.orb("round loft interior",(0,-depth/2-.09,height+.26),(.137,.029,.137),"glass_dark",18,8)
    moved_new(before,cx,cy)


def grass_paddock(width, depth):
    b.box("pasture base",(0,0,.12),(width,depth,.21),"pasture_edge",.16)
    b.box("pasture surface",(0,0,.245),(width-.10,depth-.10,.085),"pasture",.15)
    # Scatter patches without interfering with sprite silhouettes.
    for x,y in [(-1.78,-.88),(-1.28,-1.21),(.18,1.11),(1.83,.65),(-1.67,.73),(1.65,-1.08)]:
        b.orb("patch of clover",(x,y,.295),(.23,.14,.026),"grass_light",12,7)
    for x,y in [(-2.02,.25),(1.96,.45),(1.48,-.91),(-1.68,-.77)]:
        b.grass_tuft(x,y,.58)


def fence(width,depth,front_height=.83):
    """A single attached pen fence: visible front, two sides, and rear."""
    xedge, yedge = width/2-.10, depth/2-.10
    # Rear posts and top timber rail.
    for x in (-xedge, -xedge/2, 0, xedge/2, xedge):
        b.pole("fence rear post",(x,yedge,.27),(x,yedge,1.15),.080,"wood_light",8)
        b.orb("fence post cap",(x,yedge,1.16),(.10,.10,.045),"ivory",10,6)
    for z in (.56,.94):
        b.pole("rear horizontal fence rail",(-xedge,yedge,z),(xedge,yedge,z),.059,"wood",8)
    # Keep front rails low enough to see the animals and doors.
    for x in (-xedge,-xedge/2,0,xedge/2,xedge):
        b.pole("front fence post",(x,-yedge,.26),(x,-yedge,front_height),.083,"wood_light",8)
        b.orb("front round cap",(x,-yedge,front_height+.025),(.11,.11,.055),"butter",10,6)
    for z in (.42,.65):
        b.pole("front horizontal rail",(-xedge,-yedge,z),(xedge,-yedge,z),.058,"wood",8)
    # Side rails connect with front/back and make the fences a cohesive object.
    for x in (-xedge,xedge):
        for y in (-yedge/3,yedge/3):
            b.pole("fence side post",(x,y,.26),(x,y,1.02),.077,"wood_light",8)
        for z in (.52,.84):
            b.pole("side fence rail",(x,-yedge,z),(x,yedge,z),.057,"wood",8)


def chick(x,y,scale=1.0,feather="hen_light"):
    """Chubby, readable hen including comb, eyes, beak, wings, feet and tail."""
    before=set(bpy.context.scene.objects)
    b.orb("hen body",(0,.03,.57),(.30,.34,.27),feather,18,12)
    b.orb("hen chest",(0,-.17,.62),(.25,.22,.26),feather,16,10)
    b.orb("hen face",(0,-.28,.78),(.20,.18,.18),feather,16,10)
    for sx in (-1,1):
        b.orb("hen wing",(sx*.245,.0,.57),(.115,.19,.125),"hen_gold",12,8)
        b.orb("shiny eyes",(sx*.095,-.431,.82),(.034,.019,.036),"tiny_eye",12,7)
        b.orb("eye glint",(sx*.108,-.452,.837),(.010,.008,.013),"white",8,5)
        b.pole("tiny orange leg",(sx*.11,-.03,.32),(sx*.11,-.09,.24),.032,"beak",7)
        for dx in (-.055,.055):
            b.pole("hen toes",(sx*.11,-.09,.235),(sx*.11+dx,-.20,.23),.018,"beak",6)
    b.mesh("triangular yellow beak",[(-.08,-.44,.75),(.08,-.44,.75),(0,-.61,.71),(0,-.45,.66)],[(0,1,2),(0,3,1),(0,2,3),(1,3,2)],"beak")
    for i in range(3):
        b.orb("combed crown",(-.115+i*.11,-.32,.958),(.07,.064,.105 if i==1 else .08),"comb",10,7)
    for sx in (-1,1):
        b.orb("back tail feathers",(sx*.11,.33,.83),(.095,.12,.18),"hen_gold",12,8)
    for obj in set(bpy.context.scene.objects)-before:
        obj.location = Vector((x,y,.17))+obj.location*scale


def chicken_coop():
    grass_paddock(4.7,3.6)
    gable_hut(-.88,.73,1.74,1.32,1.53,2.28,"cream","roof","wood")
    # Slanted access ramp and low steps, visible in front of the coop.
    ramp=b.box("chicken access ramp",(-.84,-.49,.43),(.52, .82,.095),"wood_light",.03)
    ramp.rotation_euler[0]=-.25
    for y in (-.74,-.49,-.24):
        b.box("ramp slat",(-.84,y,.51),(.53,.06,.047),"wood_dark",.013)
    chick(.47,-.20,1.0,"hen_light")
    chick(1.35,-.57,.77,"hen_gold")
    chick(.12,.64,.68,"white")
    # Feed trough, grain and hay to add warmth.
    b.box("feed trough",(1.32,.62,.34),(.60,.31,.19),"wood",.05)
    for x in (1.11,1.35,1.58):
        b.orb("corn kernels",(x,.60,.44),(.045,.05,.026),"straw_light",10,6)
    for i in range(8):
        x=-1.75+R.uniform(-.14,.14); y=.15+R.uniform(-.17,.17)
        b.pole("loose straw",(x,y,.34),(x+.25,y+.02,.42),.016,"straw_light",6)
    fence(4.7,3.6,front_height=.81)


def cow(x,y,scale=1.0):
    before=set(bpy.context.scene.objects)
    # Friendly milking cow facing the player (-Y).
    b.orb("cow torso",(0,.17,.88),(.65,.62,.46),"cow_white",20,14)
    b.orb("cow neck",(0,-.34,1.01),(.39,.29,.39),"cow_white",16,12)
    b.orb("cow face",(0,-.51,1.11),(.36,.28,.41),"cow_white",18,12)
    b.orb("cow pink muzzle",(0,-.765,.91),(.31,.16,.215),"cow_nose",18,12)
    for sx in (-1,1):
        b.box("cow strong leg",(sx*.39, -.25,.40),(.22,.25,.64),"cow_shadow",.055)
        b.box("cow back leg",(sx*.37,.55,.41),(.23,.25,.62),"cow_white",.06)
        b.box("cloven hoof",(sx*.39,-.28,.145),(.23,.30,.15),"wood_dark",.04)
        b.box("rear hoof",(sx*.37,.56,.15),(.23,.30,.16),"wood_dark",.035)
        b.orb("cow floppy ear",(sx*.37,-.49,1.37),(.21,.105,.13),"cow_spot",14,9)
        b.orb("cow inner ear",(sx*.39,-.59,1.37),(.12,.03,.07),"cow_nose",12,7)
        b.orb("cow eyes",(sx*.15,-.755,1.23),(.057,.023,.071),"tiny_eye",12,7)
        b.orb("cow eye sparkle",(sx*.165,-.777,1.25),(.014,.012,.018),"white",9,5)
        b.orb("nostril",(sx*.115,-.92,.935),(.035,.017,.022),"cow_spot",10,7)
        b.pole("little horns",(sx*.18,-.52,1.47),(sx*.22,-.53,1.66),.048,"ivory",9)
    for cx,cy,cz,sz in [(-.34,-.08,1.03,.25),(.38,.31,1.08,.31),(-.15,.65,1.05,.20)]:
        b.orb("rounded brown cow patches",(cx,cy,cz),(.23,.19,sz),"cow_spot",14,9)
    b.pole("cow thin tail",(0,.73,.91),(-.08,1.02,.50),.052,"cow_shadow",8)
    b.orb("cow tail tuft",(-.09,1.03,.43),(.09,.09,.13),"cow_spot",10,7)
    b.orb("udder",(0,.30,.52),(.23,.21,.16),"cow_nose",12,8)
    for obj in set(bpy.context.scene.objects)-before:
        obj.location=Vector((x,y,.07))+obj.location*scale


def cow_pen():
    grass_paddock(5.1,3.9)
    gable_hut(-1.08,.84,1.88,1.42,1.76,2.55,"red_light","roof_deep","wood_dark")
    # Carved-out stable entry look with cross slats.
    b.box("stall feeding hatch",(-1.08,.029,1.01),(.65,.07,.54),"wood_dark",.04)
    b.pole("stall latch",(-1.4,-.04,1.02),(-.76,-.04,1.02),.034,"ivory",8)
    cow(.73,-.26,1.0)
    b.box("water trough",(-.95,-.94,.39),(.82,.37,.30),"wood_dark",.075)
    b.box("trough water",(-.95,-.94,.55),(.66,.28,.045),"trough",.025)
    b.box("small hay bale",(1.91,.74,.45),(.55,.43,.40),"straw",.07)
    for y in (.56,.75):
        b.pole("hay rope",(1.65,y,.62),(2.16,y,.62),.016,"straw_dark",8)
    fence(5.1,3.9,front_height=.84)


def corn_stalk(x,y,height):
    z_base=.50
    sway=R.uniform(-.07,.07)
    b.pole("corn trunk",(x,y,z_base),(x+sway,y,height),.038,"corn_dark",9)
    for j in range(4):
        z=z_base+.37+j*.30
        direction=1 if j%2 else -1
        far=R.uniform(.24,.41)
        leaf=b.orb("long corn leaf",(x+direction*far/2,y-.035,z+.12),(.34,.085,.043),"corn_leaf" if j%2 else "grass",12,8)
        leaf.rotation_euler[1]=-direction*.34
    # Plump golden cob poking from green protective husk.
    side=1 if x>0 else -1
    cx=x+side*.135; cy=y-.14; cz=height-.41
    b.orb("gold ripe ear",(cx,cy,cz),(.125,.128,.37),"corn_yellow",14,10)
    for i in range(4):
        b.orb("highlight corn grain",(cx-side*.055,cy-.103,cz-.23+i*.13),(.028,.021,.047),"corn_gold",9,6)
    for sx in (-1,1):
        leaf=b.orb("split corn husk",(cx+sx*.10,cy+.02,cz-.16),(.073,.08,.27),"corn_husk",12,8)
        leaf.rotation_euler[1]=sx*.35
    b.pole("silky corn tassel",(x+sway,y,height),(x+sway,y,height+.24),.016,"straw_light",7)
    for side in (-1,1):
        b.pole("tassel tip",(x+sway,y,height+.16),(x+sway+side*.15,y,height+.29),.012,"straw",6)


def corn_plot_ready():
    b.soil_base()
    for col,x in enumerate((-.96,-.38,.22,.84)):
        for row,y in enumerate((-.72,-.03,.67)):
            corn_stalk(x+R.uniform(-.05,.05),y+R.uniform(-.05,.05),R.uniform(1.62,2.01))


def carrot_plant(x,y,variant):
    # Top half of carrot peeks from the soil; tapered orange root points downward.
    bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=.058,radius2=.15,depth=.31,location=(x,y,.58))
    b.assign(bpy.context.object,"carrot_light" if variant%3==0 else "carrot")
    for z in (.62,.73):
        b.pole("carrot ring",(x-.09,y-.117,z),(x+.085,y-.117,z+.012),.009,"orange_dark",6)
    b.orb("carrot green crown",(x,y,.76),(.15,.13,.065),"grass_dark",12,8)
    for j in range(5):
        angle=(j/5)*math.tau
        xx=x+math.cos(angle)*.18; yy=y+math.sin(angle)*.15
        b.pole("fine carrot stem",(x,y,.76),(xx,yy,.97+R.uniform(-.05,.07)),.018,"stem",7)
        leaf=b.orb("carrot feathery leaves",(xx,yy,1.01+R.uniform(-.02,.07)),(.14,.07,.055),"leaf_light" if j%2 else "corn_leaf",10,7)
        leaf.rotation_euler[2]=angle


def carrot_plot_ready():
    b.soil_base()
    for col,x in enumerate((-.99,-.37,.27,.91)):
        for row,y in enumerate((-.73,-.03,.69)):
            carrot_plant(x+R.uniform(-.055,.055),y+R.uniform(-.06,.06),row+col)
    for x,y in [(-1.18,-.84),(1.13,.79)]:
        b.grass_tuft(x,y,.40)


def baby_sprout(x,y,scale):
    z=.47
    b.pole("seedling stem",(x,y,z),(x,y,z+.22*scale),.014,"stem",7)
    for d in (-1,1):
        leaf=b.orb("seedling pair of leaves",(x+d*.13*scale,y-.028,z+.18*scale),(.145*scale,.075*scale,.044*scale),"seedling" if d==1 else "leaf_light",12,8)
        leaf.rotation_euler[1]=d*.35
    b.orb("emerging bud",(x,y,z+.25*scale),(.047,.045,.064),"grass_light",10,7)


def young_seedlings():
    b.soil_base()
    for col,x in enumerate((-.93,-.30,.34,.96)):
        for row,y in enumerate((-.70,-.02,.68)):
            baby_sprout(x+R.uniform(-.055,.055),y+R.uniform(-.055,.055),R.uniform(.82,1.22))
    # Pale irrigation marker implies an early growth phase.
    b.box("small field marker",(1.17,.96,.62),(.19,.09,.32),"wood_light",.03)


ASSETS=[
    ("chicken_coop", chicken_coop, 7.1, 1.32),
    ("cow_pen", cow_pen, 7.8, 1.52),
    ("corn_plot_ready", corn_plot_ready, 4.68, 1.02),
    ("carrot_plot_ready", carrot_plot_ready, 4.33, .75),
    ("young_seedlings", young_seedlings, 4.33, .64),
]


def main():
    OUT.mkdir(exist_ok=True,parents=True)
    new_palette()
    result={}
    for index,(name,maker,ortho,center_height) in enumerate(ASSETS):
        b.RNG.seed(260611+index)
        R.seed(20261106+index)
        camera=b.scene_base()
        maker()
        point=Vector((0,0,center_height))
        camera.location=point+Vector((7,-9,8.0))
        camera.rotation_euler=(point-camera.location).to_track_quat("-Z","Y").to_euler()
        camera.data.type="ORTHO"
        camera.data.ortho_scale=ortho
        bpy.context.view_layer.update()
        pv=world_to_camera_view(bpy.context.scene,camera,Vector((0,0,.06)))
        foot=[round(pv.x*SIZE),round((1-pv.y)*SIZE)]
        result[name]=foot
        bpy.context.scene.render.filepath=str(OUT/(name+".png"))
        print(f"ASSET_RENDER {name} base_anchor={foot}",flush=True)
        bpy.ops.render.render(write_still=True)
    (OUT/"untrimmed_anchors.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print("RENDER_COMPLETE 5 original sprites",flush=True)


if __name__=="__main__":
    main()
