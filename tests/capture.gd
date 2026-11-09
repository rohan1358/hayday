extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	# Never use or overwrite a real player's progress while generating previews.
	var preview_game: FarmGameState = main.get("game")
	preview_game.save_path = "user://kebun_ceria_preview_only.json"
	preview_game.backup_path = "user://kebun_ceria_preview_only_backup.json"
	preview_game.new_game()
	root.add_child(main)
	await create_timer(0.5).timeout
	var toast: Control = main.get("toast_layer")
	toast.hide()
	await create_timer(0.15).timeout
	var farm_result := save_preview("res://preview.png")
	main.call("switch_tab", "misi")
	await create_timer(0.4).timeout
	var mission_result := save_preview("res://preview_misi.png")
	main.call("switch_tab", "pesanan")
	await create_timer(0.4).timeout
	var orders_result := save_preview("res://preview_pesanan.png")
	main.call("switch_tab", "produksi")
	await create_timer(0.4).timeout
	var production_result := save_preview("res://preview_production.png")
	main.call("switch_tab", "sapi")
	await create_timer(0.4).timeout
	var dairy_result := save_preview("res://preview_sapi.png")
	main.call("switch_tab", "pasar")
	await create_timer(0.4).timeout
	var market_result := save_preview("res://preview_pasar.png")
	main.call("switch_tab", "pengunjung")
	await create_timer(0.4).timeout
	var visitor_result := save_preview("res://preview_pengunjung.png")
	main.call("switch_tab", "kebun_buah")
	await create_timer(0.4).timeout
	var orchard_result := save_preview("res://preview_buah.png")
	main.call("switch_tab", "ternak")
	await create_timer(0.4).timeout
	var animal_result := save_preview("res://preview_ternak.png")
	main.call("switch_tab", "bangun")
	await create_timer(0.4).timeout
	var build_result := save_preview("res://preview_bangun.png")
	# Verify production art in the world without purchasing or touching player saves.
	preview_game.constructions["toko_roti"] = 1
	preview_game.constructions["pabrik_susu"] = 1
	main.call("switch_tab", "kebun")
	var tutorial: Control = main.get("tutorial_panel")
	if tutorial != null:
		tutorial.hide()
	var farm_view: FarmView = main.get("farm")
	farm_view.camera_center = Vector2(1050, 640)
	farm_view.camera_target = farm_view.camera_center
	farm_view.queue_redraw()
	await create_timer(0.4).timeout
	var buildings_result := save_preview("res://preview_bangunan_produksi.png")
	# Render both optional pens in an isolated preview game to review art/placement.
	preview_game.constructions["kandang_babi"] = 1
	preview_game.constructions["kandang_kambing"] = 1
	farm_view.camera_center = Vector2(555, 1525)
	farm_view.camera_target = farm_view.camera_center
	farm_view.queue_redraw()
	await create_timer(0.4).timeout
	var pens_result := save_preview("res://preview_bangunan_ternak.png")
	quit(
		(
			0
			if (
				farm_result == OK
				and mission_result == OK
				and orders_result == OK
				and production_result == OK
				and dairy_result == OK
				and market_result == OK
				and visitor_result == OK
				and orchard_result == OK
				and animal_result == OK
				and build_result == OK
				and buildings_result == OK
				and pens_result == OK
			)
			else 1
		)
	)


func save_preview(output: String) -> int:
	var image := root.get_viewport().get_texture().get_image()
	var result := image.save_png(output)
	print("PREVIEW: ", ProjectSettings.globalize_path(output), " ", result, " ", image.get_size())
	return result
