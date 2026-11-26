extends RefCounted
# Visual scenery assets only; ecosystem simulation and mutations are separate systems.
const DIRECTORY="res://assets/living_garden/"
const ITEMS=[
	{"id":"lg_greenhouse","level":8,"name":"Rumah Kaca Hias","cost":240,"width":240.0,"half":Vector2(96,65),"pack":"environment","cell":0,"anchor_y":0.88},
	{"id":"lg_composter","level":5,"name":"Sudut Komposter","cost":95,"width":150.0,"half":Vector2(62,42),"pack":"environment","cell":1,"anchor_y":0.88},
	{"id":"lg_stream","level":6,"name":"Aliran Air Mini","cost":170,"width":220.0,"half":Vector2(94,60),"pack":"environment","cell":2,"anchor_y":0.87},
	{"id":"lg_research_desk","level":7,"name":"Meja Riset Kebun","cost":125,"width":175.0,"half":Vector2(70,45),"pack":"environment","cell":3,"anchor_y":0.89},
	{"id":"lg_seed_chest","level":2,"name":"Peti Benih Warna","cost":75,"width":130.0,"half":Vector2(52,34),"pack":"environment","cell":4,"anchor_y":0.86},
	{"id":"lg_blossom_tree","level":4,"name":"Pohon Sakura Kebun","cost":165,"width":220.0,"half":Vector2(65,43),"pack":"environment","cell":5,"anchor_y":0.94},
	{"id":"lg_lantern_tree","level":12,"name":"Pohon Lentera Ungu","cost":230,"width":235.0,"half":Vector2(75,48),"pack":"environment","cell":6,"anchor_y":0.94},
	{"id":"lg_crystal_garden","level":10,"name":"Taman Batu Kristal","cost":135,"width":165.0,"half":Vector2(68,43),"pack":"environment","cell":7,"anchor_y":0.88},
	{"id":"lg_bee_habitat","level":3,"name":"Habitat Lebah Bunga","cost":90,"width":160.0,"half":Vector2(67,43),"pack":"ecosystem","cell":0,"anchor_y":0.89},
	{"id":"lg_frog_habitat","level":6,"name":"Habitat Katak","cost":110,"width":180.0,"half":Vector2(75,48),"pack":"ecosystem","cell":1,"anchor_y":0.87},
	{"id":"lg_butterfly_garden","level":4,"name":"Taman Kupu-kupu","cost":95,"width":170.0,"half":Vector2(72,45),"pack":"ecosystem","cell":2,"anchor_y":0.89},
	{"id":"lg_mushroom_grove","level":5,"name":"Rumpun Jamur Hias","cost":85,"width":170.0,"half":Vector2(70,44),"pack":"ecosystem","cell":3,"anchor_y":0.9},
]
const GROWTH_IDS=["lg_crystal_stage_0","lg_crystal_stage_1","lg_crystal_stage_2","lg_crystal_stage_3"]
