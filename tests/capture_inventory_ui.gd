extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	var preview_game: FarmGameState = screen.game
	preview_game.save_path = "user://kebun_ceria_inventory_preview_only.json"
	preview_game.backup_path = "user://kebun_ceria_inventory_preview_only_backup.json"
	root.add_child(screen)
	await create_timer(0.5).timeout
	preview_game.new_game()
	preview_game.inventory["gandum"] = 12
	preview_game.inventory["jagung"] = 8
	preview_game.inventory["wortel"] = 3
	screen.call("switch_tab", "gudang")
	screen.get("toast_layer").hide()
	await create_timer(0.55).timeout
	var image := root.get_viewport().get_texture().get_image()
	var result := image.save_png("res://build/inventory_ui_preview.png")
	print("INVENTORY PREVIEW: ", result, " ", image.get_size())
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(preview_game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(preview_game.backup_path))
	quit(0 if result == OK else 1)
