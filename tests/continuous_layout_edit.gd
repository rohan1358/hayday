extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run_test")


func check(condition: bool, description: String) -> void:
	if condition:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func world_to_screen(farm: FarmView, world_position: Vector2) -> Vector2:
	return (world_position - farm.camera_center) * farm.camera_zoom * farm.size / farm.get_virtual_size() + farm.size * 0.5


func move_plot_by_touch(farm: FarmView, index: int, destination: Vector2) -> void:
	var start := world_to_screen(farm, farm.plot_center(index))
	var finish := world_to_screen(farm, destination)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = start
	touch.pressed = true
	farm.handle_screen_touch(touch)
	check(farm.drag_key == "petak_%d" % index, "sentuhan memilih petak %d" % index)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = finish
	farm.handle_screen_drag(drag)
	touch.position = finish
	touch.pressed = false
	farm.handle_screen_touch(touch)
	check(farm.drag_key == "" and farm.pointers.is_empty(), "sentuhan petak %d dilepas bersih" % index)
	check(farm.plot_center(index).distance_to(destination) < 2.0, "petak %d tersimpan di lokasi baru" % index)


func run_test() -> void:
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = "user://kebun_ceria_continuous_layout_test.json"
	screen.game.backup_path = "user://kebun_ceria_continuous_layout_backup.json"
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.game.skip_onboarding()
	screen.toggle_arrange_mode()
	var farm: FarmView = screen.farm
	check(farm.edit_mode and farm.road_tool == "object", "ATUR aktif dengan alat OBJEK")
	var scenery_destination := Vector2(1600, 1080)
	check(not farm.can_place("petak_4", scenery_destination),
		"petak tidak boleh menimpa dekorasi pemandangan")
	var first_destination := Vector2.ZERO
	for y in range(980, 1650, 110):
		for x in range(1350, 2050, 110):
			var candidate := Vector2(x, y)
			if farm.can_place("petak_4", candidate) and farm.snap_edit_position("petak_4", candidate) == candidate:
				first_destination = candidate
				break
		if first_destination != Vector2.ZERO:
			break
	check(first_destination != Vector2.ZERO, "tujuan petak pertama kosong")
	if first_destination != Vector2.ZERO:
		move_plot_by_touch(farm, 4, first_destination)
	check(farm.edit_mode and farm.edit_selected == "", "setelah petak pertama dilepas, ATUR tetap aktif dan seleksi dibersihkan")
	var toast: Panel = screen.toast_layer.get_child(screen.toast_layer.get_child_count() - 1) as Panel
	check(toast != null and toast.mouse_filter == Control.MOUSE_FILTER_IGNORE, "notifikasi penyimpanan tidak menghalangi sentuhan peta")
	var second_destination := Vector2.ZERO
	for y in range(980, 1650, 110):
		for x in range(1350, 2050, 110):
			var candidate := Vector2(x, y)
			if candidate.distance_to(first_destination) > 200.0 and \
					farm.can_place("petak_5", candidate) and farm.snap_edit_position("petak_5", candidate) == candidate:
				second_destination = candidate
				break
		if second_destination != Vector2.ZERO:
			break
	check(second_destination != Vector2.ZERO, "tujuan petak kedua tersedia")
	if second_destination != Vector2.ZERO:
		move_plot_by_touch(farm, 5, second_destination)
	check(farm.edit_mode and farm.edit_selected == "", "petak kedua bisa digeser tanpa menekan SELESAI")
	check(screen.game.layout_positions.has("petak_4") and screen.game.layout_positions.has("petak_5"), "kedua posisi disimpan selama satu sesi ATUR")
	var saved_game := FarmGameState.new()
	saved_game.save_path = screen.game.save_path
	saved_game.backup_path = screen.game.backup_path
	check(saved_game.load_game() and saved_game.layout_positions.has("petak_4") and saved_game.layout_positions.has("petak_5"), "perubahan kedua petak tetap ada setelah dimuat ulang")
	screen.queue_free()
	await process_frame
	print("CONTINUOUS LAYOUT FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
