extends SceneTree

# Isolated UI regression: counts ready contracts and guides missing goods.
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, description: String) -> void:
	if condition:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func run_tests() -> void:
	var unique := str(Time.get_ticks_usec())
	var screen: Control = load("res://scenes/Main.tscn").instantiate()
	screen.game.save_path = "user://order_guidance_" + unique + ".json"
	screen.game.backup_path = "user://order_guidance_" + unique + "_backup.json"
	root.add_child(screen)
	await process_frame
	screen.game.new_game()
	screen.game.onboarding_step = FarmGameState.ONBOARDING_COMPLETE
	screen.game.orders[0]["items"] = {"gandum": 3}
	screen.game.orders[1]["items"] = {"roti": 2}
	screen.game.orders[2]["items"] = {"susu": 1}
	screen.game.inventory["gandum"] = 3
	screen.game.inventory["roti"] = 0
	screen.game.inventory["susu"] = 0
	screen.refresh_all()
	var badge := screen.navbar.find_child("ReadyBadge", true, false) as Panel
	check(badge != null, "Navigasi memiliki indikator pesanan siap")
	if badge:
		check(badge.visible, "Indikator muncul ketika ada satu pesanan siap")
		check((badge.get_node("Count") as Label).text == "1", "Indikator menghitung satu kontrak siap")
	screen.switch_tab("pesanan")
	check(screen.farm.panel_obscured, "Redraw berkala kebun dijeda ketika panel terbuka")
	if badge:
		check(not badge.visible, "Indikator tidak menumpuk saat papan pesanan terbuka")
	var next_step := screen.sheet.find_child("OrderSupply1", true, false) as Button
	check(next_step != null, "Pesanan roti kekurangan stok memiliki pintasan cari bahan")
	if next_step:
		next_step.pressed.emit()
		check(screen.active_tab == "produksi", "Pintasan roti membuka dapur produksi")
	check(screen.order_supply_tab("gandum") == "kebun", "Tanaman menuju kebun")
	check(screen.order_supply_tab("jeruk") == "kebun_buah", "Buah menuju kebun buah")
	check(screen.order_supply_tab("susu") == "sapi", "Susu menuju kandang sapi")
	check(screen.order_supply_tab("daging_babi") == "ternak", "Hasil hewan menuju peternakan")
	check(screen.order_supply_tab("pakan_sapi") == "pakan", "Pakan menuju pabrik pakan")
	screen.game.inventory["roti"] = 2
	screen.game.inventory["susu"] = 1
	screen.refresh_all()
	if badge:
		check((badge.get_node("Count") as Label).text == "3", "Indikator diperbarui setelah stok lengkap")
	screen.switch_tab("pesanan")
	check(
		screen.sheet.find_child("OrderSupply1", true, false) == null,
		"Pintasan disembunyikan jika stok lengkap"
	)
	var ready_labels := 0
	for item in screen.sheet.find_children("*", "Label", true, false):
		if item.text == "✓ BARANG LENGKAP • TEKAN KIRIM":
			ready_labels += 1
	check(ready_labels == 3, "Semua pesanan lengkap diberi instruksi kirim")
	screen.game.orders[0]["items"] = {}
	screen.switch_tab("kebun")
	check(not screen.farm.panel_obscured, "Animasi kebun dilanjutkan saat panel ditutup")
	if badge:
		check((badge.get_node("Count") as Label).text == "2", "Kontrak kosong tidak dianggap siap")
	var paths := [screen.game.save_path, screen.game.backup_path]
	screen.queue_free()
	await process_frame
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TOTAL FAILURES: ", failures)
	quit(1 if failures > 0 else 0)
