extends SceneTree

# Time-accelerated, event-driven economy simulation. Every crop waits for its
# full configured growth duration on a virtual clock; no instant-harvest loops.
# Saves use unique test-only user:// paths and are removed after the run.
const PLOTS_USED := 8
const MAX_BATCHES := 180
const ADVANCED_CROPS := [
	"nanas", "kopi", "cabai", "tomat", "padi", "labu", "stroberi", "jagung", "gandum"
]

var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
	else:
		print("OK: ", message)


func prepare_game(game: FarmGameState, starting_coins: int, wheat_seeds: int) -> void:
	game.level = 5
	game.xp = 0
	game.coins = starting_coins
	game.onboarding_step = FarmGameState.ONBOARDING_COMPLETE
	for id in game.seeds:
		game.seeds[id] = 0
	game.seeds["gandum"] = wheat_seeds
	for id in game.inventory:
		game.inventory[id] = 0
	for plot in game.plots:
		plot["crop"] = ""
		plot["planted_at"] = 0
		plot["ready_at"] = 0


func select_crop(game: FarmGameState, wheat_only: bool = false) -> String:
	# Upgrade only when the farm can fund a complete eight-plot batch; when cash
	# is tight, grow wheat in whatever number of plots it can afford.
	if wheat_only:
		return "gandum"
	for id in ADVANCED_CROPS:
		var crop: Dictionary = FarmGameState.CROPS[id]
		if game.level >= int(crop["level"]) and game.coins >= PLOTS_USED * int(crop["seed_cost"]):
			return id
	return "gandum"


func move_virtual_clock(game: FarmGameState, elapsed_seconds: int) -> void:
	# Emulate the exact passage of real time without sleeping or modifying
	# production rules in the game itself.
	for plot in game.plots:
		if str(plot["crop"]) != "":
			plot["ready_at"] = int(plot["ready_at"]) - elapsed_seconds
			plot["planted_at"] = int(plot["planted_at"]) - elapsed_seconds


func xp_since_level_five(game: FarmGameState) -> int:
	var result := game.xp
	for crossed_level in range(5, game.level):
		result += 30 + (crossed_level - 1) * 20
	return result


func simulate(
	name: String,
	initial_coins: int,
	initial_wheat: int,
	visit_interval: int,
	max_seconds: int,
	wheat_only: bool = false
) -> Dictionary:
	var uid := "%s_%s" % [str(Time.get_ticks_usec()), name]
	var game := FarmGameState.new()
	game.save_path = "user://p4_pacing_" + uid + ".json"
	game.backup_path = "user://p4_pacing_" + uid + "_backup.json"
	prepare_game(game, initial_coins, initial_wheat)
	var recovery_claimed := false
	if initial_coins == 0 and initial_wheat == 0:
		recovery_claimed = game.claim_seed_recovery()
		check(recovery_claimed, name + ": jalur pemulihan bibit tersedia")
	var simulation_seconds := 0
	var batches := 0
	var planted_total := 0
	var expected_xp := 0
	var total_revenue := 0
	var min_coins := game.coins
	var used_crops: Dictionary = {}
	var valid_transactions := true
	var no_early_harvest := true
	var no_storage_overflow := true
	var level11_reloaded := false
	var initial_funds := initial_coins
	var spending := 0

	while game.level < 20 and batches < MAX_BATCHES and simulation_seconds < max_seconds:
		var crop_id := select_crop(game, wheat_only)
		var info: Dictionary = FarmGameState.CROPS[crop_id]
		var unit_cost := int(info["seed_cost"])
		var available := int(game.seeds.get(crop_id, 0))
		var purchase_count := mini(PLOTS_USED - available, int(game.coins / unit_cost))
		if purchase_count > 0:
			var coins_before_purchase := game.coins
			if not game.buy_seeds(crop_id, purchase_count):
				valid_transactions = false
				break
			valid_transactions = (
				valid_transactions
				and game.coins == coins_before_purchase - purchase_count * unit_cost
			)
			spending += purchase_count * unit_cost
		min_coins = mini(min_coins, game.coins)
		var count := mini(PLOTS_USED, int(game.seeds.get(crop_id, 0)))
		if count <= 0:
			valid_transactions = false
			break
		var start_xp := xp_since_level_five(game)
		for index in count:
			if not game.plant(index, crop_id):
				valid_transactions = false
				break
		if not valid_transactions:
			break
		no_early_harvest = no_early_harvest and not game.is_ready(0) and game.harvest(0) == 0
		var grow := int(info["grow"])
		var wait_seconds := grow
		if visit_interval > 0:
			wait_seconds = ceili(float(grow) / float(visit_interval)) * visit_interval
		move_virtual_clock(game, wait_seconds)
		simulation_seconds += wait_seconds
		var actual_yield := 0
		for index in count:
			actual_yield += game.harvest(index)
		var expected_yield := count * int(info["yield"])
		valid_transactions = valid_transactions and actual_yield == expected_yield
		var earned := game.sell_all(crop_id)
		var expected_revenue := expected_yield * int(info["sell"])
		valid_transactions = valid_transactions and earned == expected_revenue
		valid_transactions = (
			valid_transactions and xp_since_level_five(game) - start_xp == count * int(info["xp"])
		)
		valid_transactions = valid_transactions and game.coins >= 0
		no_storage_overflow = no_storage_overflow and game.storage_used() <= game.storage_capacity
		min_coins = mini(min_coins, game.coins)
		planted_total += count
		expected_xp += count * int(info["xp"])
		total_revenue += earned
		used_crops[crop_id] = true
		batches += 1

		# Confirm persistence at an actual mid-game transition; continue from
		# the loaded object, as a player who restarted their app would.
		if not level11_reloaded and game.level >= 11:
			var next_game := FarmGameState.new()
			next_game.save_path = game.save_path
			next_game.backup_path = game.backup_path
			var reload_success := next_game.load_game()
			valid_transactions = valid_transactions and reload_success
			if reload_success:
				valid_transactions = (
					valid_transactions
					and next_game.coins == game.coins
					and next_game.level == game.level
				)
				game = next_game
			level11_reloaded = true

	check(
		valid_transactions and no_early_harvest, name + ": transaksi, waktu panen, dan XP konsisten"
	)
	check(no_storage_overflow, name + ": gudang tidak melampaui kapasitas")
	check(
		game.level >= 20 and simulation_seconds <= max_seconds,
		name + ": mencapai level 20 dalam batas simulasi"
	)
	check(level11_reloaded, name + ": progres tetap berlanjut sesudah restart level 11+")
	check(xp_since_level_five(game) == expected_xp, name + ": tidak ada XP dari sumber tersembunyi")
	check(
		game.coins == initial_funds + total_revenue - spending,
		name + ": tidak ada koin tercipta/hilang saat bertani"
	)
	print(
		"PACE | ",
		name,
		" | level=",
		game.level,
		" | minutes=",
		snappedf(float(simulation_seconds) / 60.0, 0.1),
		" | batches=",
		batches,
		" | plants=",
		planted_total,
		" | final_coins=",
		game.coins,
		" | min_coins=",
		min_coins,
		" | crops=",
		used_crops.keys()
	)
	for path in [game.save_path, game.backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return {
		"seconds": simulation_seconds,
		"batches": batches,
		"coins": game.coins,
		"level": game.level,
		"crops": used_crops,
		"recovered": recovery_claimed,
		"valid": valid_transactions
	}


func test_crop_profitability() -> void:
	var all_profitable := true
	var all_unlocks_valid := true
	for id in FarmGameState.CROP_ORDER:
		var info: Dictionary = FarmGameState.CROPS[id]
		var grow := int(info["grow"])
		var cost := int(info["seed_cost"])
		var revenue := int(info["yield"]) * int(info["sell"])
		var profit := revenue - cost
		all_profitable = all_profitable and grow > 0 and profit > 0 and int(info["xp"]) > 0
		all_unlocks_valid = all_unlocks_valid and int(info["level"]) <= 20
		print(
			"CROP | ",
			id,
			" | level=",
			info["level"],
			" | grow_sec=",
			grow,
			" | profit/plot=",
			profit,
			" | xp/hour/plot=",
			snappedf(float(info["xp"]) * 3600.0 / float(maxi(1, grow)), 0.1),
			" | coins/hour/plot=",
			snappedf(float(profit) * 3600.0 / float(maxi(1, grow)), 0.1)
		)
	check(all_profitable, "Semua tanaman memiliki durasi valid dan margin jual positif")
	check(all_unlocks_valid, "Seluruh tanaman dapat dibuka maksimal pada level 20")
	var wheat: Dictionary = FarmGameState.CROPS["gandum"]
	var pineapple: Dictionary = FarmGameState.CROPS["nanas"]
	var wheat_xp_rate := float(wheat["xp"]) / float(wheat["grow"])
	var pineapple_xp_rate := float(pineapple["xp"]) / float(pineapple["grow"])
	print(
		"BALANCE | XP_RATE_NANAS_VS_GANDUM=",
		snappedf(pineapple_xp_rate / wheat_xp_rate, 0.01),
		" | (1.0 means equal XP per real minute)"
	)


func run_tests() -> void:
	test_crop_profitability()
	var active := simulate("tiered_active", 400, 0, 0, 3600)
	var casual := simulate("tiered_2min_visits", 400, 0, 120, 7200)
	var sparse := simulate("tiered_10min_visits", 400, 0, 600, 14400)
	var wheat := simulate("wheat_only_active", 400, 0, 0, 3600, true)
	var limited := simulate("zero_coins_one_seed", 0, 1, 120, 9000)
	var empty := simulate("zero_coins_zero_seeds", 0, 0, 120, 9000)
	check(
		int(active["seconds"]) <= int(casual["seconds"]),
		"Kunjungan tiap 2 menit tidak lebih cepat dari pemain aktif"
	)
	check(
		int(casual["seconds"]) <= int(sparse["seconds"]),
		"Kunjungan tiap 10 menit tidak lebih cepat dari tiap 2 menit"
	)
	print(
		"BALANCE | WHEAT_ONLY_MINUTES=",
		snappedf(float(wheat["seconds"]) / 60.0, 0.1),
		" | TIERED_ACTIVE_MINUTES=",
		snappedf(float(active["seconds"]) / 60.0, 0.1),
		" | WHEAT_ONLY_COINS=",
		wheat["coins"],
		" | TIERED_COINS=",
		active["coins"]
	)
	check(
		int(limited["coins"]) > 0 and int(empty["coins"]) > 0,
		"Kondisi modal awal nol pulih menjadi arus kas positif"
	)
	check(bool(empty["recovered"]), "Jalur bibit darurat digunakan hanya untuk skenario tanpa stok")
	check(
		(active["crops"] as Dictionary).has("nanas"),
		"Tanaman level 17 dipakai pada progres hingga level 20"
	)
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
