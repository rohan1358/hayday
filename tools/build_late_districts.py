"""Render the Level 20-50 district landmarks from editable Blender models."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_world_regions as art


def house(x, y, w=0.85, color="blue", wall="cream"):
    art.box("rounded plaster walls", (x, y, 0.56), (w, 0.77, 0.97), wall, 0.08)
    for side in [-1, 1]:
        roof = art.box("overlapping roof tiles", (x + side*w*0.27, y, 1.12), (w*0.63, 0.95, 0.12), color, 0.04)
        roof.rotation_euler[1] = side * math.radians(28)
    art.box("arched entry", (x, y-0.405, 0.35), (w*0.26, 0.045, 0.52), "wood", 0.07)
    for dx in [-w*0.31, w*0.31]:
        art.box("blue shutter window", (x+dx, y-0.415, 0.71), (w*0.17, 0.05, 0.21), "blue", 0.025)
        art.box("window highlight", (x+dx, y-0.449, 0.72), (w*0.10, 0.02, 0.12), "yellow", 0.015)
    art.box("stone threshold", (x, y-0.52, 0.08), (w*0.39, 0.22, 0.12), "stone", 0.035)


def village():
    art.base(1.66)
    house(-0.65, 0.24, 0.86, "blue")
    house(0.50, 0.45, 0.76, "red")
    art.box("village walkway", (0, -0.75, 0.02), (2.45, 0.34, 0.07), "stone")
    art.tree(1.04, 0.33, 0.52)
    art.pole("post", (0.0, -0.95, 0.0), (0.0, -0.95, 0.9), 0.07, "wood")
    art.box("village board", (0, -0.97, 0.80), (0.56, 0.08, 0.29), "wood_light")


def cafe():
    art.base(1.62)
    house(0, 0.45, 1.08, "orange")
    for x in [-0.66, 0.68]:
        art.cylinder("cafe table", (x, -0.68, 0.34), 0.26, 0.08, "wood_light")
        art.cylinder("table pedestal", (x, -0.68, 0.18), 0.04, 0.29, "wood")
    art.pole("umbrella mast", (-0.65,-0.70,0.23),(-0.65,-0.70,1.60),0.06,"wood")
    art.cone("striped shade",(-0.65,-0.70,1.51),0.57,0.04,0.30,"red",12)
    for x in [-0.75,0.75]: art.box("cafe bench",(x,-1.10,0.19),(0.45,0.20,0.11),"wood")


def stable():
    art.base(1.65)
    house(0.25,0.45,1.12,"red","wood_light")
    for x in [-1.10, -0.58, 0.0, 0.58, 1.14]:
        art.pole("paddock post",(x,-0.95,0.05),(x,-0.95,0.52),0.055,"wood")
    for z in [0.23,0.45]: art.pole("paddock rail",(-1.14,-0.96,z),(1.18,-0.96,z),0.035,"wood_light")
    art.sphere("pony torso",(-0.63,-0.28,0.53),(0.40,0.20,0.25),"wood")
    art.sphere("pony head",(-0.92,-0.43,0.81),(0.20,0.15,0.22),"wood_light")
    for x in [-0.86,-0.45]:
        for y in [-0.43,-0.12]: art.pole("pony leg",(x,y,0.44),(x,y,0.16),0.045,"wood")


def station():
    art.base(1.68)
    house(0.10,0.48,1.45,"blue")
    for x in [-1.12, -0.85, -0.58, -0.31, 0.0, 0.31, 0.58, 0.85, 1.12]:
        art.box("rail sleeper",(x,-1.02,0.07),(0.12,0.58,0.06),"wood")
    for y in [-1.20,-0.83]: art.pole("steel rail",(-1.36,y,0.12),(1.36,y,0.12),0.035,"stone")
    art.box("goods carriage",(0.66,-0.98,0.38),(0.74,0.46,0.43),"orange")
    for x in [0.35,0.96]: art.cylinder("rail wheel",(x,-1.18,0.17),0.12,0.07,"dark")


def school():
    art.base(1.62)
    house(0,0.35,1.37,"blue")
    art.box("classroom tower",(0,0.40,1.58),(0.43,0.43,0.62),"cream")
    art.cone("school bell roof",(0,0.40,1.94),0.37,0.02,0.32,"red",4)
    art.sphere("school bell",(0,-0.02,1.57),(0.17,0.07,0.17),"yellow")
    for x in [-0.93,0.93]: art.tree(x,0.38,0.43)
    art.box("school path",(0,-0.91,0.05),(0.41,0.76,0.09),"stone")


def botanical():
    art.base(1.68)
    art.box("greenhouse floor",(0,0.15,0.18),(1.66,1.20,0.14),"stone")
    for x in [-0.84,0,0.84]:
        for y in [-0.46,0.76]: art.pole("glasshouse frame",(x,y,0.25),(x,y,1.47),0.035,"wood_light")
    for y in [-0.46,0.76]: art.pole("arched greenhouse ridge",(-0.84,y,1.47),(0.84,y,1.47),0.04,"blue")
    for x in [-0.84,0.84]: art.pole("glasshouse edge",(x,-0.46,1.47),(x,0.76,1.47),0.04,"blue")
    for x,y in [(-0.48,0.28),(0.35,0.32),(-0.12,-0.12)]:
        art.sphere("botanical glass",(x,y,0.48),(0.28,0.25,0.55),"water")
        art.flower(x,y-0.17,"purple")
    art.tree(1.12,0.50,0.42)


def resort():
    art.cylinder("lake shore",(0,0,-0.11),1.68,0.19,"stone",32)
    art.cylinder("bright lake",(0,0,0.02),1.46,0.07,"water",32)
    house(-0.48,0.48,0.72,"orange")
    art.box("resort deck",(0.60,-0.30,0.20),(0.95,0.88,0.11),"wood_light")
    art.pole("resort parasol",(0.65,-0.34,0.20),(0.65,-0.34,1.35),0.05,"wood")
    art.cone("pink parasol",(0.65,-0.34,1.35),0.46,0.03,0.28,"pink")
    art.sphere("lily pad",(0.38,0.76,0.10),(0.22,0.15,0.03),"leaf")


def tourism():
    art.base(1.68)
    house(-0.63,0.46,0.74,"blue")
    house(0.55,0.46,0.74,"red")
    art.box("plaza",(0,-0.83,0.06),(2.5,0.58,0.11),"stone")
    art.cylinder("fountain rim",(0,-0.76,0.20),0.39,0.16,"cream")
    art.cylinder("fountain water",(0,-0.76,0.29),0.30,0.05,"water")
    for x in [-1.10,1.10]: art.pole("tourist lamp",(x,-0.72,0.1),(x,-0.72,1.28),0.04,"wood")
    for x in [-1.10,1.10]: art.sphere("lamp glow",(x,-0.72,1.32),(0.13,0.13,0.17),"yellow")


def arena():
    art.base(1.68)
    art.cylinder("rounded arena",(0,0,0.14),1.24,0.36,"stone",20)
    art.cylinder("competition field",(0,0,0.34),0.94,0.06,"grass",20)
    for i in range(12):
        a=i*math.tau/12
        x,y=math.cos(a)*1.05,math.sin(a)*1.05
        art.box("colorful stands",(x,y,0.57),(0.42,0.21,0.34),"red" if i%2 else "blue")
    art.cylinder("trophy cup",(0,0,0.64),0.17,0.29,"yellow")
    art.cone("trophy top",(0,0,0.88),0.30,0.09,0.32,"yellow")
    art.sphere("victory star",(0,0,1.21),(0.18,0.18,0.18),"yellow")


def harbor():
    art.cylinder("harbor shore",(0,0,-0.12),1.70,0.20,"stone",32)
    art.cylinder("harbor water",(0,0,0.02),1.48,0.06,"water",32)
    for x in [-0.60,-0.27,0.06]: art.box("pier plank",(x,-0.35,0.20),(0.28,1.90,0.11),"wood_light")
    for y in [-1.22,0.42]: art.pole("pier support",(-0.70,y,0.1),(-0.70,y,0.68),0.06,"wood")
    art.cone("lighthouse tower",(0.94,0.56,0.78),0.34,0.23,1.37,"cream",12)
    art.cone("red lighthouse roof",(0.94,0.56,1.57),0.34,0.03,0.32,"red",12)
    art.box("beacon window",(0.94,0.26,1.38),(0.26,0.06,0.20),"yellow")
    art.sphere("trading boat",(0.34,0.58,0.18),(0.50,0.25,0.17),"wood")
    art.pole("boat mast",(0.34,0.58,0.25),(0.34,0.58,1.27),0.04,"wood")
    art.box("boat sail",(0.55,0.58,0.91),(0.36,0.05,0.55),"cream")


for name, build in [
    ("region_village",village), ("region_cafe",cafe), ("region_stable",stable),
    ("region_station",station), ("region_school",school), ("region_botanical",botanical),
    ("region_resort",resort), ("region_tourism",tourism), ("region_arena",arena),
    ("region_harbor",harbor),
]:
    art.setup_scene()
    build()
    art.finish(name)
    print("BUILT",name,flush=True)
