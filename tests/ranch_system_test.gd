extends SceneTree
const R=preload("res://scripts/ranch_state.gd")
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new(false)
	game.save_path="user://ranch_state_test.json"
	game.backup_path="user://ranch_state_backup.json"
	check(R.count(game,"sapi")==2 and R.count(game,"ayam")==1,"old starter herd preserved")
	check(game.ranch_yield("sapi")==2 and game.ranch_yield("ayam")==2,"original production balance preserved")
	game.coins=10000
	check(not R.buy(game,"babi"),"cannot buy animal before its building")
	check(R.buy(game,"sapi") and R.count(game,"sapi")==3,"animal purchase updates count")
	var coins=game.coins
	check(not R.buy(game,"sapi") and game.coins==coins,"full pen cannot charge coins")
	game.level=4
	check(not R.upgrade(game,"sapi"),"land upgrade level gate")
	game.level=5
	check(R.upgrade(game,"sapi") and R.capacity(game,"sapi")==6 and R.scale(game,"sapi")>1,"upgrade increases physical area and capacity")
	game.inventory.gandum=2
	game.inventory.jagung=1
	check(not game.can_feed_cow(),"larger herd needs proportional feed")
	game.inventory.gandum=4
	game.inventory.jagung=2
	check(game.feed_cow() and game.inventory.gandum==0 and game.inventory.jagung==0,"feeding consumes correct amount")
	var expected=game.ranch_yield("sapi")
	check(R.buy(game,"sapi") and game.ranch_yield("sapi")==expected,"new animals cannot inflate an already fed cycle")
	game.cow_ready_at=game.now()-1
	game.storage_capacity=game.storage_used()+expected-1
	check(not game.collect_milk() and game.cow_ready_at>0,"full storage does not lose production")
	game.storage_capacity=100
	check(game.collect_milk() and game.inventory.susu==expected,"milk yield matches fed herd")
	game.level=10
	check(R.upgrade(game,"sapi") and R.capacity(game,"sapi")==9,"last land expansion available")
	coins=game.coins
	check(not R.upgrade(game,"sapi") and game.coins==coins,"cannot exceed maximum area")
	for species in ["babi","kambing"]:
		check(game.buy_construction("kandang_"+species),"build "+species)
		check(R.count(game,species)==1 and R.buy(game,species),"starter animal plus purchased "+species)
		for ingredient in game.ANIMALS[species].feed: game.inventory[ingredient]=int(game.ANIMALS[species].feed[ingredient])*2
		check(game.feed_animal(species),"feed enlarged "+species+" herd")
		game.livestock[species]=game.now()-1
		check(game.collect_animal(species) and int(game.inventory[game.ANIMALS[species].item])==4,"yield scales for "+species)
	game.inventory.gandum=20
	game.eggs_ready_at=game.now()+25
	check(R.buy(game,"ayam") and game.feed_chickens(),"purchased chickens receive real feed")
	var egg_yield=game.ranch_yield("ayam")
	var feed_stock=game.inventory.gandum
	check(not game.feed_chickens() and game.inventory.gandum==feed_stock,"same egg cycle cannot be fed twice")
	check(R.buy(game,"ayam") and game.ranch_yield("ayam")==egg_yield,"new chicken is excluded from an already fed cycle")
	game.eggs_ready_at=game.now()-1
	check(game.collect_eggs() and game.inventory.telur==egg_yield,"fed chickens produce correct egg count")
	check(game.ranch_yield("ayam")==2,"additional chickens need feeding for the next cycle")
	game.save_game()
	var copy=FarmGameState.new(false)
	copy.save_path=game.save_path
	copy.backup_path=game.backup_path
	check(copy.load_game() and copy.ranch==game.ranch,"owned animals, capacity and production snapshots persist")
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://ranch_view_test.json"
	host.game.backup_path="user://ranch_view_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	host.game.new_game(false) # Legacy-farm regression fixture; FTUE has separate end-to-end tests.
	root.add_child(host)
	host.set_process(false)
	host.farm.set_process(false)
	host.farm.hybrid_controller.set_process(false)
	var animator=host.farm.ranch_animator
	check(animator!=null and animator.agents.size()==3,"live sprites reflect exact owned herd")
	var initial: Dictionary={}
	for key in animator.agents: initial[key]=animator.agents[key].uv
	for i in 200: animator.tick(0.05)
	var moved=false
	for key in animator.agents:
		if animator.agents[key].uv.distance_to(initial[key])>0.02: moved=true
		var uv: Vector2=animator.agents[key].uv
		check(uv.x>=0.08 and uv.x<=0.92 and uv.y>=0.08 and uv.y<=0.92,"animal remains within fenced yard "+key)
	check(moved,"animals actually walk rather than static poses")
	host.game.coins=500
	check(R.buy(host.game,"ayam"),"buy live chicken")
	animator.sync()
	check(animator.agents.size()==4,"purchased animal appears without restart")
	host.game.level=10
	var previous=R.scale(host.game,"ayam")
	var before=host.farm.object_half_size("ayam")
	check(R.upgrade(host.game,"ayam"),"upgrade live pen")
	check(host.farm.object_half_size("ayam").x>before.x and R.scale(host.game,"ayam")>previous,"placement footprint expands with visual enclosure")
	var builds=host.farm.hybrid_controller.navigation.build_count
	host.farm.hybrid_controller.navigation.ensure()
	check(host.farm.hybrid_controller.navigation.build_count>builds,"navigation rebuilt after expansion")
	host.game.coins=10000
	var ui=preload("res://scripts/ranch_ui.gd")
	var original_house=host.game.layout_positions.get("dapur",[])
	host.game.layout_positions.dapur=[host.farm.object_position("sapi").x+200,host.farm.object_position("sapi").y]
	var before_coins=host.game.coins
	var tier_before=int(host.game.ranch.pens.sapi.tier)
	ui.expand_pen(host,"sapi")
	check(host.game.coins==before_coins and int(host.game.ranch.pens.sapi.tier)==tier_before,"blocked expansion never charges coins")
	if original_house.is_empty(): host.game.layout_positions.erase("dapur")
	else: host.game.layout_positions.dapur=original_house
	# Larger realistic pens require a deliberately cleared expansion lot.
	for tree in host.farm.WILD_TREES.size():
		if tree not in host.game.cleared_wild_trees: host.game.cleared_wild_trees.append(tree)
	for scenery in host.farm.MOVABLE_SCENERY.size(): host.game.layout_positions["scenery_%d"%scenery]=[3500,2700]
	var free=Vector2.INF
	host.game.ranch.pens.sapi.tier=3
	for y in range(350,2600,200):
		for x in range(350,3200,200):
			if host.farm.can_place("sapi",Vector2(x,y)):
				free=Vector2(x,y)
				break
		if free!=Vector2.INF: break
	host.game.ranch.pens.sapi.tier=tier_before
	check(free!=Vector2.INF,"expanded enclosure has valid free land")
	if free!=Vector2.INF:
		host.game.layout_positions.sapi=[free.x,free.y]
		ui.expand_pen(host,"sapi")
		check(int(host.game.ranch.pens.sapi.tier)==2 and host.game.coins==before_coins-220,"valid land expansion charges once")
		ui.expand_pen(host,"sapi")
		while R.count(host.game,"sapi")<R.capacity(host.game,"sapi"): R.buy(host.game,"sapi")
		animator.sync()
		check(R.count(host.game,"sapi")==9,"maximum herd fits expanded land")
		for i in 100: animator.tick(0.05)
		for animal in animator.agents.values(): check(animator.allowed(animal.species,animal.uv),"full herd avoids fences and pen furniture")
	host.switch_tab("ternak")
	check(host.sheet!=null,"animal shop and expansion panel opens")
	host.queue_free()
	await process_frame
	print("RANCH FAILURES: ",failures)
	quit(failures)
