extends SceneTree
const R=preload("res://scripts/road_catalog.gd")
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://roads_visual.json"
	host.game.backup_path="user://roads_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.new_game(false)
	var guide=preload("res://scripts/cheerful_menus.gd").guide(host)
	if guide!=null: guide.hide()
	host.game.skip_onboarding()
	host.game.coins=1000
	host.game.level=20
	for id in R.ORDER: R.buy(host.game,id,10)
	host.farm.hybrid_controller.data.follow=false
	host.farm.hybrid_controller.set_process(false)
	host.toast_layer.hide()
	host.refresh_all()
	host.switch_tab("jalan")
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/toko-jalan.png")
	host.switch_tab("kebun")
	var row=0
	for id in R.ORDER:
		host.game.road_inventory.selected=id
		for x in range(27,33):
			var cell=Vector2i(x,16+row*2)
			if host.farm.can_paint_road(cell): R.place(host.game,host.farm.road_key(cell))
		row+=1
	host.farm.invalidate_scenery()
	host.farm.camera_center=Vector2(2400,1480)
	host.farm.camera_target=host.farm.camera_center
	host.farm.camera_zoom=1.8
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/tiga-varian-jalan.png")
	host.queue_free();await process_frame
	print("THREE ROAD VARIANTS VISUAL PASS")
	quit()
