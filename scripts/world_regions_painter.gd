extends RefCounted

const REGIONS = preload("res://scripts/world_regions.gd")

static func at(view, id: String) -> Vector2:
	return view.object_position("region_" + id)

static func hit(view, world: Vector2) -> String:
	for id in REGIONS.ORDER:
		var info: Dictionary = REGIONS.DATA[id]
		if not info.has("cost"):
			continue
		var point := at(view, id)
		var visual=view.farm_art.ground_bounds(str(info.art),point,float(info.width))
		if (visual if REGIONS.purchased(view.game,id) else visual.merge(preload("res://scripts/district_signs.gd").rect(point,visual))).has_point(world):
			return id
	return ""

static func visual_clear(view, id: String, point: Vector2) -> bool:
	# Test the complete painted sprite, including the roof. Ground-only tests
	# allowed buildings to look suspended over trees in the isometric view.
	var info: Dictionary = REGIONS.DATA[id]
	var bounds: Rect2 = view.farm_art.ground_bounds(str(info.art), point, float(info.width)).grow(8.0)
	for index in view.WILD_TREES.size():
		if not view.wild_tree_active(index): continue
		var tree: Vector2 = view.wild_tree_position(index)
		if bounds.intersects(Rect2(tree - Vector2(54, 155), Vector2(108, 180))):
			return false
	if not view.game.ftue.is_empty():
		for index in preload("res://scripts/first_farm_world.gd").SCENERY.size():
			var key="starter_%d"%index
			var actual=preload("res://scripts/asset_projection.gd").info(view,key,view.object_position(key))
			if not actual.is_empty() and bounds.intersects(actual.bounds):
				return false
	for other_id in REGIONS.ORDER:
		if other_id == id or not REGIONS.purchased(view.game, other_id): continue
		var other: Dictionary = REGIONS.DATA[other_id]
		if not other.has("art"): continue
		if bounds.intersects(view.farm_art.ground_bounds(str(other.art), at(view,other_id), float(other.width))):
			return false
	return true

static func paint(view) -> void:
	var visible: Rect2=view.visible_world_rect(900)
	var level=preload("res://scripts/island_journey.gd").city_level(view.game)
	var signs=preload("res://scripts/district_signs.gd")
	for id in REGIONS.ORDER:
		var info: Dictionary=REGIONS.DATA[id]
		if not info.has("cost"):continue
		var point=at(view,id)
		if not visible.has_point(point):continue
		var owned=REGIONS.purchased(view.game,id)
		var locked=level<int(info.level)
		if not preload("res://scripts/district_scenes.gd").PARTS.has(str(info.art)):view.paint_grounding(point+Vector2(0,5),float(info.width)*.36,35)
		view.farm_art.paint(view,str(info.art),point,float(info.width),Color.WHITE if owned else Color(.77,.82,.83,.95))
		var art=view.farm_art.ground_bounds(str(info.art),point,float(info.width))
		if id in ["pemancingan","pelabuhan"]:art=Rect2(point-Vector2(220,200),Vector2(440,220))
		var caption=str(info.level) if locked else ("Tingkat %d"%REGIONS.tier(view.game,id) if owned else "Buka · Beli di Kawasan")
		if not owned:signs.paint(view,point,art,str(info.name),caption,locked)
	# Existing working districts keep their functions and get matching name boards.
	for data in [["desa","dapur"],["logistik","gudang"],["pasar_desa","pasar"],["produksi","pakan"],["peternakan","kambing"],["kebun_buah","buah_0"]]:
		var id=str(data[0]);var key=str(data[1]);var point=view.object_position(key)
		if not visible.has_point(point):continue
		var art=preload("res://scripts/asset_projection.gd").info(view,key,point)
		if art.is_empty():continue
		var required=int(REGIONS.DATA[id].level)
		if id in ["logistik","produksi","pasar_desa"]:required=1
		var locked=level<required
		var title="Gudang Panen" if id=="logistik" else str(REGIONS.DATA[id].name)
		if locked:signs.paint(view,point,art.bounds,title,str(required),true)
	# Unpurchased pens and the feed mill remain visible; no animals or rewards are granted.
	for key in ["ayam","sapi","babi","kambing","pakan"]:
		var owned=preload("res://scripts/ranch_state.gd").available(view.game,key) if key!="pakan" else view.game.has_construction("pabrik_pakan")
		if owned:continue
		var point=view.object_position(key)
		if not visible.has_point(point):continue
		var art=preload("res://scripts/asset_projection.gd").info(view,key,point)
		if not art.is_empty():
			view.farm_art.paint(view,str(art.asset),point,float(art.width),Color(.77,.82,.83,.95))
			var title="Pabrik Pakan" if key=="pakan" else "Kandang "+key.capitalize()
			if key not in ["kambing","pakan"]:signs.paint(view,point,art.bounds,title,"3" if level<3 else "Beli di Toko",level<3)
	for key in ["delivery_depot","delivery_truck"]:
		if view.game.feature_unlocked("orders"):continue
		var point=view.object_position(key)
		var art=preload("res://scripts/asset_projection.gd").info(view,key,point)
		if visible.has_point(point) and not art.is_empty():view.farm_art.paint(view,str(art.asset),point,float(art.width),Color(.77,.82,.83,.95))
