extends RefCounted
const CATEGORIES=[["jalan","JALAN"],["rumput","RUMPUT"],["bunga","BUNGA"],["pohon","POHON"],["gedung","GEDUNG & TOKO"],["dekorasi","SEMUA DEKORASI"]]
static func matches(kind: String,category: String) -> bool:
 if category=="gedung": return kind=="garden_stall" or kind in ["ref_pengolah_gula","ref_silo","ref_sortir_buah","ref_bengkel_tambang","ref_penggergajian","ref_sekolah","ref_rumah_kaca_besar","ref_kios_bunga"]
 if category=="rumput": return kind=="grass_patch"
 if category=="pohon": return kind in ["garden_tree","lg_blossom_tree","lg_lantern_tree"]
 if category=="bunga": return kind in ["flower_patch","flowering_bushes","flower_garden","flowering_hedge","wildflower_crescent","lg_butterfly_garden","ref_air_mancur"]
 return true
static func links(host,list) -> void:
 host.callout(list,"TOKO ASET KEBUN","Pilih kategori, beli dengan koin, lalu pasang di kebun.",Color("e0f0df"))
 for row in 3:
  var card=host.row_card(list,70,Color("fff4df"))
  for column in 2:
   var entry=CATEGORIES[row*2+column]
   var b=host.button(card,entry[1],Vector2(12+column*294,8),Vector2(280,54),host.GREEN,Color.WHITE,18)
   b.name="GardenCategory_"+entry[0]
   b.pressed.connect(host.switch_tab.bind(entry[0]))
