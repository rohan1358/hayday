extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1200,1000)
	var preview=load("res://scenes/TerrainKitPreview.tscn").instantiate()
	root.add_child(preview)
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/terrain-kit-preview.png"))
	preview.zoom=2.0
	preview.offset=Vector2(-300,-120)
	preview.queue_redraw()
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/terrain-kit-zoom-2x.png"))
	print("TERRAIN KIT VISUAL PASS: nine materials, composite river and bridge, native 2x zoom capture")
	preview.queue_free();await process_frame;quit()
