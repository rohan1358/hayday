"""Create two original isometric livestock sprites for Kebun Ceria.

Blender 5.2: blender --background --factory-startup --python assets/art_v8/generate_assets.py
Then: py assets/art_v8/finalize_assets.py
Only writes under assets/art_v8. art_v2 is imported as a read-only geometry library.
"""

import json
import math
import random
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "art_v2"))
import generate_assets as b  # noqa: E402  (existing original in-project primitives)

SOURCE = HERE / "_render_source"
BLEND_SOURCE = HERE / "source_blender"
RNG = random.Random(80261107)


def palette():
    b.setup_materials()
    colors = {
        "pasture": "#abd17e", "pasture_edge": "#7eae69", "sod_dark": "#548b59",
        "wood_honey": "#e8b77e", "wood_cream": "#f6d9a0", "fence_oak": "#bd8658",
        "fence_line": "#926249", "roof_coral": "#d77e68", "roof_pink": "#edaa8b",
        "roof_shadow": "#a85a55", "roof_moss": "#7d9d7c", "roof_sage": "#a2bd8b",
        "roof_olive": "#617c62", "wall_warm": "#f7ddb4", "wall_sage": "#e6e3bd",
        "pig_blush": "#efa3a4", "pig_light": "#ffd0bd", "pig_shadow": "#d47f86",
        "pig_snout": "#e88f91", "pig_spot": "#d98c8b", "pig_inner": "#c96e79",
        "cream_fur": "#ffebc8", "gold_fur": "#e6bb85", "kid_fur": "#d9a879",
        "fur_shadow": "#bd936f", "goat_muzzle": "#f7d7ae", "goat_ear": "#d8a8a2",
        "horn": "#dbc7a0", "horn_dark": "#ad9977", "hoof": "#7f6959",
        "eye": "#483b38", "eye_shine": "#fff9e7", "blush": "#f4b6a9",
        "pond": "#a5cbd0", "pond_deep": "#75aeb7", "mud": "#a57961",
        "mud_light": "#c19272", "trough_blue": "#7eadae", "trough_rim": "#d8ebe0",
        "flower_lilac": "#bf99c7", "flower_white": "#fff1e4", "flower_yellow": "#ffde80",
    }
    b.M.update({key: b.material(key, color) for key, color in colors.items()})


def box(name, center, dims, color, bevel=0.04):
    return b.box(name, center, dims, color, bevel)


def orb(name, center, dims, color):
    return b.orb(name, center, dims, color, 18, 12)


def pole(name, a, c, radius, color):
    return b.pole(name, a, c, radius, color, 10)


def translated(before, x, y, z=0, scale=1.0):
    """Transform newly created details around a local model origin."""
    translation = Vector((x, y, z))
    for obj in set(bpy.context.scene.objects) - before:
        obj.location = obj.location * scale + translation
        obj.scale *= scale


def pasture():
    box("rounded turf soil slab", (0, 0, .135), (5.25, 3.96, .26), "sod_dark", .22)
    box("lush clipped paddock grass", (0, 0, .275), (5.16, 3.88, .105), "pasture", .20)
    for x, y, r in [(-2, -.8, .20), (-1.5, 1.38, .16), (-.7, -1.22, .20),
                    (.18, 1.52, .20), (1.70, 1.29, .18), (2.1, -.83, .16),
                    (.88, -.74, .13), (-1.78, -.08, .17)]:
        orb("subtle clover patch", (x, y, .337), (r, r*.64, .014), "grass_light")
    for x, y in [(-2.24, -.63), (-1.92, 1.42), (2.23, 1.0), (1.90, -1.37),
                 (-.58, -1.5), (1.33, 1.56)]:
        b.grass_tuft(x, y, .57)
    # Soil and stones along the exposed lip add hand-crafted material variation.
    for x in (-2.12, -1.55, -.92, -.20, .60, 1.28, 2.06):
        orb("small stone in turf rim", (x, -1.96, .24), (.095, .04, .036), "stone_light")


def flowers(variant):
    clusters = [(-2.08, -1.02), (2.18, -.59), (-2.08, 1.15), (2.11, 1.48)]
    for i, (x, y) in enumerate(clusters):
        tone = ("pink", "flower_white", "flower_yellow")[(i + variant) % 3]
        b.flower(x, y, .61, tone, .64)
        b.flower(x + .13, y + .17, .59, "flower_lilac", .47)


def paddock_fence():
    """Open front fence, tall rear and side fences, with a centered low gate."""
    xx, yy = 2.45, 1.78
    for x in (-xx, -1.24, 0, 1.24, xx):
        pole("rear octagonal timber post", (x, yy, .31), (x, yy, 1.33), .088, "wood_honey")
        orb("rounded ivory finial", (x, yy, 1.33), (.112, .112, .072), "wood_cream")
    for z, tone in [(.65, "fence_oak"), (1.04, "wood_honey")]:
        pole("rear horizontal oak railing", (-xx, yy, z), (xx, yy, z), .07, tone)
    for sx in (-1, 1):
        x = sx * xx
        for y in (-yy, -.6, .59, yy):
            pole("side fence pale post", (x, y, .32), (x, y, 1.10), .086, "wood_honey")
            orb("post cover", (x, y, 1.12), (.097, .097, .04), "wood_cream")
        for z in (.59, .95):
            pole("side contiguous fence rail", (x, -yy, z), (x, yy, z), .068, "fence_oak")
    # A low front rail is necessary to keep the animal expressions visible.
    for x in (-xx, -1.40, -.48, .48, 1.40, xx):
        pole("front low fence post", (x, -yy, .31), (x, -yy, .82), .09, "wood_honey")
        orb("front ivory post cap", (x, -yy, .86), (.115, .115, .067), "wood_cream")
    for z in (.44, .67):
        for a, c in [(-xx, -.48), (.48, xx)]:
            pole("front open fence crossbar", (a, -yy, z), (c, -yy, z), .06, "fence_oak")
    # Detached outward-swinging gate in a central half-width gap.
    gate = box("oak gate broad plank", (.01, -1.81, .535), (.84, .095, .34), "wood_honey", .042)
    box("gate upper trim", (0, -1.875, .68), (.78, .035, .038), "wood_cream", .01)
    for x in (-.24, 0, .24):
        pole("gate vertical oak engraving", (x, -1.872, .40), (x, -1.872, .67), .013, "fence_line")
    for x in (-.34, .34):
        orb("gate golden stud", (x, -1.895, .53), (.025, .015, .025), "gold")


def shelter(kind):
    """Small back-left gable lodge that shares the farm's established roof language."""
    before = set(bpy.context.scene.objects)
    w, d, wall, peak = 1.84, 1.28, 1.65, 2.33
    roof_tone = "roof_coral" if kind == "pig" else "roof_moss"
    roof_shingle = "roof_pink" if kind == "pig" else "roof_sage"
    roof_trim = "roof_shadow" if kind == "pig" else "roof_olive"
    wall_tone = "wall_warm" if kind == "pig" else "wall_sage"
    box("warm stone lodge foundation", (0, 0, .43), (w+.11, d+.13, .25), "stone_light", .085)
    box("wooden siding plaster walls", (0, 0, 1.12), (w, d, 1.18), wall_tone, .043)
    b.gable_walls(w, d, wall, peak, wall_tone)
    b.roof(w, d, wall+.02, peak+.02, roof_tone, roof_trim, tile_color=roof_shingle)
    for x in (-w/2+.07, w/2-.07):
        box("lodge exposed corner post", (x, -d/2-.032, 1.13), (.12, .10, 1.16), "wood_honey", .018)
    for z in (.65, .98, 1.31):
        box("shiplap thin horizontal wall batten", (0, -d/2-.025, z), (w-.13, .04, .025), "cream_shadow", .01)
    box("shelter door dark inset", (0, -d/2-.065, .99), (.89, .14, 1.19), "wood_dark", .065)
    box("stable door painted timber", (0, -d/2-.15, 1.01), (.74, .065, 1.05), "fence_oak", .04)
    for x in (-.26, -.08, .10, .28):
        pole("vertical stable door groove", (x, -d/2-.19, .57), (x, -d/2-.19, 1.43), .012, "fence_line")
    for z in (.59, 1.37):
        box("oak stable door crosspiece", (0, -d/2-.20, z), (.76, .035, .058), "wood_honey", .018)
    orb("small brass door knob", (.27, -d/2-.22, 1.04), (.045, .023, .045), "gold")
    orb("gable arched round timber trim", (0, -d/2-.048, 1.89), (.205, .08, .207), "wood_honey")
    orb("gable round dark ventilation port", (0, -d/2-.12, 1.89), (.146, .033, .149), "glass_dark")
    pole("ventilation crossbar", (-.1, -d/2-.158, 1.89), (.1, -d/2-.158, 1.89), .012, "wood_cream")
    box("entrance small step", (0, -d/2-.29, .37), (.90, .36, .13), "stone", .046)
    translated(before, -1.16, .81)


def bale(x, y, scale=1.0):
    before = set(bpy.context.scene.objects)
    box("rough woven golden hay bale", (0, 0, .51), (.53, .41, .38), "straw", .095)
    for ix in range(6):
        yline = -.175 + ix * .071
        pole("hay bale straw whisker", (-.25, yline, .71), (.25, yline+.02, .72), .016, "straw_light")
    for xpos in (-.14, .14):
        box("hay baling cord", (xpos, 0, .52), (.034, .43, .42), "wood_dark", .009)
    translated(before, x, y, scale=scale)


def trough(x, y, blue=True):
    hue = "trough_blue" if blue else "fence_oak"
    rim = "trough_rim" if blue else "wood_honey"
    box("livestock water basin body", (x, y, .41), (.67, .42, .22), hue, .075)
    box("reflective water surface", (x, y, .536), (.52, .28, .026), "pond_deep", .058)
    for offset in (-.21, .21):
        orb("water little specular ripple", (x+offset/2, y-.045, .552), (.075, .022, .007), "pond")
    for xx in (-.33, .33):
        box("water basin lip edge", (x+xx, y, .546), (.046, .44, .047), rim, .012)
    for yy in (-.21, .21):
        box("water basin lip end", (x, y+yy, .546), (.69, .046, .047), rim, .012)


def ear(front_y, side, body_tone, inner_tone, height=1.28):
    """Sculpted triangular, forward-facing porcine ear."""
    sx = side
    b.mesh("pointed ear outer", [
        (sx*.24, front_y, height-.12), (sx*.52, front_y-.035, height+.24),
        (sx*.47, front_y+.12, height-.13), (sx*.34, front_y-.09, height+.02),
    ], [(0,1,3), (1,2,3), (2,0,3)], body_tone)
    b.mesh("inner velvet ear", [
        (sx*.33, front_y-.052, height-.047),
        (sx*.48, front_y-.069, height+.16),
        (sx*.43, front_y-.05, height-.066),
    ], [(0,1,2)], inner_tone)


def pig(x, y, scale=1.0, tone="pig_blush", small=False):
    """Own stylized pig character, rounded nose and friendly facing-front expression."""
    before = set(bpy.context.scene.objects)
    orb("plump pear-like pig torso", (0, .11, .77), (.45, .56, .43), tone)
    orb("porker pale round chest", (0, -.18, .73), (.36, .30, .36), tone)
    orb("pig large rounded cranium", (0, -.36, 1.02), (.365, .31, .30), tone)
    orb("broad expressive oval muzzle", (0, -.653, .922), (.225, .105, .17), "pig_snout")
    for sx in (-1, 1):
        orb("pig indented oval nostril", (sx*.097, -.752, .935), (.046, .017, .056), "pig_inner")
        orb("bright black round eye", (sx*.175, -.625, 1.11), (.047, .028, .053), "eye")
        orb("eyelight sparkle", (sx*.187, -.653, 1.132), (.014, .009, .017), "eye_shine")
        orb("pink rosy cheek", (sx*.292, -.55, .978), (.071, .028, .048), "pig_light")
        for fy in (-.22, .40):
            orb("pig stout short leg", (sx*.265, fy, .415), (.113, .13, .19), tone)
            box("soft split cloven hoof", (sx*.265, fy-.025, .328), (.18, .20, .09), "pig_shadow", .027)
        ear(-.40, sx, tone, "pig_inner", 1.30)
    orb("pig round flank spot", (.37, .20, .84), (.09, .20, .12), "pig_spot")
    # A distinctive curled tail, visible from the exposed right-hand flank.
    points = [(.38,.53,.89), (.52,.66,.94), (.64,.71,1.04), (.67,.67,1.14),
              (.60,.61,1.15), (.54,.63,1.08)]
    for a, c in zip(points[:-1], points[1:]):
        pole("curled pig spiral tail", a, c, .034, "pig_shadow")
    if not small:
        orb("pig secondary color spot", (-.32, .25, .98), (.10, .16, .064), "pig_light")
    translated(before, x, y, .02, scale)


def pig_pen():
    pasture()
    shelter("pig")
    # Plush mud patch and its tiny sculpted highlights are behind the animal.
    orb("rounded puddle of clean garden mud", (.85, .33, .346), (1.12, .83, .035), "mud")
    for x, y, ra in [(.38,.37,.22), (1.49,.17,.17), (.90,.83,.14)]:
        orb("mud warm reflective patch", (x,y,.374), (ra, ra*.43, .011), "mud_light")
    for x, y in [(.18,.16), (1.56,.50), (.95,.80)]:
        orb("mud splish droplets", (x,y,.388), (.067,.05,.03), "mud_light")
    pig(.52, -.49, 1.02, "pig_blush")
    pig(1.66, .67, .64, "pig_light", True)
    trough(1.81, -1.02)
    bale(-1.80, -.68, .76)
    flowers(0)
    paddock_fence()


def goat(x, y, scale=1.0, tone="cream_fur"):
    """Original smiling bearded goat with tipped ears, horns and split hooves."""
    before = set(bpy.context.scene.objects)
    orb("goat slightly long woolly torso", (0, .11, .85), (.38, .51, .37), tone)
    orb("goat white wool belly", (0, -.13, .76), (.30, .28, .28), "gold_fur" if tone == "kid_fur" else "cream_fur")
    orb("goat tall neck", (0, -.29, 1.09), (.23, .225, .37), tone)
    orb("goat forehead with soft fur", (0, -.38, 1.36), (.295, .245, .27), tone)
    orb("goat expressive muzzle", (0, -.609, 1.238), (.24, .145, .17), "goat_muzzle")
    orb("goat little soft brown triangular nose", (0, -.739, 1.284), (.081, .028, .048), "hoof")
    pole("goat subtle smile", (-.075,-.739,1.165), (0,-.753,1.14), .014, "fur_shadow")
    pole("goat subtle smile right", (0,-.753,1.14), (.075,-.739,1.165), .014, "fur_shadow")
    for sx in (-1,1):
        orb("big black friendly eye", (sx*.155, -.593, 1.408), (.048,.025,.056), "eye")
        orb("tiny eye shine", (sx*.169, -.616, 1.428), (.016,.009,.017), "eye_shine")
        out = orb("soft drooping goat ear", (sx*.33, -.40, 1.433), (.227,.115,.093), tone)
        out.rotation_euler[1] = sx*.20
        orb("goat ear inner colored velvet", (sx*.37, -.486, 1.438), (.152,.022,.046), "goat_ear")
        # A curved horn rather than straight cartoon spikes.
        pole("goat horn lower", (sx*.162,-.29,1.57), (sx*.203,-.21,1.77), .065, "horn")
        pole("goat horn middle", (sx*.203,-.21,1.77), (sx*.228,-.08,1.86), .047, "horn_dark")
        pole("goat horn tip", (sx*.228,-.08,1.86), (sx*.185,.0,1.94), .026, "horn")
        for fy in (-.20, .46):
            pole("goat tapered little leg", (sx*.235,fy,.64), (sx*.25,fy-.035,.37), .075, tone)
            box("goat dark split foot", (sx*.25,fy-.06,.33), (.185,.20,.11), "hoof", .029)
            pole("split hoof groove", (sx*.25,fy-.17,.32), (sx*.25,fy-.17,.39), .009, "fur_shadow")
    orb("small tuft at the nape", (0,-.30,1.605), (.13,.11,.14), "cream_fur")
    for i in (-1,0,1):
        orb("pointed fuzzy beard", (i*.047,-.634,1.055-abs(i)*.02), (.064,.062,.127), "cream_fur")
    orb("upturned fluffy tail", (0,.59,.99), (.14,.18,.16), tone)
    translated(before, x, y, -.03, scale)


def climbing_platform():
    # Playful low wooden training step and ramp, behind the large goat.
    box("sturdy square goat climbing deck", (-.04, .40, .69), (.74, .85, .105), "wood_honey", .036)
    for x in (-.31,.31):
        for y in (.09,.72):
            pole("platform post", (x,y,.35), (x,y,.66), .053, "fence_oak")
    ramp = box("sloped wooden goat ramp", (-.06, -.06, .48), (.66, .72, .09), "wood_honey", .04)
    ramp.rotation_euler[0] = -.34
    for y, z in [(-.29,.43), (-.10,.51), (.09,.57)]:
        box("ramp nonslip oak tread", (-.06,y,z), (.67,.064,.037), "fence_line", .01)


def hayrack():
    # Vertical hay rack with a fan of individual golden stalks.
    box("hay rack rear support", (1.89, .83, .71), (.43,.31,.57), "fence_oak", .041)
    for n in range(11):
        x = 1.70 + n*.035
        start = (x, .61, .55)
        end = (x + (n-5)*.017, .58+(n%3)*.026, .94+RNG.uniform(-.09,.13))
        pole("hay stalks in livestock rack", start, end, .022, "straw_light" if n%3 else "straw")
    for x in (1.72, 2.08):
        pole("hay rack front retention bar", (x,.56,.47), (x,.56,.90), .044, "wood_honey")
    pole("hay rack transverse bar", (1.72,.55,.62), (2.08,.55,.62), .040, "wood_honey")


def goat_pen():
    pasture()
    shelter("goat")
    climbing_platform()
    hayrack()
    goat(.64, -.56, .91, "cream_fur")
    goat(1.41, .59, .63, "kid_fur")
    trough(1.73, -1.18)
    bale(-1.93,-.70,.68)
    flowers(1)
    paddock_fence()


def render(name, builder, scale=8.15, target_height=1.35):
    camera = b.scene_base()
    builder()
    target = Vector((0,0,target_height))
    camera.location = target + Vector((7,-9,8))
    camera.rotation_euler = (target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = scale
    bpy.context.view_layer.update()
    projected = world_to_camera_view(bpy.context.scene, camera, Vector((0,0,.07)))
    anchor = [round(projected.x * 1024), round((1-projected.y)*1024)]
    bpy.context.scene.render.filepath = str(SOURCE / (name+".png"))
    print(f"RENDER_START {name} anchor_raw={anchor} objects={len(bpy.context.scene.objects)}",flush=True)
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_SOURCE/(name+".blend")), compress=True)
    print(f"RENDER_DONE {name} anchor_raw={anchor}",flush=True)
    return anchor


def main():
    SOURCE.mkdir(parents=True, exist_ok=True)
    BLEND_SOURCE.mkdir(parents=True, exist_ok=True)
    palette()
    anchors = {
        "pig_pen": render("pig_pen", pig_pen, 8.1, 1.33),
        "goat_pen": render("goat_pen", goat_pen, 8.25, 1.44),
    }
    (SOURCE/"untrimmed_anchors.json").write_text(
        json.dumps(anchors, indent=2)+"\n",encoding="utf-8"
    )
    print(f"BLENDER_COMPLETE {anchors}",flush=True)


if __name__ == "__main__":
    main()
