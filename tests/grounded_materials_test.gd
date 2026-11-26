extends SceneTree
const UP=preload("res://scripts/building_upgrades.gd")
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://grounded_materials_test.json"
	host.game.backup_path="user://grounded_materials_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	var system=host.farm.hybrid_controller
	system.set_process(false)
	for node in host.get_children():
		if node.get_script()==load("res://scripts/farm_progression.gd"):
			node.set_process(false)
			if is_instance_valid(node.dialog): node.dialog.hide()
	host.game.ftue.started=true
	host.game.ftue.step="done"
	host.game.level=2
	var data=UP.prepare(host.game)
	data.materials.kayu=17
	data.nodes=[{"kind":"palu","position":[100,100],"ready_at":0},{"kind":"kayu","position":[200,150],"ready_at":0}]
	data.gathering_version=0
	UP.setup_nodes(system)
	assert(data.materials.kayu==17,"Migration preserves existing materials")
	assert(not data.nodes.is_empty())
	for node in data.nodes:
		assert(node.kind=="batu" and float(node.position[1])>=820)
	assert(not UP.valid_node(host.game,{"index":0,"generation":0}),"Old jobs cannot claim replacement nodes")
	assert(host.game.clear_wild_tree(0))
	assert(data.materials.kayu==20)
	assert(not host.game.clear_wild_tree(0))
	for child in host.get_children():
		if child.get_script()==load("res://scripts/first_farm_ui.gd"):
			if is_instance_valid(child.opening): child.opening.hide()
	host.set_meta("first_farm_modal",false)
	host.switch_tab("kebun")
	system.data.follow=false
	host.farm.camera_target=Vector2(data.nodes[0].position[0],data.nodes[0].position[1])
	host.farm.clamp_camera_target()
	host.farm.camera_center=host.farm.camera_target
	for i in 20: await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/bongkahan-di-tanah.png"))
	var job=UP.node_job(host.game,0)
	assert(UP.gather(host.game,job))
	assert(data.materials.batu==3 and int(data.nodes[0].ready_at)>host.game.now())
	assert(not UP.gather(host.game,job))
	print("GROUNDED MATERIALS PASS: old icons removed, stock preserved, tree wood, boulder stones, stale jobs rejected")
	host.queue_free()
	await process_frame
	quit()
