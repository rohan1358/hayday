extends SceneTree

# End-to-end decoration ownership and touch layout regression. Uses its own save files.
const SAVE_TEST := "user://kebun_ceria_decorations_test.json"
const BACKUP_TEST := "user://kebun_ceria_decorations_test_backup.json"

var failures := 0


func _initialize() -> void:
	call_deferred("run_test")


func check(ok: bool, description: String) -> void:
	if ok:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func world_to_screen(farm: FarmView, at: Vector2) -> Vector2:
	return (at - farm.camera_center) * farm.camera_zoom * farm.size / farm.get_virtual_size() + farm.size * 0.5


func tap(farm: FarmView, at: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = world_to_screen(farm, at)
	touch.pressed = true
	farm.handle_screen_touch(touch)
	touch.pressed = false
	farm.handle_screen_touch(touch)


func run_test() -> void:
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = SAVE_TEST
	screen.game.backup_path = BACKUP_TEST
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.game.skip_onboarding()
	var state: FarmGameState = screen.game
	var farm: FarmView = screen.farm

	check(FarmGameState.DECORATION_ORDER.size() == 16, "Katalog 16 jenis dekorasi tersedia")
	var initial_coins := state.coins
	check(state.buy_decoration("jenis_tidak_valid") == "" and state.coins == initial_coins,
		"Jenis tidak dikenal tidak dapat dibeli")
	screen.switch_tab("bangun")
	check(screen.sheet != null, "Toko bangunan dan dekorasi dapat dibuka")
	screen.on_buy_decoration("wishing_well")
	var first_key := "dekor_1"
	check(state.coins == initial_coins - 140 and state.decoration_by_key(first_key).get("kind", "") == "wishing_well",
		"Beli satu sumur mengurangi koin sekali dan menambah koleksi")
	check(farm.edit_mode and farm.placement_decoration_key == first_key and screen.active_tab == "kebun",
		"Pembelian langsung membuka mode penempatan di kebun")
	check(state.stored_decoration_count("wishing_well") == 1,
		"Item yang belum dipasang tercatat sebagai dekorasi tersimpan")

	var target := Vector2(2100, 2050)
	check(farm.can_place(first_key, target), "Lokasi sumur berada di lahan yang valid")
	if farm.can_place(first_key, target):
		tap(farm, target)
	check(farm.placement_decoration_key == "" and state.decoration_by_key(first_key)["position"] == [target.x, target.y],
		"Sentuhan menempatkan sumur dan posisi disimpan")
	check(farm.editable_keys().has(first_key) and state.stored_decoration_count("wishing_well") == 0,
		"Dekorasi terpasang dapat dipilih di editor dan tidak dihitung sebagai stok")

	var next_target := Vector2(2450, 1990)
	check(farm.can_place(first_key, next_target), "Ada lokasi valid untuk memindahkan sumur")
	if farm.can_place(first_key, next_target):
		farm.begin_edit_drag(world_to_screen(farm, target))
		check(farm.drag_key == first_key, "Editor memilih dekorasi yang sudah terpasang")
		farm.move_edit_drag(world_to_screen(farm, next_target))
		farm.finish_edit_drag()
		check(farm.object_position(first_key).distance_to(next_target) < 2,
			"Dekorasi dapat dipindahkan dan posisi baru disimpan")

	var placed_at := farm.object_position(first_key)
	var saved := FarmGameState.new()
	saved.save_path = SAVE_TEST
	saved.backup_path = BACKUP_TEST
	check(saved.load_game() and saved.coins == state.coins and saved.decoration_by_key(first_key)["position"] == [placed_at.x, placed_at.y],
		"Posisi dan harga pembelian bertahan setelah memuat save")

	screen.switch_tab("bangun")
	screen.on_store_decoration(first_key)
	check(state.stored_decoration_count("wishing_well") == 1 and not farm.editable_keys().has(first_key),
		"SIMPAN menghapus dekorasi dari peta dan menambah stok tanpa menjualnya")
	var coins_before_reuse := state.coins
	screen.on_place_stored_decoration("wishing_well")
	check(farm.placement_decoration_key == first_key and state.coins == coins_before_reuse,
		"PASANG memakai koleksi yang sudah dibeli tanpa menarik koin lagi")
	screen.toggle_arrange_mode()
	check(farm.placement_decoration_key == "" and state.stored_decoration_count("wishing_well") == 1,
		"BATAL menjaga dekorasi tetap berada di koleksi")

	screen.on_buy_decoration("flower_patch")
	var second_key := "dekor_2"
	check(state.decoration_by_key(second_key).get("kind", "") == "flower_patch",
		"Pembelian berikutnya mendapatkan ID unik")
	var blocked := Vector2(2750, 2080)
	var cell := farm.road_cell_from_world(blocked)
	state.road_tiles[farm.road_key(cell)] = true
	check(not farm.can_place(second_key, blocked), "Jalan menolak penempatan dekorasi")
	if not farm.can_place(second_key, blocked):
		tap(farm, blocked)
	check(farm.placement_decoration_key == second_key and state.stored_decoration_count("flower_patch") == 1,
		"Gagal pasang di jalan mempertahankan mode penempatan dan stok")
	screen.toggle_arrange_mode()

	var restored := FarmGameState.new()
	restored.save_path = SAVE_TEST
	restored.backup_path = BACKUP_TEST
	check(restored.load_game() and restored.stored_decoration_count("wishing_well") == 1 and
		restored.stored_decoration_count("flower_patch") == 1 and restored.next_decoration_id == 3,
		"Koleksi dekorasi, status disimpan, dan urutan ID bertahan setelah restart")
	var legacy_data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_TEST))
	if legacy_data is Dictionary:
		legacy_data.erase("decorations")
		legacy_data.erase("next_decoration_id")
		var legacy_file := FileAccess.open(SAVE_TEST, FileAccess.WRITE)
		if legacy_file != null:
			legacy_file.store_string(JSON.stringify(legacy_data))
			legacy_file.close()
	var legacy := FarmGameState.new()
	legacy.save_path = SAVE_TEST
	legacy.backup_path = BACKUP_TEST
	check(legacy.load_game() and legacy.decorations.is_empty() and legacy.next_decoration_id == 1,
		"Save game lama tanpa data dekorasi tetap kompatibel")

	screen.queue_free()
	await process_frame
	for path in [SAVE_TEST, BACKUP_TEST]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("DECORATION FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
