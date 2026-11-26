extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var main=load("res://scenes/Main.tscn").instantiate()
	main.game.save_path="user://hybrid_visual.json"
	main.game.backup_path="user://hybrid_visual_backup.json"
	DirAccess.remove_absolute(main.game.save_path)
	DirAccess.remove_absolute(main.game.backup_path)
	root.add_child(main)
	main.game.skip_onboarding()
	main.refresh_all()
	var system=main.farm.hybrid_controller
	for i in 25: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/hybrid-controls.png")
	system.ui.open_menu()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/hybrid-jobs.png")
	system.ui.change_section("animals")
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/hybrid-animals.png")
	system.ui.menu.hide()
	system.data.follow=false
	var cow=system.animals.animal("sapi_1")
	main.farm.camera_target=system.animals.position(cow)
	main.farm.camera_center=main.farm.camera_target
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/hybrid-pasture.png")
	# Exercise all action poses in real rendering rather than headless compilation.
	for action in ["walk","run","plant","water","fertilize","harvest","feed","drink","collect","milk","eggs","shear","clean","pet","herd","chop","sit"]:
		system.set_process(false)
		var pose={"activity":action,"direction":Vector2(-1,1),"clock":1.2,"phase":"action"}
		main.farm.set_meta("hybrid_pose",pose)
		if main.farm.mobile_ujang_layer!=null:
			main.farm.mobile_ujang_layer.set_meta("hybrid_pose",pose)
			main.farm.mobile_ujang_layer.queue_redraw()
		main.farm.queue_redraw()
		await process_frame
	print("HYBRID VISUAL PASS: UI, pasture and all action poses rendered")
	main.queue_free()
	await process_frame
	quit()
