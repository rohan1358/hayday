extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	# Dedicated sandbox save: never touch the player's current progress.
	main.game.save_path = "user://feed_mill_capture_test.json"
	main.game.backup_path = "user://feed_mill_capture_test_backup.json"
	root.add_child(main)
	await create_timer(0.4).timeout
	main.game.new_game()
	main.call("refresh_all")
	main.call("switch_tab", "pakan")
	main.toast_layer.hide()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var locked_result := save_frame("res://build/feed_mill_locked.png")

	main.game.level = 3
	main.game.coins = 600
	main.game.storage_capacity = 120
	if not main.game.buy_construction("pabrik_pakan"):
		push_error("Failed to build feed mill in capture fixture")
		cleanup(main)
		quit(1)
		return
	for ingredient in ["gandum", "jagung", "kedelai", "wortel"]:
		main.game.inventory[ingredient] = 20
	main.call("refresh_all")
	main.call("switch_tab", "pakan")
	main.toast_layer.hide()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var idle_result := save_frame("res://build/feed_mill_idle.png")

	if not main.game.queue_feed("pakan_sapi") or not main.game.queue_feed("pakan_babi"):
		push_error("Failed to enqueue feed in capture fixture")
		cleanup(main)
		quit(1)
		return
	main.game.feed_queue[0]["ready_at"] = main.game.now() - 1
	main.call("switch_tab", "pakan")
	main.toast_layer.hide()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var ready_result := save_frame("res://build/feed_mill_ready.png")

	main.call("switch_tab", "kebun")
	main.tutorial_panel.hide()
	main.toast_layer.hide()
	main.action_panel.hide()
	main.farm.zoom_target = 1.25
	main.farm.camera_zoom = 1.25
	main.farm.camera_target = main.farm.clamp_camera_center(Vector2(2110, 1150), 1.25)
	main.farm.camera_center = main.farm.camera_target
	main.farm.queue_redraw()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var world_result := save_frame("res://build/feed_mill_world.png")

	cleanup(main)
	quit(0 if [locked_result, idle_result, ready_result, world_result].all(func(result: int) -> bool: return result == OK) else 1)


func cleanup(main: Control) -> void:
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://feed_mill_capture_test.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://feed_mill_capture_test_backup.json"))


func save_frame(path: String) -> int:
	var screenshot := root.get_viewport().get_texture().get_image()
	var status := screenshot.save_png(path)
	print("FEED MILL CAPTURE: ", ProjectSettings.globalize_path(path), " status=", status, " size=", screenshot.get_size())
	return status
