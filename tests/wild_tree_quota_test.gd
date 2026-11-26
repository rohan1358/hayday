extends SceneTree

var failures := 0


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game := FarmGameState.new(false)
	game.save_path = "user://wild_tree_quota_test.json"
	game.backup_path = "user://wild_tree_quota_backup.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.backup_path))

	for tree_id in range(3):
		check(game.clear_wild_tree(tree_id), "free tree %d can be chopped" % (tree_id + 1))
		check(not game.wild_tree_chop_cooling_down(), "free tree %d sets no cooldown" % (tree_id + 1))
	check(game.wild_tree_chops_today == 3, "three free chops consume the daily allowance")
	check(not game.can_chop_wild_tree(), "no free chops remain")
	check(not game.clear_wild_tree(3) and not game.cleared_wild_trees.has(3), "fourth tree is blocked")
	check(not game.clear_wild_tree(0), "already chopped tree cannot be chopped again")

	var ads := FarmAds.new()
	root.add_child(ads)
	var earned: Array[bool] = []
	var finished: Array[bool] = []
	var gems: Array[int] = []
	ads.tree_chop_rewarded.connect(func() -> void:
		earned.append(true)
		game.grant_wild_tree_bonus_chop()
	)
	ads.tree_chop_finished.connect(func(was_earned: bool) -> void: finished.append(was_earned))
	ads.reward_granted.connect(func(amount: int) -> void: gems.append(amount))
	check(not ads.request_tree_chop() and earned.is_empty(), "unsupported or disabled ads give no extra chops")

	# Mock the SDK reward callback without playing a real ad.
	ads._tree_chop_request = true
	ads._pending_reward = "rewarded"
	ads._fullscreen_active = true
	ads._reward_paid = false
	ads._grant_reward("rewarded_interstitial", 3)
	check(earned.is_empty(), "callback for a different ad type is ignored")
	ads._grant_reward("rewarded", 2)
	ads._grant_reward("rewarded", 2)
	check(earned.size() == 1 and game.wild_tree_bonus_chops == 1, "one SDK reward gives exactly one extra chop")
	check(gems.is_empty(), "tree ad reward does not also award gems")
	ads._cleanup_fullscreen("rewarded")
	check(finished == [true] and not ads._tree_chop_request, "completed ad request is cleared")

	var reloaded := FarmGameState.new(false)
	reloaded.save_path = game.save_path
	reloaded.backup_path = game.backup_path
	check(reloaded.load_game() and reloaded.wild_tree_chops_today == 3 and reloaded.wild_tree_bonus_chops == 1, "daily count and earned credit persist")
	check(reloaded.clear_wild_tree(3), "earned credit permits one extra tree")
	check(reloaded.wild_tree_bonus_chops == 0 and not reloaded.can_chop_wild_tree(), "earned credit is consumed once")
	check(not reloaded.clear_wild_tree(4), "fifth tree is blocked without another ad")

	ads._tree_chop_request = true
	ads._pending_reward = "rewarded_interstitial"
	ads._fullscreen_active = true
	ads._reward_paid = false
	ads._cleanup_fullscreen("rewarded_interstitial")
	ads._grant_reward("rewarded_interstitial", 3)
	check(finished == [true, false] and earned.size() == 1, "dismissed ad and late callback give no credit")
	ads._tree_chop_request = true
	ads._pending_reward = "rewarded_interstitial"
	ads._fullscreen_active = true
	ads._reward_paid = false
	ads._grant_reward("rewarded_interstitial", 3)
	ads._grant_reward("rewarded_interstitial", 3)
	ads._cleanup_fullscreen("rewarded_interstitial")
	check(finished == [true, false, true] and earned.size() == 2 and game.wild_tree_bonus_chops == 2, "rewarded interstitial also grants exactly one extra chop")

	reloaded.grant_wild_tree_bonus_chop()
	reloaded.wild_tree_chop_date = "2001-01-01"
	check(reloaded.can_chop_wild_tree() and reloaded.wild_tree_chops_today == 0 and reloaded.wild_tree_bonus_chops == 0, "new local date resets free allowance and unused ad credits")
	check(reloaded.clear_wild_tree(4), "new day allows chopping again")

	var old_save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	old_save.erase("wild_tree_chop_date")
	old_save.erase("wild_tree_chops_today")
	old_save.erase("wild_tree_bonus_chops")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_save))
	file.close()
	var older_game := FarmGameState.new(false)
	older_game.save_path = game.save_path
	older_game.backup_path = game.backup_path
	check(older_game.load_game() and older_game.wild_tree_chops_today == 0 and older_game.wild_tree_bonus_chops == 0, "older saves without quota fields start with a fresh allowance")

	var config = preload("res://scripts/tree_count_config.gd").new()
	older_game.new_game(false)
	config.host = {"game": older_game}
	config._on_config_ready('{"MaxDailyFreeTreeCuts":5}')
	check(older_game.max_daily_free_tree_cuts == 5, "numeric remote value sets daily free allowance")
	for tree_id in range(5):
		check(older_game.clear_wild_tree(tree_id), "remote free allowance permits tree %d" % (tree_id + 1))
	check(not older_game.clear_wild_tree(5), "sixth chop requires an ad at remote limit five")
	older_game.save_game()
	check(older_game.load_game() and older_game.wild_tree_chops_today == 5, "save preserves usage above default limit")
	config._on_config_ready('{"MaxDailyFreeTreeCuts":2}')
	check(not older_game.can_chop_wild_tree() and older_game.wild_tree_chops_today == 5, "decreasing remote limit preserves used quota")
	config._on_config_ready('{"MaxDailyFreeTreeCuts":6}')
	check(older_game.clear_wild_tree(5) and not older_game.can_chop_wild_tree(), "increasing remote limit grants only the remaining allowance")
	config._on_config_ready('{"MaxDailyFreeTreeCuts":0}')
	older_game.new_game(false)
	check(not older_game.clear_wild_tree(0), "zero disables free chops")
	older_game.grant_wild_tree_bonus_chop()
	check(older_game.clear_wild_tree(0) and older_game.wild_tree_chops_today == 0, "zero limit still allows rewarded chops")
	for invalid in [null, -1, 2.5, "5", true, 2147483648]:
		config._apply_max_daily_free_tree_cuts(invalid)
		check(older_game.max_daily_free_tree_cuts == 3, "invalid remote quota falls back to three: " + str(invalid))
	config.free()

	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = "user://wild_tree_quota_ui.json"
	host.game.backup_path = "user://wild_tree_quota_ui_backup.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.wild_tree_chop_date = Time.get_date_string_from_system()
	host.get_node("TreeCountConfig")._apply_max_daily_free_tree_cuts(5)
	host.game.wild_tree_chops_today = 5
	host.game.wild_tree_bonus_chops = 0
	var available_tree := -1
	for tree_id in host.farm.WILD_TREES.size():
		if host.farm.wild_tree_active(tree_id):
			available_tree = tree_id
			break
	host.game.wild_tree_next_chop_at = int(Time.get_unix_time_from_system()) + 90
	check(not host.farm.start_chopping(available_tree) and host.tree_chop_ad_dialog == null and host.farm.chopping_tree == -1,
		"cooldown blocks another chop without displaying an ad offer")
	var cooldown_notice_visible := false
	for toast in host.toast_layer.get_children():
		for caption in toast.get_children():
			if caption is Label and caption.text == FarmGameState.WILD_TREE_COOLDOWN_NOTICE:
				cooldown_notice_visible = true
	check(cooldown_notice_visible, "cooldown shows only the generic ad-unavailable notice")
	host.game.wild_tree_next_chop_at = 0
	var chop_started := false
	if available_tree >= 0:
		chop_started = host.farm.start_chopping(available_tree)
	check(not chop_started and host.tree_chop_ad_dialog != null and host.tree_chop_ad_dialog.visible, "tapping after remote quota opens ad dialog")
	check(host.tree_chop_ad_dialog.quota_label.text == "5/5 TEBANG GRATIS TERPAKAI", "ad dialog displays remote quota")
	host.get_node("TreeCountConfig")._apply_max_daily_free_tree_cuts(4)
	check(host.tree_chop_ad_dialog.quota_label.text == "4/4 TEBANG GRATIS TERPAKAI", "open dialog updates when remote limit changes")
	check(host.pending_tree_chop_index == available_tree and host.farm.chopping_tree == -1, "blocked tree remains selected and untouched")
	check((host.tree_chop_ad_dialog.get_node("ConfirmationCard/WatchRewardedAd") as Button).text == "TONTON IKLAN BERHADIAH" and (host.tree_chop_ad_dialog.get_node("ConfirmationCard/CancelButton") as Button).text == "Batal", "confirmation offers watch ad or cancel")
	if host.tree_chop_ad_dialog != null:
		host.tree_chop_ad_dialog.hide()
		host.tree_chop_ad_dialog.canceled.emit()
	check(host.pending_tree_chop_index == -1 and host.farm.chopping_tree == -1, "canceling the dialog clears the selected tree")
	host.farm.start_chopping(available_tree)
	host.tree_chop_ad_dialog.hide()
	host._on_tree_chop_ad_confirmed()
	check(not host.game.can_chop_wild_tree() and host.pending_tree_chop_index == -1, "PC ad confirmation cannot bypass the daily limit")
	host.farm.start_chopping(available_tree)
	host.tree_chop_ad_dialog.hide()
	host.ads._tree_chop_request = true
	host.ads._pending_reward = "rewarded_interstitial"
	host.ads._fullscreen_active = true
	host.ads._reward_paid = false
	host.ads._grant_reward("rewarded_interstitial", 3)
	host.ads._cleanup_fullscreen("rewarded_interstitial")
	check(host.game.wild_tree_bonus_chops == 1 and host.farm.chopping_tree == available_tree and host.pending_tree_chop_index == -1, "SDK reward automatically resumes chopping the selected tree")
	host.farm.chopping_tree = -1
	host.game.clear_wild_tree(available_tree)
	var hybrid_tree := -1
	for tree_id in host.farm.WILD_TREES.size():
		if host.farm.wild_tree_active(tree_id):
			hybrid_tree = tree_id
			break
	if hybrid_tree >= 0:
		var controller = host.farm.hybrid_controller
		check(not controller.enqueue({"action": "chop", "target": "tree", "index": hybrid_tree}) and host.pending_tree_chop_index == -1,
			"hybrid cooldown also blocks chopping without opening an ad offer")
		host.game.wild_tree_next_chop_at = 0
		check(not controller.enqueue({"action": "chop", "target": "tree", "index": hybrid_tree}), "hybrid tree chop also opens confirmation after quota")
		check(host.tree_chop_ad_dialog.visible and host.pending_tree_chop_index == hybrid_tree and host.pending_tree_chop_hybrid, "hybrid pending tree is remembered")
		host.tree_chop_ad_dialog.hide()
		host.ads._tree_chop_request = true
		host.ads._pending_reward = "rewarded"
		host.ads._fullscreen_active = true
		host.ads._reward_paid = false
		host.ads._grant_reward("rewarded", 2)
		host.ads._cleanup_fullscreen("rewarded")
		check(host.game.wild_tree_bonus_chops == 1 and host.pending_tree_chop_index == -1 and controller.data.jobs.any(func(job): return job.get("action") == "chop" and int(job.get("index", -1)) == hybrid_tree), "SDK reward requeues selected tree through Ujang's hybrid controller")
	host.queue_free()
	for i in 6:
		await process_frame
	host = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://wild_tree_quota_ui.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://wild_tree_quota_ui_backup.json"))

	ads.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.backup_path))
	await process_frame
	ads = null
	game = null
	reloaded = null
	older_game = null
	preload("res://tests/admob_mock_cleanup.gd").release()
	await process_frame
	print("WILD TREE QUOTA FAILURES: ", failures)
	quit(failures)
