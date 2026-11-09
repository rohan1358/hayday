extends SceneTree

# Isolated level 1-5 gameplay regression; never uses the player's save paths.
const MAIN_SCRIPT = preload("res://scripts/main.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func find_crop_card(container: Node, crop_name: String) -> Panel:
	for card in container.get_children():
		for child in card.get_children():
			if child is Label and child.text == crop_name:
				return card as Panel
	return null


func find_button(card: Panel, caption: String) -> Button:
	if card == null:
		return null
	for child in card.get_children():
		if child is Button and child.text == caption:
			return child as Button
	return null


func verify_shop(game: FarmGameState, crop_id: String, expected_one: bool, expected_five: bool) -> void:
	var screen := MAIN_SCRIPT.new()
	screen.game = game
	var list := VBoxContainer.new()
	screen.populate_shop(list)
	var card := find_crop_card(list, str(FarmGameState.CROPS[crop_id]["name"]))
	check(card != null, "Toko menampilkan tanaman " + crop_id)
	var one := find_button(card, "BELI 1")
	var five := find_button(card, "BELI 5")
	check(one != null and not one.disabled == expected_one, "Tombol beli 1 cocok dengan saldo " + crop_id)
	check(five != null and not five.disabled == expected_five, "Tombol beli 5 cocok dengan saldo " + crop_id)
	list.free()
	screen.free()


func run_tests() -> void:
	var game := FarmGameState.new()
	var unique_id := str(Time.get_ticks_usec())
	game.save_path = "user://programmer4_economy_" + unique_id + ".json"
	game.backup_path = "user://programmer4_economy_" + unique_id + "_backup.json"
	game.new_game()
	check(game.level == 1 and game.coins == 400, "Petani baru memulai di level 1 dengan 400 koin")
	check(game.harvest(5) == 2 and game.harvest(6) == 2, "Panen pertama menghasilkan gandum dan jagung")
	check(game.plant(0, "gandum"), "Bibit awal cukup untuk menanam kembali")
	game.plots[0]["ready_at"] = game.now() - 1
	check(game.harvest(0) == 2 and game.queue_product("roti"), "Panen dapat diolah menjadi roti tanpa bangunan premium")
	game.production_queue[0]["ready_at"] = game.now() - 1
	check(game.collect_product() and game.inventory["roti"] == 1, "Roti masuk gudang setelah waktu produksi")
	check(game.sell_quantity("roti", 1) == 24, "Roti terjual dan mengembalikan modal")
	check(game.plant(1, "jagung"), "Jagung bisa ditanam untuk melengkapi pesanan")
	game.plots[1]["ready_at"] = game.now() - 1
	check(game.harvest(1) == 2 and game.deliver_order(1), "Pesanan truk diselesaikan dengan panen nyata")

	var harvest_cycles := 0
	var valid_farming := true
	while game.level < 5 and harvest_cycles < 12:
		harvest_cycles += 1
		for index in 8:
			if game.plots[index]["crop"] == "":
				if int(game.seeds["gandum"]) == 0:
					valid_farming = game.buy_seeds("gandum", 5) and valid_farming
				valid_farming = game.plant(index, "gandum") and valid_farming
			game.plots[index]["ready_at"] = game.now() - 1
			valid_farming = game.harvest(index) == 2 and valid_farming
		game.sell_all("gandum")
		valid_farming = valid_farming and game.coins >= 0 and game.storage_used() <= game.storage_capacity
	check(valid_farming and game.level >= 5, "Siklus tanam-panen-jual mencapai level 5 tanpa defisit atau gudang berlebih")
	check(harvest_cycles <= 12, "Progres level 1-5 selesai dalam batas siklus panen")
	check(game.buy_construction("pabrik_pakan"), "Pendapatan bercocok tanam mampu membayar pabrik pakan level 2")

	# Rice is unlocked at level 5, but its five-seed bundle costs 230 coins.
	# A player with 184 coins must be able to buy one or four seeds.
	game.coins = 184
	game.seeds["padi"] = 0
	verify_shop(game, "padi", true, false)
	check(not game.buy_seeds("padi", 5) and game.coins == 184, "Paket 5 padi tetap menolak saldo yang tidak cukup")
	check(game.buy_seeds("padi", 4) and game.coins == 0 and game.seeds["padi"] == 4, "Empat bibit padi dapat dibeli sesuai harga satuan")
	verify_shop(game, "padi", false, false)
	game.coins = 46
	verify_shop(game, "padi", true, false)
	check(game.buy_seeds("padi", 1) and game.coins == 0 and game.seeds["padi"] == 5, "Satu bibit padi cukup untuk mulai bertani dengan 46 koin")
	check(not game.buy_seeds("padi", 1) and not game.buy_seeds("padi", 0), "Pembelian ditolak jika saldo kosong atau jumlah tidak valid")
	check(game.plant(0, "padi"), "Bibit hasil pembelian satuan bisa ditanam")
	game.plots[0]["ready_at"] = game.now() - 1
	check(game.harvest(0) == 3, "Padi tumbuh dan menghasilkan 3 unit hasil")
	check(game.sell_quantity("padi", 1) == 69 and game.coins == 69, "Hasil padi bisa dijual untuk memulihkan modal")
	check(game.storage_used() <= game.storage_capacity and game.coins >= 0, "Kapasitas dan saldo valid setelah pembelian dan panen")

	game.save_game()
	var restored := FarmGameState.new()
	restored.save_path = game.save_path
	restored.backup_path = game.backup_path
	check(restored.load_game(), "Save ekonomi terisolasi bisa dimuat ulang")
	check(restored.level >= 5 and restored.coins == 69 and restored.seeds["padi"] == 4 and restored.inventory["padi"] == 2, "Level, saldo, bibit, dan hasil panen bertahan setelah restart")
	for path in [game.save_path, game.backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
