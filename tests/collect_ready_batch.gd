extends SceneTree

# All scenarios use throwaway user:// files. The Android player's save is never loaded.
var failures := 0
var test_paths: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func make_game(name: String) -> FarmGameState:
	var game := FarmGameState.new()
	var stem := "user://batch_%s_%d" % [name, Time.get_ticks_usec()]
	game.save_path = stem + ".json"
	game.backup_path = stem + "_backup.json"
	test_paths.append(game.save_path)
	test_paths.append(game.backup_path)
	game.new_game()
	game.level = 10
	return game


func run_tests() -> void:
	var kitchen := make_game("kitchen")
	var start_time := kitchen.now()
	kitchen.production_queue.append({"product": "roti", "started_at": start_time - 40, "ready_at": start_time - 30})
	kitchen.production_queue.append({"product": "popcorn", "started_at": start_time - 30, "ready_at": start_time - 20})
	kitchen.production_queue.append({"product": "roti", "started_at": start_time - 20, "ready_at": start_time - 10})
	kitchen.storage_capacity = kitchen.storage_used() + 2
	check(kitchen.count_collectable_products() == 2, "kitchen counts only finished items that fit in the barn")
	check(kitchen.collect_ready_products() == 2, "batch kitchen collect respects barn capacity")
	check(kitchen.production_queue.size() == 1 and kitchen.production_queue[0]["product"] == "roti", "uncollected kitchen item keeps its FIFO position")
	check(int(kitchen.inventory["roti"]) == 1 and int(kitchen.inventory["popcorn"]) == 1, "kitchen batch grants each recipe's exact yield")
	check(kitchen.xp == 29 and int(kitchen.daily_progress["produksi"]) == 2 and int(kitchen.achievement_progress["produksi"]) == 2, "kitchen rewards XP, daily progress and achievement exactly once per unit")
	check(kitchen.count_collectable_products() == 0 and kitchen.collect_ready_products() == 0, "full barn cannot collect or pay remaining item")
	var reloaded_kitchen := FarmGameState.new()
	reloaded_kitchen.save_path = kitchen.save_path
	reloaded_kitchen.backup_path = kitchen.backup_path
	check(reloaded_kitchen.load_game() and reloaded_kitchen.production_queue.size() == 1 and reloaded_kitchen.xp == 29, "partial kitchen batch is saved consistently")
	kitchen.storage_capacity += 1
	check(kitchen.collect_ready_products() == 1 and kitchen.collect_ready_products() == 0, "remaining kitchen product is collectible once after space opens")
	check(kitchen.production_queue.is_empty() and kitchen.xp == 41 and int(kitchen.achievement_progress["produksi"]) == 3, "second kitchen batch does not duplicate the first rewards")

	var delayed := make_game("fifo")
	delayed.production_queue.append({"product": "roti", "started_at": delayed.now() - 12, "ready_at": delayed.now() - 2})
	delayed.production_queue.append({"product": "popcorn", "started_at": delayed.now() - 2, "ready_at": delayed.now() + 3600})
	delayed.production_queue.append({"product": "roti", "started_at": delayed.now() - 5, "ready_at": delayed.now() - 1})
	check(delayed.count_collectable_products() == 1 and delayed.collect_ready_products() == 1, "unfinished second job blocks later ready job")
	check(delayed.count_collectable_products() == 0 and delayed.collect_ready_products() == 0, "batch never skips unfinished FIFO head")
	delayed.production_queue[0]["ready_at"] = delayed.now() - 1
	check(delayed.count_collectable_products() == 2 and delayed.collect_product(), "single-product API remains compatible after adding batch")
	check(delayed.production_queue.size() == 1 and delayed.collect_ready_products() == 1, "single collect leaves later item for the next action")

	var feed := make_game("feed")
	feed.feed_queue.append({"feed": "pakan_sapi", "started_at": feed.now() - 60, "ready_at": feed.now() - 30})
	feed.feed_queue.append({"feed": "pakan_babi", "started_at": feed.now() - 30, "ready_at": feed.now() - 20})
	feed.feed_queue.append({"feed": "pakan_kambing", "started_at": feed.now() - 20, "ready_at": feed.now() - 10})
	feed.storage_capacity = feed.storage_used() + 5
	check(feed.count_collectable_feed() == 2 and feed.collect_ready_feed() == 2, "feed batch collects two full recipes into five free slots")
	check(feed.feed_queue.size() == 1 and int(feed.inventory["pakan_sapi"]) == 2 and int(feed.inventory["pakan_babi"]) == 2, "feed yields two packages per completed recipe and retains third")
	check(feed.xp == 18 and int(feed.daily_progress["produksi"]) == 2 and int(feed.achievement_progress["produksi"]) == 4, "feed XP and lifetime achievement use exact recipe units; daily goal caps at two")
	check(feed.count_collectable_feed() == 0 and not feed.collect_feed(), "single-feed API also rejects a full barn")
	var reloaded_feed := FarmGameState.new()
	reloaded_feed.save_path = feed.save_path
	reloaded_feed.backup_path = feed.backup_path
	check(reloaded_feed.load_game() and reloaded_feed.feed_queue.size() == 1 and int(reloaded_feed.inventory["pakan_sapi"]) == 2, "feed partial batch and inventory survive reload")
	feed.storage_capacity += 2
	check(feed.collect_feed() and feed.feed_queue.is_empty() and int(feed.inventory["pakan_kambing"]) == 2, "single-feed collection remains compatible when capacity increases")
	check(feed.xp == 30 and int(feed.achievement_progress["produksi"]) == 6 and feed.collect_ready_feed() == 0, "remaining feed grants rewards once without duplicates")

	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	var ui_game := make_game("ui")
	screen.game.save_path = ui_game.save_path
	screen.game.backup_path = ui_game.backup_path
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.game.level = 10
	for product in ["roti", "popcorn", "roti"]:
		screen.game.production_queue.append({"product": product, "started_at": screen.game.now() - 20, "ready_at": screen.game.now() - 1})
	screen.call("switch_tab", "produksi")
	check(screen.production_collect_button != null and screen.production_collect_button.text == "AMBIL SEMUA (3)", "kitchen UI shows batch action for three ready jobs")
	screen.production_collect_button.pressed.emit()
	check(screen.game.production_queue.is_empty() and int(screen.game.inventory["roti"]) == 2 and int(screen.game.inventory["popcorn"]) == 1, "kitchen button collects all jobs with one press")

	screen.game.constructions["pabrik_pakan"] = 1
	for feed_id in ["pakan_sapi", "pakan_babi", "pakan_kambing"]:
		screen.game.feed_queue.append({"feed": feed_id, "started_at": screen.game.now() - 20, "ready_at": screen.game.now() - 1})
	screen.game.storage_capacity = screen.game.storage_used() + 4
	screen.call("switch_tab", "pakan")
	check(screen.feed_collect_button != null and screen.feed_collect_button.text == "AMBIL SEMUA (2)", "feed UI shows only two jobs that fit")
	screen.feed_collect_button.pressed.emit()
	check(screen.game.feed_queue.size() == 1 and screen.feed_collect_button.text == "BUKA GUDANG ›", "feed button collects partial batch and offers barn shortcut")
	screen.feed_collect_button.pressed.emit()
	check(screen.active_tab == "gudang" and screen.game.feed_queue.size() == 1, "barn shortcut preserves ready feed without a payout")
	screen.queue_free()
	await process_frame

	for path in test_paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
