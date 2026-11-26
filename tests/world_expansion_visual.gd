extends SceneTree

const REGIONS = preload("res://scripts/world_regions.gd")

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	for i in 7:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../outputs/" + name + ".png")
	var result := root.get_texture().get_image().save_png(path)
	print("CAPTURE ", name, " status=", result, " path=", path)

func run() -> void:
	root.size = Vector2i(720, 1600)
	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://world_expansion_visual.json"
	host.game.backup_path="user://world_expansion_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.ftue.started=true
	host.game.ftue.step="done"
	host.game.level=18
	host.game.coins=15000
	var farm=host.farm
	for id in REGIONS.ORDER:
		if REGIONS.DATA[id].has("cost"):
			var at: Vector2 = REGIONS.DATA[id].position
			var found := false
			for radius in range(0,9):
				if found: break
				for dy in range(-radius,radius+1):
					if found: break
					for dx in range(-radius,radius+1):
						var candidate=at+Vector2(dx,dy)*80.0
						if farm.can_place("region_"+id,candidate):
							at=candidate
							found=true
							break
			assert(found,"No placement for "+id)
			assert(REGIONS.buy(host.game,id,at))
			print("PLACED ",id," ",at)
	for node in host.find_children("*","",true,false):
		if node.name=="NewPlayerWelcome": node.hide()
		if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
			node.set_process(false)
			if is_instance_valid(node.dialog): node.dialog.hide()
	host.set_meta("first_farm_modal",false)
	host.switch_tab("kebun")
	host.refresh_all()
	farm.hybrid_controller.data.follow=false
	farm.set_process(false)
	farm.invalidate_scenery()
	farm.camera_zoom=0.72
	farm.zoom_target=0.72
	farm.camera_target=farm.clamp_camera_center(Vector2(3100,1150),farm.camera_zoom)
	farm.camera_center=farm.camera_target
	farm.queue_redraw()
	await capture("world-expansion-east")
	farm.camera_target=farm.clamp_camera_center(Vector2(3100,2460),farm.camera_zoom)
	farm.camera_center=farm.camera_target
	farm.queue_redraw()
	await capture("world-expansion-south")
	host.switch_tab("kawasan")
	await capture("world-expansion-menu")
	print("WORLD_EXPANSION_VISUAL_DONE")
	host.queue_free()
	await process_frame
	quit()
