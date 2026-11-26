extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	root.size = Vector2i(720,1280)
	var main = load("res://scenes/Main.tscn").instantiate()
	main.game.save_path = "user://visual_3d_test.json"
	main.game.backup_path = "user://visual_3d_test_backup.json"
	root.add_child(main)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/kebun-3d.png")
	var ui = main.get_children().filter(func(c): return c.get_script() == load("res://scripts/seasonal_ui.gd"))[0]
	ui.choose_character("female")
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/shop-3d.png")
	main.queue_free()
	await process_frame
	quit()
