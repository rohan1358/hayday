extends SceneTree
const SAFE=preload("res://scripts/safe_asset_placement.gd")
const PROJECTION=preload("res://scripts/asset_projection.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://production_buildings_test.json"
	host.game.backup_path="user://production_buildings_test_backup.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
	root.add_child(host)
	for child in host.get_children():
		if child.get_script()==load("res://scripts/first_farm_ui.gd"):
			child.opening.hide()
		if child.get_script()==load("res://scripts/farm_progression.gd"):
			child.set_process(false)
			child.pending.clear()
			if child.dialog!=null: child.dialog.hide()
	host.set_meta("first_farm_modal",false)
	var game=host.game
	game.ftue.started=true;game.ftue.step="done";game.level=6;game.coins=10000
	game.ftue.cow_built=true
	var cow_site=SAFE.find(host.farm,"sapi",Vector2(2050,1150))
	assert(cow_site!=Vector2.INF)
	game.layout_positions["sapi"]=[cow_site.x,cow_site.y]
	assert(not game.has_construction("toko_roti"))
	for pair in [["toko_roti","roti"],["pabrik_susu","susu"],["pabrik_pakan","pakan"]]:
		host.on_buy_construction(pair[0])
		assert(game.has_construction(pair[0]),"Building must be purchasable: "+pair[0])
		var art=PROJECTION.info(host.farm,pair[1],host.farm.object_position(pair[1]))
		assert(art.width>=265.0,"Production building must match house scale")
		assert(SAFE.clear(host.farm,pair[1],host.farm.object_position(pair[1])),"Production building must have clear land")
	# Older saves may contain a bakery at the cow pen. Migration must move it.
	var cow_before=host.farm.object_position("sapi")
	game.layout_positions["roti"]=game.layout_positions["sapi"].duplicate()
	game.ftue.asset_overlap_repair=4
	SAFE.repair_owned_pens(host)
	var cow=PROJECTION.info(host.farm,"sapi",host.farm.object_position("sapi"))
	var bakery=PROJECTION.info(host.farm,"roti",host.farm.object_position("roti"))
	assert(not cow.bounds.intersects(bakery.bounds),"Legacy bakery must move clear of cow pen")
	assert(host.farm.object_position("sapi")==cow_before,"Existing cow pen must keep its saved position")
	assert(int(game.ftue.asset_overlap_repair)==5)
	if DisplayServer.get_name()!="headless":
		host.switch_tab("kebun")
		var target=host.farm.object_position("roti").lerp(host.farm.object_position("susu"),0.5)
		host.farm.camera_zoom=0.85;host.farm.zoom_target=0.85
		host.farm.camera_center=host.farm.clamp_camera_center(target,0.85)
		host.farm.camera_target=host.farm.camera_center
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/bangunan-produksi-rapi.png"))
	for pair in [["roti","Toko Roti","ProductionIcon_roti","ProductionIcon_keju"],["susu","Pabrik Susu","ProductionIcon_keju","ProductionIcon_roti"]]:
		host.switch_tab("kebun")
		preload("res://scripts/first_farm_input.gd").tap(host.farm.hybrid_controller,host.farm.object_position(pair[0])+Vector2(0,-40))
		assert(host.active_tab==pair[0],"Tap must open dedicated page: "+pair[0])
		assert(host.sheet.find_child("MenuTitle",true,false).text==pair[1])
		assert(host.sheet.find_child(pair[2],true,false)!=null,"Own recipes visible")
		assert(host.sheet.find_child(pair[3],true,false)==null,"Other building recipes hidden")
	print("PRODUCTION BUILDINGS PASS: clear placement, saved overlap repair, sizes and dedicated recipe pages")
	host.queue_free();await process_frame;quit()
