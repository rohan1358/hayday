extends RefCounted
const UI=preload("res://scripts/ranch_presentation.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
const ROADS=preload("res://scripts/road_catalog.gd")
const R=preload("res://scripts/ranch_state.gd")
const STORE=preload("res://scripts/animal_store.gd")
const CATEGORIES=["Rekomendasi","Benih","Ternak","Bangunan","Jalan","Dekorasi"]
const HINTS=["Pilihan untuk mempercantik dan mengembangkan kebunmu!","Tanam, panen, dan kembangkan kebunmu!","Pelihara hewan dan kumpulkan hasil peternakan!","Bangun fasilitas untuk mendukung kegiatan kebunmu!","Rapikan kebun dengan jalan yang saling menyambung!","Hiasi kebun agar semakin indah dan ceria!"]
static func item(kind: String,key: String,name: String,price: int,level: int,asset: String="") -> Dictionary:
 return {"kind":kind,"key":key,"name":name,"price":price,"level":level,"asset":asset}
static func catalog(host,category: int) -> Array:
 var g=host.game;var entries=[]
 if category==1:
  for key in g.CROP_ORDER:
   var c=g.CROPS[key];entries.append(item("seed",key,c.name,int(c.seed_cost),g.crop_level(key)))
  for key in g.FRUITS:
   var tree=g.FRUITS[key]
   entries.append(item("tree",key,"Pohon "+str(tree.name),int(tree.cost),int(tree.level),"fruit_tree_"+key+"_ripe"))
 elif category==2:
  for species in R.SPECIES:
   entries.append(item("pen",species,"Kandang "+str(R.INFO[species].name),80 if species=="ayam" else int(STORE.COST[species]),3,R.INFO[species].asset))
  for species in R.SPECIES:
   entries.append(item("animal",species,str(R.INFO[species].name),int(R.INFO[species].price),3))
 elif category==3:
  entries.append(item("upgrade","house","Rumah · Upgrade",0,2,"kitchen_cottage"))
  entries.append(item("upgrade","storage","Gudang · Upgrade",0,2,"village_barn"))
  for key in g.CONSTRUCTIONS:
   if key.begins_with("kandang_"): continue
   var c=g.CONSTRUCTIONS[key]
   var assets={"pabrik_pakan":"feed_mill_building","toko_roti":"bakery_building","pabrik_susu":"dairy_building","petak_bunga":"flower_garden","kincir_angin":"windmill","gazebo":"gazebo","kolam":"decorative_pond"}
   entries.append(item("building",key,c.name,int(c.cost),maxi(int(c.level),5) if not g.ftue.is_empty() else int(c.level),str(assets.get(key,"wooden_crates"))))
 elif category==4:
  for key in ROADS.ORDER: entries.append(item("road",key,ROADS.ITEMS[key].name,int(ROADS.ITEMS[key].price),2))
 elif category==5:
  for key in g.DECORATION_ORDER:
   var c=g.DECORATIONS[key];entries.append(item("decor",key,c.name,int(c.cost),maxi(2,int(c.get("level",1))),key))
 else:
  var seeds=catalog(host,1);var pens=catalog(host,2);var roads=catalog(host,4);var decor=catalog(host,5)
  for key in ["gandum","jagung"]:
   for entry in seeds:
    if entry.key==key: entries.append(entry)
  entries.insert(1,pens[0]);entries.insert(2,roads[0])
  for key in ["flower_patch","garden_tree","rustic_lamp","flowering_hedge"]:
   for entry in decor:
    if entry.key==key: entries.append(entry)
 return entries
static func owned(host,entry) -> bool:
 if entry.kind=="pen": return preload("res://scripts/first_coop.gd").built(host.game) if entry.key=="ayam" else STORE.owned(host.game,entry.key)
 if entry.kind=="building": return host.game.construction_count(entry.key)>=(3 if entry.key=="petak_bunga" else 1)
 return false
static func reason(host,entry,quantity: int=1) -> String:
 if host.game.level<int(entry.level): return "Terbuka Lv %d"%entry.level
 if owned(host,entry): return "Sudah dibangun"
 if entry.kind=="animal": return R.buy_reason(host.game,entry.key)
 if entry.kind=="road" and not host.game.feature_unlocked("roads"): return "Selesaikan misi awal"
 if entry.kind=="decor" and not host.game.feature_unlocked("decorations"): return "Selesaikan misi awal"
 if host.game.coins<int(entry.price)*quantity: return "Koin belum cukup"
 return ""
static func picture(host,parent,entry,at: Vector2,dimensions: Vector2):
 if not str(entry.asset).is_empty(): return UI.art(host,parent,entry.asset,at,dimensions)
 var icon=ICON.add(parent,"hewan",at,dimensions)
 if entry.kind=="seed": icon.texture=host.seed_icon_texture(entry.key)
 elif entry.kind=="road": icon.texture=preload("res://scripts/road_painter.gd").preview(entry.key)
 elif entry.kind=="animal" and host.farm.ranch_animator!=null: icon.texture=host.farm.ranch_animator.frames.get(entry.key+"0",icon.texture)
 return icon
static func select_category(host,index: int):
 host.set_meta("shop_category",index);host.set_meta("shop_quantity",1);host.set_meta("shop_selected",{})
 host.sheet_scroll_positions["toko"]=0;host.show_sheet()
static func populate(host,list):
 var category=clampi(int(host.get_meta("shop_category",0)),0,5)
 var tabs=host.row_card(list,92,Color("fff2cf"))
 for i in 6:
  var tab_x=2 if i==0 else 130+(i-1)*95
  var tab_width=124 if i==0 else 91
  var b=host.button(tabs,CATEGORIES[i],Vector2(tab_x,2),Vector2(tab_width,86),Color("2aa84e") if category==i else Color("fff1cf"),Color.WHITE if category==i else Color("47381d"),14 if i==0 else 15)
  b.clip_text=true
  b.name="ShopTab"+str(i)
  b.icon=ICON.texture(["hadiah","bibit","hewan","kebun","jalan","bunga"][i]);b.expand_icon=true
  b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
  b.add_theme_constant_override("icon_max_width",37)
  b.pressed.connect(select_category.bind(host,i))
 var banner=host.row_card(list,152,Color("c6edb3"));banner.clip_contents=true
 var landscape=TextureRect.new();landscape.texture=load("res://assets/cheerful/countryside.png");landscape.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 landscape.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;landscape.size=Vector2(601,152);landscape.mouse_filter=Control.MOUSE_FILTER_IGNORE;banner.add_child(landscape)
 ICON.add(banner,"app_icon",Vector2(4,10),Vector2(128,128))
 var bubble=Panel.new();bubble.position=Vector2(136,16);bubble.size=Vector2(305,121);bubble.clip_contents=true;bubble.add_theme_stylebox_override("panel",UI.style(Color("fff8db"),Color("fffdf0"),28));banner.add_child(bubble)
 host.label(bubble,CATEGORIES[category],Vector2(14,10),Vector2(275,31),23,Color("315827"),true)
 var hint=host.label(bubble,HINTS[category],Vector2(14,40),Vector2(275,68),17,Color("4e462b"));hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.set_deferred("size",Vector2(275,68))
 UI.art(host,banner,"kitchen_cottage" if category!=4 else "stone_path_tile",Vector2(446,20),Vector2(145,125))
 var entries=catalog(host,category)
 if category==0: heading(host,list,"Pilihan Hari Ini")
 var columns=4 if category==0 else 2
 var width=145 if columns==4 else 296
 for start in range(0,entries.size(),columns):
  if category==0 and start==4: heading(host,list,"Pilihan Kebun")
  if category==2 and start==4: heading(host,list,"Hewan · Beli per ekor")
  var row=Control.new();row.custom_minimum_size=Vector2(601,207 if columns==4 else 166);list.add_child(row)
  for n in range(start,mini(start+columns,entries.size())):
   tile(host,row,entries[n],Vector2((n-start)*(width+7),0),width,columns==4)
 if category==0: bonus(host,list)
 var selected=host.get_meta("shop_selected",{})
 if selected.is_empty(): selected=entries[0] if not entries.is_empty() else {}
 if not selected.is_empty(): detail(host,list,selected)
 if category==1 and host.game.needs_seed_recovery():
  var c=host.row_card(list,100,Color("fff0cf"))
  host.label(c,"Bibit habis? Mulai berkebun lagi.",Vector2(15,5),Vector2(570,30),19,host.GREEN,true)
  var wait=host.game.seed_recovery_seconds_left()
  host.seed_recovery_button=host.button(c,"AMBIL 3 BIBIT GRATIS" if wait==0 else "TUNGGU %d:%02d"%[wait/60,wait%60],Vector2(15,40),Vector2(570,48),host.GREEN,Color.WHITE,18)
  host.seed_recovery_button.disabled=wait>0;host.seed_recovery_button.pressed.connect(host.on_claim_seed_recovery)
 var links=host.row_card(list,76,Color("fff2d4"))
 for i in 3:
  var b=host.button(links,["Rawat Ternak","Atur Jalan","Pasar Tetangga"][i],Vector2(5+i*200,10),Vector2(190,52),Color("dbe9bd"),host.GREEN,16)
  b.pressed.connect(func(): host.switch_tab(["ternak","jalan","pasar"][i]))
static func heading(host,list,text: String):
 var c=host.row_card(list,42,Color("f7dfab"));host.label(c,text,Vector2(14,2),Vector2(570,36),23,Color("604322"),true)
static func tile(host,row,entry,at: Vector2,width: int,tall: bool):
 var card=Panel.new();card.name="ShopItem_"+entry.kind+"_"+entry.key
 card.position=at;card.size=Vector2(width,207 if tall else 166);card.add_theme_stylebox_override("panel",UI.style(Color("fff4d9"),Color("e6cca0"),20));row.add_child(card)
 picture(host,card,entry,Vector2(17,7),Vector2(width-34,95) if tall else Vector2(100,110))
 var label_at=Vector2(5,103) if tall else Vector2(120,13)
 var name=host.label(card,entry.name,label_at,Vector2(width-10 if tall else width-126,47),18 if tall else 19,Color("443c20"),true)
 name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 name.set_deferred("size",Vector2(width-10 if tall else width-126,47))
 if tall: name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var status="Lv %d"%entry.level
 if entry.kind=="seed": status="Stok: %d"%int(host.game.seeds.get(entry.key,0))
 elif entry.kind=="animal": status="%d / %d ekor"%[R.count(host.game,entry.key),R.capacity(host.game,entry.key)]
 elif entry.kind=="road": status="Stok: %d"%int(ROADS.prepare(host.game).stock[entry.key])
 if not tall: host.label(card,status,Vector2(120,68),Vector2(width-126,29),16,Color("8c6034"))
 var text="%d"%entry.price if entry.kind!="upgrade" else "Misi Upgrade"
 var why=reason(host,entry)
 if host.game.level<int(entry.level): text="Lv %d"%entry.level
 elif owned(host,entry): text="Dibangun"
 var buy=host.button(card,text,Vector2(8,158) if tall else Vector2(120,112),Vector2(width-16 if tall else width-130,41),Color("28aa3d"),Color.WHITE,17)
 buy.name="Buy_"+entry.kind+"_"+entry.key;buy.tooltip_text=entry.name+(" · "+why if not why.is_empty() else " · Beli 1")
 buy.icon=ICON.texture("koin");buy.expand_icon=true;buy.add_theme_constant_override("icon_max_width",24)
 buy.disabled=not why.is_empty();buy.pressed.connect(purchase.bind(host,entry,1))
 var select=Button.new();select.name="Detail_"+entry.kind+"_"+entry.key;select.flat=true;select.position=Vector2(0,0);select.size=Vector2(width,150 if tall else 108)
 select.tooltip_text="Lihat detail "+entry.name;card.add_child(select)
 select.pressed.connect(func(): host.set_meta("shop_selected",entry);host.set_meta("shop_quantity",1);host.show_sheet())
static func detail(host,list,entry):
 var card=host.row_card(list,176,Color("fff6df"));picture(host,card,entry,Vector2(9,12),Vector2(115,125))
 host.label(card,entry.name,Vector2(133,9),Vector2(310,35),24,Color("4a3a21"),true)
 var quantity=clampi(int(host.get_meta("shop_quantity",1)),1,100)
 var bulk=entry.kind in ["seed","road"]
 var description="Lv %d · %d koin per unit"%[entry.level,entry.price]
 if entry.kind=="seed": description="%d dtk tumbuh · 1 hasil · jual %d koin"%[host.game.CROPS[entry.key].grow,host.game.CROPS[entry.key].sell]
 host.label(card,description,Vector2(133,51),Vector2(455,44),17,Color("80643a")).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 if bulk:
  for i in 2:
   var b=host.button(card,"−" if i==0 else "+",Vector2(345+i*190,100),Vector2(52,48),Color("f5dfb5"),host.INK,25)
   b.name="QuantityMinus" if i==0 else "QuantityPlus"
   b.pressed.connect(func(): host.set_meta("shop_quantity",clampi(quantity+(-1 if i==0 else 1),1,100));host.show_sheet())
  host.label(card,str(quantity),Vector2(410,106),Vector2(95,38),24,host.GREEN,true).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var buy=host.button(card,"Beli · %d"%(entry.price*quantity) if entry.kind!="upgrade" else "Lihat Misi Upgrade",Vector2(133,107),Vector2(198,51),Color("22a23c"),Color.WHITE,19)
 buy.name="DetailBuy"
 buy.disabled=not reason(host,entry,quantity).is_empty();buy.tooltip_text=reason(host,entry,quantity);buy.pressed.connect(purchase.bind(host,entry,quantity))
 if entry.kind=="seed":
  var choose=host.button(card,"PILIH BIBIT",Vector2(345,151),Vector2(240,24),Color("ecd49b"),host.GREEN,14)
  choose.disabled=host.game.level<int(entry.level)
  choose.pressed.connect(func(): host.game.selected_crop=entry.key;host.game.save_game();host.refresh_all();host.show_toast("Bibit "+entry.name+" dipilih."))
static func purchase(host,entry,quantity: int):
 var why=reason(host,entry,quantity)
 if not why.is_empty(): host.show_toast(why);return
 match entry.kind:
  "tree":
   var empty=-1
   for i in host.game.orchard.size():
    if str(host.game.orchard[i].fruit).is_empty(): empty=i;break
   if empty<0: host.show_toast("Semua petak pohon sudah terisi.");return
   host.on_orchard_plant(empty,entry.key)
  "seed": host.buy_crop(entry.key,quantity)
  "road": preload("res://scripts/road_shop_ui.gd").buy(host,entry.key,quantity)
  "decor": host.on_buy_decoration(entry.key)
  "building": host.on_buy_construction(entry.key)
  "animal": STORE.purchase(host,entry.key,false)
  "pen":
   if entry.key=="ayam":
    var placement=preload("res://scripts/safe_asset_placement.gd")
    var at=placement.find(host.farm,"ayam",host.farm.object_position("ayam"))
    if at==Vector2.INF: host.show_toast("Rapikan lahan untuk kandang dahulu.");return
    if preload("res://scripts/first_coop.gd").build(host.game):
     placement.commit(host,"ayam",at)
     if host.farm.ranch_animator!=null: host.farm.ranch_animator.sync()
     host.refresh_all();host.show_toast("Kandang ayam dibangun.")
   else: STORE.purchase(host,entry.key,true)
  "upgrade": host.switch_tab("upgrade")
static func bonus(host,list):
 if host.ads==null: return
 var card=host.row_card(list,135,Color("efdafa"));ICON.add(card,"hadiah",Vector2(9,8),Vector2(64,64))
 host.label(card,"Bonus Permata",Vector2(83,6),Vector2(470,32),24,Color("6e397f"),true)
 host.label(card,"Hadiah melalui iklan yang tersedia saat ini.",Vector2(83,42),Vector2(500,26),16,host.INK)
 for i in 2:
  var kind="rewarded" if i==0 else "rewarded_interstitial"
  var caption=("Tonton Iklan" if host.ads.can_show_kind(kind) else "Klaim Gratis")+" +%d ◆"%(2+i)
  var b=host.button(card,caption,Vector2(12+i*299,81),Vector2(285,43),Color("1baf54") if i==0 else Color("169bd4"),Color.WHITE,18)
  b.pressed.connect(func(): host.ads.show_rewarded(kind))
 if host.ads.has_enabled_ads():
  var privacy=host.button(card,"Privasi Iklan",Vector2(430,3),Vector2(160,30),Color("eed6f4"),host.INK,14)
  privacy.pressed.connect(host.ads.show_privacy_options)
