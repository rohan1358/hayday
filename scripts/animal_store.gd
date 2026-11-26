extends RefCounted
const R=preload("res://scripts/ranch_state.gd")
const COST={"sapi":200,"babi":220,"kambing":320}
static func owned(game,species: String) -> bool:
	return (bool(game.ftue.get("cow_built",false)) or game.ftue.is_empty()) if species=="sapi" else game.has_construction("kandang_"+species)
static func buy_pen(game,species: String) -> bool:
	if not COST.has(species) or game.level<3 or not game.feature_unlocked("ranch") or owned(game,species) or game.coins<int(COST[species]): return false
	if species=="sapi":
		game.coins-=COST.sapi
		game.ftue.cow_built=true
		R.prepare(game)
		game.ranch.pens.sapi.count=0
		game.save_game()
		return true
	return game.buy_construction("kandang_"+species)
static func populate(ui,parent,game):
	ui.callout(parent,"TOKO TERNAK · LEVEL 3","Beli kandang dan hewan secara terpisah. Setiap pembelian hewan menambahkan satu ekor yang hidup di kandangnya.",Color("fff1cc"))
	for species in ["sapi","babi","kambing"]:
		var name=str(R.INFO[species].name)
		var has_pen=owned(game,species)
		var card=ui.row_card(parent,170,Color("e5efda"))
		ui.label(card,"KANDANG "+name.to_upper()+" · LEVEL 3",Vector2(14,10),Vector2(570,30),21,Color("355b48"),true)
		var pen=ui.button(card,"SUDAH DIBELI" if has_pen else ("TERKUNCI · LEVEL 3" if game.level<3 else "BELI KANDANG "+name.to_upper()+" · %d KOIN"%COST[species]),Vector2(14,50),Vector2(570,44),Color("387956"),Color.WHITE,17)
		pen.disabled=has_pen or game.level<3 or game.coins<int(COST[species])
		pen.pressed.connect(purchase.bind(ui,species,true))
		var animal=ui.button(card,"BELI 1 "+name.to_upper()+" · %d KOIN"%R.INFO[species].price,Vector2(14,105),Vector2(570,44),Color("dfcc9f"),Color("355b48"),17)
		animal.disabled=game.level<3 or not R.buy_reason(game,species).is_empty()
		animal.tooltip_text=R.buy_reason(game,species)
		animal.pressed.connect(purchase.bind(ui,species,false))
static func purchase(ui,species: String,pen: bool):
	var placement=preload("res://scripts/safe_asset_placement.gd")
	var at=Vector2.INF
	if pen:
		at=load("res://scripts/island_layout.gd").purchase_spot(ui,species)
		if at==Vector2.INF: ui.show_toast("Tidak ada lahan kosong untuk kandang. Rapikan lahan dahulu; koin tidak dipotong.");return
	var ok=buy_pen(ui.game,species) if pen else R.buy(ui.game,species)
	if ok and pen: placement.commit(ui,species,at)
	if not ok: ui.show_toast("Level, koin, atau kapasitas kandang belum memenuhi syarat.");return
	ui.farm.invalidate_scenery()
	if ui.farm.ranch_animator!=null: ui.farm.ranch_animator.sync()
	ui.refresh_all()
	ui.switch_tab("toko")
	ui.show_toast("Kandang dibeli. Sekarang beli hewannya." if pen else "Satu "+str(R.INFO[species].name)+" ditambahkan ke kandang.")
