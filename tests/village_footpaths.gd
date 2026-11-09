extends SceneTree

# In-memory regression for replacing fixed village paths with editable dirt roads.
# Does not read or write the player's save file.
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

	check(state.road_tiles.is_empty(), "Fresh farms start without permanent roads")
	check(not farm.has_method("paint_village_footpaths") and
			not farm.has_method("paint_delivery_track"),
		"Old permanent-road renderers are absent")
	check(is_equal_approx(FarmView.ROAD_WIDTH, 75.0),
		"Editable roads use the former village path's 75-pixel width")
	check(not farm.road_overlaps_rect(Rect2(Vector2(865, 595), Vector2(12, 12))) and
			not farm.road_overlaps_rect(Rect2(Vector2(2050, 1340), Vector2(30, 30))),
		"Former village paths and truck route no longer block empty land")

	farm.set_edit_mode(true)
	farm.set_road_tool("draw")
	var first := Vector2i(27, 24)
	var second := first + Vector2i.RIGHT
	check(farm.can_paint_road(first) and farm.can_paint_road(second),
		"Adjacent customizable road cells are available")
	farm.paint_road_cell(first)
	farm.paint_road_cell(second)
	check(state.road_tiles.has(farm.road_key(first)) and
			state.road_tiles.has(farm.road_key(second)),
		"Players can paint a connected dirt road")
	var middle := (farm.road_visual_center(first) + farm.road_visual_center(second)) * 0.5
	check(farm.road_overlaps_rect(Rect2(middle - Vector2(4, 4), Vector2(8, 8))),
		"Painted road occupies ground between adjacent cells")

	farm.set_road_tool("erase")
	farm.paint_road_cell(first)
	farm.paint_road_cell(second)
	check(state.road_tiles.is_empty(), "Players can erase all created roads")
	check(not farm.road_overlaps_rect(Rect2(middle - Vector2(4, 4), Vector2(8, 8))),
		"Erasing roads immediately frees their ground")

	root.remove_child(farm)
	farm.free()
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
