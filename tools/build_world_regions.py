"""Build small stylized 3D village props and their Android friendly renders.

Run with Blender 3.4+: blender --background --python tools/build_world_regions.py
The .blend and .glb files are source models; the PNGs are game sprites.
"""
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1] / "assets" / "world_regions"
ROOT.mkdir(parents=True, exist_ok=True)
SOURCE_ROOT = Path(__file__).resolve().parents[2] / "art_sources" / "world_regions"
SOURCE_ROOT.mkdir(parents=True, exist_ok=True)

PALETTE = {
    "grass": (0.28, 0.68, 0.25, 1), "leaf": (0.16, 0.52, 0.19, 1),
    "wood": (0.53, 0.27, 0.11, 1), "wood_light": (0.82, 0.51, 0.24, 1),
    "cream": (0.98, 0.83, 0.51, 1), "blue": (0.10, 0.49, 0.82, 1),
    "red": (0.83, 0.19, 0.18, 1), "orange": (1.0, 0.48, 0.13, 1),
    "purple": (0.50, 0.31, 0.82, 1), "water": (0.13, 0.69, 0.92, 1),
    "stone": (0.48, 0.49, 0.51, 1), "dark": (0.22, 0.20, 0.22, 1),
    "yellow": (1.0, 0.76, 0.10, 1), "pink": (0.95, 0.39, 0.60, 1),
}

def material(name):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = PALETTE[name]
    return mat

def assign(obj, name):
    obj.data.materials.append(material(name))
    return obj

def bevel(obj, width=0.08):
    mod = obj.modifiers.new("Soft rounded edge", "BEVEL")
    mod.width = width
    mod.segments = 2
    obj.data.use_auto_smooth = True
    mod = obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj

def box(name, pos, scale, color, edge=0.08):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel(obj, edge)
    return assign(obj, color)

def sphere(name, pos, scale, color, segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=8, radius=1, location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    for face in obj.data.polygons:
        face.use_smooth = True
    return assign(obj, color)

def cylinder(name, pos, radius, depth, color, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=pos)
    obj = bpy.context.object
    obj.name = name
    bevel(obj, 0.035)
    return assign(obj, color)

def pole(name, start, end, radius, color):
    start, end = Vector(start), Vector(end)
    obj = cylinder(name, (start+end)*0.5, radius, (end-start).length, color, 12)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(end-start)
    return obj

def cone(name, pos, radius1, radius2, depth, color, vertices=12):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=pos)
    return assign(bpy.context.object, color)

def flower(x, y, color="pink"):
    pole("stem", (x,y,0.12), (x,y,0.33), 0.025, "leaf")
    for angle in range(5):
        theta = angle * math.tau / 5
        sphere("flower petal", (x+math.cos(theta)*0.09,y+math.sin(theta)*0.09,0.37), (0.09,0.06,0.035), color, 8)
    sphere("flower centre", (x,y,0.38), (0.06,0.06,0.04), "yellow", 8)

def base(radius=1.5):
    cylinder("round grassy plot", (0,0,-0.12), radius, 0.20, "grass", 32)
    for i in range(10):
        angle = i*math.tau/10
        flower(radius*0.80*math.cos(angle), radius*0.80*math.sin(angle), "pink" if i%2 else "yellow")

def tree(x,y,scale=1):
    cylinder("tree trunk", (x,y,0.60*scale), 0.11*scale, 1.1*scale, "wood")
    for dx,dy,dz in [(-0.28,0,1.15),(0.30,0.08,1.10),(0,-0.20,1.38)]:
        sphere("rounded foliage",(x+dx*scale,y+dy*scale,dz*scale),(0.43*scale,0.39*scale,0.39*scale),"leaf")

def mill():
    base()
    cylinder("stone footing", (0,0,0.08),0.58,0.17,"stone",12)
    cone("cream tapered mill", (0,0,0.91),0.55,0.34,1.55,"cream",12)
    cone("blue tiled roof", (0,0,1.82),0.53,0.02,0.42,"blue",12)
    box("arched wooden door", (0,-0.50,0.42),(0.35,0.10,0.60),"wood")
    pole("windmill shaft",(0,-0.44,1.37),(0,-0.76,1.37),0.11,"wood")
    for a in range(4):
        theta=a*math.pi/2
        x,z=math.sin(theta),math.cos(theta)
        pole("windmill arm",(0,-0.79,1.37),(x*0.88,-0.79,1.37+z*0.88),0.045,"wood")
        blade=box("curved fabric sail",(x*0.62,-0.81,1.37+z*0.62),(0.22,0.06,0.50),"cream")
        blade.rotation_euler[1]=theta

def playground():
    base(1.58)
    for x in [-0.65,0.65]:
        pole("swing frame",(x,-0.4,0.08),(-0.05 if x<0 else 0.05,-0.4,1.48),0.07,"wood_light")
    pole("swing top",(-0.55,-0.4,1.40),(0.55,-0.4,1.40),0.09,"wood")
    for x in [-0.22,0.22]: pole("swing rope",(x,-0.42,1.38),(x,-0.42,0.55),0.024,"cream")
    box("red swing seat",(0,-0.42,0.53),(0.55,0.30,0.08),"red")
    box("slide platform",(0.63,0.55,0.82),(0.55,0.55,0.10),"purple")
    for x in [0.38,0.88]: pole("slide support",(x,0.54,0.08),(x,0.54,0.83),0.055,"wood")
    slide=box("rounded blue slide",(0.60,0.05,0.47),(0.55,1.05,0.08),"blue")
    slide.rotation_euler[0]=math.radians(-30)
    for x in [0.30,0.90]: pole("slide side",(x,-0.48,0.18),(x,0.49,0.89),0.055,"yellow")

def fishing():
    cylinder("rock shore",(0,0,-0.12),1.58,0.20,"stone",32)
    cylinder("blue pond",(0,0,0.0),1.37,0.06,"water",32)
    for x in [-0.42,0.0,0.42]:
        box("dock plank",(x,-0.65,0.20),(0.37,1.35,0.10),"wood_light")
    for x in [-0.56,0.56]:
        for y in [-1.2,-0.08]: cylinder("dock pile",(x,y,0.02),0.07,0.56,"wood")
    sphere("boat hull",(0.5,0.55,0.13),(0.56,0.30,0.18),"wood")
    box("boat seat",(0.5,0.55,0.30),(0.35,0.31,0.06),"cream")
    for i in range(5):
        angle=i*math.tau/5
        x,y=1.2*math.cos(angle),1.2*math.sin(angle)
        pole("reed",(x,y,0.02),(x+0.05,y,0.60),0.025,"leaf")

def mine():
    base(1.55)
    for x,y,r in [(-0.42,0.25,0.69),(0.38,0.38,0.83),(0.0,0.55,1.0)]:
        sphere("faceted rock hill",(x,y,0.30),(r,r*0.68,r*0.70),"stone",8)
    sphere("dark mine opening",(0,-0.53,0.48),(0.48,0.13,0.55),"dark",12)
    for x in [-0.46,0.46]: pole("timber mine support",(x,-0.67,0.10),(x,-0.67,0.95),0.09,"wood")
    pole("timber lintel",(-0.5,-0.67,0.95),(0.5,-0.67,0.95),0.09,"wood")
    for x in [-0.25,0.25]: pole("cart rail",(x,-0.64,0.09),(x,-1.42,0.09),0.035,"wood_light")
    box("ore cart",(0,-1.05,0.31),(0.58,0.40,0.33),"wood")
    for x in [-0.25,0.25]: sphere("wheel",(x,-1.11,0.12),(0.12,0.07,0.12),"dark")

def festival():
    base(1.62)
    cylinder("festival stage",(0,0,0.12),0.92,0.24,"wood_light",16)
    for i in range(10):
        a=i*math.tau/10
        color="red" if i%2 else "yellow"
        x,y=math.cos(a)*0.82,math.sin(a)*0.82
        pole("striped tent roof rib",(0,0,1.75),(x,y,1.09),0.12,color)
        pole("canvas stripe",(x,y,1.09),(x*1.08,y*1.08,0.82),0.14,color)
    pole("festival mast",(0,0,0.20),(0,0,2.05),0.08,"wood")
    cone("flag topper",(0,0,2.05),0.17,0.0,0.25,"purple",6)
    for a in range(8):
        theta=a*math.tau/8
        sphere("paper lantern",(math.cos(theta)*1.15,math.sin(theta)*1.15,0.85),(0.13,0.13,0.16),"pink" if a%2 else "yellow")

def camp():
    base(1.58)
    # A triangular canvas shelter built from a custom prism mesh.
    vertices=[(-0.90,-0.48,0.10),(0.90,-0.48,0.10),(0,-0.48,1.30),(-0.90,0.48,0.10),(0.90,0.48,0.10),(0,0.48,1.30)]
    faces=[(0,1,2),(3,5,4),(0,3,4,1),(0,2,5,3),(1,4,5,2)]
    mesh=bpy.data.meshes.new("tailored canvas");mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new("orange camping tent",mesh);bpy.context.collection.objects.link(obj);assign(obj,"orange");bevel(obj,0.025)
    box("tent entrance",(0,-0.49,0.38),(0.38,0.03,0.55),"dark",0.02)
    pole("tent ridge",(0,-0.55,1.32),(0,0.55,1.32),0.035,"wood")
    for x,y in [(-0.58,-0.75),(0.55,-0.77),(0.68,0.77)]:
        sphere("fire pit stone",(x,y,0.11),(0.13,0.10,0.10),"stone",8)
    cone("camp fire",(0.48,-0.72,0.32),0.16,0.02,0.48,"yellow",8)
    cone("warm flame",(0.48,-0.72,0.38),0.09,0.01,0.31,"red",8)
    tree(-1.04,0.65,0.56)

def setup_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    world=bpy.context.scene.world
    world.color=(0.8,0.9,1.0)
    world.use_nodes=True
    world.node_tree.nodes.get("Background").inputs["Color"].default_value=(0.75,0.86,1.0,1)
    world.node_tree.nodes.get("Background").inputs["Strength"].default_value=0.8

def finish(name):
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_ROOT / (name+".blend")))
    bpy.ops.export_scene.gltf(filepath=str(ROOT / (name+".glb")), export_format="GLB", export_apply=True)
    bpy.ops.object.light_add(type="AREA", location=(-3,-4,7))
    bpy.context.object.data.energy=700
    bpy.context.object.data.size=5
    bpy.ops.object.camera_add(location=(4,-6,4.4))
    camera=bpy.context.object
    direction=Vector((0,0,0.65))-camera.location
    camera.rotation_euler=direction.to_track_quat("-Z","Y").to_euler()
    camera.data.type="ORTHO"
    camera.data.ortho_scale=4.3
    scene=bpy.context.scene
    scene.camera=camera
    scene.render.engine="BLENDER_EEVEE"
    scene.eevee.use_gtao=True
    scene.eevee.use_soft_shadows=True
    scene.render.film_transparent=True
    scene.render.resolution_x=512
    scene.render.resolution_y=512
    scene.render.resolution_percentage=100
    scene.view_settings.view_transform="Standard"
    scene.view_settings.look="Medium High Contrast"
    scene.display.shading.light="STUDIO"
    scene.render.image_settings.file_format="PNG"
    scene.render.filepath=str(ROOT / (name+".png"))
    bpy.ops.render.render(write_still=True)

if __name__ == "__main__":
    for asset_name, build in [
        ("region_mill",mill),("region_playground",playground),("region_fishing",fishing),
        ("region_mine",mine),("region_festival",festival),("region_camp",camp),
    ]:
        setup_scene()
        build()
        finish(asset_name)
        print("BUILT",asset_name,flush=True)
