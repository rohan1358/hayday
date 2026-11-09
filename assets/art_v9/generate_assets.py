"""Original Kebun Ceria delivery depot and courier truck, Blender 5.2.

Run: blender --background --factory-startup --python assets/art_v9/generate_assets.py
Only writes in art_v9. Uses art_v2 geometry/lighting helpers read-only.
"""

import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
SOURCE = HERE / "_render_source"
BLEND_SOURCE = HERE / "source_blender"
sys.path.insert(0, str(HERE.parent / "art_v2"))
import generate_assets as b

R = random.Random(921106)


def init_palette():
    b.setup_materials()
    colors = {
        "oak": "#bf895f", "oak_light": "#e6b781", "oak_pale": "#f3d4a0",
        "oak_deep": "#825942", "creamwall": "#f4dfb9", "creamhighlight": "#fff1cb",
        "jade": "#4c8e7e", "jade_light": "#80b4a0", "jade_dark": "#356c62",
        "roof_tan": "#c97c58", "roof_light": "#e9a16d", "roof_deep": "#95573e",
        "teal_roof": "#739589", "teal_roof_light": "#a3c3a5", "teal_roof_dark": "#456e66",
        "sage": "#93bc79", "grass_edge": "#639c61", "soil_edge": "#855d47",
        "paving": "#d8b78b", "paving_light": "#efd4a2", "paving_shadow": "#b89071",
        "cargo_gold": "#ebbe6d", "crate_strap": "#9c693f", "package": "#f2ce8f",
        "apple": "#df7169", "apple_sun": "#ee9a6a", "leaf_green": "#4d9b67",
        "glass_sky": "#96d1ce", "glass_pale": "#c9eee1", "glass_dark": "#518f91",
        "rubber": "#344443", "rubber_light": "#536360", "hub": "#d7dfca",
        "metal": "#96aca0", "brass": "#f4d68a", "lamp": "#fff1b8",
        "pink_flower": "#eb9da6", "blue_flower": "#9bbae1", "white_flower": "#ffedd5",
        "awning_cream": "#ffddad", "awning_teal": "#5c9e8d", "sticker": "#f4d57f",
    }
    b.M.update({k: b.material(k, v) for k, v in colors.items()})


def box(name, at, dims, color, bev=.04):
    return b.box(name, at, dims, color, bev)


def ball(name, at, dims, color):
    return b.orb(name, at, dims, color, 18, 12)


def pole(name, p1, p2, radius, color):
    return b.pole(name, p1, p2, radius, color, 10)


def move_new(before, shift):
    d = Vector(shift)
    for ob in set(bpy.context.scene.objects) - before:
        ob.location += d


def text_on_front(content, pos, size, material):
    data = bpy.data.curves.new('lettering ' + content, 'FONT')
    data.body = content
    data.align_x = 'CENTER'
    data.align_y = 'CENTER'
    data.size = size
    data.extrude = .008
    data.bevel_depth = .002
    ob = bpy.data.objects.new('raised sign lettering ' + content, data)
    bpy.context.collection.objects.link(ob)
    ob.rotation_euler = (math.pi / 2, 0, 0)
    ob.location = pos
    b.assign(ob, material)


def parcel(x, y, z, scale=1):
    before = set(bpy.context.scene.objects)
    box('kraft-paper parcel with rounded corners', (0,0,.18), (.54,.42,.36), 'package', .05)
    box('postal wrap seam top', (0,0,.368), (.074,.42,.016), 'oak_deep', .008)
    box('postal twine band', (0,0,.18), (.064,.43,.38), 'crate_strap', .01)
    box('postal label', (.14,-.217,.26), (.17,.017,.10), 'creamhighlight', .01)
    for ob in set(bpy.context.scene.objects)-before:
        ob.location = Vector((x,y,z)) + ob.location * scale
        ob.scale *= scale


def wooden_crate(x, y, z, s=1):
    before = set(bpy.context.scene.objects)
    box('cross-braced shipping crate', (0,0,.25), (.64,.55,.49), 'oak', .055)
    box('crate front inset panel', (0,-.289,.25), (.53,.022,.38), 'oak_light', .02)
    for side in (-1,1):
        pole('diagonal crate brace', (side*.26,-.309,.08), (-side*.26,-.309,.43), .023, 'oak_deep')
    for x0 in (-.28,.28):
        box('crate edge rib', (x0,-.308,.26), (.055,.03,.48), 'oak_pale', .01)
    for ob in set(bpy.context.scene.objects)-before:
        ob.location = Vector((x,y,z)) + ob.location*s
        ob.scale *= s


def flowering(x,y,tone):
    b.flower(x,y,.56,tone,.56)
    b.flower(x+.16,y+.08,.54,'white_flower',.40)


def depot_base():
    box('hand-layered garden stone edging', (0,0,.14), (5.35,3.55,.24), 'grass_edge', .21)
    box('warm delivery courtyard flagstone', (0,0,.26), (5.24,3.45,.12), 'paving', .18)
    for x,y in [(-2.1,-1.13),(-1.25,-1.4),(-.28,-1.26),(.76,-1.29),
                (1.79,-1.3),(-2.2,.38),(-.4,.31),(1.3,.49)]:
        box('delicate staggered paving stone', (x,y,.333), (.48,.37,.026),
            'paving_light' if x>0 else 'paving_shadow', .082)
    for x,y in [(-2.43,-1.18),(2.39,-1.09),(-2.38,.92),(2.36,.94)]:
        flowering(x,y,'pink_flower' if x<0 else 'blue_flower')
    for x,y in [(-2.46,.18),(2.45,-.26)]:
        b.grass_tuft(x,y,.55)


def depot_building():
    before = set(bpy.context.scene.objects)
    w,d,wall,peak = 2.38,1.72,1.78,2.63
    box('limestone loading lodge base',(0,0,.46),(w+.17,d+.18,.26),'stone_light',.06)
    box('buttery plaster timber walls',(0,0,1.14),(w,d,1.32),'creamwall',.063)
    b.gable_walls(w,d,wall,peak,'creamwall')
    b.roof(w,d,wall+.02,peak+.015,'teal_roof','teal_roof_dark',tile_color='teal_roof_light')
    for xx in (-w/2+.09,w/2-.09):
        box('oak framed corner pillar',(xx,-d/2-.07,1.14),(.12,.13,1.36),'oak_light',.025)
    for zz in (.69,1.05,1.40):
        box('handpainted horizontal shiplap',(0,-d/2-.06,zz),(w-.24,.036,.029),'creamhighlight',.01)
    box('inset deep delivery doorway',(0,-d/2-.09,1.08),(.97,.19,1.28),'oak_deep',.07)
    box('panelled jade delivery door',(0,-d/2-.20,1.08),(.79,.07,1.09),'jade',.035)
    for xx in (-.29,-.09,.12,.3):
        pole('hand-planked door seam',(xx,-d/2-.245,.64),(xx,-d/2-.245,1.54),.013,'jade_dark')
    ball('round iron door handle',(.25,-d/2-.27,1.05),(.038,.023,.037),'brass')
    ball('circular loft port timber rim',(0,-d/2-.049,2.13),(.24,.065,.24),'oak_light')
    ball('loft shaded turquoise glazing',(0,-d/2-.107,2.13),(.16,.027,.16),'glass_dark')
    pole('tiny loft mullion',(-.12,-d/2-.13,2.13),(.12,-d/2-.13,2.13),.018,'oak_pale')
    # Wide receiving awning hangs over the loading desk and leaves the road clear.
    for sx in (-1,1):
        pole('striped canopy wooden support',(sx*1.02,-1.69,.37),(sx*1.02,-1.69,1.72),.075,'oak_light')
    b.mesh('cantilevered fabric awning',[(-1.27,-1.77,1.69),(1.27,-1.77,1.69),
                                        (1.27,-.72,1.96),(-1.27,-.72,1.96)],
           [(0,1,2,3)],'awning_cream')
    for idx in range(7):
        if idx % 2:
            continue
        a = -1.27+idx*(2.54/7)
        c = a+2.54/7
        b.mesh('striped jade canvas canopy stripe',[(a,-1.777,1.70),(c,-1.777,1.70),
               (c,-.728,1.97),(a,-.728,1.97)],[(0,1,2,3)],'awning_teal')
    pole('canopy front rolled hem',(-1.27,-1.785,1.70),(1.27,-1.785,1.70),.058,'oak_light')
    # Curved wood billboard above the counter, text faces the farm camera.
    for sx in (-1,1):
        pole('billboard little stanchion',(sx*.88,-1.75,1.65),(sx*.88,-1.75,2.16),.047,'oak_deep')
    box('thick rustic orders billboard',(0,-1.81,2.17),(2.07,.13,.54),'oak_deep',.09)
    box('honey gold lettering inset',(0,-1.896,2.17),(1.93,.042,.42),'awning_cream',.06)
    text_on_front('PESANAN',(0,-1.935,2.19),.283,'jade_dark')
    for sx in (-1,1):
        ball('gilded sign bolt',(sx*.84,-1.928,2.18),(.034,.017,.034),'brass')
    move_new(before,(-1.00,.77,0))


def depot_cargo_details():
    # Crates and delivery orders outside the store, away from the truck path.
    wooden_crate(-2.13,-.69,.28,.87)
    wooden_crate(-1.76,-1.06,.28,.68)
    parcel(-2.11,.10,.34,.66)
    parcel(-1.43,-1.03,.68,.48)
    box('short low loading counter',(1.52,.67,.74),(1.62,.68,.14),'oak_light',.05)
    for x in (.84,2.20):
        for y in (.45,.88):
            pole('packing table carved foot',(x,y,.34),(x,y,.70),.068,'oak_deep')
    wooden_crate(1.18,.74,.80,.69)
    parcel(1.87,.68,.82,.60)
    # Compact letter box is a useful distant landmark, not a copy of any game prop.
    pole('courier post base',(2.08,-.75,.33),(2.08,-.75,1.27),.085,'oak_deep')
    box('sage wall mailbox',(2.08,-.75,1.35),(.65,.35,.47),'jade',.084)
    box('mail slot shadow',(2.08,-.945,1.44),(.38,.02,.057),'jade_dark',.012)
    box('mail slot golden plate',(2.08,-.975,1.45),(.27,.016,.02),'brass',.005)
    ball('round mailbox seal',(2.08,-.946,1.24),(.064,.027,.064),'brass')
    for x in (1.64,1.94,2.19):
        pole('wooden direction railing',(x,1.43,.34),(x,1.43,.94),.065,'oak')
    pole('short loading rail',(1.64,1.43,.77),(2.19,1.43,.77),.047,'oak_light')
    for x in (.43,.76):
        ball('harvest apple in packing tray',(x,.69,1.20),(.135,.13,.14),'apple')
        pole('apple stem',(x,.69,1.29),(x,.69,1.38),.012,'oak_deep')
    # Exposed patio boards and occasional leaves add scale without visual noise.
    for x,y in [(-.1,1.42),(.55,1.37),(.1,-1.41)]:
        ball('organic scattered leaf',(x,y,.355),(.12,.045,.016),'leaf_green')


def delivery_depot():
    depot_base()
    depot_building()
    depot_cargo_details()


def wheel(x, y):
    # Real round wheels perpendicular to the truck's long axis.
    for radius, thick, material, yy in [(.39,.19,'rubber',y),(.270,.205,'rubber_light',y-.013),
                                        (.190,.215,'hub',y-.03),(.099,.231,'metal',y-.035)]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=radius,depth=thick,location=(x,yy,.48))
        obj=bpy.context.object
        obj.name='truck wheel ' + material
        obj.rotation_euler[0]=math.pi/2
        b.assign(obj,material)
    for angle in range(6):
        t=math.tau*angle/6
        ball('shining wheel nut',(x+math.cos(t)*.14,y-.16,.48+math.sin(t)*.14),(.025,.015,.025),'oak_deep')


def courier_truck():
    # Distinct original mint-green wooden farm van with a rounded cab and open produce bed.
    box('underbody sturdy graphite chassis',(0,0,.73),(3.80,1.40,.28),'oak_deep',.12)
    box('cargo deck top honey timber',(-.73,0,.91),(2.56,1.46,.20),'oak',.10)
    box('cargo plank rear face',(-1.91,0,1.30),(.14,1.45,.84),'oak_deep',.05)
    for y in (-.75,.75):
        box('long wood cargo sideboard',(-.79,y,1.28),(2.32,.11,.72),'oak_light',.038)
        for i in range(6):
            xx=-1.78+i*.38
            box('livestock-style cargo wood seam',(xx,y*1.085,1.27),(.025,.037,.61),'oak',.008)
        for zz in (1.02,1.58):
            pole('bolted cargo rails',(-1.91,y*1.09,zz),(.39,y*1.09,zz),.043,'oak_deep')
    for xx in (-1.75,-.79,.14):
        wooden_crate(xx,.08,1.59,.59)
        for dx in (-.10,.07):
            ball('produce fruit visible above crate',(xx+dx,-.08,1.94),(.10,.10,.11),
                 'apple_sun' if dx<0 else 'apple')
            ball('fresh vegetable leaf',(xx+dx,.01,2.015),(.073,.042,.018),'leaf_green')
    # Lightweight rolled tarp across one end of the produce load.
    box('rolled cream canvas end cover',(-1.81,.0,2.07),(.26,1.53,.19),'awning_cream',.085)
    for yy in (-.48,.48):
        box('pale mint cab step',(1.13,yy,.89),(1.35,.29,.12),'jade_dark',.043)
    # The front nose points toward +X; front and near (-Y) cabin are visible.
    box('rounded jade green cabin',(1.08,0,1.47),(1.22,1.34,1.12),'jade',.16)
    box('cab rounded mint roof',(1.06,0,2.080),(1.43,1.48,.17),'jade_light',.095)
    box('front jade hood',(1.78,0,1.19),(.64,1.32,.57),'jade_light',.11)
    box('front cream bumper',(2.10,0,.84),(.21,1.49,.16),'metal',.043)
    box('front grille dark slot',(2.132,0,1.14),(.035,.72,.21),'jade_dark',.03)
    for yy in (-.42,.42):
        ball('warm truck round headlamp',(2.16,yy,1.38),(.04,.13,.13),'lamp')
        ball('turn indicator',(2.162,yy,1.10),(.035,.069,.051),'cargo_gold')
    # Windscreen and near side window are inset painted shapes.
    box('cabin near window edge',(1.09,-.694,1.70),(1.035,.064,.56),'jade_dark',.073)
    box('reflective broad side window',(1.08,-.738,1.725),(.89,.035,.44),'glass_sky',.065)
    box('near-side narrow window pillar',(1.17,-.765,1.74),(.057,.023,.45),'jade_light',.016)
    box('white glass glint stripe',(.85,-.768,1.85),(.25,.017,.038),'glass_pale',.017)
    box('front glass band',(1.72,0,1.70),(.048,1.04,.51),'glass_dark',.06)
    box('front glass brilliant reflection',(1.755,-.23,1.76),(.018,.24,.35),'glass_pale',.024)
    box('cabin mint door trim',(1.10,-.704,1.16),(.85,.038,.35),'jade_light',.047)
    pole('truck rounded door pull',(1.14,-.754,1.17),(1.32,-.754,1.17),.025,'brass')
    # Leaf seal on the door becomes a distinct game-scale identifier.
    ball('farm delivery leaf seal',(.86,-.756,1.17),(.11,.018,.14),'sticker')
    ball('tiny jade leaf centre',(.85,-.778,1.18),(.06,.012,.095),'jade_dark')
    pole('rear cab side mirror arm',(1.58,-.70,1.67),(1.78,-.92,1.70),.033,'oak_deep')
    box('rearview mirror',(1.80,-.93,1.71),(.12,.10,.17),'oak_deep',.026)
    for x in (-1.25,1.28):
        for y in (-.80,.80):
            wheel(x,y)
    for xx in (-1.93,-1.95):
        box('rear red brake lamp',(xx,-.58,1.03),(.05,.17,.16),'apple',.035)


def render(asset_id, maker, ortho, z_target):
    camera=b.scene_base()
    maker()
    target=Vector((0,0,z_target))
    camera.location=target+Vector((7,-9,8))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'
    camera.data.ortho_scale=ortho
    bpy.context.view_layer.update()
    view=world_to_camera_view(bpy.context.scene,camera,Vector((0,0,.09)))
    anchor=[round(view.x*1024),round((1-view.y)*1024)]
    bpy.context.scene.render.filepath=str(SOURCE/(asset_id+'.png'))
    print(f'RENDER_START {asset_id} objects={len(bpy.context.scene.objects)} anchor={anchor}',flush=True)
    bpy.ops.render.render(write_still=True)
    BLEND_SOURCE.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_SOURCE/(asset_id+'.blend')),compress=True)
    print(f'RENDER_DONE {asset_id}',flush=True)
    return anchor


def main():
    SOURCE.mkdir(parents=True,exist_ok=True)
    init_palette()
    anchors={
        'delivery_depot':render('delivery_depot',delivery_depot,8.15,1.35),
        'delivery_truck':render('delivery_truck',courier_truck,6.40,1.18),
    }
    (SOURCE/'untrimmed_anchors.json').write_text(json.dumps(anchors,indent=2)+'\n',encoding='utf-8')
    print(f'RENDER_COMPLETE {anchors}',flush=True)


if __name__=='__main__':
    main()
