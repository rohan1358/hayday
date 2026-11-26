extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var main = load("res://scenes/Main.tscn").instantiate()
	main.game.save_path = "user://season_test.json"
	main.game.backup_path = "user://season_test_backup.json"
	DirAccess.remove_absolute(main.game.save_path)
	DirAccess.remove_absolute(main.game.backup_path)
	root.add_child(main)
	await process_frame
	var ui = main.get_node("SeasonalUI") if main.has_node("SeasonalUI") else main.get_children().filter(func(c): return c.get_script() == load("res://scripts/seasonal_ui.gd"))[0]
	main.game.coins = 400
	ui.open_shop()
	preload("res://scripts/seasonal_character_packs.gd").buy_and_equip(main.game,3)
	assert(main.game.coins == 285)
	preload("res://scripts/seasonal_character_packs.gd").buy_and_equip(main.game,3)
	assert(main.game.coins == 285)
	ui.buy("equipment", 3, 100)
	ui.preview(3)
	ui.claim()
	assert(main.game.coins == 200)
	ui.claim()
	assert(main.game.coins == 200)
	var saved = FarmGameState.new()
	saved.save_path = main.game.save_path
	saved.backup_path = main.game.backup_path
	assert(saved.load_game())
	assert(preload("res://scripts/seasonal_character_packs.gd").equipped(saved.seasonal) == 3)
	assert("equipment3" in saved.seasonal.owned)
	for i in 4:
		ui.preview(i)
		assert(ui.season == i)
	ui.choose_character("female")
	assert(main.game.seasonal.gender == "female")
	assert(saved.load_game())
	assert(saved.seasonal.gender == "female")
	ui.choose_character("male")
	assert(main.game.seasonal.gender == "male")
	print("SEASON TEST PASS: purchase, duplicate, equip, seasons, bonus, save/load")
	main.queue_free()
	await process_frame
	await process_frame
	quit()
