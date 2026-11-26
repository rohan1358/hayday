extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://building_upgrade_visual.json"
	host.game.backup_path="user://building_upgrade_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.level=5
	host.game.coins=5000
	preload("res://scripts/building_upgrades.gd").start(host.game,"gudang")
	host.refresh_all()
	host.toast_layer.hide()
	host.switch_tab("upgrade")
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/misi-upgrade-bangunan.png")
	print("BUILDING VISUAL PASS")
	host.queue_free()
	await process_frame
	quit()
