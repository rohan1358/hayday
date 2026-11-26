extends RefCounted
const UP = preload("res://scripts/building_upgrades.gd")
const GREEN = Color("368d5b")
const INK = Color("344b39")
static func link(ui,list) -> void:
	var card = ui.row_card(list,80,Color("f4e7cc"))
	var b = ui.button(card,"UPGRADE BANGUNAN & TOKO  ›",Vector2(16,10),Vector2(575,60),GREEN,Color.WHITE,18)
	b.pressed.connect(func(): ui.switch_tab("upgrade"))
static func populate(ui,list) -> void:
	var game = ui.game
	var data = UP.prepare(game)
	var bag = ui.row_card(list,175,Color("e5f2d8"))
	ui.label(bag,"BAHAN PEMBANGUNAN · TAS TERPISAH",Vector2(18,12),Vector2(575,30),20,GREEN,true)
	var column=0
	for kind in UP.MATERIALS:
		preload("res://scripts/colorful_icons.gd").add(bag,kind,Vector2(18+column*143,46),Vector2(32,32))
		ui.label(bag,"%s %d" % [UP.MATERIALS[kind],int(data.materials[kind])],Vector2(54+column*143,49),Vector2(102,30),17,INK,true)
		column+=1
	ui.label(bag,"Tebang pohon liar: +3 kayu. Pahat bongkahan: +3 batu.\nTambang: +1 palu dan +2 batu.\nSelesaikan pesanan: +1 paku.",Vector2(18,85),Vector2(575,80),17,INK)
	for kind in ["batu","kayu","palu"]:
		var row = ui.row_card(list,70,Color("f4e7cc"))
		var b = ui.button(row,"CARI "+UP.MATERIALS[kind].to_upper()+ (" DI TAMBANG" if kind=="palu" else ""),Vector2(16,8),Vector2(575,54),GREEN,Color.WHITE,18)
		b.pressed.connect(func(): gather(ui,kind))
	for key in UP.NAMES: building(ui,list,key)
	var note = ui.row_card(list,110,Color("f4e7cc"))
	ui.label(note,"Gudang: +30 kapasitas. Dapur: +1 antrean.\nRumah: bonus koin penjualan tamu.\nToko Roti / Susu: +1 antrean dan produksi lebih cepat.",Vector2(18,14),Vector2(570,90),18,INK)
static func building(ui,list,key: String) -> void:
	var game = ui.game
	var s = UP.spec(game,key)
	var data = UP.prepare(game)
	var active = data.missions.has(key)
	var card = ui.row_card(list,370 if int(s.tier)<5 else 90,Color("edf3e5"))
	ui.label(card,UP.NAMES[key].to_upper()+" · TINGKAT %d / 5" % int(s.tier),Vector2(18,12),Vector2(570,32),23,GREEN,true)
	if int(s.tier)>=5:
		ui.label(card,"Bangunan sudah mencapai tingkat tertinggi.",Vector2(18,50),Vector2(570,30),18,INK)
		return
	var benefit = "+30 ruang simpan" if key=="gudang" else ("+5% koin penjualan tamu" if key=="rumah" else "+1 slot antrean produksi")
	if key in ["roti","susu"]: benefit+=" · 10% lebih cepat"
	ui.label(card,benefit,Vector2(18,48),Vector2(570,30),18,INK,true)
	ui.label(card,"Syarat Lv.%d · %d koin" % [s.level,s.coins],Vector2(18,80),Vector2(570,28),18,INK)
	var text = ""
	for mat in s.materials: text+="%s %d/%d   " % [UP.MATERIALS[mat],data.materials[mat],s.materials[mat]]
	ui.label(card,text,Vector2(18,114),Vector2(570,55),18,INK)
	var y = 174
	for task in s.tasks:
		if int(s.tasks[task])<=0: continue
		ui.label(card,"%s: %d / %d" % [UP.TASKS[task],mini(UP.progress(game,key,task),int(s.tasks[task])),s.tasks[task]],Vector2(18,y),Vector2(570,29),18,INK)
		y+=30
	var can = UP.ready(game,key) if active else game.level>=int(s.level)
	var caption = "SELESAIKAN UPGRADE" if active else "MULAI MISI UPGRADE"
	if active and not can: caption="LENGKAPI TUGAS, BAHAN & KOIN"
	elif not can: caption="TERBUKA DI LEVEL %d" % int(s.level)
	var b = ui.button(card,caption,Vector2(18,300),Vector2(570,54),GREEN if can else Color("abb9a3"),Color.WHITE,18)
	b.name="Upgrade_"+key
	b.disabled=not active and not can
	b.pressed.connect(func():
		if active and not can:
			ui.show_toast("Lengkapi progres tugas, bahan, dan koin yang tercantum di kartu ini.")
			return
		var ok=UP.claim(game,key) if active else UP.start(game,key)
		ui.show_toast((UP.NAMES[key]+" berhasil ditingkatkan!") if active and ok else ("Misi dimulai. Tugas dihitung mulai sekarang." if ok else "Syarat belum terpenuhi."))
		ui.refresh_all()
		ui.switch_tab("upgrade")
	)
static func gather(ui,kind: String) -> void:
	var system=ui.farm.hybrid_controller
	if system==null: return
	if kind=="palu":
		ui.switch_tab("kebun")
		ui.set_meta("selected_region","tambang")
		ui.switch_tab("kawasan")
		return
	if kind=="kayu":
		var nearest=-1
		var distance=INF
		for i in ui.farm.WILD_TREES.size():
			if not ui.farm.wild_tree_active(i): continue
			var at: Vector2=ui.farm.wild_tree_position(i)
			if system.navigation.path(ui.farm.ujang_position,at+Vector2(80,45)).is_empty(): continue
			var d=ui.farm.ujang_position.distance_squared_to(at)
			if d<distance: nearest=i;distance=d
		if nearest<0:
			ui.show_toast("Tidak ada pohon liar yang dapat dijangkau.")
			return
		ui.switch_tab("kebun")
		system.enqueue({"action":"chop","target":"tree","index":nearest})
		return
	var nodes: Array=UP.prepare(ui.game).nodes
	var best=-1
	var distance=INF
	var wait=999999
	for i in nodes.size():
		if str(nodes[i].kind)!=kind: continue
		wait=mini(wait,maxi(0,int(nodes[i].ready_at)-ui.game.now()))
		if int(nodes[i].ready_at)>ui.game.now(): continue
		var at=Vector2(nodes[i].position[0],nodes[i].position[1])
		var d=ui.farm.ujang_position.distance_to(at)
		if d<distance: best=i; distance=d
	if best<0:
		ui.show_toast("Bongkahan tersedia lagi dalam %d detik." % wait if wait<999999 else "Belum ada bongkahan yang dapat dijangkau.")
		return
	ui.switch_tab("kebun")
	system.enqueue(UP.node_job(ui.game,best))
