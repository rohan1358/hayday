extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	var preview_game: FarmGameState = main.get("game")
	preview_game.save_path = "user://kebun_ceria_swipe_preview_only.json"
	preview_game.backup_path = "user://kebun_ceria_swipe_preview_only_backup.json"
	preview_game.new_game()
	root.add_child(main)
	await create_timer(0.6).timeout
	var toast: Control = main.get("toast_layer")
	toast.hide()
	var farm: FarmView = main.get("farm")
	var start_at := farm.plot_center(5)
	var end_at := farm.plot_center(6)
	var start_screen := (start_at - farm.camera_center) * farm.camera_zoom * farm.size / farm.get_virtual_size() + farm.size * 0.5
	var end_screen := (end_at - farm.camera_center) * farm.camera_zoom * farm.size / farm.get_virtual_size() + farm.size * 0.5
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = start_screen
	farm.handle_screen_touch(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = end_screen
	farm.handle_screen_drag(drag)
	await create_timer(0.15).timeout
	var path := "res://build/swipe_preview.png"
	var result := root.get_viewport().get_texture().get_image().save_png(path)
	print("SWIPE_PREVIEW: ", ProjectSettings.globalize_path(path), " result=", result, " selected=", farm.swipe_indices)
	farm.cancel_farm_swipe()
	main.queue_free()
	quit(0 if result == OK else 1)
