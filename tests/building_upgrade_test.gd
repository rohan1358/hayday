extends SceneTree
const UP=preload("res://scripts/building_upgrades.gd")
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new(false)
	game.save_path="user://building_upgrade_test.json"
	game.backup_path="user://building_upgrade_test_backup.json"
	game.coins=10000
	check(game.production_capacity()==3 and game.storage_capacity==60,"baseline storage and kitchen preserved")
	check(not UP.start(game,"dapur"),"upgrade level gate")
	game.level=20
	game.achievement_progress.panen=100
	check(UP.start(game,"gudang") and not UP.start(game,"gudang"),"start once and snapshot existing progress")
	check(UP.progress(game,"gudang","panen")==0,"old harvest does not complete new mission")
	check(not game.upgrade_storage(),"old coin-only path cannot bypass mission")
	var data=UP.prepare(game)
	for mat in UP.MATERIALS: data.materials[mat]=100
	var coins=game.coins
	check(not UP.claim(game,"gudang") and game.coins==coins and data.materials.palu==100,"unfinished mission cannot consume materials")
	game.add_achievement_progress("panen",6)
	game.add_achievement_progress("pengiriman")
	check(UP.ready(game,"gudang") and UP.claim(game,"gudang"),"completed mission upgrades warehouse")
	check(game.storage_capacity==90 and UP.tier(game,"gudang")==2 and game.coins==coins-100,"capacity tier and coin transaction")
	coins=game.coins
	check(not UP.claim(game,"gudang") and game.coins==coins,"repeated claim cannot charge twice")
	for key in ["dapur","rumah"]:
		check(UP.start(game,key),"start "+key)
		game.add_achievement_progress("panen",6)
		game.add_achievement_progress("pengiriman")
		if key=="dapur": game.add_achievement_progress("produksi")
		check(UP.claim(game,key),"complete "+key)
	check(game.storage_capacity==90 and game.production_capacity()==4,"three building benefits stack correctly")
	game.inventory.gandum=50
	for i in 4: check(game.queue_product("roti"),"upgraded kitchen accepts slot "+str(i+1))
	check(not game.queue_product("roti"),"kitchen respects upgraded maximum")
	game.save_game()
	var loaded=FarmGameState.new(false)
	loaded.save_path=game.save_path
	loaded.backup_path=game.backup_path
	check(loaded.load_game() and loaded.production_queue.size()==4 and loaded.production_capacity()==4,"expanded queue survives load")
	check(loaded.storage_capacity==90 and UP.tier(loaded,"rumah")==2,"save restores benefits without doubling capacity")
	UP.prepare(loaded)
	check(loaded.storage_capacity==90,"prepare is idempotent")
	game.coins=100000
	for mat in UP.MATERIALS: UP.prepare(game).materials[mat]=1000
	for key in UP.NAMES:
		while UP.tier(game,key)<5:
			check(UP.start(game,key),"start next tier "+key)
			var requirements=UP.spec(game,key).tasks
			for task in requirements: game.add_achievement_progress(task,int(requirements[task]))
			check(UP.claim(game,key),"complete next tier "+key)
		check(UP.tier(game,key)==5 and not UP.start(game,key) and not UP.claim(game,key),"maximum tier cannot be exceeded "+key)
	check(game.production_capacity()==15 and game.storage_capacity==180,"all four upgrades stack to final capacities")
	game.new_game(false)
	check(game.building_upgrades.is_empty() and game.production_capacity()==3 and game.storage_capacity==60,"new game resets building progress")
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://building_upgrade_live_test.json"
	host.game.backup_path="user://building_upgrade_live_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	host.game.new_game(false) # Legacy-farm regression fixture; FTUE has separate end-to-end tests.
	root.add_child(host)
	await process_frame
	var system=host.farm.hybrid_controller
	system.set_process(false)
	host.game.building_upgrades.nodes=[{"kind":"palu","position":[250,180],"ready_at":0},{"kind":"batu","position":[400,300],"ready_at":0}]
	host.game.building_upgrades.gathering_version=2
	host.game.building_upgrades.materials.kayu=7
	UP.setup_nodes(system)
	check(int(host.game.building_upgrades.gathering_version)==3 and int(host.game.building_upgrades.materials.kayu)==7,"old floating resources migrate without losing materials")
	var nodes: Array=UP.prepare(host.game).nodes
	check(nodes.size()>0,"boulders placed on clear reachable grass")
	for node in nodes: check(str(node.kind)=="batu" and float(node.position[1])>=820,"only grounded boulders remain")
	system.navigation.ensure()
	check(system.navigation.blocked(Vector2(nodes[0].position[0],nodes[0].position[1])),"resource pile blocks walking through its center")
	var job=UP.node_job(host.game,0)
	var old=host.game.storage_capacity
	host.game.storage_capacity=host.game.storage_used()
	check(system.actions.valid(job)=="" and system.actions.execute(job).ok,"gather works through existing interaction action with full storage")
	check(host.game.building_upgrades.materials.batu==3,"real resource reward")
	check(not system.actions.execute(job).ok,"stale queued gather cannot duplicate reward")
	check(not UP.valid_node(host.game,UP.node_job(host.game,0)),"cooldown blocks repeat gathering")
	host.game.storage_capacity=old
	host.game.building_upgrades.nodes[0].ready_at=0
	job=UP.node_job(host.game,0)
	check(system.enqueue(job),"gather enters character queue")
	system.cancel_all()
	check(host.game.building_upgrades.materials.batu==3,"cancelled action grants no material")
	host.game.skip_onboarding()
	host.switch_tab("kebun")
	system.ui.menu.hide()
	system.enqueue(UP.node_job(host.game,0))
	for i in 2000:
		system._process(0.1)
		if host.game.building_upgrades.materials.batu>3: break
	check(host.game.building_upgrades.materials.batu==6,"character follows path and actually gathers material")
	host.game.level=20
	var nails=int(host.game.building_upgrades.materials.paku)
	for i in 2:
		host.game.orders[0]={"items":{"gandum":1},"coins":10,"xp":1,"ready_at":0}
		host.game.inventory.gandum=10
		check(host.game.deliver_order(0),"real delivery accepted")
	check(host.game.building_upgrades.materials.paku==nails+2 and host.game.building_upgrades.materials.palu==0,"delivery awards nails; hammers come from the mine")
	var regions=preload("res://scripts/world_regions.gd")
	host.game.world_regions.owned["tambang"]=true
	regions.action(host.game,"tambang")
	check(host.game.building_upgrades.materials.palu==1,"mine awards a hammer")
	regions.action(host.game,"tambang")
	check(host.game.building_upgrades.materials.palu==1,"mine cooldown prevents duplicate hammer")
	var wood_before=int(host.game.building_upgrades.materials.kayu)
	check(host.game.clear_wild_tree(999) and host.game.building_upgrades.materials.kayu==wood_before+3,"tree clearing awards construction wood")
	for tab in ["upgrade","produksi","gudang","misi","toko"]:
		host.switch_tab(tab)
		await process_frame
		check(host.active_tab==tab,"page opens "+tab)
	host.queue_free()
	await process_frame
	print("BUILDING UPGRADE FAILURES: ",failures)
	quit(failures)
