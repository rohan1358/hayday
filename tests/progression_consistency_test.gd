extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://progression_consistency.json"
	host.game.backup_path="user://progression_consistency_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	var game=host.game
	game.ftue.started=true
	game.ftue.step="done"
	var positions=game.layout_positions.duplicate(true)
	var stock=game.road_tiles.duplicate(true)
	for level in range(1,7):
		game.level=level
		assert(preload("res://scripts/first_farm.gd").compact(game))
		assert(not preload("res://scripts/ranch_state.gd").available(game,"sapi"))
		assert(game.layout_positions==positions and game.road_tiles==stock)
	game.level=4
	game.xp=game.xp_target()-1
	game.award_xp(1)
	await process_frame
	await process_frame
	var progression=host.get_children().filter(func(n): return n.get_script()==load("res://scripts/farm_progression.gd"))[0]
	assert(progression.dialog!=null and progression.dialog.visible)
	progression.dialog.hide()
	host.switch_tab("gedung")
	assert(host.sheet!=null)
	game.ftue.cow_built=true
	assert(preload("res://scripts/ranch_state.gd").available(game,"sapi"))
	game.save_game()
	var copy=FarmGameState.new()
	copy.save_path=game.save_path
	copy.backup_path=game.backup_path
	assert(copy.load_game() and copy.ftue.cow_built)
	host.queue_free()
	await process_frame
	print("PROGRESSION CONSISTENCY PASS: stable world levels 1–6, no free cow pen, level-up dialog, shop and persistence")
	quit()
