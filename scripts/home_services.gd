extends RefCounted
# Starter workshops are a grant, never a repeat purchase or a save reset.
static func prepare(game) -> void:
 for id in ["toko_roti","pabrik_susu"]:
  if not game.has_construction(id): game.constructions[id]=1
static func populate(host,list) -> void:
 host.callout(list,"RUMAH PETANI","Rumah adalah pusat karakter dan dapur. Gudang menyimpan hasil panen serta bahan makanan. Upgrade Rumah menambah bonus penjualan tamu; upgrade Gudang menambah kapasitas.",Color("e5f2d8"))
 for item in [["DAPUR RUMAH","produksi"],["UPGRADE RUMAH / BANGUNAN","upgrade"],["LIHAT ISI GUDANG","gudang"]]:
  var row=host.row_card(list,86,Color("fff1d3"))
  var b=host.button(row,item[0]+"  ›",Vector2(18,12),Vector2(570,60),Color("19a363"),Color.WHITE,20)
  var target=str(item[1])
  b.pressed.connect(func(): host.switch_tab(target))
 var row=host.row_card(list,86,Color("fff1d3"))
 var edit=host.button(row,"EDIT KARAKTER  ›",Vector2(18,12),Vector2(570,60),Color("19a363"),Color.WHITE,20)
 edit.pressed.connect(func():
  for node in host.get_children():
   if node.get_script()==load("res://scripts/seasonal_ui.gd"): node.wardrobe_editor.open();return)
