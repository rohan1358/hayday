extends Control
signal dismissed(open_missions: bool)
const JOURNEY=preload("res://scripts/level_journey.gd")
var host
var reached_level=2
var paper: Panel
var elapsed=0.0
var closing=false
func label_at(parent,text: String,at: Vector2,extent: Vector2,font: int,color: Color=Color("425126")) -> Label:
	var node=Label.new();node.set_meta("typography_extent",extent);node.text=text;node.position=at;node.size=extent
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size",font);node.add_theme_color_override("font_color",color)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node);return node
func _ready():
	name="AnimatedLevelUp";z_index=150
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	var shade=ColorRect.new();shade.color=Color(0.08,0.18,0.04,0.58);shade.mouse_filter=Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
	paper=Panel.new();paper.set_meta("colorful_applied",true);paper.size=Vector2(640,820);paper.pivot_offset=paper.size*0.5
	var box=StyleBoxFlat.new();box.bg_color=Color("fff0ca");box.border_color=Color("bb793f")
	box.set_border_width_all(10);box.set_corner_radius_all(36);box.shadow_color=Color("183d2366");box.shadow_size=18;box.shadow_offset=Vector2(0,12)
	paper.add_theme_stylebox_override("panel",box);add_child(paper)
	var header=TextureRect.new();header.texture=load("res://assets/cheerful/level_header.png")
	header.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;header.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.position=Vector2(0,-40);header.size=Vector2(640,260);header.mouse_filter=Control.MOUSE_FILTER_IGNORE;paper.add_child(header)
	var badge=label_at(paper,str(reached_level),Vector2(260,13),Vector2(120,80),50 if str(reached_level).length()<4 else 32,Color("8d4b09"))
	badge.name="DynamicLevelNumber"
	var ribbon_title=label_at(paper,"Naik Level!",Vector2(80,112),Vector2(480,65),45,Color("fff4b5"))
	ribbon_title.add_theme_color_override("font_outline_color",Color("80501b"))
	ribbon_title.add_theme_constant_override("outline_size",5)
	label_at(paper,"Selamat! Kamu mencapai Level %d."%reached_level,Vector2(30,218),Vector2(580,55),27)
	var items=JOURNEY.unlocks(host.game,reached_level)
	for i in mini(3,items.size()):
		var card=Panel.new();card.set_meta("colorful_applied",true);card.position=Vector2((640-mini(3,items.size())*202)*0.5+i*202,290);card.size=Vector2(192,190)
		var style=StyleBoxFlat.new();style.bg_color=Color("ffe6a3");style.border_color=Color("fff9dc");style.set_border_width_all(3);style.set_corner_radius_all(24)
		card.add_theme_stylebox_override("panel",style);paper.add_child(card)
		var icon=TextureRect.new();icon.texture=unlock_icon(items[i])
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position=Vector2(38,12);icon.size=Vector2(116,104);card.add_child(icon)
		var item_name=str(items[i].name).replace(" · Beli di Kawasan", "").replace(" · Beli di Toko", "")
		var title=label_at(card,item_name,Vector2(8,112),Vector2(176,70),18)
		title.max_lines_visible=3;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		card.modulate.a=0;var tween=card.create_tween();tween.tween_interval(0.18+i*0.1);tween.tween_property(card,"modulate:a",1.0,0.25)
	var next=JOURNEY.goals(reached_level)
	var objective="Misi Level %d:\n"%reached_level
	for goal in next: objective+="• %s: %d\n"%[goal.name,goal.goal]
	var portrait=TextureRect.new();portrait.texture=load("res://assets/cheerful/app_icon.png");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.position=Vector2(28,512);portrait.size=Vector2(100,100);paper.add_child(portrait)
	var mission=label_at(paper,objective.strip_edges(),Vector2(145,495),Vector2(465,140),21)
	mission.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	var reward=JOURNEY.reward(reached_level)
	var reward_text=label_at(paper,"Hadiah misi: %d koin + %d XP"%[reward.coins,reward.xp],Vector2(28,690),Vector2(584,34),21)
	reward_text.name="LevelMissionReward"
	label_at(paper,"+2 permata diterima · Klaim hadiah setelah misi selesai",Vector2(28,728),Vector2(584,22),14)
	for x in [8,548]:
		var flowers=TextureRect.new();flowers.texture=preload("res://scripts/colorful_icons.gd").texture("bunga")
		flowers.position=Vector2(x,737);flowers.size=Vector2(84,74)
		flowers.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flowers.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flowers.mouse_filter=Control.MOUSE_FILTER_IGNORE;paper.add_child(flowers)
	var extra="Bangunan tetap harus dibeli. Tata kebunmu tersimpan."
	if items.size()>3:
		var names=[]
		for i in range(3,items.size()): names.append(str(items[i].name))
		extra="Bangunan perlu dibeli; tata kebun tersimpan.\nJuga terbuka: "+", ".join(names)+"."
	var details=ScrollContainer.new();details.name="ExtraUnlocks";details.position=Vector2(32,630);details.size=Vector2(576,53)
	details.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;paper.add_child(details)
	var more=Label.new();more.text=extra;more.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;more.custom_minimum_size.x=550;more.add_theme_font_size_override("font_size",15);more.add_theme_color_override("font_color",Color("425126"));details.add_child(more)
	var go=Button.new();go.set_meta("colorful_applied",true);go.name="LevelUpMissions";go.text="Lihat Misi  ›";go.position=Vector2(125,750);go.size=Vector2(390,54)
	var green=StyleBoxFlat.new();green.bg_color=Color("25ad32");green.border_color=Color("f8ce53");green.set_border_width_all(4);green.set_corner_radius_all(26)
	go.add_theme_stylebox_override("normal",green);go.add_theme_font_size_override("font_size",28);go.add_theme_color_override("font_color",Color.WHITE)
	paper.add_child(go);go.pressed.connect(finish.bind(true))
	var close=Button.new();close.set_meta("colorful_applied",true);close.name="LevelUpClose";close.text="×";close.position=Vector2(576,190);close.size=Vector2(48,48)
	var red=green.duplicate();red.bg_color=Color("e7503f");red.border_color=Color("ffc4a2")
	close.add_theme_stylebox_override("normal",red);close.add_theme_font_size_override("font_size",34);close.add_theme_color_override("font_color",Color.WHITE)
	paper.add_child(close);close.pressed.connect(finish.bind(false))
	resized.connect(arrange);arrange()
	var final_scale=paper.scale;paper.scale=final_scale*0.78;paper.modulate.a=0
	var enter=create_tween().set_parallel(true);enter.tween_property(paper,"scale",final_scale,0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.tween_property(paper,"modulate:a",1.0,0.25)
	get_tree().call_group("garden_audio","play","level")
func unlock_icon(item: Dictionary) -> Texture2D:
	if item.has("crop"): return host.seed_icon_texture(str(item.crop))
	var actual: Dictionary=host.farm.farm_art.sprites.get(str(item.get("asset","")),{})
	if not actual.is_empty():
		var texture=AtlasTexture.new();texture.atlas=actual.texture;texture.region=actual.region;return texture
	if str(item.icon)=="jalan": return preload("res://scripts/road_painter.gd").preview("stone")
	if str(item.icon)=="rumput": return load("res://assets/decor/grass_patch.svg") as Texture2D
	if str(item.icon)=="bunga":
		var sprite: Dictionary=host.farm.farm_art.sprites.get("flowering_hedge",{})
		if not sprite.is_empty():
			var tex=AtlasTexture.new();tex.atlas=sprite.texture;tex.region=sprite.region;return tex
	return preload("res://scripts/colorful_icons.gd").texture(str(item.icon))
func arrange():
	if paper==null: return
	var factor=minf((size.x-26)/640.0,(size.y-90)/860.0)
	factor=maxf(0.2,factor)
	paper.scale=Vector2.ONE*factor;paper.position=(size-paper.size)*0.5+Vector2(0,20)
func _process(dt):
	elapsed+=dt
	if elapsed<3.5: queue_redraw()
func _draw():
	var alpha=maxf(0,1-elapsed/3.5)
	for i in 28:
		var x=fposmod(float(i*137)+sin(elapsed+i)*22,maxf(1,size.x))
		var y=fposmod(float(i*73)+elapsed*65,maxf(1,size.y))
		var radius=3+absf(sin(elapsed*4+i))*4
		draw_line(Vector2(x-radius,y),Vector2(x+radius,y),Color(1,0.83,0.25,alpha),2,true)
		draw_line(Vector2(x,y-radius),Vector2(x,y+radius),Color(1,0.96,0.65,alpha),2,true)
func finish(missions: bool):
	if closing: return
	closing=true;dismissed.emit(missions);queue_free()
