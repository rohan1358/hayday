extends PanelContainer
const CATALOG=preload("res://scripts/wardrobe_catalog.gd")
const PACKS=preload("res://scripts/seasonal_character_packs.gd")
const ART = preload("res://scripts/wardrobe_assets.gd")
const PREVIEW = preload("res://scripts/wardrobe_preview.gd")
const SEASONS := ["Semi", "Panas", "Gugur", "Dingin"]
const OUTFITS := ["Overall Kebun", "Linen Pantai", "Kardigan Panen", "Mantel Hangat"]
var host
var body: VBoxContainer
var balance: Label
var selected_season := 0
var category := "outfit"
var preview_sector := 0
var scroll: ScrollContainer

func _ready() -> void:
	z_index=70
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left=16
	offset_right=-16
	offset_top=148
	offset_bottom=-132
	var paper := StyleBoxFlat.new()
	paper.bg_color=Color("fff9ed")
	paper.set_corner_radius_all(20)
	paper.content_margin_left=18
	paper.content_margin_right=18
	paper.content_margin_top=16
	paper.content_margin_bottom=16
	add_theme_stylebox_override("panel",paper)
	var layout=VBoxContainer.new()
	add_child(layout)
	var header=HBoxContainer.new()
	layout.add_child(header)
	text(header,"EDIT KARAKTER",25).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var done=button(header,"SELESAI",close_editor,true)
	done.name="WardrobeDone"
	done.custom_minimum_size=Vector2(160,56)
	done.size_flags_horizontal=Control.SIZE_SHRINK_END
	scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	body=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	scroll.add_child(body)
	hide()

func text(parent: Node, value: String, font_size := 20) -> Label:
	var label := Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("355b48"))
	parent.add_child(label)
	return label

func button(parent: Node, value: String, action: Callable, active := false) -> Button:
	var b := Button.new()
	b.text=value
	b.custom_minimum_size.y=48
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color=Color("387956") if active else Color("e4ecd9")
	style.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal",style)
	b.add_theme_color_override("font_color",Color.WHITE if active else Color("355b48"))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func close_editor() -> void:
	var focus=get_viewport().gui_get_focus_owner()
	if focus!=null: focus.release_focus()
	hide()
	host.farm.set_panel_obscured(host.active_tab!="kebun")

func open() -> void:
	host.switch_tab("kebun")
	show()
	scroll.scroll_vertical=0
	rebuild()

func save() -> void:
	CATALOG.remember(host.game.seasonal)
	host.game.save_game()
	host.refresh_all()
	host.farm.queue_redraw()
	if host.farm.mobile_ujang_layer!=null: host.farm.mobile_ujang_layer.queue_redraw()

func rebuild() -> void:
	for node in body.get_children():
		body.remove_child(node)
		node.queue_free()
	var data: Dictionary=host.game.seasonal
	var top := HBoxContainer.new()
	body.add_child(top)
	button(top,"CUACA & PERSIAPAN",func(): hide(); get_parent().open_shop())
	text(body,"%d KOIN • pembelian memakai koin hasil panen"%host.game.coins,17)
	var views:=HBoxContainer.new()
	body.add_child(views)
	for i in 5:
		button(views,["Depan","Serong","Samping","Balik","Belakang"][i],select_view.bind(i),preview_sector==i)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation",14)
	body.add_child(cards)
	for gender in ["male","female"]:
		var card := VBoxContainer.new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		cards.add_child(card)
		var preview := PREVIEW.new()
		preview.data=data.duplicate(true)
		preview.data.wardrobe_slots=CATALOG.slots_for(data,gender).duplicate(true)
		preview.data.gender=gender
		preview.sector=preview_sector
		preview.custom_minimum_size=Vector2(150,270)
		card.add_child(preview)
		var active: bool=str(data.get("gender","male"))==gender
		button(card,("LAKI-LAKI" if gender=="male" else "PEREMPUAN")+(" • AKTIF" if active else ""),select_gender.bind(gender),active)
	var name_input := LineEdit.new()
	name_input.text=str(data.get("name","Ujang"))
	name_input.placeholder_text="Nama petani"
	name_input.max_length=20
	body.add_child(name_input)
	button(body,"SIMPAN NAMA",func():
		var value:=name_input.text.strip_edges()
		if value.is_empty(): value="Ujang"
		data.name=value
		save()
		host.show_toast("Nama petani disimpan."))
	var filters := HBoxContainer.new()
	body.add_child(filters)
	for i in 4: button(filters,SEASONS[i],filter_season.bind(i),selected_season==i)
	text(body,"PAKET AKSESORI MUSIM "+SEASONS[selected_season].to_upper(),23)
	text(body,"Satu paket figur lengkap: topi, syal/bandana, sabuk tas, dan pakaian. Depan dan belakang langsung terpasang bersama.",16)
	var paired:=HBoxContainer.new()
	paired.add_theme_constant_override("separation",12)
	body.add_child(paired)
	var gender=str(data.get("gender","male"))
	for direction in [0,4]:
		var card:=VBoxContainer.new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		paired.add_child(card)
		var sample:=data.duplicate(true)
		if not sample.has("seasonal_pack_gender"): sample.seasonal_pack_gender={}
		sample.seasonal_pack_gender[gender]=selected_season
		if PACKS.key(gender,selected_season) not in sample.owned: sample.owned.append(PACKS.key(gender,selected_season))
		var preview:=PREVIEW.new()
		preview.data=sample
		preview.sector=direction
		preview.custom_minimum_size=Vector2(150,300)
		card.add_child(preview)
		text(card,"DEPAN" if direction==0 else "BELAKANG",16)
	var owned: bool=PACKS.key(gender,selected_season) in data.owned
	var active: bool=PACKS.equipped(data)==selected_season
	button(body,"TERPASANG" if active else ("PASANG PAKET" if owned else "BELI & PASANG PAKET • %d KOIN"%PACKS.PRICE),purchase.bind("pack",selected_season),active)
	button(body,"LEPAS PAKET • KARAKTER DASAR",reset_outfit)

func select_gender(value: String) -> void:
	CATALOG.select_gender(host.game.seasonal,value)
	save()
	rebuild()
func filter_season(value: int) -> void:
	selected_season=value
	rebuild()
func filter_category(value: String) -> void:
	category=value
	rebuild()
func price(index: int) -> int:
	return CATALOG.price(index)
func purchase(kind: String,index: int) -> void:
	if kind!="pack" or not PACKS.valid(index): return
	if not PACKS.buy_and_equip(host.game,index):
		host.show_toast("Koin belum cukup. Panen atau kirim pesanan dulu.")
		return
	save()
	rebuild()
	show_equipped.call_deferred()
	host.show_toast(PACKS.NAMES[index]+" terpasang, depan dan belakang sekaligus!")
func show_equipped() -> void:
	scroll.scroll_vertical = 0
func unequip(slot: String) -> void:
	var data: Dictionary=host.game.seasonal
	if data.has("wardrobe_slots"): data.wardrobe_slots.erase(slot)
	save()
	rebuild()
func reset_outfit() -> void:
	host.game.seasonal.seasonal_pack_gender[str(host.game.seasonal.get("gender","male"))]=-1
	host.game.seasonal.wardrobe_slots={}
	save()
	rebuild()

func select_view(value: int) -> void:
	preview_sector=clampi(value,0,4)
	rebuild()
