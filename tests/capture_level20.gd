extends SceneTree

# Render a crop showcase in an isolated game; never load the player's save.


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	var game: FarmGameState = main.get("game")
	game.save_path = "user://pm_capture_level20_only.json"
	game.backup_path = "user://pm_capture_level20_only_backup.json"
	game.new_game()
	game.level = 20
	game.onboarding_step = 3
	var crops := ["tomat", "cabai", "kopi", "nanas"]
	for index in 8:
		var crop_id: String = crops[index % crops.size()]
		game.plots[index]["crop"] = crop_id
		game.plots[index]["planted_at"] = game.now() - int(FarmGameState.CROPS[crop_id]["grow"])
		game.plots[index]["ready_at"] = game.now() - 1
	root.add_child(main)
	await create_timer(0.45).timeout
	main.call("switch_tab", "kebun")
	main.toast_layer.hide()
	main.tutorial_panel.hide()
	var farm: FarmView = main.get("farm")
	var center := Vector2.ZERO
	for index in 8:
		center += farm.plot_center(index)
	center /= 8.0
	farm.zoom_target = 1.17
	farm.camera_zoom = farm.zoom_target
	farm.camera_target = farm.clamp_camera_center(center, farm.zoom_target)
	farm.camera_center = farm.camera_target
	farm.queue_redraw()
	await create_timer(0.65).timeout
	var output := "res://build/pm_level20_crops.png"
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(output)
	print("LEVEL20 VISUAL: ", ProjectSettings.globalize_path(output), " code=", error)
	quit(0 if error == OK else 1)
