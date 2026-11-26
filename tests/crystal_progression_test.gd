extends SceneTree
const PACK=preload("res://scripts/living_garden_assets.gd")
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new(false)
	game.save_path="user://crystal_progression_test.json"
	game.backup_path="user://crystal_progression_backup.json"
	game.coins=20000
	var count=game.plots.size()
	assert(game.CROPS.stroberi.level==4)
	assert(game.CROPS.stroberi_kristal.level==20)
	for crop in game.CROPS: assert(int(game.CROPS[crop].level)<=20)
	game.level=4
	assert(game.buy_seeds("stroberi",1) and game.plant(0,"stroberi"))
	game.plots[0].ready_at=game.now()-1
	assert(game.harvest(0)==3 and game.inventory.stroberi==3)
	game.level=19
	var coins=game.coins
	assert(not game.buy_seeds("stroberi_kristal",1) and game.coins==coins)
	game.seeds.stroberi_kristal=1
	assert(not game.can_plant(0,"stroberi_kristal"))
	game.seeds.stroberi_kristal=0
	game.level=20
	assert(game.buy_seeds("stroberi_kristal",1))
	assert(game.coins==coins-160)
	assert(game.can_plant(0,"stroberi_kristal") and game.plant(0,"stroberi_kristal"))
	assert(game.plots.size()==count and count==16)
	assert(game.seeds.stroberi_kristal==0 and not game.is_ready(0))
	var copy=FarmGameState.new(false)
	copy.save_path=game.save_path
	copy.backup_path=game.backup_path
	assert(copy.load_game())
	assert(copy.plots[0].crop=="stroberi_kristal" and copy.inventory.stroberi==3)
	copy.plots[0].ready_at=copy.now()-1
	copy.storage_capacity=copy.storage_used()+2
	assert(copy.harvest(0)==0 and copy.plots[0].crop=="stroberi_kristal")
	copy.storage_capacity=100
	assert(copy.harvest(0)==3 and copy.inventory.stroberi_kristal==3)
	var before=copy.coins
	assert(copy.sell_all("stroberi_kristal")==675 and copy.coins==before+675)
	assert(copy.inventory.stroberi_kristal==0 and copy.plots[0].crop=="")
	copy.save_game()
	assert(game.load_game() and game.inventory.stroberi_kristal==0)
	for entry in PACK.ITEMS:
		var info=game.DECORATIONS[entry.id]
		game.level=int(info.level)-1
		var before_purchase=game.coins
		assert(game.buy_decoration(entry.id)=="" and game.coins==before_purchase)
		game.level=int(info.level)
		var key=game.buy_decoration(entry.id)
		assert(key!="")
		assert(game.set_decoration_position(key,Vector2(2800,2200)))
		game.level=int(info.level)-1
		assert(not game.set_decoration_position(key,Vector2(2810,2200)))
		assert(game.store_decoration(key))
	game.level=20
	var art=FarmArt.new()
	for entry in PACK.ITEMS: assert(art.sprites.has(entry.id))
	for id in PACK.GROWTH_IDS: assert(art.sprites.has(id))
	print("CRYSTAL PROGRESSION PASS: Lv4 ordinary strawberry unchanged; Lv20 highest seed, same 16 plots, buy/plant/grow/harvest/sell/save/load; storage safety; 12 decoration level gates and 4 crystal growth assets")
	quit()
