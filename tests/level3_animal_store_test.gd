extends SceneTree
const STORE=preload("res://scripts/animal_store.gd")
const R=preload("res://scripts/ranch_state.gd")
func _initialize(): call_deferred("run")
func run():
	var h=load("res://scenes/Main.tscn").instantiate()
	h.game.save_path="user://level3_animal_store_test.json"
	h.game.backup_path="user://level3_animal_store_test_backup.json"
	DirAccess.remove_absolute(h.game.save_path);DirAccess.remove_absolute(h.game.backup_path)
	root.add_child(h)
	for frame in 3: await process_frame
	var g=h.game
	g.ftue.started=true;g.ftue.step="done";g.coins=5000;g.level=2
	for species in ["sapi","babi","kambing"]:
		assert(not STORE.buy_pen(g,species) and not R.buy(g,species))
	assert(g.coins==5000)
	g.level=3
	h.switch_tab("toko")
	var captions=[]
	for b in h.sheet.find_children("*","Button",true,false): captions.append(b.text)
	for species in ["sapi","babi","kambing"]:
		var before=g.coins
		assert(STORE.buy_pen(g,species) and g.coins==before-int(STORE.COST[species]))
		assert(R.count(g,species)==0,"Buying the pen does not grant a free animal")
		assert(not STORE.buy_pen(g,species))
		before=g.coins
		assert(R.buy(g,species) and R.count(g,species)==1 and g.coins==before-int(R.INFO[species].price))
	h.farm.ranch_animator.sync()
	for species in ["sapi","babi","kambing"]: assert(h.farm.ranch_animator.agents.has(species+"_0"))
	for i in 300: h.farm.ranch_animator.tick(0.05)
	for a in h.farm.ranch_animator.agents.values(): assert(h.farm.ranch_animator.allowed(a.species,a.uv))
	g.save_game()
	var copy=FarmGameState.new();copy.save_path=g.save_path;copy.backup_path=g.backup_path
	assert(copy.load_game())
	for species in ["sapi","babi","kambing"]: assert(STORE.owned(copy,species) and R.count(copy,species)==1)
	h.queue_free();await process_frame
	print("LEVEL 3 ANIMAL STORE PASS: locked at 2, three pens and animals purchasable at 3, exact coin deductions, no free animals, live bounded agents, save/load")
	quit()
