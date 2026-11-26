extends RefCounted
# Materials are stored separately so a full harvest warehouse never blocks upgrades.
const NAMES = {"gudang":"Gudang Panen", "dapur":"Dapur", "rumah":"Rumah", "roti":"Toko Roti", "susu":"Pabrik Susu"}
const MATERIALS = {"batu":"Batu", "kayu":"Kayu", "paku":"Paku", "palu":"Palu"}
const TASKS = {"panen":"Panen hasil", "pengiriman":"Selesaikan pesanan", "produksi":"Ambil hasil dapur"}
static func prepare(game) -> Dictionary:
	var data: Dictionary = game.building_upgrades
	if not data.get("tiers", {}) is Dictionary: data.tiers = {}
	if not data.get("materials", {}) is Dictionary: data.materials = {}
	if not data.get("missions", {}) is Dictionary: data.missions = {}
	if not data.get("nodes", []) is Array: data.nodes = []
	for key in ["tiers", "materials", "missions"]:
		if not data.has(key): data[key] = {}
	if not data.has("nodes"): data.nodes = []
	for key in NAMES: data.tiers[key] = clampi(int(data.tiers.get(key, 1)), 1, 5)
	for key in MATERIALS: data.materials[key] = clampi(int(data.materials.get(key, 0)), 0, 1000000)
	return data
static func tier(game, key: String) -> int:
	return int(prepare(game).tiers.get(key, 1))
static func spec(game, key: String) -> Dictionary:
	var t = tier(game, key)
	var levels = {"gudang":[2,5,8,11], "dapur":[3,6,9,12], "rumah":[1,2,3,4], "roti":[1,1,1,1], "susu":[1,1,1,1]}
	return {"tier":t, "level":levels[key][mini(t-1,3)], "coins":100*t*t,
		"materials":{"batu":4*t,"kayu":5*t,"paku":2*t,"palu":t},
		"tasks":{"panen":6*t,"pengiriman":t,"produksi":t if key in ["dapur","roti","susu"] else 0},
		"storage":30 if key=="gudang" else 0}
static func start(game, key: String) -> bool:
	if not NAMES.has(key): return false
	var data = prepare(game)
	if tier(game,key)>=5 or data.missions.has(key) or game.level<int(spec(game,key).level): return false
	data.missions[key] = {"tier":tier(game,key),"baseline":game.achievement_progress.duplicate(true)}
	game.save_game()
	return true
static func progress(game, key: String, task: String) -> int:
	var mission: Dictionary = prepare(game).missions.get(key,{})
	return maxi(0,int(game.achievement_progress.get(task,0))-int(mission.get("baseline",{}).get(task,0))) if not mission.is_empty() else 0
static func ready(game, key: String) -> bool:
	if not NAMES.has(key): return false
	var data = prepare(game)
	var s = spec(game,key)
	var mission: Dictionary = data.missions.get(key,{})
	if mission.is_empty() or int(s.tier)>=5 or int(mission.get("tier",0))!=int(s.tier) or game.level<int(s.level) or game.coins<int(s.coins): return false
	for mat in s.materials:
		if int(data.materials[mat])<int(s.materials[mat]): return false
	for task in s.tasks:
		if progress(game,key,task)<int(s.tasks[task]): return false
	return true
static func claim(game, key: String) -> bool:
	if not ready(game,key): return false
	var data = prepare(game)
	var s = spec(game,key)
	game.coins-=int(s.coins)
	for mat in s.materials: data.materials[mat]=int(data.materials[mat])-int(s.materials[mat])
	data.tiers[key]=int(s.tier)+1
	data.missions.erase(key)
	game.storage_capacity+=int(s.storage)
	game.save_game()
	return true
static func delivery(game) -> void:
	var data = prepare(game)
	data.materials.paku=int(data.materials.paku)+1
static func wood(game) -> void:
	var data = prepare(game)
	data.materials.kayu=int(data.materials.kayu)+3
static func near_plot(system, at: Vector2) -> bool:
	for index in system.host.game.plots.size():
		if at.distance_to(system.farm.plot_center(index)) < 195.0: return true
	return false
static func boulder_clear(farm, at: Vector2, ignore_index: int=-1) -> bool:
	if not preload("res://scripts/reference_terrain.gd").asset_clear(at):return false
	var projection=preload("res://scripts/asset_projection.gd")
	var bounds=farm.farm_art.ground_bounds("resource_boulder",at,130.0).grow(20)
	if not preload("res://scripts/reference_terrain.gd").bounds_clear(bounds):return false
	if preload("res://scripts/four_seasons.gd").blocked(farm.game,at): return false
	if bounds.position.y<650 or not Rect2(Vector2.ZERO,farm.WORLD_SIZE).grow(-60).encloses(bounds): return false
	if not projection.region_sites_clear(farm,bounds): return false
	for key in farm.editable_keys():
		if preload("res://scripts/asset_edit.gd").special(key):continue
		var item=projection.info(farm,key,farm.settled_object_position(key))
		if not item.is_empty() and bounds.intersects(item.bounds.grow(20)): return false
		if key.begins_with("petak_"):
			var center=farm.settled_object_position(key)
			if bounds.intersects(Rect2(center-Vector2(110,90),Vector2(220,180))): return false
	for i in farm.WILD_TREES.size():
		if farm.wild_tree_active(i) and bounds.intersects(projection.wild_tree_bounds(farm,i).grow(15)): return false
	var nodes: Array=prepare(farm.game).nodes
	for i in nodes.size():
		if i==ignore_index: continue
		var other=Vector2(nodes[i].position[0],nodes[i].position[1])
		if bounds.intersects(farm.farm_art.ground_bounds("resource_boulder",other,130.0).grow(30)): return false
	return not farm.road_overlaps_rect(bounds)
static func setup_nodes(system) -> void:
	var data = prepare(system.host.game)
	if int(data.get("gathering_version",0)) < 3:
		data.nodes = []
		data.gathering_version = 3
	if data.nodes.is_empty():
		for at in [Vector2(650,1100),Vector2(1770,1330),Vector2(2250,1590),Vector2(2920,1850),Vector2(3550,2200),Vector2(3930,2800)]:
			data.nodes.append({"kind":"batu","position":[at.x,at.y],"ready_at":0})
	var changed=false
	for index in data.nodes.size():
		var node: Dictionary=data.nodes[index]
		var original=Vector2(node.position[0],node.position[1])
		if boulder_clear(system.farm,original,index): continue
		var found=false
		for radius in range(160,2561,160):
			if found: break
			for step in 24:
				var candidate=original+Vector2.from_angle(TAU*float(step)/24.0)*radius
				if not boulder_clear(system.farm,candidate,index): continue
				if not preload("res://scripts/reference_terrain.gd").dry_ground(candidate+Vector2(90,40)): continue
				node.position=[candidate.x,candidate.y]
				changed=true;found=true
				break
	if changed: system.navigation.revision=""
	system.host.game.save_game()
static func node_job(game, index: int) -> Dictionary:
	var nodes: Array = prepare(game).nodes
	if index<0 or index>=nodes.size(): return {}
	var node: Dictionary = nodes[index]
	return {"action":"gather","target":"resource","index":index,"position":node.position,"generation":int(node.ready_at),"resource_version":3}
static func boulder_at(farm, at: Vector2) -> int:
	var nodes: Array=prepare(farm.game).nodes
	for i in nodes.size():
		if str(nodes[i].get("kind",""))!="batu": continue
		var packed: Array=nodes[i].get("position",[])
		if packed.size()!=2: continue
		var center=Vector2(float(packed[0]),float(packed[1]))
		if farm.farm_art.ground_bounds("resource_boulder",center,130.0).grow(16).has_point(at): return i
	return -1
static func valid_node(game, job: Dictionary) -> bool:
	var nodes: Array = prepare(game).nodes
	var i = int(job.get("index",-1))
	return int(job.get("resource_version",0))==3 and i>=0 and i<nodes.size() and str(nodes[i].kind)=="batu" and nodes[i].position==job.get("position",[]) and int(nodes[i].ready_at)<=game.now() and int(nodes[i].ready_at)==int(job.get("generation",-1))
static func gather(game, job: Dictionary) -> bool:
	if not valid_node(game,job): return false
	var data = prepare(game)
	var node: Dictionary = data.nodes[int(job.index)]
	data.materials.batu=int(data.materials.batu)+3
	node.ready_at=game.now()+90
	game.save_game()
	return true
