extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	# Keep test construction unlocks and autosaves isolated from the actual player.
	main.game.save_path = "user://programmer4_livestock_test.json"
	main.game.backup_path = "user://programmer4_livestock_test_backup.json"
	root.add_child(main)
	await create_timer(0.4).timeout
	main.game.new_game()
	main.game.constructions["kandang_babi"] = 1
	main.game.constructions["kandang_kambing"] = 1
	main.call("refresh_all")
	main.call("switch_tab", "kebun")
	main.toast_layer.hide()
	main.action_panel.hide()
	var farm: FarmView = main.farm
	farm.selected_plot = -1

	set_camera(farm, Vector2(555, 1450), 1.15)
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var cow_result := save_frame("user://programmer4_livestock_cow_pig.png")

	set_camera(farm, Vector2(700, 1635), 1.28)
	await create_timer(2.15).timeout
	await RenderingServer.frame_post_draw
	var goat_result := save_frame("user://programmer4_livestock_goat.png")

	set_camera(farm, Vector2(1355, 400), 1.20)
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	var chicken_result := save_frame("user://programmer4_livestock_chicken.png")

	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://programmer4_livestock_test.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://programmer4_livestock_test_backup.json"))
	quit(0 if cow_result == OK and goat_result == OK and chicken_result == OK else 1)


func set_camera(farm: FarmView, center: Vector2, zoom: float) -> void:
	farm.zoom_target = zoom
	farm.camera_zoom = zoom
	farm.camera_target = farm.clamp_camera_center(center, zoom)
	farm.camera_center = farm.camera_target
	farm.queue_redraw()


func save_frame(path: String) -> int:
	var frame := root.get_viewport().get_texture().get_image()
	var status := frame.save_png(path)
	print("PROGRAMMER4 LIVESTOCK: ", ProjectSettings.globalize_path(path),
		" status=", status, " size=", frame.get_size())
	return status
