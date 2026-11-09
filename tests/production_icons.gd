extends SceneTree


func _initialize() -> void:
	call_deferred("check_production_icons")


func check_production_icons() -> void:
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = "user://kebun_ceria_production_icons_test.json"
	screen.game.backup_path = "user://kebun_ceria_production_icons_test_backup.json"
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.call("switch_tab", "produksi")
	await process_frame
	var missing: Array[String] = []
	var cramped: Array[String] = []
	for product_id in FarmGameState.PRODUCT_ORDER:
		var icon := screen.sheet.find_child("ProductionIcon_" + product_id, true, false) as TextureRect
		if icon == null or icon.texture == null or icon.texture.get_width() <= 0:
			missing.append(product_id)
			continue
		for child in icon.get_parent().get_children():
			if child is Label and child.get_global_rect().position.x < icon.get_global_rect().end.x + 18.0:
				cramped.append(product_id)
				break
	print("Kitchen recipe icons loaded: %d/%d" % [FarmGameState.PRODUCT_ORDER.size() - missing.size(), FarmGameState.PRODUCT_ORDER.size()])
	if not missing.is_empty():
		printerr("Missing production icons: ", ", ".join(missing))
	if not cramped.is_empty():
		printerr("Kitchen recipe text too close to icons: ", ", ".join(cramped))
	screen.sheet_scroll.scroll_vertical = 390
	screen.toast_layer.hide()
	await create_timer(0.4).timeout
	var image: Image = root.get_viewport().get_texture().get_image()
	var preview_result := image.save_png("res://build/production_icons_preview.png") if image != null else ERR_UNAVAILABLE
	print("Kitchen preview: ", preview_result)
	screen.queue_free()
	await process_frame
	quit(0 if missing.is_empty() and cramped.is_empty() and preview_result == OK else 1)
