extends RefCounted
const RANCH=preload("res://scripts/ranch_state.gd")
static func populate(host,list: VBoxContainer,selected: String="") -> void:
	host.callout(list,"KANDANG & PEMBELIAN HEWAN","Beli hewan. Perluas lahan pada Lv5 dan Lv10: 3 / 6 / 9 hewan.",Color("e1edda"))
	for species in RANCH.SPECIES:
		if selected!="" and selected!=species: continue
		var info: Dictionary=RANCH.INFO[species]
		preload("res://scripts/ranch_presentation.gd").hero(host,list,species)
		if not RANCH.available(host.game,species):
			var locked=host.row_card(list,100,Color("eee8db"))
			host.label(locked,str(info.name)+" / kandang belum dibangun",Vector2(15,12),Vector2(570,30),21,Color("355b48"),true)
			var build=host.button(locked,"BANGUN KANDANG / LV"+str(maxi(3,int(info.level)) if not host.game.ftue.is_empty() else int(info.level)),Vector2(15,48),Vector2(570,40),Color("dfcc9f"),Color("355b48"),16)
			build.pressed.connect(func(): host.switch_tab("bangun"))
			continue
		var pen: Dictionary=host.game.ranch.pens[species]
		var card=host.row_card(list,175,Color("fff5df"))
		var animal_icon=preload("res://scripts/colorful_icons.gd").add(card,"hewan",Vector2(13,8),Vector2(42,36))
		if host.farm.ranch_animator!=null: animal_icon.texture=host.farm.ranch_animator.frames.get(species+"0",animal_icon.texture)
		host.label(card,"%s / %d dari %d hewan / lahan %d"%[info.name,int(pen.count),RANCH.capacity(host.game,species),int(pen.tier)],Vector2(62,9),Vector2(523,34),21,Color("355b48"),true)
		host.label(card,"Hasil: %d telur / Pakan: %d Gandum"%[host.game.ranch_yield(species),RANCH.count(host.game,"ayam")] if species=="ayam" else "Hasil per siklus: %d / Pakan: %d porsi"%[host.game.ranch_yield(species),RANCH.feed_multiplier(host.game,species)],Vector2(15,45),Vector2(570,29),17,Color("6e795e"))
		var buy=host.button(card,"BELI "+str(info.name).to_upper()+" / "+str(info.price)+" KOIN",Vector2(15,82),Vector2(277,42),Color("387956"),Color.WHITE,16)
		buy.disabled=not RANCH.buy_reason(host.game,species).is_empty()
		buy.tooltip_text=RANCH.buy_reason(host.game,species)
		if RANCH.count(host.game,species)>=RANCH.capacity(host.game,species): buy.text="KANDANG PENUH"
		buy.pressed.connect(buy_animal.bind(host,species))
		var maxed=int(pen.tier)>=3
		var expand=host.button(card,"LAHAN MAKSIMAL" if maxed else "PERLUAS / %d KOIN / LV%d"%[RANCH.upgrade_cost(host.game,species),RANCH.upgrade_level(host.game,species)],Vector2(302,82),Vector2(282,42),Color("dba95d"),Color("4d4731"),15)
		expand.disabled=not RANCH.upgrade_reason(host.game,species).is_empty()
		expand.tooltip_text=RANCH.upgrade_reason(host.game,species)
		expand.pressed.connect(expand_pen.bind(host,species))
		if species=="ayam":
			var feed=host.button(card,"BERI PAKAN AYAM",Vector2(15,132),Vector2(277,32),Color("e7d5a6"),Color("355b48"),15)
			feed.disabled=not host.game.can_feed_chickens()
			feed.tooltip_text="Ayam awal mencari makan sendiri. Ayam tambahan perlu Gandum. Ambil telur yang siap sebelum memberi pakan baru."
			feed.pressed.connect(feed_chickens.bind(host))
		var focus=host.button(card,"LIHAT KANDANG",Vector2(302 if species=="ayam" else 15,132),Vector2(282 if species=="ayam" else 570,32),Color("deead4"),Color("355b48"),15)
		focus.pressed.connect(focus_pen.bind(host,species))
static func buy_animal(host,species: String) -> void:
	var reason=RANCH.buy_reason(host.game,species)
	if not RANCH.buy(host.game,species): host.show_toast(reason); return
	if host.farm.ranch_animator!=null: host.farm.ranch_animator.sync()
	host.refresh_all()
	host.show_toast(str(RANCH.INFO[species].name)+" ditambahkan ke kandang.")
static func expand_pen(host,species: String) -> void:
	var reason=RANCH.upgrade_reason(host.game,species)
	if not reason.is_empty(): host.show_toast(reason); return
	var pen: Dictionary=host.game.ranch.pens[species]
	var previous=int(pen.tier)
	pen.tier=previous+1
	var clear=host.farm.can_place(species,host.farm.object_position(species))
	pen.tier=previous
	if not clear:
		host.show_toast("Lahan perlu ruang kosong. Pindahkan kandang lewat ATUR, lalu perluas lagi.")
		return
	if RANCH.upgrade(host.game,species):
		host.farm.invalidate_scenery()
		host.farm.hybrid_controller.navigation.ensure()
		host.refresh_all()
		host.show_toast("Lahan kandang diperluas. Kapasitas "+str(RANCH.capacity(host.game,species))+" hewan.")
static func focus_pen(host,species: String) -> void:
	host.switch_tab("kebun")
	host.farm.hybrid_controller.data.follow=false
	host.farm.frame_asset(species)

static func feed_chickens(host) -> void:
	if host.game.feed_chickens(): host.show_toast("Ayam diberi makan. Telur siap dalam 38 detik.")
	else: host.show_toast("Ambil telur siap dulu, tunggu siklus selesai, atau siapkan Gandum untuk seluruh ayam.")
	host.refresh_all()
