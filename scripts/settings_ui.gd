extends RefCounted
const UI=preload("res://scripts/ranch_presentation.gd")
const CATEGORIES=["Audio","Kamera","Kontrol","Tata Letak","Kelola Aset","Pulihkan","Bahasa","Tentang"]
static func card(host,parent,title: String,description: String="",height: int=105):
 var box=host.panel(parent,Vector2.ZERO,Vector2(439,height),Color("fff5db"),23,3)
 box.add_theme_stylebox_override("panel",UI.style(Color("fff5db"),Color("e4c893"),23))
 host.label(box,title,Vector2(14,9),Vector2(410,34),25,host.INK,true)
 if not description.is_empty(): host.label(box,description,Vector2(14,50),Vector2(410,height-56),18,host.SOFT_INK).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 return box
static func action(host,parent,text: String,callback: Callable,enabled=true):
 var button=host.button(parent,text,Vector2.ZERO,Vector2(439,57),host.GREEN,Color.WHITE,20)
 button.disabled=not enabled;button.pressed.connect(callback);return button
static func populate(host,list):
 var current=clampi(int(host.get_meta("settings_category",0)),0,7)
 var layout=HBoxContainer.new();layout.add_theme_constant_override("separation",12);list.add_child(layout)
 var navigation=VBoxContainer.new();navigation.custom_minimum_size.x=146;navigation.add_theme_constant_override("separation",12);layout.add_child(navigation)
 var body=VBoxContainer.new();body.custom_minimum_size.x=439;body.add_theme_constant_override("separation",14);layout.add_child(body)
 for i in CATEGORIES.size():
  var tab=host.button(navigation,CATEGORIES[i],Vector2.ZERO,Vector2(146,57),host.GREEN if i==current else Color("f7e3b9"),Color.WHITE if i==current else host.INK,19)
  tab.name="SettingsTab_"+str(i);tab.set_meta("typography_role","tab")
  tab.pressed.connect(func(): host.set_meta("settings_category",i);host.show_sheet())
 var system=host.farm.hybrid_controller
 match current:
  0:
   card(host,body,"Musik & Suara","Atur musik, efek suara, dan suasana alam.")
   var audio=host.get_node_or_null("GardenAudio")
   if audio==null: return
   for pair in [["music","Musik"],["sfx","Efek Suara"],["ambience","Suasana Alam"]]:
    var row=host.panel(body,Vector2.ZERO,Vector2(439,93),Color("fff8e5"),18)
    var label=host.label(row,pair[1]+" Â· %d%%"%int(audio.volumes[pair[0]]*100),Vector2(14,5),Vector2(410,30),21,host.INK,true)
    var slider=HSlider.new();slider.name="Audio_"+pair[0];slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=audio.volumes[pair[0]]*100
    slider.position=Vector2(14,43);slider.size=Vector2(410,36);row.add_child(slider)
    slider.value_changed.connect(func(value): audio.set_volume(pair[0],value/100);label.text=pair[1]+" Â· %d%%"%int(value))
   var mute=host.button(body,"Matikan Semua Suara",Vector2.ZERO,Vector2(439,54),host.GREEN,Color.WHITE,20);mute.name="SettingsMute";mute.toggle_mode=true;mute.button_pressed=audio.muted
   mute.toggled.connect(func(value): audio.muted=value;audio.apply_volumes();audio.save_settings())
  1:
   card(host,body,"Kamera","Pilih kamera bebas atau mengikuti karakter.")
   for mode in [false,true]:
    var b=action(host,body,("âœ“ " if bool(system.data.follow)==mode else "")+("Ikuti Karakter" if mode else "Eksplorasi Bebas"),func(): system.data.follow=mode;system.save_state();host.show_sheet())
    b.name="CameraFollow" if mode else "CameraFree"
   action(host,body,"Kembalikan Kamera",func(): host.farm.reset_camera())
  2:
   card(host,body,"Kontrol & Antrean Tugas","WASD atau joystick untuk berjalan. Ketuk objek untuk berinteraksi.",135)
   action(host,body,"Kontrol & Antrean Tugas",func(): host.switch_tab("kebun");system.ui.open_menu())
   if preload("res://scripts/first_farm.gd").active(host.game): action(host,body,"Lewati Panduan",func(): host.game.skip_onboarding();host.refresh_all())
  3:
   card(host,body,"Tata Letak Kebun","Atur bangunan, dekorasi, jalan, dan lahan.")
   action(host,body,"Pindah Aset",func(): host.switch_tab("kebun");host.toggle_arrange_mode(),host.game.feature_unlocked("decorations"))
   action(host,body,"Tata Seperti Contoh",func(): preload("res://scripts/cheerful_layout.gd").apply(host.game);preload("res://scripts/cheerful_menus.gd").reload_layout(host),not host.game.ftue.is_empty())
  4:
   card(host,body,"Kelola Aset","Lihat dekorasi tersimpan dan benda yang telah dipasang.")
   action(host,body,"Buka Aset Milikmu",func(): host.switch_tab("aset"))
   action(host,body,"Buka Koleksi",func(): host.switch_tab("koleksi"))
  5:
   card(host,body,"Pulihkan Data","Pulihkan posisi kebun dari cadangan tata letak.")
   action(host,body,"Pulihkan Posisi Sebelumnya",func():
    if preload("res://scripts/cheerful_layout.gd").restore(host.game): preload("res://scripts/cheerful_menus.gd").reload_layout(host),host.game.ftue.has("layout_backup"))
   action(host,body,"Mulai Permainan Baru",host.confirm_new_game)
  6:
   card(host,body,"Bahasa","Pilih bahasa permainan. Pilihan tersimpan secara otomatis.",130)
   var picker=OptionButton.new();picker.name="SettingsLanguage";picker.custom_minimum_size=Vector2(439,54)
   picker.add_item("Indonesia",0);picker.add_item("English",1)
   var language=host.get_node("/root/GardenLanguage")
   picker.select(0 if language.locale=="id" else 1);body.add_child(picker)
   picker.item_selected.connect(func(index): language.set_language("id" if index==0 else "en"))
  7:
   card(host,body,"Cheerful Garden","Berkebun, beternak, dan membangun kebun yang hidup.",140)
   card(host,body,"Informasi Game","Progres disimpan secara lokal di perangkat ini.",120)
   if host.ads!=null and host.ads.has_enabled_ads(): action(host,body,"Privasi Iklan",host.ads.show_privacy_options)
