extends RefCounted
# Unlimited level templates; objectives use persistent lifetime counters.
static func prepare(game):
	if not game.level_journey is Dictionary: game.level_journey={}
	if not game.level_journey.get("entries",{}) is Dictionary: game.level_journey.entries={}
	if not game.level_journey.has("entries"): game.level_journey.entries={}
	if not game.level_journey.get("queue",[]) is Array: game.level_journey.queue=[]
	if not game.level_journey.has("queue"): game.level_journey.queue=[]
	ensure_entry(game,game.level)
static func ensure_entry(game,level: int):
	var id=str(level)
	if not game.level_journey.entries.has(id):
		game.level_journey.entries[id]={"baseline":game.achievement_progress.duplicate(true),"claimed":false}
static func reached(game,level: int):
	prepare(game);ensure_entry(game,level)
	if level not in game.level_journey.queue: game.level_journey.queue.append(level)
static func goals(level: int) -> Array:
	var result=[{"counter":"panen","name":"Panen hasil kebun","goal":mini(80,3+level*2),"icon":"bibit"}]
	if level>=3: result.append({"counter":"pengiriman","name":"Selesaikan pesanan","goal":mini(8,1+int(level/8)),"icon":"pesanan"})
	if level>=5: result.append({"counter":"produksi","name":"Ambil hasil produksi","goal":mini(20,2+int(level/4)),"icon":"bangun"})
	return result
static func reward(level: int) -> Dictionary: return {"coins":mini(100000,30+level*10),"xp":mini(500,10+level*3)}
static func status(game,level: int) -> Dictionary:
	prepare(game);ensure_entry(game,level)
	var entry: Dictionary=game.level_journey.entries[str(level)]
	var rows=[];var ready=true
	for objective in goals(level):
		var value=maxi(0,int(game.achievement_progress.get(objective.counter,0))-int(entry.baseline.get(objective.counter,0)))
		var row=objective.duplicate();row.progress=mini(value,objective.goal);rows.append(row)
		if value<objective.goal: ready=false
	return {"rows":rows,"ready":ready and not bool(entry.claimed),"claimed":bool(entry.claimed),"reward":reward(level)}
static func claim(game,level: int) -> bool:
	if level<1 or level>game.level: return false
	var info=status(game,level)
	if not info.ready: return false
	game.level_journey.entries[str(level)].claimed=true
	game.coins+=int(info.reward.coins)
	game.award_xp(int(info.reward.xp));game.save_game()
	return true
static func unlocks(game,level: int) -> Array:
	var result=[]
	for id in preload("res://scripts/world_regions.gd").ORDER:
		var region: Dictionary = preload("res://scripts/world_regions.gd").DATA[id]
		if region.has("cost") and int(region.level)==level:
			result.append({"name":"Kawasan " + str(region.name) + " · Beli di Kawasan", "icon":"bangun", "asset":str(region.art)})
	var features={2:[["Perluasan Kebun","rumput"],["Dekorasi","bunga"],["Jalan","jalan"]],3:[["Kandang & Hewan","hewan"],["Pesanan","pesanan"]],4:[["Ekosistem Kebun","pohon"]],5:[["Dapur Produksi","bangun","kitchen_cottage"]]}
	for item in features.get(level,[]): result.append({"name":item[0],"icon":item[1],"asset":item[2] if item.size()>2 else ""})
	for id in game.CROPS:
		if int(game.crop_level(id))==level: result.append({"name":"Bibit "+str(game.CROPS[id].name),"icon":"bibit","crop":id})
	for id in game.CONSTRUCTIONS:
		if id not in game.BUILDING_ORDER: continue
		var required=int(game.CONSTRUCTIONS[id].level)
		if not game.ftue.is_empty(): required=1 if id in ["toko_roti","pabrik_susu"] else maxi(3 if id.begins_with("kandang_") else 5,required)
		if required==level:
			var assets={"pabrik_pakan":"feed_mill_building","kandang_babi":"pig_pen","kandang_kambing":"goat_pen","toko_roti":"bakery_building","pabrik_susu":"dairy_building"}
			result.append({"name":str(game.CONSTRUCTIONS[id].name),"icon":"bangun","asset":assets.get(id,"")})
	for id in game.DECORATIONS:
		if int(game.DECORATIONS[id].get("level",1))==level:
			result.append({"name":str(game.DECORATIONS[id].get("name",id)),"icon":"bunga","asset":id})
	if result.is_empty(): result.append({"name":"Misi Level %d"%level,"icon":"pesanan"})
	return result
static func populate(host,list):
	prepare(host.game)
	host.callout(list,"MISI PERJALANAN LEVEL","Tugas setiap level tersimpan sampai hadiahnya diambil. Tidak mengubah tata kebun.",Color("fff0cc"))
	var picker=OptionButton.new();picker.custom_minimum_size.y=48
	var levels=[]
	for key in host.game.level_journey.entries: levels.append(int(key))
	levels.sort()
	for number in levels: picker.add_item("Misi Level %d"%number,number)
	var selected=int(host.get_meta("journey_selected",host.game.level))
	if selected not in levels: selected=host.game.level
	picker.select(picker.get_item_index(selected));list.add_child(picker)
	picker.item_selected.connect(func(index): host.set_meta("journey_selected",picker.get_item_id(index));host.show_sheet())
	var info=status(host.game,selected)
	for row in info.rows:
		var card=host.row_card(list,70,Color("e7efd9"))
		host.label(card,"%s · %d/%d"%[row.name,row.progress,row.goal],Vector2(18,18),Vector2(570,34),20,host.GREEN,true)
		var bar=ProgressBar.new();bar.name="LevelMissionProgress_"+str(row.counter)
		bar.position=Vector2(18,56);bar.size=Vector2(570,10);bar.max_value=row.goal;bar.value=row.progress;bar.show_percentage=false
		card.add_child(bar)
	var card=host.row_card(list,125,Color("fff0c9"))
	host.label(card,"Hadiah: %d koin + %d XP"%[info.reward.coins,info.reward.xp],Vector2(16,8),Vector2(570,30),20,host.GREEN,true)
	var button=host.button(card,"SUDAH DIAMBIL" if info.claimed else ("AMBIL HADIAH MISI" if info.ready else "SELESAIKAN TUGAS DI ATAS"),Vector2(16,50),Vector2(570,54),host.GREEN,Color.WHITE,19)
	button.disabled=not info.ready
	button.pressed.connect(func():
		if claim(host.game,selected): host.show_toast("Hadiah misi Level %d diterima!"%selected);host.refresh_all();host.show_sheet())
