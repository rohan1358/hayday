extends RefCounted
static func info(farm,key: String,at: Vector2) -> Dictionary:
	if preload("res://scripts/asset_edit.gd").special(key):return preload("res://scripts/asset_edit.gd").info(farm,key,at)
	var asset="";var width=0.0;var offset=Vector2.ZERO
	var ranch=preload("res://scripts/ranch_state.gd")
	if key in ranch.SPECIES:
		asset=ranch.INFO[key].asset;width=ranch.PEN_WIDTHS[key]
		if key in ["babi","kambing"]: offset=Vector2(0,30)
	elif key.begins_with("buah_"):
		var index := int(key.trim_prefix("buah_"))
		var fruit: String = farm.game.orchard[index].fruit
		if fruit.is_empty(): fruit="apel"
		asset="fruit_tree_"+fruit+("_ripe" if farm.game.tree_ready(index) else "_bare")
		width=175.0
	elif key in ["dapur","gudang","pakan","roti","susu","buah_0"]:
		var data={"dapur":["kitchen_cottage",300],"gudang":["village_barn",190],"pakan":["feed_mill_building",275],"roti":["bakery_building",265],"susu":["dairy_building",265],"buah_0":["apple_tree",175]}
		asset=data[key][0];width=data[key][1]
	elif key=="pasar":
		asset="market_cart";width=240.0
	elif key in ["delivery_depot","delivery_truck"]:
		asset=key;width=290.0 if key=="delivery_depot" else 210.0
	elif key.begins_with("starter_"):
		var item=preload("res://scripts/first_farm_world.gd").SCENERY[int(key.trim_prefix("starter_"))]
		asset=preload("res://scripts/first_farm_world.gd").seasonal_asset(item[0]);width=item[2]
	elif key.begins_with("dekor_"):
		asset=str(farm.game.decoration_by_key(key).get("kind",""))
		width=float(farm.game.DECORATIONS.get(asset,{}).get("width",100))
	elif key.begins_with("region_"):
		var region=preload("res://scripts/world_regions.gd").DATA.get(key.trim_prefix("region_"),{})
		asset=str(region.get("art",""));width=float(region.get("width",100))
	farm.farm_art.ensure_reference(asset)
	if asset.is_empty() or not farm.farm_art.sprites.has(asset): return {}
	return {"asset":asset,"width":width,"ground":at+offset,"bounds":farm.farm_art.ground_bounds(asset,at+offset,width)}
static func wild_tree_bounds(farm,index: int) -> Rect2:
	return preload("res://scripts/asset_edit.gd").info(farm,"wild_%d"%index,farm.wild_tree_position(index)).bounds
static func nature_clear(farm,bounds: Rect2) -> bool:
	for i in farm.WILD_TREES.size():
		if farm.wild_tree_active(i) and bounds.grow(12).intersects(wild_tree_bounds(farm,i)): return false
	for node in farm.game.building_upgrades.get("nodes",[]):
		var at=Vector2(node.position[0],node.position[1])
		if bounds.grow(42).intersects(farm.farm_art.ground_bounds("resource_boulder",at,130.0)): return false
	return true
static func region_sites_clear(farm,bounds: Rect2,key: String="") -> bool:
	# Cache immutable lot rectangles until a committed layout edit invalidates scenery.
	if int(farm.get_meta("lot_revision",-1))!=farm.scenery_revision:
		var lots={}
		var regions=preload("res://scripts/world_regions.gd")
		for id in regions.ORDER:
			var data: Dictionary=regions.DATA[id]
			if not data.has("cost"):continue
			var name="region_"+id
			var at=farm.object_position(name)
			var visual=farm.farm_art.ground_bounds(str(data.art),at,float(data.width))
			lots[name]=visual.merge(preload("res://scripts/district_signs.gd").rect(at,visual)).merge(Rect2(at-data.half,data.half*2)).grow(20)
		for future in ["ayam","sapi","babi","kambing","roti","susu","pakan","pasar"]:
			var at=farm.object_position(future)
			var item=info(farm,future,at)
			if not item.is_empty():lots[future]=item.bounds.merge(Rect2(at-farm.object_half_size(future),farm.object_half_size(future)*2)).grow(20)
		farm.set_meta("lot_rects",lots);farm.set_meta("lot_revision",farm.scenery_revision)
	for other in farm.get_meta("lot_rects",{}):
		if other!=key and bounds.intersects(farm.get_meta("lot_rects")[other]):return false
	return true
static func paint_foreground(farm):
	var feet: Vector2=farm.ujang_position
	var character=Rect2(feet-Vector2(44,132),Vector2(88,132))
	var entries=[]
	for key in farm.editable_keys():
		var at=farm.object_position(key)
		if at.y<=feet.y: continue
		var item=info(farm,key,at)
		if not item.is_empty() and item.bounds.intersects(character): entries.append(item)
	for index in farm.WILD_TREES.size():
		if not farm.wild_tree_active(index):continue
		var at=farm.wild_tree_position(index)
		if at.y>feet.y and wild_tree_bounds(farm,index).intersects(character):entries.append({"wild":index,"ground":at})
	entries.sort_custom(func(a,b): return a.ground.y<b.ground.y)
	farm.set_world_transform()
	for item in entries:
		if item.has("wild"):farm.paint_wild_tree(int(item.wild),item.ground)
		else:farm.farm_art.paint(farm,item.asset,item.ground,item.width)
