extends SceneTree

# Isolated save paths: never reads or mutates the installed player's save.
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func run_tests() -> void:
	var uid := str(Time.get_ticks_usec())
	var game := FarmGameState.new()
	game.save_path = "user://achievements_" + uid + ".json"
	game.backup_path = "user://achievements_" + uid + "_backup.json"
	game.new_game()
	check(game.achievement_status("missing").is_empty(), "unknown achievement rejected")
	check(game.claim_achievement("panen").is_empty(), "claim before milestone rejected")
	check(game.achievement_progress["panen"] == 0, "new game starts with zero harvested goods")
	check(game.harvest(5) == 2 and game.achievement_progress["panen"] == 2, "real harvest counts units")
	check(game.harvest(5) == 0 and game.achievement_progress["panen"] == 2, "double-harvest does not count")
	game.orchard[0]["ready_at"] = game.now() - 1
	check(game.harvest_tree(0) == 3 and game.achievement_progress["panen"] == 5, "fruit harvest counts units")
	var harvested := int(game.achievement_progress["panen"])
	game.storage_capacity = game.storage_used()
	check(game.harvest(6) == 0 and game.achievement_progress["panen"] == harvested, "full barn does not count failed harvest")
	game.storage_capacity = 60

	game.production_queue.append({"product": "roti", "started_at": game.now() - 50, "ready_at": game.now() - 1})
	check(game.collect_product() and game.achievement_progress["produksi"] == 1, "finished kitchen product counts")
	check(not game.collect_product() and game.achievement_progress["produksi"] == 1, "failed collect does not count")
	game.feed_queue.append({"feed": "pakan_sapi", "started_at": game.now() - 90, "ready_at": game.now() - 1})
	check(game.collect_feed() and game.achievement_progress["produksi"] == 3, "two feed packages count")

	check(game.sell_quantity("gandum", 1) > 0 and game.achievement_progress["dagang"] == 1, "warehouse sale counts one transaction")
	check(game.sell_quantity("gandum", 999) == 0 and game.achievement_progress["dagang"] == 1, "failed sale does not count")
	check(not game.deliver_order(-1) and game.achievement_progress["pengiriman"] == 0, "invalid order does not count")
	game.inventory["gandum"] = 8
	check(game.deliver_order(0) and game.achievement_progress["pengiriman"] == 1, "successful delivery counts once")
	game.inventory["jagung"] = 6
	check(game.list_market_item("jagung", 2), "NPC market listing succeeds")
	check(game.achievement_progress["dagang"] == 1, "listing itself is not a completed sale")
	check(game.settle_market_sales(game.now() + 500) > 0 and game.achievement_progress["dagang"] == 2, "offline market settlement counts once")
	check(game.settle_market_sales(game.now() + 500) == 0 and game.achievement_progress["dagang"] == 2, "repeat market settlement does not count twice")
	game.visitor_request = {"item": "gandum", "quantity": 1, "coins": 20, "xp": 3}
	check(game.fulfill_visitor() and game.achievement_progress["dagang"] == 3, "successful visitor sale counts")
	check(not game.fulfill_visitor() and game.achievement_progress["dagang"] == 3, "visitor double sale rejected")

	game.add_achievement_progress("panen", -10)
	game.add_achievement_progress("unknown", 100)
	check(game.achievement_progress["panen"] == harvested, "invalid progress input ignored")
	game.add_achievement_progress("panen", 600)
	var prev_coins := game.coins
	var prev_gems := game.diamonds
	var one := game.claim_achievement("panen")
	check(int(one.get("tier", 0)) == 1 and game.coins == prev_coins + 100, "tier one reward paid")
	check(game.achievement_status("panen")["tier"] == 2 and game.achievement_status("panen")["ready"], "tier two unlocked automatically")
	var two := game.claim_achievement("panen")
	var three := game.claim_achievement("panen")
	check(int(two.get("tier", 0)) == 2 and int(three.get("tier", 0)) == 3, "three milestones can be claimed in order")
	check(game.achievement_claimed_tiers["panen"] == 3 and game.achievement_status("panen")["completed"], "all three milestones completed")
	check(game.diamonds == prev_gems + 3 or game.diamonds > prev_gems + 3, "tier rewards include three gems (plus any level-up gems)")
	var paid_coins := game.coins
	check(game.claim_achievement("panen").is_empty() and game.coins == paid_coins, "fully claimed milestone cannot pay again")

	var loaded := FarmGameState.new()
	loaded.save_path = game.save_path
	loaded.backup_path = game.backup_path
	check(loaded.load_game() and loaded.achievement_claimed_tiers["panen"] == 3, "claimed tiers persist across reload")
	check(loaded.achievement_progress["produksi"] == 3 and loaded.achievement_progress["dagang"] == 3, "career counters persist across reload")
	check(loaded.claim_achievement("panen").is_empty(), "reload never resets claim status")

	var legacy_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	legacy_data.erase("achievement_progress")
	legacy_data.erase("achievement_claimed_tiers")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_data))
	file.close()
	var legacy := FarmGameState.new()
	legacy.save_path = game.save_path
	legacy.backup_path = game.backup_path
	check(legacy.load_game() and legacy.achievement_progress["pengiriman"] == legacy.deliveries, "legacy save uses delivery history")
	check(legacy.achievement_progress["dagang"] == legacy.market_sales_count, "legacy save retains market transaction history")
	check(legacy.achievement_progress["panen"] == 0 and legacy.achievement_claimed_tiers["panen"] == 0, "legacy save starts missing counters at zero")
	check(legacy.coins == paid_coins, "legacy migration keeps original wallet")
	var badge := FarmGameState.new()
	badge.save_path = "user://achievement_badge_" + uid + ".json"
	badge.backup_path = "user://achievement_badge_" + uid + "_backup.json"
	badge.new_game()
	check(badge.claimable_rewards_count() == 1, "fresh farm highlights available daily check-in")
	check(not badge.claim_daily_checkin().is_empty() and badge.claimable_rewards_count() == 0, "claimed check-in clears header badge")
	badge.add_daily_progress("panen", 6)
	badge.add_achievement_progress("pengiriman", 3)
	check(badge.claimable_rewards_count() == 2, "ready mission and career achievement are both counted")
	check(badge.claim_daily_task("panen") and badge.claimable_rewards_count() == 1, "claimed daily mission disappears from badge")
	check(not badge.claim_achievement("pengiriman").is_empty() and badge.claimable_rewards_count() == 0, "claimed career tier disappears from badge")
	badge.add_achievement_progress("pengiriman", 12)
	check(badge.claimable_rewards_count() == 1, "new career tier is visible when already eligible")
	check(badge.claimable_rewards_count() == 1, "badge calculation does not consume rewards")
	badge.ensure_daily_tasks("2000-01-01")
	check(badge.daily_claimed_count() == 0 and badge.claimable_rewards_count() == 1, "daily task reset retains pending career reward without reissuing today's check-in")

	for path in [game.save_path, game.backup_path, badge.save_path, badge.backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
