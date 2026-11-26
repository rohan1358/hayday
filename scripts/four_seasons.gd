extends RefCounted

const SIZE := Vector2(4320, 7680)
const CENTER := Vector2(1728,3686)
static var active_id="summer"
const ORDER := ["summer", "spring", "central", "autumn", "winter"]
const DATA := {
	"spring":{"name":"Spring Valley", "level":1, "center":Vector2(1100,1900), "color":Color("ffffff")},
	"summer":{"name":"Summer Meadow", "level":1, "center":Vector2(1100,1900), "color":Color("f5df8c")},
	"central":{"name":"Central Village", "level":1, "center":CENTER, "color":Color("ffffff")},
	"autumn":{"name":"Autumn Hollow", "level":1, "center":Vector2(1100,5700), "color":Color("dfaa62")},
	"winter":{"name":"Winter Peak", "level":1, "center":Vector2(3250,5700), "color":Color("e6f3fc")}
}
const SITES := {
	"penggilingan":Vector2(650,2450), "rumah_kaca":Vector2(1600,2500),
	"taman_bermain":Vector2(1650,3170), "pemancingan":Vector2(3500,2800),
	"tambang":Vector2(1750,2850), "festival":Vector2(1400,6400),
	"camping":Vector2(650,6050), "permukiman":Vector2(1820,3950),
	"kafe":Vector2(2500,3950), "berkuda":Vector2(3600,1900),
	"stasiun":Vector2(2450,3500), "sekolah":Vector2(1770,3500),
	"botani":Vector2(3600,5400), "resor_danau":Vector2(3100,6300),
	"kota_wisata":Vector2(3700,6800), "arena":Vector2(650,6900),
	"pelabuhan":Vector2(2700,7130)
}
const BRIDGES := [Vector2(2160,3200),Vector2(2160,4500),Vector2(1400,3840),Vector2(2920,3840)]

static func region(at: Vector2) -> String:
	if at.distance_to(CENTER)<350:return "central"
	return active_id

static func unlocked(game, _at: Vector2) -> bool:
	return active_id in ["summer","spring","autumn","winter"] # Entry is gated by IslandJourney; a loaded island is one full playable world.

static func river(at: Vector2) -> bool:
	return preload("res://scripts/reference_terrain.gd").water(at)

static func blocked(game, at: Vector2) -> bool:
	for site in [Vector2(3370,5680),Vector2(3720,6100)]:
		if Rect2(preload("res://scripts/reference_terrain.gd").safe_anchor(site)-Vector2(95,80),Vector2(190,120)).has_point(at): return true
	return not unlocked(game,at) or preload("res://scripts/reference_terrain.gd").solid(at)

static func migrate(game) -> bool:
	preload("res://scripts/island_journey.gd").prepare(game)
	if int(game.world_regions.get("four_seasons_version",0))>=1: return preload("res://scripts/reference_terrain.gd").migrate(game)
	game.world_regions["four_seasons_backup"]={"positions":game.layout_positions.duplicate(true), "decorations":game.decorations.duplicate(true), "trees":game.building_upgrades.get("tree_positions",{}).duplicate(true), "nodes":game.building_upgrades.get("nodes",[]).duplicate(true)}
	# Keep the starter house, three fields and roads in their familiar place.
	for key in game.layout_positions.keys():
		var packed=game.layout_positions[key]
		if not packed is Array or packed.size()!=2: continue
		var point=Vector2(packed[0],packed[1])
		if str(key).begins_with("region_"):
			point=SITES.get(str(key).trim_prefix("region_"),point)
		elif point.x>2200: point=Vector2(450+fposmod(point.x-2200,1350),1800+fposmod(point.y,1300))
		game.layout_positions[key]=[point.x,point.y]
	for id in SITES:
		var point: Vector2=SITES[id]
		if bool(game.world_regions.get("owned",{}).get(id,false)) and not unlocked(game,point):
			var index=SITES.keys().find(id)
			point=Vector2(450+(index%3)*500,2600+floori(float(index)/3.0)*150)
		game.layout_positions["region_"+id]=[point.x,point.y]
	for key in ["roti","susu","pakan"]:
		var point=Vector2(560+["roti","susu","pakan"].find(key)*460,2050)
		game.layout_positions[key]=[point.x,point.y]
	for item in game.decorations:
		var packed=item.get("position",[])
		if packed.size()==2 and float(packed[0])>4200:
			item.position=[500+fposmod(float(packed[0]),1200),2300+fposmod(float(packed[1]),700)]
	var trees: Dictionary=game.building_upgrades.get("tree_positions",{})
	for key in trees:
		var packed=trees[key]
		if float(packed[0])>4200: trees[key]=[400+fposmod(float(packed[0]),1400),2300+fposmod(float(packed[1]),1000)]
	var player=game.hybrid.get("player",[1170,760])
	if player is Array and player.size()==2:
		var at=Vector2(player[0],player[1])
		if not Rect2(Vector2.ZERO,SIZE).has_point(at) or blocked(game,at): game.hybrid.player=[1170,760]
	game.hybrid["jobs"]=[]
	if not game.ftue.is_empty(): game.ftue.asset_overlap_repair=4
	game.world_regions.four_seasons_version=1
	preload("res://scripts/reference_terrain.gd").migrate(game)
	game.save_game()
	return true

static func ground(view, _texture: Texture2D) -> void:
	preload("res://scripts/reference_terrain.gd").paint(view)

static func paint(view) -> void:
	var visible: Rect2=view.visible_world_rect(250)
	var point: Vector2=DATA[active_id].center
	var sign=preload("res://scripts/reference_terrain.gd").safe_anchor(point+Vector2(0,-430),active_id)
	var clear_sign=true
	for key in ["dapur","gudang","roti","susu","ayam","sapi"]:
		var info=preload("res://scripts/asset_projection.gd").info(view,key,view.object_position(key))
		if not info.is_empty() and Rect2(sign-Vector2(255,70),Vector2(510,140)).intersects(info.bounds):clear_sign=false
	if clear_sign and visible.has_point(sign):
		var plaque=StyleBoxFlat.new();plaque.bg_color=Color("a76b37");plaque.border_color=Color("f5d695");plaque.set_border_width_all(5);plaque.set_corner_radius_all(22)
		view.draw_style_box(plaque,Rect2(sign-Vector2(245,60),Vector2(490,120)))
		view.label(str(DATA[active_id].name),sign+Vector2(-215,13),42,Color("fff4ce"))
	for row in (4 if active_id=="summer" else 0):
		for col in 3:
			var flower=Vector2(2670+col*490,1280+row*430)
			if visible.has_point(flower) and preload("res://scripts/reference_terrain.gd").asset_clear(flower): view.farm_art.paint(view,"sunflower_patch",flower,120.0)
	for feature in ([["snow_cabin",Vector2(3370,5680),280.0],["snow_greenhouse",Vector2(3720,6100),270.0]] if active_id=="winter" else []):
		var ground=preload("res://scripts/reference_terrain.gd").safe_anchor(feature[1])
		if visible.has_point(ground): view.farm_art.paint(view,feature[0],ground,feature[2])

static func handle_tap(host,at: Vector2) -> bool:
	if not unlocked(host.game,at):
		var id=region(at)
		host.show_toast("%s terbuka pada Level %d." % [DATA[id].name,DATA[id].level])
		return true
	if river(at): host.show_toast("Gunakan jembatan untuk menyeberangi sungai.");return true
	return false
