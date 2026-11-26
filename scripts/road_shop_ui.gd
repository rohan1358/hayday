extends RefCounted
const ROADS=preload("res://scripts/road_catalog.gd")
static func link(host,list) -> void:
	var card=host.row_card(list,80,Color("e6ecff"))
	var b=host.button(card,"TOKO JALAN · 3 VARIAN",Vector2(16,10),Vector2(575,60),Color("6979bd"),Color.WHITE,20)
	b.pressed.connect(func(): host.switch_tab("jalan"))
static func populate(host,list) -> void:
	host.callout(list,"1 UNIT = 1 UBIN BESAR","Beli dengan koin, pasang, lalu pindahkan melalui PINDAH ASET.",Color("e2efdb"))
	var game=host.game
	var data=ROADS.prepare(game)
	var intro=host.row_card(list,146,Color("e7efff"))
	host.label(intro,"JALAN UNTUK KEBUNMU",Vector2(20,15),Vector2(565,31),23,Color("368d5b"),true)
	var instructions=host.label(intro,"Beli memakai koin; setiap ruas memakai 1 stok.\nHapus jalan untuk mengembalikannya ke stok.\nStok jalan terpisah dari kapasitas gudang.",Vector2(20,53),Vector2(565,80),18,Color("6e795e"))
	instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for id in ROADS.ORDER:
		var info: Dictionary=ROADS.ITEMS[id]
		var card=host.row_card(list,224,Color("fff5df"))
		var icon=preload("res://scripts/colorful_icons.gd").add(card,"road_"+id,Vector2(17,12),Vector2(86,86))
		var preview=preload("res://scripts/road_painter.gd").preview(id)
		if preview!=null: icon.texture=preview
		host.label(card,str(info.name),Vector2(119,16),Vector2(465,34),25,Color("355b48"),true)
		host.label(card,"%d koin / ruas · Stok: %d" % [int(info.price),int(data.stock[id])],Vector2(120,57),Vector2(460,32),20,Color("6e795e"),true)
		var selected=" · DIPILIH" if str(data.selected)==id else ""
		host.label(card,"Terpasang: %d ruas%s" % [count_placed(game,id),selected],Vector2(20,106),Vector2(563,30),18,Color("766448"))
		var one=host.button(card,"BELI 1 · %d" % int(info.price),Vector2(18,155),Vector2(180,51),Color("d39939"),Color.WHITE,17)
		one.disabled=game.coins<int(info.price)
		one.pressed.connect(buy.bind(host,id,1))
		var five=host.button(card,"BELI 5 · %d" % (int(info.price)*5),Vector2(211,155),Vector2(180,51),Color("b78032"),Color.WHITE,17)
		five.disabled=game.coins<int(info.price)*5
		five.pressed.connect(buy.bind(host,id,5))
		var place=host.button(card,"PASANG",Vector2(404,155),Vector2(180,51),Color("2c966b"),Color.WHITE,18)
		place.disabled=int(data.stock[id])<=0
		place.pressed.connect(choose.bind(host,id))
	var note=host.row_card(list,146,Color("f1e8ff"))
	host.label(note,"TANPA BIAYA ULANG",Vector2(20,15),Vector2(565,31),23,Color("368d5b"),true)
	var explanation=host.label(note,"Untuk ganti varian, pakai 1 ruas varian baru.\nRuas lama kembali ke stok dan bisa dipakai lagi.\nJalan lama otomatis menjadi Batu Pastel.",Vector2(20,53),Vector2(565,80),18,Color("6e795e"))
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
static func count_placed(game,id: String) -> int:
	var total=0
	for key in game.road_tiles:
		if ROADS.style(game,str(key))==id: total+=1
	return total
static func buy(host,id: String,amount: int) -> void:
	if ROADS.buy(host.game,id,amount): host.show_toast("%d ruas %s masuk stok jalan." % [amount,ROADS.ITEMS[id].name])
	else: host.show_toast("Koin tidak cukup atau stok sudah maksimal.")
	host.refresh_all()
static func choose(host,id: String) -> void:
	var data=ROADS.prepare(host.game)
	if not ROADS.ITEMS.has(id) or int(data.stock.get(id,0))<=0: return
	data.selected=id
	host.game.save_game()
	host.switch_tab("kebun")
	if not host.farm.edit_mode: host.toggle_arrange_mode()
	host.select_road_tool("draw")
