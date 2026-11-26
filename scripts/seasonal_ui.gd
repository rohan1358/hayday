extends Control

const SEASONS = ["Semi", "Panas", "Gugur", "Dingin"]
const REGION_INFO={"spring":{"season":0,"weather":"Cerah","detail":"Angin lembut dan kelopak sakura"},"summer":{"season":1,"weather":"Terik","detail":"Sinar hangat musim panas"},"autumn":{"season":2,"weather":"Berangin","detail":"Angin sejuk dan daun berguguran"},"winter":{"season":3,"weather":"Salju","detail":"Salju turun perlahan"},"central":{"season":0,"weather":"Cerah","detail":"Pusat desa · Cuaca netral"}}
const COLORS = ["82b76b", "e8bd59", "c87848", "76a9ce"]
const OUTFITS = ["Baju Berkebun", "Kemeja Pantai", "Jaket Daun", "Mantel Salju"]
const ACCESSORIES = ["Topi Bunga", "Kacamata Surya", "Syal Rajut", "Kupluk Hangat"]
const EQUIPMENT = ["Rumah Bibit", "Tangki Penyiram", "Gudang Daun", "Rumah Kaca"]
const TIPS = ["Spring Valley: kelopak sakura dan angin lembut.", "Summer Meadow: cerah dengan cahaya hangat.", "Autumn Hollow: angin sejuk dan daun berguguran.", "Winter Peak: salju turun perlahan."]
var host
var panel: PanelContainer
var content: VBoxContainer
var badge: Button
var wardrobe_editor: PanelContainer
var clock := 0.0
var season := 0
var weather := ""
var current_region=""
var pending_region=""
var region_dwell=0.0
var last_announced_region=""
var entry_count=0
var effects
var entry_banner: Panel
var entry_title: Label
var entry_description: Label
var entry_tween: Tween

func _ready() -> void:
	host = get_parent()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge = Button.new()
	badge.position = Vector2(12, 150)
	badge.custom_minimum_size = Vector2(260, 42)
	wardrobe_editor = preload("res://scripts/wardrobe_editor.gd").new()
	wardrobe_editor.host = host
	add_child(wardrobe_editor)
	badge.pressed.connect(wardrobe_editor.open)
	add_child(badge)
	panel = PanelContainer.new()
	panel.z_index = 50
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("fff9eb")
	paper.set_corner_radius_all(18)
	paper.content_margin_left = 18
	paper.content_margin_right = 18
	paper.content_margin_top = 16
	paper.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", paper)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_top = 150
	panel.offset_bottom = -145
	add_child(panel)
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	panel.hide()
	effects=preload("res://scripts/regional_weather.gd").new()
	effects.name="RegionalWeather"
	effects.farm=host.farm
	effects.host=host
	host.farm.add_child(effects)
	build_entry_banner()
	refresh_weather()

func _process(delta: float) -> void:
	clock+=delta
	var region=preload("res://scripts/four_seasons.gd").region(host.farm.ujang_position)
	if region!=pending_region:pending_region=region;region_dwell=0
	region_dwell+=delta
	if region_dwell>=0.25 and (region!=current_region or clock>0.25):
		clock=0
		refresh_weather()
	if host.active_tab!="kebun":entry_banner.hide()
	elif bool(host.game.ftue.get("started",false)) and current_region!=last_announced_region and region_dwell>=0.25:
		animate_entry(current_region)

func refresh_weather() -> void:
	var data: Dictionary=host.game.seasonal
	if str(data.get("weather_model",""))!="regional":
		if int(data.get("epoch",0))==0:data.epoch=int(Time.get_unix_time_from_system())
		data.preview=-1
		data.weather_model="regional"
		data.erase("weather")
		data.erase("weather_epoch")
		data.erase("weather_seed")
		host.game.save_game()
	current_region=preload("res://scripts/four_seasons.gd").region(host.farm.ujang_position)
	season=int(REGION_INFO[current_region].season)
	weather=str(REGION_INFO[current_region].weather)
	badge.text="EDIT KARAKTER • %s | %s"%[preload("res://scripts/four_seasons.gd").DATA[current_region].name,weather]
	host.farm.self_modulate=Color.WHITE

func build_entry_banner() -> void:
	entry_banner=Panel.new()
	entry_banner.name="RegionEntryBanner"
	entry_banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	entry_banner.z_index=20
	var paper=StyleBoxFlat.new()
	paper.bg_color=Color("fff7de")
	paper.border_color=Color("dca64f")
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(20)
	paper.content_margin_left=18;paper.content_margin_right=18
	paper.content_margin_top=10;paper.content_margin_bottom=10
	entry_banner.add_theme_stylebox_override("panel",paper)
	add_child(entry_banner)
	entry_title=Label.new();entry_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	entry_title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	entry_title.theme_type_variation="GardenHeading";entry_title.set_meta("typography_role","heading")
	entry_title.add_theme_font_size_override("font_size",25)
	entry_title.add_theme_color_override("font_color",Color("315b39"))
	entry_title.position=Vector2(18,10)
	entry_banner.add_child(entry_title)
	entry_description=Label.new();entry_description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	entry_description.mouse_filter=Control.MOUSE_FILTER_IGNORE
	entry_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	entry_description.add_theme_font_size_override("font_size",18)
	entry_description.add_theme_color_override("font_color",Color("715534"))
	entry_description.position=Vector2(18,45)
	entry_banner.add_child(entry_description)
	entry_banner.hide()

func animate_entry(id: String) -> void:
	if not REGION_INFO.has(id):return
	last_announced_region=id
	entry_count+=1
	effects.enter_region(id)
	entry_title.text=str(preload("res://scripts/four_seasons.gd").DATA[id].name)
	entry_description.text=str(REGION_INFO[id].detail)
	var width=minf(maxf(size.x-40,250),430)
	entry_banner.size=Vector2(width,88)
	entry_title.size=Vector2(width-36,33)
	entry_description.size=Vector2(width-36,30)
	var destination=Vector2((size.x-width)*0.5,205)
	entry_banner.position=destination+Vector2(0,-18)
	entry_banner.modulate.a=0
	entry_banner.show()
	if entry_tween!=null:entry_tween.kill()
	entry_tween=create_tween().set_parallel(true)
	entry_tween.tween_property(entry_banner,"position",destination,0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entry_tween.tween_property(entry_banner,"modulate:a",1.0,0.35)
	entry_tween.chain().tween_interval(2.0)
	entry_tween.chain().tween_property(entry_banner,"modulate:a",0.0,0.45)
	entry_tween.chain().tween_callback(entry_banner.hide)

func label_line(value: String, font_size := 20) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", Color("344b39"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	content.add_child(label)

func button_line(value: String, action: Callable) -> void:
	var button := Button.new()
	button.text = value
	var style := StyleBoxFlat.new()
	style.bg_color = Color("dbe9d2")
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_color_override("font_color", Color("344b39"))
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	content.add_child(button)

func open_shop() -> void:
	for child in content.get_children():
		child.queue_free()
	panel.show()
	label_line("LEMARI & PERSIAPAN MUSIM", 26)
	button_line("TUTUP", func(): panel.hide())
	label_line("%s • %s | %d koin" % [SEASONS[season], weather, host.game.coins])
	label_line("Cuaca mengikuti kawasan: Semi di Spring Valley, Panas di Summer Meadow, Gugur di Autumn Hollow, dan Salju di Winter Peak. Pusat desa netral.",17)
	for i in 4:
		label_line("MUSIM " + SEASONS[i].to_upper(), 23)
		label_line(TIPS[i], 17)
		button_line("BUKA PAKET FIGUR MUSIM "+SEASONS[i].to_upper(), open_pack.bind(i))
		item_button("equipment", i, EQUIPMENT[i], 100)
		item_button("decor", i, ["Pot Bunga", "Payung Taman", "Lentera Panen", "Boneka Salju"][i], 55)
	label_line("Perlengkapan + pakaian sesuai musim: bonus persiapan 15 koin sekali per musim per siklus.", 17)
	button_line("KLAIM BONUS PERSIAPAN", claim)

func open_pack(index: int) -> void:
	panel.hide()
	wardrobe_editor.selected_season=index
	wardrobe_editor.open()

func preview(index: int) -> void:
	# Preview is for clothing only; it never changes regional weather.
	open_pack(index)

func item_button(kind: String, index: int, title: String, price: int) -> void:
	var key := kind + str(index)
	var owned: bool = key in host.game.seasonal.owned
	var suffix := "MILIKMU" if owned else "%d koin" % price
	if owned and kind in ["outfit", "accessory"]:
		suffix = "DIPAKAI" if int(host.game.seasonal.get(kind, -1)) == index else "PAKAI"
	button_line("%s • %s" % [title, suffix], buy.bind(kind, index, price))

func buy(kind: String, index: int, price: int) -> void:
	var data: Dictionary = host.game.seasonal
	var key := kind + str(index)
	if key not in data.owned:
		if host.game.coins < price:
			host.show_toast("Koin belum cukup. Panen atau kirim pesanan dulu.")
			return
		host.game.coins -= price
		data.owned.append(key)
	if kind in ["outfit", "accessory"]:
		data[kind] = index
	persist()
	open_shop()

func claim() -> void:
	var data: Dictionary = host.game.seasonal
	var cycle := int(maxi(0, int(Time.get_unix_time_from_system()) - int(data.epoch)) / 2400)
	var key := "%d:%d" % [cycle, season]
	var pack_season=preload("res://scripts/seasonal_character_packs.gd").equipped(data)
	var dressed_season=pack_season if pack_season>=0 else int(data.outfit)
	if dressed_season != season or "equipment" + str(season) not in data.owned:
		host.show_toast("Pakai baju musim ini dan beli perlengkapannya dahulu.")
		return
	if key in data.claimed:
		host.show_toast("Bonus musim ini sudah diambil.")
		return
	data.claimed.append(key)
	host.game.coins += 15
	persist()
	open_shop()

func persist() -> void:
	host.game.save_game()
	host.refresh_all()
	host.farm.queue_redraw()
	refresh_weather()

func choose_character(gender: String) -> void:
	preload("res://scripts/wardrobe_catalog.gd").select_gender(host.game.seasonal,gender)
	persist()
	open_shop()

func _draw() -> void:
	# All particles now belong to world-space RegionalWeather, never the UI.
	pass
