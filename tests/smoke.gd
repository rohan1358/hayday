extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, what: String) -> void:
	if condition:
		print("OK: ", what)
	else:
		failures += 1
		printerr("FAIL: ", what)


func run_tests() -> void:
	var tutorial := FarmGameState.new()
	tutorial.save_path = "user://kebun_ceria_onboarding_test.json"
	tutorial.backup_path = "user://kebun_ceria_onboarding_test_backup.json"
	tutorial.new_game()
	check(tutorial.onboarding_step == 0 and not tutorial.onboarding_skipped, "pemain baru mendapat panduan panen")
	check(tutorial.harvest(6) > 0 and tutorial.onboarding_step == 0, "panen bukan gandum tidak memajukan panduan")
	check(tutorial.harvest(5) > 0 and tutorial.onboarding_step == 1 and tutorial.onboarding_plot_index == 5, "panen gandum membuka panduan tanam ulang")
	tutorial.onboarding_open_orders()
	check(tutorial.onboarding_step == 1, "membuka pesanan terlalu awal tidak melewati tutorial")
	var tutorial_resume := FarmGameState.new()
	tutorial_resume.save_path = tutorial.save_path
	tutorial_resume.backup_path = tutorial.backup_path
	check(tutorial_resume.load_game() and tutorial_resume.onboarding_step == 1 and tutorial_resume.onboarding_plot_index == 5, "tutorial berlanjut dari langkah tersimpan")
	check(tutorial_resume.plant(0, "gandum") and tutorial_resume.onboarding_step == 1, "menanam di petak lain tidak dihitung sebagai tanam ulang")
	check(tutorial_resume.plant(5, "gandum") and tutorial_resume.onboarding_step == 2, "tanam ulang gandum membuka panduan pesanan")
	tutorial_resume.onboarding_open_orders()
	check(tutorial_resume.onboarding_step == 3 and not tutorial_resume.onboarding_skipped, "buka PESANAN menyelesaikan panduan")
	var tutorial_done := FarmGameState.new()
	tutorial_done.save_path = tutorial.save_path
	tutorial_done.backup_path = tutorial.backup_path
	check(tutorial_done.load_game() and tutorial_done.onboarding_step == 3, "tutorial selesai tetap selesai setelah restart")
	tutorial_done.new_game()
	tutorial_done.skip_onboarding()
	var tutorial_skipped := FarmGameState.new()
	tutorial_skipped.save_path = tutorial.save_path
	tutorial_skipped.backup_path = tutorial.backup_path
	check(tutorial_skipped.load_game() and tutorial_skipped.onboarding_step == 3 and tutorial_skipped.onboarding_skipped, "melewati tutorial tersimpan lintas restart")
	var visitors := FarmGameState.new()
	visitors.save_path = "user://kebun_ceria_visitor_test.json"
	visitors.backup_path = "user://kebun_ceria_visitor_test_backup.json"
	visitors.new_game()
	check(not visitors.visitor_request.is_empty(), "pengunjung pertama datang ke kebun baru")
	var first_offer: Dictionary = visitors.visitor_request.duplicate(true)
	check(first_offer["item"] == "gandum" and first_offer["quantity"] == 2, "permintaan awal dapat dipenuhi panen tutorial")
	var visitor_coins := visitors.coins
	check(not visitors.fulfill_visitor(), "pengunjung menolak transaksi saat barang kurang")
	check(visitors.coins == visitor_coins and visitors.visitor_request == first_offer, "transaksi gagal tidak mengubah hadiah atau permintaan")
	visitors.inventory["gandum"] = 2
	check(visitors.visitor_can_sell(), "pengunjung mengenali stok yang cukup")
	check(visitors.fulfill_visitor(), "barang pengunjung berhasil dijual")
	check(visitors.inventory["gandum"] == 0 and visitors.coins == visitor_coins + int(first_offer["coins"]), "transaksi pengunjung mengurangi stok dan membayar tepat")
	check(visitors.visitor_request.is_empty(), "pengunjung pergi setelah dibayar")
	check(not visitors.fulfill_visitor() and not visitors.refresh_visitor(visitors.visitor_next_at - 1), "transaksi ganda dan kedatangan sebelum cooldown ditolak")
	check(visitors.refresh_visitor(visitors.visitor_next_at), "pengunjung baru tiba tepat setelah jeda")
	var second_offer: Dictionary = visitors.visitor_request.duplicate(true)
	check(visitors.decline_visitor(), "permintaan pengunjung dapat ditolak")
	check(visitors.visitor_request.is_empty() and visitors.visitor_next_at > visitors.now(), "menolak tamu menetapkan jeda kedatangan")
	check(not visitors.refresh_visitor(visitors.visitor_next_at - 1), "penolakan tidak bisa dilewati sebelum cooldown")
	check(visitors.refresh_visitor(visitors.visitor_next_at), "tamu baru menggantikan tawaran yang ditolak")
	check(visitors.visitor_request != second_offer, "tawaran berganti setelah penolakan")
	visitors.save_game()
	var loaded_visitors := FarmGameState.new()
	loaded_visitors.save_path = visitors.save_path
	loaded_visitors.backup_path = visitors.backup_path
	check(loaded_visitors.load_game(), "save pengunjung berhasil dimuat")
	check(loaded_visitors.visitor_request == visitors.visitor_request and loaded_visitors.visitor_counter == visitors.visitor_counter, "tawaran dan urutan tamu tersimpan setelah restart")
	# Simulate a previous save version that had no visitor fields.
	var old_save = JSON.parse_string(FileAccess.get_file_as_string(visitors.save_path))
	old_save.erase("visitor_request")
	old_save.erase("visitor_counter")
	old_save.erase("visitor_next_at")
	var old_save_file := FileAccess.open(visitors.save_path, FileAccess.WRITE)
	old_save_file.store_string(JSON.stringify(old_save))
	old_save_file.close()
	var legacy_visitors := FarmGameState.new()
	legacy_visitors.save_path = visitors.save_path
	legacy_visitors.backup_path = visitors.backup_path
	check(legacy_visitors.load_game(), "save lama tanpa data pengunjung tetap terbaca")
	check(legacy_visitors.refresh_visitor() and not legacy_visitors.visitor_request.is_empty(), "save lama mendapat pengunjung saat permainan dibuka")
	check(legacy_visitors.coins == visitors.coins, "migrasi pengunjung tidak mengubah koin lama")
	var game := FarmGameState.new()
	game.save_path = "user://kebun_ceria_test.json"
	game.backup_path = "user://kebun_ceria_test_backup.json"
	game.new_game()
	var harvest_guard := FarmGameState.new()
	harvest_guard.save_path = "user://kebun_ceria_harvest_guard_test.json"
	harvest_guard.backup_path = "user://kebun_ceria_harvest_guard_test_backup.json"
	harvest_guard.new_game()
	var xp_before_harvest := harvest_guard.xp
	var wheat_before_harvest := int(harvest_guard.inventory["gandum"])
	harvest_guard.storage_capacity = harvest_guard.storage_used() + 1
	check(harvest_guard.harvest(5) == 0, "panen tidak boleh menghilangkan sebagian hasil bila gudang tersisa satu slot")
	check(harvest_guard.is_ready(5) and int(harvest_guard.inventory["gandum"]) == wheat_before_harvest and harvest_guard.xp == xp_before_harvest, "gagal panen menjaga petak, stok, dan XP")
	harvest_guard.storage_capacity = harvest_guard.storage_used() + 2
	check(harvest_guard.harvest(5) == 2 and int(harvest_guard.inventory["gandum"]) == wheat_before_harvest + 2, "dua slot kosong menerima hasil panen utuh")
	check(not harvest_guard.is_ready(5) and harvest_guard.harvest(5) == 0, "panen penuh hanya dapat diambil sekali")
	var sale := FarmGameState.new()
	sale.save_path = "user://kebun_ceria_partial_sale_test.json"
	sale.backup_path = "user://kebun_ceria_partial_sale_test_backup.json"
	sale.new_game()
	sale.inventory["gandum"] = 8
	sale.save_game()
	var sale_start_coins := sale.coins
	check(sale.sell_quantity("gandum", 1) == 5 and sale.inventory["gandum"] == 7 and sale.coins == sale_start_coins + 5, "jual satu gandum menghitung koin dan stok tepat")
	check(sale.sell_quantity("gandum", 5) == 25 and sale.inventory["gandum"] == 2 and sale.coins == sale_start_coins + 30, "jual lima gandum menyisakan dua unit")
	check(sale.sell_quantity("gandum", 3) == 0, "jual melebihi stok ditolak")
	check(sale.sell_quantity("gandum", 0) == 0 and sale.sell_quantity("gandum", -1) == 0 and sale.sell_quantity("tidak_ada", 1) == 0, "jumlah nonpositif dan item tidak dikenal ditolak")
	sale.inventory["item_tanpa_harga"] = 3
	check(sale.sell_quantity("item_tanpa_harga", 1) == 0 and sale.inventory["item_tanpa_harga"] == 3, "item tanpa harga jual tidak bisa dijual")
	sale.inventory.erase("item_tanpa_harga")
	check(sale.inventory["gandum"] == 2 and sale.coins == sale_start_coins + 30, "transaksi ditolak tidak mengubah stok atau koin")
	var sale_restored := FarmGameState.new()
	sale_restored.save_path = sale.save_path
	sale_restored.backup_path = sale.backup_path
	check(sale_restored.load_game() and sale_restored.inventory["gandum"] == 2 and sale_restored.coins == sale.coins, "penjualan parsial tersimpan dan dapat dimuat")
	check(sale.sell_all("gandum") == 10 and sale.inventory["gandum"] == 0 and sale.coins == sale_start_coins + 40, "jual semua menghabiskan sisa stok lewat fungsi kompatibel")
	check(sale.sell_all("gandum") == 0 and sale.sell_quantity("gandum", 1) == 0, "stok habis tidak dapat dijual ulang")
	check(sale_restored.load_game() and sale_restored.inventory["gandum"] == 0 and sale_restored.coins == sale.coins, "jual semua tersimpan tanpa transaksi ganda")
	var economy := FarmGameState.new()
	economy.save_path = "user://kebun_ceria_early_economy_test.json"
	economy.backup_path = "user://kebun_ceria_early_economy_test_backup.json"
	economy.new_game()
	var economy_actions_valid := true
	for cycle in 4:
		for plot_index in 8:
			if economy.plots[plot_index]["crop"] == "":
				if int(economy.seeds["gandum"]) == 0:
					economy_actions_valid = economy.buy_seeds("gandum", 5) and economy_actions_valid
				economy_actions_valid = economy.plant(plot_index, "gandum") and economy_actions_valid
		for plot_index in 8:
			economy.plots[plot_index]["ready_at"] = economy.now() - 1
			economy_actions_valid = economy.harvest(plot_index) == 2 and economy_actions_valid
		economy.sell_all("gandum")
		economy.sell_all("jagung")
	check(economy_actions_valid and economy.level >= 3 and economy.coins >= 595, "panen dan penjualan normal membuka level 3 serta modal tiga bangunan level 2")
	check(economy.buy_construction("pabrik_pakan") and economy.buy_construction("kandang_babi") and economy.buy_construction("toko_roti"), "hasil ekonomi awal cukup membeli pabrik pakan, kandang babi, dan rumah roti")
	check(economy.coins >= 0 and economy.storage_used() <= economy.storage_capacity, "progres ekonomi awal menjaga koin dan kapasitas gudang valid")
	check(game.plots.size() == 16, "16 petak tersedia")
	check(game.plots[0]["unlocked"] and not game.plots[15]["unlocked"], "8 petak terbuka")
	check(game.plots[5]["crop"] == "gandum" and game.is_ready(5), "gandum pertama siap dipanen")
	check(game.plots[6]["crop"] == "jagung" and game.is_ready(6), "jagung pertama siap dipanen")
	check(game.plots[7]["crop"] == "gandum" and not game.is_ready(7), "bibit tutorial sedang tumbuh")
	check(game.plant(0, "gandum"), "bisa menanam gandum")
	check(not game.plant(0, "gandum"), "tidak bisa menanam dua kali")
	check(game.seeds["gandum"] == 7, "bibit berkurang")
	check(game.accelerate(0) and game.is_ready(0), "permata mempercepat panen")
	check(game.harvest(0) == 2, "panen menghasilkan 2 gandum")
	check(game.daily_progress["panen"] == 2, "misi harian menghitung jumlah panen")
	check(not game.claim_daily_task("panen"), "hadiah misi tidak bisa diklaim terlalu awal")
	check(game.inventory["gandum"] == 2, "hasil masuk gudang")
	check(not game.harvest(0), "panen ganda ditolak")
	check(game.plant(1, "gandum"), "bisa menanam di petak kedua")
	game.plots[1]["ready_at"] = game.now() - 1
	check(game.harvest(1) == 2, "waktu panen terhitung")
	check(game.daily_progress["panen"] == 4, "panen berikutnya menambah progres misi")
	check(game.order_can_fill(0), "stok cukup untuk pesanan pertama")
	var before := game.coins
	check(game.deliver_order(0), "pesanan bisa dikirim")
	check(game.daily_progress["pesanan"] == 1, "pengiriman masuk ke misi kurir")
	check(not game.deliver_order(-1), "pesanan invalid tidak dihitung sebagai misi")
	check(game.daily_progress["pesanan"] == 1, "misi tidak bertambah pada pesanan gagal")
	check(
		game.coins > before and game.inventory["gandum"] == 0, "hadiah dan pengurangan stok atomik"
	)
	check(game.buy_seeds("jagung"), "toko bisa menjual bibit")
	var land_price := game.land_cost()
	before = game.coins
	check(game.unlock_plot(8), "lahan dapat dibuka")
	check(game.coins == before - land_price, "harga lahan sesuai")
	game.eggs_ready_at = game.now() - 1
	check(game.collect_eggs(), "ayam menghasilkan telur")
	check(game.inventory["telur"] == 2, "telur masuk gudang")
	check(game.sell_all("telur") == 36, "telur terjual 36 koin")
	game.add_daily_progress("panen", 100)
	check(game.daily_progress["panen"] == 6, "progres misi dibatasi target")
	var coins_before_mission := game.coins
	check(game.claim_daily_task("panen"), "misi panen selesai dapat diklaim")
	check(game.coins == coins_before_mission + 65, "hadiah misi menambah koin tepat")
	check(game.daily_claimed_count() == 1, "papan menghitung misi yang diklaim")
	check(not game.claim_daily_task("panen"), "hadiah misi tidak bisa diklaim dua kali")
	check(game.coins == coins_before_mission + 65, "klaim ganda tidak menghasilkan koin")
	game.add_daily_progress("pesanan")
	var gems_before_mission := game.diamonds
	check(game.claim_daily_task("pesanan"), "misi pengiriman dapat diklaim")
	check(game.diamonds >= gems_before_mission + 1, "hadiah misi pengiriman memberi permata")
	game.save_game()
	var restored := FarmGameState.new()
	restored.save_path = game.save_path
	restored.backup_path = game.backup_path
	check(restored.load_game(), "progres dimuat dari JSON")
	check(restored.coins == game.coins and restored.level == game.level, "data tersimpan konsisten")
	check(restored.plots[8]["unlocked"], "status lahan tersimpan")
	check(restored.daily_progress["panen"] == 6, "progres misi tersimpan")
	check(
		restored.daily_claimed["panen"] and restored.daily_claimed["pesanan"],
		"klaim harian tersimpan"
	)
	check(not restored.claim_daily_task("panen"), "misi terklaim tetap terkunci setelah load")
	check(not game.can_queue_product("tidak_ada"), "produk tidak dikenal ditolak")
	var contracts := FarmGameState.new()
	contracts.save_path = "user://kebun_ceria_contract_test.json"
	contracts.backup_path = "user://kebun_ceria_contract_test_backup.json"
	contracts.new_game()
	check(not contracts.can_refresh_order(-1), "kontrak negatif tidak dapat diganti")
	check(not contracts.can_refresh_order(3), "kontrak di luar slot tidak dapat diganti")
	var first_contract: Dictionary = contracts.orders[0].duplicate(true)
	var initial_coins := contracts.coins
	check(contracts.refresh_order(0), "kontrak pertama dapat diganti")
	check(contracts.coins == initial_coins - 15, "penggantian mengurangi tepat 15 koin")
	check(contracts.orders[0] != first_contract, "kontrak baru berbeda dari sebelumnya")
	check(contracts.order_revision == 1, "nomor revisi kontrak bertambah")
	var refresh_until := contracts.order_refresh_until[0]
	check(
		refresh_until >= contracts.now() + FarmGameState.ORDER_REFRESH_SECONDS - 1,
		"cooldown tercatat 45 detik",
	)
	check(not contracts.refresh_order(0), "tidak bisa membayar ulang selama cooldown")
	check(
		contracts.coins == initial_coins - 15 and contracts.order_revision == 1,
		"penggantian gagal tidak mengurangi koin",
	)
	check(
		(
			not contracts.can_refresh_order(0, refresh_until - 1)
			and contracts.can_refresh_order(0, refresh_until)
		),
		"cooldown berakhir tepat pada waktunya",
	)
	check(contracts.refresh_order(1), "cooldown setiap kontrak terpisah")
	contracts.coins = 0
	check(not contracts.refresh_order(2), "koin tidak cukup menolak penggantian")
	contracts.coins = 250
	contracts.save_game()
	var restored_contracts := FarmGameState.new()
	restored_contracts.save_path = contracts.save_path
	restored_contracts.backup_path = contracts.backup_path
	check(restored_contracts.load_game(), "save kontrak dapat dibaca")
	check(
		(
			restored_contracts.order_refresh_until == contracts.order_refresh_until
			and restored_contracts.order_revision == contracts.order_revision
		),
		"cooldown dan revisi kontrak bertahan setelah restart",
	)
	var saved_contracts_match := restored_contracts.orders.size() == contracts.orders.size()
	for index in contracts.orders.size():
		var expected: Dictionary = contracts.orders[index]
		var actual: Dictionary = restored_contracts.orders[index]
		if (
			actual["title"] != expected["title"]
			or int(actual["coins"]) != int(expected["coins"])
			or int(actual["xp"]) != int(expected["xp"])
			or actual["items"].size() != expected["items"].size()
		):
			saved_contracts_match = false
		for id in expected["items"]:
			if int(actual["items"].get(id, -1)) != int(expected["items"][id]):
				saved_contracts_match = false
	check(saved_contracts_match, "isi kontrak terbaru tetap tersimpan")
	contracts.deliveries = 4
	contracts.level = 4
	contracts.order_revision = 0
	var multi_contract: Dictionary = contracts.make_order(0)
	check(multi_contract["items"].size() == 2, "kontrak lanjut berisi dua jenis barang")
	check(not contracts.order_item_accessible("apel"), "apel yang belum ditanam tidak diminta")
	check(not contracts.order_item_accessible("bacon"), "bacon butuh kandang babi")
	check(not contracts.order_item_accessible("yogurt_kambing"), "yogurt butuh kandang kambing")
	var all_accessible := true
	for revision in 30:
		contracts.order_revision = revision
		for id in contracts.make_order(0)["items"]:
			if not contracts.order_item_accessible(id):
				all_accessible = false
	check(all_accessible, "kontrak baru hanya meminta komoditas yang dapat dihasilkan")
	contracts.constructions["kandang_babi"] = 1
	contracts.constructions["kandang_kambing"] = 1
	contracts.orchard[1]["fruit"] = "apel"
	check(
		(
			contracts.order_item_accessible("bacon")
			and contracts.order_item_accessible("yogurt_kambing")
			and contracts.order_item_accessible("apel")
		),
		"produk dari fasilitas yang dibeli menjadi tersedia",
	)
	contracts.orders[0] = multi_contract
	var requested: Dictionary = multi_contract["items"]
	for id in requested:
		contracts.inventory[id] = int(requested[id])
	var missing_id: String = requested.keys()[0]
	contracts.inventory[missing_id] -= 1
	var insufficient_stock := contracts.inventory.duplicate(true)
	var coins_before_rejected := contracts.coins
	check(not contracts.deliver_order(0), "kontrak gabungan menolak stok belum lengkap")
	check(
		contracts.inventory == insufficient_stock and contracts.coins == coins_before_rejected,
		"kontrak gagal tidak mengambil sebagian barang atau koin",
	)
	contracts.inventory[missing_id] += 1
	var coins_before_delivery := contracts.coins
	check(contracts.deliver_order(0), "kontrak gabungan dapat dipenuhi")
	var consumed_both := true
	for id in requested:
		if int(contracts.inventory[id]) != 0:
			consumed_both = false
	check(consumed_both, "dua jenis komoditas dikurangi sesuai kontrak")
	check(
		contracts.coins == coins_before_delivery + int(multi_contract["coins"]),
		"hadiah kontrak gabungan dibayar tepat",
	)
	var kitchen := FarmGameState.new()
	kitchen.save_path = "user://kebun_ceria_production_test.json"
	kitchen.backup_path = "user://kebun_ceria_production_test_backup.json"
	kitchen.new_game()
	check(not kitchen.queue_product("roti"), "bahan kosong menolak pembuatan roti")
	kitchen.inventory["gandum"] = 9
	kitchen.inventory["jagung"] = 3
	check(kitchen.queue_product("roti"), "resep roti dapat diantre")
	check(kitchen.inventory["gandum"] == 6, "bahan roti dikurangi saat antre")
	check(kitchen.queue_product("popcorn"), "resep popcorn dapat diantre")
	check(kitchen.inventory["jagung"] == 0, "bahan popcorn dikurangi saat antre")
	check(kitchen.queue_product("roti"), "slot produksi ketiga tersedia")
	check(not kitchen.queue_product("roti"), "slot produksi keempat ditolak")
	check(kitchen.inventory["gandum"] == 3, "antrean penuh tidak mengambil bahan")
	check(
		(
			int(kitchen.production_queue[1]["started_at"])
			== int(kitchen.production_queue[0]["ready_at"])
		),
		"resep kedua dimulai setelah resep pertama",
	)
	check(
		(
			int(kitchen.production_queue[2]["started_at"])
			== int(kitchen.production_queue[1]["ready_at"])
		),
		"resep ketiga dimulai setelah resep kedua",
	)
	var queued_copy := FarmGameState.new()
	queued_copy.save_path = kitchen.save_path
	queued_copy.backup_path = kitchen.backup_path
	check(queued_copy.load_game(), "antrian produksi dapat dimuat")
	check(
		(
			queued_copy.production_queue.size() == 3
			and queued_copy.production_queue[1]["product"] == "popcorn"
		),
		"urutan produksi bertahan setelah aplikasi ditutup",
	)
	check(not kitchen.collect_product(), "hasil belum matang tidak dapat diambil")
	kitchen.production_queue[0]["ready_at"] = kitchen.now() - 1
	check(kitchen.production_ready(), "produksi berjalan dengan jam asli")
	var previous_capacity := kitchen.storage_capacity
	kitchen.storage_capacity = kitchen.storage_used()
	check(not kitchen.collect_product(), "gudang penuh menolak pengambilan hasil")
	check(kitchen.production_queue.size() == 3, "gudang penuh menjaga antrian")
	kitchen.storage_capacity = previous_capacity
	var previous_xp := kitchen.xp
	check(kitchen.collect_product(), "hasil roti matang dapat diambil")
	check(kitchen.daily_progress["produksi"] == 1, "misi dapur menghitung produk diambil")
	check(kitchen.inventory["roti"] == 1, "roti masuk gudang")
	check(kitchen.xp == previous_xp + 12, "produksi roti memberi XP")
	kitchen.production_queue[0]["ready_at"] = kitchen.now() - 1
	check(kitchen.collect_product(), "produksi popcorn dapat diambil")
	check(kitchen.daily_progress["produksi"] == 2, "misi dapur selesai setelah dua produk")
	check(kitchen.claim_daily_task("produksi"), "hadiah misi dapur dapat diklaim")
	check(not kitchen.claim_daily_task("produksi"), "hadiah dapur hanya sekali")
	check(kitchen.inventory["popcorn"] == 1, "popcorn masuk gudang")
	check(kitchen.sell_all("popcorn") == 48, "produk olahan dapat dijual")
	check(kitchen.inventory["popcorn"] == 0, "produk terjual keluar dari gudang")
	check(not kitchen.can_queue_product("jus_wortel"), "resep level dua masih terkunci")
	kitchen.level = 2
	kitchen.inventory["wortel"] = 2
	check(kitchen.queue_product("jus_wortel"), "resep level dua dapat dibuat")
	check(kitchen.inventory["wortel"] == 0, "resep jus mengonsumsi wortel")
	kitchen.deliveries = 2
	var crafted_order: Dictionary = kitchen.make_order(1)["items"]
	check(
		FarmGameState.PRODUCTS.has(crafted_order.keys()[0]),
		"pesanan kota dapat meminta hasil olahan setelah dua pengiriman"
	)
	var dairy := FarmGameState.new()
	dairy.save_path = "user://kebun_ceria_dairy_test.json"
	dairy.backup_path = "user://kebun_ceria_dairy_test_backup.json"
	dairy.new_game()
	check(dairy.cow_is_hungry(), "sapi baru memerlukan pakan")
	check(not dairy.feed_cow(), "sapi tidak bisa makan tanpa bahan")
	dairy.inventory["gandum"] = 2
	dairy.inventory["jagung"] = 1
	check(dairy.can_feed_cow(), "pakan gandum dan jagung cukup")
	check(dairy.feed_cow(), "pakan memulai siklus susu")
	check(
		dairy.inventory["gandum"] == 0 and dairy.inventory["jagung"] == 0, "pakan dikurangi tepat"
	)
	check(not dairy.feed_cow(), "tidak bisa memberi pakan dua kali saat produksi")
	check(not dairy.cow_milk_ready(), "susu tidak langsung siap")
	var loaded_dairy := FarmGameState.new()
	loaded_dairy.save_path = dairy.save_path
	loaded_dairy.backup_path = dairy.backup_path
	check(loaded_dairy.load_game(), "progres kandang sapi disimpan")
	check(loaded_dairy.cow_ready_at == dairy.cow_ready_at, "timer sapi bertahan setelah ditutup")
	dairy.cow_ready_at = dairy.now() - 1
	check(dairy.cow_milk_ready(), "susu matang berdasarkan waktu nyata")
	dairy.storage_capacity = dairy.storage_used() + 1
	check(not dairy.collect_milk(), "gudang harus muat dua botol susu")
	check(dairy.cow_milk_ready(), "susu tetap siap saat gudang penuh")
	dairy.storage_capacity = 60
	check(dairy.collect_milk(), "susu siap dapat diperah")
	check(
		dairy.inventory["susu"] == 2 and dairy.cow_is_hungry(),
		"dua susu masuk gudang; sapi lapar lagi"
	)
	check(not dairy.collect_milk(), "susu tidak dapat diambil dua kali")
	check(dairy.xp == 10, "memerah sapi memberi 10 XP")
	check(not dairy.can_queue_product("keju"), "resep keju terkunci di level satu")
	dairy.level = 2
	dairy.inventory["jagung"] = 1
	check(dairy.queue_product("keju"), "susu dan jagung menjadi bahan keju")
	check(
		dairy.inventory["susu"] == 0 and dairy.inventory["jagung"] == 0,
		"resep keju mengonsumsi bahan"
	)
	dairy.production_queue[0]["ready_at"] = dairy.now() - 1
	check(dairy.collect_product() and dairy.inventory["keju"] == 1, "keju matang dapat dipanen")
	check(dairy.sell_all("keju") == 85, "keju dapat dijual untuk koin")
	dairy.save_game()
	var reread_dairy := FarmGameState.new()
	reread_dairy.save_path = dairy.save_path
	reread_dairy.backup_path = dairy.backup_path
	check(reread_dairy.load_game(), "progres sapi dan keju dapat dimuat ulang")
	check(
		reread_dairy.inventory["susu"] == 0 and reread_dairy.cow_is_hungry(),
		"status kandang setelah perah tersimpan"
	)
	var market := FarmGameState.new()
	market.save_path = "user://kebun_ceria_market_test.json"
	market.backup_path = "user://kebun_ceria_market_test_backup.json"
	market.inventory["gandum"] = 8
	market.inventory["jagung"] = 4
	check(not market.list_market_item("palsu", 1), "pasar menolak barang tidak dikenal")
	check(not market.list_market_item("gandum", 0), "pasar menolak jumlah nol")
	check(not market.list_market_item("gandum", 4), "pasar membatasi jumlah per lapak")
	check(market.list_market_item("gandum", 3), "pasang tiga gandum ke pasar")
	check(market.inventory["gandum"] == 5, "stok berpindah ke lapak secara langsung")
	check(market.market_listings[0]["unit_price"] == 10, "harga pasar dua kali jual gudang")
	check(market.list_market_item("jagung", 1), "lapak kedua menerima jagung")
	check(market.list_market_item("gandum", 1), "lapak ketiga tersedia")
	check(not market.list_market_item("jagung", 1), "lapak keempat ditolak")
	check(not market.cancel_market_listing(-1), "nomor lapak invalid ditolak")
	check(market.cancel_market_listing(1), "lapak kedua bisa dibatalkan")
	check(market.inventory["jagung"] == 4, "pembatalan mengembalikan barang")
	check(market.market_listings.size() == 2, "pembatalan membebaskan slot")
	check(market.list_market_item("jagung", 3), "slot dibebaskan dapat dipakai lagi")
	market.save_game()
	var listed_market := FarmGameState.new()
	listed_market.save_path = market.save_path
	listed_market.backup_path = market.backup_path
	check(listed_market.load_game(), "lapak pasar dapat dimuat dari save")
	check(listed_market.market_listings.size() == 3, "semua lapak bertahan setelah restart")
	check(listed_market.inventory["gandum"] == 4, "barang lapak tidak kembali saat load")
	check(
		listed_market.settle_market_sales(listed_market.now() - 1) == 0,
		"belum jatuh tempo tidak menghasilkan koin"
	)
	listed_market.market_listings[0]["ready_at"] = listed_market.now() - 1
	var market_coins_before := listed_market.coins
	check(listed_market.settle_market_sales() == 30, "pembeli otomatis membayar gandum")
	check(listed_market.coins == market_coins_before + 30, "koin pasar bertambah sekali")
	check(listed_market.market_sales_count == 1, "total penjualan mencatat pembelian")
	check(
		listed_market.settle_market_sales() == 0, "transaksi yang sama tidak dapat diklaim dua kali"
	)
	check(listed_market.market_listings.size() == 2, "lapak terjual kembali kosong")
	for listing in listed_market.market_listings:
		listing["ready_at"] = listed_market.now() - 1
	listed_market.save_game()
	var offline_market := FarmGameState.new()
	offline_market.save_path = market.save_path
	offline_market.backup_path = market.backup_path
	check(offline_market.load_game(), "penjualan offline dapat dimuat")
	var offline_before := offline_market.coins
	check(offline_market.settle_market_sales() == 88, "dua lapak laku ketika aplikasi ditutup")
	check(offline_market.coins == offline_before + 88, "hadiah offline dibayar dengan benar")
	check(offline_market.market_sales_count == 3, "jumlah penjualan kumulatif benar")
	check(offline_market.market_listings.is_empty(), "lapak kosong setelah pembelian offline")
	var paid_market := FarmGameState.new()
	paid_market.save_path = market.save_path
	paid_market.backup_path = market.backup_path
	check(paid_market.load_game(), "transaksi offline yang dibayar tersimpan")
	check(paid_market.settle_market_sales() == 0, "restart tidak mengulang hadiah offline")
	market.new_game()
	market.inventory["gandum"] = 1
	market.inventory["jagung"] = 60
	check(market.list_market_item("gandum", 1), "barang bisa dipasang saat gudang padat")
	check(not market.cancel_market_listing(0), "pembatalan ditolak jika gudang penuh")
	check(market.market_listings.size() == 1, "pembatalan gagal mempertahankan lapak")
	market.inventory["jagung"] = 59
	check(market.cancel_market_listing(0), "barang dapat kembali setelah ada ruang")
	var orchard := FarmGameState.new()
	orchard.save_path = "user://kebun_ceria_orchard_test.json"
	orchard.backup_path = "user://kebun_ceria_orchard_test_backup.json"
	check(orchard.orchard.size() == 2, "dua petak pohon buah tersedia")
	check(
		orchard.orchard[0]["fruit"] == "jeruk" and orchard.orchard[1]["fruit"] == "",
		"kebun baru memiliki satu pohon jeruk"
	)
	check(not orchard.plant_tree(-1, "jeruk"), "nomor petak pohon invalid ditolak")
	check(not orchard.plant_tree(1, "tak_dikenal"), "jenis buah invalid ditolak")
	check(not orchard.plant_tree(0, "apel"), "pohon yang sudah tumbuh tidak dapat ditimpa")
	check(not orchard.plant_tree(1, "apel"), "pohon apel terkunci sebelum level dua")
	orchard.level = 2
	orchard.coins = 100
	check(not orchard.plant_tree(1, "apel"), "koin kurang menolak pembelian pohon")
	orchard.coins = 400
	check(orchard.plant_tree(1, "apel"), "petak kedua bisa ditanami pohon apel")
	check(orchard.coins == 180, "harga pembelian apel dipotong sekali")
	check(not orchard.plant_tree(1, "apel"), "tidak bisa membeli pohon dua kali")
	check(not orchard.tree_ready(0, orchard.now() - 1), "buah mentah belum bisa dipanen")
	check(orchard.harvest_tree(0) == 0, "panen sebelum matang ditolak")
	orchard.orchard[0]["ready_at"] = orchard.now() - 1
	orchard.storage_capacity = orchard.storage_used() + 2
	check(orchard.harvest_tree(0) == 0, "gudang kurang dari tiga slot menolak panen")
	check(orchard.tree_ready(0), "buah tetap siap setelah panen ditolak")
	orchard.storage_capacity = 60
	check(orchard.harvest_tree(0) == 3, "pohon jeruk menghasilkan tiga buah")
	check(orchard.inventory["jeruk"] == 3, "jeruk masuk gudang")
	check(not orchard.tree_ready(0), "pohon mengulang masa tumbuh setelah panen")
	check(orchard.harvest_tree(0) == 0, "panen dua kali langsung ditolak")
	check(orchard.daily_progress["panen"] == 3, "panen buah menambah misi harian")
	orchard.orchard[1]["ready_at"] = orchard.now() - 1
	check(orchard.harvest_tree(1) == 3, "pohon apel menghasilkan tiga buah")
	check(orchard.inventory["apel"] == 3, "apel masuk gudang")
	check(orchard.list_market_item("jeruk", 1), "buah dapat dijual lewat pasar")
	check(orchard.sell_all("apel") == 123, "apel dapat dijual lewat gudang")
	orchard.save_game()
	var orchard_restored := FarmGameState.new()
	orchard_restored.save_path = orchard.save_path
	orchard_restored.backup_path = orchard.backup_path
	check(orchard_restored.load_game(), "kebun buah tetap tersedia setelah restart")
	check(
		(
			orchard_restored.orchard[0]["fruit"] == "jeruk"
			and orchard_restored.orchard[1]["fruit"] == "apel"
		),
		"jenis pohon tersimpan di kedua petak"
	)
	check(
		orchard_restored.orchard[0]["ready_at"] == orchard.orchard[0]["ready_at"],
		"waktu tumbuh pohon tersimpan untuk panen offline"
	)
	check(
		orchard_restored.inventory["jeruk"] == 2 and orchard_restored.market_listings.size() == 1,
		"stok dan lapak buah bertahan setelah restart"
	)
	# Expansion: new crops, livestock, buildings, decoration and backward-compatible saves.
	var expanded := FarmGameState.new()
	expanded.save_path = "user://kebun_ceria_expansion_test.json"
	expanded.backup_path = "user://kebun_ceria_expansion_test_backup.json"
	expanded.new_game()
	check(FarmGameState.CROP_ORDER.size() == 13, "tiga belas jenis tanaman tersedia")
	check(FarmGameState.PRODUCT_ORDER.size() == 13, "tiga belas resep produksi tersedia")
	check(not expanded.buy_seeds("kedelai", 0), "pembelian nol bibit ditolak")
	check(not expanded.buy_seeds("padi", 1), "padi terkunci sebelum naik level")
	expanded.level = 6
	expanded.coins = 10000
	for index in 4:
		var crop_id: String = ["kedelai", "kentang", "labu", "padi"][index]
		check(expanded.buy_seeds(crop_id, 1), "bibit %s dapat dibeli" % crop_id)
		check(expanded.plant(index, crop_id), "%s dapat ditanam" % crop_id)
		expanded.plots[index]["ready_at"] = expanded.now() - 1
		check(expanded.harvest(index) == 3, "%s menghasilkan tiga panen" % crop_id)
	check(not expanded.buy_construction("tak_dikenal"), "bangunan invalid ditolak")
	check(expanded.buy_construction("kandang_babi"), "kandang babi berhasil dibeli")
	check(not expanded.buy_construction("kandang_babi"), "kandang babi tidak dapat dibeli dua kali")
	check(expanded.buy_construction("kandang_kambing"), "kandang kambing berhasil dibeli")
	check(not expanded.feed_animal("palsu"), "hewan tidak dikenal ditolak")
	expanded.inventory["jagung"] = 0
	expanded.inventory["kedelai"] = 0
	check(not expanded.can_feed_animal("babi"), "babi perlu stok pakan")
	check(expanded.missing_animal_feed("babi") == {"jagung": 2, "kedelai": 1}, "kekurangan pakan babi dijelaskan per bahan")
	expanded.inventory["jagung"] = 3
	expanded.inventory["kedelai"] = 1
	check(expanded.missing_animal_feed("babi").is_empty() and expanded.can_feed_animal("babi"), "tombol pakan aktif ketika bahan sudah lengkap")
	check(expanded.feed_animal("babi"), "babi memakan jagung dan kedelai")
	check(expanded.missing_animal_feed("babi").is_empty(), "pakan tidak dianggap kurang ketika hewan sedang produksi")
	check(
		expanded.inventory["jagung"] == 1 and expanded.inventory["kedelai"] == 0,
		"pakan babi terpotong tepat"
	)
	check(not expanded.feed_animal("babi"), "babi tidak diberi makan saat proses")
	check(not expanded.collect_animal("babi"), "babi belum siap tidak bisa dipanen")
	expanded.livestock["babi"] = expanded.now() - 1
	expanded.storage_capacity = expanded.storage_used() + 1
	check(not expanded.collect_animal("babi"), "gudang penuh menolak panen babi")
	expanded.storage_capacity = 100
	check(expanded.collect_animal("babi"), "babi menghasilkan dua bahan")
	check(
		expanded.inventory["daging_babi"] == 2 and expanded.animal_hungry("babi"),
		"hasil babi masuk gudang"
	)
	expanded.inventory["wortel"] = 2
	expanded.inventory["gandum"] = 2
	check(expanded.feed_animal("kambing"), "kambing menerima pakan")
	expanded.livestock["kambing"] = expanded.now() - 1
	check(expanded.collect_animal("kambing"), "kambing menghasilkan susu")
	check(expanded.inventory["susu_kambing"] == 2, "susu kambing masuk gudang")
	check(expanded.buy_construction("toko_roti"), "rumah roti berhasil dibeli")
	check(expanded.buy_construction("pabrik_susu"), "rumah susu berhasil dibeli")
	expanded.inventory["gandum"] = 5
	check(expanded.queue_product("roti"), "roti diproduksi di rumah roti")
	check(
		(
			(
				int(expanded.production_queue[0]["ready_at"])
				- int(expanded.production_queue[0]["started_at"])
			)
			== 26
		),
		"rumah roti mempersingkat produksi 20 persen"
	)
	expanded.production_queue.clear()
	expanded.inventory["susu"] = 2
	check(expanded.queue_product("mentega"), "mentega dibuat dari susu")
	check(
		(
			(
				int(expanded.production_queue[0]["ready_at"])
				- int(expanded.production_queue[0]["started_at"])
			)
			== 48
		),
		"rumah susu mempersingkat produksi 20 persen"
	)
	expanded.production_queue[0]["ready_at"] = expanded.now() - 1
	check(
		expanded.collect_product() and expanded.inventory["mentega"] == 1,
		"mentega matang bisa diambil"
	)
	for index in 3:
		check(
			expanded.buy_construction("petak_bunga"), "taman bunga %d berhasil dibeli" % (index + 1)
		)
	check(not expanded.buy_construction("petak_bunga"), "dekorasi dibatasi tiga petak")
	for decoration in ["gazebo", "kincir_angin", "kolam"]:
		check(expanded.buy_construction(decoration), "%s dapat dibangun" % decoration)
	expanded.save_game()
	var expanded_copy := FarmGameState.new()
	expanded_copy.save_path = expanded.save_path
	expanded_copy.backup_path = expanded.backup_path
	check(expanded_copy.load_game(), "save ekspansi dimuat kembali")
	check(
		(
			expanded_copy.construction_count("petak_bunga") == 3
			and expanded_copy.has_construction("kandang_babi")
		),
		"bangunan tetap tersimpan"
	)
	check(
		expanded_copy.inventory["susu_kambing"] == 2 and expanded_copy.inventory["mentega"] == 1,
		"produk baru tetap tersimpan"
	)
	var expansion_legacy: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(expanded.save_path)
	)
	expansion_legacy.erase("livestock")
	expansion_legacy.erase("constructions")
	var expansion_legacy_file := FileAccess.open(expanded.save_path, FileAccess.WRITE)
	expansion_legacy_file.store_string(JSON.stringify(expansion_legacy))
	expansion_legacy_file.close()
	var expanded_old := FarmGameState.new()
	expanded_old.save_path = expanded.save_path
	expanded_old.backup_path = expanded.backup_path
	check(expanded_old.load_game(), "save lama tanpa ternak dan bangunan tetap dapat dimuat")
	check(
		(
			expanded_old.construction_count("kandang_babi") == 0
			and expanded_old.livestock["babi"] == 0
		),
		"save lama memakai default ternak"
	)
	# Feed mill: unlock, FIFO offline timer, warehouse, cow/pig/goat lifecycle, and legacy save.
	var feed_test := FarmGameState.new()
	feed_test.save_path = "user://kebun_ceria_feed_mill_test.json"
	feed_test.backup_path = "user://kebun_ceria_feed_mill_test_backup.json"
	feed_test.new_game()
	check(not feed_test.buy_construction("pabrik_pakan") and not feed_test.queue_feed("pakan_sapi"), "pabrik pakan dan produksi terkunci di level satu")
	feed_test.inventory["gandum"] = 2
	feed_test.inventory["jagung"] = 1
	check(feed_test.feed_cow() and feed_test.inventory["gandum"] == 0 and feed_test.inventory["jagung"] == 0, "sapi pemain baru tetap bisa diberi hasil panen langsung")
	check(feed_test.onboarding_step == 0, "alur pakan sapi tidak mengganggu tutorial awal")
	feed_test.new_game()
	feed_test.level = 2
	feed_test.coins = 189
	check(not feed_test.buy_construction("pabrik_pakan"), "pembelian pabrik ditolak jika koin kurang")
	feed_test.coins = 500
	check(feed_test.buy_construction("pabrik_pakan") and feed_test.coins == 310, "pabrik pakan dibeli seharga 190 koin di level dua")
	check(not feed_test.buy_construction("pabrik_pakan"), "pabrik pakan tidak dapat dibeli dua kali")
	feed_test.inventory["gandum"] = 10
	feed_test.inventory["jagung"] = 10
	feed_test.inventory["kedelai"] = 10
	feed_test.inventory["wortel"] = 10
	check(not feed_test.can_queue_feed("pakan_kambing"), "resep kambing tetap terkunci sebelum level tiga")
	feed_test.level = 3
	feed_test.coins = 1000
	check(feed_test.buy_construction("kandang_babi") and feed_test.buy_construction("kandang_kambing"), "kandang ternak uji pakan berhasil dibangun")
	check(feed_test.queue_feed("pakan_sapi") and feed_test.queue_feed("pakan_babi") and feed_test.queue_feed("pakan_kambing"), "tiga resep pakan masuk antrean")
	check(feed_test.feed_queue.size() == 3 and feed_test.feed_queue[1]["started_at"] >= feed_test.feed_queue[0]["ready_at"] and feed_test.feed_queue[2]["started_at"] >= feed_test.feed_queue[1]["ready_at"], "antrean pakan berjalan FIFO tanpa tumpang tindih timer")
	check(feed_test.inventory["gandum"] == 5 and feed_test.inventory["jagung"] == 5 and feed_test.inventory["kedelai"] == 8 and feed_test.inventory["wortel"] == 7, "setiap resep memotong bahan baku tepat")
	check(not feed_test.queue_feed("pakan_sapi") and not feed_test.collect_feed(), "antrean penuh dan produksi belum matang tidak bisa diklaim")
	# Advance timestamps as if the player closed the app for 200 seconds.
	for task in feed_test.feed_queue:
		task["started_at"] = int(task["started_at"]) - 200
		task["ready_at"] = int(task["ready_at"]) - 200
	feed_test.save_game()
	var offline_feed := FarmGameState.new()
	offline_feed.save_path = feed_test.save_path
	offline_feed.backup_path = feed_test.backup_path
	check(offline_feed.load_game() and offline_feed.feed_queue.size() == 3 and offline_feed.feed_ready(), "tiga timer pakan tetap matang setelah save/load offline")
	offline_feed.storage_capacity = offline_feed.storage_used() + 1
	check(not offline_feed.collect_feed() and offline_feed.feed_queue.size() == 3, "gudang penuh menahan paket siap tanpa menghilangkan antrean")
	offline_feed.storage_capacity = 60
	check(offline_feed.collect_feed() and offline_feed.inventory["pakan_sapi"] == 2 and offline_feed.feed_queue.size() == 2, "klaim pakan sapi memberi dua paket")
	var gandum_before_cow: int = offline_feed.inventory["gandum"]
	var jagung_before_cow: int = offline_feed.inventory["jagung"]
	check(offline_feed.feed_cow() and offline_feed.inventory["pakan_sapi"] == 1 and offline_feed.inventory["gandum"] == gandum_before_cow and offline_feed.inventory["jagung"] == jagung_before_cow, "sapi mengonsumsi satu paket sebelum memakai panen mentah")
	offline_feed.cow_ready_at = offline_feed.now() - 1
	check(offline_feed.collect_milk() and offline_feed.inventory["susu"] == 2 and not offline_feed.collect_milk(), "sapi diberi pakan menghasilkan susu sekali saja")
	check(offline_feed.collect_feed() and offline_feed.inventory["pakan_babi"] == 2, "klaim kedua mengeluarkan pakan babi sesuai FIFO")
	var jagung_before_pig: int = offline_feed.inventory["jagung"]
	check(offline_feed.feed_animal("babi") and offline_feed.inventory["pakan_babi"] == 1 and offline_feed.inventory["jagung"] == jagung_before_pig, "babi memakan satu paket tanpa mengurangi bahan mentah")
	offline_feed.livestock["babi"] = offline_feed.now() - 1
	check(offline_feed.collect_animal("babi") and offline_feed.inventory["daging_babi"] == 2, "pakan babi menghasilkan daging")
	check(offline_feed.collect_feed() and offline_feed.inventory["pakan_kambing"] == 2 and offline_feed.feed_queue.is_empty(), "klaim ketiga mengeluarkan pakan kambing dan mengosongkan antrean")
	var wortel_before_goat: int = offline_feed.inventory["wortel"]
	check(offline_feed.feed_animal("kambing") and offline_feed.inventory["pakan_kambing"] == 1 and offline_feed.inventory["wortel"] == wortel_before_goat, "kambing memakan paket tanpa mengurangi wortel")
	offline_feed.livestock["kambing"] = offline_feed.now() - 1
	check(offline_feed.collect_animal("kambing") and offline_feed.inventory["susu_kambing"] == 2 and not offline_feed.collect_feed(), "pakan kambing menghasilkan susu dan klaim kosong ditolak")
	offline_feed.save_game()
	var restored_feed := FarmGameState.new()
	restored_feed.save_path = feed_test.save_path
	restored_feed.backup_path = feed_test.backup_path
	check(restored_feed.load_game() and restored_feed.inventory["pakan_sapi"] == 1 and restored_feed.inventory["pakan_babi"] == 1 and restored_feed.inventory["pakan_kambing"] == 1 and restored_feed.feed_queue.is_empty(), "inventori pakan dan antrean tersimpan benar setelah restart")
	var legacy_feed_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(feed_test.save_path))
	legacy_feed_data.erase("feed_queue")
	for feed_id in FarmGameState.FEED_ORDER:
		legacy_feed_data["inventory"].erase(feed_id)
	var legacy_feed_file := FileAccess.open(feed_test.save_path, FileAccess.WRITE)
	legacy_feed_file.store_string(JSON.stringify(legacy_feed_data))
	legacy_feed_file.close()
	var legacy_feed := FarmGameState.new()
	legacy_feed.save_path = feed_test.save_path
	legacy_feed.backup_path = feed_test.backup_path
	check(legacy_feed.load_game() and legacy_feed.feed_queue.is_empty(), "save lama tanpa feed_queue tetap dimuat")
	check(legacy_feed.inventory["pakan_sapi"] == 0 and legacy_feed.inventory["pakan_babi"] == 0 and legacy_feed.inventory["pakan_kambing"] == 0, "save lama tanpa kunci paket diberi stok nol")
	legacy_feed.new_game()
	check(legacy_feed.feed_queue.is_empty() and legacy_feed.inventory["pakan_sapi"] == 0 and not legacy_feed.has_construction("pabrik_pakan"), "permainan baru mereset antrean dan bangunan pakan")
	kitchen.save_game()
	var legacy_data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(kitchen.save_path)
	)
	legacy_data.erase("production_queue")
	legacy_data.erase("cow_ready_at")
	legacy_data.erase("daily_date")
	legacy_data.erase("daily_progress")
	legacy_data.erase("daily_claimed")
	legacy_data.erase("market_listings")
	legacy_data.erase("market_sales_count")
	legacy_data.erase("orchard")
	legacy_data.erase("order_refresh_until")
	legacy_data.erase("order_revision")
	legacy_data.erase("onboarding_step")
	legacy_data.erase("onboarding_plot_index")
	legacy_data.erase("onboarding_skipped")
	legacy_data["inventory"].erase("jeruk")
	legacy_data["inventory"].erase("apel")
	legacy_data["inventory"].erase("roti")
	legacy_data["inventory"].erase("popcorn")
	legacy_data["inventory"].erase("jus_wortel")
	legacy_data["inventory"].erase("susu")
	legacy_data["inventory"].erase("keju")
	var legacy_file := FileAccess.open(kitchen.save_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy_data))
	legacy_file.close()
	var legacy := FarmGameState.new()
	legacy.save_path = kitchen.save_path
	legacy.backup_path = kitchen.backup_path
	check(legacy.load_game(), "save lama tanpa data produksi tetap dapat dimuat")
	check(legacy.onboarding_step == 3, "save pemain lama tidak menampilkan onboarding baru")
	check(legacy.production_queue.is_empty(), "save lama dimulai dengan antrian kosong")
	check(legacy.inventory["roti"] == 0, "save lama memiliki stok produk baru default nol")
	check(legacy.cow_is_hungry(), "save lama otomatis memiliki sapi yang belum diberi pakan")
	check(legacy.daily_progress["panen"] == 0, "save lama memiliki misi harian baru")
	check(not legacy.daily_claimed["produksi"], "save lama tidak menandai misi diklaim")
	check(legacy.market_listings.is_empty(), "save lama memiliki lapak kosong")
	check(legacy.market_sales_count == 0, "save lama memiliki statistik pasar nol")
	check(
		legacy.order_refresh_until == [0, 0, 0] and legacy.order_revision == 0,
		"save lama tanpa data penggantian kontrak memakai nilai default",
	)
	check(legacy.orchard.size() == 2, "save lama menghasilkan dua petak pohon valid")
	check(legacy.orchard[0]["fruit"] == "", "save lama tidak gagal karena tidak ada pohon")
	check(legacy.inventory["jeruk"] == 0, "save lama menambahkan stok jeruk nol")
	check(
		legacy.inventory["susu"] == 0 and legacy.inventory["keju"] == 0,
		"save lama aman tanpa susu dan keju"
	)
	check(game.ensure_daily_tasks("2000-01-01"), "tanggal lain mengatur ulang misi")
	check(game.daily_claimed_count() == 0, "klaim direset saat pergantian hari")
	check(game.daily_progress["panen"] == 0, "progres direset saat pergantian hari")
	check(not game.ensure_daily_tasks(), "pembacaan jumlah klaim sudah memulihkan misi tanggal lokal")
	check(not game.ensure_daily_tasks(), "pemeriksaan berulang tidak menghapus progres")
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = "user://kebun_ceria_ui_test.json"
	screen.game.backup_path = "user://kebun_ceria_ui_test_backup.json"
	root.add_child(screen)
	await process_frame
	check(
		absf(screen.farm.position.y + screen.farm.size.y - screen.navbar.position.y) < 1.0,
		"peta mengisi ruang hingga navigasi bawah tanpa area kosong",
	)
	var virtual_map_size: Vector2 = screen.farm.get_virtual_size()
	check(
		is_equal_approx(
			screen.farm.size.x / virtual_map_size.x, screen.farm.size.y / virtual_map_size.y
		),
		"peta tetap proporsional setelah diperpanjang",
	)
	check(not screen.action_panel.visible, "panel petak tersembunyi saat masuk kebun")
	screen.call("on_plot_pressed", 0)
	check(screen.action_panel.visible, "mengetuk petak membuka panel aksi")
	screen.farm.blank_pressed.emit()
	check(not screen.action_panel.visible, "mengetuk area kosong menutup panel aksi")
	for tab_id in ["pasar", "gudang", "produksi"]:
		# A new farm keeps zero-stock items collapsed in the barn. Supply a
		# temporary, realistically populated barn for the scrolling regression.
		var temporary_barn_stock: Dictionary = {}
		if tab_id == "gudang":
			for item_id in screen.game.inventory:
				if temporary_barn_stock.size() >= 8:
					break
				temporary_barn_stock[item_id] = screen.game.inventory[item_id]
				screen.game.inventory[item_id] = maxi(1, int(screen.game.inventory[item_id]))
		screen.call("switch_tab", tab_id)
		await process_frame
		var list_scroll: ScrollContainer = screen.sheet.find_child("ContentScroll", true, false)
		check(
			list_scroll.get_v_scroll_bar().max_value > list_scroll.size.y,
			"daftar %s menyediakan area scroll vertikal" % tab_id,
		)
		list_scroll.scroll_vertical = 140
		check(list_scroll.scroll_vertical > 0, "daftar %s dapat digeser" % tab_id)
		screen.call("refresh_all")
		await process_frame
		var restored_scroll: ScrollContainer = screen.sheet.find_child("ContentScroll", true, false)
		check(
			restored_scroll.scroll_vertical > 0,
			"posisi scroll %s bertahan setelah pembaruan" % tab_id
		)
		for item_id in temporary_barn_stock:
			screen.game.inventory[item_id] = temporary_barn_stock[item_id]
	screen.call("switch_tab", "pesanan")
	check(screen.order_refresh_rows.size() == 3, "panel pesanan memiliki tiga tombol ganti")
	screen.game.orders[0]["items"] = {"gandum": 4}
	screen.game.inventory["gandum"] = 1
	screen.call("switch_tab", "pesanan")
	var order_bars: Array = screen.sheet.find_children("OrderProgressTrack*", "Panel", true, false)
	check(order_bars.size() == 3, "panel pesanan memiliki tiga indikator progres")
	if order_bars.size() == 3:
		var first_bar: Panel = order_bars[0]
		var first_fill: Panel = first_bar.get_node("OrderProgressFill")
		check(
			is_equal_approx(first_fill.size.x / first_bar.size.x, 0.25),
			"indikator pesanan menampilkan 25 persen"
		)
	var progress_game := FarmGameState.new()
	progress_game.new_game()
	check(progress_game.order_progress(-1) == 0.0, "progres pesanan invalid adalah nol")
	check(progress_game.order_progress(0) == 0.0, "pesanan kosong belum memiliki progres")
	progress_game.inventory["gandum"] = 2
	check(is_equal_approx(progress_game.order_progress(0), 0.5), "progres pesanan sebagian")
	progress_game.inventory["gandum"] = 8
	check(progress_game.order_progress(0) == 1.0, "progres pesanan dibatasi 100 persen")
	progress_game.orders[0]["items"] = {"gandum": 4, "jagung": 2}
	progress_game.inventory["jagung"] = 1
	check(
		is_equal_approx(progress_game.order_progress(0), 5.0 / 6.0),
		"progres kontrak gabungan menghitung tiap barang"
	)
	var refresh_button: Button = screen.order_refresh_rows[0]["button"]
	check(not refresh_button.disabled, "tombol ganti aktif jika koin cukup")
	screen.game.coins = 0
	screen.call("refresh_order_buttons")
	check(refresh_button.disabled, "tombol ganti nonaktif jika koin tidak cukup")
	screen.call("switch_tab", "kebun_buah")
	check(screen.orchard_status_rows.size() == 1, "panel buah menampilkan pohon aktif")
	screen.call("switch_tab", "gudang")
	check(screen.active_tab == "gudang", "panel gudang tetap dapat dibuka")
	screen.call("switch_tab", "ternak")
	check(
		screen.active_tab == "ternak" and screen.animal_status_rows.size() == 3,
		"peternakan menampilkan ayam, babi, kambing"
	)
	screen.call("switch_tab", "bangun")
	check(screen.active_tab == "bangun", "panel bangun dan dekorasi dapat dibuka")
	screen.call("switch_tab", "pakan")
	check(screen.active_tab == "pakan" and screen.feed_status_text == null, "panel pakan belum dibangun mengarahkan pemain ke menu Bangun")
	var ui_feed_level: int = screen.game.level
	screen.game.level = 3
	screen.game.constructions["pabrik_pakan"] = 1
	screen.game.inventory["gandum"] = 10
	screen.game.inventory["jagung"] = 10
	screen.call("switch_tab", "pakan")
	check(screen.feed_status_text != null and screen.feed_collect_button != null, "pabrik pakan menampilkan antrean dan tombol klaim")
	screen.call("on_queue_feed", "pakan_sapi")
	check(screen.game.feed_queue.size() == 1 and screen.feed_status_text.text.contains("Pakan Sapi"), "panel pakan dapat memulai produksi nyata")
	screen.game.feed_queue[0]["ready_at"] = screen.game.now() - 1
	screen.call("refresh_feed_status")
	check(not screen.feed_collect_button.disabled and screen.feed_collect_button.text.contains("AMBIL PAKAN"), "tombol klaim aktif ketika timer selesai")
	var ready_feed_badge: Vector2 = screen.farm.object_position("pakan") + FarmView.READY_MARKERS["pakan"]["offset"]
	check(screen.farm.ready_marker_at(ready_feed_badge) == "pakan", "pabrik menampilkan penanda pakan siap di peta")
	screen.call("switch_tab", "kebun")
	check(screen.farm.handle_ready_marker_touch(ready_feed_badge) and screen.active_tab == "pakan", "ketuk tanda pakan siap membuka pabrik")
	screen.call("on_collect_feed")
	check(screen.game.inventory["pakan_sapi"] == 2 and screen.game.feed_queue.is_empty(), "tombol UI klaim memindahkan dua paket ke gudang")
	screen.call("switch_tab", "kebun")
	check(screen.farm.handle_shortcut_touch(screen.farm.object_position("pakan")) and screen.active_tab == "pakan", "ketuk gedung pakan membuka panel produksinya")
	screen.game.feed_queue.clear()
	screen.game.constructions.erase("pabrik_pakan")
	screen.game.level = ui_feed_level
	screen.call("switch_tab", "kebun")
	check(
		screen.farm.handle_shortcut_touch(Vector2(330, 818)) and screen.active_tab == "bangun",
		"papan BANGUN di kebun membuka panel pembangunan"
	)
	screen.call("switch_tab", "kebun")
	check(
		screen.farm.handle_shortcut_touch(Vector2(1750, 818)) and screen.active_tab == "ternak",
		"papan TERNAK di kebun membuka panel peternakan"
	)
	check(
		not screen.farm.handle_shortcut_touch(Vector2(400, 1332)),
		"kandang babi belum dibeli tidak menerima sentuhan"
	)
	screen.game.constructions["kandang_babi"] = 1
	screen.call("switch_tab", "kebun")
	check(
		screen.farm.handle_shortcut_touch(Vector2(395, 1480)) and screen.active_tab == "ternak",
		"kandang babi terbangun bisa diketuk"
	)
	screen.game.constructions["kandang_kambing"] = 1
	screen.call("switch_tab", "kebun")
	check(
		(
			screen.farm.handle_shortcut_touch(FarmView.GOAT_PEN_CENTER)
			and screen.active_tab == "ternak"
		),
		"kandang kambing terbangun bisa diketuk"
	)
	screen.game.constructions["toko_roti"] = 1
	screen.call("switch_tab", "kebun")
	check(
		screen.farm.handle_shortcut_touch(Vector2(673, 590)) and screen.active_tab == "produksi",
		"rumah roti terbangun membuka produksi"
	)
	screen.call("switch_tab", "kebun")
	check(
		screen.farm.handle_shortcut_touch(Vector2(673, 476)) and screen.active_tab == "produksi",
		"atap rumah roti baru dapat diketuk"
	)
	screen.game.constructions["pabrik_susu"] = 1
	screen.call("switch_tab", "kebun")
	check(
		screen.farm.handle_shortcut_touch(Vector2(1510, 510)) and screen.active_tab == "produksi",
		"rumah susu terbangun membuka produksi"
	)
	screen.call("switch_tab", "kebun")
	check(
		screen.farm.handle_shortcut_touch(Vector2(1510, 405)) and screen.active_tab == "produksi",
		"atap rumah susu baru dapat diketuk"
	)
	var camera: FarmView = screen.farm
	screen.call("switch_tab", "kebun")
	# The ready markers follow real production timers and route world taps to the right panel.
	var kitchen_badge := camera.object_position("dapur") + Vector2(0, -186)
	var cow_badge := camera.object_position("sapi") + Vector2(125, -156)
	var pig_badge := camera.object_position("babi") + Vector2(75, -145)
	var goat_badge := camera.object_position("kambing") + Vector2(75, -145)
	screen.game.production_queue.clear()
	screen.game.cow_ready_at = 0
	screen.game.livestock["babi"] = 0
	screen.game.livestock["kambing"] = 0
	check(camera.ready_marker_at(kitchen_badge) == "" and camera.ready_marker_at(cow_badge) == "", "indikator produksi dan sapi tersembunyi sebelum siap")
	check(camera.ready_marker_at(pig_badge) == "" and camera.ready_marker_at(goat_badge) == "", "indikator ternak tersembunyi sebelum siap")
	screen.game.production_queue.append({"product": "roti", "started_at": screen.game.now(), "ready_at": screen.game.now() + 20})
	check(camera.ready_marker_at(kitchen_badge) == "", "indikator dapur menunggu waktu produksi")
	screen.game.production_queue[0]["ready_at"] = screen.game.now() - 1
	screen.game.cow_ready_at = screen.game.now() - 1
	screen.game.livestock["babi"] = screen.game.now() - 1
	screen.game.livestock["kambing"] = screen.game.now() - 1
	check(camera.ready_marker_at(kitchen_badge) == "dapur" and camera.ready_marker_at(cow_badge) == "sapi", "indikator dapur dan susu aktif sesudah matang")
	check(camera.ready_marker_at(pig_badge) == "babi" and camera.ready_marker_at(goat_badge) == "kambing", "indikator babi dan kambing aktif sesudah matang")
	var old_capacity: int = screen.game.storage_capacity
	screen.game.storage_capacity = 0
	check(camera.ready_marker_at(kitchen_badge) == "dapur", "hasil siap tetap diberi tanda ketika gudang penuh")
	screen.game.storage_capacity = old_capacity
	for item in [
		["dapur", kitchen_badge, "produksi"], ["sapi", cow_badge, "sapi"],
		["babi", pig_badge, "ternak"], ["kambing", goat_badge, "ternak"]
	]:
		screen.call("switch_tab", "kebun")
		var world_at: Vector2 = item[1]
		var badge_screen := (world_at - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
		camera.activate_at(badge_screen)
		check(screen.active_tab == item[2], "ketuk indikator %s membuka panel %s" % [item[0], item[2]])
	# Relocating the pen changes both the visual anchor and the hit area.
	screen.game.layout_positions["babi"] = [2350, 1900]
	check(camera.ready_marker_at(pig_badge) == "" and camera.ready_marker_at(Vector2(2425, 1755)) == "babi", "indikator mengikuti kandang babi yang dipindahkan")
	camera.edit_mode = true
	check(camera.ready_marker_at(kitchen_badge) == "", "mode atur mengabaikan tap indikator")
	camera.edit_mode = false
	screen.game.layout_positions.erase("babi")
	screen.game.production_queue.clear()
	screen.game.cow_ready_at = 0
	screen.game.livestock["babi"] = 0
	screen.game.livestock["kambing"] = 0
	check(camera.ready_marker_at(kitchen_badge) == "" and camera.ready_marker_at(cow_badge) == "" and camera.ready_marker_at(pig_badge) == "", "indikator hilang setelah hasil dikosongkan")
	screen.call("switch_tab", "kebun")
	check(screen.visitor_shortcut.visible, "tombol tamu selalu terlihat pada kebun")
	check(screen.visitor_shortcut.text.contains("TAMU DATANG"), "tombol tamu menampilkan kedatangan")
	screen.visitor_shortcut.pressed.emit()
	check(screen.active_tab == "pengunjung", "tombol tamu membuka permintaan dari kebun")
	check(not screen.visitor_shortcut.visible, "tombol tamu tidak menutupi panel")
	screen.call("switch_tab", "kebun")
	var visitor_at := camera.visitor_world_position()
	var visitor_touch := (visitor_at - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	camera.activate_at(visitor_touch)
	check(screen.active_tab == "pengunjung", "ketuk pengunjung di samping pasar membuka tawaran")
	check(screen.sheet != null and screen.sheet.find_child("ContentScroll", true, false) != null, "panel tawaran pengunjung mempunyai konten")
	screen.game.inventory["gandum"] = 2
	screen.call("refresh_all")
	check(screen.game.visitor_can_sell(), "tombol pengunjung dapat diaktifkan saat gudang cukup")
	screen.call("on_visitor_sell")
	check(screen.game.visitor_request.is_empty() and screen.active_tab == "pengunjung", "penjualan pengunjung menampilkan status tunggu")
	check(is_instance_valid(screen.visitor_status_text), "panel pengunjung menampilkan hitung mundur")
	screen.call("switch_tab", "kebun")
	check(screen.visitor_shortcut.visible and screen.visitor_shortcut.text.begins_with("TAMU "), "hitung mundur tamu terlihat sesudah transaksi")
	screen.call("toggle_arrange_mode")
	check(not screen.visitor_shortcut.visible, "tombol tamu tidak menutupi alat atur")
	screen.call("toggle_arrange_mode")
	check(screen.visitor_shortcut.visible, "tombol tamu kembali setelah mengatur")
	# Feedback is transient, capped for Android, and never mutates farm state.
	var plots_before_feedback: Array = screen.game.plots.duplicate(true)
	var inventory_before_feedback: Dictionary = screen.game.inventory.duplicate(true)
	camera.visual_feedback.clear()
	camera.show_plot_feedback(-1, "plant")
	camera.show_orchard_feedback(FarmGameState.ORCHARD_SIZE, "harvest", 3)
	check(camera.visual_feedback.is_empty(), "feedback mengabaikan indeks petak dan kebun invalid")
	camera.show_plot_feedback(0, "plant")
	check(camera.visual_feedback.size() == 1 and camera.visual_feedback[0]["at"] == camera.plot_center(0), "efek tanam muncul tepat pada petak")
	camera.show_orchard_feedback(0, "harvest", 3)
	check(camera.visual_feedback.back()["text"] == "+3", "efek panen buah menunjukkan jumlah hasil")
	for feedback_index in 14:
		camera.show_world_feedback("plant", Vector2(300 + feedback_index, 600))
	check(camera.visual_feedback.size() == 12, "antrian efek visual dibatasi 12")
	check(screen.game.plots == plots_before_feedback and screen.game.inventory == inventory_before_feedback, "efek visual tidak mengubah data permainan")
	camera._process(1.1)
	check(camera.visual_feedback.is_empty(), "efek visual hilang otomatis setelah sekitar satu detik")
	# The painted loading depot is a shortcut to the real order panel.
	screen.call("switch_tab", "kebun")
	var depot_sign := FarmView.DELIVERY_DOCK + Vector2(-90, -115)
	var depot_touch := (depot_sign - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	camera.activate_at(depot_touch)
	check(screen.active_tab == "pesanan", "mengetuk papan depot pengiriman membuka pesanan")
	# Only a successful transaction starts the truck. The animation cannot
	# grant a second reward when it completes or returns to the loading dock.
	screen.game.orders[0]["items"] = {"gandum": 4}
	screen.game.inventory["gandum"] = 4
	var deliveries_before_truck: int = screen.game.deliveries
	screen.call("send_delivery", 0)
	check(screen.game.deliveries == deliveries_before_truck + 1, "pesanan dari depot memberi hadiah satu kali")
	check(is_zero_approx(camera.delivery_elapsed), "truk mulai berangkat setelah pengiriman berhasil")
	var depot_position := camera.delivery_truck_position()
	camera._process(1.1)
	check(camera.delivery_truck_position().x > depot_position.x + 200.0, "truk pengiriman bergerak meninggalkan depot")
	camera._process(5.6)
	check(camera.delivery_elapsed < 0.0 and camera.delivery_truck_position() == depot_position, "truk kembali parkir sesudah animasi")
	check(screen.game.deliveries == deliveries_before_truck + 1, "animasi truk tidak menggandakan hadiah")
	screen.call("send_delivery", -1)
	check(camera.delivery_elapsed < 0.0, "pengiriman gagal tidak menjalankan animasi truk")
	screen.call("switch_tab", "kebun")
	var motion_before := LivestockPainter.animal_motion(camera, 1.2, Vector2(21, 11))
	camera.shimmer += 3.0
	var motion_after := LivestockPainter.animal_motion(camera, 1.2, Vector2(21, 11))
	check(
		(motion_before["offset"] as Vector2).distance_to(motion_after["offset"]) > 0.1,
		"hewan ternak berpindah posisi seiring waktu"
	)
	check(
		(
			absf((motion_after["offset"] as Vector2).x) <= 21.01
			and absf((motion_after["offset"] as Vector2).y) <= 11.01
		),
		"hewan ternak tetap berada di dalam area geraknya"
	)
	var initial_bounds := camera.accessible_world()
	screen.game.plots[8]["unlocked"] = true
	check(
		camera.accessible_world().size.x > initial_bounds.size.x,
		"kamera membuka batas baru saat petak lahan dibeli"
	)
	screen.game.plots[8]["unlocked"] = false
	camera.reset_camera()
	check(
		camera.screen_to_world(camera.size * 0.5).distance_to(camera.camera_center) < 0.01,
		"koordinat dunia benar di tengah kamera"
	)
	var pivot := Vector2(250, 330)
	var center_offset := (
		pivot * camera.get_virtual_size() / camera.size - camera.get_virtual_size() * 0.5
	)
	var anchor_before: Vector2 = camera.camera_target + center_offset / camera.zoom_target
	camera.zoom_at(pivot, 1.3)
	var anchor_after: Vector2 = camera.camera_target + center_offset / camera.zoom_target
	check(anchor_before.distance_to(anchor_after) < 0.02, "zoom tetap berpusat pada titik jari")
	camera.reset_camera()
	var starting_camera := camera.camera_target
	camera.pan_by(Vector2(110, 65))
	check(camera.camera_target.distance_to(starting_camera) > 50, "drag menggeser target kamera")
	camera.camera_target = Vector2(-9999, 9999)
	camera.clamp_camera_target()
	var view_half := camera.get_virtual_size() / (2.0 * camera.zoom_target)
	check(
		(
			camera.camera_target.x >= initial_bounds.position.x + view_half.x
			and camera.camera_target.y <= initial_bounds.end.y - view_half.y
		),
		"kamera tidak keluar dari batas lahan"
	)
	camera.reset_camera()
	screen.call("switch_tab", "kebun")
	var field_location := camera.plot_center(4)
	var field_screen := (
		(
			(field_location - camera.camera_center)
			* camera.camera_zoom
			* camera.size
			/ camera.get_virtual_size()
		)
		+ camera.size * 0.5
	)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = field_screen
	camera.handle_screen_touch(touch)
	touch.pressed = false
	camera.handle_screen_touch(touch)
	check(screen.selected_plot == 4, "tap setelah transform kamera memilih petak yang benar")
	touch.pressed = true
	camera.handle_screen_touch(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = field_screen + Vector2(180, 80)
	camera.handle_screen_drag(drag)
	touch.pressed = false
	touch.position = drag.position
	camera.handle_screen_touch(touch)
	check(screen.selected_plot == 4, "geser kamera tidak dianggap sebagai tap petak")
	camera.reset_camera()
	# Farm swipes commit only on release; the same swipe must work on touch and mouse.
	screen.game.new_game()
	screen.game.selected_crop = "gandum"
	var ripe_wheat_at := camera.plot_center(5)
	var ripe_corn_at := camera.plot_center(6)
	var ripe_wheat_screen := (ripe_wheat_at - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var ripe_corn_screen := (ripe_corn_at - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var wheat_before := int(screen.game.inventory["gandum"])
	var corn_before := int(screen.game.inventory["jagung"])
	touch.pressed = true
	touch.position = ripe_wheat_screen
	camera.handle_screen_touch(touch)
	drag.position = ripe_corn_screen
	camera.handle_screen_drag(drag)
	check(screen.game.is_ready(5) and screen.game.is_ready(6), "usap belum memanen sebelum jari dilepas")
	camera.handle_screen_drag(drag)
	check(camera.swipe_active and camera.swipe_mode == "harvest", "pratinjau usap panen aktif selama sentuhan")
	check(camera.swipe_indices.has(5) and camera.swipe_indices.has(6) and camera.swipe_indices.size() == 2, "pratinjau hanya menandai petak panen yang memenuhi syarat tanpa duplikasi")
	check(not camera.can_swipe_plot(7) and not camera.can_swipe_plot(0), "usap panen melewati petak yang masih tumbuh atau kosong")
	touch.pressed = false
	touch.position = ripe_corn_screen
	camera.handle_screen_touch(touch)
	check(not camera.swipe_active and camera.swipe_indices.is_empty(), "pratinjau usap panen hilang setelah pelepasan")
	check(screen.game.plots[5]["crop"] == "" and screen.game.plots[6]["crop"] == "", "usap cepat memanen dua petak berbeda")
	check(int(screen.game.inventory["gandum"]) == wheat_before + 2 and int(screen.game.inventory["jagung"]) == corn_before + 2, "usap tidak memberi panen ganda untuk petak yang dilewati berulang")
	var empty_from := (camera.plot_center(0) - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var empty_to := (camera.plot_center(1) - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var mouse_press := InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.position = empty_from
	mouse_press.pressed = true
	camera._gui_input(mouse_press)
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = empty_to
	mouse_motion.relative = empty_to - empty_from
	camera._gui_input(mouse_motion)
	camera._gui_input(mouse_motion)
	check(screen.game.plots[0]["crop"] == "" and screen.game.plots[1]["crop"] == "", "usap mouse belum menanam sebelum klik dilepas")
	check(camera.swipe_active and camera.swipe_mode == "plant" and camera.swipe_indices.size() == 2, "pratinjau tanam mouse menandai dua petak")
	check(not camera.can_swipe_plot(7) and not camera.can_swipe_plot(8), "usap tanam tidak memilih petak yang masih tumbuh atau terkunci")
	mouse_press.pressed = false
	mouse_press.position = empty_to
	camera._gui_input(mouse_press)
	check(not camera.swipe_active and camera.swipe_indices.is_empty(), "pratinjau tanam terhapus setelah klik dilepas")
	check(screen.game.plots[0]["crop"] == "gandum" and screen.game.plots[1]["crop"] == "gandum", "usap mouse menanam dua petak sekaligus")
	check(int(screen.game.seeds["gandum"]) == 6, "usap menanam tidak mengurangi bibit berulang")
	var saved_swipe := FarmGameState.new()
	saved_swipe.save_path = screen.game.save_path
	saved_swipe.backup_path = screen.game.backup_path
	check(saved_swipe.load_game() and saved_swipe.plots[0]["crop"] == "gandum" and saved_swipe.plots[6]["crop"] == "", "hasil usap disimpan dan dapat dimuat kembali")
	screen.game.new_game()
	touch.pressed = true
	touch.position = ripe_wheat_screen
	camera.handle_screen_touch(touch)
	drag.position = ripe_corn_screen
	camera.handle_screen_drag(drag)
	var cancel_finger := InputEventScreenTouch.new()
	cancel_finger.index = 1
	cancel_finger.pressed = true
	cancel_finger.position = Vector2(380, 260)
	camera.handle_screen_touch(cancel_finger)
	check(not camera.swipe_active and camera.swipe_mode == "" and camera.swipe_indices.is_empty(), "jari kedua menghapus seluruh pratinjau usap")
	touch.pressed = false
	touch.position = ripe_corn_screen
	camera.handle_screen_touch(touch)
	cancel_finger.pressed = false
	camera.handle_screen_touch(cancel_finger)
	check(screen.game.is_ready(5) and screen.game.is_ready(6), "pinch membatalkan usap panen sebelum diterapkan")
	var growing_from := (camera.plot_center(7) - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var pan_target_before := camera.camera_target
	touch.pressed = true
	touch.position = growing_from
	camera.handle_screen_touch(touch)
	drag.position = growing_from + Vector2(-170, -65)
	camera.handle_screen_drag(drag)
	touch.pressed = false
	touch.position = drag.position
	camera.handle_screen_touch(touch)
	check(camera.camera_target.distance_to(pan_target_before) > 30.0, "geser dari petak tumbuh tetap menggerakkan kamera")
	camera.reset_camera()
	var finger_a := InputEventScreenTouch.new()
	finger_a.index = 0
	finger_a.position = Vector2(220, 250)
	finger_a.pressed = true
	camera.handle_screen_touch(finger_a)
	var finger_b := InputEventScreenTouch.new()
	finger_b.index = 1
	finger_b.position = Vector2(420, 250)
	finger_b.pressed = true
	camera.handle_screen_touch(finger_b)
	var pinch := InputEventScreenDrag.new()
	pinch.index = 1
	pinch.position = Vector2(500, 250)
	camera.handle_screen_drag(pinch)
	check(camera.zoom_target > 0.75, "pinch dua jari memperbesar kamera")
	finger_b.pressed = false
	camera.handle_screen_touch(finger_b)
	finger_a.pressed = false
	camera.handle_screen_touch(finger_a)
	check(camera.pointers.is_empty(), "status sentuhan pulih setelah pinch")
	# Moving a planted field must keep its harvest state and survive restarting the game.
	camera.reset_camera()
	screen.game.new_game()
	check(screen.game.plant(4, "gandum"), "petak bisa ditanami sebelum dipindahkan")
	screen.call("toggle_arrange_mode")
	check(camera.edit_mode, "tombol ATUR membuka mode pemindahan")
	var original_plot := camera.plot_center(4)
	var moved_plot := Vector2(1600, 1080)
	var plot_screen := (original_plot - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var destination_screen := (moved_plot - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	camera.begin_edit_drag(plot_screen)
	check(camera.drag_key == "petak_4", "petak dipilih saat disentuh di mode ATUR")
	camera.move_edit_drag(destination_screen)
	camera.finish_edit_drag()
	check(camera.plot_center(4).distance_to(moved_plot) < 2.0, "petak pertanian berhasil dipindahkan")
	check(camera.visual_feedback.back()["kind"] == "move", "pemindahan valid memunculkan efek sukses")
	check(screen.game.plots[4]["crop"] == "gandum", "gandum tetap tumbuh saat petaknya dipindahkan")
	var moved_plot_screen := (moved_plot - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var occupied := camera.plot_center(5)
	var occupied_screen := (occupied - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	camera.begin_edit_drag(moved_plot_screen)
	camera.move_edit_drag(occupied_screen)
	camera.finish_edit_drag()
	check(camera.plot_center(4).distance_to(moved_plot) < 2.0, "petak tidak boleh ditumpuk pada petak lain")
	check(camera.visual_feedback.back()["kind"] == "reject", "pemindahan terhalang memunculkan efek penolakan")
	check(not camera.can_place("petak_4", Vector2(-50, -50)), "petak di luar area ditolak")
	var original_pen := camera.object_position("sapi")
	var moved_pen := Vector2(1750, 900)
	var pen_screen := (original_pen - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var pen_dest_screen := (moved_pen - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	camera.begin_edit_drag(pen_screen)
	check(camera.drag_key == "sapi", "kandang sapi bisa dipilih dalam mode ATUR")
	camera.move_edit_drag(pen_dest_screen)
	camera.finish_edit_drag()
	check(camera.object_position("sapi").distance_to(moved_pen) < 2.0, "kandang sapi berhasil dipindahkan")
	var saved_layout := FarmGameState.new()
	saved_layout.save_path = screen.game.save_path
	saved_layout.backup_path = screen.game.backup_path
	check(saved_layout.load_game(), "layout baru bisa dimuat ulang")
	check(saved_layout.layout_positions.has("petak_4") and saved_layout.layout_positions.has("sapi"), "lokasi petak dan kandang disimpan permanen")
	check(saved_layout.plots[4]["crop"] == "gandum", "status tanaman tersimpan bersama layout")
	# Roads are painted continuously on a grid and saved when a stroke finishes.
	screen.select_road_tool("draw")
	check(camera.road_tool == "draw" and screen.road_tool_buttons["draw"].visible, "kuas jalan tersedia di mode ATUR")
	camera.camera_center = Vector2(2370, 1320)
	camera.camera_target = camera.camera_center
	var road_from := Vector2(2280, 1320)
	var road_to := Vector2(2600, 1320)
	var road_from_screen := (road_from - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var road_to_screen := (road_to - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	var road_touch := InputEventScreenTouch.new()
	road_touch.index = 0
	road_touch.position = road_from_screen
	road_touch.pressed = true
	camera.handle_screen_touch(road_touch)
	var road_drag := InputEventScreenDrag.new()
	road_drag.index = 0
	road_drag.position = road_to_screen
	camera.handle_screen_drag(road_drag)
	road_touch.pressed = false
	road_touch.position = road_to_screen
	camera.handle_screen_touch(road_touch)
	check(screen.game.road_tiles.has("28,16") and screen.game.road_tiles.has("32,16"), "jalan tergambar sepanjang sapuan jari")
	check(screen.game.road_tiles.has("29,16") and screen.game.road_tiles.has("30,16") and screen.game.road_tiles.has("31,16"), "ruas jalan tersambung tanpa celah")
	check(not camera.can_paint_road(camera.road_cell_from_world(camera.object_position("dapur"))), "jalan tidak boleh menimpa bangunan")
	var roads_saved := FarmGameState.new()
	roads_saved.save_path = screen.game.save_path
	roads_saved.backup_path = screen.game.backup_path
	check(roads_saved.load_game() and roads_saved.road_tiles.has("30,16"), "jalan tetap ada setelah game dimuat ulang")
	screen.select_road_tool("erase")
	camera.begin_road_stroke(road_from_screen)
	camera.extend_road_stroke(road_to_screen)
	camera.finish_road_stroke()
	check(not screen.game.road_tiles.has("28,16") and not screen.game.road_tiles.has("32,16"), "kuas HAPUS membersihkan jalan")
	check(roads_saved.load_game() and roads_saved.road_tiles.is_empty(), "penghapusan jalan disimpan permanen")
	screen.select_road_tool("pan")
	check(camera.road_tool == "pan", "mode GESER mengaktifkan navigasi peta")
	screen.call("toggle_arrange_mode")
	check(not camera.edit_mode, "tombol SELESAI menutup mode pemindahan")
	camera.reset_camera()
	camera.activate_at(pen_dest_screen)
	check(screen.active_tab == "sapi", "kandang yang sudah dipindah tetap bisa diketuk")
	check(FarmView.WORLD_SIZE.x >= 3500.0 and FarmView.WORLD_SIZE.y >= 2800.0, "peta diperluas")
	check(camera.WILD_TREES.size() >= 20, "pohon liar tersedia di peta")
	check(camera.ujang_patrol_points().size() >= 5, "Ujang berpatroli memantau peternakan dan pertanian")
	check(is_equal_approx(FarmView.UJANG_SCALE, 0.8), "ukuran Ujang berkurang 20 persen")
	var walker := FarmView.new()
	walker.game = FarmGameState.new()
	walker.ujang_position = Vector2(650, 845)
	var plot_route := walker.ujang_route_to(Vector2(1550, 845))
	check(plot_route.size() >= 3, "Ujang memilih rute memutar ketika petak menutup jalan langsung")
	var safe_route := true
	for path_index in range(1, plot_route.size()):
		if not walker.ujang_segment_clear(plot_route[path_index - 1], plot_route[path_index]):
			safe_route = false
	check(safe_route, "semua segmen rute berada di luar petak tanaman")
	walker.ujang_patrol_index = 1
	walker.ujang_pause = 0.0
	var never_steps_on_crops := true
	var walked_distance := 0.0
	for frame in 180:
		if frame == 45:
			walker.game.layout_positions["petak_0"] = [770, 1140]
		var previous_position := walker.ujang_position
		walker.update_ujang(0.2)
		walked_distance += previous_position.distance_to(walker.ujang_position)
		if walker.ujang_point_blocked(walker.ujang_position):
			never_steps_on_crops = false
	check(never_steps_on_crops, "Ujang tidak menginjak petak selama berpatroli meski layout berubah")
	check(walked_distance > 150.0, "Ujang tetap bergerak setelah menghindari tanaman")
	check(walker.ujang_point_blocked(walker.object_position("dapur")), "Ujang menghindari area rumah/dapur")
	check(walker.ujang_point_blocked(walker.object_position("gudang")), "Ujang menghindari gudang")
	check(walker.ujang_point_blocked(walker.object_position("sapi")), "Ujang menghindari kandang sapi")
	check(walker.ujang_point_blocked(walker.object_position("ayam")), "Ujang menghindari kandang ayam")
	check(walker.ujang_point_blocked(walker.orchard_center(0)), "Ujang menghindari pohon buah besar")
	var standing_tree: Vector2 = FarmView.WILD_TREES[0]
	check(walker.ujang_point_blocked(standing_tree), "Ujang menghindari pohon liar yang masih berdiri")
	check(not walker.ujang_segment_clear(standing_tree + Vector2(-90, 0), standing_tree + Vector2(90, 0)), "rute lurus tidak menembus pohon besar")
	walker.game.cleared_wild_trees.append(0)
	check(not walker.ujang_point_blocked(standing_tree), "bekas pohon yang ditebang kembali bisa dilewati")
	walker.game.cleared_wild_trees.erase(0)
	var old_layout: String = walker.ujang_obstacle_snapshot()
	walker.game.layout_positions["dapur"] = [2380, 1380]
	check(walker.ujang_point_blocked(Vector2(2380, 1380)), "rumah yang dipindahkan tetap menjadi rintangan")
	check(old_layout != walker.ujang_obstacle_snapshot(), "perubahan posisi bangunan memicu pembaruan rute")
	walker.free()
	var tapped_animals: Array[String] = []
	camera.animal_tapped.connect(func(kind: String) -> void: tapped_animals.append(kind))
	var cow_screen := (camera.object_position("sapi") - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	camera.activate_at(cow_screen)
	check(tapped_animals.has("sapi"), "ketuk kandang sapi memicu suara sapi")
	var chicken_screen := (camera.object_position("ayam") - camera.camera_center) * camera.camera_zoom * camera.size / camera.get_virtual_size() + camera.size * 0.5
	camera.activate_at(chicken_screen)
	check(tapped_animals.has("ayam"), "ketuk kandang ayam memicu suara ayam")
	check(screen.animal_audio.stream != null, "berkas audio hewan berhasil dimuat")
	for kind in ["babi", "kambing"]:
		screen.play_animal_sound(kind)
		check(
			screen.animal_audio.stream != null
			and screen.animal_audio.stream.resource_path.ends_with("%s.ogg" % ("pig" if kind == "babi" else "goat")),
			"suara %s tersedia saat kandang diketuk" % kind
		)
	check(screen.ANIMAL_SOUND_MAX_SECONDS < 3.0, "batas suara hewan kurang dari tiga detik")
	await create_timer(2.90).timeout
	check(not screen.animal_audio.playing, "suara kambing berhenti otomatis sebelum tiga detik")
	screen.play_animal_sound("ayam")
	check(screen.animal_audio.stream.get_length() < 3.0, "rekaman ayam secara fisik lebih pendek dari tiga detik")
	var first_chicken_generation: int = screen.animal_sound_generation
	screen.play_animal_sound("ayam")
	check(screen.animal_sound_generation == first_chicken_generation, "ketuk ayam beruntun tidak memperpanjang suara")
	await create_timer(2.88).timeout
	check(not screen.animal_audio.playing, "suara ayam berhenti sebelum tiga detik")
	var coins_before_tree: int = screen.game.coins
	var xp_before_tree: int = screen.game.xp
	var tree_id := 0
	check(camera.wild_tree_at(FarmView.WILD_TREES[tree_id]) == tree_id, "pohon liar bisa diketuk")
	var axe_hits := [0]
	camera.wild_tree_struck.connect(func() -> void: axe_hits[0] += 1)
	camera.ujang_position = FarmView.WILD_TREES[tree_id] + Vector2(450, 24)
	check(camera.start_chopping(tree_id), "Ujang mulai menebang pohon liar")
	check(camera.visual_feedback.back()["kind"] == "target", "target pohon diberi penanda sentuhan")
	var ujang_before_walk: Vector2 = camera.ujang_position
	camera.update_ujang(0.25)
	check(camera.ujang_walking and camera.ujang_position.distance_to(ujang_before_walk) > 0.0, "Ujang berjalan mendekati pohon")
	check(axe_hits[0] == 0, "suara kapak belum diputar saat Ujang berjalan")
	camera.ujang_position = FarmView.WILD_TREES[tree_id] + Vector2(57, 24)
	camera.update_ujang(0.65)
	check(camera.chopping_tree == tree_id and camera.chop_progress > 0.0, "animasi ayunan kapak berlangsung sebelum pohon jatuh")
	check(camera.visual_feedback.back()["kind"] == "chop_hit", "efek pukulan kapak selaras dengan ayunan")
	check(axe_hits[0] == 2, "dua suara kapak mengikuti dua ayunan pertama")
	check(screen.axe_audio.stream != null and screen.axe_audio.stream.get_length() <= 0.5, "efek suara kapak berhasil dimuat")
	check(not screen.game.cleared_wild_trees.has(tree_id), "pohon tetap berdiri selama animasi tebang")
	camera.update_ujang(1.35)
	check(camera.visual_feedback.back()["kind"] == "chop_done" and camera.visual_feedback.back()["text"] == "+6", "pohon tumbang memberi efek hadiah enam koin")
	check(axe_hits[0] == 3, "tiga ketukan kapak selesai sebelum pohon tumbang")
	check(screen.game.cleared_wild_trees.has(tree_id), "pohon hilang setelah animasi tebang selesai")
	check(screen.game.coins == coins_before_tree + 6, "tebang pohon memberi enam koin")
	check(screen.game.xp >= xp_before_tree + 3, "tebang pohon memberi XP")
	check(not camera.start_chopping(tree_id), "pohon yang ditebang tidak dapat ditebang ulang")
	var tree_saved := FarmGameState.new()
	tree_saved.save_path = screen.game.save_path
	tree_saved.backup_path = screen.game.backup_path
	check(tree_saved.load_game() and tree_saved.cleared_wild_trees.has(tree_id), "pohon yang ditebang tetap hilang setelah load")
	screen.game.new_game()
	check(screen.game.cleared_wild_trees.is_empty(), "permainan baru mengembalikan pohon liar")
	screen.call("switch_tab", "kebun")
	screen.call("refresh_all")
	check(screen.tutorial_panel.visible and screen.tutorial_title.text.contains("1/3"), "UI pemain baru menampilkan langkah pertama dan progres")
	var orders_guide_badge: Control = null
	for nav_tab in screen.navbar.get_children():
		if nav_tab.has_meta("tab_id") and nav_tab.get_meta("tab_id") == "pesanan":
			orders_guide_badge = nav_tab.get_node_or_null("GuideBadge") as Control
			break
	check(orders_guide_badge != null, "tab PESANAN menyediakan penanda panduan")
	check(screen.farm.guide_plot_index == 5 and screen.farm.guide_plot_action == "harvest", "langkah pertama menyorot petak gandum yang dapat dipanen")
	if orders_guide_badge:
		check(not orders_guide_badge.visible, "penanda PESANAN belum muncul saat tahap panen")
	screen.call("on_plot_pressed", 5)
	screen.call("on_harvest_or_speed")
	check(screen.game.onboarding_step == 1 and screen.tutorial_title.text.contains("2/3"), "UI panen gandum beralih ke langkah tanam ulang")
	check(screen.farm.guide_plot_index == 5 and screen.farm.guide_plot_action == "plant", "langkah kedua menyorot petak yang harus ditanam ulang")
	screen.call("on_plant")
	check(screen.game.onboarding_step == 2 and screen.tutorial_title.text.contains("3/3"), "UI tanam ulang beralih ke langkah PESANAN")
	check(screen.farm.guide_plot_index == -1, "penanda petak hilang setelah tanam ulang")
	if orders_guide_badge:
		check(orders_guide_badge.visible, "penanda PESANAN menyala saat tahap membuka pesanan")
	screen.call("switch_tab", "pesanan")
	check(screen.game.onboarding_step == 3 and not screen.tutorial_panel.visible, "UI buka PESANAN menutup tutorial")
	if orders_guide_badge:
		check(not orders_guide_badge.visible, "penanda PESANAN hilang setelah panduan selesai")
	screen.game.new_game()
	screen.call("switch_tab", "kebun")
	screen.call("refresh_all")
	var tutorial_skip_button := screen.tutorial_panel.get_node("TutorialSkip") as Button
	tutorial_skip_button.pressed.emit()
	check(screen.game.onboarding_skipped and not screen.tutorial_panel.visible, "tombol LEWATI menghentikan panduan")
	check(screen.farm.guide_plot_index == -1, "melewati panduan menghapus sorotan petak")
	if orders_guide_badge:
		check(not orders_guide_badge.visible, "melewati panduan tidak meninggalkan penanda PESANAN")
	screen.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tutorial.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tutorial.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(visitors.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(visitors.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(contracts.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(contracts.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(harvest_guard.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(harvest_guard.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sale.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sale.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(economy.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(economy.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(kitchen.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(kitchen.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dairy.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dairy.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(market.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(market.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(orchard.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(orchard.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(expanded.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(expanded.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(feed_test.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(feed_test.backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://kebun_ceria_ui_test.json"))
	DirAccess.remove_absolute(
		ProjectSettings.globalize_path("user://kebun_ceria_ui_test_backup.json")
	)
	print("TOTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
