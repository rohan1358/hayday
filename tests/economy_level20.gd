extends SceneTree

# Simulates long-term farming without touching the installed Android save.
# Growth timers are shortened only inside the isolated test instance.
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func grow_crop(game: FarmGameState, id: String, index: int = 0) -> bool:
	if not game.buy_seeds(id, 1) or not game.plant(index, id):
		return false
	game.plots[index]["ready_at"] = game.now() - 1
	return game.harvest(index) == int(FarmGameState.CROPS[id]["yield"])


func craft_from_harvest(game: FarmGameState, id: String) -> bool:
	var recipe: Dictionary = FarmGameState.PRODUCTS[id]
	for ingredient in recipe["ingredients"]:
		if not FarmGameState.CROPS.has(ingredient):
			return false
		while int(game.inventory.get(ingredient, 0)) < int(recipe["ingredients"][ingredient]):
			if not grow_crop(game, ingredient):
				return false
	if not game.queue_product(id):
		return false
	game.production_queue[0]["ready_at"] = game.now() - 1
	return game.collect_product() and int(game.inventory[id]) == 1


func test_progression(game: FarmGameState) -> void:
	var crop_tiers := ["nanas", "kopi", "cabai", "tomat", "padi", "gandum"]
	var iterations := 0
	var profitable := true
	var level_history: Array[int] = []
	while game.level < 20 and iterations < 80:
		iterations += 1
		var chosen := ""
		for crop_id in crop_tiers:
			var crop: Dictionary = FarmGameState.CROPS[crop_id]
			if game.level >= int(crop["level"]) and game.coins >= 8 * int(crop["seed_cost"]):
				chosen = crop_id
				break
		if chosen.is_empty() or not game.buy_seeds(chosen, 8):
			profitable = false
			break
		var before := game.coins
		var produced := 0
		for plot_index in 8:
			if not game.plant(plot_index, chosen):
				profitable = false
				break
			game.plots[plot_index]["ready_at"] = game.now() - 1
			produced += game.harvest(plot_index)
		var earned := game.sell_all(chosen)
		profitable = profitable and produced == 8 * int(FarmGameState.CROPS[chosen]["yield"])
		profitable = profitable and earned > 0 and game.coins > before
		profitable = profitable and game.coins >= 0 and game.storage_used() <= game.storage_capacity
		if level_history.is_empty() or level_history.back() != game.level:
			level_history.append(game.level)
	check(profitable, "Ekonomi panen campuran menguntungkan dan gudang tidak overflow")
	check(game.level >= 20 and iterations < 80, "Level 5-20 tercapai dari panen sungguhan")
	print(
		"PROGRESSION: cycles=",
		iterations,
		" level=",
		game.level,
		" coins=",
		game.coins,
		" levels=",
		level_history
	)


func run_tests() -> void:
	var game := FarmGameState.new()
	var uid := str(Time.get_ticks_usec())
	game.save_path = "user://pm_economy_l20_" + uid + ".json"
	game.backup_path = "user://pm_economy_l20_" + uid + "_backup.json"
	game.new_game()
	game.level = 5
	game.coins = 0
	for id in game.seeds:
		game.seeds[id] = 0
	for id in game.inventory:
		game.inventory[id] = 0
	for plot in game.plots:
		plot["crop"] = ""
		plot["ready_at"] = 0
	check(
		not game.buy_seeds("tomat", 1) and not game.can_queue_product("saus_tomat"),
		"Tanaman dan resep level 6+ terkunci di level 5"
	)
	game.eggs_ready_at = game.now() - 1
	check(
		game.collect_eggs() and game.sell_all("telur") == 36,
		"Saat uang dan bibit habis, telur gratis menjadi jalur pemulihan"
	)
	check(
		grow_crop(game, "gandum") and game.sell_all("gandum") == 10,
		"Satu bibit memulihkan modal dan meningkatkan saldo"
	)
	test_progression(game)
	for id in ["tomat", "cabai", "kopi", "nanas"]:
		check(
			game.level >= int(FarmGameState.CROPS[id]["level"]) and grow_crop(game, id),
			"Tanaman level lanjut bisa dibeli, ditanam, dan dipanen: " + id
		)
	for id in ["saus_tomat", "sambal", "selai_nanas"]:
		check(craft_from_harvest(game, id), "Resep lanjut dibuat dari panen sendiri: " + id)
		check(
			game.sell_quantity(id, 1) == int(FarmGameState.PRODUCTS[id]["sell"]),
			"Produk lanjut dapat dijual: " + id
		)
	var old_capacity := game.storage_capacity
	check(
		game.upgrade_storage() and game.storage_capacity == old_capacity + 30,
		"Gudang dapat ditingkatkan setelah progres ekonomi"
	)
	check(
		game.unlock_plot(8) and bool(game.plots[8]["unlocked"]),
		"Lahan tambahan dapat dibeli tanpa memblokir progres"
	)
	game.inventory["gandum"] = game.storage_capacity - game.storage_used()
	check(game.storage_used() == game.storage_capacity, "Gudang penuh terdeteksi")
	check(
		game.buy_seeds("padi", 1) and game.plant(0, "padi"), "Boleh menanam walaupun gudang penuh"
	)
	game.plots[0]["ready_at"] = game.now() - 1
	check(
		game.harvest(0) == 0 and game.is_ready(0),
		"Panen tertahan dan tetap utuh ketika gudang penuh"
	)
	check(
		game.sell_quantity("gandum", 3) == 15 and game.harvest(0) == 3,
		"Penjualan sebagian stok membebaskan ruang untuk panen"
	)
	game.selected_crop = "cabai"
	game.deliveries = 25
	game.order_revision += 1
	game.orders = [game.make_order(0), game.make_order(1), game.make_order(2)]
	var order_valid := true
	for order in game.orders:
		order_valid = order_valid and int(order["coins"]) > 0 and int(order["xp"]) > 0
		for id in order["items"]:
			order_valid = order_valid and game.order_item_accessible(id)
	check(order_valid, "Pesanan akhir game meminta barang yang bisa diperoleh pemain")
	game.save_game()
	var loaded := FarmGameState.new()
	loaded.save_path = game.save_path
	loaded.backup_path = game.backup_path
	check(loaded.load_game(), "Save level 20 dapat dimuat ulang")
	check(
		(
			loaded.level == game.level
			and loaded.coins == game.coins
			and loaded.selected_crop == "cabai"
		),
		"Level, uang, dan pilihan tanaman bertahan"
	)
	check(
		(
			loaded.inventory == game.inventory
			and loaded.seeds == game.seeds
			and loaded.storage_capacity == game.storage_capacity
		),
		"Seluruh stok baru dan kapasitas bertahan setelah restart"
	)
	check(
		loaded.plots == JSON.parse_string(JSON.stringify(game.plots)),
		"Kondisi dan lahan kebun bertahan setelah restart"
	)
	var legacy := FarmGameState.new()
	legacy.save_path = "user://pm_economy_legacy_" + uid + ".json"
	legacy.backup_path = "user://pm_economy_legacy_" + uid + "_backup.json"
	legacy.level = 5
	legacy.save_game()
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(legacy.save_path))
	for id in ["tomat", "cabai", "kopi", "nanas"]:
		json["seeds"].erase(id)
		json["inventory"].erase(id)
	for id in ["saus_tomat", "sambal", "selai_nanas"]:
		json["inventory"].erase(id)
	var file := FileAccess.open(legacy.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(json))
	file.close()
	var migrated := FarmGameState.new()
	migrated.save_path = legacy.save_path
	migrated.backup_path = legacy.backup_path
	check(
		migrated.load_game() and migrated.level == 5 and migrated.coins == legacy.coins,
		"Save lama tanpa item baru tetap kompatibel"
	)
	var migrated_items := true
	for id in ["tomat", "cabai", "kopi", "nanas"]:
		migrated_items = (
			migrated_items and int(migrated.seeds[id]) == 0 and int(migrated.inventory[id]) == 0
		)
	for id in ["saus_tomat", "sambal", "selai_nanas"]:
		migrated_items = migrated_items and int(migrated.inventory[id]) == 0
	check(migrated_items, "Item baru diinisialisasi nol pada data lama")
	for path in [game.save_path, game.backup_path, legacy.save_path, legacy.backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
