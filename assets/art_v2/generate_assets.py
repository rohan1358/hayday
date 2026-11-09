"""Generate original 3/4-view farm art for Kebun Ceria with Blender 5.x.

Run from any directory:
    blender --background --python generate_assets.py

Only files in this directory are written. A second script adds soft shadows,
checks each PNG, and produces the manifest + review contact sheet.
"""

import bpy
import math
import random
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view


ROOT = Path(__file__).resolve().parent
RESOLUTION = 1024
RNG = random.Random(260611)


def material(name, hex_color, roughness=0.85):
    # Node shader colors are scene-linear; convert the art-directed sRGB palette.
    srgb = tuple(int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    color = tuple(c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in srgb)
    out = bpy.data.materials.new(name)
    out.diffuse_color = (*color, 1.0)
    out.use_nodes = True
    surface = out.node_tree.nodes.get("Principled BSDF")
    surface.inputs["Base Color"].default_value = (*color, 1.0)
    surface.inputs["Roughness"].default_value = roughness
    return out


def setup_materials():
    global M
    palette = {
        "cream": "#f9e3ad", "cream_shadow": "#ecc78d", "ivory": "#fff1cb",
        "yellow": "#f7c875", "orange": "#ee925f", "orange_dark": "#bf684d",
        "red": "#cb6654", "red_light": "#e48166", "red_dark": "#9c4d43",
        "roof": "#c66b4e", "roof_light": "#dc8661", "roof_deep": "#a75146",
        "wood": "#b77747", "wood_light": "#d9a46b", "wood_dark": "#85523e",
        "straw": "#efba58", "straw_light": "#ffdc85", "straw_dark": "#c78e3d",
        "stone": "#b6b39b", "stone_light": "#d5ccb0", "stone_dark": "#888d7a",
        "mint": "#a8c984", "grass": "#87b86b", "grass_light": "#b7d788",
        "grass_dark": "#5e9b64", "leaf": "#69a968", "leaf_light": "#9bd37c",
        "leaf_sun": "#c1dc83", "leaf_dark": "#477e57", "leaf_cool": "#74b18b",
        "soil": "#865b46", "soil_light": "#ab7453", "soil_dark": "#694b3e",
        "skyblue": "#9ccdd1", "glass": "#82b8b1", "glass_dark": "#4d9293",
        "peach": "#ef9b78", "pink": "#ee8e9e", "rose": "#d86d81",
        "white": "#fff4dc", "butter": "#f5e0ac", "berry": "#bd5150",
        "gold": "#f7c566", "lavender": "#b4a4ce", "lavender_dark": "#9886b6",
        "mushroom": "#d89976", "stem": "#739d59", "dark": "#65544a",
    }
    M = {key: material(key, value) for key, value in palette.items()}


def assign(obj, color):
    obj.data.materials.append(M[color] if isinstance(color, str) else color)
    return obj


def box(name, center, dimensions, color, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(obj, color)
    if bevel:
        modifier = obj.modifiers.new("soft edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.affect = "EDGES"
        normals = obj.modifiers.new("weighted normals", "WEIGHTED_NORMAL")
        normals.keep_sharp = True
    return obj


def mesh(name, verts, faces, color):
    geo = bpy.data.meshes.new(name)
    geo.from_pydata(verts, [], faces)
    geo.update()
    obj = bpy.data.objects.new(name, geo)
    bpy.context.collection.objects.link(obj)
    assign(obj, color)
    return obj


def orb(name, center, radius, color, segments=14, rings=9):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.scale = radius
    assign(obj, color)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def ico(name, center, radius, color, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.scale = radius
    assign(obj, color)
    return obj


def pole(name, a, b, radius, color, vertices=10):
    start, end = Vector(a), Vector(b)
    diff = end - start
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=diff.length, location=(start + end) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = diff.to_track_quat("Z", "Y").to_euler()
    assign(obj, color)
    return obj


def planks_front(x_positions, y, z_min, z_max, tone="wood_dark", thickness=0.018):
    for ix, x in enumerate(x_positions):
        pole(f"front plank seam {ix}", (x, y, z_min), (x, y, z_max), thickness, tone, 6)


def grass_tuft(x, y, scale=1.0):
    for i in range(3):
        at = (x + (i - 1) * 0.08 * scale, y + (i % 2) * 0.04 * scale, 0.08)
        obj = orb("grass tuft", at, (0.05 * scale, 0.04 * scale, 0.13 * scale), "grass" if i != 1 else "grass_light", 9, 6)
        obj.rotation_euler[1] = (i - 1) * 0.32


def flower(x, y, z, color="pink", scale=1.0):
    pole("flower stem", (x, y, z - 0.24 * scale), (x, y, z), 0.018 * scale, "stem", 6)
    orb("left leaf", (x - 0.06 * scale, y, z - 0.12 * scale), (0.09, 0.035, 0.035), "leaf", 9, 6)
    for i in range(5):
        angle = 2 * math.pi * i / 5
        orb("flower petal", (x + math.cos(angle) * 0.084 * scale,
                             y + math.sin(angle) * 0.084 * scale,
                             z + 0.016 * scale),
            (0.085 * scale, 0.085 * scale, 0.036 * scale), color, 10, 6)
    orb("flower center", (x, y, z + 0.055 * scale), (0.052 * scale,) * 3, "gold", 10, 6)


def gable_walls(width, depth, wall_z, peak_z, material_name):
    half_w, half_d = width / 2, depth / 2
    for side in (-1, 1):
        y = side * half_d
        mesh("gable plaster", [(-half_w, y, wall_z), (half_w, y, wall_z),
                               (0, y, peak_z)], [(0, 1, 2)], material_name)


def roof(width, depth, wall_z, peak_z, color, trim_color, front_shift=0, tile_color=None):
    half_w, half_d = width / 2, depth / 2
    half_w += 0.14
    half_d += 0.16
    for side in (-1, 1):
        upper = [(0, -half_d, peak_z), (0, half_d, peak_z),
                 (side * half_w, half_d, wall_z), (side * half_w, -half_d, wall_z)]
        lower = [(x, y, z - 0.13) for x, y, z in upper]
        mesh("roof thick slab", upper + lower,
             [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1),
              (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], color)
        pole("gable fascia", upper[0], upper[3], 0.065, trim_color)
        pole("gable fascia back", upper[1], upper[2], 0.058, trim_color)
        pole("eave timber", upper[3], upper[2], 0.061, trim_color)
        # Each small raised roof tile adds visible rhythm in the isometric view.
        if tile_color:
            for row in range(4):
                frac = (row + 1.0) / 5.0
                x = side * half_w * frac
                z = peak_z - (peak_z - wall_z) * frac + 0.025
                for col in range(5):
                    y = (-0.77 + 0.385 * col) * half_d
                    tile = box("curved roof shingle", (x, y, z), (0.26, 0.34, 0.048),
                               tile_color if (row + col) % 4 else trim_color, 0.04)
                    tile.rotation_euler[1] = side * math.atan2(peak_z - wall_z, half_w)
    pole("ridge cap", (0, -half_d, peak_z), (0, half_d, peak_z), 0.075, trim_color)


def window_front(x, y, z, size=0.48):
    box("window outer frame", (x, y - 0.037, z), (size + 0.14, 0.1, size + 0.17), "wood_light", 0.035)
    box("window deep blue pane", (x, y - 0.096, z), (size, 0.037, size), "glass", 0.025)
    pole("window bar vertical", (x, y - 0.12, z - size / 2), (x, y - 0.12, z + size / 2), 0.024, "ivory", 6)
    pole("window bar horizontal", (x - size / 2, y - 0.12, z), (x + size / 2, y - 0.12, z), 0.022, "ivory", 6)
    box("window flower ledge", (x, y - 0.14, z - size / 2 - 0.04), (size + 0.19, 0.18, 0.09), "wood", 0.02)


def window_side(x, y, z, size=0.5):
    box("side frame", (x, y, z), (0.09, size + 0.1, size + 0.1), "wood_light", 0.015)
    box("side glass", (x + 0.06, y, z), (0.025, size, size), "glass", 0.012)
    pole("side window bar", (x + 0.077, y - size / 2, z), (x + 0.077, y + size / 2, z), 0.025, "ivory", 6)
    pole("side window bar", (x + 0.077, y, z - size / 2), (x + 0.077, y, z + size / 2), 0.025, "ivory", 6)


def flowerpot(x, y):
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.14, radius2=0.20,
                                    depth=0.24, location=(x, y, 0.15))
    assign(bpy.context.object, "orange_dark")
    orb("pot shrub", (x, y, 0.33), (0.19, 0.18, 0.15), "leaf", 12, 8)
    for ix in (-1, 1):
        orb("pot blossom", (x + ix * 0.11, y - 0.06, 0.41), (0.05, 0.045, 0.05), "pink", 9, 6)


def cottage():
    box("stone footing", (0, 0, 0.16), (2.66, 2.1, 0.32), "stone", 0.07)
    box("warm stucco cottage", (0, 0, 1.04), (2.55, 2, 1.73), "cream", 0.05)
    gable_walls(2.55, 2.0, 1.90, 2.91, "cream_shadow")
    # Corner structural beams visible at the front and sunlit right wall.
    for x in (-1.20, 1.20):
        box("oak corner trim", (x, -1.023, 1.04), (0.11, 0.075, 1.78), "wood_light", 0.018)
    for z in (0.40, 1.78):
        box("horizontal cottage trim", (0, -1.022, z), (2.49, 0.073, 0.09), "wood_light", 0.015)
    roof(2.75, 2.25, 1.94, 3.04, "roof", "roof_deep", tile_color="roof_light")
    # Chimney with visible chimney cap and brick lines.
    box("chimney bricks", (-0.67, 0.40, 2.82), (0.43, 0.43, 1.17), "red", 0.04)
    box("chimney crown", (-0.67, 0.40, 3.45), (0.55, 0.55, 0.14), "stone_light", 0.04)
    for z in (2.54, 2.79, 3.04, 3.25):
        pole("chimney mortar", (-0.9, 0.172, z), (-0.46, 0.172, z), 0.014, "cream_shadow", 6)
    # Front entry, dark recess, bright curved sign and steps.
    box("entry surround", (-0.40, -1.065, 0.89), (0.84, 0.13, 1.50), "wood_light", 0.07)
    box("entry recessed", (-0.40, -1.145, 0.86), (0.65, 0.055, 1.37), "wood_dark", 0.04)
    box("honey colored door", (-0.40, -1.183, 0.87), (0.59, 0.050, 1.30), "wood", 0.06)
    for x in (-0.59, -0.40, -0.21):
        pole("door timber grooves", (x, -1.215, 0.28), (x, -1.215, 1.42), 0.012, "wood_dark", 6)
    orb("brass door handle", (-0.17, -1.238, 0.84), (0.046, 0.025, 0.046), "straw_light", 10, 6)
    box("porch welcome step", (-0.41, -1.34, 0.12), (1.06, 0.60, 0.22), "stone_light", 0.08)
    window_front(0.72, -1.025, 1.23, 0.52)
    window_side(1.30, 0.18, 1.20, 0.52)
    # Overhanging shop sign signals kitchen/workshop without embedding text.
    box("bakery signboard", (0.36, -1.18, 2.15), (0.56, 0.095, 0.33), "wood_dark", 0.085)
    orb("sign bread emblem", (0.36, -1.248, 2.17), (0.18, 0.02, 0.09), "straw_light", 12, 8)
    for x in (-1.09, 1.02):
        flowerpot(x, -1.21)
    for x, y in [(-1.18, -0.80), (1.15, 0.85), (-0.99, 0.95)]:
        grass_tuft(x, y, 0.85)


def barn():
    box("foundation stones", (0, 0, 0.17), (3.16, 2.46, 0.34), "stone", 0.08)
    box("terracotta barn", (0, 0, 1.21), (3.06, 2.35, 2.08), "red", 0.052)
    gable_walls(3.04, 2.35, 2.25, 3.45, "red_light")
    roof(3.18, 2.57, 2.29, 3.58, "roof_deep", "wood_dark", tile_color="roof")
    # Corner timbers and siding rhythm.
    for x in (-1.40, 1.40):
        box("barn ivory corner", (x, -1.198, 1.18), (0.13, 0.076, 2.13), "ivory", 0.023)
    for z in (0.47, 2.17):
        box("cream horizontal rail", (0, -1.200, z), (2.99, 0.076, 0.12), "cream_shadow", 0.012)
    for x in (-1.14, -0.92, 0.92, 1.14):
        pole("slat rhythm", (x, -1.208, 0.50), (x, -1.208, 2.1), 0.012, "red_dark", 6)
    for y in (-0.90, -0.45, 0, 0.45, 0.9):
        pole("side siding", (1.56, y, 0.47), (1.56, y, 2.13), 0.012, "red_dark", 6)
    # Two large doors with X braces.
    box("door portal", (0, -1.223, 1.02), (1.98, 0.105, 1.70), "wood_dark", 0.028)
    for side in (-1, 1):
        x = side * 0.48
        box("barn sliding door", (x, -1.292, 1.02), (0.90, 0.085, 1.58), "wood", 0.015)
        for offset in (-0.25, 0, 0.25):
            pole("door boards", (x + offset, -1.343, 0.29), (x + offset, -1.343, 1.73),
                 0.014, "wood_dark", 6)
        pole("barn X brace a", (x - 0.36, -1.372, 0.40), (x + 0.36, -1.372, 1.59), 0.058, "ivory", 6)
        pole("barn X brace b", (x + 0.36, -1.378, 0.40), (x - 0.36, -1.378, 1.59), 0.058, "ivory", 6)
        orb("latch rivet", (x - side * 0.34, -1.407, 1.02), (0.047, 0.032, 0.047), "straw_light", 10, 6)
    # Loft opening, roof-end badge and right-wall accents.
    orb("loft wooden round frame", (0, -1.224, 2.69), (0.37, 0.068, 0.37), "cream_shadow", 24, 12)
    orb("loft circular glass", (0, -1.300, 2.69), (0.275, 0.02, 0.275), "glass_dark", 24, 12)
    pole("round window mullion", (0, -1.325, 2.43), (0, -1.325, 2.94), 0.032, "ivory")
    pole("round window mullion", (-0.25, -1.325, 2.69), (0.25, -1.325, 2.69), 0.032, "ivory")
    window_side(1.54, 0.45, 1.25, 0.57)
    # Hay bundle, sack and tiny wildflowers make the barn feel inhabited.
    box("hay bale side", (1.61, -0.81, 0.36), (0.73, 0.53, 0.52), "straw", 0.08)
    for z in (0.24, 0.51):
        pole("hay baling rope", (1.64, -1.09, z), (2.04, -1.09, z), 0.023, "straw_dark")
    orb("grain sack", (-1.23, -1.44, 0.28), (0.23, 0.20, 0.34), "butter", 12, 8)
    for x, y in [(-1.35, 0.88), (1.44, 1.06), (1.25, -1.24)]:
        grass_tuft(x, y)


def apple_tree():
    # Layered twisting trunk and branches.
    pole("tree trunk base", (0, 0, 0.20), (0.05, 0.02, 2.44), 0.28, "wood_dark", 12)
    pole("tree sunlit bark", (-0.10, -0.12, 0.40), (0.01, -0.12, 2.24), 0.082, "wood", 8)
    for i, (a, b) in enumerate([
        ((0.01, 0, 1.77), (-0.98, -0.19, 2.70)),
        ((0.04, 0, 2.03), (0.92, 0.33, 2.82)),
        ((0.02, 0, 2.18), (-0.21, 0.91, 3.01)),
        ((0, -0.04, 1.61), (0.55, -0.87, 2.67)),
    ]):
        pole(f"branch {i}", a, b, 0.14 if i < 2 else 0.105, "wood", 9)
    orb("root shadow mound", (0, 0, 0.09), (0.78, 0.65, 0.18), "grass", 18, 10)
    # Distinct interior canopy mass, irregular overlapping cloudlets.
    bases = [
        (-0.88, 0.40, 2.66, .88), (-0.21, .84, 3.16, .85),
        (.74, .70, 3.10, .80), (1.12, .06, 2.69, .74),
        (.65, -.69, 2.99, .87), (-.18, -.85, 3.14, .83),
        (-1.03, -.40, 2.84, .79), (.12, .03, 3.67, .96),
        (-.82, -.1, 3.45, .73), (.89, -.02, 3.53, .71),
        (-.26, -.33, 2.70, .95), (.40, .43, 2.75, .80),
    ]
    for i, (x, y, z, r) in enumerate(bases):
        col = ["leaf_dark", "leaf", "grass", "leaf_cool", "leaf_light", "leaf"][i % 6]
        ico("canopy primary", (x, y, z), (r, r * .82, r * .79), col, 3)
    for i in range(76):
        angle = RNG.uniform(0, math.tau)
        phi = RNG.uniform(-0.12, 1.18)
        r = RNG.uniform(0.77, 1.60)
        x = r * math.cos(angle)
        y = r * math.sin(angle) * 0.88
        z = 3.18 + 0.72 * math.sin(phi) + RNG.uniform(-.43, .45)
        col = RNG.choices(["leaf", "leaf_light", "leaf_sun", "leaf_cool", "grass_dark"],
                          weights=[22, 32, 12, 20, 14])[0]
        orb("small leafy pompom", (x, y, z),
            (RNG.uniform(.19, .36), RNG.uniform(.21, .35), RNG.uniform(.20, .38)),
            col, 12, 8)
    # Apples hang off the front-facing canopy. Add small leaf and highlight to each.
    for i, (x, y, z) in enumerate([
        (-.81,-1.06,3.21), (-.23,-1.34,3.39), (.58,-1.14,3.07),
        (.99,-.69,3.70), (-1.21,-.58,3.59), (.11,-.64,4.02),
        (-.58,-.43,4.16), (1.28,.12,3.28), (-1.52,.13,3.02),
        (.78,-.32,2.66), (-.18,-1.00,2.80),
    ]):
        fruit_color = "berry" if i % 3 else "red_light"
        orb("ripe apple", (x, y, z), (.115, .12, .125), fruit_color, 14, 9)
        pole("apple stem", (x, y, z + .12), (x + .012, y, z + .19), .012, "wood_dark", 6)
        orb("apple top leaf", (x + .055, y, z + .15), (.085,.040,.024), "leaf_sun", 10, 6)
    for x, y in [(-0.56, -0.24), (0.65, 0.18), (0.16, -0.58)]:
        grass_tuft(x, y)


def soil_base():
    box("soil layer", (0, 0, .17), (3.03, 2.45, .31), "soil_dark", 0.085)
    box("top earth surface", (0, 0, .33), (2.83, 2.25, .075), "soil", 0.02)
    # Four thick wooden beams around the bed, with joints at the corners.
    for y in (-1.18, 1.18):
        box("horizontal planter rail", (0, y, .30), (3.16, .19, .28), "wood", .04)
        pole("planter highlight", (-1.42, y - .072, .45), (1.42, y - .072, .45), .023, "wood_light")
    for x in (-1.52, 1.52):
        box("side planter rail", (x, 0, .30), (.20, 2.47, .28), "wood_dark", .04)
        pole("planter edge", (x - .07, -1.10, .46), (x - .07, 1.10, .46), .023, "wood_light")
    for x in (-1.52, 1.52):
        for y in (-1.18, 1.18):
            orb("wood joint cap", (x, y, .464), (.050,.050,.021), "straw_light", 9, 5)
    # Ridges follow the Y axis and are visibly three dimensional.
    for x in (-.91, -.33, .33, .91):
        orb("soft tilled soil ridge", (x, 0, .41), (.21, 1.00, .108),
            "soil_light" if x > 0 else "soil", 20, 10)
        for y in (-.82, -.47, -.04, .37, .73):
            orb("soil turned earth fleck", (x + .07, y, .495), (.060,.09,.023), "soil_light", 10, 6)
    for x, y in [(-1.12,-.88),(-.04,.88),(.77,-.60),(1.21,.38)]:
        orb("field pebble", (x, y, .43), (.06,.04,.025), "stone_light", 10, 6)


def plot_empty():
    soil_base()
    # Tiny croppable starter sprouts clarify scale but keep the tile visibly empty.
    for x, y in [(-1.14, -.79), (1.07, .70)]:
        pole("young grass tip", (x,y,.43), (x,y,.56), .014, "stem", 6)
        orb("young leaf", (x-.06,y,.54), (.09,.040,.026), "leaf_light", 10,6)


def wheat_stalk(x, y, height):
    z0, z1 = .48, .48 + height
    bend = RNG.uniform(-.09, .09)
    pole("wheat stalk", (x,y,z0), (x + bend,y + .015,z1), .017, "stem", 7)
    for j in range(2):
        z = z0 + height * (.25 + j * .20)
        direction = -1 if j % 2 else 1
        leaf = orb("wheat blade", (x + direction * .11, y - .025, z),
                   (.16, .039, .034), "grass_light" if j % 2 else "leaf", 10, 7)
        leaf.rotation_euler[1] = direction * .45
    top = Vector((x + bend, y, z1))
    for j in range(4):
        dz = j * .105
        for side in (-1, 1):
            orb("golden grain", (top.x + side * (.055 - .010 * j), top.y, top.z + dz),
                (.063, .065, .102), "straw_light" if (j + side) % 3 else "straw", 10, 7)
    orb("wheat grain tip", (top.x, top.y, top.z + .43), (.043,.050,.1), "straw_light", 10,7)
    for direction in (-1, 1):
        pole("awn bristle", (top.x + direction * .05, top.y, top.z + .31),
             (top.x + direction * .15, top.y, top.z + .52), .008, "straw", 5)


def plot_wheat_ready():
    soil_base()
    for x in (-.94, -.44, .10, .65, 1.09):
        for y in (-.77, -.24, .33, .82):
            height = RNG.uniform(.76, 1.20)
            wheat_stalk(x + RNG.uniform(-.08, .08), y + RNG.uniform(-.08, .08), height)
    for x, y in [(-1.20, -.89), (1.20, .86)]:
        grass_tuft(x, y, .60)


def garden():
    box("earth flower bed", (0,0,.18), (2.84, 2.29, .33), "soil", .13)
    orb("scalloped bed foliage", (0,.05,.33), (1.41, 1.04, .22), "grass_dark", 20, 12)
    for index in range(18):
        angle = index * math.tau / 18
        x = math.cos(angle) * 1.40
        y = math.sin(angle) * 1.10
        ico("hand laid edge stone", (x,y,.20), (.25,.21,.17),
            ["stone_light", "stone", "butter"][index % 3], 1)
    # Front flowers are low so the taller back row remains readable.
    for row, yy in enumerate((.66, .19, -.40, -.79)):
        for col, xx in enumerate((-.93, -.45, .08, .61, 1.00)):
            x = xx + RNG.uniform(-.13,.13)
            y = yy + RNG.uniform(-.10,.10)
            height = (.57 if row < 2 else .47) + RNG.uniform(-.10,.13)
            flower(x,y,height,["pink","lavender","white","orange","rose"][((row*2)+col)%5],
                   RNG.uniform(.72,.95))
            if RNG.random() < .65:
                orb("leafy flower bush", (x, y, .34), (.13,.14,.12),
                    "grass_light" if col % 2 else "leaf", 10, 7)
    # Behind the flowers sits a small trellis with rustic wood posts.
    for x in (-1.14, 0, 1.14):
        pole("trellis post", (x,.92,.21), (x,.92,1.13), .065, "wood_light", 8)
    for z in (.70, 1.06):
        pole("trellis rail", (-1.16,.92,z), (1.16,.92,z), .048, "wood", 8)
    # Butterfly alights above the flowers, wings read as a silhouette.
    orb("butterfly wing left", (.16,-.38,1.10), (.18,.036,.125), "lavender", 12, 8)
    orb("butterfly wing right", (.50,-.38,1.10), (.18,.036,.125), "pink", 12, 8)
    pole("butterfly body", (.33,-.38,1.02), (.33,-.38,1.22), .028, "dark", 7)


def scene_base():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = RESOLUTION
    scene.render.resolution_y = RESOLUTION
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.image_settings.color_depth = "8"
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = 64
    scene.render.image_settings.compression = 65
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0
    world = bpy.data.worlds.new("Warm daylight")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.38, 0.49, 0.42, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.52
    # Three softbox lights keep materials dimensional but avoid hard contours.
    for name, loc, power, size, color in [
        ("golden key", (-3.8, -4.8, 9), 360, 6.0, (1.0,.89,.78)),
        ("sky fill", (5.0, -2.0, 6.0), 155, 7.0, (.78,.88,1.0)),
        ("warm rim", (1.0, 5.0, 9.0), 210, 6.0, (1.0,.90,.80)),
    ]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy = power
        data.shape = "DISK"
        data.size = size
        data.color = color
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        light.location = loc
        light.rotation_euler = (Vector((0,0,1.0)) - light.location).to_track_quat("-Z", "Y").to_euler()
    data = bpy.data.cameras.new("shared farm 3-4 view")
    camera = bpy.data.objects.new("shared farm 3-4 view", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return camera


def render_asset(name, maker, ortho, target_height):
    camera = scene_base()
    maker()
    target = Vector((0,0,target_height))
    camera.location = target + Vector((7,-9,8.0))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = ortho
    bpy.context.view_layer.update()
    projected = world_to_camera_view(bpy.context.scene, camera, Vector((0,0,.05)))
    pixel_anchor = [round(projected.x * RESOLUTION), round((1 - projected.y) * RESOLUTION)]
    bpy.context.scene.render.filepath = str(ROOT / f"{name}.png")
    print(f"ASSET_RENDER name={name} anchor={pixel_anchor}", flush=True)
    bpy.ops.render.render(write_still=True)
    return (name, pixel_anchor)


def main():
    setup_materials()
    assets = [
        ("kitchen_cottage", cottage, 5.14, 1.62),
        ("village_barn", barn, 5.55, 1.83),
        ("apple_tree", apple_tree, 5.95, 2.21),
        ("soil_plot_empty", plot_empty, 4.28, .43),
        ("wheat_plot_ready", plot_wheat_ready, 4.32, .83),
        ("flower_garden", garden, 4.13, .54),
    ]
    import json
    anchors = {}
    for name, maker, scale, target_z in assets:
        _, anchors_for = render_asset(name, maker, scale, target_z)
        anchors[name] = anchors_for
    (ROOT / "anchors.json").write_text(json.dumps(anchors, indent=2) + "\n", encoding="utf-8")
    print("RENDER_PASS all 6 assets written", flush=True)


if __name__ == "__main__":
    main()
