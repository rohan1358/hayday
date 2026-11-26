extends RefCounted
const UI=preload("res://scripts/ranch_presentation.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
static func populate(host,list):
 list.add_theme_constant_override("separation",25)
 var actions=[Callable(host.farm.hybrid_controller.ui,"open_character"),func(): host.switch_tab("aset"),func(): host.switch_tab("prestasi"),func(): host.switch_tab("kawasan")]
 var titles=["Karakter & Kostum","Dekorasi Kebun","Prestasi","Kawasan Desa"]
 var descriptions=["Ubah tampilan karaktermu.","Kelola dekorasi dan benda yang kamu miliki.","Lihat pencapaian dan hadiah yang kamu raih.","Lihat area terbuka, bangunan, dan kegiatan desa."]
 for i in 4:
  var row=host.row_card(list,166,Color("fff8e5"));row.name="CollectionCard"+str(i)
  row.set_meta("colorful_applied",true)
  var box=UI.style(Color("fff8e5"),Color("fffdf2"),30)
  box.shadow_color=Color("ae8d4a44");box.shadow_size=4;box.shadow_offset=Vector2(0,4)
  row.add_theme_stylebox_override("panel",box)
  if i==0:
   var preview=preload("res://scripts/wardrobe_preview.gd").new();preview.data=host.game.seasonal.duplicate(true)
   preview.position=Vector2(44,2);preview.size=Vector2(125,158);row.add_child(preview)
   ICON.add(row,"pakaian",Vector2(8,52),Vector2(70,75))
  elif i==1:
   UI.art(host,row,"lg_blossom_tree",Vector2(10,5),Vector2(155,140))
   UI.art(host,row,"flower_patch",Vector2(70,92),Vector2(107,60))
  elif i==2: ICON.add(row,"trophy",Vector2(25,16),Vector2(135,131))
  else: UI.art(host,row,"village_waypost",Vector2(20,8),Vector2(145,140))
  var title=host.label(row,titles[i],Vector2(194,27),Vector2(353,42),27,Color("195235"),true)
  title.set_meta("typography_role","heading")
  var description=host.label(row,descriptions[i],Vector2(194,78),Vector2(350,64),20,Color("6d6751"))
  description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  host.label(row,"›",Vector2(553,52),Vector2(35,58),44,Color("9c632b"),true)
  var tap=Button.new();tap.name=["CollectionCharacter","CollectionDecorations","CollectionAchievements","CollectionRegions"][i]
  tap.flat=true;tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tap.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  tap.tooltip_text=titles[i];row.add_child(tap)
  if i==2: tap.disabled=preload("res://scripts/first_farm.gd").active(host.game)
  if i==0: tap.pressed.connect(func(): host.switch_tab("kebun");host.farm.hybrid_controller.ui.open_character())
  else: tap.pressed.connect(actions[i])
static func assets(host,list):
 host.label(list,"Dekorasi dan bangunan milikmu",Vector2.ZERO,Vector2(590,40),25,host.GREEN,true)
 preload("res://scripts/cheerful_menus.gd").owned_assets(host,list)
 if host.game.decorations.is_empty(): host.callout(list,"BELUM ADA DEKORASI","Dekorasi yang dibeli akan tampil di sini untuk dipasang atau dilihat di kebun.",Color("fff4da"))
 var b=host.button(list,"BUKA TOKO DEKORASI",Vector2.ZERO,Vector2(590,55),host.GREEN,Color.WHITE,20)
 b.disabled=not host.game.feature_unlocked("decorations")
 b.pressed.connect(func(): host.set_meta("shop_category",5);host.switch_tab("toko"))
