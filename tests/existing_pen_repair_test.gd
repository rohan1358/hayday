extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://existing_pen_repair_test.json";host.game.backup_path="user://existing_pen_repair_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	var game=host.game
	game.ftue.started=true;game.ftue.step="done";game.level=3
	game.ftue.cow_built=true;game.ftue.erase("asset_overlap_repair")
	game.ranch.pens.sapi.count=2
	var old=host.farm.object_position("starter_14")
	game.layout_positions.sapi=[old.x,old.y]
	var money=game.coins
	var helper=preload("res://scripts/safe_asset_placement.gd")
	assert(not helper.clear(host.farm,"sapi",old))
	helper.repair_owned_pens(host)
	var moved=host.farm.object_position("sapi")
	assert(moved!=old and helper.clear(host.farm,"sapi",moved))
	assert(game.coins==money and game.ranch.pens.sapi.count==2)
	assert(game.ftue.asset_overlap_backup.sapi==[old.x,old.y])
	helper.repair_owned_pens(host)
	assert(host.farm.object_position("sapi")==moved)
	assert(not host.farm.hybrid_controller.navigation.blocked(host.farm.ujang_position))
	var copy=FarmGameState.new();copy.save_path=game.save_path;copy.backup_path=game.backup_path
	assert(copy.load_game() and copy.layout_positions.sapi==game.layout_positions.sapi)
	host.queue_free();await process_frame
	print("EXISTING PEN REPAIR PASS: tree overlap removed, original position backed up, animals/coins preserved, safe player position, idempotent save/load")
	quit()
