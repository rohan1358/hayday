extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://colorful_world_visual.json"
	host.game.backup_path="user://colorful_world_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.level=20
	host.game.coins=24650
	host.game.diamonds=320
	host.game.constructions["toko_roti"]=1
	host.game.constructions["pabrik_susu"]=1
	host.game.constructions["pabrik_pakan"]=1
	host.farm.hybrid_controller.data.follow=false
	host.farm.hybrid_controller.set_process(false)
	host.farm.camera_zoom=1.35
	host.farm.camera_center=Vector2(700,680)
	host.farm.camera_target=host.farm.camera_center
	host.toast_layer.hide()
	host.refresh_all()
	for i in 25: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/colorful-kebun.png")
	host.switch_tab("upgrade")
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/colorful-menu.png")
	for tab in ["toko","gudang","ternak"]:
		if tab=="gudang":
			host.game.inventory.gandum=8
			host.game.inventory.roti=2
			host.game.inventory.telur=2
			host.game.inventory.susu=1
		host.switch_tab(tab)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/colorful-"+tab+".png")
	host.switch_tab("kebun")
	for node in host.get_children():
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("seasonal_ui.gd"): node.wardrobe_editor.open()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/colorful-karakter.png")
	print("COLORFUL VISUAL PASS")
	host.queue_free()
	await process_frame
	quit()
