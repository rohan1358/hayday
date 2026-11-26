extends Control
const JOBS=preload("res://scripts/industry_jobs.gd")
var host
var kind="penggilingan"
var old_modal=false
var status: Label
var progress: ProgressBar
var claim_button: Button
var start_buttons=[]
var stock_labels={}
var clock=0.0
var preview
func _ready():
 z_index=130;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_STOP
 old_modal=bool(host.get_meta("first_farm_modal",false));host.set_meta("first_farm_modal",true);host.farm.set_panel_obscured(true)
 var shade=ColorRect.new();shade.color=Color(.06,.15,.05,.65);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var paper=PanelContainer.new();paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper.offset_left=20;paper.offset_right=-20;paper.offset_top=155;paper.offset_bottom=-130
 var skin=StyleBoxFlat.new();skin.bg_color=Color("fff3d2");skin.border_color=Color("d58e35");skin.set_border_width_all(6);skin.set_corner_radius_all(28);skin.content_margin_left=18;skin.content_margin_right=18;skin.content_margin_top=14;skin.content_margin_bottom=14;paper.add_theme_stylebox_override("panel",skin);add_child(paper)
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);paper.add_child(column)
 var title_board=PanelContainer.new();column.add_child(title_board)
 var wood=StyleBoxFlat.new();wood.bg_color=Color("de9b42");wood.border_color=Color("a75c25");wood.set_border_width_all(3);wood.set_corner_radius_all(20);wood.content_margin_left=10;wood.content_margin_right=10;wood.content_margin_top=6;wood.content_margin_bottom=6;title_board.add_theme_stylebox_override("panel",wood)
 var top=HBoxContainer.new();title_board.add_child(top)
 var title=label(top,"Penggilingan" if kind=="penggilingan" else "Tambang",34);title.size_flags_horizontal=SIZE_EXPAND_FILL;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var close_button=button(top,"X",close);close_button.custom_minimum_size=Vector2(55,55);close_button.size_flags_horizontal=SIZE_SHRINK_END;close_button.name="IndustryClose"
 var red=StyleBoxFlat.new();red.bg_color=Color("e24c35");red.set_corner_radius_all(22);close_button.add_theme_stylebox_override("normal",red)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
 var body=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
 preview=load("res://scripts/industry_preview.gd").new();preview.window=self;preview.custom_minimum_size=Vector2(580,190 if kind=="penggilingan" else 360);body.add_child(preview)
 label(body,"Mengolah hasil panen menjadi bahan yang lebih berguna." if kind=="penggilingan" else "Pahat batu untuk bahan upgrade. Hasil: 2 batu + 1 palu.",19)
 if kind=="penggilingan":
  var pick=label(body,"PILIH BAHAN",24);pick.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);body.add_child(grid)
  for crop in JOBS.RECIPES:
   var card=PanelContainer.new();card.size_flags_horizontal=SIZE_EXPAND_FILL;card.custom_minimum_size=Vector2(280,190)
   var box=StyleBoxFlat.new();box.bg_color=Color("ffebbb");box.border_color=Color("e1bd78");box.set_border_width_all(2);box.set_corner_radius_all(20);box.content_margin_left=10;box.content_margin_right=10;box.content_margin_top=8;box.content_margin_bottom=8;card.add_theme_stylebox_override("panel",box);grid.add_child(card)
   var stack=VBoxContainer.new();card.add_child(stack)
   var heading=label(stack,str(host.game.item_info(crop).name)+" x2",22);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   var row=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;stack.add_child(row)
   for path in ["res://assets/seed_icons/"+crop+".svg","res://assets/production_icons/tepung.svg"]:
    var icon=TextureRect.new();icon.texture=load(path);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(65,60);row.add_child(icon)
    if row.get_child_count()==1:label(row,">",24)
   var detail=label(stack,"1 hasil - %d mnt - Stok %d"%[int(JOBS.RECIPES[crop].seconds)/60,int(host.game.inventory.get(crop,0))],16);detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;stock_labels[crop]=detail
   var produce=button(stack,"PRODUKSI",start.bind(crop));produce.name="MillProduce_"+crop;produce.set_meta("crop",crop);start_buttons.append(produce)
 else:
  var begin=button(body,"MULAI MENAMBANG - 1 MNT 15 DTK",start.bind(""));begin.name="StartMining";start_buttons.append(begin)
 status=label(column,"",20);status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 progress=ProgressBar.new();progress.custom_minimum_size.y=22;progress.show_percentage=false;column.add_child(progress)
 claim_button=button(column,"AMBIL HASIL",claim);claim_button.name="ClaimIndustryResult"
 update_state()
func label(parent,text,font):
 var node=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.add_theme_font_size_override("font_size",font);node.add_theme_color_override("font_color",Color("674324"));parent.add_child(node);return node
func button(parent,text,action):
 var node=Button.new();node.text=text;node.custom_minimum_size=Vector2(0,52);node.size_flags_horizontal=SIZE_EXPAND_FILL;node.add_theme_font_size_override("font_size",20)
 var skin=StyleBoxFlat.new();skin.bg_color=Color("19a752");skin.border_color=Color("e8c773");skin.set_border_width_all(3);skin.set_corner_radius_all(18);node.add_theme_stylebox_override("normal",skin);node.pressed.connect(action);parent.add_child(node);return node
func start(crop: String):
 host.show_toast(JOBS.start(host.game,kind,crop));update_state()
func claim():
 var ready=JOBS.jobs(host.game).has(kind) and JOBS.remaining(host.game,kind)==0
 var message=JOBS.claim(host.game,kind);host.show_toast(message)
 if ready and message.begins_with("+"):host.farm.show_world_feedback("chop_done",host.farm.object_position("region_"+kind),message)
 update_state()
func update_state():
 var job=JOBS.jobs(host.game).get(kind,{})
 var remaining=JOBS.remaining(host.game,kind)
 for crop in stock_labels:stock_labels[crop].text="1 hasil - %d mnt - Stok %d"%[int(JOBS.RECIPES[crop].seconds)/60,int(host.game.inventory.get(crop,0))]
 status.text="Kapasitas mesin: 1 item / antrean - Waktu produksi 1-2 menit" if job.is_empty() and kind=="penggilingan" else ("Siap memahat batu." if job.is_empty() else ("HASIL SIAP - Ambil hasil di bawah" if remaining==0 else "Waktu tersisa %02d:%02d"%[remaining/60,remaining%60]))
 progress.visible=not job.is_empty();progress.max_value=maxi(1,int(job.get("seconds",1)));progress.value=progress.max_value-remaining
 claim_button.disabled=job.is_empty() or remaining>0
 for node in start_buttons:node.disabled=not job.is_empty() or (kind=="penggilingan" and int(host.game.inventory.get(node.get_meta("crop"),0))<2)
func _process(delta):
 clock+=delta
 if is_instance_valid(status):update_state()
 if is_instance_valid(preview):preview.queue_redraw()
func close():
 host.set_meta("first_farm_modal",old_modal);host.farm.set_panel_obscured(host.active_tab!="kebun");host.refresh_all();queue_free()
