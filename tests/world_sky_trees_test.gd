extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = "user://world_sky_trees_test.json"
	host.game.backup_path = "user://world_sky_trees_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	for i in 4: await process_frame
	var opening = host.find_child("NewPlayerWelcome", true, false)
	assert(opening != null)
	for node in host.get_children():
		if node.get_script() == load("res://scripts/first_farm_ui.gd"):
			node.start_adventure()
			break
	for i in 3: await process_frame
	assert(host.find_child("HeaderLandscape", true, false) == null)
	assert(host.find_child("CheerfulHeader", true, false) != null)
	assert(host.farm.WILD_TREES.size() >= 40)
	for tree in host.farm.WILD_TREES:
		assert(tree.y >= preload("res://scripts/world_sky.gd").WILD_TREE_MIN_Y,
			"The whole wild tree must remain below the sky transition")
		assert(Rect2(Vector2.ZERO, host.farm.WORLD_SIZE).grow(-50).has_point(tree))
	assert(host.game.seeds.gandum == 3)
	for i in 3: assert(host.game.plots[i].unlocked)
	assert(not host.game.plots[3].unlocked)
	assert(not host.game.feature_unlocked("ranch"))
	assert(not host.game.feature_unlocked("expansion"))
	var tree_id = host.farm.WILD_TREES.size() - 8
	var tree_at: Vector2 = host.farm.WILD_TREES[tree_id]
	assert(host.farm.wild_tree_at(tree_at + Vector2(0, -35)) == tree_id)
	var materials = preload("res://scripts/building_upgrades.gd").prepare(host.game).materials
	var wood_before = int(materials.kayu)
	var coins_before = host.game.coins
	assert(host.farm.start_chopping(tree_id))
	host.farm.chopping_tree = -1
	host.farm.wild_tree_chopped.emit(tree_id)
	assert(host.game.cleared_wild_trees.has(tree_id))
	assert(int(materials.kayu) == wood_before + 3)
	assert(host.game.coins == coins_before + 6)
	assert(host.farm.wild_tree_at(tree_at + Vector2(0, -35)) == -1)
	print("WORLD SKY AND TREES PASS: transparent HUD, starter plots, level locks, choppable trees, wood reward")
	host.queue_free()
	await process_frame
	quit()
