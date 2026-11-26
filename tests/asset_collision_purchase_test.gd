extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var h=load("res://scenes/Main.tscn").instantiate()
	h.game.save_path="user://asset_collision_purchase.json";h.game.backup_path="user://asset_collision_purchase_backup.json"
	DirAccess.remove_absolute(h.game.save_path);DirAccess.remove_absolute(h.game.backup_path)
	root.add_child(h)
	h.game.ftue.started=true;h.game.ftue.step="done";h.game.level=20;h.game.coins=100000
	h.game.ftue.cow_built=true;h.game.ftue.coop_built=true
	h.game.constructions={"kandang_babi":1,"kandang_kambing":1,"toko_roti":1,"pabrik_susu":1,"pabrik_pakan":1}
	var nav=h.farm.hybrid_controller.navigation
	nav.ensure()
	for key in h.farm.editable_keys():
		if key.begins_with("road_") or key.begins_with("petak_"): continue
		assert(nav.blocked(h.farm.object_position(key)),"Asset ground must block movement: "+key)
	var safe=preload("res://scripts/safe_asset_placement.gd")
	for key in ["ayam","sapi","babi","kambing"]:
		var overlap=h.farm.object_position("starter_14")
		var at=safe.find(h.farm,key,overlap)
		assert(at!=Vector2.INF and at!=overlap and h.farm.can_place(key,at))
		assert(not nav.clear_segment(overlap-Vector2(80,0),overlap+Vector2(80,0)))
	for kind in h.game.DECORATION_ORDER:
		assert(h.farm.farm_art.sprites.has(kind),"Purchased decoration must have renderable art: "+kind)
		var key=h.game.buy_decoration(kind)
		assert(key!="" and h.game.stored_decoration_count(kind)>0)
		h.switch_tab("dekorasi")
		assert(h.sheet!=null)
		var at=safe.find(h.farm,key,Vector2(2400,1400))
		if at!=Vector2.INF:
			assert(h.game.set_decoration_position(key,at))
			assert(key in h.farm.editable_keys())
			assert(h.game.store_decoration(key))
	h.game.save_game()
	var copy=FarmGameState.new();copy.save_path=h.game.save_path;copy.backup_path=h.game.backup_path
	assert(copy.load_game() and copy.decorations.size()==h.game.decorations.size())
	h.queue_free();await process_frame
	print("ASSET COLLISION PURCHASE PASS: solid asset footprints, blocked cross-asset paths, clear livestock placement, every decoration renderable and owned after save/load")
	quit()
