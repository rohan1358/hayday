extends SceneTree
const CAT=preload("res://scripts/wardrobe_catalog.gd")
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new()
	game.coins=235
	game.inventory.gandum=5
	game.level=2
	var plots=game.plots.duplicate(true)
	game.seasonal={"gender":"female","name":"Ujang","outfit":3,"owned":["wardrobe_acc_0","wardrobe_acc_3","wardrobe_acc_3","outfit3","equipment0"],"wardrobe_slots":{"head":0,"face":1,"bag":3}}
	assert(CAT.prepare(game))
	assert(game.coins==335)
	assert(game.inventory.gandum==5 and game.level==2 and game.plots==plots)
	assert(game.seasonal.name=="Ujang" and game.seasonal.outfit==3)
	assert("outfit3" in game.seasonal.owned and "equipment0" in game.seasonal.owned)
	assert(not game.seasonal.wardrobe_slots.has("face"))
	assert(game.seasonal.wardrobe_slots==CAT.defaults("female"))
	assert(not CAT.prepare(game) and game.coins==335)
	CAT.select_gender(game.seasonal,"male")
	assert(game.seasonal.wardrobe_slots==CAT.defaults("male"))
	game.seasonal.wardrobe_slots.erase("head")
	CAT.remember(game.seasonal)
	CAT.select_gender(game.seasonal,"female")
	assert(game.seasonal.wardrobe_slots==CAT.defaults("female"))
	CAT.select_gender(game.seasonal,"male")
	assert(not game.seasonal.wardrobe_slots.has("head"))
	game.seasonal.wardrobe_slots.neck=1
	CAT.prepare(game)
	assert(not game.seasonal.wardrobe_slots.has("neck"))
	for gender in ["female","male"]:
		for season in 4:
			var items=CAT.items(gender,season)
			assert(items.size()==3)
			for i in 3:
				assert(CAT.gender_of(items[i])==gender and CAT.season_of(items[i])==season and CAT.slot_of(items[i])==CAT.SLOTS[i])
	print("COLORFUL CATALOG PASS: one-time reset/refund, no repeated refund, retained crops/progress/costume, gender-isolated equipment, stale/wrong-gender removal, eight seasonal collections")
	quit()
