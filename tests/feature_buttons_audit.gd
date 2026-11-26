extends SceneTree
const RANCH=preload("res://scripts/ranch_state.gd")
func _initialize(): call_deferred("run")
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://feature_buttons_audit.json"
	host.game.backup_path="user://feature_buttons_audit_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	var game=host.game
	game.ftue.started=true
	game.ftue.step="done"
	game.level=1
	assert(not game.feature_unlocked("house"))
	game.level=2
	assert(game.feature_unlocked("house"))
	host.switch_tab("kebun")
	preload("res://scripts/first_farm_input.gd").tap(host.farm.hybrid_controller,host.farm.object_position("dapur"))
	assert(host.active_tab=="upgrade","House tap opens its upgrade page at Level 2")
	game.level=6
	game.coins=10000
	for tab in ["toko","gedung","gudang","upgrade","ternak","ayam","pakan","produksi","pesanan","misi","koleksi","pengaturan","jalan","dekorasi","rumput","bunga","pohon"]:
		host.switch_tab(tab)
		assert(host.active_tab==tab and host.sheet!=null,"Page must open: "+tab)
		print("PASS: page ",tab)
	host.set_meta("shop_category",2)
	host.switch_tab("toko")
	var buy: Button
	for node in host.sheet.find_children("*","Button",true,false):
		if node.name=="Buy_pen_sapi": buy=node;break
	assert(buy!=null and not buy.disabled)
	var coins=game.coins
	buy.pressed.emit()
	assert(game.coins==coins-200 and game.ftue.cow_built)
	assert(game.ranch.pens.sapi.count==0,"Barn purchase must not grant an unpurchased animal")
	assert(RANCH.buy(game,"sapi") and RANCH.count(game,"sapi")==1)
	assert("sapi" in host.farm.editable_keys() and "gudang" in host.farm.editable_keys())
	for pair in [["gudang","gudang"],["sapi","ternak"],["dapur","upgrade"]]:
		host.switch_tab("kebun")
		preload("res://scripts/first_farm_input.gd").tap(host.farm.hybrid_controller,host.farm.object_position(pair[0]))
		assert(host.active_tab==pair[1],"World object tap must open its feature: "+str(pair[0]))
	host.switch_tab("kebun")
	var nodes=preload("res://scripts/building_upgrades.gd").prepare(game).nodes
	assert(not nodes.is_empty())
	var rock=Vector2(nodes[0].position[0],nodes[0].position[1])
	preload("res://scripts/first_farm_input.gd").tap(host.farm.hybrid_controller,rock+Vector2(0,-40))
	assert(not host.farm.hybrid_controller.data.jobs.is_empty() and host.farm.hybrid_controller.data.jobs[0].action=="gather")
	if "--visual" in OS.get_cmdline_user_args():
		root.size=Vector2i(720,1280)
		var guide=preload("res://scripts/cheerful_menus.gd").guide(host)
		if guide!=null: guide.hide()
		for child in host.get_children():
			if child.get_script()==load("res://scripts/farm_progression.gd"):
				child.set_process(false)
				child.pending.clear()
				if child.dialog!=null: child.dialog.hide()
		host.toast_layer.hide()
		host.farm.camera_center=Vector2(1450,900)
		host.farm.camera_target=host.farm.camera_center
		host.farm.camera_zoom=0.65
		for frame in 6: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/audit-kebun-terbaru.png")
	game.save_game()
	var copy=FarmGameState.new()
	copy.save_path=game.save_path;copy.backup_path=game.backup_path
	assert(copy.load_game() and copy.ftue.cow_built and RANCH.count(copy,"sapi")==1)
	host.queue_free();await process_frame
	print("FEATURE BUTTON AUDIT PASS: 17 pages, actual cow-pen purchase, animal purchase, warehouse/house/cow taps, editability and persistence")
	quit()
