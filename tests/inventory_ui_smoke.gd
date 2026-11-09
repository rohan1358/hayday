extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, description: String) -> void:
	if condition:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func find_sale_button(screen: Control, title: String) -> Button:
	for item in screen.sheet.find_children("*", "Button", true, false):
		if item.text == title and not item.disabled:
			return item as Button
	return null


func run_tests() -> void:
	var save_path := "user://kebun_ceria_inventory_ui_test.json"
	var backup_path := "user://kebun_ceria_inventory_ui_test_backup.json"
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = save_path
	screen.game.backup_path = backup_path
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.game.inventory["gandum"] = 12
	screen.game.inventory["jeruk"] = 3
	screen.game.orders[0]["items"] = {"gandum": 4}
	screen.game.orders[1]["items"] = {"gandum": 3, "jeruk": 2}
	screen.game.orders[2]["items"] = {}
	var unit_price := int(screen.game.item_info("gandum")["sell"])
	var original_coins: int = screen.game.coins
	screen.call("switch_tab", "gudang")
	var order_notices: Array[String] = []
	for text_label in screen.sheet.find_children("*", "Label", true, false):
		order_notices.append(text_label.text)
	check("DIBUTUHKAN PESANAN: 7" in order_notices, "Gudang menunjukkan total kebutuhan gandum pada pesanan")
	check("DIBUTUHKAN PESANAN: 2" in order_notices, "Gudang menunjukkan kebutuhan jeruk pada pesanan")
	var free_sell_five := find_sale_button(screen, "JUAL 5")
	if free_sell_five:
		free_sell_five.pressed.emit()
		check(screen.game.inventory["gandum"] == 7, "Lima stok bebas terjual tanpa mengganggu pesanan")
		check(screen.find_child("ConfirmSaleReservedStock", true, false) == null, "Stok bebas tidak memunculkan dialog")
		screen.game.inventory["gandum"] = 12
		screen.game.coins = original_coins
		screen.call("switch_tab", "gudang")
	var reserved_sell_all := find_sale_button(screen, "JUAL SEMUA")
	check(reserved_sell_all != null, "Penjualan seluruh stok tersedia dengan pesanan aktif")
	if reserved_sell_all:
		reserved_sell_all.pressed.emit()
		var warning_dialog := screen.find_child("ConfirmSaleReservedStock", true, false) as ConfirmationDialog
		check(warning_dialog != null, "Menjual stok pesanan meminta konfirmasi")
		check(screen.game.inventory["gandum"] == 12, "Stok pesanan tidak berkurang sebelum konfirmasi")
		if warning_dialog:
			warning_dialog.canceled.emit()
			await process_frame
			check(screen.game.inventory["gandum"] == 12, "Membatalkan penjualan menjaga stok pesanan")
			reserved_sell_all.pressed.emit()
			var confirmed_dialog := screen.find_child("ConfirmSaleReservedStock", true, false) as ConfirmationDialog
			if confirmed_dialog:
				confirmed_dialog.confirmed.emit()
				check(screen.game.inventory["gandum"] == 0, "Konfirmasi membolehkan penjualan pilihan pemain")
				check(screen.game.coins == original_coins + 12 * unit_price, "Konfirmasi membayar jumlah yang tepat")
			else:
				check(false, "Dialog tetap tersedia saat pemain mencoba kembali")
			await process_frame
	# Continue the ordinary quantity regression without a reservation.
	screen.game.inventory["gandum"] = 12
	screen.game.coins = original_coins
	screen.game.orders[0]["items"] = {}
	screen.game.orders[1]["items"] = {}
	screen.call("switch_tab", "gudang")
	var stock_rows: Array[Node] = screen.sheet.find_children("StockRow_*", "Panel", true, false)
	check(stock_rows.size() == 2, "Gudang menampilkan jenis barang berstok saja")
	if stock_rows.size() >= 2:
		check(stock_rows[0].name == "StockRow_gandum", "Gandum tersedia di awal daftar")
		check(stock_rows[1].name == "StockRow_jeruk", "Stok buah tampil tanpa melewati barang kosong")
	var empty_group := screen.sheet.find_child("EmptyStockRows", true, false) as VBoxContainer
	var toggle_empty := screen.sheet.find_child("ToggleEmptyStock", true, false) as Button
	check(empty_group != null and not empty_group.visible, "Jenis dengan nol stok awalnya tersembunyi")
	check(empty_group != null and empty_group.get_child_count() == 0, "Baris kosong dibuat saat dibutuhkan saja")
	check(toggle_empty != null, "Gudang menyediakan tombol melihat barang kosong")
	if toggle_empty and empty_group:
		toggle_empty.pressed.emit()
		check(empty_group.visible, "Tombol membuka daftar barang kosong")
		check(empty_group.get_child_count() > 0, "Baris barang kosong dibuat saat dibuka")
		var empty_wheat := empty_group.find_child("EmptyRow_jagung", true, false) as Panel
		check(empty_wheat != null, "Barang kosong tetap dapat dilihat pemain")
		if empty_wheat:
			var sale_buttons := empty_wheat.find_children("*", "Button", true, false)
			check(sale_buttons.all(func(sale: Button) -> bool: return sale.disabled), "Barang nol stok tidak bisa dijual")
		toggle_empty.pressed.emit()
		check(not empty_group.visible, "Tombol menutup kembali daftar kosong")
	screen.game.inventory["jeruk"] = 0
	screen.call("switch_tab", "gudang")
	var sell_one := find_sale_button(screen, "JUAL 1")
	check(sell_one != null, "Gudang menyediakan aksi jual satu unit")
	if sell_one:
		sell_one.pressed.emit()
		check(screen.game.inventory["gandum"] == 11, "Jual satu menjaga sisa stok")
		check(screen.game.coins == original_coins + unit_price, "Jual satu memberi harga sesuai satuan")
	await process_frame
	var sell_five := find_sale_button(screen, "JUAL 5")
	check(sell_five != null, "Gudang menyediakan aksi jual lima unit")
	if sell_five:
		sell_five.pressed.emit()
		check(screen.game.inventory["gandum"] == 6, "Jual lima menjaga sisa stok")
		check(screen.game.coins == original_coins + unit_price * 6, "Jual lima membayar tepat")
	await process_frame
	var sell_all := find_sale_button(screen, "JUAL SEMUA")
	check(sell_all != null, "Gudang mempertahankan aksi jual seluruh stok")
	if sell_all:
		sell_all.pressed.emit()
		check(screen.game.inventory["gandum"] == 0, "Jual semua menghabiskan stok jenis terpilih")
		check(screen.game.coins == original_coins + unit_price * 12, "Jual semua membayar tepat")
		check(screen.sheet.find_children("StockRow_*", "Panel", true, false).is_empty(), "Stok terjual habis tidak memenuhi daftar utama")
		check(find_sale_button(screen, "JUAL 1") == null, "Stok kosong tak punya tombol jual aktif")

	# A full barn must link directly to the inventory before any harvest is lost.
	screen.game.inventory["gandum"] = 8
	screen.game.storage_capacity = screen.game.storage_used()
	screen.call("switch_tab", "gudang")
	var full_warning := false
	for node in screen.sheet.find_children("*", "Label", true, false):
		if node.text == "GUDANG PENUH!":
			full_warning = true
	check(full_warning, "Gudang penuh diberi peringatan jelas")
	screen.call("switch_tab", "kebun")
	screen.call("on_plot_pressed", 5)
	var plot_before: Dictionary = screen.game.plots[5].duplicate(true)
	var stock_before: int = screen.game.inventory["gandum"]
	check(screen.game.is_ready(5), "Petak tutorial siap untuk kasus gudang penuh")
	screen.call("on_harvest_or_speed")
	check(screen.active_tab == "gudang", "Tombol kosongkan gudang membuka gudang langsung")
	check(screen.game.plots[5] == plot_before, "Panen tertahan tidak menghapus tanaman")
	check(screen.game.inventory["gandum"] == stock_before, "Panen tertahan tidak mengubah stok")

	# Collection buttons should remain actionable when the barn is full,
	# redirect to the inventory, and leave ready goods untouched.
	var ready_at: int = screen.game.now() - 1
	screen.game.production_queue.clear()
	screen.game.production_queue.append({"product": "roti", "ready_at": ready_at})
	screen.call("switch_tab", "produksi")
	var product_button := find_sale_button(screen, "BUKA GUDANG ›")
	check(product_button != null, "Hasil dapur siap saat penuh menyediakan tombol gudang")
	if product_button:
		product_button.pressed.emit()
		check(screen.active_tab == "gudang", "Hasil dapur penuh mengarah ke gudang")
		check(screen.game.production_queue.size() == 1, "Hasil dapur tetap antre saat penuh")

	screen.game.constructions["pabrik_pakan"] = 1
	screen.game.feed_queue.clear()
	screen.game.feed_queue.append({"feed": "pakan_sapi", "ready_at": ready_at})
	screen.call("switch_tab", "pakan")
	var feed_button := find_sale_button(screen, "BUKA GUDANG ›")
	check(feed_button != null, "Pakan siap saat penuh menyediakan tombol gudang")
	if feed_button:
		feed_button.pressed.emit()
		check(screen.active_tab == "gudang", "Pakan penuh mengarah ke gudang")
		check(screen.game.feed_queue.size() == 1, "Pakan tetap antre saat penuh")

	screen.game.cow_ready_at = ready_at
	screen.call("switch_tab", "sapi")
	var cow_button := find_sale_button(screen, "BUKA GUDANG ›")
	check(cow_button != null, "Susu siap saat penuh menyediakan tombol gudang")
	if cow_button:
		cow_button.pressed.emit()
		check(screen.active_tab == "gudang", "Susu penuh mengarah ke gudang")
		check(screen.game.cow_milk_ready(), "Susu tetap siap diperah sesudah navigasi")

	screen.game.eggs_ready_at = ready_at
	screen.call("switch_tab", "ternak")
	var eggs_button := find_sale_button(screen, "BUKA GUDANG ›")
	check(eggs_button != null, "Telur siap saat penuh menyediakan tombol gudang")
	if eggs_button:
		eggs_button.pressed.emit()
		check(screen.active_tab == "gudang", "Telur penuh mengarah ke gudang")
		check(screen.game.ready_eggs(), "Telur tetap siap diambil sesudah navigasi")

	screen.game.constructions["kandang_babi"] = 1
	screen.game.livestock["babi"] = ready_at
	screen.game.eggs_ready_at = screen.game.now() + 60
	screen.call("switch_tab", "ternak")
	var pig_button := find_sale_button(screen, "BUKA GUDANG ›")
	check(pig_button != null, "Hasil babi siap saat penuh menyediakan tombol gudang")
	if pig_button:
		pig_button.pressed.emit()
		check(screen.active_tab == "gudang", "Hasil babi penuh mengarah ke gudang")
		check(screen.game.animal_ready("babi"), "Hasil babi tetap siap sesudah navigasi")
	check(screen.game.inventory["gandum"] == stock_before, "Semua jalur gudang menjaga stok awal")

	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	print("TOTAL FAILURES: ", failures)
	quit(1 if failures > 0 else 0)
