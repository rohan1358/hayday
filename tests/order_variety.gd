extends SceneTree

# Tests new contracts in isolated user:// files; never reads the player's save.
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func all_orders_unique(game: FarmGameState) -> bool:
	for left in game.orders.size():
		for right in range(left + 1, game.orders.size()):
			if game.order_items_equal(game.orders[left]["items"], game.orders[right]["items"]):
				return false
	return true


func run_tests() -> void:
	var game := FarmGameState.new()
	var uid := str(Time.get_ticks_usec())
	game.save_path = "user://pm_order_variety_" + uid + ".json"
	game.backup_path = "user://pm_order_variety_" + uid + "_backup.json"
	game.new_game()
	game.level = 8
	game.deliveries = 14
	var duplicate: Dictionary = game.make_order(2)
	for index in 3:
		game.orders[index] = duplicate.duplicate(true)
	var previous_order: Dictionary = game.orders[2].duplicate(true)
	var starting_coins := game.coins
	check(game.refresh_order(2), "Pesanan duplikat dapat diganti")
	check(
		game.orders[2]["items"] != previous_order["items"],
		"Ganti pesanan memilih komoditas berbeda"
	)
	check(
		game.coins == starting_coins - FarmGameState.ORDER_REFRESH_COST, "Biaya ganti tepat sekali"
	)
	check(
		game.orders[0] == previous_order and game.orders[1] == previous_order,
		"Kontrak aktif lama tetap utuh"
	)
	check(game.refresh_order(0) and game.refresh_order(1), "Sisa pesanan duplikat dapat diganti")
	check(all_orders_unique(game), "Tiga slot meminta komoditas berbeda setelah diganti")
	var previous_items: Dictionary = game.orders[0]["items"].duplicate(true)
	var previous_coins := game.coins
	for id in previous_items:
		game.inventory[id] = int(previous_items[id])
	check(game.deliver_order(0), "Mengirim pesanan menghasilkan kontrak pengganti")
	check(all_orders_unique(game), "Pesanan baru dari truk tidak mengulang komoditas aktif")
	check(game.coins > previous_coins, "Hadiah pesanan diberikan")
	game.save_game()
	var restored := FarmGameState.new()
	restored.save_path = game.save_path
	restored.backup_path = game.backup_path
	check(restored.load_game(), "Pesanan tersimpan dan dimuat kembali")
	var saved_orders_match := restored.orders.size() == game.orders.size()
	for index in game.orders.size():
		var before: Dictionary = game.orders[index]
		var after: Dictionary = restored.orders[index]
		if (
			after["title"] != before["title"]
			or int(after["coins"]) != int(before["coins"])
			or int(after["xp"]) != int(before["xp"])
			or after["items"].size() != before["items"].size()
		):
			saved_orders_match = false
		for id in before["items"]:
			if int(after["items"].get(id, -1)) != int(before["items"][id]):
				saved_orders_match = false
	check(saved_orders_match, "Isi pesanan tetap sama setelah memuat save")
	# Simulate a legacy save with duplicate active orders. Repair must not
	# charge the player or change their inventory, crops, or cooldowns.
	var legacy_order: Dictionary = game.orders[0].duplicate(true)
	for index in 3:
		game.orders[index] = legacy_order.duplicate(true)
	game.order_refresh_until[1] = game.now() + 37
	game.save_game()
	var legacy_coins := game.coins
	var legacy_inventory := game.inventory.duplicate(true)
	var legacy_plots := game.plots.duplicate(true)
	var repaired := FarmGameState.new()
	repaired.save_path = game.save_path
	repaired.backup_path = game.backup_path
	check(repaired.load_game(), "Save lawas dengan pesanan duplikat dapat dibuka")
	check(all_orders_unique(repaired), "Pesanan duplikat dalam save lawas diperbaiki saat load")
	check(
		repaired.order_items_equal(repaired.orders[0]["items"], legacy_order["items"])
		and repaired.orders[0]["title"] == legacy_order["title"]
		and int(repaired.orders[0]["coins"]) == int(legacy_order["coins"])
		and int(repaired.orders[0]["xp"]) == int(legacy_order["xp"]),
		"Kontrak pertama dipertahankan saat perbaikan"
	)
	check(repaired.coins == legacy_coins, "Perbaikan duplikat tidak membebankan koin")
	check(repaired.inventory == legacy_inventory, "Stok tetap utuh setelah perbaikan")
	check(
		repaired.plots == JSON.parse_string(JSON.stringify(legacy_plots)),
		"Kebun tetap utuh setelah perbaikan"
	)
	check(
		repaired.order_refresh_until[1] == game.order_refresh_until[1],
		"Cooldown slot tetap utuh setelah perbaikan"
	)
	var second_load := FarmGameState.new()
	second_load.save_path = game.save_path
	second_load.backup_path = game.backup_path
	check(second_load.load_game(), "Perbaikan tersimpan permanen dan dapat dimuat ulang")
	check(
		all_orders_unique(second_load) and second_load.order_revision == repaired.order_revision,
		"Load berikutnya tidak mengubah kontrak atau revisi lagi"
	)
	for path in [game.save_path, game.backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
