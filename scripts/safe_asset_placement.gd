extends RefCounted
const KEYS={"kandang_ayam":"ayam","kandang_sapi":"sapi","kandang_babi":"babi","kandang_kambing":"kambing","toko_roti":"roti","pabrik_susu":"susu","pabrik_pakan":"pakan"}
static func find(farm,key: String,preferred: Vector2) -> Vector2:
	var projection=preload("res://scripts/asset_projection.gd")
	var source=projection.info(farm,key,preferred)
	var occupied: Array[Rect2]=[]
	if not key.begins_with("dekor_") and not source.is_empty():
		for other in farm.editable_keys():
			if other==key: continue
			var item=projection.info(farm,other,farm.object_position(other))
			if not item.is_empty(): occupied.append(item.bounds)
	var candidates=[preferred]
	for radius in range(80,2001,80):
		for i in 24: candidates.append(preferred+Vector2.from_angle(TAU*i/24)*radius)
	for point in candidates:
		if key=="sapi" and point.distance_to(load("res://scripts/island_layout.gd").preferred("sapi"))>800:continue
		if not preload("res://scripts/reference_terrain.gd").allowed_region(key,point):continue
		if not farm.accessible_world().has_point(point): continue
		var conflict=false
		if not occupied.is_empty():
			var shifted=Rect2(source.bounds.position+point-preferred,source.bounds.size).grow(8)
			for rect in occupied:
				if shifted.intersects(rect): conflict=true;break
		if not conflict and (source.is_empty() or (source.bounds.position+point-preferred).y>=440) and farm.can_place(key,point): return point
	return Vector2.INF
static func clear(farm,key: String,at: Vector2) -> bool:
	if not farm.can_place(key,at): return false
	if key.begins_with("dekor_"): return true
	var projection=preload("res://scripts/asset_projection.gd")
	var candidate=projection.info(farm,key,at)
	if candidate.is_empty(): return true
	if key in ["ayam","sapi","babi","kambing"] and candidate.bounds.position.y<440: return false
	for other in farm.editable_keys():
		if other==key: continue
		var item=projection.info(farm,other,farm.object_position(other))
		if not item.is_empty() and candidate.bounds.grow(8).intersects(item.bounds): return false
	return true
static func commit(host,key: String,at: Vector2):
	host.game.layout_positions[key]=[at.x,at.y]
	host.game.save_game();host.farm.invalidate_scenery()
	if host.farm.hybrid_controller!=null:
		host.farm.hybrid_controller.navigation.revision=""
		host.farm.hybrid_controller.data.follow=false
	host.farm.frame_asset(key)

static func repair_owned_pens(host):
	if int(load("res://scripts/island_layout.gd").state(host.game).get("zoning_version",0))>=1:return
	if host.game.ftue.is_empty() or int(host.game.ftue.get("asset_overlap_repair",0))>=6: return
	var ranch=preload("res://scripts/ranch_state.gd")
	var changed=false
	var unresolved=false
	# Resolve production buildings first so older overlaps keep the player's
	# existing animal pens in place and move the offending workshop instead.
	var repair_keys: Array=["roti","susu","pakan"]
	repair_keys.append_array(ranch.SPECIES)
	repair_keys.append_array(["delivery_depot","delivery_truck","dapur","gudang"])
	for species in repair_keys:
		if species in ranch.SPECIES and not ranch.available(host.game,species): continue
		if species not in host.farm.editable_keys(): continue
		var old=host.farm.object_position(species)
		if species in ["dapur","gudang"]: continue # Move nature away from the home, not the home away from nature.
		if clear(host.farm,species,old): continue
		var at=find(host.farm,species,old)
		if at==Vector2.INF: unresolved=true;continue
		if not host.game.ftue.has("asset_overlap_backup"): host.game.ftue.asset_overlap_backup={}
		host.game.ftue.asset_overlap_backup[species]=[old.x,old.y]
		host.game.layout_positions[species]=[at.x,at.y]
		changed=true
	if not unresolved: host.game.ftue.asset_overlap_repair=6
	host.game.save_game()
	if changed:
		host.farm.invalidate_scenery()
		host.farm.hybrid_controller.navigation.revision=""

# Repair nature around existing assets, keeping purchased buildings in place.
static func repair_nature(host):
	var farm=host.farm
	var projection=preload("res://scripts/asset_projection.gd")
	var data=host.game.building_upgrades
	if not data.has("tree_positions"): data.tree_positions={}
	var signature=JSON.stringify([14,host.game.layout_positions,host.game.decorations,host.game.constructions,host.game.road_tiles,host.game.cleared_wild_trees,["ayam","sapi","babi","kambing"].map(func(species): return host.game.ranch.get("pens",{}).get(species,{}).get("tier",1)),preload("res://scripts/four_seasons.gd").active_id],"",true).sha256_text()
	if str(data.get("nature_signature",""))==signature: return
	var occupied: Array[Rect2]=[]
	var reserve_keys=farm.editable_keys().filter(func(key): return not preload("res://scripts/asset_edit.gd").special(key))
	for key in ["ayam","sapi","babi","kambing","roti","susu","pakan"]:
		if key not in reserve_keys:reserve_keys.append(key)
	for index in farm.game.plots.size():
		var key="petak_%d"%index
		if key not in reserve_keys:reserve_keys.append(key)
	for key in reserve_keys:
		var item=projection.info(farm,key,farm.settled_object_position(key))
		if not item.is_empty(): occupied.append(item.bounds.grow(45))
		elif key.begins_with("petak_"):
			occupied.append(Rect2(farm.plot_center(int(key.trim_prefix("petak_")))-Vector2(100,100),Vector2(200,165)))
	for node in host.game.building_upgrades.get("nodes",[]):
		var point=Vector2(node.position[0],node.position[1])
		occupied.append(farm.farm_art.ground_bounds("resource_boulder",point,130).grow(55))
	var fallback: Array[Vector2]=[]
	for y in range(1100,7100,80):
		for x in range(350,4050,80): fallback.append(Vector2(x,y))
	data.hidden_trees={}
	var accepted: Array[Rect2]=[]
	var accepted_roots: Array[Vector2]=[]
	# Regenerated trees are placed and checked by wild_tree_regrowth.gd.
	# Never relocate inactive reserved slots during old-world repairs.
	var tree_order=range(farm.original_wild_tree_count)
	var manual: Dictionary=data.get("manual_trees",{})
	tree_order.sort_custom(func(a,b):return bool(manual.get(str(a),false)) and not bool(manual.get(str(b),false)))
	for i in tree_order:
		if i in host.game.cleared_wild_trees: continue
		var original=farm.wild_tree_position(i)
		var bounds=projection.wild_tree_bounds(farm,i)
		var candidates=[original]
		# Try widely distributed slots before the fine-grained shoreline fallback.
		for slot in 240:
			var cell=(slot+i*37)%240
			candidates.append(Vector2(480+(cell%12)*280,1400+int(cell/12)*280))
		for radius in range(180,2161,180):
			for step in 16: candidates.append(original+Vector2.from_angle(TAU*step/16.0)*radius)
		candidates.append_array(fallback)
		var placed=false
		for relaxed in [false,true]:
			if placed:break
			var reserved=occupied if relaxed else occupied+accepted
			for candidate in candidates:
				var actual=preload("res://scripts/reference_terrain.gd").tree_bounds(candidate,i)
				var shifted=actual.grow(14)
				if shifted.position.y<820 or not Rect2(Vector2(90,820),farm.WORLD_SIZE-Vector2(180,1000)).encloses(shifted):continue
				var blocked=false
				for other in reserved:
					if shifted.intersects(other):blocked=true;break
				if blocked:continue
				if relaxed:
					for root in accepted_roots:
						if root.distance_squared_to(candidate)<120.0*120.0:blocked=true;break
					if blocked:continue
				if not projection.region_sites_clear(farm,shifted):continue
				if not preload("res://scripts/reference_terrain.gd").asset_clear(candidate):continue
				if not preload("res://scripts/reference_terrain.gd").bounds_clear(shifted):continue
				if not preload("res://scripts/reference_terrain.gd").bounds_clear(actual):continue
				if farm.road_overlaps_rect(shifted):continue
				data.tree_positions[str(i)]=[candidate.x,candidate.y]
				accepted.append(shifted);accepted_roots.append(candidate);placed=true
				break
		if not placed:data.hidden_trees[str(i)]=true
	if farm.hybrid_controller!=null:
		preload("res://scripts/building_upgrades.gd").setup_nodes(farm.hybrid_controller)
		farm.hybrid_controller.navigation.revision=""
	farm.invalidate_scenery()
	data.nature_signature=signature
	host.game.save_game()
