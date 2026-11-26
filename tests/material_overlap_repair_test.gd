extends SceneTree
const UP=preload("res://scripts/building_upgrades.gd")
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://material_overlap_repair_test.json"
	host.game.backup_path="user://material_overlap_repair_backup.json"
	var original=ProjectSettings.globalize_path("user://kebun_ceria_v1.json")
	if FileAccess.file_exists(original):
		DirAccess.copy_absolute(original,ProjectSettings.globalize_path(host.game.save_path))
	root.add_child(host)
	for node in host.get_children():
		if node.get_script()==load("res://scripts/farm_progression.gd"):
			node.set_process(false)
			if is_instance_valid(node.dialog): node.dialog.hide()
	host.set_meta("first_farm_modal",false)
	host.switch_tab("kebun")
	var system=host.farm.hybrid_controller
	system.set_process(false)
	system.data.follow=false
	var data=UP.prepare(host.game)
	assert(not data.nodes.is_empty())
	for i in data.nodes.size():
		var at=Vector2(data.nodes[i].position[0],data.nodes[i].position[1])
		assert(UP.boulder_clear(host.farm,at,i),"Saved boulders must clear roofs, trees, roads and fields")
	var projection=preload("res://scripts/asset_projection.gd")
	for key in ["dapur","delivery_depot","delivery_truck"]:
		if key not in host.farm.editable_keys(): continue
		var item=projection.info(host.farm,key,host.farm.object_position(key))
		assert(item.is_empty() or projection.nature_clear(host.farm,item.bounds),"Building must clear trees and boulders: "+key)
	var first=Vector2(data.nodes[0].position[0],data.nodes[0].position[1])
	assert(not host.farm.can_place("dapur",first),"A moved house cannot cover a boulder")
	var at=host.farm.object_position("delivery_depot")
	host.farm.camera_target=host.farm.clamp_camera_center(at+Vector2(0,-70),0.9)
	host.farm.camera_center=host.farm.camera_target
	host.farm.camera_zoom=0.9;host.farm.zoom_target=0.9
	for i in 20: await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/perbaikan-batu-rumah.png"))
	print("MATERIAL OVERLAP REPAIR PASS: saved farm, full artwork clearance, placement protection")
	host.queue_free();await process_frame;quit()
