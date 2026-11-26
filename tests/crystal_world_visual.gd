extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var main=load("res://scenes/Main.tscn").instantiate()
	main.game.save_path="user://crystal_visual.json"
	main.game.backup_path="user://crystal_visual_backup.json"
	DirAccess.remove_absolute(main.game.save_path)
	DirAccess.remove_absolute(main.game.backup_path)
	root.add_child(main)
	main.game.skip_onboarding()
	main.game.level=20
	var fractions=[0.08,0.35,0.72,1.05]
	for i in 4:
		var planted=main.game.now()-int(420*fractions[i])
		main.game.plots[i]={"crop":"stroberi_kristal","planted_at":planted,"ready_at":planted+420,"unlocked":true}
	main.farm.hybrid_controller.data.follow=false
	main.farm.hybrid_controller.set_process(false)
	main.farm.camera_target=(main.farm.plot_center(0)+main.farm.plot_center(3))*0.5
	main.farm.camera_center=main.farm.camera_target
	main.farm.camera_zoom=1.05
	main.refresh_all()
	for i in 30: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/stroberi-kristal-dalam-game.png")
	print("CRYSTAL WORLD VISUAL PASS: four stages rendered on existing farm plots, isolated Lv20 preview save")
	main.queue_free()
	await process_frame
	quit()
