extends Control

const INK := Color("344b39")
const SOFT_INK := Color("72806d")
const CREAM := Color("fff9e8")
const PAPER := Color("fffcf3")
const GREEN := Color("368d5b")
const MINT := Color("dbefce")
const GOLD := Color("e9b84b")
const PINK := Color("ef837b")
const HUD_GREEN := Color("26774e")
const HUD_TAB_IDLE := Color("f4f0dd")
const HUD_TAB_TEXT := Color("3f6547")
const TEXT_FORMAT := preload("res://scripts/game_text.gd")
const ANIMAL_SOUND_MAX_SECONDS := 2.65
const AXE_CHOP_SOUND := preload("res://assets/audio/axe_chop.wav")

var game := FarmGameState.new()
var farm: FarmView
var animal_audio: AudioStreamPlayer
var animal_sound_generation := 0
var animal_sound_deadline_ms := 0
var current_animal_sound_kind := ""
var axe_audio: AudioStreamPlayer
var ads: FarmAds
var ad_footer_reserved := 0.0
var ad_space: Panel
var selected_plot := 0
var active_tab := "kebun"
var action_panel: Panel
var navbar: Panel
var arrange_button: Button
var visitor_shortcut: Button
var activity_shortcut: Button
var activity_signature := ""
var road_tool_buttons: Dictionary = {}
var sheet: Control
var sheet_scroll: ScrollContainer
var sheet_scroll_positions: Dictionary = {}
var toast_layer: Control
var top_level_text: Label
var top_xp_text: Label
var top_coins_text: Label
var top_gems_text: Label
var xp_track: ProgressBar
var production_status_text: Label
var production_collect_button: Button
var feed_status_text: Label
var feed_collect_button: Button
var cow_status_text: Label
var cow_action_button: Button
var mission_header_button: Button
var timer_accum := 0.0
var android_profile_accum := 0.0
var market_time_labels: Array[Label] = []
var seed_recovery_button: Button
var seed_icon_textures: Dictionary = {}
var production_icon_textures: Dictionary = {}
var order_refresh_rows: Array[Dictionary] = []
var orchard_status_rows: Array[Dictionary] = []
var animal_status_rows: Array[Dictionary] = []
var visitor_status_text: Label
var seed_scroll_left := 0
var tutorial_panel: Panel
var tutorial_title: Label
var tutorial_hint: Label


func _ready() -> void:
	game.load_game()
	game.refresh_visitor()
	build_screen()
	ads = FarmAds.new()
	add_child(ads)
	ads.reward_granted.connect(_on_ad_reward_granted)
	ads.message_requested.connect(show_toast)
	ads.config_changed.connect(_sync_ad_footer)
	ads.visible_ad_changed.connect(_sync_ad_footer)
	_sync_ad_footer()
	ads.set_game_tab(active_tab)
	var offline_coins := game.settle_market_sales()
	refresh_all()
	# Optional diagnostic, enabled only on a debug Android install with an
	# explicit local flag. Normal gameplay never loads the layer profiler.
	if OS.get_name() == "Android" and OS.has_feature("debug") and FileAccess.file_exists("user://pm_render_probe.flag"):
		add_child(load("res://scripts/android_render_probe.gd").new())
	if offline_coins > 0:
		show_toast("Pembeli pasar membayar %d koin saat kamu pergi!" % offline_coins)
	elif game.first_visit:
		show_toast("Selamat datang! Panen tanaman siap, lalu mulai menanam!")


func _process(delta: float) -> void:
	# Wall-clock cutoff also applies if a scene timer runs late on a busy device.
	if animal_audio != null and animal_audio.playing and Time.get_ticks_msec() >= animal_sound_deadline_ms:
		animal_audio.stop()
	if OS.get_name() == "Android" and OS.has_feature("debug"):
		android_profile_accum += delta
		if android_profile_accum >= 15.0:
			android_profile_accum = 0.0
			print(
				"KEBUN_PERF fps=%d process_ms=%.2f draw_calls=%d static_mb=%.1f tab=%s" % [
					Engine.get_frames_per_second(),
					Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
					int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
					Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
					active_tab,
				]
			)
	timer_accum += delta
	if timer_accum > 0.9:
		timer_accum = 0.0
		if game.refresh_visitor():
			if active_tab == "kebun":
				farm.queue_redraw()
			update_visitor_shortcut()
			if active_tab == "pengunjung":
				show_sheet()
		update_visitor_shortcut()
		update_activity_shortcut()
		if active_tab == "aktivitas" and activity_signature != JSON.stringify(game.ready_activities()):
			show_sheet()
		var earned := game.settle_market_sales()
		if earned > 0:
			refresh_all()
			show_toast("Barang pasar terjual! +%d koin" % earned)
		if game.ensure_daily_tasks():
			game.save_game()
			refresh_all()
		if (
			active_tab == "kebun"
			and action_panel.visible
			and game.plots[selected_plot]["crop"] != ""
		):
			refresh_action()
		elif active_tab == "produksi":
			refresh_production_status()
		elif active_tab == "pakan":
			refresh_feed_status()
		elif active_tab == "sapi":
			refresh_cow_status()
		elif active_tab == "pasar":
			MarketUI.refresh_timers(game, market_time_labels)
		elif active_tab == "toko" and is_instance_valid(seed_recovery_button):
			var remaining := game.seed_recovery_seconds_left()
			if remaining == 0 and seed_recovery_button.disabled:
				show_sheet()
			else:
				seed_recovery_button.text = (
					"AMBIL 3 BIBIT GRATIS" if remaining == 0
					else "TUNGGU %d:%02d" % [int(remaining / 60), remaining % 60]
				)
		elif active_tab == "pesanan":
			refresh_order_buttons()
		elif active_tab == "kebun_buah":
			OrchardUI.refresh_status(game, orchard_status_rows)
		elif active_tab == "ternak":
			FarmExpansionUI.refresh_animals(game, animal_status_rows)
		elif active_tab == "pengunjung" and is_instance_valid(visitor_status_text):
			visitor_status_text.text = "Tamu berikutnya tiba dalam %d detik." % maxi(0, game.visitor_next_at - game.now())


func build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var backdrop := ColorRect.new()
	backdrop.color = CREAM
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	farm = FarmView.new()
	farm.game = game
	farm.selected_plot = selected_plot
	farm.anchor_left = 0.0
	farm.anchor_right = 1.0
	farm.anchor_top = 0.0
	farm.anchor_bottom = 1.0
	farm.offset_top = 146.0
	farm.offset_bottom = -125.0 - ad_footer_reserved
	add_child(farm)
	animal_audio = AudioStreamPlayer.new()
	animal_audio.volume_db = -4.0
	add_child(animal_audio)
	axe_audio = AudioStreamPlayer.new()
	axe_audio.volume_db = -3.0
	axe_audio.stream = AXE_CHOP_SOUND
	add_child(axe_audio)
	farm.plot_pressed.connect(on_plot_pressed)
	farm.farm_swipe_requested.connect(on_farm_swipe_requested)
	farm.blank_pressed.connect(hide_action_panel)
	farm.coop_pressed.connect(on_coop_pressed)
	farm.cow_pressed.connect(func() -> void: switch_tab("sapi"))
	farm.barn_pressed.connect(func() -> void: switch_tab("gudang"))
	farm.factory_pressed.connect(func() -> void: switch_tab("produksi"))
	farm.feed_mill_pressed.connect(func() -> void: switch_tab("pakan"))
	farm.missions_pressed.connect(func() -> void: switch_tab("misi"))
	farm.orders_pressed.connect(func() -> void: switch_tab("pesanan"))
	farm.market_pressed.connect(func() -> void: switch_tab("pasar"))
	farm.visitor_pressed.connect(func() -> void: switch_tab("pengunjung"))
	farm.orchard_pressed.connect(func(_index: int) -> void: switch_tab("kebun_buah"))
	farm.livestock_pressed.connect(func() -> void: switch_tab("ternak"))
	farm.constructions_pressed.connect(func() -> void: switch_tab("bangun"))
	farm.layout_changed.connect(on_object_moved)
	farm.decoration_placed.connect(on_decoration_placed)
	farm.roads_changed.connect(on_roads_changed)
	farm.placement_rejected.connect(func() -> void: show_toast("Tidak bisa menaruh objek di jalan, objek lain, atau luar peta."))
	farm.animal_tapped.connect(play_animal_sound)
	farm.wild_tree_started.connect(func() -> void: show_toast("Ujang sedang menuju pohon untuk menebangnya!"))
	farm.wild_tree_struck.connect(play_axe_chop_sound)
	farm.wild_tree_chopped.connect(on_wild_tree_chopped)

	build_header()
	arrange_button = button(self, "✥ ATUR", Vector2(532, 158), Vector2(171, 52), GREEN, Color.WHITE, 19)
	arrange_button.pressed.connect(toggle_arrange_mode)
	visitor_shortcut = button(
		self, "TAMU KEBUN", Vector2(352, 158), Vector2(170, 52),
		Color("fce6ae"), Color("71502c"), 17
	)
	visitor_shortcut.pressed.connect(func() -> void: switch_tab("pengunjung"))
	activity_shortcut = button(
		self, "AKTIVITAS  ›", Vector2(14, 158), Vector2(328, 52),
		Color("f7e3a0"), HUD_GREEN, 19
	)
	activity_shortcut.name = "ActivityShortcut"
	activity_shortcut.pressed.connect(func() -> void: switch_tab("aktivitas"))
	for spec in [
		["object", "OBJEK"], ["draw", "+ JALAN"],
		["erase", "- HAPUS"], ["pan", "GESER"]
	]:
		var tool_id: String = spec[0]
		var index := road_tool_buttons.size()
		var tool_button := button(self, spec[1], Vector2(14 + index * 128, 158), Vector2(120, 52), MINT, GREEN, 16)
		tool_button.pressed.connect(select_road_tool.bind(tool_id))
		road_tool_buttons[tool_id] = tool_button
	refresh_road_toolbar()
	action_panel = panel(
		self, Vector2(15, 926 - ad_footer_reserved), Vector2(690, 224), PAPER, 27, 8
	)
	action_panel.hide()
	build_navbar()
	build_tutorial()
	toast_layer = Control.new()
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(toast_layer)
	resized.connect(_sync_ad_footer)
	resize_screen_layout()


func resize_screen_layout() -> void:
	if farm == null or navbar == null:
		return
	var height := size.y
	if height <= 0.0:
		return
	farm.offset_bottom = -125.0 - ad_footer_reserved
	navbar.position.y = height - 125.0 - ad_footer_reserved
	action_panel.position.y = navbar.position.y - 229.0
	if ad_space:
		ad_space.position.y = height - ad_footer_reserved
		ad_space.size = Vector2(size.x, ad_footer_reserved)
	if sheet and active_tab != "kebun":
		var area_height := navbar.position.y - 160.0
		sheet.size.y = area_height
		var dim := sheet.get_child(0) as ColorRect
		dim.size.y = area_height
		var card := sheet.get_child(1) as Panel
		card.size.y = area_height - 42.0
		var scroll := card.get_node_or_null("ContentScroll") as ScrollContainer
		if scroll:
			scroll.size.y = card.size.y - 158.0


func toggle_arrange_mode() -> void:
	if farm.placement_decoration_key != "":
		farm.cancel_decoration_placement()
		farm.set_edit_mode(false)
		arrange_button.text = "✥ ATUR"
		refresh_road_toolbar()
		update_visitor_shortcut()
		show_toast("Pemasangan dibatalkan. Dekorasi tetap tersimpan di koleksi.")
		return
	farm.set_edit_mode(not farm.edit_mode)
	arrange_button.text = "✓ SELESAI" if farm.edit_mode else "✥ ATUR"
	refresh_road_toolbar()
	update_visitor_shortcut()
	update_activity_shortcut()
	action_panel.hide()
	if farm.edit_mode:
		show_toast("Pilih OBJEK, + JALAN, - HAPUS, atau GESER.")


func select_road_tool(tool_id: String) -> void:
	farm.set_road_tool(tool_id)
	refresh_road_toolbar()
	if tool_id == "draw":
		show_toast("Seret jari di lahan kosong untuk membuat jalan.")
	elif tool_id == "erase":
		show_toast("Seret jari di atas jalan untuk menghapusnya.")


func refresh_road_toolbar() -> void:
	update_activity_shortcut()
	for tool_id in road_tool_buttons:
		var control: Button = road_tool_buttons[tool_id]
		control.visible = farm.edit_mode and farm.placement_decoration_key == "" and active_tab == "kebun"
		var chosen: bool = farm.road_tool == str(tool_id)
		var bg: Color = GREEN if chosen else MINT
		var fg: Color = Color.WHITE if chosen else GREEN
		control.add_theme_stylebox_override("normal", style(bg, 17, 2))
		control.add_theme_stylebox_override("hover", style(bg.lightened(0.08), 17, 2))
		control.add_theme_stylebox_override("pressed", style(bg.darkened(0.08), 17))
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			control.add_theme_color_override(state, fg)


func on_roads_changed() -> void:
	farm.invalidate_scenery()
	game.save_game()


func on_object_moved(key: String, at: Vector2) -> void:
	if key.begins_with("dekor_"):
		if not game.set_decoration_position(key, at):
			show_toast("Posisi dekorasi tidak berhasil disimpan.")
			return
	else:
		game.layout_positions[key] = [at.x, at.y]
		game.save_game()
	farm.invalidate_scenery()
	show_toast("Posisi berhasil disimpan!")


func on_decoration_placed(key: String, at: Vector2) -> void:
	if not game.set_decoration_position(key, at):
		show_toast("Gagal menyimpan posisi dekorasi.")
		return
	farm.invalidate_scenery()
	arrange_button.text = "✓ SELESAI"
	refresh_road_toolbar()
	refresh_all()
	show_toast("Dekorasi terpasang! Gunakan ATUR untuk memindahkannya.")


func on_wild_tree_chopped(tree_id: int) -> void:
	if game.clear_wild_tree(tree_id):
		farm.invalidate_scenery()
		game.save_game()
		refresh_all()
		show_toast("Ujang menebang pohon liar! +6 koin dan +3 XP")


func play_axe_chop_sound() -> void:
	if axe_audio == null:
		return
	axe_audio.stop()
	axe_audio.play()


func play_animal_sound(kind: String) -> void:
	var files := {
		"ayam": "res://assets/audio/chicken.ogg",
		"sapi": "res://assets/audio/cow.ogg",
		"babi": "res://assets/audio/pig.ogg",
		"kambing": "res://assets/audio/goat.ogg"
	}
	if not files.has(kind) or animal_audio == null:
		return
	var now := Time.get_ticks_msec()
	# Rapid repeated taps on a coop must not stretch one reaction indefinitely.
	if kind == current_animal_sound_kind and now < animal_sound_deadline_ms:
		return
	var sound := load(files[kind]) as AudioStream
	if sound == null:
		return
	animal_sound_generation += 1
	var this_sound := animal_sound_generation
	current_animal_sound_kind = kind
	animal_sound_deadline_ms = now + int(ANIMAL_SOUND_MAX_SECONDS * 1000.0)
	animal_audio.stop()
	animal_audio.stream = sound
	animal_audio.play()
	# Every tapped animal is limited to a short reaction, including long recordings.
	get_tree().create_timer(ANIMAL_SOUND_MAX_SECONDS).timeout.connect(func() -> void:
		if is_instance_valid(animal_audio) and this_sound == animal_sound_generation:
			animal_audio.stop()
	)


func _sync_ad_footer() -> void:
	var footer := 0.0
	if ads:
		var ad_height_px := ads.get_visible_ad_height_in_pixels()
		var screen_width_px := float(DisplayServer.window_get_size().x)
		if ad_height_px > 0.0 and screen_width_px > 0.0:
			# The AdMob overlay is in Android pixels; our UI uses stretched Godot units.
			footer = ceilf(ad_height_px * size.x / screen_width_px)
	if is_equal_approx(footer, ad_footer_reserved):
		resize_screen_layout()
		return
	ad_footer_reserved = footer
	if ad_space:
		ad_space.queue_free()
		ad_space = null
	if footer > 0.0:
		ad_space = panel(
			self, Vector2(0, size.y - footer), Vector2(size.x, footer), Color("fff9e8"), 0
		)
		move_child(ad_space, toast_layer.get_index())
	resize_screen_layout()
	if OS.is_debug_build():
		print("FarmAds: footer canvas=%.1f, window width px=%.1f" % [footer, float(DisplayServer.window_get_size().x)])


func build_header() -> void:
	var header := panel(self, Vector2(0, 0), Vector2(720, 146), Color("fff9ea"), 0, 2)
	var stripe := ColorRect.new()
	stripe.color = Color("d1e5b5")
	stripe.position = Vector2(0, 141)
	stripe.size = Vector2(720, 5)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(stripe)
	label(header, "KEBUN CERIA", Vector2(24, 12), Vector2(324, 47), 34, HUD_GREEN, true)
	label(header, "Panen hari ini, ceria setiap hari", Vector2(26, 58), Vector2(320, 28), 17, HUD_TAB_TEXT)

	var lvl := panel(header, Vector2(24, 92), Vector2(80, 40), HUD_GREEN, 15, 2)
	top_level_text = label(lvl, "LV 1", Vector2(0, 7), Vector2(80, 27), 20, Color.WHITE, true)
	top_level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_track = ProgressBar.new()
	xp_track.show_percentage = false
	xp_track.position = Vector2(116, 116)
	xp_track.size = Vector2(202, 12)
	xp_track.max_value = 30
	xp_track.value = 0
	xp_track.add_theme_stylebox_override("background", style(Color("dae5ca"), 10))
	xp_track.add_theme_stylebox_override("fill", style(Color("efbe53"), 10))
	header.add_child(xp_track)
	top_xp_text = label(header, "0 / 30 XP", Vector2(116, 90), Vector2(202, 26), 17, HUD_TAB_TEXT, true)

	var coin_chip := panel(header, Vector2(350, 15), Vector2(180, 65), Color("fff0c5"), 20, 2)
	coin_chip.add_child(circle(Vector2(29, 33), 19, GOLD))
	label(coin_chip, "✦", Vector2(16, 17), Vector2(32, 34), 24, Color("85591c"), true)
	label(coin_chip, "KOIN", Vector2(57, 6), Vector2(116, 21), 15, Color("85591c"), true)
	top_coins_text = label(coin_chip, "400", Vector2(56, 25), Vector2(118, 36), 25, INK, true)

	var gem_chip := panel(header, Vector2(541, 15), Vector2(155, 65), Color("e6f0fa"), 20, 2)
	label(gem_chip, "◆", Vector2(13, 13), Vector2(43, 43), 32, Color("4a9ac0"), true)
	label(gem_chip, "PERMATA", Vector2(54, 6), Vector2(94, 21), 14, Color("4c7792"), true)
	top_gems_text = label(gem_chip, "12", Vector2(54, 25), Vector2(94, 36), 25, INK, true)

	mission_header_button = button(
		header,
		"★ MISI 0/3  ·  1 KLAIM  ›",
		Vector2(350, 91),
		Vector2(346, 41),
		Color("e3f0d5"),
		HUD_GREEN,
		18
	)
	mission_header_button.pressed.connect(func() -> void: switch_tab("misi"))


func build_navbar() -> void:
	navbar = panel(
		self, Vector2(0, 1155 - ad_footer_reserved), Vector2(720, 125), Color("fff9e9"), 21, 7
	)
	var navbar_rule := ColorRect.new()
	navbar_rule.color = Color("d1e5b5")
	navbar_rule.position = Vector2(21, 2)
	navbar_rule.size = Vector2(678, 3)
	navbar_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	navbar.add_child(navbar_rule)
	var entries := [
		["kebun", "KEBUN", "⌂"],
		["pesanan", "PESANAN", "≡"],
		["toko", "TOKO", "+"],
		["produksi", "PRODUKSI", "⚙"],
		["gudang", "GUDANG", "▣"],
	]
	for i in entries.size():
		var entry: Array = entries[i]
		var tab_id: String = entry[0]
		var tab := panel(navbar, Vector2(14 + 140 * i, 14), Vector2(132, 91), HUD_TAB_IDLE, 22)
		tab.set_meta("tab_id", tab_id)
		var icon_bg := panel(tab, Vector2(42, 8), Vector2(48, 47), Color("e0ecd5"), 23)
		icon_bg.name = "IconBg"
		icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := label(icon_bg, entry[2], Vector2(0, 1), Vector2(48, 44), 30, HUD_GREEN, true)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.name = "Symbol"
		var text_label := label(tab, entry[1], Vector2(2, 61), Vector2(128, 25), 17, HUD_TAB_TEXT, true)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.name = "Caption"
		var click := Button.new()
		click.flat = true
		click.position = Vector2.ZERO
		click.size = tab.size
		click.focus_mode = Control.FOCUS_NONE
		click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tab.add_child(click)
		click.pressed.connect(func() -> void: switch_tab(tab_id))
		tab.pivot_offset = tab.size * 0.5
		click.button_down.connect(func() -> void: animate_press(tab, true))
		click.button_up.connect(func() -> void: animate_press(tab, false))
		click.mouse_exited.connect(func() -> void: animate_press(tab, false))
		if tab_id == "pesanan":
			var guide_badge := panel(tab, Vector2(98, 1), Vector2(29, 29), Color("ffcc61"), 15, 2)
			guide_badge.name = "GuideBadge"
			guide_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var badge_label := label(guide_badge, "!", Vector2.ZERO, Vector2(29, 27), 21, HUD_GREEN, true)
			badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			guide_badge.hide()
			var ready_badge := panel(tab, Vector2(98, 1), Vector2(29, 29), GOLD, 15, 2)
			ready_badge.name = "ReadyBadge"
			ready_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ready_label := label(ready_badge, "", Vector2.ZERO, Vector2(29, 27), 19, HUD_GREEN, true)
			ready_label.name = "Count"
			ready_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ready_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ready_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ready_badge.hide()
	update_navbar()


func update_navbar() -> void:
	var ready_count := 0
	for order_index in game.orders.size():
		if not game.orders[order_index]["items"].is_empty() and game.order_can_fill(order_index):
			ready_count += 1
	for node in navbar.get_children():
		if not node.has_meta("tab_id"):
			continue
		var chosen: bool = node.get_meta("tab_id") == active_tab
		var tile_style := style(HUD_GREEN if chosen else HUD_TAB_IDLE, 22, 3 if chosen else 0)
		tile_style.border_color = Color("1e6543") if chosen else Color("e1dfc9")
		tile_style.set_border_width_all(2 if chosen else 1)
		node.add_theme_stylebox_override("panel", tile_style)
		var icon_bg := node.get_node("IconBg") as Panel
		icon_bg.add_theme_stylebox_override(
			"panel", style(Color("f3f7dc") if chosen else Color("e0ecd5"), 23)
		)
		var symbol := icon_bg.get_node("Symbol") as Label
		symbol.add_theme_color_override("font_color", HUD_GREEN)
		var caption := node.get_node("Caption") as Label
		caption.add_theme_color_override("font_color", Color.WHITE if chosen else HUD_TAB_TEXT)
		if node.has_node("GuideBadge"):
			node.get_node("GuideBadge").visible = (
				game.onboarding_step == 2 and active_tab == "kebun"
			)
			var ready_badge := node.get_node("ReadyBadge") as Panel
			ready_badge.visible = (
				game.onboarding_step >= FarmGameState.ONBOARDING_COMPLETE
				and ready_count > 0
				and active_tab != "pesanan"
			)
			(ready_badge.get_node("Count") as Label).text = str(ready_count)


func build_tutorial() -> void:
	tutorial_panel = panel(self, Vector2(19, 221), Vector2(682, 113), PAPER, 21, 5)
	# Only the skip button receives clicks. The farm remains interactive below the card.
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_title = label(tutorial_panel, "", Vector2(22, 12), Vector2(510, 29), 19, GREEN, true)
	tutorial_hint = label(tutorial_panel, "", Vector2(22, 42), Vector2(510, 63), 19, INK)
	tutorial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var skip := button(
		tutorial_panel, "LEWATI", Vector2(548, 34), Vector2(114, 51),
		Color("e5ecd9"), HUD_GREEN, 17
	)
	skip.name = "TutorialSkip"
	skip.mouse_filter = Control.MOUSE_FILTER_STOP
	skip.pressed.connect(on_skip_tutorial)
	refresh_tutorial()


func refresh_tutorial() -> void:
	if is_instance_valid(farm):
		farm.guide_plot_index = -1
		farm.guide_plot_action = ""
	if is_instance_valid(navbar):
		update_navbar()
	if not is_instance_valid(tutorial_panel):
		return
	tutorial_panel.visible = game.onboarding_step < FarmGameState.ONBOARDING_COMPLETE and active_tab == "kebun"
	if not tutorial_panel.visible:
		if not farm.panel_obscured:
			farm.queue_redraw()
		return
	match game.onboarding_step:
		0:
			tutorial_title.text = "PANDUAN 1/3  •  PANEN GANDUM"
			tutorial_hint.text = "Ketuk gandum yang matang (petak 6), lalu pilih PANEN SEKARANG."
			farm.guide_plot_index = 5
			farm.guide_plot_action = "harvest"
		1:
			tutorial_title.text = "PANDUAN 2/3  •  TANAM ULANG"
			tutorial_hint.text = "Ketuk petak %d yang kosong, pilih GANDUM lalu TANAM." % (game.onboarding_plot_index + 1)
			farm.guide_plot_index = game.onboarding_plot_index
			farm.guide_plot_action = "plant"
		2:
			tutorial_title.text = "PANDUAN 3/3  •  BUKA PESANAN"
			tutorial_hint.text = "Tekan tab PESANAN pada menu bawah untuk melihat pesanan pelanggan."
	if not farm.panel_obscured:
		farm.queue_redraw()


func on_skip_tutorial() -> void:
	game.skip_onboarding()
	refresh_tutorial()


func switch_tab(tab_id: String) -> void:
	if farm.edit_mode:
		farm.set_edit_mode(false)
		arrange_button.text = "✥ ATUR"
	refresh_road_toolbar()
	arrange_button.visible = tab_id == "kebun"
	save_sheet_scroll_position()
	active_tab = tab_id
	update_activity_shortcut()
	farm.set_panel_obscured(tab_id != "kebun")
	if tab_id == "pesanan":
		game.onboarding_open_orders()
	refresh_tutorial()
	update_visitor_shortcut()
	if ads:
		ads.set_game_tab(active_tab)
	update_navbar()
	if sheet != null:
		sheet.queue_free()
		sheet = null
	sheet_scroll = null
	if tab_id == "kebun":
		action_panel.hide()
		return
	action_panel.hide()
	show_sheet()
	if is_instance_valid(sheet):
		sheet.modulate.a = 0.0
		sheet.position.y += 14.0
		var reveal := sheet.create_tween().set_parallel(true)
		reveal.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		reveal.tween_property(sheet, "modulate:a", 1.0, 0.17)
		reveal.tween_property(sheet, "position:y", 148.0, 0.21)


func show_sheet() -> void:
	save_sheet_scroll_position()
	if sheet != null:
		sheet.queue_free()
	sheet_scroll = null
	production_status_text = null
	production_collect_button = null
	feed_status_text = null
	feed_collect_button = null
	cow_status_text = null
	cow_action_button = null
	market_time_labels.clear()
	seed_recovery_button = null
	order_refresh_rows.clear()
	orchard_status_rows.clear()
	animal_status_rows.clear()
	visitor_status_text = null
	var layer := Control.new()
	layer.position = Vector2(0, 148)
	layer.size = Vector2(720, navbar.position.y - 160.0)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)
	sheet = layer
	var dim := ColorRect.new()
	dim.color = Color(0.15, 0.32, 0.22, 0.48)
	dim.size = layer.size
	layer.add_child(dim)
	var card := panel(layer, Vector2(20, 16), Vector2(680, layer.size.y - 42.0), PAPER, 29, 8)
	var titles := {
		"aktivitas": ["AKTIVITAS KEBUN", "Semua hasil siap dan pekerjaan yang menunggu."],
		"misi": ["MISI & PRESTASI", "Tantangan harian dan pencapaian kebun."],
		"pesanan": ["PAPAN PESANAN", "Antar hasil panen, dapatkan hadiah!"],
		"toko": ["TOKO BENIH", "Pilih bibit untuk kebunmu."],
		"produksi": ["DAPUR PRODUKSI", "Olah hasil kebun menjadi makanan."],
		"pakan": ["PABRIK PAKAN", "Racik pakan siap pakai untuk ternak."],
		"gudang": ["GUDANG PANEN", "Jual hasil atau simpan untuk pesanan."],
		"sapi": ["KANDANG SAPI", "Rawat sapi dan hasilkan susu segar."],
		"pasar": ["PASAR PINGGIR JALAN", "Jual barang ke tetangga desa."],
		"pengunjung": ["TAMU KEBUN", "Tetangga datang mencari hasil kebun segar!"],
		"kebun_buah": ["KEBUN BUAH", "Panen buah segar dari pohonmu."],
		"ternak": ["PETERNAKAN", "Pelihara hewan dan kumpulkan hasil ternak."],
		"bangun": ["BANGUN & DEKORASI", "Kembangkan peternakan dan percantik kebun."],
	}
	var title_data: Array = titles[active_tab]
	label(card, title_data[0], Vector2(31, 25), Vector2(540, 44), 31, HUD_GREEN, true)
	label(card, title_data[1], Vector2(33, 69), Vector2(545, 33), 19, HUD_TAB_TEXT)
	var close := button(card, "×", Vector2(595, 28), Vector2(53, 53), Color("e9f0df"), GREEN, 25)
	close.pressed.connect(func() -> void: switch_tab("kebun"))
	var rule := ColorRect.new()
	rule.color = Color("d9e5cb")
	rule.position = Vector2(30, 117)
	rule.size = Vector2(618, 3)
	card.add_child(rule)
	var rule_accent := ColorRect.new()
	rule_accent.color = HUD_GREEN
	rule_accent.position = Vector2(30, 117)
	rule_accent.size = Vector2(94, 3)
	rule_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rule_accent)
	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.position = Vector2(26, 133)
	scroll.size = Vector2(627, card.size.y - 158.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 12
	card.add_child(scroll)
	sheet_scroll = scroll
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(609, 0)
	list.add_theme_constant_override("separation", 17)
	scroll.add_child(list)
	match active_tab:
		"aktivitas":
			populate_activities(list)
		"misi":
			populate_missions(list)
		"pesanan":
			populate_orders(list)
		"toko":
			populate_shop(list)
		"produksi":
			populate_production(list)
		"pakan":
			populate_feed_mill(list)
		"gudang":
			populate_inventory(list)
		"sapi":
			populate_cow(list)
		"pasar":
			market_time_labels = MarketUI.populate(
				self,
				list,
				game,
				Callable(self, "on_market_list"),
				Callable(self, "on_market_cancel")
			)
		"pengunjung":
			populate_visitors(list)
		"kebun_buah":
			orchard_status_rows = OrchardUI.populate(
				self,
				list,
				game,
				Callable(self, "on_orchard_plant"),
				Callable(self, "on_orchard_harvest")
			)
		"ternak":
			var feed_link := row_card(list, 91, Color("f4e7cc"))
			var feed_button := button(feed_link, "PABRIK PAKAN  ›", Vector2(20, 13), Vector2(560, 65), GREEN, Color.WHITE, 22)
			feed_button.pressed.connect(func() -> void: switch_tab("pakan"))
			var cow_link := row_card(list, 91, Color("e6f1df"))
			var cow_button := button(
				cow_link, "RAWAT SAPI  ›", Vector2(20, 13), Vector2(560, 65), GREEN, Color.WHITE, 22
			)
			cow_button.pressed.connect(func() -> void: switch_tab("sapi"))
			animal_status_rows = FarmExpansionUI.populate_animals(
				self,
				list,
				game,
				Callable(self, "on_animal_action"),
				Callable(self, "on_open_buildings")
			)
		"bangun":
			populate_decorations(list)
			FarmExpansionUI.populate_buildings(
				self, list, game, Callable(self, "on_buy_construction")
			)
	scroll.set_deferred("scroll_vertical", int(sheet_scroll_positions.get(active_tab, 0)))


func save_sheet_scroll_position() -> void:
	if sheet_scroll != null and is_instance_valid(sheet_scroll):
		sheet_scroll_positions[active_tab] = sheet_scroll.scroll_vertical


func populate_activities(list: VBoxContainer) -> void:
	var activities := game.ready_activities()
	activity_signature = JSON.stringify(activities)
	var total := 0
	for activity in activities:
		total += int(activity["count"])
	callout(
		list, "SELESAIKAN PEKERJAAN KEBUN",
		"%d tugas siap. Ketuk LIHAT untuk menuju lokasi." % total,
		Color("e4f1d9")
	)
	if game.storage_used() >= game.storage_capacity:
		var warning := row_card(list, 105, Color("fff0d8"))
		label(warning, "GUDANG PENUH", Vector2(20, 12), Vector2(420, 35), 21, Color("98652f"), true)
		var storage_link := button(warning, "BUKA GUDANG  ›", Vector2(20, 51), Vector2(559, 45), GREEN, Color.WHITE, 20)
		storage_link.pressed.connect(func() -> void: switch_tab("gudang"))
	if activities.is_empty():
		callout(
			list, "SEMUA PEKERJAAN SELESAI!",
			"Tanaman dan hasil produksi sedang tumbuh. Kembali lagi nanti.",
			Color("fff1d5")
		)
		return
	for activity in activities:
		var card := row_card(list, 151, Color("fff5e1"))
		label(card, str(activity["title"]), Vector2(21, 15), Vector2(465, 31), 22, GREEN, true)
		label(card, "×%d" % int(activity["count"]), Vector2(492, 15), Vector2(82, 30), 20, HUD_GREEN, true)
		label(card, str(activity["detail"]), Vector2(21, 53), Vector2(550, 29), 18, INK)
		var link := button(card, "LIHAT  ›", Vector2(20, 94), Vector2(561, 47), GREEN, Color.WHITE, 20)
		link.name = "ActivityRow_" + str(activity["id"])
		link.pressed.connect(open_activity.bind(activity))


func open_activity(activity: Dictionary) -> void:
	var destination := str(activity.get("tab", "kebun"))
	switch_tab(destination)
	if destination == "kebun" and int(activity.get("plot", -1)) >= 0:
		on_plot_pressed(int(activity["plot"]))


func populate_visitors(list: VBoxContainer) -> void:
	var intro := callout(list, "TETANGGA MAMPIR", "Ketuk tamu di dekat pasar atau tombol TAMU di peta.", Color("e1f1d8"))
	intro.custom_minimum_size.y = 100
	if game.visitor_request.is_empty():
		var rest := row_card(list, 190, Color("fff1d8"))
		label(rest, "Pengunjung sedang di perjalanan...", Vector2(24, 29), Vector2(555, 40), 24, INK, true)
		visitor_status_text = label(rest, "", Vector2(24, 85), Vector2(545, 35), 21, GREEN)
		visitor_status_text.text = "Tamu berikutnya tiba dalam %d detik." % maxi(0, game.visitor_next_at - game.now())
		label(rest, "Sambil menunggu, isi kembali gudangmu!", Vector2(24, 139), Vector2(555, 30), 18, SOFT_INK)
		return
	var request: Dictionary = game.visitor_request
	var item_id := str(request["item"])
	var quantity := int(request["quantity"])
	var in_storage := int(game.inventory.get(item_id, 0))
	var guest := row_card(list, 318, Color("fff4d9"))
	label(guest, str(request["name"]).to_upper(), Vector2(22, 19), Vector2(530, 37), 27, INK, true)
	label(guest, "\"Halo! Boleh saya beli hasil kebunmu?\"", Vector2(22, 65), Vector2(556, 29), 18, SOFT_INK)
	label(guest, "%s  •  %d/%d tersedia" % [str(game.item_info(item_id)["name"]), in_storage, quantity], Vector2(22, 109), Vector2(554, 36), 22, GREEN if in_storage >= quantity else INK, true)
	var track := panel(guest, Vector2(22, 158), Vector2(556, 12), Color("d9d6b1"), 6)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_width := 556.0 * clampf(float(in_storage) / float(quantity), 0.0, 1.0)
	if fill_width > 0.0:
		var fill := panel(track, Vector2.ZERO, Vector2(fill_width, 12), GREEN, 6)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label(guest, "+%d koin     +%d XP" % [int(request["coins"]), int(request["xp"])], Vector2(22, 187), Vector2(550, 35), 22, GREEN, true)
	var sell := button(guest, "JUAL BARANG", Vector2(22, 245), Vector2(330, 56), GREEN if game.visitor_can_sell() else Color("b8c7b2"), Color.WHITE, 20)
	sell.disabled = not game.visitor_can_sell()
	sell.pressed.connect(on_visitor_sell)
	var decline := button(guest, "TOLAK", Vector2(371, 245), Vector2(209, 56), Color("cf9271"), Color.WHITE, 19)
	decline.pressed.connect(on_visitor_decline)
	if not game.visitor_can_sell():
		callout(list, "STOK BELUM CUKUP", "Panen atau produksi %s untuk memenuhi permintaan." % str(game.item_info(item_id)["name"]), Color("fbe7df"))


func on_visitor_sell() -> void:
	var reward := int(game.visitor_request.get("coins", 0))
	if game.fulfill_visitor():
		farm.show_world_feedback("harvest", farm.visitor_world_position(), "+%d" % reward)
		show_toast("Terima kasih! Pengunjung membayar %d koin." % reward)
	else:
		show_toast("Barang belum cukup untuk permintaan pengunjung.")
	refresh_all()


func on_visitor_decline() -> void:
	if game.decline_visitor():
		show_toast("Tamu pamit. Tetangga lain segera datang!")
	refresh_all()


func on_open_buildings() -> void:
	switch_tab("bangun")


func on_animal_action(id: String) -> void:
	if id == "ayam" and game.ready_eggs() and game.storage_used() + 2 > game.storage_capacity:
		show_toast("Gudang kurang %d slot untuk telur. Jual stok dulu." % (game.storage_used() + 2 - game.storage_capacity))
		switch_tab("gudang")
		return
	if id != "ayam" and game.animal_ready(id):
		var amount := int(FarmGameState.ANIMALS[id]["yield"])
		if game.storage_used() + amount > game.storage_capacity:
			show_toast("Gudang kurang %d slot untuk hasil ternak." % (game.storage_used() + amount - game.storage_capacity))
			switch_tab("gudang")
			return
	var success := (
		game.collect_eggs()
		if id == "ayam"
		else game.feed_animal(id) if game.animal_hungry(id) else game.collect_animal(id)
	)
	if success:
		show_toast("Berhasil merawat ternak!")
	elif id == "ayam":
		show_toast("Ruang gudang kurang untuk 2 telur." if game.ready_eggs() else "Telur belum siap.")
	elif game.animal_hungry(id):
		var shortages: Array[String] = []
		var missing := game.missing_animal_feed(id)
		for ingredient in missing:
			shortages.append("%s +%d" % [game.item_info(ingredient)["name"], missing[ingredient]])
		show_toast("Pakan kurang: %s." % ", ".join(shortages))
	elif game.animal_ready(id):
		var required := int(FarmGameState.ANIMALS[id]["yield"])
		var shortage := maxi(0, game.storage_used() + required - game.storage_capacity)
		show_toast("Ruang gudang kurang. Kosongkan %d slot." % shortage)
	else:
		show_toast("Hasil ternak sedang diproses.")
	refresh_all()


func on_buy_construction(id: String) -> void:
	if game.buy_construction(id):
		show_toast("%s telah dibangun!" % FarmGameState.CONSTRUCTIONS[id]["name"])
	else:
		show_toast("Belum bisa dibeli. Cek level, koin, dan jumlah bangunan.")
	refresh_all()


func populate_decorations(list: VBoxContainer) -> void:
	callout(list, "TOKO DEKORASI", "Beli, pasang, pindahkan lewat ATUR, atau simpan kembali.", Color("dcefd3"))
	for kind in FarmGameState.DECORATION_ORDER:
		var info: Dictionary = FarmGameState.DECORATIONS[kind]
		var stored := game.stored_decoration_count(kind)
		var placed := 0
		for item in game.decorations:
			if str(item.get("kind", "")) == kind and (item.get("position", []) as Array).size() == 2:
				placed += 1
		var card := row_card(list, 136, Color("f9f3e2"))
		if farm.farm_art.sprites.has(kind):
			var sprite: Dictionary = farm.farm_art.sprites[kind]
			var atlas := AtlasTexture.new()
			atlas.atlas = sprite["texture"]
			atlas.region = sprite["region"]
			var thumbnail := TextureRect.new()
			thumbnail.position = Vector2(11, 9)
			thumbnail.size = Vector2(101, 88)
			thumbnail.texture = atlas
			thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(thumbnail)
		label(card, str(info["name"]), Vector2(115, 11), Vector2(465, 36), 23, INK, true)
		label(card, "%d koin  •  %d disimpan  •  %d dipasang" % [int(info["cost"]), stored, placed],
			Vector2(115, 52), Vector2(466, 31), 17, SOFT_INK)
		var buy := button(card, "BELI & PASANG", Vector2(410, 88), Vector2(175, 42),
			GREEN if game.coins >= int(info["cost"]) else Color("b4baad"), Color.WHITE, 16)
		buy.disabled = game.coins < int(info["cost"])
		buy.pressed.connect(on_buy_decoration.bind(kind))
		if stored > 0:
			var place := button(card, "PASANG", Vector2(115, 88), Vector2(152, 42), MINT, GREEN, 18)
			place.pressed.connect(on_place_stored_decoration.bind(kind))
	if game.decorations.is_empty():
		return
	var placed_count := 0
	for item in game.decorations:
		if (item.get("position", []) as Array).size() == 2:
			placed_count += 1
	if placed_count == 0:
		return
	callout(list, "DEKORASI TERPASANG", "Tekan SIMPAN untuk mengembalikan benda ke koleksi.", Color("e3f1db"))
	for item in game.decorations:
		if (item.get("position", []) as Array).size() != 2:
			continue
		var kind := str(item["kind"])
		var card := row_card(list, 77, Color("fff5e3"))
		label(card, str(FarmGameState.DECORATIONS[kind]["name"]), Vector2(16, 17), Vector2(376, 39), 21, INK, true)
		var store := button(card, "SIMPAN", Vector2(416, 15), Vector2(168, 48), GREEN, Color.WHITE, 18)
		store.pressed.connect(on_store_decoration.bind(str(item["key"])))


func begin_decoration_from_inventory(key: String) -> void:
	switch_tab("kebun")
	farm.begin_decoration_placement(key)
	arrange_button.text = "✕ BATAL"
	refresh_road_toolbar()
	update_visitor_shortcut()
	show_toast("Ketuk lahan kosong untuk memasang dekorasi. BATAL menyimpannya.")


func on_buy_decoration(kind: String) -> void:
	var key := game.buy_decoration(kind)
	if key == "":
		show_toast("Koin tidak cukup untuk membeli dekorasi ini.")
		refresh_all()
		return
	begin_decoration_from_inventory(key)
	refresh_all()


func on_place_stored_decoration(kind: String) -> void:
	for item in game.decorations:
		if str(item.get("kind", "")) == kind and (item.get("position", []) as Array).is_empty():
			begin_decoration_from_inventory(str(item["key"]))
			return
	show_toast("Tidak ada dekorasi tersimpan untuk dipasang.")


func on_store_decoration(key: String) -> void:
	if not game.store_decoration(key):
		show_toast("Dekorasi tidak ditemukan.")
		return
	farm.invalidate_scenery()
	refresh_all()
	show_toast("Dekorasi sudah disimpan dan bisa dipasang kembali.")


func on_orchard_plant(index: int, fruit_id: String) -> void:
	if game.plant_tree(index, fruit_id):
		farm.show_orchard_feedback(index, "plant")
		show_toast("Pohon berhasil ditanam! Buah tumbuh otomatis.")
	else:
		show_toast("Petak terisi, level belum cukup, atau koin kurang.")
	refresh_all()


func on_orchard_harvest(index: int) -> void:
	var collected := game.harvest_tree(index)
	if collected > 0:
		farm.show_orchard_feedback(index, "harvest", collected)
		show_toast("Panen %d buah! Pohon mulai berbuah lagi." % collected)
	else:
		show_toast("Buah belum matang atau gudang penuh.")
	refresh_all()


func on_market_list(id: String, quantity: int) -> void:
	if game.list_market_item(id, quantity):
		show_toast("Barang ditawarkan! Pembeli akan datang otomatis.")
	else:
		show_toast("Stok kurang atau tiga lapak pasar sudah terisi.")
	refresh_all()


func on_market_cancel(index: int) -> void:
	if game.cancel_market_listing(index):
		show_toast("Barang kembali ke gudang.")
	else:
		show_toast("Lapak sudah terjual atau ruang gudang tidak cukup.")
	refresh_all()


func populate_missions(list: VBoxContainer) -> void:
	DailyMissionsUI.populate(
		self, list, game, Callable(self, "claim_mission"), Callable(self, "claim_checkin"),
		Callable(self, "claim_achievement")
	)


func claim_achievement(id: String) -> void:
	var reward := game.claim_achievement(id)
	if reward.is_empty():
		show_toast("Prestasi belum selesai atau hadiahnya sudah diklaim.")
	else:
		show_toast("Prestasi tahap %d! +%d koin dan +%d XP." % [int(reward["tier"]), int(reward["coins"]), int(reward["xp"])])
	refresh_all()


func claim_checkin() -> void:
	var reward := game.claim_daily_checkin()
	if reward.is_empty():
		show_toast("Hadiah kunjungan hari ini sudah diambil atau belum tersedia.")
	else:
		var message := "+%d koin kunjungan harian!" % int(reward["coins"])
		if int(reward["diamonds"]) > 0:
			message += " Bonus 1 permata!"
		show_toast(message)
	refresh_all()


func claim_mission(id: String) -> void:
	if game.claim_daily_task(id):
		show_toast("Hadiah misi berhasil diklaim! Koin dan XP bertambah.")
	else:
		show_toast("Misi belum selesai atau hadiah sudah diambil.")
	refresh_all()


func populate_cow(list: VBoxContainer) -> void:
	var feed_link := row_card(list, 86, Color("f4e7cc"))
	var feed_button := button(feed_link, "BUAT PAKAN SAPI  ›", Vector2(20, 12), Vector2(560, 60), GREEN, Color.WHITE, 20)
	feed_button.pressed.connect(func() -> void: switch_tab("pakan"))
	var status_card := row_card(list, 324, Color("e5f1da"))
	label(
		status_card,
		"SAPI PERAH  ·  2 SUSU / SIKLUS",
		Vector2(23, 19),
		Vector2(552, 36),
		23,
		GREEN,
		true
	)
	cow_status_text = label(status_card, "", Vector2(23, 77), Vector2(550, 104), 23, INK, true)
	cow_action_button = button(
		status_card, "", Vector2(21, 215), Vector2(559, 76), GREEN, Color.WHITE, 22
	)
	cow_action_button.pressed.connect(on_cow_action)
	refresh_cow_status()
	var feed_card := row_card(list, 179, Color("fff1d3"))
	label(feed_card, "PAKAN SAPI", Vector2(21, 19), Vector2(420, 40), 24, INK, true)
	label(
		feed_card,
		"1 paket pakan, atau 2 Gandum + 1 Jagung per siklus.",
		Vector2(22, 68),
		Vector2(550, 43),
		20,
		SOFT_INK
	)
	label(
		feed_card,
		"Paket %d  ·  Gandum %d  ·  Jagung %d" % [game.inventory["pakan_sapi"], game.inventory["gandum"], game.inventory["jagung"]],
		Vector2(22, 120),
		Vector2(550, 34),
		20,
		GREEN,
		true
	)
	callout(
		list,
		"DARI KANDANG KE DAPUR",
		"Susu bisa dijual di gudang atau dibuat Keju Desa mulai level 2.",
		Color("e8f2f7")
	)


func refresh_cow_status() -> void:
	if cow_status_text == null or not is_instance_valid(cow_status_text):
		return
	if game.cow_is_hungry():
		cow_status_text.text = "Sapi lapar! Pakai paket pakan atau hasil panen."
	elif game.cow_milk_ready():
		cow_status_text.text = "2 botol susu sudah siap diperah!"
	else:
		cow_status_text.text = (
			"Sapi kenyang! Susu siap dalam %d detik." % maxi(0, game.cow_ready_at - game.now())
		)
	if cow_action_button != null and is_instance_valid(cow_action_button):
		if game.cow_is_hungry():
			cow_action_button.text = "BERI PAKAN"
			cow_action_button.disabled = not game.can_feed_cow()
		elif game.cow_milk_ready():
			cow_action_button.text = (
				"BUKA GUDANG ›" if game.storage_used() + 2 > game.storage_capacity else "PERAH SUSU"
			)
			cow_action_button.disabled = false
		else:
			cow_action_button.text = "MENUNGGU SUSU"
			cow_action_button.disabled = true


func on_cow_action() -> void:
	if game.cow_milk_ready() and game.storage_used() + 2 > game.storage_capacity:
		show_toast("Gudang kurang %d slot untuk susu. Jual stok dulu." % (game.storage_used() + 2 - game.storage_capacity))
		switch_tab("gudang")
		return
	if game.cow_is_hungry():
		if game.feed_cow():
			show_toast("Sapi sudah diberi makan! Susu segera siap.")
		else:
			show_toast("Pakan kurang. Panen 2 gandum dan 1 jagung dulu.")
	elif game.collect_milk():
		show_toast("Berhasil memerah! +2 susu dan +10 XP.")
	else:
		show_toast("Susu belum siap atau gudang penuh.")
	refresh_all()


func populate_orders(list: VBoxContainer) -> void:
	var ready_count := 0
	for index in game.orders.size():
		if not game.orders[index]["items"].is_empty() and game.order_can_fill(index):
			ready_count += 1
	var note := callout(
		list,
		"TRUK PENGIRIMAN",
		"%d/%d siap kirim. Kontrak bisa diganti seharga 15 koin." % [ready_count, game.orders.size()],
		Color("e0f1d6")
	)
	note.custom_minimum_size.y = 100
	for i in game.orders.size():
		var order: Dictionary = game.orders[i]
		var card := row_card(list, 338, Color("fff4dc"))
		label(
			card,
			"KONTRAK 0" + str(i + 1),
			Vector2(20, 13),
			Vector2(325, 27),
			16,
			Color("aa8254"),
			true
		)
		label(card, order["title"], Vector2(20, 40), Vector2(450, 39), 27, INK, true)
		var item_row := 0
		for id in order["items"]:
			var target: int = order["items"][id]
			var current := int(game.inventory.get(id, 0))
			label(
				card,
				(
					"%s    %d/%d %s"
					% [
						str(game.item_info(id)["name"]),
						current,
						target,
						"✓" if current >= target else "•"
					]
				),
				Vector2(21, 86 + item_row * 35),
				Vector2(560, 32),
				19,
				GREEN if current >= target else SOFT_INK,
				true
			)
			item_row += 1
		# Draw the proportional fill explicitly: a 0..1 ProgressBar can render
		# partial quantities as a full bar on some Android renderers.
		var progress_track := panel(card, Vector2(21, 166), Vector2(560, 9), Color("e7d5b7"), 5)
		progress_track.name = "OrderProgressTrack%d" % i
		progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var filled_width := 560.0 * game.order_progress(i)
		if filled_width > 0.0:
			var progress_fill := panel(
				progress_track, Vector2.ZERO, Vector2(filled_width, 9), GREEN, 5
			)
			progress_fill.name = "OrderProgressFill"
			progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label(
			card,
			"+%d koin    +%d XP" % [int(order["coins"]), int(order["xp"])],
			Vector2(21, 200),
			Vector2(300, 32),
			18,
			GREEN,
			true
		)
		var deliver := button(
			card,
			"KIRIM",
			Vector2(462, 190),
			Vector2(120, 51),
			GREEN if game.order_can_fill(i) else Color("bec8b5"),
			Color.WHITE,
			17
		)
		deliver.disabled = not game.order_can_fill(i)
		var order_slot := i
		deliver.pressed.connect(func() -> void: send_delivery(order_slot))
		var change := button(
			card, "GANTI 15", Vector2(324, 190), Vector2(128, 51), Color("c69253"), Color.WHITE, 16
		)
		change.pressed.connect(func() -> void: on_refresh_order(order_slot))
		var status := label(card, "", Vector2(327, 250), Vector2(255, 23), 14, SOFT_INK)
		order_refresh_rows.append({"index": order_slot, "button": change, "status": status})
		var missing_id := ""
		var missing_quantity := 0
		for item_id in order["items"]:
			var needed := int(order["items"][item_id]) - int(game.inventory.get(item_id, 0))
			if needed > 0:
				missing_id = str(item_id)
				missing_quantity = needed
				break
		if missing_id.is_empty():
			label(card, "✓ BARANG LENGKAP • TEKAN KIRIM", Vector2(21, 281), Vector2(560, 37), 19, GREEN, true)
		else:
			var supply_tab := order_supply_tab(missing_id)
			var item_name := str(game.item_info(missing_id)["name"])
			label(card, "KURANG %d %s" % [missing_quantity, item_name], Vector2(21, 251), Vector2(300, 27), 17, SOFT_INK, true)
			var supply_button := button(
				card, "CARI BAHAN  ›", Vector2(21, 279), Vector2(560, 44), MINT, GREEN, 18
			)
			supply_button.name = "OrderSupply%d" % order_slot
			supply_button.pressed.connect(func() -> void: switch_tab(supply_tab))
	refresh_order_buttons()


func order_supply_tab(id: String) -> String:
	if FarmGameState.CROPS.has(id) or id == "telur":
		return "kebun"
	if FarmGameState.PRODUCTS.has(id):
		return "produksi"
	if FarmGameState.FRUITS.has(id):
		return "kebun_buah"
	if id == "susu":
		return "sapi"
	if id == "daging_babi" or id == "susu_kambing":
		return "ternak"
	if FarmGameState.FEED_RECIPES.has(id):
		return "pakan"
	return "gudang"


func refresh_order_buttons() -> void:
	for row in order_refresh_rows:
		var index: int = row["index"]
		var change: Button = row["button"]
		var status: Label = row["status"]
		if not is_instance_valid(change) or not is_instance_valid(status):
			continue
		change.disabled = not game.can_refresh_order(index)
		var left := maxi(0, game.order_refresh_until[index] - game.now())
		status.text = (
			"Tunggu %d detik" % left
			if left > 0
			else (
				"Butuh 15 koin" if game.coins < FarmGameState.ORDER_REFRESH_COST else "Siap diganti"
			)
		)


func on_refresh_order(index: int) -> void:
	if game.refresh_order(index):
		show_toast("Kontrak baru datang! Biaya 15 koin.")
	else:
		show_toast("Perlu 15 koin atau tunggu jeda penggantian.")
	refresh_all()


func populate_shop(list: VBoxContainer) -> void:
	if ads:
		var bonus := row_card(list, 236, Color("e3eff7"))
		label(bonus, "BONUS PERMATA", Vector2(20, 14), Vector2(555, 34), 24, GREEN, true)
		label(
			bonus,
			"Tonton iklan jika aktif, atau klaim saat nonaktif.",
			Vector2(20, 51),
			Vector2(570, 30),
			16,
			INK
		)
		var watch := button(
			bonus,
			"▶ IKLAN REWARD: +2 ◆" if ads.can_show_kind("rewarded") else "KLAIM GRATIS: +2 ◆",
			Vector2(18, 91),
			Vector2(570, 51),
			GREEN,
			Color.WHITE,
			19
		)
		watch.pressed.connect(func() -> void: ads.show_rewarded("rewarded"))
		var watch_more := button(
			bonus,
			(
				"▶ IKLAN BONUS: +3 ◆"
				if ads.can_show_kind("rewarded_interstitial")
				else "KLAIM GRATIS: +3 ◆"
			),
			Vector2(18, 150),
			Vector2(570, 51),
			Color("6196b5"),
			Color.WHITE,
			19
		)
		watch_more.pressed.connect(func() -> void: ads.show_rewarded("rewarded_interstitial"))
		if ads.has_enabled_ads():
			var privacy := button(
				bonus,
				"PRIVASI IKLAN",
				Vector2(376, 207),
				Vector2(205, 26),
				Color("deebd9"),
				INK,
				13
			)
			privacy.pressed.connect(ads.show_privacy_options)
	var menu := row_card(list, 202, Color("e4f0d8"))
	label(menu, "JELAJAHI PERTANIAN", Vector2(20, 15), Vector2(565, 36), 23, GREEN, true)
	var go_animals := button(
		menu, "TERNAK", Vector2(19, 69), Vector2(268, 58), GREEN, Color.WHITE, 21
	)
	go_animals.pressed.connect(func() -> void: switch_tab("ternak"))
	var go_build := button(
		menu, "BANGUN & DEKOR", Vector2(302, 69), Vector2(279, 58), GREEN, Color.WHITE, 19
	)
	go_build.pressed.connect(func() -> void: switch_tab("bangun"))
	var go_market := button(
		menu, "PASAR TETANGGA  ›", Vector2(19, 137), Vector2(562, 52), Color("f8d58e"), INK, 19
	)
	go_market.pressed.connect(func() -> void: switch_tab("pasar"))
	if game.needs_seed_recovery():
		var recovery := row_card(list, 180, Color("fff0d8"))
		label(recovery, "BANTUAN BIBIT DARURAT", Vector2(20, 14), Vector2(559, 34), 23, GREEN, true)
		var recovery_wait := game.seed_recovery_seconds_left()
		var recovery_hint := (
			"Stok habis? Ambil 3 bibit gandum gratis untuk mulai bertani lagi."
			if recovery_wait == 0
			else "Bantuan tersedia kembali setelah jeda. Kamu juga bisa jual telur di gudang."
		)
		label(recovery, recovery_hint, Vector2(20, 50), Vector2(561, 54), 16, INK)
		seed_recovery_button = button(
			recovery,
			"AMBIL 3 BIBIT GRATIS" if recovery_wait == 0 else "TUNGGU %d:%02d" % [int(recovery_wait / 60), recovery_wait % 60],
			Vector2(19, 113), Vector2(561, 50),
			GREEN if recovery_wait == 0 else Color("b9c5b3"), Color.WHITE, 18
		)
		seed_recovery_button.disabled = recovery_wait > 0
		seed_recovery_button.pressed.connect(on_claim_seed_recovery)
	callout(
		list, "PILIH BIBIT FAVORIT", "Beli bibit lalu ketuk petak untuk menanam.", Color("e3f0db")
	)
	for id in FarmGameState.CROP_ORDER:
		var info: Dictionary = FarmGameState.CROPS[id]
		var unlocked: bool = game.level >= int(info["level"])
		var seed_price: int = int(info["seed_cost"])
		var card := row_card(list, 149, Color("fff3e1"))
		var icon := TextureRect.new()
		icon.name = "SeedIcon_" + id
		icon.texture = seed_icon_texture(id)
		icon.position = Vector2(12, 28)
		icon.size = Vector2(88, 88)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			icon.modulate = Color(0.76, 0.76, 0.76, 0.65)
		card.add_child(icon)
		var seed_name := label(card, str(info["name"]), Vector2(172, 15), Vector2(265, 38), 27, INK, true)
		seed_name.clip_text = true
		var seed_stock := label(
			card,
			"Stok: " + str(game.seeds.get(id, 0)) + "    •    " + str(info["grow"]) + " dtk",
			Vector2(172, 55),
			Vector2(176, 31),
			17,
			SOFT_INK
		)
		seed_stock.clip_text = true
		label(
			card,
			"1 bibit: %d  ·  5 bibit: %d koin" % [seed_price, seed_price * 5],
			Vector2(172, 102),
			Vector2(402, 30),
			16,
			Color("a4783e"),
			true
		)
		if unlocked:
			var buy_one := button(
				card, "BELI 1", Vector2(447, 46), Vector2(65, 54),
				GREEN if game.coins >= seed_price else Color("b9c5b3"), Color.WHITE, 13
			)
			buy_one.disabled = game.coins < seed_price
			buy_one.pressed.connect(func() -> void: buy_crop(id, 1))
			var buy_five := button(
				card, "BELI 5", Vector2(516, 46), Vector2(66, 54),
				GREEN if game.coins >= seed_price * 5 else Color("b9c5b3"), Color.WHITE, 13
			)
			buy_five.disabled = game.coins < seed_price * 5
			buy_five.pressed.connect(func() -> void: buy_crop(id, 5))
			var choose := button(
				card,
				"DIPILIH" if game.selected_crop == id else "PILIH",
				Vector2(354, 46),
				Vector2(90, 54),
				Color("f8d58e") if game.selected_crop == id else Color("e6ead6"),
				INK,
				15
			)
			choose.pressed.connect(func() -> void: choose_crop(id))
		else:
			var locked := button(
				card, "LV " + str(info["level"]), Vector2(447, 46),
				Vector2(135, 54), Color("b9c5b3"), Color.WHITE, 18
			)
			locked.disabled = true


func seed_icon_texture(id: String) -> Texture2D:
	if not seed_icon_textures.has(id):
		var path := "res://assets/seed_icons/%s.svg" % id
		seed_icon_textures[id] = load(path) as Texture2D
	return seed_icon_textures[id]


func production_icon_texture(id: String) -> Texture2D:
	if not production_icon_textures.has(id):
		var path := "res://assets/production_icons/%s.svg" % id
		production_icon_textures[id] = load(path) as Texture2D
	return production_icon_textures[id]


func populate_production(list: VBoxContainer) -> void:
	var feed_link := row_card(list, 82, Color("f3e9d6"))
	var feed_button := button(feed_link, "BUKA PABRIK PAKAN  ›", Vector2(20, 12), Vector2(560, 56), GREEN, Color.WHITE, 19)
	feed_button.pressed.connect(func() -> void: switch_tab("pakan"))
	var queue_card := row_card(list, 237, Color("e1f0d5"))
	label(
		queue_card, "ANTRIAN DAPUR  ·  MAKS. 3", Vector2(22, 13), Vector2(552, 35), 21, GREEN, true
	)
	production_status_text = label(
		queue_card, "", Vector2(22, 56), Vector2(565, 102), 19, INK, true
	)
	production_collect_button = button(
		queue_card, "AMBIL HASIL", Vector2(20, 167), Vector2(560, 53), GREEN, Color.WHITE, 19
	)
	production_collect_button.pressed.connect(on_collect_product)
	refresh_production_status()
	callout(
		list, "RESEP PILIHAN", "Panen bahan, lalu masukkan makanan ke antrian.", Color("fff0d3")
	)
	for id in FarmGameState.PRODUCT_ORDER:
		var info: Dictionary = FarmGameState.PRODUCTS[id]
		var unlocked := game.level >= int(info["level"])
		var card := row_card(list, 163, Color("fff4df"))
		var icon := TextureRect.new()
		icon.name = "ProductionIcon_" + id
		icon.texture = production_icon_texture(id)
		icon.position = Vector2(14, 36)
		icon.size = Vector2(76, 76)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			icon.modulate = Color(0.76, 0.76, 0.76, 0.65)
		card.add_child(icon)
		var recipe_name := label(card, str(info["name"]), Vector2(172, 15), Vector2(277, 37), 26, INK, true)
		recipe_name.clip_text = true
		var ingredients := ""
		for ingredient in info["ingredients"]:
			ingredients += (
				str(game.item_info(ingredient)["name"])
				+ " "
				+ str(game.inventory.get(ingredient, 0))
				+ "/"
				+ str(info["ingredients"][ingredient])
				+ "  "
			)
		var ingredient_label := label(card, ingredients.strip_edges(), Vector2(172, 55), Vector2(277, 42), 17, SOFT_INK)
		ingredient_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ingredient_label.clip_text = true
		label(
			card,
			(
				str(info["seconds"])
				+ " detik  ·  +"
				+ str(info["xp"])
				+ " XP  ·  "
				+ str(info["sell"])
				+ " koin"
			),
			Vector2(172, 110),
			Vector2(402, 30),
			17,
			Color("a4783e"),
			true
		)
		var can_make := game.can_queue_product(id)
		var make := button(
			card,
			"BUAT" if unlocked else "LV " + str(info["level"]),
			Vector2(457, 25),
			Vector2(124, 56),
			GREEN if can_make else Color("b9c5b3"),
			Color.WHITE,
			17
		)
		make.disabled = not can_make
		make.pressed.connect(func() -> void: on_queue_product(id))


func populate_feed_mill(list: VBoxContainer) -> void:
	if not game.has_construction("pabrik_pakan"):
		callout(list, "PABRIK BELUM DIBANGUN", "Level 2 · 190 koin. Ternak bisa makan panen langsung.", Color("fff0d3"))
		var build_card := row_card(list, 97, Color("e5f1da"))
		var build_button := button(build_card, "BUKA MENU BANGUN  ›", Vector2(19, 17), Vector2(562, 60), GREEN, Color.WHITE, 20)
		build_button.pressed.connect(func() -> void: switch_tab("bangun"))
		return
	var queue_card := row_card(list, 235, Color("e1f0d5"))
	label(queue_card, "ANTRIAN PAKAN  ·  MAKS. 3", Vector2(22, 13), Vector2(550, 35), 21, GREEN, true)
	feed_status_text = label(queue_card, "", Vector2(22, 55), Vector2(563, 102), 19, INK, true)
	feed_collect_button = button(queue_card, "AMBIL PAKAN", Vector2(20, 165), Vector2(560, 53), GREEN, Color.WHITE, 19)
	feed_collect_button.pressed.connect(on_collect_feed)
	refresh_feed_status()
	callout(list, "RACIK PAKAN", "1 racikan = 2 paket. Hewan memakai pakan lebih dulu.", Color("fff0d3"))
	for id in FarmGameState.FEED_ORDER:
		var info: Dictionary = FarmGameState.FEED_RECIPES[id]
		var unlocked := game.level >= int(info["level"])
		var card := row_card(list, 167, Color("fff4df"))
		card.add_child(circle(Vector2(44, 67), 27, Color(info["color"])))
		label(card, str(info["name"]), Vector2(87, 15), Vector2(355, 35), 25, INK, true)
		var ingredients := ""
		for ingredient in info["ingredients"]:
			ingredients += "%s %d/%d  " % [str(game.item_info(ingredient)["name"]), int(game.inventory.get(ingredient, 0)), int(info["ingredients"][ingredient])]
		label(card, ingredients.strip_edges(), Vector2(87, 57), Vector2(495, 29), 17, SOFT_INK)
		label(card, "%d dtk  ·  +%d XP  ·  Stok %d paket" % [int(info["seconds"]), int(info["xp"]), int(game.inventory.get(id, 0))], Vector2(87, 104), Vector2(470, 30), 17, Color("a4783e"), true)
		var can_make := game.can_queue_feed(id)
		var make := button(card, "BUAT ×2" if unlocked else "LV %d" % int(info["level"]), Vector2(453, 19), Vector2(130, 53), GREEN if can_make else Color("b9c5b3"), Color.WHITE, 16)
		make.disabled = not can_make
		make.pressed.connect(func() -> void: on_queue_feed(id))


func refresh_feed_status() -> void:
	if feed_status_text == null or not is_instance_valid(feed_status_text):
		return
	var queue_lines := ""
	for i in game.feed_queue.size():
		var task: Dictionary = game.feed_queue[i]
		var time_left := maxi(0, int(task["ready_at"]) - game.now())
		queue_lines += "%d.  %s  ·  %s\n" % [i + 1, str(game.item_info(task["feed"])["name"]), "SIAP!" if time_left == 0 else "%d dtk" % time_left]
	feed_status_text.text = queue_lines.strip_edges() if not queue_lines.is_empty() else "Belum ada pakan dibuat. Pilih resep di bawah!"
	if feed_collect_button != null and is_instance_valid(feed_collect_button):
		var ready := game.feed_ready()
		var collectable := game.count_collectable_feed() if ready else 0
		feed_collect_button.disabled = not ready
		feed_collect_button.text = (
			"BUKA GUDANG ›" if ready and collectable == 0
			else "AMBIL SEMUA (%d)" % collectable if collectable > 1
			else "AMBIL PAKAN ×2" if ready else "MENUNGGU PAKAN"
		)


func on_queue_feed(id: String) -> void:
	if game.queue_feed(id):
		show_toast("Pakan masuk antrean pabrik!")
	else:
		show_toast("Pabrik belum dibangun, bahan kurang, atau antrean penuh.")
	refresh_all()


func on_collect_feed() -> void:
	if game.feed_ready():
		var feed_id := str(game.feed_queue[0]["feed"])
		if FarmGameState.FEED_RECIPES.has(feed_id):
			var needed := int(FarmGameState.FEED_RECIPES[feed_id]["yield"])
			if game.storage_used() + needed > game.storage_capacity:
				show_toast("Gudang kurang %d slot untuk pakan." % (game.storage_used() + needed - game.storage_capacity))
				switch_tab("gudang")
				return
	var collected := game.collect_ready_feed()
	if collected > 0:
		var full := game.feed_ready() and game.count_collectable_feed() == 0
		show_toast("%d racikan pakan masuk gudang%s" % [collected, ". Sisa antrean menunggu ruang." if full else "!"])
	else:
		show_toast("Pakan belum selesai atau gudang penuh.")
	refresh_all()


func refresh_production_status() -> void:
	if production_status_text == null or not is_instance_valid(production_status_text):
		return
	var queue_lines := ""
	for i in game.production_queue.size():
		var task: Dictionary = game.production_queue[i]
		var time_left := maxi(0, int(task["ready_at"]) - game.now())
		var status := "SIAP!" if time_left == 0 else str(time_left) + " dtk"
		queue_lines += (
			str(i + 1)
			+ ".  "
			+ str(game.item_info(task["product"])["name"])
			+ "  ·  "
			+ status
			+ "\n"
		)
	production_status_text.text = (
		queue_lines.strip_edges()
		if not queue_lines.is_empty()
		else "Belum ada produksi. Pilih resep di bawah!"
	)
	if production_collect_button != null and is_instance_valid(production_collect_button):
		var ready := game.production_ready()
		var collectable := game.count_collectable_products() if ready else 0
		production_collect_button.disabled = not ready
		production_collect_button.text = (
			"BUKA GUDANG ›"
			if ready and collectable == 0
			else "AMBIL SEMUA (%d)" % collectable if collectable > 1
			else "AMBIL HASIL" if ready else "MENUNGGU PRODUKSI"
		)


func on_queue_product(id: String) -> void:
	if game.queue_product(id):
		show_toast(str(game.item_info(id)["name"]) + " masuk antrian dapur!")
	else:
		show_toast("Bahan tidak cukup atau antrian sudah penuh.")
	refresh_all()


func on_collect_product() -> void:
	if game.production_ready():
		var product_id := str(game.production_queue[0]["product"])
		if FarmGameState.PRODUCTS.has(product_id):
			var needed := int(FarmGameState.PRODUCTS[product_id]["yield"])
			if game.storage_used() + needed > game.storage_capacity:
				show_toast("Gudang kurang %d slot untuk hasil dapur." % (game.storage_used() + needed - game.storage_capacity))
				switch_tab("gudang")
				return
	var collected := game.collect_ready_products()
	if collected > 0:
		var full := game.production_ready() and game.count_collectable_products() == 0
		show_toast("%d hasil dapur masuk gudang%s" % [collected, ". Sisa antrean menunggu ruang." if full else "!"])
	else:
		show_toast("Belum siap atau gudang penuh.")
	refresh_all()


func populate_inventory(list: VBoxContainer) -> void:
	InventoryUI.populate(
		self,
		list,
		game,
		Callable(self, "upgrade_barn"),
		Callable(self, "sell_crop"),
		Callable(self, "confirm_new_game")
	)


func refresh_all() -> void:
	var ready_rewards := game.claimable_rewards_count()
	mission_header_button.text = (
		"★ MISI %d/3  ·  %d KLAIM  ›" % [game.daily_claimed_count(), ready_rewards]
		if ready_rewards > 0 else "★ MISI %d/3  ›" % game.daily_claimed_count()
	)
	mission_header_button.add_theme_stylebox_override(
		"normal", style(Color("f7e3a0") if ready_rewards > 0 else Color("e3f0d5"), 17, 2)
	)
	top_level_text.text = "LV " + str(game.level)
	top_coins_text.text = TEXT_FORMAT.format_number(game.coins)
	top_gems_text.text = str(game.diamonds)
	top_xp_text.text = str(game.xp) + " / " + str(game.xp_target()) + " XP"
	refresh_tutorial()
	xp_track.max_value = game.xp_target()
	xp_track.value = game.xp
	update_visitor_shortcut()
	update_activity_shortcut()
	if not farm.panel_obscured:
		farm.queue_redraw()
	if action_panel.visible:
		refresh_action()
	if active_tab != "kebun":
		show_sheet()


func update_visitor_shortcut() -> void:
	if not is_instance_valid(visitor_shortcut):
		return
	visitor_shortcut.visible = active_tab == "kebun" and not farm.edit_mode
	if not game.visitor_request.is_empty():
		visitor_shortcut.text = "✦ TAMU DATANG"
		visitor_shortcut.disabled = false
	else:
		var remaining := maxi(0, game.visitor_next_at - game.now())
		visitor_shortcut.text = "TAMU %02d:%02d" % [remaining / 60, remaining % 60]
		visitor_shortcut.disabled = false


func update_activity_shortcut() -> void:
	if not is_instance_valid(activity_shortcut):
		return
	activity_shortcut.visible = active_tab == "kebun" and not farm.edit_mode and game.onboarding_step >= FarmGameState.ONBOARDING_COMPLETE
	if not activity_shortcut.visible:
		return
	var total := 0
	for activity in game.ready_activities():
		total += int(activity["count"])
	activity_shortcut.text = "★ %d SIAP  ·  AKTIVITAS ›" % total if total > 0 else "✓ AKTIVITAS KEBUN ›"


func refresh_action() -> void:
	if action_panel == null or not action_panel.visible:
		return
	var old_seed_scroller := action_panel.get_node_or_null("SeedScroller") as ScrollContainer
	if old_seed_scroller != null:
		seed_scroll_left = old_seed_scroller.scroll_horizontal
	for child in action_panel.get_children():
		child.queue_free()
	var plot: Dictionary = game.plots[selected_plot]
	var title := "PETAK %02d" % (selected_plot + 1)
	label(action_panel, title, Vector2(23, 14), Vector2(215, 33), 22, INK, true)
	var close := button(
		action_panel, "×", Vector2(614, 9), Vector2(52, 45), Color("e9f0df"), GREEN, 23
	)
	close.pressed.connect(hide_action_panel)
	if not plot["unlocked"]:
		label(
			action_panel,
			"Buka lahan baru untuk menanam!",
			Vector2(23, 55),
			Vector2(612, 37),
			21,
			SOFT_INK
		)
		var cost := game.land_cost()
		var unlock := button(
			action_panel,
			"BUKA LAHAN  •  " + str(cost) + " KOIN",
			Vector2(23, 113),
			Vector2(644, 77),
			GREEN if game.coins >= cost else Color("b9c5b3"),
			Color.WHITE,
			23
		)
		unlock.disabled = game.coins < cost
		unlock.pressed.connect(on_unlock_plot)
		return
	var crop_id: String = plot["crop"]
	if crop_id == "":
		label(
			action_panel,
			"Pilih bibit untuk ditanam",
			Vector2(242, 15),
			Vector2(417, 33),
			20,
			SOFT_INK
		)
		var seed_scroller := ScrollContainer.new()
		seed_scroller.name = "SeedScroller"
		seed_scroller.position = Vector2(23, 55)
		seed_scroller.size = Vector2(644, 64)
		seed_scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		seed_scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		action_panel.add_child(seed_scroller)
		var seed_content := Control.new()
		seed_content.custom_minimum_size = Vector2(FarmGameState.CROP_ORDER.size() * 132, 59)
		seed_scroller.add_child(seed_content)
		for i in FarmGameState.CROP_ORDER.size():
			var id: String = FarmGameState.CROP_ORDER[i]
			var info: Dictionary = FarmGameState.CROPS[id]
			var eligible := game.level >= int(info["level"])
			var count: int = game.seeds[id]
			var color := Color("f4d38e") if game.selected_crop == id else Color("f0ecd9")
			var chip := button(
				seed_content,
				str(info["name"]) + "\n" + (str(count) if eligible else "LV" + str(info["level"])),
				Vector2(i * 132, 0),
				Vector2(122, 59),
				color,
				INK if eligible else SOFT_INK,
				16
			)
			chip.disabled = not eligible
			chip.pressed.connect(func() -> void: choose_crop(id))
		seed_scroller.set_deferred("scroll_horizontal", seed_scroll_left)
		var chosen: String = game.selected_crop
		var can := game.can_plant(selected_plot, chosen)
		var text := (
			"TANAM " + str(FarmGameState.CROPS[chosen]["name"]).to_upper()
			if can
			else "BIBIT HABIS • KUNJUNGI TOKO"
		)
		var grow: int = FarmGameState.CROPS[chosen]["grow"]
		var planting := button(
			action_panel,
			text + ("   ·   " + str(grow) + " DETIK" if can else ""),
			Vector2(23, 128),
			Vector2(644, 70),
			GREEN if can else Color("a9c4a0"),
			Color.WHITE,
			22
		)
		planting.pressed.connect(on_plant)
	else:
		var info: Dictionary = FarmGameState.CROPS[crop_id]
		var ready := game.is_ready(selected_plot)
		var shortage := maxi(0, game.storage_used() + int(info["yield"]) - game.storage_capacity)
		var status := "Tumbuh • %d detik lagi" % maxi(0, int(plot["ready_at"]) - game.now())
		if ready:
			status = "Perlu %d slot kosong di gudang" % shortage if shortage > 0 else "Siap dipanen!"
		label(
			action_panel,
			str(info["name"]) + "  ·  " + status,
			Vector2(23, 58),
			Vector2(644, 42),
			23,
			GREEN if ready else SOFT_INK,
			true
		)
		var harvest_text := "PERCEPAT PANEN  •  1 PERMATA"
		if ready:
			harvest_text = "KOSONGKAN GUDANG  •  %d SLOT" % shortage if shortage > 0 else "PANEN SEKARANG  +%d" % int(info["yield"])
		var harvest := button(
			action_panel,
			harvest_text,
			Vector2(23, 124),
			Vector2(644, 74),
			GREEN if ready else Color("d3a759"),
			Color.WHITE,
			22
		)
		harvest.disabled = not ready and game.diamonds < 1
		harvest.pressed.connect(on_harvest_or_speed)


func on_plot_pressed(index: int) -> void:
	selected_plot = index
	action_panel.show()
	refresh_action()


func on_farm_swipe_requested(mode: String, plot_indices: PackedInt32Array) -> void:
	var changed := 0
	var total_yield := 0
	if mode == "harvest":
		for index in plot_indices:
			var amount := game.harvest(index)
			if amount > 0:
				changed += 1
				total_yield += amount
				farm.show_plot_feedback(index, "harvest", amount)
		if changed > 0:
			show_toast("Panen %d petak! +%d hasil masuk gudang." % [changed, total_yield])
		else:
			switch_tab("gudang")
			show_toast("Ruang gudang kurang untuk panen. Pilih jumlah barang yang dijual.")
	elif mode == "plant":
		for index in plot_indices:
			if game.plant(index, game.selected_crop):
				changed += 1
				farm.show_plot_feedback(index, "plant")
		if changed > 0:
			show_toast("%d petak berhasil ditanami!" % changed)
		elif int(game.seeds.get(game.selected_crop, 0)) == 0:
			show_toast(
				"Bibit habis. Cek bantuan gratis di TOKO."
				if game.needs_seed_recovery() else "Bibit habis. Beli lagi di TOKO."
			)
	if changed > 0:
		hide_action_panel()
		refresh_all()


func hide_action_panel() -> void:
	action_panel.hide()


func on_coop_pressed() -> void:
	if game.collect_eggs():
		show_toast("Ayam menghasilkan 2 telur! +8 XP")
	else:
		show_toast("Ayam sedang bertelur, atau gudang sudah penuh.")
	refresh_all()


func on_plant() -> void:
	if game.plant(selected_plot, game.selected_crop):
		farm.show_plot_feedback(selected_plot, "plant")
		show_toast("Bibit " + str(FarmGameState.CROPS[game.selected_crop]["name"]) + " ditanam!")
	else:
		switch_tab("toko")
	refresh_all()


func on_harvest_or_speed() -> void:
	if game.is_ready(selected_plot):
		var crop_id: String = str(game.plots[selected_plot]["crop"])
		var yield_amount := int(FarmGameState.CROPS[crop_id]["yield"])
		if game.storage_used() + yield_amount > game.storage_capacity:
			switch_tab("gudang")
			var shortage := game.storage_used() + yield_amount - game.storage_capacity
			show_toast("Kosongkan %d slot agar panen bisa diambil." % shortage)
			return
		var quantity := game.harvest(selected_plot)
		if quantity > 0:
			farm.show_plot_feedback(selected_plot, "harvest", quantity)
			show_toast("Panen berhasil! +" + str(quantity) + " hasil masuk gudang.")
		else:
			show_toast("Ruang gudang kurang. Jual hasil di GUDANG.")
	elif game.accelerate(selected_plot):
		farm.show_plot_feedback(selected_plot, "plant")
		show_toast("Panen dipercepat dengan 1 permata!")
	refresh_all()


func on_unlock_plot() -> void:
	if game.unlock_plot(selected_plot):
		show_toast("Lahan baru terbuka! +10 XP")
	else:
		show_toast("Koin belum cukup untuk membuka lahan.")
	refresh_all()


func choose_crop(id: String) -> void:
	game.selected_crop = id
	game.save_game()
	refresh_all()


func buy_crop(id: String, count: int = 5) -> void:
	if game.buy_seeds(id, count):
		show_toast(str(count) + " bibit " + str(FarmGameState.CROPS[id]["name"]) + " dibeli!")
	else:
		show_toast("Koin belum cukup atau bibit terkunci.")
	refresh_all()


func on_claim_seed_recovery() -> void:
	if game.claim_seed_recovery():
		show_toast("+3 bibit gandum! Tanam, panen, lalu jual hasilnya.")
	else:
		show_toast("Bantuan belum tersedia. Coba panen atau jual telur.")
	refresh_all()


func send_delivery(index: int) -> void:
	if game.deliver_order(index):
		farm.start_delivery_animation()
		show_toast("Pesanan terkirim! Koin dan XP bertambah.")
		if ads:
			ads.maybe_show_interstitial(game.deliveries)
	else:
		show_toast("Hasil panen untuk pesanan belum cukup.")
	refresh_all()


func _on_ad_reward_granted(gems: int) -> void:
	game.diamonds += gems
	game.save_game()
	refresh_all()
	show_toast("Bonus berhasil! +%d permata." % gems)


func sell_crop(id: String, quantity: int) -> void:
	var reward := game.sell_quantity(id, quantity)
	if reward > 0:
		show_toast("Terjual %d %s! +%d koin" % [quantity, str(game.item_info(id)["name"]), reward])
	refresh_all()


func upgrade_barn() -> void:
	if game.upgrade_storage():
		show_toast("Gudang diperbesar! +30 kapasitas.")
	refresh_all()


func confirm_new_game() -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.title = "Mulai permainan baru?"
	confirmation.dialog_text = "Semua progres kebun saat ini akan dihapus. Lanjutkan?"
	confirmation.ok_button_text = "Mulai ulang"
	confirmation.cancel_button_text = "Batalkan"
	add_child(confirmation)
	confirmation.confirmed.connect(
		func() -> void:
			game.new_game()
			game.save_game()
			selected_plot = 0
			farm.selected_plot = 0
			switch_tab("kebun")
			refresh_all()
			show_toast("Kebun baru siap! Selamat bertani.")
	)
	confirmation.canceled.connect(confirmation.queue_free)
	confirmation.confirmed.connect(confirmation.queue_free)
	confirmation.popup_centered()


func show_toast(message: String) -> void:
	for node in toast_layer.get_children():
		node.queue_free()
	var toast := panel(toast_layer, Vector2(69, 849), Vector2(582, 67), Color("3d7653"), 24, 4)
	# Notifications must never block the next farm touch or drag.
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption := label(toast, message, Vector2(17, 11), Vector2(548, 45), 19, Color.WHITE, true)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.17)
	tween.tween_interval(2.6)
	tween.tween_property(toast, "modulate:a", 0.0, 0.25)
	tween.tween_callback(toast.queue_free)


func panel(
	parent: Node, pos: Vector2, dimensions: Vector2, bg: Color, radius: int = 18, shadow: int = 0
) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.custom_minimum_size = dimensions
	p.size = dimensions
	p.add_theme_stylebox_override("panel", style(bg, radius, shadow))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(p)
	return p


func style(color: Color, radius: int = 14, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = color.darkened(0.11)
	s.anti_aliasing = true
	if shadow > 0:
		s.shadow_color = Color(0.30, 0.40, 0.24, 0.17)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.5)
	return s


func label(
	parent: Node,
	content: String,
	pos: Vector2,
	dimensions: Vector2,
	font_size: int,
	color: Color,
	bold: bool = false
) -> Label:
	var l := Label.new()
	l.text = content
	l.position = pos
	l.size = dimensions
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_color_override(
			"font_shadow_color", Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, 0.05)
		)
		l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func button(
	parent: Node,
	caption: String,
	pos: Vector2,
	dimensions: Vector2,
	bg: Color,
	color: Color,
	font_size: int = 20
) -> Button:
	var b := Button.new()
	b.text = caption
	b.position = pos
	b.size = dimensions
	b.custom_minimum_size = dimensions
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", color)
	b.add_theme_color_override("font_pressed_color", color)
	b.add_theme_color_override("font_disabled_color", color.darkened(0.12))
	b.add_theme_stylebox_override("normal", style(bg, 17, 2))
	b.add_theme_stylebox_override("hover", style(bg.lightened(0.09), 17, 2))
	b.add_theme_stylebox_override("pressed", style(bg.darkened(0.08), 17))
	b.add_theme_stylebox_override("disabled", style(bg, 17))
	b.pivot_offset = dimensions * 0.5
	b.button_down.connect(func() -> void: animate_press(b, true))
	b.button_up.connect(func() -> void: animate_press(b, false))
	b.mouse_exited.connect(func() -> void: animate_press(b, false))
	parent.add_child(b)
	return b


func animate_press(target: Control, pressed: bool) -> void:
	if not is_instance_valid(target):
		return
	var motion := target.create_tween()
	motion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(target, "scale", Vector2.ONE * (0.955 if pressed else 1.0), 0.09)


func circle(center: Vector2, radius: float, color: Color) -> Control:
	var shape := CircleIcon.new()
	shape.position = center - Vector2(radius, radius)
	shape.size = Vector2(radius * 2, radius * 2)
	shape.color = color
	return shape


func row_card(parent: Node, height: int, bg: Color) -> Panel:
	var row := panel(parent, Vector2.ZERO, Vector2(601, height), bg, 19)
	row.custom_minimum_size = Vector2(601, height)
	return row


func callout(parent: Node, title: String, caption: String, bg: Color) -> Panel:
	var card := row_card(parent, 106, bg)
	label(card, title, Vector2(20, 17), Vector2(555, 34), 21, GREEN, true)
	label(card, caption, Vector2(20, 55), Vector2(555, 35), 17, SOFT_INK)
	return card


class CircleIcon:
	extends Control
	var color := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(size * 0.5, minf(size.x, size.y) * 0.5, color)
