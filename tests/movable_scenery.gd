extends SceneTree

# Regression for the existing illustrated map props, independent of the
# purchasable decorations catalog and the player's actual save.
const SAVE_TEST := "user://kebun_ceria_movable_scenery_test.json"
const BACKUP_TEST := "user://kebun_ceria_movable_scenery_backup.json"

var failures := 0


func _initialize() -> void:
	call_deferred("run_test")


func check(condition: bool, description: String) -> void:
	if condition:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func world_to_screen(farm: FarmView, at: Vector2) -> Vector2:
	return (at - farm.camera_center) * farm.camera_zoom * farm.size / farm.get_virtual_size() + farm.size * 0.5


func find_touchable_prop(farm: FarmView, kind: String) -> Dictionary:
	var keys := farm.editable_keys()
	for index in range(FarmView.MOVABLE_SCENERY.size() - 1, -1, -1):
		var info: Array = FarmView.MOVABLE_SCENERY[index]
		var key := "scenery_%d" % index
		if str(info[0]) != kind or not keys.has(key):
			continue
		var anchor := farm.object_position(key)
		var bounds := farm.farm_art.ground_bounds(kind, anchor, float(info[2]))
		for row in 9:
			for col in 9:
				var hit := bounds.position + bounds.size * Vector2((col + 0.5) / 9.0, (row + 0.5) / 9.0)
				if farm.editable_at(hit) == key:
					return {"key": key, "hit": hit, "original": anchor}
	return {}


func find_free_target(farm: FarmView, key: String, source: Vector2) -> Vector2:
	for y in range(1080, 2320, 105):
		for x in range(450, 2400, 105):
			var target := Vector2(x, y)
			if source.distance_to(target) < 340.0:
				continue
			if farm.can_place(key, target) and farm.snap_edit_position(key, target) == target:
				return target
	return Vector2.ZERO


func drag_prop(farm: FarmView, prop: Dictionary, destination: Vector2) -> bool:
	var key: String = prop["key"]
	var anchor: Vector2 = prop["original"]
	var hit: Vector2 = prop["hit"]
	var start := InputEventScreenTouch.new()
	start.index = 0
	start.pressed = true
	start.position = world_to_screen(farm, hit)
	farm.handle_screen_touch(start)
	check(farm.drag_key == key, "sentuhan memilih %s" % key)
	if farm.drag_key != key:
		start.pressed = false
		farm.handle_screen_touch(start)
		return false
	var finish := world_to_screen(farm, destination + hit - anchor)
	var swipe := InputEventScreenDrag.new()
	swipe.index = 0
	swipe.position = finish
	farm.handle_screen_drag(swipe)
	check(farm.drag_preview.distance_to(destination) < 2.0,
		"pratinjau %s mengikuti posisi tujuan" % key)
	start.position = finish
	start.pressed = false
	farm.handle_screen_touch(start)
	return farm.drag_key == "" and farm.object_position(key).distance_to(destination) < 2.0


func run_test() -> void:
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = SAVE_TEST
	screen.game.backup_path = BACKUP_TEST
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.game.skip_onboarding()
	screen.toggle_arrange_mode()
	var farm: FarmView = screen.farm
	check(farm.edit_mode and farm.road_tool == "object",
		"ATUR membuka mode pemindahan ilustrasi pemandangan")
	var visible_keys := farm.editable_keys()
	var count := 0
	for index in FarmView.MOVABLE_SCENERY.size():
		if visible_keys.has("scenery_%d" % index):
			count += 1
	check(count >= 15, "dekorasi bawaan peta mempunyai target sentuhan (jumlah %d)" % count)

	var moved: Dictionary = {}
	for kind in ["wishing_well", "arched_fence", "herb_drying_rack", "rainwater_collector", "flowering_bushes"]:
		var prop := find_touchable_prop(farm, kind)
		check(not prop.is_empty(), "objek %s dapat dipilih" % kind)
		if prop.is_empty():
			continue
		var key: String = prop["key"]
		var target := find_free_target(farm, key, prop["original"])
		check(target != Vector2.ZERO, "tersedia area kosong untuk %s" % kind)
		if target == Vector2.ZERO:
			continue
		check(drag_prop(farm, prop, target), "objek %s dipindahkan tanpa menutup ATUR" % kind)
		if farm.object_position(key).distance_to(target) < 2.0:
			moved[key] = target
		check(farm.edit_mode and farm.edit_selected == "", "ATUR tetap aktif setelah memindahkan %s" % kind)

	check(moved.size() == 5, "lima jenis dekorasi pemandangan berpindah")
	var saved := FarmGameState.new()
	saved.save_path = SAVE_TEST
	saved.backup_path = BACKUP_TEST
	var loaded := saved.load_game()
	check(loaded, "perubahan objek pemandangan disimpan ke disk")
	if loaded:
		for key in moved:
			var at: Vector2 = moved[key]
			check(saved.layout_positions.get(key, []) == [at.x, at.y],
				"posisi %s bertahan setelah load" % key)

	if not moved.is_empty():
		var selected: String = moved.keys()[0]
		var at: Vector2 = moved[selected]
		farm.begin_edit_drag(world_to_screen(farm, farm.object_position("petak_5")))
		check(not farm.can_place("petak_5", at),
			"petak yang sedang di-drag tidak dapat menimpa pemandangan")
		farm.cancel_edit_drag()
		var road_at := farm.road_visual_center(Vector2i(19, 19))
		screen.game.road_tiles[farm.road_key(Vector2i(19, 19))] = true
		check(not farm.can_place(selected, road_at), "jalan buatan pemain menghalangi dekorasi pemandangan")
		screen.game.road_tiles.erase(farm.road_key(Vector2i(19, 19)))

	screen.queue_free()
	await process_frame
	for path in [SAVE_TEST, BACKUP_TEST]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MOVABLE SCENERY FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
