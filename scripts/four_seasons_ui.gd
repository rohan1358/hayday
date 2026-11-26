extends Control

const WORLD=preload("res://scripts/four_seasons.gd")
var host
var map_button: Button
var menu: Panel

func _ready() -> void:
	host=get_parent()
	name="FourSeasonsNavigation"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_button=Button.new()
	map_button.text="PULAU MUSIM"
	map_button.size=Vector2(170,45)
	map_button.add_theme_font_size_override("font_size",18)
	map_button.set_meta("colorful_applied",true)
	map_button.add_theme_stylebox_override("normal",host.style(Color("fff0c5"),18,3))
	map_button.add_theme_color_override("font_color",host.INK)
	add_child(map_button)
	map_button.pressed.connect(toggle)
	resized.connect(arrange)
	arrange()

func arrange() -> void:
	map_button.position=Vector2(size.x-190,235)
	if menu!=null: menu.position=(size-menu.size)*0.5

func _process(_delta: float) -> void:
	map_button.visible=host.active_tab=="kebun" and not bool(host.get_meta("first_farm_modal",false))

func toggle() -> void:
	if is_instance_valid(menu): menu.queue_free();menu=null;return
	menu=Panel.new()
	menu.name="SeasonsMapMenu"
	menu.size=Vector2(minf(600,size.x-40),585)
	menu.add_theme_stylebox_override("panel",host.style(Color("fff4d3"),24,4))
	add_child(menu)
	host.label(menu,"Dunia Empat Pulau",Vector2(20,15),Vector2(menu.size.x-40,45),28,host.GREEN,true).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for i in preload("res://scripts/island_journey.gd").ORDER.size():
		var id: String=preload("res://scripts/island_journey.gd").ORDER[i]
		var data: Dictionary=WORLD.DATA[id]
		var unlocked=preload("res://scripts/island_journey.gd").can_enter(host.game,id)
		var caption=str(data.name)+(" · %d/25 terbuka"%preload("res://scripts/island_journey.gd").opened(host.game,id) if unlocked else " · Selesaikan pulau sebelumnya")
		var button=host.button(menu,caption,Vector2(20,75+i*65),Vector2(menu.size.x-180,55),host.GREEN if unlocked else Color("b79b70"),Color.WHITE,21)
		button.name="VisitSeason_"+id
		button.pressed.connect(func(): visit(id))
		var preview=host.button(menu,"Lihat",Vector2(menu.size.x-150,75+i*65),Vector2(130,55),Color("e7c77e"),host.INK,19)
		preview.name="PreviewSeason_"+id
		preview.pressed.connect(func(): open_preview(id))
	host.label(menu,"Kota pulau Lv %d · Buka 25/25 kawasan untuk melanjutkan."%preload("res://scripts/island_journey.gd").city_level(host.game),Vector2(20,347),Vector2(menu.size.x-40,50),17,host.INK).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var overview=host.button(menu,"LIHAT SELURUH PULAU",Vector2(20,410),Vector2(menu.size.x-40,45),Color("e7c77e"),host.INK,20)
	overview.pressed.connect(func():
		host.farm.hybrid_controller.data.follow=false
		host.farm.zoom_target=host.farm.minimum_camera_zoom()
		host.farm.camera_target=WORLD.SIZE*0.5
		host.farm.clamp_camera_target()
		toggle())
	var districts=host.button(menu,"KAWASAN & BANGUNAN",Vector2(20,470),Vector2(menu.size.x-40,45),host.GREEN,Color.WHITE,20)
	districts.pressed.connect(func(): toggle();host.switch_tab("kawasan"))
	var close=host.button(menu,"TUTUP",Vector2(20,530),Vector2(menu.size.x-40,40),Color("f1dfb6"),host.INK,18)
	close.pressed.connect(toggle)
	arrange()

func visit(id: String) -> void:
	if preload("res://scripts/island_journey.gd").enter(host,id):toggle()

func open_preview(id: String) -> void:
	if is_instance_valid(menu):toggle()
	var preview=preload("res://scripts/island_preview.gd").new()
	preview.host=host;preview.selected=id
	host.add_child(preview)
