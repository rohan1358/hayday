extends SceneTree


func _initialize() -> void:
	call_deferred("check_shop")


func check_shop() -> void:
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = "user://kebun_ceria_seed_shop_test.json"
	screen.game.backup_path = "user://kebun_ceria_seed_shop_test_backup.json"
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.call("switch_tab", "toko")
	await process_frame
	var missing: Array[String] = []
	var cramped: Array[String] = []
	for crop_id in FarmGameState.CROP_ORDER:
		var icon := screen.sheet.find_child("SeedIcon_" + crop_id, true, false) as TextureRect
		if icon == null or icon.texture == null or icon.texture.get_width() <= 0:
			missing.append(crop_id)
			continue
		for child in icon.get_parent().get_children():
			if child is Label and child.get_global_rect().position.x < icon.get_global_rect().end.x + 18.0:
				cramped.append(crop_id)
				break
	print("Seed shop icons loaded: %d/%d" % [FarmGameState.CROP_ORDER.size() - missing.size(), FarmGameState.CROP_ORDER.size()])
	if not missing.is_empty():
		printerr("Missing seed icons: ", ", ".join(missing))
	if not cramped.is_empty():
		printerr("Seed shop text too close to icons: ", ", ".join(cramped))
	screen.sheet_scroll.scroll_vertical = 550
	screen.toast_layer.hide()
	await create_timer(0.3).timeout
	var preview_result := root.get_viewport().get_texture().get_image().save_png("res://build/seed_shop_preview.png")
	print("Seed shop preview: ", preview_result)
	screen.queue_free()
	await process_frame
	quit(0 if missing.is_empty() and cramped.is_empty() and preview_result == OK else 1)
