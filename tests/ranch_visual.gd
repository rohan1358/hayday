extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://ranch_visual.json"
	host.game.backup_path="user://ranch_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.level=10
	host.game.coins=5000
	host.farm.hybrid_controller.data.follow=false
	host.farm.hybrid_controller.set_process(false)
	var animator=host.farm.ranch_animator
	for species in ["ayam","sapi"]:
		host.game.ranch.pens[species].count=3
		animator.sync()
		host.farm.camera_zoom=1.8
		host.farm.camera_target=host.farm.object_position(species)+Vector2(0,35)
		host.farm.camera_center=host.farm.camera_target
		host.refresh_all()
		for i in 20: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/kandang-hidup-"+species+".png")
	host.switch_tab("ternak")
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/toko-hewan.png")
	print("RANCH VISUAL PASS")
	host.queue_free()
	await process_frame
	quit()
