extends SceneTree

# Geometry regression using fresh in-memory gameplay only; never touch a save.
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(ok: bool, description: String) -> void:
	if ok:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func run_tests() -> void:
	var state := FarmGameState.new()
	state.new_game()
	var farm := FarmView.new()
	farm.game = state
	root.add_child(farm)
	await process_frame

	check(state.road_tiles.is_empty(), "A new farm has no prepainted roads")
	var default_clear := true
	for key in FarmView.OBJECT_DEFAULTS:
		var at: Vector2 = farm.default_position(String(key))
		var half: Vector2 = farm.object_half_size(String(key))
		if farm.road_overlaps_rect(Rect2(at - half, half * 2.0)):
			printerr("Road crosses default object: ", key)
			default_clear = false
	for index in state.plots.size():
		var at := farm.default_position("petak_%d" % index)
		var half := farm.object_half_size("petak_%d" % index)
		if farm.road_overlaps_rect(Rect2(at - half, half * 2.0)):
			printerr("Road crosses default plot: ", index)
			default_clear = false
	check(default_clear, "No permanent road occupies a default building or plot")

	check(not farm.road_overlaps_rect(Rect2(Vector2(865, 595), Vector2(12, 12))),
		"The former village path no longer blocks land")
	check(not farm.road_overlaps_rect(Rect2(Vector2(2050, 1340), Vector2(30, 30))),
		"The former delivery track no longer blocks land")
	check(farm.can_paint_road(farm.road_cell_from_world(Vector2(865, 595))),
		"Players can pave over the former village footpath")
	check(farm.can_paint_road(farm.road_cell_from_world(Vector2(2050, 1340))),
		"Players can pave over the former delivery track")
	check(farm.can_place("roti", Vector2(2100, 2050)),
		"Dragging a building onto empty grass is still allowed")

	var clear_cell := Vector2i(27, 24)
	check(farm.can_paint_road(clear_cell), "Road can be painted on unobstructed ground")
	state.road_tiles[farm.road_key(clear_cell)] = true
	var road_at := farm.road_visual_center(clear_cell)
	check(not farm.can_place("roti", road_at),
		"Player-created road protects its full surface from new object placements")
	check(farm.road_overlaps_rect(Rect2(road_at - Vector2(40, 8), Vector2(12, 16))),
		"Player road footprint matches the full 75-pixel dirt trail")
	check(not farm.can_paint_road(farm.road_cell_from_world(farm.object_position("dapur"))),
		"New roads cannot be painted beneath an existing building")
	check(not farm.can_paint_road(farm.road_cell_from_world(farm.plot_center(0))),
		"New roads cannot be painted through crop plots")

	var sprite_bounds := farm.farm_art.ground_bounds("wooden_crates", Vector2(900, 900), 150.0)
	check(sprite_bounds.has_area() and sprite_bounds.size.x >= 149.0,
		"Decor uses the full nontransparent sprite bounds")
	check(not farm.scenery_clear_of_farm(road_at + Vector2(220, 0),
			Rect2(road_at - Vector2(45, 25), Vector2(70, 50))),
		"Road under a sprite edge is rejected even when its anchor is distant")
	check(farm.scenery_clear_of_farm(Vector2(2100, 2050),
			Rect2(2060, 1980, 80, 80)),
		"Decorations may still appear where there are no roads or farm objects")

	var existing_layout := state.layout_positions.duplicate(true)
	var existing_roads := state.road_tiles.duplicate(true)
	farm.can_place("roti", road_at)
	farm.can_paint_road(clear_cell)
	check(state.layout_positions == existing_layout and state.road_tiles == existing_roads,
		"Geometry checks do not modify existing save data")

	root.remove_child(farm)
	farm.free()
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
