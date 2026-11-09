extends SceneTree

# Uses unique save files; does not touch the actual player's progress.
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
	game.save_path = "user://checkin_" + uid + ".json"
	game.backup_path = "user://checkin_" + uid + "_backup.json"
	game.new_game()
	var initial_coins := game.coins
	check(game.daily_checkin_preview("2026-11-01")["day"] == 1, "kunjungan pertama menawarkan hari 1")
	var day_one := game.claim_daily_checkin("2026-11-01")
	check(int(day_one.get("coins", 0)) == 35 and game.coins == initial_coins + 35, "hadiah hari 1 adalah 35 koin")
	check(game.claim_daily_checkin("2026-11-01").is_empty() and game.coins == initial_coins + 35, "klaim kedua pada hari yang sama ditolak")
	check(game.claim_daily_checkin("2026-10-31").is_empty(), "tanggal perangkat mundur tidak memberi hadiah")
	for day in range(2, 8):
		var date := "2026-11-%02d" % day
		var reward := game.claim_daily_checkin(date)
		check(int(reward.get("day", 0)) == day, "kunjungan berurutan mencapai hari %d" % day)
	check(game.checkin_day == 7 and game.diamonds == 13, "hari 7 menghadiahkan satu permata")
	check(game.daily_checkin_preview("2026-11-08")["day"] == 1, "hari 8 memulai siklus tujuh hari berikutnya")
	check(int(game.claim_daily_checkin("2026-11-08").get("day", 0)) == 1, "hadiah siklus kedua kembali ke hari 1")
	check(int(game.claim_daily_checkin("2026-11-10").get("day", 0)) == 1, "melewatkan sehari mengulang progres ke hari 1")
	var persisted_coins := game.coins
	var loaded := FarmGameState.new()
	loaded.save_path = game.save_path
	loaded.backup_path = game.backup_path
	check(loaded.load_game() and loaded.checkin_date == "2026-11-10" and loaded.checkin_day == 1, "save/load mempertahankan status kunjungan")
	check(loaded.coins == persisted_coins and loaded.claim_daily_checkin("2026-11-10").is_empty(), "reload tidak mengizinkan hadiah ganda")

	var old_save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	old_save.erase("checkin_date")
	old_save.erase("checkin_day")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_save))
	file.close()
	var legacy := FarmGameState.new()
	legacy.save_path = game.save_path
	legacy.backup_path = game.backup_path
	check(legacy.load_game() and legacy.checkin_date.is_empty() and legacy.checkin_day == 0, "save lama tanpa kunjungan tetap kompatibel")
	check(legacy.coins == persisted_coins and int(legacy.claim_daily_checkin("2026-11-11").get("day", 0)) == 1, "migrasi mempertahankan koin dan memulai hadiah hari 1")

	for path in [game.save_path, game.backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
