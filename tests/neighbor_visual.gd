extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://delivery_layout_visual.json"
	host.game.backup_path="user://delivery_layout_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.visitor_request=host.game.make_visitor_request()
	host.farm.hybrid_controller.data.follow=false
	host.farm.hybrid_controller.set_process(false)
	host.toast_layer.hide()
	host.farm.camera_zoom=2.4
	host.farm.camera_center=host.farm.visitor_world_position()+Vector2(0,-25)
	host.farm.camera_target=host.farm.camera_center
	host.refresh_all()
	host.farm.set_edit_mode(false)
	host.refresh_road_toolbar()
	for i in 18: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/tetangga-baru.png")
	host.queue_free();await process_frame
	print("NEIGHBOR VISUAL PASS")
	quit()
