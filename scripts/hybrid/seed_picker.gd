extends RefCounted
const FLOW=preload("res://scripts/first_farm.gd")
const STYLE=preload("res://scripts/ranch_presentation.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
static func targets(ui) -> Array:
 var game=ui.system.host.game
 var crop=str(game.selected_crop)
 var reserved={};var seeds=int(game.seeds.get(crop,0))
 if ui.system.append_jobs:
  for job in ui.system.data.jobs+[ui.system.active]:
   if job.get("action","")=="plant":
    reserved[int(job.index)]=true
    if job.get("crop","")==crop: seeds-=1
 var result=[]
 if ui.seed_plot>=0 and (not game.can_plant(ui.seed_plot,crop) or reserved.has(ui.seed_plot)): return []
 for i in game.plots.size():
  if not reserved.has(i) and game.can_plant(i,crop): result.append(i)
 var origin: Vector2=ui.system.farm.plot_center(ui.seed_plot) if ui.seed_plot>=0 else ui.system.farm.ujang_position
 result.sort_custom(func(a,b): return ui.system.farm.plot_center(a).distance_squared_to(origin)<ui.system.farm.plot_center(b).distance_squared_to(origin))
 return result.slice(0,maxi(0,seeds))
static func layout(ui):
 var first=FLOW.active(ui.system.host.game)
 var dim=ui.get_node_or_null("SeedPickerDim")
 if dim==null:
  dim=ColorRect.new();dim.name="SeedPickerDim";dim.color=Color(0.03,0.12,0.05,0.24);dim.z_index=39
  dim.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(dim)
  dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  ui.menu.visibility_changed.connect(func():
   if is_instance_valid(dim): dim.visible=ui.menu.visible and ui.section=="seeds")
 # GUI hit testing follows sibling order, not z_index. Keep the blocker behind the menu.
 ui.move_child(dim,ui.get_child_count()-1)
 ui.move_child(ui.menu,ui.get_child_count()-1)
 dim.show()
 var width=minf(620,ui.size.x-48)
 var height=minf(470 if first else 650,ui.size.y-240)
 ui.menu.custom_minimum_size=Vector2.ZERO
 ui.menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 ui.menu.position=Vector2((ui.size.x-width)*0.5,maxf(160,(ui.size.y-height)*0.5))
 ui.menu.size=Vector2(width,height)
 var skin=STYLE.style(Color("fff6dd"),Color("dca455"),28)
 skin.content_margin_left=16;skin.content_margin_right=16;skin.content_margin_top=14;skin.content_margin_bottom=14
 ui.menu.add_theme_stylebox_override("panel",skin)
 ui.seed_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
static func populate(ui):
 layout(ui)
 var host=ui.system.host;var game=host.game;var first=FLOW.active(game)
 var width=ui.menu.size.x-32
 var header=Control.new();header.custom_minimum_size=Vector2(width,83);ui.content.add_child(header)
 var wood=Panel.new();wood.position=Vector2(45,0);wood.size=Vector2(width-100,48)
 wood.add_theme_stylebox_override("panel",STYLE.style(Color("d69a50"),Color("ffe1a0"),18));header.add_child(wood)
 ICON.add(wood,"bibit",Vector2(9,5),Vector2(38,38))
 var title=host.label(wood,"Pilih Bibit",Vector2(70,1),Vector2(width-150,45),31,Color("fff9e5"),true)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var close=host.button(header,"X",Vector2(width-44,1),Vector2(42,42),Color("df4936"),Color.WHITE,27)
 close.name="CloseSeedPicker";close.pressed.connect(func(): ui.menu.hide())
 var hint="Gandum gratis siap. Tekan Tanam untuk mulai." if first else "Pilih bibit dan jumlah petak yang ingin ditanam."
 host.label(header,hint,Vector2(0,55),Vector2(width,28),17,host.INK).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var scroll=ScrollContainer.new();scroll.name="SeedGridScroll";scroll.custom_minimum_size=Vector2(width,150 if first else 290)
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;ui.content.add_child(scroll)
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
 for id in game.CROP_ORDER:
  if first and id!="gandum": continue
  var info=game.CROPS[id];var unlocked=game.level>=game.crop_level(id)
  var selected=game.selected_crop==id and (not first or ui.first_seed_selected)
  var tile=Panel.new();tile.custom_minimum_size=Vector2((width-34)/3,150);grid.add_child(tile)
  tile.set_meta("colorful_applied",true)
  tile.add_theme_stylebox_override("panel",STYLE.style(Color("edf8c9") if selected else Color("fff8e4"),Color("49a02c") if selected else Color("ebd5ab"),18))
  var w=tile.custom_minimum_size.x
  var icon=TextureRect.new();icon.texture=host.seed_icon_texture(id);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.position=Vector2((w-59)/2,6);icon.size=Vector2(59,59);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.add_child(icon)
  var name=host.label(tile,str(info.name),Vector2(5,66),Vector2(w-10,27),20,host.INK,true);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  host.label(tile,"Stok: %d"%int(game.seeds.get(id,0)),Vector2(10,96),Vector2(w-20,23),16,host.INK)
  host.label(tile,("8 dtk | Gratis" if first else "%d dtk"%int(info.grow)) if unlocked else "Level %d"%game.crop_level(id),Vector2(10,120),Vector2(w-20,25),16,host.GREEN if unlocked else host.SOFT_INK)
  if selected: host.label(tile,"OK",Vector2(w-30,0),Vector2(28,28),23,host.GREEN,true)
  var choose=Button.new();choose.name="SeedChoice_"+str(id);choose.flat=true;choose.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);choose.disabled=not unlocked
  choose.tooltip_text=str(info.name)+(" | Stok habis" if int(game.seeds.get(id,0))==0 else "");tile.add_child(choose);choose.pressed.connect(ui.select_seed.bind(str(id)))
 var candidates=targets(ui);ui.seed_quantity=clampi(ui.seed_quantity,1,maxi(1,candidates.size()))
 var footer=host.row_card(ui.content,132,Color("fff2ce"));footer.custom_minimum_size.x=width
 var selected=str(game.selected_crop)
 host.label(footer,str(game.CROPS[selected].name),Vector2(10,6),Vector2(width-20,29),22,host.INK,true)
 host.label(footer,"Stok %d | %d petak tersedia"%[int(game.seeds.get(selected,0)),candidates.size()],Vector2(10,37),Vector2(width-20,23),17,host.SOFT_INK)
 for i in 2:
  var b=host.button(footer,"-" if i==0 else "+",Vector2(10+i*108,75),Vector2(42,42),Color("f4dfa9"),host.INK,24)
  b.name="SeedQuantityMinus" if i==0 else "SeedQuantityPlus"
  b.disabled=ui.seed_quantity<=1 if i==0 else ui.seed_quantity>=candidates.size()
  b.pressed.connect(func(): ui.seed_quantity+=-1 if i==0 else 1;ui.rebuild())
 host.label(footer,str(ui.seed_quantity),Vector2(57,77),Vector2(55,39),26,host.GREEN,true).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var plant=host.button(footer,"TANAM",Vector2(width-162,72),Vector2(150,47),host.GREEN,Color.WHITE,23)
 plant.name="ConfirmSeedPlant";plant.disabled=candidates.is_empty() or (first and not ui.first_seed_selected)
 plant.pressed.connect(ui.confirm_seed_plant)
 if not first:
  var buy=ui.button("BELI 1 BIBIT | %d KOIN"%int(game.CROPS[selected].seed_cost),ui.buy_seed.bind(selected))
  buy.name="BuySeed_"+selected;buy.disabled=game.coins<int(game.CROPS[selected].seed_cost) or game.level<game.crop_level(selected)
static func confirm(ui):
 var available=targets(ui)
 if available.is_empty(): ui.system.host.show_toast("Petak terisi, bibit habis, atau belum terbuka.");ui.rebuild();return
 if FLOW.active(ui.system.host.game) and not ui.first_seed_selected: return
 var jobs=[]
 for index in available.slice(0,ui.seed_quantity): jobs.append(ui.system.actions.plot_job("plant",index))
 var count=0
 for job in jobs:
  if ui.system.enqueue(job,count==0 and not ui.system.append_jobs): count+=1
 if count>0:
  ui.seed_plot=-1;ui.menu.hide()
 else: ui.system.host.show_toast("Perintah tanam belum dapat dibuat.")
