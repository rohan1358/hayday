"""Original Kebun Ceria courier-yard decoration, rendered in Blender 5.2.

Run from the game project root:
  blender --background --factory-startup --python assets/art_v10/generate_assets.py

Only art_v10 outputs are written. Shared art_v2 geometry helpers are read-only.
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
RENDERS = ROOT / "_render_source"
BLENDS = ROOT / "source_blender"
sys.path.insert(0, str(ROOT.parent / "art_v2"))
import generate_assets as b


def palette():
    b.setup_materials()
    colors = {
        "oak": "#bf895f", "oak_light": "#e6b781", "oak_pale": "#f3d4a0",
        "oak_deep": "#825942", "cream": "#f4dfb9", "white": "#fff1cb",
        "jade": "#4c8e7e", "jade_light": "#80b4a0", "jade_dark": "#356c62",
        "sage": "#93bc79", "leaf_green": "#4d9b67", "leaf_sun": "#b9ce7c",
        "paving": "#d8b78b", "paving_light": "#efd4a2",
        "cargo_gold": "#ebbe6d", "straw": "#ecca77", "package": "#f2ce8f",
        "pink": "#eb9da6", "blue": "#9bbae1", "apple": "#df7169",
        "apple_sun": "#ee9a6a", "brass": "#f4d68a", "lamp": "#fff1b8",
        "metal": "#96aca0", "rubber": "#344443", "stone": "#b6b39b",
    }
    b.M.update({name: b.material(name, color) for name, color in colors.items()})


def box(name, at, dims, color, bevel=0.04):
    return b.box(name, at, dims, color, bevel)


def ball(name, at, dims, color):
    return b.orb(name, at, dims, color, 14, 10)


def pole(name, a, c, radius, color):
    return b.pole(name, a, c, radius, color, 9)


def front_lettering(content, at, size, color):
    data = bpy.data.curves.new("carved letters " + content, "FONT")
    data.body = content
    data.size = size
    data.align_x = "CENTER"
    data.align_y = "CENTER"
    data.extrude = 0.006
    obj = bpy.data.objects.new("carved letters " + content, data)
    bpy.context.collection.objects.link(obj)
    obj.rotation_euler = (math.pi / 2, 0, 0)
    obj.location = at
    b.assign(obj, color)


def little_parcel(x, y, z, scale=1.0):
    box("paper-wrapped farmer's order", (x,y,z+.18*scale),
        (.48*scale,.39*scale,.36*scale), "package", .05*scale)
    box("crossed twine top", (x,y,z+.365*scale),
        (.06*scale,.40*scale,.02*scale), "oak_deep", .008)
    box("twine around other side", (x,y,z+.18*scale),
        (.055*scale,.40*scale,.37*scale), "oak_deep", .012)
    box("handwritten order label", (x+.08*scale,y-.209*scale,z+.23*scale),
        (.19*scale,.012,.125*scale), "white", .008)


def basket(x,y,z,s=1.0):
    # A distinct slatted wicker harvest tray; feet touch the cart surface.
    box("wicker basket floor", (x,y,z+.09*s),(.68*s,.49*s,.16*s), "oak_deep", .055)
    for xx in (-.31,.31):
        box("basket side",(x+xx*s,y,z+.27*s),(.065*s,.52*s,.32*s),"oak_light", .025)
    for yy in (-.235,.235):
        box("basket rim",(x,y+yy*s,z+.36*s),(.68*s,.065*s,.1*s),"oak_pale", .02)
    for i in range(4):
        fruit_x = x + (i%2-.5)*.27*s
        fruit_y = y + (i//2-.5)*.17*s
        ball("sorted orchard produce",(fruit_x,fruit_y,z+.39*s),
             (.12*s,.13*s,.13*s),"apple" if i%3 else "apple_sun")
        ball("tiny green produce leaf",(fruit_x+.03*s,fruit_y,z+.51*s),
             (.07*s,.038*s,.025*s),"leaf_green")


def sorting_trolley():
    """Compact two-wheeled sorting trolley, drawn left of depot's loading apron."""
    # Slim tapered flagstone footing gives scale without an oversized ground tile.
    box("trolley sandstone landing",(0,0,.055),(2.15,1.27,.09),"paving",.13)
    for x,y in [(-.91,-.44),(.89,.43)]:
        box("individual paving inset",(x,y,.108),(.21,.20,.018),"paving_light",.055)
    # The visible wheel hubs and handles imply the trolley can be moved by hand.
    box("dark iron trolley axle",(0,.06,.38),(1.65,.12,.08),"rubber",.02)
    for xx in (-.8,.8):
        bpy.ops.mesh.primitive_cylinder_add(vertices=18,radius=.30,depth=.14,
                                             location=(xx,-.22,.35))
        wheel=bpy.context.object
        wheel.name="wood-and-rubber handcart wheel"
        wheel.rotation_euler[0]=math.pi/2
        b.assign(wheel,"rubber")
        ball("gold-bronze wheel hub",(xx,-.304,.35),(.12,.025,.12),"brass")
    for y in (-.43,.43):
        box("turned wooden cart leg",(-.87,y,.39),(.14,.13,.57),"oak_deep",.027)
    box("broad timber sorting bed",(0,0,.74),(1.91,1.00,.16),"oak",.079)
    for x in (-.6,-.2,.2,.6):
        box("cart decking plank seam",(x,-.50,.735),(.022,.04,.13),"oak_deep",.006)
    for x in (-.83,.83):
        pole("curved cart handle",(x,.48,.75),(x,.92,1.12),.052,"oak_light")
    pole("rear pull handle",(-.83,.92,1.12),(.83,.92,1.12),.058,"oak_deep")
    # One produce basket, one parcel pile: readable silhouettes at mobile size.
    basket(-.45,-.11,.83,.91)
    little_parcel(.42,-.12,.83,.90)
    little_parcel(.60,.20,.83,.62)
    box("folded courier canvas on rear rail",(.28,.49,.84),(.50,.20,.16),"jade_light",.057)
    # Small embossed icon on the order envelope, intentionally no borrowed logo.
    ball("wax seal on dispatch box",(.51,-.31,1.03),(.075,.018,.075),"apple",)
    for x,y in [(-.91,-.66),(.95,-.43)]:
        ball("low verge flowering leaves",(x,y,.13),(.14,.10,.10),"leaf_green")
        ball("verge blossom",(x-.04,y-.035,.22),(.065,.06,.054),"pink")


def directional_arrow():
    # Wooden arrow points toward the village road (+world X).
    face=[(-.52,-.168,1.77),(.43,-.168,1.77),(.72,-.168,1.99),
          (.43,-.168,2.21),(-.52,-.168,2.21)]
    back=[(x,y+.12,z) for x,y,z in face]
    b.mesh("hand-cut arrow front and beveled sides",face+back,
           [(0,1,2,3,4),(9,8,7,6,5),(0,5,6,1),(1,6,7,2),
            (2,7,8,3),(3,8,9,4),(4,9,5,0)],"oak_deep")
    box("cream face inset",(-.06,-.191,1.99),(.92,.024,.32),"cargo_gold",.034)
    front_lettering("DESA",(-.075,-.219,1.956),.212,"jade_dark")


def village_waypost():
    """Garden lantern, directional arrow, bird perch and flowers by road."""
    box("rounded sandstone footing",(0,0,.115),(1.48,1.16,.21),"paving",.17)
    box("chamfered post foot",(-.30,.13,.27),(.50,.48,.35),"oak_deep",.087)
    box("strong weathered cedar signpost",(-.30,.13,1.36),(.23,.21,2.05),"oak",.04)
    box("protective post cap",(-.30,.13,2.49),(.35,.32,.16),"oak_pale",.06)
    for zz in (.70,1.48,2.19):
        box("carved grain detail",(-.30,-.003,zz),(.11,.008,.10),"oak_deep",.004)
    directional_arrow()
    # Curved wrought-iron lamp arm with faceted, warm glass lantern.
    pole("arched lantern arm",(-.30,.13,2.31),(.49,.13,2.37),.055,"jade_dark")
    pole("lantern drooping hook",(.49,.13,2.37),(.56,.13,2.17),.039,"jade_dark")
    box("lantern top roof",(.56,.13,2.13),(.43,.36,.14),"jade_dark",.07)
    box("amber glass lantern",(.56,.13,1.87),(.34,.29,.41),"lamp",.085)
    for xx in (.39,.73):
        pole("lantern corner iron",(xx,-.03,1.68),(xx,-.03,2.05),.024,"jade_dark")
    box("cast iron lamp base",(.56,.13,1.66),(.41,.33,.10),"jade_dark",.033)
    ball("sunlit lantern knob",(.56,.13,2.25),(.061,.061,.072),"brass")
    # Two ceramic planters tie the waypost into the farmhouse garden language.
    for x,y,size in [(-.55,-.41,.85),(.51,-.33,.68)]:
        box("terracotta planter",(x,y,.24*size),(.50*size,.42*size,.43*size),"oak_deep",.09)
        box("plant pot lip",(x,y,.46*size),(.57*size,.48*size,.10*size),"oak_light",.045)
        for i in range(3):
            ox=(i-1)*.14*size
            ball("sage leafy mass",(x+ox,y,.54*size),(.18*size,.17*size,.22*size),"leaf_green")
            ball("tiny five-petal color hint",(x+ox,y-.11*size,.70*size),
                 (.082*size,.058*size,.076*size),"blue" if i==0 else "pink")
    # One tiny wooden bird perch distinguishes the station silhouette.
    pole("robin perch bracket",(-.30,.13,2.51),(-.70,.13,2.59),.022,"oak_deep")
    ball("round friendly visiting songbird",(-.69,.13,2.66),(.115,.095,.14),"apple_sun")
    ball("cream bird cheek",(-.77,.035,2.63),(.054,.042,.048),"white")
    ball("tiny dark bird eye",(-.745,.018,2.705),(.017,.014,.018),"rubber")
    b.mesh("little bird beak",[(-.80,-.02,2.655),(-.94,-.04,2.665),(-.82,-.03,2.60)],
           [(0,1,2)],"cargo_gold")


def render(asset_id, maker, ortho, z_target):
    camera=b.scene_base()
    maker()
    target=Vector((0,0,z_target))
    camera.location=target+Vector((7,-9,8))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'
    camera.data.ortho_scale=ortho
    bpy.context.view_layer.update()
    at=world_to_camera_view(bpy.context.scene,camera,Vector((0,0,.05)))
    anchor=[round(at.x*1024),round((1-at.y)*1024)]
    bpy.context.scene.render.filepath=str(RENDERS/(asset_id+'.png'))
    print(f'RENDER_START {asset_id} objects={len(bpy.context.scene.objects)} anchor={anchor}',flush=True)
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLENDS/(asset_id+'.blend')),compress=True)
    print(f'RENDER_DONE {asset_id}',flush=True)
    return anchor


def main():
    RENDERS.mkdir(parents=True,exist_ok=True)
    BLENDS.mkdir(parents=True,exist_ok=True)
    (RENDERS/'.gdignore').touch()
    (BLENDS/'.gdignore').touch()
    palette()
    anchors={
        'sorting_trolley':render('sorting_trolley',sorting_trolley,3.75,.96),
        'village_waypost':render('village_waypost',village_waypost,4.15,1.27),
    }
    (RENDERS/'untrimmed_anchors.json').write_text(json.dumps(anchors,indent=2)+'\n',encoding='utf-8')
    print('RENDER_COMPLETE '+repr(anchors),flush=True)


if __name__=='__main__':
    main()
