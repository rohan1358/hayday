extends RefCounted
const UI=preload("res://scripts/ranch_presentation.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
static func populate(host,list):
 var activities=host.game.ready_activities();host.activity_signature=JSON.stringify(activities)
 if host.game.storage_used()>=host.game.storage_capacity:
  host.callout(list,"GUDANG PENUH","Jual sebagian stok agar hasil baru dapat disimpan.",Color("fff0d0"))
  var storage=host.button(list,"BUKA GUDANG",Vector2.ZERO,Vector2(601,51),host.GREEN,Color.WHITE,20);storage.pressed.connect(func(): host.switch_tab("gudang"))
 if activities.is_empty(): host.callout(list,"SEMUA PEKERJAAN SELESAI!","Belum ada pekerjaan siap. Tanaman dan produksi masih berjalan.",Color("edf4d7"));return
 for activity in activities:
  var row=host.row_card(list,110,Color("fff6df"));row.add_theme_stylebox_override("panel",UI.style(Color("fff7df"),Color("e3cb9d"),23))
  var art={"panen":"wheat_plot_ready","buah":"apple_tree","produksi":"kitchen_cottage","pakan":"feed_mill_building"}.get(str(activity.id),"")
  if not str(art).is_empty(): UI.art(host,row,art,Vector2(9,12),Vector2(77,82))
  else: ICON.add(row,"susu" if activity.id=="sapi" else ("hadiah" if activity.id=="misi" else ("app_icon" if activity.id=="tamu" else "pesanan")),Vector2(13,19),Vector2(68,68))
  host.label(row,str(activity.title).capitalize(),Vector2(94,14),Vector2(315,33),25,host.INK,true)
  host.label(row,str(activity.detail),Vector2(94,53),Vector2(315,46),18,host.INK).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  host.label(row,"×%d"%int(activity.count),Vector2(414,39),Vector2(47,34),23,host.INK,true)
  var b=host.button(row,"Lihat ›",Vector2(471,34),Vector2(113,47),host.GREEN,Color.WHITE,22)
  b.name="ActivityRow_"+str(activity.id);b.pressed.connect(host.open_activity.bind(activity))
