extends RefCounted

# One new wild tree per configured interval, up to the configured standing-tree limit.
# Save the next deadline in the active island so restarting cannot reset it.
const PLACEMENT_ATTEMPTS := 180
const ACCESS_CHECK_ATTEMPTS := 12
const TREE_CLEARANCE := 38.0
const SPAWN_AREA := Rect2(Vector2(280, 1550), Vector2(3720, 5380))


static func standing_count(farm) -> int:
	var count := 0
	var playable_area := Rect2(Vector2.ZERO, farm.WORLD_SIZE)
	for i in farm.WILD_TREES.size():
		if farm.wild_tree_active(i) and playable_area.has_point(farm.wild_tree_position(i)):
			count += 1
	return count


static func tick(host) -> bool:
	var game = host.game
	var farm = host.farm
	if game == null or farm == null:
		return false
	var next_at := int(game.building_upgrades.get("wild_tree_next_spawn_at", 0))
	if standing_count(farm) >= game.max_standing_trees:
		if next_at != 0:
			game.building_upgrades.wild_tree_next_spawn_at = 0
			game.save_game()
		return false
	var now: int = int(game.now())
	if next_at <= 0:
		game.building_upgrades.wild_tree_next_spawn_at = now + randi_range(game.wild_tree_spawn_min_seconds, game.wild_tree_spawn_max_seconds)
		game.save_game()
		return false
	if now < next_at:
		return false
	# A missed deadline spawns only one tree, even after a long offline period.
	game.building_upgrades.wild_tree_next_spawn_at = now + randi_range(game.wild_tree_spawn_min_seconds, game.wild_tree_spawn_max_seconds)
	var spawned := spawn_one(host)
	if spawned:
		farm.invalidate_scenery()
		farm.queue_redraw()
		if farm.hybrid_controller != null:
			farm.hybrid_controller.navigation.revision = ""
	game.save_game()
	return spawned


static func spawn_one(host) -> bool:
	var farm = host.farm
	var game = host.game
	if standing_count(farm) >= game.max_standing_trees:
		return false
	var slot := -1
	for i in range(farm.original_wild_tree_count, farm.WILD_TREES.size()):
		if not farm.wild_tree_active(i):
			slot = i
			break
	if slot < 0:
		return false

	var terrain = preload("res://scripts/reference_terrain.gd")
	var projection = preload("res://scripts/asset_projection.gd")
	var reserved: Array[Rect2] = []
	# Collect existing objects once, before selecting a position.
	for key in farm.editable_keys():
		if preload("res://scripts/asset_edit.gd").special(key):
			continue
		var at: Vector2 = farm.settled_object_position(key)
		var art: Dictionary = projection.info(farm, key, at)
		var half: Vector2 = farm.object_half_size(key)
		var ground := Rect2(at - half, half * 2.0)
		reserved.append(ground.merge(art["bounds"]) if art.has("bounds") else ground)
	# Every farm plot occupies land, including locked plots.
	for i in game.plots.size():
		var center: Vector2 = farm.plot_center(i)
		reserved.append(Rect2(center - Vector2(105, 87), Vector2(210, 174)))
	for node in game.building_upgrades.get("nodes", []):
		var position: Array = node.get("position", [])
		if position.size() != 2:
			continue
		var rock := Vector2(float(position[0]), float(position[1]))
		reserved.append(farm.farm_art.ground_bounds("resource_boulder", rock, 130.0))
	for i in farm.WILD_TREES.size():
		if farm.wild_tree_active(i):
			reserved.append(terrain.tree_bounds(farm.wild_tree_position(i), i))
	var roads: Array[Vector2] = []
	for road_id in game.road_tiles:
		var parts := str(road_id).split(",")
		if parts.size() != 2:
			continue
		roads.append(farm.road_visual_center(Vector2i(int(parts[0]), int(parts[1]))))

	var access_checks := 0
	for attempt in PLACEMENT_ATTEMPTS:
		var point := Vector2(randf_range(SPAWN_AREA.position.x, SPAWN_AREA.end.x), randf_range(SPAWN_AREA.position.y, SPAWN_AREA.end.y))
		var sprite: Rect2 = terrain.tree_bounds(point, slot)
		var safe := sprite.grow(TREE_CLEARANCE)
		if not SPAWN_AREA.has_point(point) or not Rect2(Vector2(140, 1270), Vector2(4040, 5830)).encloses(safe):
			continue
		if not terrain.asset_clear(point) or not terrain.bounds_clear(safe):
			continue
		var blocked := false
		for rect in reserved:
			if safe.intersects(rect):
				blocked = true
				break
		if blocked:
			continue
		for center in roads:
			if farm.road_segment_overlaps_rect(center, center, safe, farm.ROAD_HALF_WIDTH):
				blocked = true
				break
		if blocked or not projection.region_sites_clear(farm, safe):
			continue
		if not farm.scenery_clear_of_farm(point, safe):
			continue
		if point.distance_to(farm.ujang_position) < 170.0:
			continue
		access_checks += 1
		if not _can_reach_tree(farm, point):
			if access_checks >= ACCESS_CHECK_ATTEMPTS:
				break
			continue

		# Cleared regenerative slots can be reused without changing original IDs.
		var id := str(slot)
		game.cleared_wild_trees.erase(slot)
		for property in ["tree_positions", "hidden_trees", "manual_trees"]:
			var positions = game.building_upgrades.get(property, {})
			if positions is Dictionary:
				positions.erase(id)
		game.layout_positions.erase("wild_%d" % slot)
		preload("res://scripts/asset_edit.gd").state(game).erase("wild_%d" % slot)
		if not game.building_upgrades.has("regrown_wild_trees"):
			game.building_upgrades.regrown_wild_trees = {}
		game.building_upgrades.regrown_wild_trees[id] = [point.x, point.y]
		return true
	return false


static func _can_reach_tree(farm, point: Vector2) -> bool:
	var seasons = preload("res://scripts/four_seasons.gd")
	var navigator = farm.hybrid_controller.navigation if farm.hybrid_controller != null else null
	for offset in [Vector2(112, 0), Vector2(-112, 0), Vector2(0, 112), Vector2(0, -112), Vector2(106, 70), Vector2(-106, 70)]:
		var stand: Vector2 = point + offset
		if seasons.blocked(farm.game, stand) or farm.ujang_point_blocked(stand):
			continue
		if navigator == null or not navigator.path(farm.ujang_position, stand).is_empty():
			return true
	return false
