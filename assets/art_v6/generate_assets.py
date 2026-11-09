"""Blender 5.2 generator for six original 3/4 orthographic farm sprites.

Usage from the HayDay project root:
  blender --background --factory-startup --python assets/art_v6/generate_assets.py

Read-only imports of art_v2 shape/lighting primitives. Output stays in art_v6.
"""

import json
import math
import random
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "_render_source"
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT.parent / "art_v2"))
import generate_assets as b

RNG = random.Random(63910)
RES = 1024


def palette():
    b.setup_materials()
    tones = {
        "oak": "#b88350", "oak_sun": "#e3ac67", "oak_rim": "#f2c78d",
        "oak_deep": "#7d5038", "oak_mid": "#9a623d", "grain": "#86563e",
        "wicker": "#d6ab68", "wicker_gold": "#f3d189", "wicker_shade": "#a77847",
        "rope": "#d7bf83", "iron": "#625d53", "brass": "#c49558",
        "apple": "#e36955", "peach_fruit": "#f59a73", "pear": "#bfda83",
        "carrot": "#f7a250", "pumpkin": "#e1a34e", "leafdeep": "#4c875c",
        "leafmid": "#77b577", "leafsun": "#a5d189", "leafcool": "#8cbd99",
        "soil_earth": "#77533f", "soil_rim": "#97694b", "grass_bright": "#b5d78b",
        "stone_warm": "#d6c6a4", "stone_shade": "#9e9c84", "stone_cream": "#eee0bc",
        "water_dark": "#438c99", "water_teal": "#6dc0c1", "water_light": "#b7e0d8",
        "roof_red": "#ce725b", "roof_sun": "#eb9972", "roof_deep": "#9b5448",
        "petal_pink": "#f6a0a9", "petal_coral": "#f4a27c", "petal_lilac": "#c4acdc",
        "petal_cream": "#fff0c7", "petal_gold": "#f4d07c", "petal_rose": "#dd7b95",
        "sky_paint": "#92bcb5", "sky_paint_dark": "#5e9592", "copper": "#bd875b",
        "copper_sun": "#e2ab72", "barrel_dark": "#865a3e", "cattail": "#805c47",
    }
    b.M.update({name: b.material(name, color) for name, color in tones.items()})


def orb(name, xyz, radii, mat, seg=16):
    return b.orb(name, xyz, radii, mat, seg, 9)


def leaf(x, y, z, angle=0.0, sx=.15, sy=.074, mat="leafsun"):
    o = orb("soft spear leaf", (x, y, z), (sx, sy, .032), mat, 12)
    o.rotation_euler[2] = angle
    return o


def pebble(x, y, z, r=.12, mat="stone_warm"):
    p = orb("rounded pebble", (x, y, z), (r, r*.82, r*.55), mat, 10)
    p.rotation_euler[2] = RNG.uniform(-.6,.6)


def blossom(x, y, z, mat="petal_coral", radius=.091):
    for t in range(5):
        a = t*math.tau/5
        orb("five-petal flower", (x+math.cos(a)*radius, y+math.sin(a)*radius, z),
            (radius*.98, radius*.84, radius*.31), mat, 10)
    orb("marigold pollen", (x,y,z+radius*.42), (radius*.58,)*3, "petal_gold", 10)


def vein(x, y, z, dx, dy, mat="grain", r=.008):
    b.pole("fine natural texture stroke", (x,y,z), (x+dx,y+dy,z), r, mat, 6)


def ring(name, xyz, rx, ry, width, color):
    bpy.ops.mesh.primitive_torus_add(major_segments=36, minor_segments=8,
                                     major_radius=1, minor_radius=width, location=xyz)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (rx,ry,(rx+ry)*.5)
    b.assign(obj,color)
    return obj


def flat_ground(radius_x=1.2,radius_y=.7):
    orb("soft soil foundation", (0,0,.095), (radius_x,radius_y,.10), "soil_rim", 32)
    orb("patch of flowering green", (0,0,.175), (radius_x*.90,radius_y*.86,.083), "grass", 32)


def scatter_grass(points, scale=.65):
    for x,y in points:
        b.grass_tuft(x,y,scale*RNG.uniform(.78,1.15))


# --- Harvest baskets ------------------------------------------------------

def basket(x,y,z,r=.51,height=.53,kind="apples"):
    """Tapered woven wicker basket with open dark interior and crossed reeds."""
    bottom_r, top_r = r*.82, r
    bpy.ops.mesh.primitive_cone_add(vertices=18, radius1=bottom_r, radius2=top_r,
                                    depth=height, location=(x,y,z+height*.5))
    shell=bpy.context.object
    shell.name="handwoven tapered basket"
    b.assign(shell,"wicker")
    orb("deep shadow inside basket", (x,y,z+height-.035), (r*.86,r*.86,.038), "wicker_shade", 32)
    ring("continuous rolled basket lip",(x,y,z+height),r,r,.062,"wicker_gold")
    for row in range(4):
        frac=(row+.65)/5
        rr=bottom_r+(top_r-bottom_r)*frac
        zz=z+frac*height
        # 18 staggered, segmented reed strokes at each weave level.
        for i in range(18):
            a=math.tau*(i+(row%2)*.45)/18
            a2=a+math.tau*.85/18
            b.pole("arched wicker weft", (x+rr*math.cos(a),y+rr*math.sin(a),zz),
                   (x+rr*math.cos(a2),y+rr*math.sin(a2),zz+.023*(1 if i%2 else -1)),
                   .025,"wicker_gold" if row%2 else "wicker_shade",6)
    for i in range(18):
        a=math.tau*i/18
        b.pole("vertical basket reed", (x+bottom_r*math.cos(a),y+bottom_r*math.sin(a),z+.055),
               (x+top_r*math.cos(a),y+top_r*math.sin(a),z+height-.025),
               .016,"wicker_shade" if i%2 else "wicker_gold",6)
    if kind=="apples":
        fruit_tones=["apple","peach_fruit","apple","pear","apple"]
        for i,(dx,dy) in enumerate([(-.24,-.15),(.05,-.23),(.27,.01),(-.21,.22),(.04,.18)]):
            fz=z+height+.038+(i%2)*.04
            orb("shiny orchard apple", (x+dx,y+dy,fz), (.155,.145,.143), fruit_tones[i])
            b.pole("apple stalk", (x+dx,y+dy,fz+.12),(x+dx+.02,y+dy,fz+.20),.013,"oak_deep",6)
            leaf(x+dx+.068,y+dy+.012,fz+.166,.3,.078,.043)
    elif kind=="carrots":
        for i,(dx,dy) in enumerate([(-.20,-.15),(.10,-.22),(.21,.10),(-.16,.21)]):
            xx,yy=x+dx,y+dy
            bpy.ops.mesh.primitive_cone_add(vertices=10,radius1=.09,radius2=.16,depth=.39,
                                            location=(xx,yy,z+height+.08))
            b.assign(bpy.context.object,"carrot")
            for j in (-1,0,1):
                leaf(xx+j*.045,yy,z+height+.31, j*.43,.095,.028,"leafmid")
    else:
        for i,(dx,dy,size) in enumerate([(-.18,-.13,.19),(.16,-.11,.18),(.01,.18,.2)]):
            orb("round golden pumpkin",(x+dx,y+dy,z+height+.056),
                (size,size*.94,size*.78),"pumpkin" if i!=1 else "peach_fruit",18)
            for s in (-1,1):
                b.pole("pumpkin ridge",(x+dx+s*size*.52,y+dy-.07,z+height+.073),
                       (x+dx+s*size*.52,y+dy+.08,z+height+.073),.012,"carrot",6)
            b.pole("pumpkin vine",(x+dx,y+dy,z+height+.18),
                   (x+dx+.03,y+dy,z+height+.28),.017,"leafdeep",6)


def harvest_baskets():
    basket(-.76,.08,.075,.59,.61,"apples")
    basket(.57,.28,.08,.55,.57,"carrots")
    basket(.05,-.73,.055,.47,.51,"pumpkins")
    pebble(-1.36,-.65,.11,.12)
    pebble(.97,-.55,.10,.095,"stone_cream")
    orb("loose fallen apple",(-1.34,.15,.145),(.12,.13,.13),"apple")
    scatter_grass([(-1.25,.55),(.99,.72),(1.14,-.30),(-.56,-1.18)],.75)


# --- Directional rustic sign ----------------------------------------------

def arrow_board(label, z, direction=1, tilt=0):
    """Closed extruded arrow silhouette with carved front lettering."""
    if direction==1:
        verts=[(-.75,-.22),(.92,-.22),(1.25,0),(.92,.22),(-.75,.22)]
    else:
        verts=[(.75,-.22),(-.92,-.22),(-1.25,0),(-.92,.22),(.75,.22)]
    # Board lies in XZ plane, front at y=-.20.
    coords=[(xx,-.26,z+zz) for xx,zz in verts]
    coords += [(xx,-.13,z+zz) for xx,zz in verts]
    n=len(verts)
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    ob=b.mesh("hand-carved direction arrow",coords,faces,"oak_sun" if direction==1 else "oak")
    ob.rotation_euler[1]=tilt
    b.pole("weathered board grain",(-.65,-.283,z-.12),(.60,-.283,z-.10),.011,"oak_mid",6)
    b.pole("second board grain",(-.54,-.284,z+.125),(.44,-.284,z+.128),.009,"oak_rim",6)
    for xx in (-.59,.56):
        orb("small decorative nail",(xx,-.292,z),(.032,.012,.032),"brass",9)
    # Raised lettering is readable on the large original sprite.
    curve=bpy.data.curves.new(f"engraved {label}","FONT")
    curve.body=label
    curve.align_x="CENTER"
    curve.align_y="CENTER"
    curve.size=.255
    curve.extrude=.002
    curve.bevel_depth=.001
    text_obj=bpy.data.objects.new(f"hand-painted {label} label",curve)
    bpy.context.collection.objects.link(text_obj)
    text_obj.location=(.01,-.307,z)
    text_obj.rotation_euler[0]=math.pi/2
    b.assign(text_obj,"oak_deep")


def wooden_signpost():
    b.box("oak post with soft edges",(0,0,1.35),(.26,.26,2.58),"oak_deep",.06)
    b.box("post top decorative golden cap",(0,0,2.70),(.40,.39,.18),"oak_rim",.05)
    b.box("post top dark plug",(0,0,2.83),(.22,.22,.13),"oak_mid",.04)
    arrow_board("PANEN",2.18,1,.012)
    arrow_board("KEBUN",1.57,-1,-.012)
    for z in (.36,1.11,2.43):
        b.pole("golden carved post band",(-.122,-.146,z),(.122,-.146,z),.019,"oak_rim",6)
    b.box("foundation stone",(0,0,.17),(.74,.70,.31),"stone_shade",.115)
    for x,y in [(-.42,-.38),(.51,.13),(-.30,.43)]:
        pebble(x,y,.07,.12,"stone_cream")
    scatter_grass([(-.43,.26),(.33,-.43),(.57,.4),(-.56,-.14)],.80)
    blossom(-.45,-.18,.33,"petal_pink",.077)
    blossom(.42,.21,.34,"petal_lilac",.084)


# --- Covered stone water well ---------------------------------------------

def roof_half(side):
    # A roof with thick exposed warm clay tiles, no Supercell art reference.
    a=0
    left,right=-1.12,1.12
    bottom=1.88
    peak=2.60
    verts=[(0,-.85,peak),(0,.86,peak),
           (side*1.00,.87,bottom),(side*1.00,-.85,bottom)]
    underside=[(x,y,z-.13) for x,y,z in verts]
    b.mesh("red clay pitched well canopy",verts+underside,
           [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],
           "roof_red" if side==1 else "roof_sun")
    for j in range(4):
        frac=(j+.65)/5
        x=side*frac
        z=peak-(peak-bottom)*frac+.023
        for k in range(5):
            y=-.66+k*.34
            tile=b.box("individual curved canopy tile",(x,y,z),(.23,.27,.045),
                       "roof_sun" if (j+k)%3 else "roof_deep",.038)
            tile.rotation_euler[1]=-side*math.atan2(peak-bottom,1.0)
    b.pole("smooth side fascia",(0,-.87,peak),(side*1,-.87,bottom),.052,"oak_deep",8)
    b.pole("rear roof fascia",(0,.88,peak),(side*1,.88,bottom),.046,"oak_deep",8)


def wishing_well():
    # Masonry cylinder built from individually chamfered stones.
    segments=16
    for layer in range(4):
        z=.20+layer*.17
        for i in range(segments):
            ang=math.tau*(i+(layer%2)*.5)/segments
            stone=b.box("varied cobblestone wall",
                        (.75*math.cos(ang),.75*math.sin(ang),z),
                        (.35,.24,.166),
                        ["stone_warm","stone_cream","stone_shade"][((i+layer*3)%7)%3],.065)
            stone.rotation_euler[2]=ang-math.pi/2
    ring("smooth well coping",(0,0,.86),.83,.83,.115,"stone_cream")
    orb("deep water in the well",(0,0,.67),(.65,.64,.05),"water_dark",28)
    orb("reflective well water",(0,0,.705),(.53,.53,.017),"water_teal",28)
    for x in (-.90,.90):
        b.box("thick wooden well support",(x,0,1.38),(.17,.20,1.53),"oak_deep",.03)
        b.box("chamfered well support cap",(x,0,2.16),(.25,.26,.14),"oak_rim",.038)
    b.pole("windlass axle",(-.89,0,1.51),(.90,0,1.51),.11,"oak_mid",12)
    for x in (-.30,.30):
        ring("reel hub ring",(x,0,1.51),.14,.14,.025,"brass")
    b.pole("well handle crank",(.94,0,1.51),(1.12,-.12,1.51),.035,"iron",8)
    b.pole("well handle grip",(1.12,-.12,1.51),(1.12,-.12,1.22),.050,"oak_sun",8)
    b.pole("twisted rope descending",(.0,-.08,1.48),(.01,-.08,.92),.028,"rope",8)
    b.box("wooden bucket lower body",(.01,-.08,.90),(.33,.28,.27),"oak",.055)
    b.box("bucket dark hollow rim",(.01,-.08,1.04),(.34,.30,.045),"oak_deep",.018)
    roof_half(-1)
    roof_half(1)
    b.pole("sunlit ridge cap",(0,-.94,2.62),(0,.93,2.62),.072,"roof_deep",10)
    for x,y in [(-1.09,-.42),(.92,.67),(.05,-1.03)]:
        pebble(x,y,.08,.13,"stone_shade")
    scatter_grass([(-.97,.47),(1.03,-.31),(-.24,-1.01)],.65)
    blossom(-.80,-.67,.21,"petal_pink",.07)


# --- Flowering hedgerow, lower and fuller than art_v5 flower patch --------

def flowering_bushes():
    orb("irregular bark soil edge",(0,0,.125),(1.76,.86,.18),"soil_rim",32)
    orb("groundcover behind bushes",(0,0,.21),(1.66,.74,.13),"grass",32)
    centers=[(-1.00,.06,.48,.59,.43),(-.33,.24,.64,.67,.54),(.43,-.06,.60,.67,.55),(1.03,.22,.47,.53,.43)]
    for i,(x,y,z,rx,rz) in enumerate(centers):
        orb("bush dark inner foliage",(x,y,z),(rx,.47,rz),"leafdeep",24)
        for k in range(13):
            a=k*math.tau/13
            px=x+math.cos(a)*rx*.68+RNG.uniform(-.08,.08)
            py=y+math.sin(a)*.39+RNG.uniform(-.06,.06)
            pz=z+RNG.uniform(-.06,.21)
            rr=RNG.uniform(.19,.34)
            orb("layered soft bush leaf cluster",(px,py,pz),(rr,rr*.94,rr*.86),
                ["leafmid","leafsun","leafcool","leafmid"][k%4],14)
    # Flowers placed on the near / upper surface for clean isometric readability.
    for k in range(64):
        x=RNG.uniform(-1.47,1.47)
        y=RNG.uniform(-.49,.51)
        loc=min(centers,key=lambda c:abs(c[0]-x))
        crown=loc[2]+loc[4]*.64
        z=crown + RNG.uniform(-.13,.19)-.13*(abs(y)/.55)
        mat=["petal_pink","petal_coral","petal_cream","petal_lilac","petal_gold","petal_rose"][k%6]
        blossom(x,y,z,mat,RNG.uniform(.042,.075))
        if k%4==0:
            leaf(x+.1,y,z-.08,RNG.uniform(-1,1),.09,.045,"leafsun")
    scatter_grass([(-1.65,-.22),(-1.26,-.63),(.05,-.74),(1.57,-.16),(1.39,.56)],.76)
    for x,y in [(-1.39,.45),(-.68,-.70),(.78,-.68),(1.39,.45)]:
        pebble(x,y,.10,.095,"stone_warm")


# --- Carved arch with side pickets and climbing roses ---------------------

def arched_fence():
    for x in (-1.25,1.25):
        b.box("heavy farm entrance post",(x,0,1.16),(.23,.27,2.24),"oak",.042)
        b.box("ornate post sunlit cap",(x,0,2.33),(.36,.38,.20),"oak_rim",.04)
        b.box("pointed cap finial",(x,0,2.48),(.19,.18,.16),"oak_deep",.03)
        for h in (.35,1.56):
            b.box("post inset wooden detail",(x,-.152,h),(.16,.025,.095),"oak_sun",.014)
    # Elevated semicircular curved wood beam with narrow segmented inlay.
    def arch_height(x):
        return 2.30+.53*(1-(x/1.25)**2)
    for i in range(18):
        x0=-1.25+i*2.5/18
        x1=-1.25+(i+1)*2.5/18
        z0,z1=arch_height(x0),arch_height(x1)
        b.pole("thick curved oak arch",(x0,0,z0),(x1,0,z1),.12,"oak_deep",8)
        b.pole("small warm arched inlay",(x0,-.08,z0+.01),(x1,-.08,z1+.01),.031,"oak_sun",7)
    # Small flanking wings leave the arch opening unobstructed.
    for side in (-1,1):
        for x in (side*1.65,side*1.99):
            b.box("small tapered picket",(x,0,.64),(.13,.15,1.09),"oak_sun",.026)
            b.box("picket shaped top",(x,0,1.20),(.15,.18,.11),"oak_rim",.033)
        for h in (.48,.92):
            b.pole("side garden fence rail",(side*1.24,0,h),(side*2.09,0,h),.056,"oak_mid",8)
    # Winding vines curl along the upper arch and both supports.
    for side in (-1,1):
        for k in range(9):
            zz=.51+k*.22
            yy=-.16-.025*math.sin(k*.9)
            xx=side*(1.23-.04*math.sin(k*.9))
            if k:
                pz=.51+(k-1)*.22
                b.pole("climbing vine",(side*1.23,yy,pz),(xx,yy,zz),.021,"leafdeep",6)
            leaf(xx+side*.07,yy-.02,zz,side*.7,.14,.062,"leafsun" if k%2 else "leafmid")
            if k in (2,5,8):
                blossom(xx-side*.035,yy-.10,zz+.055,"petal_rose" if side==-1 else "petal_pink",.085)
    for k in range(10):
        x=-1.11+k*2.22/9
        z=arch_height(x)
        leaf(x,-.13,z+.08,RNG.uniform(-.8,.8),.12,.055,"leafmid")
        if k in (2,6,8):
            blossom(x,-.17,z+.11,"petal_cream" if k==6 else "petal_coral",.075)
    scatter_grass([(-2.10,-.20),(-1.59,-.37),(1.64,-.35),(2.12,.22)],.66)
    pebble(-1.39,-.22,.11,.13,"stone_warm")
    pebble(1.45,-.24,.11,.13,"stone_shade")


# --- Raised farm water tower ----------------------------------------------

def water_tower():
    for x in (-.54,.54):
        for y in (-.46,.46):
            b.box("cedar water tower stilts",(x,y,.82),(.19,.20,1.52),"oak_deep",.045)
            b.box("small foundation stone",(x,y,.12),(.30,.30,.22),"stone_shade",.055)
    for y in (-.48,.48):
        b.pole("raised platform crossbeam",(-.65,y,1.43),(.65,y,1.43),.086,"oak",8)
    for x in (-.55,.55):
        b.pole("crossed tower brace A",(x,-.51,.35),(x,.51,1.35),.051,"oak_mid",8)
        b.pole("crossed tower brace B",(x,.51,.35),(x,-.51,1.35),.049,"oak_mid",8)
    b.box("wooden water tank platform",(0,0,1.54),(1.55,1.45,.20),"oak_sun",.075)
    # Individually colored cedar staves wrapped around the cylindrical water tank.
    for k in range(16):
        a=math.tau*k/16
        a2=math.tau*(k+1)/16
        zlo,zhi=1.67,2.88
        r=.69
        vertices=[(r*math.cos(a),r*math.sin(a),zlo),
                  (r*math.cos(a2),r*math.sin(a2),zlo),
                  (r*math.cos(a2),r*math.sin(a2),zhi),
                  (r*math.cos(a),r*math.sin(a),zhi)]
        b.mesh("alternating cedar barrel stave",vertices,[(0,1,2,3)],
               ["oak","oak_sun","oak_mid","oak"][k%4])
        for end in (1.78,2.70):
            b.pole("barrel metal rivet lip",(r*math.cos(a),r*math.sin(a),end),
                   (r*math.cos(a),r*math.sin(a),end+.10),.009,"grain",6)
    for zz in (1.87,2.41,2.77):
        ring("copper water barrel hoop",(0,0,zz),.69,.69,.048,"copper" if zz!=2.41 else "copper_sun")
    # 16-panel rainproof tapered roof on the tank.
    bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=.85,radius2=.07,depth=.48,
                                    location=(0,0,3.05))
    b.assign(bpy.context.object,"sky_paint")
    for i in range(16):
        ang=math.tau*i/16
        b.pole("fine radial roof seam",(.85*math.cos(ang),.85*math.sin(ang),2.81),
               (.06*math.cos(ang),.06*math.sin(ang),3.29),.012,"sky_paint_dark",6)
    orb("tower roof finial",(0,0,3.35),(.11,.11,.12),"brass",12)
    # Front copper drain and wooden faucet lever.
    b.pole("protruding drain tube",(.30,-.68,1.95),(.30,-1.02,1.95),.073,"copper",10)
    b.pole("down-facing drain elbow",(.30,-1.03,1.95),(.30,-1.03,1.74),.067,"copper",10)
    b.pole("oak spigot handle",(.21,-.96,2.06),(.42,-.96,2.06),.038,"oak_sun",8)
    # Mini rung ladder, leaning against near side of tank to read its scale.
    for xx in (-.39,.16):
        b.pole("timber water tower ladder",(xx,-1.16,.10),(xx,-.72,1.70),.047,"oak_deep",8)
    for i in range(7):
        yy=-1.13+i*.064
        zz=.20+i*.224
        b.pole("ladder rung",(-.39,yy,zz),(.16,yy,zz),.034,"oak_sun",8)
    scatter_grass([(-.97,-.34),(.88,.43),(.78,-.75),(-.84,.69)],.76)
    pebble(.45,-1.27,.08,.13,"stone_cream")
    blossom(-.71,-.43,.24,"petal_pink",.075)


ASSETS = [
    ("harvest_baskets",harvest_baskets,4.60,.62),
    ("wooden_signpost",wooden_signpost,4.50,1.43),
    ("wishing_well",wishing_well,4.92,1.35),
    ("flowering_bushes",flowering_bushes,4.64,.60),
    ("arched_fence",arched_fence,5.28,1.39),
    ("water_tower",water_tower,5.64,1.80),
]


def main():
    SOURCE.mkdir(exist_ok=True,parents=True)
    palette()
    anchors={}
    for i,(name,maker,ortho,zcenter) in enumerate(ASSETS):
        RNG.seed(46060+i)
        b.RNG.seed(99560+i)
        camera=b.scene_base()
        maker()
        target=Vector((0,0,zcenter))
        camera.location=target+Vector((7,-9,8))
        camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
        camera.data.type="ORTHO"
        camera.data.ortho_scale=ortho
        bpy.context.view_layer.update()
        ground=world_to_camera_view(bpy.context.scene,camera,Vector((0,0,.05)))
        anchors[name]=[round(ground.x*RES),round((1-ground.y)*RES)]
        bpy.context.scene.render.filepath=str(SOURCE/(name+".png"))
        print(f"ASSET_RENDER {name} ground_anchor={anchors[name]}",flush=True)
        bpy.ops.render.render(write_still=True)
    (SOURCE/"untrimmed_anchors.json").write_text(json.dumps(anchors,indent=2)+"\n",encoding="utf-8")
    print("RENDER_COMPLETE original art_v6 six sprites",flush=True)


if __name__=="__main__":
    main()
