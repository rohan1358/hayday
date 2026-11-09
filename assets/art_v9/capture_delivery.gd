extends SceneTree

# Isolated visual QA. Never reads or writes the player's normal save paths.


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	main.game.save_path = "user://art_v9_delivery_fixture.json"
	main.game.backup_path = "user://art_v9_delivery_fixture_backup.json"
	root.add_child(main)
	await create_timer(0.45).timeout
	main.game.new_game()
	main.call("refresh_all")
	main.call("switch_tab", "kebun")
	main.toast_layer.hide()
	main.action_panel.hide()
	main.tutorial_panel.hide()

	var farm: FarmView = main.farm
	farm.selected_plot = -1
	farm.zoom_target = 1.38
	farm.camera_zoom = 1.38
	farm.camera_target = farm.clamp_camera_center(Vector2(1360, 1200), 1.38)
	farm.camera_center = farm.camera_target

	var successes := true
	for frame in [
		{"tag": "idle", "time": -1.0},
		{"tag": "outbound", "time": 0.45},
		{"tag": "returning", "time": 5.75},
		{"tag": "showcase", "time": -1.0, "zoom": 1.15, "center": Vector2(1230, 1160)},
	]:
		if frame.has("zoom"):
			farm.zoom_target = float(frame["zoom"])
			farm.camera_zoom = farm.zoom_target
			farm.camera_target = farm.clamp_camera_center(frame["center"], farm.camera_zoom)
			farm.camera_center = farm.camera_target
		farm.delivery_elapsed = float(frame["time"])
		farm.queue_redraw()
		await create_timer(0.18).timeout
		await RenderingServer.frame_post_draw
		var path: String = "res://assets/art_v9/world_delivery_%s.png" % frame["tag"]
		var screenshot := root.get_viewport().get_texture().get_image()
		var result := screenshot.save_png(path)
		print("ART_V9_CAPTURE ", ProjectSettings.globalize_path(path),
			" result=", result, " size=", screenshot.get_size(),
			" position=", farm.delivery_truck_position())
		successes = successes and result == OK

	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://art_v9_delivery_fixture.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://art_v9_delivery_fixture_backup.json"))
	quit(0 if successes else 1)
