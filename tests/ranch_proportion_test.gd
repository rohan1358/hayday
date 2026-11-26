extends SceneTree
const R=preload("res://scripts/ranch_state.gd")
func _initialize(): call_deferred("run")
func run():
	var h=load("res://scenes/Main.tscn").instantiate()
	h.game.save_path="user://ranch_proportion_test.json";h.game.backup_path="user://ranch_proportion_backup.json"
	DirAccess.remove_absolute(h.game.save_path);DirAccess.remove_absolute(h.game.backup_path)
	root.add_child(h)
	var game=h.game
	game.ftue.started=true;game.ftue.step="done";game.ftue.coop_built=true;game.ftue.cow_built=true
	game.level=10;game.constructions={"kandang_babi":1,"kandang_kambing":1}
	var a=h.farm.ranch_animator
	for species in R.SPECIES:
		game.ranch.pens[species]={"tier":1,"count":2}
		var info=R.INFO[species]
		assert(is_equal_approx(h.farm.farm_art.ranch_width(info.asset,17),R.pen_width(game,species)),"Drawing uses the shared pen width")
		var before=h.farm.object_half_size(species)
		game.ranch.pens[species].tier=2
		assert(h.farm.object_half_size(species).x>before.x)
		game.ranch.pens[species].tier=1
		var animal_width=R.animal_width(species)
		assert(animal_width<R.pen_width(game,species)*0.3)
		for i in 20: assert(a.allowed(species,a.free_spawn(species)))
	assert(R.animal_width("sapi")>R.animal_width("ayam")*3.5)
	assert(R.animal_width("sapi")>R.animal_width("babi") and R.animal_width("babi")>R.animal_width("ayam"))
	h.farm.camera_center=Vector2(1800,1400);h.farm.camera_zoom=0.2
	a.sync();a.tick(0.1)
	for animal in a.agents.values():
		var width=animal.node.texture.get_width()*absf(animal.node.scale.x)/h.farm.camera_zoom/(h.farm.size.x/h.farm.get_virtual_size().x)
		assert(absf(width-R.animal_width(animal.species))<0.1)
	if "--visual" in OS.get_cmdline_user_args():
		root.size=Vector2i(900,1350)
		h.layout_direction=Control.LAYOUT_DIRECTION_LTR
		game.layout_positions.merge({"dapur":[900,500],"ayam":[1450,550],"sapi":[1450,1050],"babi":[850,1100],"kambing":[1150,1550],"gudang":[2400,2000],"buah_0":[2400,2200]},true)
		for i in 17: game.layout_positions["starter_%d"%i]=[3000,2800]
		for plot in game.plots: plot.unlocked=false
		game.road_tiles.clear();game.visitor_request.clear()
		h.farm.ujang_position=Vector2(1110,700);h.farm.hybrid_controller.data.follow=false
		h.farm.hybrid_controller.set_process(false)
		var guide=preload("res://scripts/cheerful_menus.gd").guide(h)
		if guide!=null: guide.hide()
		for child in h.get_children():
			if child.get_script()==load("res://scripts/farm_progression.gd"): child.set_process(false)
		h.toast_layer.hide()
		h.farm.camera_center=Vector2(1150,1050);h.farm.camera_target=h.farm.camera_center
		h.farm.camera_zoom=0.72;h.farm.zoom_target=0.72
		h.farm.invalidate_scenery()
		for frame in 30: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/perbandingan-kandang-hewan.png")
	h.queue_free();await process_frame
	print("RANCH PROPORTION PASS: consistent pen drawing/collision, upgraded areas, valid spawn margins, eight live animal widths and species proportions")
	quit()
