extends SceneTree
const P=preload("res://scripts/road_painter.gd")
const L=preload("res://scripts/cheerful_layout.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://starter_road_integrity_test.json"
	host.game.backup_path="user://starter_road_integrity_test_backup.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
	root.add_child(host)
	var ui=host.get_children().filter(func(node): return node.get_script()==load("res://scripts/first_farm_ui.gd"))[0]
	ui.start_adventure()
	var cells=P.cells_in_view(host.farm,Rect2(Vector2.ZERO,host.farm.WORLD_SIZE))
	for cell in L.ROUTE:
		assert(cells.has(cell),"Starter road tile must render: "+str(cell))
	if DisplayServer.get_name()!="headless":
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/jalan-awal-rapi.png"))
	print("STARTER ROAD PASS: %d / %d tiles render" % [cells.size(),L.ROUTE.size()])
	host.queue_free();await process_frame;quit()
