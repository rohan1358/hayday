extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	# Use an isolated save path so the visual preview cannot alter the player's save.
	main.game.save_path = "user://kebun_ceria_feedback_capture.json"
	main.game.backup_path = "user://kebun_ceria_feedback_capture_backup.json"
	root.add_child(main)
	await create_timer(0.35).timeout
	main.game.new_game()
	main.call("switch_tab", "kebun")
	main.toast_layer.hide()
	main.action_panel.hide()
	var farm: FarmView = main.farm
	farm.selected_plot = -1
	var crops := ["gandum", "jagung", "wortel", "tebu", "stroberi", "kedelai", "kentang", "labu"]
	var stages := [0.10, 0.33, 0.61, 0.88, 1.0, 0.57, 0.74, 0.95]
	var now: int = main.game.now()
	for index in crops.size():
		var plot: Dictionary = main.game.plots[index]
		plot["crop"] = crops[index]
		plot["planted_at"] = now - roundi(600.0 * stages[index])
		plot["ready_at"] = int(plot["planted_at"]) + 600
	set_camera(farm, Vector2(1140, 860), 1.04)
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	var stage_result := save_frame("res://build/p0_feedback_growth_stages.png")

	farm.show_plot_feedback(1, "plant")
	farm.show_plot_feedback(3, "harvest", 4)
	farm.show_world_feedback("move", farm.plot_center(5) + Vector2(-85, 45))
	await create_timer(0.18).timeout
	await RenderingServer.frame_post_draw
	var touch_result := save_frame("res://build/p0_feedback_touch_effects.png")

	farm.visual_feedback.clear()
	set_camera(farm, Vector2(2120, 910), 1.06)
	farm.show_world_feedback("target", FarmView.WILD_TREES[7])
	farm.show_world_feedback("chop_hit", FarmView.WILD_TREES[7] + Vector2(0, -33))
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var chop_result := save_frame("res://build/p0_feedback_chop.png")

	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://kebun_ceria_feedback_capture.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://kebun_ceria_feedback_capture_backup.json"))
	quit(0 if stage_result == OK and touch_result == OK and chop_result == OK else 1)


func set_camera(farm: FarmView, center: Vector2, zoom: float) -> void:
	farm.zoom_target = zoom
	farm.camera_zoom = zoom
	farm.camera_target = farm.clamp_camera_center(center, zoom)
	farm.camera_center = farm.camera_target
	farm.queue_redraw()


func save_frame(path: String) -> int:
	var frame := root.get_viewport().get_texture().get_image()
	var status := frame.save_png(path)
	print("FEEDBACK CAPTURE: ", ProjectSettings.globalize_path(path), " status=", status, " size=", frame.get_size())
	return status
