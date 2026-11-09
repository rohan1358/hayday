extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.4).timeout
	# Unlock both optional paddocks only for this visual test.
	main.game.constructions["kandang_babi"] = 1
	main.game.constructions["kandang_kambing"] = 1
	main.call("switch_tab", "kebun")
	main.toast_layer.hide()
	var farm: FarmView = main.farm
	place_camera(farm, Vector2(560, 1450), 0.82)
	await create_timer(0.3).timeout
	var first := save_preview("res://build/livestock_pens_1.png")
	await create_timer(3.0).timeout
	var second := save_preview("res://build/livestock_pens_2.png")
	place_camera(farm, Vector2(1345, 455), 0.95)
	await create_timer(0.3).timeout
	var chicken := save_preview("res://build/livestock_chickens.png")
	quit(0 if first == OK and second == OK and chicken == OK else 1)


func place_camera(farm: FarmView, center: Vector2, zoom: float) -> void:
	farm.zoom_target = zoom
	farm.camera_zoom = zoom
	farm.camera_target = farm.clamp_camera_center(center, zoom)
	farm.camera_center = farm.camera_target
	farm.queue_redraw()


func save_preview(output: String) -> int:
	var image := root.get_viewport().get_texture().get_image()
	var result := image.save_png(output)
	print("LIVESTOCK PREVIEW: ", ProjectSettings.globalize_path(output), " status=", result)
	return result
