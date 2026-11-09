extends SceneTree

# Geometry and gesture regression. Uses in-memory state, never the player's save.
var failures := 0


func _initialize() -> void:
	call_deferred("run_test")


func check(ok: bool, description: String) -> void:
	if ok:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func world_to_screen(farm: FarmView, world_position: Vector2) -> Vector2:
	return (world_position - farm.camera_center) * farm.camera_zoom * farm.size / farm.get_virtual_size() + farm.size * 0.5


func run_test() -> void:
	var state := FarmGameState.new()
	state.new_game()
	var farm := FarmView.new()
	farm.game = state
	farm.size = Vector2(720, 780)
	root.add_child(farm)
	await process_frame
	farm.set_edit_mode(true)

	var plot_target := farm.object_position("petak_15") + Vector2(100, 55)
	check(farm.can_place("petak_4", plot_target), "Target isometric untuk petak kosong")
	check(farm.snap_edit_position("petak_4", plot_target + Vector2(9, -7)) == plot_target,
		"Petak tersnap ke pola isometrik petak lain")
	var free_target := Vector2(2183, 1757)
	check(farm.snap_edit_position("petak_4", free_target) == free_target,
		"Posisi jauh dari tetangga tetap bebas")

	var kitchen := farm.object_position("dapur")
	var building_target := Vector2(kitchen.x + farm.object_half_size("dapur").x +
		farm.object_half_size("gudang").x + FarmView.OBJECT_SNAP_GAP, kitchen.y)
	check(farm.can_place("gudang", building_target), "Target gudang berdampingan dapur valid")
	check(farm.snap_edit_position("gudang", building_target + Vector2(9, -9)) == building_target,
		"Bangunan tersnap ke sisi dan garis tengah bangunan lain")

	farm.layout_changed.connect(func(key: String, at: Vector2) -> void:
		state.layout_positions[key] = [at.x, at.y]
	)
	farm.begin_edit_drag(world_to_screen(farm, farm.object_position("gudang")))
	check(farm.drag_key == "gudang", "Gestur memilih gudang")
	farm.move_edit_drag(world_to_screen(farm, building_target + Vector2(9, -9)))
	check(farm.drag_preview == building_target and farm.drag_snapped,
		"Preview drag menunjukkan posisi snap")
	farm.finish_edit_drag()
	check(state.layout_positions.has("gudang") and farm.object_position("gudang") == building_target,
		"Lepas drag menyimpan posisi snap")
	check(farm.drag_key == "" and not farm.drag_snapped,
		"Status snap dibersihkan usai drag")

	# A player road must never be bypassed by magnetic alignment.
	var blocker := farm.road_cell_from_world(plot_target + Vector2(0, 30))
	state.road_tiles[farm.road_key(blocker)] = true
	var near_blocked := plot_target + Vector2(9, -7)
	check(not farm.can_place("petak_4", plot_target), "Jalan menutupi lokasi snap")
	check(farm.snap_edit_position("petak_4", near_blocked) != plot_target,
		"Snap tidak memilih target yang melanggar jalan")

	farm.queue_free()
	await process_frame
	print("OBJECT SNAPPING FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
