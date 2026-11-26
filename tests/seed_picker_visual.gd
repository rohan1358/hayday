extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://seed_picker_visual.json"
	host.game.backup_path="user://seed_picker_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.level=4
	var system=host.farm.hybrid_controller
	system.set_process(false)
	system.ui.open_seed_picker(0)
	system.ui.select_seed("jagung")
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/pilih-bibit.png")
	print("SEED PICKER VISUAL PASS")
	host.queue_free()
	await process_frame
	quit()
