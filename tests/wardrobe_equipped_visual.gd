extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var main=load("res://scenes/Main.tscn").instantiate()
	main.game.save_path="user://wardrobe_visual.json"
	main.game.backup_path="user://wardrobe_visual_backup.json"
	root.add_child(main)
	var seasonal=main.get_children().filter(func(c): return c.get_script()==load("res://scripts/seasonal_ui.gd"))[0]
	var editor=seasonal.wardrobe_editor
	main.game.seasonal.gender="female"
	main.game.seasonal.outfit=-1
	main.game.seasonal.wardrobe_slots={}
	main.game.seasonal.wardrobe_slots=preload("res://scripts/wardrobe_catalog.gd").defaults(str(main.game.seasonal.get("gender","male")))
	editor.open()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/edit-karakter.png")
	editor.category="accessory"
	editor.rebuild()
	for i in 5: await process_frame
	editor.scroll.scroll_vertical=650
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/katalog-aksesori.png")
	editor.hide()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/karakter-di-kebun.png")
	main.queue_free()
	await process_frame
	quit()
