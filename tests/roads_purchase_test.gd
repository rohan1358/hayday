extends SceneTree
const R=preload("res://scripts/road_catalog.gd")
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new(false)
	game.save_path="user://roads_purchase_test.json"
	game.backup_path="user://roads_purchase_backup.json"
	check(R.ORDER.size()==3 and not R.ITEMS.has("wood"),"three stone/brick variants with no wooden road")
	game.road_inventory={"stock":{"wood":4},"selected":"wood"}
	check(R.prepare(game).stock.moss==4 and game.road_inventory.selected=="moss" and not game.road_inventory.stock.has("wood"),"old wood purchases migrate once without loss")
	check(R.prepare(game).stock.moss==4,"migration cannot duplicate old inventory")
	game.road_inventory={}
	check(not R.place(game,"28,16"),"cannot place without bought stock")
	var before=game.coins
	check(R.buy(game,"stone",5) and game.coins==before-15 and game.road_inventory.stock.stone==5,"purchase charges listed coin price")
	check(not R.buy(game,"fake",1) and not R.buy(game,"moss",0) and not R.buy(game,"moss",-1),"invalid purchases rejected")
	game.coins=1
	check(not R.buy(game,"moss",1) and game.coins==1 and game.road_inventory.stock.moss==0,"insufficient coins never grant stock or charge")
	check(not R.place(game,"-1,0") and not R.place(game,"45,0"),"invalid map cells cannot consume stock")
	check(R.place(game,"28,16") and game.road_inventory.stock.stone==4,"placement consumes exactly one purchased unit")
	check(not R.place(game,"28,16") and game.road_inventory.stock.stone==4,"painting same style twice is free and unchanged")
	game.coins=100
	check(R.buy(game,"brick",2),"buy second variant")
	check(R.place(game,"28,16") and game.road_tiles["28,16"]=="brick" and game.road_inventory.stock.brick==1 and game.road_inventory.stock.stone==5,"restyling consumes new unit and returns old unit")
	before=game.coins
	check(R.erase(game,"28,16") and game.road_inventory.stock.brick==2 and game.coins==before,"erase returns material without minting coins")
	check(not R.erase(game,"28,16") and game.road_inventory.stock.brick==2,"repeated erase cannot duplicate inventory")
	R.place(game,"28,16")
	game.save_game()
	var loaded=FarmGameState.new(false)
	loaded.save_path=game.save_path
	loaded.backup_path=game.backup_path
	check(loaded.load_game() and R.style(loaded,"28,16")=="brick" and loaded.road_inventory.stock.brick==1,"styles and stock persist together")
	var legacy_wood=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	legacy_wood.road_inventory={"stock":{"wood":3},"selected":"wood"}
	legacy_wood.road_styles={"28,16":"wood"}
	var migration_file=FileAccess.open(game.save_path,FileAccess.WRITE)
	migration_file.store_string(JSON.stringify(legacy_wood));migration_file.close()
	check(loaded.load_game() and R.style(loaded,"28,16")=="moss" and R.prepare(loaded).stock.moss==3 and loaded.road_inventory.selected=="moss","old placed wood and remaining purchases convert to moss stone")
	loaded.save_game()
	check(loaded.load_game() and R.prepare(loaded).stock.moss==3,"wood conversion persists without duplicate stock")
	var old=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	old.erase("road_inventory")
	old.erase("road_styles")
	var f=FileAccess.open(game.save_path,FileAccess.WRITE)
	f.store_string(JSON.stringify(old));f.close()
	check(loaded.load_game() and R.style(loaded,"28,16")=="stone" and R.prepare(loaded).stock.stone==0,"legacy road array migrates without removing roads or inventing stock")
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://roads_live_test.json"
	host.game.backup_path="user://roads_live_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	host.game.new_game(false) # Legacy-farm regression fixture; FTUE has separate end-to-end tests.
	root.add_child(host)
	host.game.skip_onboarding()
	R.buy(host.game,"stone",2)
	var farm=host.farm
	farm.set_edit_mode(true)
	farm.set_road_tool("draw")
	farm.road_stroke_active=true
	var placed=[]
	for y in range(10,30):
		for x in range(20,40):
			var cell=Vector2i(x,y)
			if farm.can_paint_road(cell):
				farm.paint_road_cell(cell)
				placed.append(cell)
				if placed.size()==3: break
		if placed.size()==3: break
	check(host.game.road_tiles.size()==2 and host.game.road_inventory.stock.stone==0,"drag stops consuming when stock runs out")
	farm.finish_road_stroke()
	var saved=FarmGameState.new(false)
	saved.save_path=host.game.save_path;saved.backup_path=host.game.backup_path
	check(saved.load_game() and saved.road_tiles.size()==2 and saved.road_inventory.stock.stone==0,"stroke commits both geometry and stock")
	R.buy(host.game,"moss",1)
	var stock=int(host.game.road_inventory.stock.moss)
	var blocked=farm.road_cell_from_world(farm.object_position("dapur"))
	farm.paint_road_cell(blocked)
	check(host.game.road_inventory.stock.moss==stock,"blocked building cell never consumes purchased road")
	host.switch_tab("jalan")
	await process_frame
	check(host.active_tab=="jalan" and is_instance_valid(host.sheet),"three-variant shop opens")
	preload("res://scripts/road_shop_ui.gd").choose(host,"moss")
	check(host.active_tab=="kebun" and farm.edit_mode and farm.road_tool=="draw" and host.game.road_inventory.selected=="moss","shop places selected variant in edit brush")
	host.game.new_game(false)
	check(host.game.road_inventory.is_empty() and host.game.road_tiles.is_empty(),"new game clears road ownership and placement")
	host.queue_free();await process_frame
	print("ROAD PURCHASE FAILURES: ",failures)
	quit(failures)
