extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	# Isolate test state from the player's regular save file.
	main.game.save_path = "user://programmer4_ui_capture.json"
	main.game.backup_path = "user://programmer4_ui_capture_backup.json"
	root.add_child(main)
	await create_timer(0.4).timeout
	main.game.new_game()
	main.call("refresh_all")
	main.call("switch_tab", "kebun")
	main.toast_layer.hide()
	main.action_panel.hide()
	main.farm.selected_plot = -1
	main.farm.zoom_target = 1.02
	main.farm.camera_zoom = 1.02
	main.farm.camera_target = main.farm.clamp_camera_center(Vector2(1310, 1050), 1.02)
	main.farm.camera_center = main.farm.camera_target
	main.farm.queue_redraw()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var farm_result := save_frame("res://build/programmer4_ui.png")

	# Exercise the real tab button signal before capturing the open sheet.
	var pesanan_tab: Panel = null
	for child in main.navbar.get_children():
		if child.has_meta("tab_id") and child.get_meta("tab_id") == "pesanan":
			pesanan_tab = child as Panel
			break
	if pesanan_tab == null:
		push_error("Tab PESANAN was not found")
		quit(1)
		return
	var tap_target := pesanan_tab.get_child(pesanan_tab.get_child_count() - 1) as Button
	if tap_target == null or tap_target.size.x < 120 or tap_target.size.y < 85:
		push_error("PESANAN tab tap target is missing or too small")
		quit(1)
		return
	tap_target.pressed.emit()
	if main.active_tab != "pesanan":
		push_error("PESANAN tab signal did not navigate")
		quit(1)
		return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var sheet_result := save_frame("res://build/programmer4_ui_sheet.png")

	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://programmer4_ui_capture.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://programmer4_ui_capture_backup.json"))
	quit(0 if farm_result == OK and sheet_result == OK else 1)


func save_frame(path: String) -> int:
	var frame := root.get_viewport().get_texture().get_image()
	var status := frame.save_png(path)
	print("PROGRAMMER4 UI: ", ProjectSettings.globalize_path(path), " status=", status, " size=", frame.get_size())
	return status
