extends SceneTree

var failures := 0


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game := FarmGameState.new(false)
	game.cash_reward_real_device = true
	game.cash_reward_allow_all_regions = true
	game.save_path = "user://wild_tree_cooldown_test.json"
	game.backup_path = "user://wild_tree_cooldown_test_backup.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.backup_path))

	check(game.clear_wild_tree(0), "first tree can be chopped")
	check(game.wild_tree_next_chop_at == 0 and not game.wild_tree_chop_cooling_down(), "first free chop sets no cooldown")
	game.wild_tree_next_chop_at = int(Time.get_unix_time_from_system()) + 90
	check(not game.wild_tree_chop_cooling_down(), "old saved cooldown does not block remaining free chops")
	check(game.clear_wild_tree(1) and game.clear_wild_tree(2), "second and third free chops work immediately")
	check(game.wild_tree_chops_today == 3 and game.cash_reward_chops_today == 3, "all three free chops are counted")
	check(not game.wild_tree_chop_cooling_down() and game.wild_tree_next_chop_at == 0, "fourth tree can offer an ad immediately")
	check(not game.clear_wild_tree(3), "fourth tree requires a bonus credit")
	game.grant_wild_tree_bonus_chop()
	var start_at := int(Time.get_unix_time_from_system())
	check(game.clear_wild_tree(3), "first bonus chop works immediately")
	check(game.wild_tree_next_chop_at >= start_at + 60 and game.wild_tree_next_chop_at <= start_at + 120,
		"bonus chop sets a random cooldown of 60-120 seconds")
	game.grant_wild_tree_bonus_chop()
	check(not game.clear_wild_tree(4) and game.wild_tree_bonus_chops == 1 and game.cash_reward_chops_today == 4,
		"cooldown blocks another bonus chop without consuming credit or increasing progress")

	game.save_game()
	var reloaded := FarmGameState.new(false)
	reloaded.cash_reward_allow_all_regions = true
	reloaded.save_path = game.save_path
	reloaded.backup_path = game.backup_path
	check(reloaded.load_game() and reloaded.wild_tree_next_chop_at == game.wild_tree_next_chop_at,
		"cooldown persists after reloading a save")
	check(not reloaded.clear_wild_tree(4), "restarting the game cannot bypass the bonus cooldown")

	reloaded.wild_tree_next_chop_at = int(Time.get_unix_time_from_system()) - 1
	check(not reloaded.wild_tree_chop_cooling_down(), "expired cooldown allows the next attempt")
	start_at = int(Time.get_unix_time_from_system())
	check(reloaded.clear_wild_tree(4), "second bonus tree can be chopped after cooldown")
	check(reloaded.wild_tree_next_chop_at >= start_at + 60 and reloaded.wild_tree_next_chop_at <= start_at + 120,
		"each successful bonus chop generates its own cooldown")
	reloaded.wild_tree_chop_date = "2001-01-01"
	check(not reloaded.wild_tree_chop_cooling_down() and reloaded.wild_tree_next_chop_at == 0, "new day clears the previous bonus cooldown")
	check(reloaded.clear_wild_tree(5) and reloaded.wild_tree_chops_today == 1, "new daily free allowance can be used immediately")

	reloaded.new_game(false)
	check(not reloaded.wild_tree_chop_cooling_down() and reloaded.wild_tree_next_chop_at == 0,
		"a new farm resets the cooldown")
	var progress_updates: Array[int] = []
	reloaded.cash_reward_progress_changed.connect(func(amount: int) -> void: progress_updates.append(amount))
	check(reloaded.clear_wild_tree(0) and reloaded.cash_reward_chops_today == 0 and progress_updates.is_empty(),
		"an unverified or emulator device with AllowEmulator disabled can chop without cash reward progress")
	reloaded.cash_reward_allow_emulator = true
	check(reloaded.clear_wild_tree(1) and reloaded.cash_reward_chops_today == 1,
		"AllowEmulator enables cash reward progress without counting previous chops")
	reloaded.cash_reward_allow_emulator = false
	reloaded.cash_reward_real_device = true
	check(reloaded.clear_wild_tree(2) and reloaded.cash_reward_chops_today == 2,
		"a real device counts even when AllowEmulator is disabled")
	reloaded.cash_reward_allow_emulator = true
	reloaded.grant_wild_tree_bonus_chop()
	check(reloaded.clear_wild_tree(3) and progress_updates == [1, 2, 3],
		"a real device with AllowEmulator enabled counts each chop only once")

	reloaded.new_game(false)
	reloaded.cash_reward_real_device = true
	reloaded.cash_reward_allow_emulator = false
	var rewards = preload("res://scripts/tree_count_config.gd").new()
	rewards.host = {"game": reloaded}
	rewards._apply_region_config({"AllowAllRegion": false, "AllowedRegion": [
		{"country": "United States", "code": "us", "rewarded": 15.15, "interstitial": 12.65},
		{"code": " JP "}, {"code": "US"}, {"code": "USA"}, {"code": 42}
	]})
	check(reloaded.cash_reward_allowed_regions == ["US", "JP"], "region config uses normalized country codes only")
	reloaded.cash_reward_ip_country = ""
	check(reloaded.clear_wild_tree(0) and reloaded.cash_reward_chops_today == 0,
		"unknown IP country does not count")
	reloaded.cash_reward_ip_country = "ID"
	check(reloaded.clear_wild_tree(1) and reloaded.cash_reward_chops_today == 0,
		"unlisted IP country does not count")
	reloaded.cash_reward_ip_country = "JP"
	check(reloaded.clear_wild_tree(2) and reloaded.cash_reward_chops_today == 1,
		"listed IP country counts")
	rewards._apply_region_config({"AllowAllRegion": false, "AllowedRegion": "invalid"})
	check(not reloaded.cash_reward_region_allowed(), "invalid region list fails closed")
	rewards._apply_region_config({"AllowAllRegion": true})
	reloaded.cash_reward_ip_country = ""
	reloaded.grant_wild_tree_bonus_chop()
	check(reloaded.clear_wild_tree(3) and reloaded.cash_reward_chops_today == 2,
		"AllowAllRegion counts without an IP lookup")
	# Remote configuration applies to the next bonus chop, preserving an active deadline.
	var active_deadline := reloaded.wild_tree_next_chop_at
	rewards._on_config_ready('{"IsEmulator":false,"AllowAllRegion":true,"CooldownCutDownTrees":{"min":15,"max":25}}')
	check(reloaded.wild_tree_cooldown_min_seconds == 15 and reloaded.wild_tree_cooldown_max_seconds == 25,
		"remote JSON object sets the cooldown range")
	check(reloaded.wild_tree_next_chop_at == active_deadline, "config update preserves active cooldown")
	reloaded.wild_tree_next_chop_at = 0
	reloaded.grant_wild_tree_bonus_chop()
	start_at = int(Time.get_unix_time_from_system())
	check(reloaded.clear_wild_tree(4) and reloaded.wild_tree_next_chop_at >= start_at + 15
		and reloaded.wild_tree_next_chop_at <= start_at + 25, "next bonus chop uses remote cooldown")
	rewards._apply_cooldown_config('{"min":30,"max":30}')
	check(reloaded.wild_tree_cooldown_min_seconds == 30 and reloaded.wild_tree_cooldown_max_seconds == 30,
		"JSON string and fixed cooldown are supported")
	rewards._apply_cooldown_config({"min":0,"max":0})
	check(reloaded.wild_tree_cooldown_min_seconds == 0 and reloaded.wild_tree_cooldown_max_seconds == 0,
		"zero cooldown is supported")
	for invalid in [{"min":90,"max":30}, {"min":-1,"max":20}, {"min":1.5,"max":20}, {"min":"10","max":20}, {"min":10}, {}, "invalid"]:
		rewards._apply_cooldown_config({"min":5,"max":10})
		rewards._apply_cooldown_config(invalid)
		check(reloaded.wild_tree_cooldown_min_seconds == 60 and reloaded.wild_tree_cooldown_max_seconds == 120,
			"invalid or missing cooldown falls back to defaults: " + str(invalid))
	var regrowth = preload("res://scripts/wild_tree_regrowth.gd")
	var farm := {"WORLD_SIZE": Vector2(4000, 7000), "WILD_TREES": [], "original_wild_tree_count": 0}
	var spawn_host := {"game": reloaded, "farm": farm}
	check(reloaded.wild_tree_spawn_min_seconds == 300 and reloaded.wild_tree_spawn_max_seconds == 600,
		"missing spawn cooldown uses 300-600 seconds")
	rewards._on_config_ready('{"AllowAllRegion":true,"CooldownCutDownTrees":{"min":15,"max":25},"CooldownSpawnTrees":{"min":40,"max":50}}')
	check(reloaded.wild_tree_spawn_min_seconds == 40 and reloaded.wild_tree_spawn_max_seconds == 50
		and reloaded.wild_tree_cooldown_min_seconds == 15 and reloaded.wild_tree_cooldown_max_seconds == 25,
		"remote spawn and chop cooldowns are independent")
	reloaded.building_upgrades.wild_tree_next_spawn_at = 0
	start_at = int(reloaded.now())
	regrowth.tick(spawn_host)
	var spawn_deadline := int(reloaded.building_upgrades.wild_tree_next_spawn_at)
	check(spawn_deadline >= start_at + 40 and spawn_deadline <= start_at + 50,
		"first spawn deadline uses remote range")
	rewards._apply_spawn_cooldown_config('{"min":12,"max":12}')
	regrowth.tick(spawn_host)
	check(int(reloaded.building_upgrades.wild_tree_next_spawn_at) == spawn_deadline,
		"remote updates preserve the active spawn deadline")
	reloaded.building_upgrades.wild_tree_next_spawn_at = int(reloaded.now()) - 1
	start_at = int(reloaded.now())
	regrowth.tick(spawn_host)
	check(int(reloaded.building_upgrades.wild_tree_next_spawn_at) >= start_at + 12
		and int(reloaded.building_upgrades.wild_tree_next_spawn_at) <= int(reloaded.now()) + 12,
		"next spawn attempt uses updated fixed interval")
	for invalid in [{"min":90,"max":30}, {"min":-1,"max":20}, {"min":1.5,"max":20}, {"min":"10","max":20}, {"min":10}, {}, "invalid"]:
		rewards._apply_spawn_cooldown_config({"min":5,"max":10})
		rewards._apply_spawn_cooldown_config(invalid)
		check(reloaded.wild_tree_spawn_min_seconds == 300 and reloaded.wild_tree_spawn_max_seconds == 600,
			"invalid spawn cooldown falls back to defaults: " + str(invalid))
	check(reloaded.max_standing_trees == 200, "missing standing-tree limit uses 200")
	var real_farm := FarmView.new()
	real_farm.game = reloaded
	var overlay := FarmView.new()
	overlay.game = reloaded
	rewards.host = {"game": reloaded, "farm": real_farm}
	var real_host := {"game": reloaded, "farm": real_farm}
	var standing := regrowth.standing_count(real_farm)
	check(standing > 0, "farm starts with standing trees")
	rewards._on_config_ready(JSON.stringify({"MaxStandingTrees": standing}))
	reloaded.building_upgrades.wild_tree_next_spawn_at = int(reloaded.now()) - 1
	check(not regrowth.tick(real_host) and not regrowth.spawn_one(real_host)
		and reloaded.building_upgrades.wild_tree_next_spawn_at == 0,
		"configured limit stops spawning at the threshold")
	rewards._apply_max_standing_trees(standing - 1)
	check(not regrowth.tick(real_host) and regrowth.standing_count(real_farm) == standing,
		"lowering the limit leaves existing trees intact")
	rewards._apply_max_standing_trees(standing + 1)
	check(not regrowth.tick(real_host) and reloaded.building_upgrades.wild_tree_next_spawn_at > int(reloaded.now()),
		"raising the limit resumes the spawn schedule")
	rewards._apply_max_standing_trees(0)
	check(not regrowth.tick(spawn_host) and reloaded.building_upgrades.wild_tree_next_spawn_at == 0,
		"zero disables spawning even on an empty farm")
	rewards._apply_max_standing_trees(350.0)
	check(reloaded.max_standing_trees == 350 and real_farm.WILD_TREES.size() >= real_farm.original_wild_tree_count + 350
		and overlay.WILD_TREES.size() == real_farm.WILD_TREES.size(), "higher limits expand shared tree slots")
	var saved_slot := 950
	reloaded.building_upgrades.regrown_wild_trees = {str(saved_slot): [400, 2000]}
	rewards._apply_max_standing_trees(200)
	real_farm.restore_wild_tree_slots()
	check(overlay.wild_tree_active(saved_slot) and overlay.wild_tree_position(saved_slot) == Vector2(400, 2000),
		"saved higher tree IDs remain visible after lowering the limit")
	for invalid in [-1, 1.5, "100", true, 1001, null]:
		rewards._apply_max_standing_trees(50)
		rewards._apply_max_standing_trees(invalid)
		check(reloaded.max_standing_trees == 200, "invalid limit uses default: " + str(invalid))
	overlay.free()
	real_farm.free()
	rewards.free()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.backup_path))
	print("WILD TREE COOLDOWN FAILURES: ", failures)
	quit(failures)
