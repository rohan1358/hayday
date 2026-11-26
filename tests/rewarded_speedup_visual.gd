extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://rewarded_speed_visual.json"
	host.game.backup_path="user://rewarded_speed_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.diamonds=0
	host.game.plots[0].crop=""
	host.game.plant(0,"gandum")
	host.game.plots[0].ready_at=host.game.now()+300
	host.farm.hybrid_controller.set_process(false)
	host.toast_layer.hide()
	host.refresh_all()
	host.on_plot_pressed(0)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/percepatan-iklan.png")
	host.queue_free()
	for i in 3: await process_frame
	preload("res://tests/admob_mock_cleanup.gd").release()
	await process_frame
	print("REWARDED SPEEDUP VISUAL PASS")
	quit()
