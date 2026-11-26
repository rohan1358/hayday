extends Control
const STATE=preload("res://scripts/hybrid/hybrid_state.gd")
var system
var joystick
var menu: PanelContainer
var content: VBoxContainer
var status: Label
var controls_button: Button
var seed_button: Button
var seed_plot: int=-1
var seed_quantity: int=1
var first_seed_selected=false
var seed_scroll: ScrollContainer
var character_button: Button
var stop_button: Button
var queue_summary: Label
var timer=0.0
var section="jobs"
var target_zone=0
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 z_index=40
 joystick=preload("res://scripts/hybrid/joystick.gd").new()
 joystick.size=Vector2(144,144)
 add_child(joystick)
 controls_button=Button.new()
 controls_button.text="KONTROL & TUGAS"
 controls_button.custom_minimum_size=Vector2(182,46)
 controls_button.pressed.connect(open_menu)
 add_child(controls_button)
 character_button=Button.new()
 character_button.text="EDIT KARAKTER"
 character_button.custom_minimum_size=Vector2(174,46)
 character_button.pressed.connect(open_character)
 add_child(character_button)
 seed_button=Button.new()
 seed_button.name="SeedPickerShortcut"
 seed_button.custom_minimum_size=Vector2(182,48)
 seed_button.add_theme_font_size_override("font_size",14)
 seed_button.pressed.connect(primary_farm_action)
 add_child(seed_button)
 stop_button=Button.new()
 stop_button.text="BATALKAN TUGAS"
 stop_button.custom_minimum_size=Vector2(182,44)
 stop_button.pressed.connect(func(): system.cancel_all())
 add_child(stop_button)
 for root_button in [controls_button,character_button,seed_button]:
  var style=StyleBoxFlat.new()
  style.bg_color=Color("efe2ffee") if root_button==character_button else (Color("fff0bdee") if root_button==seed_button else Color("d5f3edee"))
  style.set_corner_radius_all(12)
  root_button.add_theme_stylebox_override("normal",style)
  root_button.add_theme_color_override("font_color",Color("355b48"))
 status=Label.new()
 var status_style=StyleBoxFlat.new()
 status_style.bg_color=Color("fff4d9ee")
 status_style.set_corner_radius_all(6)
 status.add_theme_stylebox_override("normal",status_style)
 status.add_theme_font_size_override("font_size",16)
 status.add_theme_color_override("font_color",Color("355b48"))
 add_child(status)
 menu=PanelContainer.new()
 menu.z_index=40
 menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.offset_left=16
 menu.offset_right=-16
 menu.offset_top=148
 menu.offset_bottom=-132
 var paper=StyleBoxFlat.new()
 paper.bg_color=Color("fff9ed")
 paper.set_corner_radius_all(18)
 paper.content_margin_left=18
 paper.content_margin_right=18
 paper.content_margin_top=16
 paper.content_margin_bottom=16
 menu.add_theme_stylebox_override("panel",paper)
 add_child(menu)
 var scroll=ScrollContainer.new()
 seed_scroll=scroll
 menu.add_child(scroll)
 content=VBoxContainer.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",12)
 scroll.add_child(content)
 menu.hide()
func _process(delta: float) -> void:
 if not menu.visible: z_index=40
 joystick.position=Vector2(20,size.y-335-system.host.ad_footer_reserved)
 controls_button.position=Vector2(size.x-202,size.y-202-system.host.ad_footer_reserved)
 status.position=Vector2(20,size.y-154-system.host.ad_footer_reserved)
 status.size.x=size.x-40
 controls_button.visible=system.host.active_tab=="kebun" and not system.farm.edit_mode and not system.host.action_panel.visible
 joystick.visible=controls_button.visible and not system.controls_blocked() and not system.host.action_panel.visible
 status.visible=controls_button.visible
 character_button.position=Vector2(20,size.y-389-system.host.ad_footer_reserved)
 character_button.visible=controls_button.visible
 seed_button.position=Vector2(size.x-178,size.y-116-system.host.ad_footer_reserved)
 seed_button.size=Vector2(164,104)
 seed_button.custom_minimum_size=Vector2(164,104)
 seed_button.add_theme_font_size_override("font_size",18)
 seed_button.icon=preload("res://scripts/colorful_icons.gd").texture("bibit")
 seed_button.expand_icon=true
 seed_button.add_theme_constant_override("icon_max_width",46)
 preload("res://scripts/cheerful_hud.gd").skin(seed_button,true)
 seed_button.visible=controls_button.visible and not system.host.action_panel.visible
 if not system.host.game.ftue.is_empty() and not bool(system.host.game.ftue.get("started",true)): seed_button.hide()
 stop_button.position=Vector2(size.x-202,size.y-254-system.host.ad_footer_reserved)
 stop_button.visible=controls_button.visible and (not system.active.is_empty() or not system.data.jobs.is_empty() or system.data.auto_work)
 if preload("res://scripts/first_farm.gd").active(system.host.game):
  character_button.hide()
  status.hide()
  controls_button.hide()
 if not system.host.game.ftue.is_empty() and system.host.game.level<3:
  controls_button.hide();character_button.hide();status.hide()
 controls_button.hide();character_button.hide();status.hide()
 if is_instance_valid(queue_summary) and menu.visible: queue_summary.text="Menunggu: %d â€¢ Sedang: %s"%[system.data.jobs.size(),system.actions.TITLES.get(system.activity,"Istirahat")]
 timer+=delta
 if timer<0.3: return
 timer=0
 var selected: String=system.host.game.selected_crop
 seed_button.text="Pilih Bibit\n%s"%system.host.game.CROPS[selected].name
 if preload("res://scripts/first_farm.gd").active(system.host.game):
  var step=str(system.host.game.ftue.step)
  if step=="harvest": seed_button.text="Panen\nGandum"
  elif step=="sale": seed_button.text="Jual\nGandum"
  elif step=="reward": seed_button.text="Ambil\nHadiah"
 preload("res://scripts/colorful_icons.gd").decorate(seed_button)
 var title: String=system.actions.TITLES.get(system.activity,system.activity)
 status.text=("KELOLA" if system.manager_mode() else "KARAKTER")+" â€¢ "+title+" â€¢ antrean %d â€¢ air %d â€¢ pupuk %d"%[system.data.jobs.size(),int(system.data.water),int(system.data.fertilizer)]
func raise_menu() -> void:
 z_index=90
 if get_parent()!=null: get_parent().move_child(self,get_parent().get_child_count()-1)
func label_line(value: String,font_size=20) -> Label:
 var label=Label.new()
 label.text=value
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("355b48"))
 content.add_child(label)
 return label
func button(value: String,action: Callable) -> Button:
 var b=Button.new()
 b.text=value
 b.custom_minimum_size.y=46
 var style=StyleBoxFlat.new()
 style.bg_color=Color("dfead5")
 style.set_corner_radius_all(10)
 b.add_theme_stylebox_override("normal",style)
 b.add_theme_color_override("font_color",Color("355b48"))
 b.pressed.connect(action)
 content.add_child(b)
 return b
func open_menu() -> void:
 menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.offset_left=16;menu.offset_right=-16;menu.offset_top=148;menu.offset_bottom=-132
 raise_menu()
 if preload("res://scripts/first_farm.gd").active(system.host.game):
  open_seed_picker(-1)
  return
 seed_plot=-1
 section="jobs"
 joystick.release()
 menu.show()
 rebuild()
func rebuild() -> void:
 for node in content.get_children():
  content.remove_child(node)
  node.queue_free()
 if section=="seeds":
  preload("res://scripts/hybrid/seed_picker.gd").populate(self)
  return
 if preload("res://scripts/first_farm.gd").active(system.host.game):
  label_line("PILIH BIBIT",26)
  button("KEMBALI KE KEBUN",func(): menu.hide())
  seed_menu()
  return
 label_line("KONTROL PERKEBUNAN",26)
 button("KEMBALI KE KEBUN",func(): menu.hide())
 var tabs=HBoxContainer.new()
 content.add_child(tabs)
 for entry in [["jobs","TUGAS"],["seeds","BIBIT"],["animals","TERNAK"],["zones","ZONA"]]:
  var b=Button.new()
  b.text=entry[1]
  b.custom_minimum_size.y=46
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  b.pressed.connect(change_section.bind(entry[0]))
  tabs.add_child(b)
 if section=="seeds": seed_menu()
 elif section=="animals": animal_menu()
 elif section=="zones": zone_menu()
 else: job_menu()
func change_section(value: String) -> void:
 if value in ["animals","zones"] and not system.host.game.feature_unlocked("ranch"): return
 if value!="seeds": seed_plot=-1
 section=value
 rebuild()
func job_menu() -> void:
 label_line("WASD / joystick: berjalan. Shift / joystick penuh: berlari. Ketuk tanah: berjalan. Ketuk objek: mendekati lalu beraksi. Geser peta: kamera bebas; cubit atau roda mouse: zoom.",17)
 button("MODE: "+("KELOLA LANGSUNG" if system.manager_mode() else "KARAKTER"),toggle_manager)
 button("KAMERA: "+("IKUTI KARAKTER" if system.data.follow else "EKSPLORASI BEBAS"),toggle_camera)
 var picker=OptionButton.new()
 picker.custom_minimum_size.y=48
 var tools: Array=["auto","plant","water","fertilize","harvest","feed","drink","collect","clean","pet"]
 for action in tools: picker.add_item("Alat: "+str(system.actions.TITLES.get(action,"Otomatis")))
 picker.selected=maxi(0,tools.find(system.selected_tool))
 picker.item_selected.connect(func(i): system.selected_tool=tools[i])
 content.add_child(picker)
 button("ANTREKAN KETUKAN: "+("YA" if system.append_jobs else "GANTI PERINTAH"),func(): system.append_jobs=not system.append_jobs; rebuild())
 button("PILIH BIBIT UNTUK MENANAM",open_seed_picker.bind(-1))
 label_line("KELOLA BANYAK PETAK",22)
 for action in ["harvest","plant","water","fertilize"]:
  button(str(system.actions.TITLES[action])+" semua petak yang sesuai",batch_plots.bind(action))
 button("KERJA BERULANG: "+("AKTIF" if system.data.auto_work else "MATI"),func(): system.data.auto_work=not system.data.auto_work; system.save_state(); rebuild())
 label_line("Kerja berulang mengecek panen, tanam, pakan dan hasil setiap 5 detik. WASD/joystick membatalkan otomatis beserta antreannya.",16)
 button("ISI AIR DI SUMUR",func(): system.enqueue({"action":"refill","target":"position","position":[330,580]}); menu.hide())
 button("BELI 5 PUPUK â€¢ 10 KOIN",buy_fertilizer)
 button("BATALKAN SEMUA PERINTAH",func(): system.cancel_all(); rebuild())
 label_line("ANTREAN PEKERJAAN",22)
 queue_summary=label_line("Menunggu: "+str(system.data.jobs.size()),18)
 button("PERBARUI DAFTAR TUGAS",rebuild)
 if not system.active.is_empty(): label_line("Sedang: "+str(system.actions.TITLES.get(system.active.action,"Tugas")),17)
 if system.data.jobs.is_empty(): label_line("Belum ada tugas menunggu.",17)
 for i in system.data.jobs.size():
  var job: Dictionary=system.data.jobs[i]
  var target=str(job.get("animal",job.get("index",job.get("key","lokasi"))))
  label_line("%d. %s â€¢ %s"%[i+1,system.actions.TITLES.get(job.action,job.action),target],17)
  button("HAPUS TUGAS "+str(i+1),remove_job.bind(int(job.id)))
 if not system.data.history.is_empty():
  label_line("HASIL TUGAS TERAKHIR",20)
  for entry in system.data.history.slice(maxi(0,system.data.history.size()-5)):
   label_line(("âœ“ " if entry.ok else "! ")+str(entry.message),16)
func toggle_manager() -> void:
 system.cancel_all("")
 system.data.manager=not bool(system.data.manager)
 system.save_state()
 rebuild()
func toggle_camera() -> void:
 system.data.follow=not bool(system.data.follow)
 system.save_state()
 rebuild()
func batch_plots(action: String) -> void:
 system.batch_plots(action)
 rebuild()
func remove_job(id: int) -> void:
 for i in range(system.data.jobs.size()-1,-1,-1):
  if int(system.data.jobs[i].id)==id: system.data.jobs.remove_at(i)
 system.save_state()
 rebuild()
func buy_fertilizer() -> void:
 if system.host.game.coins<10:
  system.host.show_toast("Koin belum cukup.")
  return
 system.host.game.coins-=10
 system.data.fertilizer=int(system.data.fertilizer)+5
 system.save_state()
 system.host.refresh_all()
 rebuild()
func animal_menu() -> void:
 button("BELI HEWAN & PERLUAS KANDANG",func(): menu.hide(); system.host.switch_tab("ternak"))
 label_line("Hewan berkeliaran dalam zona berpagar. Sediakan pakan/minum di palung agar mereka makan dan minum sendiri. Buka gerbang asal dan tujuan sebelum menggiring.",17)
 for action in ["feed","drink","collect","clean","pet"]:
  button(str(system.actions.TITLES[action])+" semua hewan",func(): system.batch_animals(action); rebuild())
 button("BELI DOMBA â€¢ 180 KOIN â€¢ LEVEL 3",buy_sheep)
 for animal in system.data.animals:
  label_line(str(animal.id).replace("_"," ").to_upper(),22)
  label_line("Kenyang %d | Air %d | Energi %d | Bersih %d\nAktivitas: %s"%[animal.hunger,animal.thirst,animal.energy,animal.cleanliness,str(animal.state)],17)
  button("LIHAT HEWAN",focus_animal.bind(str(animal.id)))
  for action in ["feed","drink","collect","clean","pet"]: button(str(system.actions.TITLES[action]),animal_job.bind(action,str(animal.id)))
  if animal.get("legacy_pen",false): continue
  var zones=OptionButton.new()
  zones.custom_minimum_size.y=46
  for zone in system.data.zones: zones.add_item(str(zone.name),int(zone.id))
  content.add_child(zones)
  button("GIRING KE ZONA YANG DIPILIH",herd_selected.bind(str(animal.id),zones))
func animal_job(action: String,id: String) -> void:
 system.enqueue({"action":action,"target":"animal","animal":id})
 menu.hide()
func focus_animal(id: String) -> void:
 var value: Dictionary=system.animals.animal(id)
 if value.is_empty(): return
 system.selected_animal=id
 system.data.follow=false
 system.farm.camera_target=system.animals.position(value)
 system.farm.clamp_camera_target()
 menu.hide()
func herd_selected(id: String,picker: OptionButton) -> void:
 if picker.item_count==0: return
 system.enqueue({"action":"herd","target":"animal","animal":id,"zone":picker.get_selected_id()})
 menu.hide()
func buy_sheep() -> void:
 if system.data.sheep_owned:
  system.host.show_toast("Domba sudah dimiliki.")
  return
 if system.host.game.level<3 or system.host.game.coins<180:
  system.host.show_toast("Domba memerlukan level 3 dan 180 koin.")
  return
 system.host.game.coins-=180
 system.data.sheep_owned=true
 system.animals.ensure_animals()
 system.save_state()
 system.host.refresh_all()
 rebuild()
func zone_menu() -> void:
 button("BUAT ZONA BERPAGAR â€¢ PILIH DUA SUDUT",func():
  system.zone_tool="create"
  system.zone_first=Vector2.INF
  system.data.follow=false
  menu.hide()
  system.host.show_toast("Ketuk sudut pertama zona, lalu sudut berlawanan."))
 button("BATALKAN PEMBUATAN ZONA",func(): system.zone_tool=""; system.zone_first=Vector2.INF; rebuild())
 for zone in system.data.zones:
  label_line(str(zone.name),22)
  label_line("Palung pakan %d â€¢ palung air %d"%[int(zone.feed),int(zone.water)],17)
  button("GERBANG: "+("BUKA" if zone.gate_open else "TUTUP"),toggle_gate.bind(int(zone.id)))
  button("PINDAHKAN GERBANG KE SISI BERIKUTNYA",rotate_gate.bind(int(zone.id)))
  button("STOK PAKAN PALUNG â€¢ 3 GANDUM",stock_zone.bind(int(zone.id),"feed"))
  button("STOK AIR PALUNG â€¢ 5 AIR",stock_zone.bind(int(zone.id),"water"))
  button("LIHAT ZONA",focus_zone.bind(int(zone.id)))
  button("HAPUS ZONA KOSONG",delete_zone.bind(int(zone.id)))
func toggle_gate(id: int) -> void:
 var zone: Dictionary=system.animals.zone(id)
 if zone.is_empty(): return
 zone.gate_open=not bool(zone.gate_open)
 system.navigation.ensure()
 system.save_state()
 rebuild()
func stock_zone(id: int,kind: String) -> void:
 var zone: Dictionary=system.animals.zone(id)
 if zone.is_empty(): return
 if kind=="feed":
  if int(system.host.game.inventory.get("gandum",0))<3:
   system.host.show_toast("Perlu 3 gandum.")
   return
  system.host.game.inventory.gandum=int(system.host.game.inventory.gandum)-3
  zone.feed=int(zone.feed)+3
 else:
  if int(system.data.water)<5:
   system.host.show_toast("Perlu 5 air; isi air di sumur.")
   return
  system.data.water=int(system.data.water)-5
  zone.water=int(zone.water)+5
 system.save_state()
 system.host.refresh_all()
 rebuild()
func focus_zone(id: int) -> void:
 var zone: Dictionary=system.animals.zone(id)
 if zone.is_empty(): return
 system.data.follow=false
 system.farm.camera_target=STATE.zone_rect(zone).get_center()
 system.farm.clamp_camera_target()
 menu.hide()
func delete_zone(id: int) -> void:
 for animal in system.data.animals:
  if int(animal.zone)==id or system.animals.agents.get(str(animal.id),{}).get("target_zone",-1)==id:
   system.host.show_toast("Pindahkan hewan dari zona ini dahulu.")
   return
 for i in range(system.data.zones.size()-1,-1,-1):
  if int(system.data.zones[i].id)==id: system.data.zones.remove_at(i)
 system.navigation.ensure()
 system.save_state()
 rebuild()

func open_character() -> void:
 joystick.release()
 for node in system.host.get_children():
  if node.get_script()==load("res://scripts/seasonal_ui.gd"):
   node.wardrobe_editor.open()
   return
func rotate_gate(id: int) -> void:
 var zone: Dictionary=system.animals.zone(id)
 if zone.is_empty(): return
 zone.gate_edge=(int(zone.get("gate_edge",1))+1)%4
 system.navigation.ensure()
 system.save_state()
 rebuild()
func open_seed_picker(plot_index: int=-1) -> void:
 raise_menu()
 preload("res://scripts/first_farm.gd").selected(system.host.game,plot_index)
 first_seed_selected=preload("res://scripts/first_farm.gd").active(system.host.game)
 if first_seed_selected: system.host.game.selected_crop="gandum"
 seed_quantity=1
 seed_plot=plot_index
 section="seeds"
 joystick.release()
 menu.show()
 rebuild()
func seed_menu() -> void:
 preload("res://scripts/hybrid/seed_picker.gd").populate(self)

func select_seed(id: String) -> void:
 var game=system.host.game
 if not game.CROPS.has(id) or game.level<game.crop_level(id): return
 game.selected_crop=id
 first_seed_selected=true
 game.save_game()
 system.host.refresh_all()
 rebuild()
 seed_scroll.set_deferred("scroll_vertical",0)
func buy_seed(id: String) -> void:
 var game=system.host.game
 if game.buy_seeds(id,1):
  game.selected_crop=id
  game.save_game()
 else: system.host.show_toast("Koin belum cukup atau bibit masih terkunci.")
 system.host.refresh_all()
 rebuild()
func style_seed_button(b: Button,selected: bool,purchase: bool) -> void:
 var base:=StyleBoxFlat.new()
 base.bg_color=Color("387956") if selected else (Color("f6dda2") if purchase else Color("e4ecd9"))
 base.set_corner_radius_all(9)
 b.add_theme_stylebox_override("normal",base)
 var disabled:=base.duplicate() as StyleBoxFlat
 disabled.bg_color=Color("e3e5dc")
 b.add_theme_stylebox_override("disabled",disabled)
 b.add_theme_color_override("font_color",Color.WHITE if selected else Color("355b48"))
 b.add_theme_color_override("font_disabled_color",Color("878e80"))
 b.add_theme_font_size_override("font_size",16)
func confirm_seed_plant() -> void:
 preload("res://scripts/hybrid/seed_picker.gd").confirm(self)

func primary_farm_action() -> void:
 var game=system.host.game
 var flow=preload("res://scripts/first_farm.gd")
 if flow.active(game):
  if game.ftue.step in ["welcome","plant"]:
   open_seed_picker(flow.target(game))
  elif game.ftue.step in ["grow","harvest"]:
   var target=flow.target(game)
   if target>=0: system.tap_world(system.farm.plot_center(target))
  elif game.ftue.step=="sale": system.host.switch_tab("pengunjung")
  elif game.ftue.step=="reward":
   var ui=preload("res://scripts/cheerful_menus.gd").guide(system.host)
   if ui!=null: ui.claim_reward()
 else: open_seed_picker(-1)
