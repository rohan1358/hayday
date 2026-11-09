extends SceneTree

# Exercises emergency seed recovery using unique test saves only.
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func drain_farm(game: FarmGameState) -> void:
	game.coins = 0
	for id in game.seeds:
		game.seeds[id] = 0
	for plot in game.plots:
		plot["crop"] = ""
		plot["ready_at"] = 0
		plot["planted_at"] = 0


func run_tests() -> void:
	var uid := str(Time.get_ticks_usec())
	var game := FarmGameState.new()
	game.save_path = "user://prog4_recovery_" + uid + ".json"
	game.backup_path = "user://prog4_recovery_" + uid + "_backup.json"
	check(not game.needs_seed_recovery(), "Kebun normal tidak meminta bantuan")
	game.level = 5
	drain_farm(game)
	check(game.needs_seed_recovery() and game.can_claim_seed_recovery(), "Level 5 kehabisan modal bisa meminta bibit")

	game.seeds["jagung"] = 1
	check(not game.can_claim_seed_recovery(), "Tidak memberikan bibit saat tanaman lain masih bisa ditanam")
	game.seeds["jagung"] = 0
	game.plots[0]["crop"] = "gandum"
	check(not game.can_claim_seed_recovery(), "Tidak memberikan bibit saat masih ada tanaman tumbuh")
	game.plots[0]["crop"] = ""
	game.coins = 3
	check(not game.can_claim_seed_recovery(), "Pembelian satu bibit tetap diprioritaskan jika uang cukup")
	game.coins = 0
	game.seeds["nanas"] = 1
	check(game.can_claim_seed_recovery(), "Bibit yang masih terkunci tidak memblokir pemulihan")
	game.seeds["nanas"] = 0

	game.selected_crop = "jagung"
	check(game.claim_seed_recovery(), "Bantuan pertama berhasil diklaim")
	check(game.coins == 0 and int(game.seeds["gandum"]) == 3 and game.selected_crop == "gandum", "Tepat 3 bibit masuk tanpa menambah koin")
	check(not game.claim_seed_recovery(), "Klaim ulang langsung ditolak")
	check(game.seed_recovery_seconds_left() > 0, "Cooldown 10 menit aktif")

	for index in 3:
		check(game.plant(index, "gandum"), "Bibit bantuan dapat ditanam di petak %d" % index)
		game.plots[index]["ready_at"] = game.now() - 1
		check(game.harvest(index) > 0, "Panen bantuan berhasil di petak %d" % index)
	var harvest_coins := game.sell_all("gandum")
	check(harvest_coins >= 3 and game.coins == harvest_coins, "Hasil bantuan bisa dijual menjadi modal baru")
	check(game.buy_seeds("gandum", 1) and game.plant(0, "gandum"), "Siklus bertani kembali berjalan tanpa bantuan tambahan")

	drain_farm(game)
	game.save_game()
	var loaded := FarmGameState.new()
	loaded.save_path = game.save_path
	loaded.backup_path = game.backup_path
	check(loaded.load_game(), "Save bantuan berhasil dimuat ulang")
	check(loaded.seed_recovery_ready_at == game.seed_recovery_ready_at, "Cooldown tidak hilang setelah restart")
	check(loaded.needs_seed_recovery() and not loaded.can_claim_seed_recovery(), "Pemain yang kembali tetap harus menunggu cooldown")
	loaded.seed_recovery_ready_at = loaded.now() - 1
	check(loaded.claim_seed_recovery() and int(loaded.seeds["gandum"]) == 3, "Bantuan dapat dipakai lagi setelah cooldown berakhir")

	var level20 := FarmGameState.new()
	level20.save_path = "user://prog4_recovery_l20_" + uid + ".json"
	level20.backup_path = "user://prog4_recovery_l20_" + uid + "_backup.json"
	level20.level = 20
	drain_farm(level20)
	check(level20.claim_seed_recovery(), "Bantuan berlaku juga untuk pemain level 20")
	level20.save_game()
	var legacy_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(level20.save_path))
	legacy_data.erase("seed_recovery_ready_at")
	var legacy_file := FileAccess.open(level20.save_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy_data))
	legacy_file.close()
	var legacy_loaded := FarmGameState.new()
	legacy_loaded.save_path = level20.save_path
	legacy_loaded.backup_path = level20.backup_path
	check(legacy_loaded.load_game() and legacy_loaded.seed_recovery_ready_at == 0, "Save lama tanpa kolom bantuan tetap kompatibel")

	for path in [game.save_path, game.backup_path, level20.save_path, level20.backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
