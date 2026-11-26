extends SceneTree
const P=preload("res://scripts/road_painter.gd")
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://iso_roads_test.json"
	host.game.backup_path="user://iso_roads_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	host.game.new_game(false) # Legacy-farm regression fixture; FTUE has separate end-to-end tests.
	root.add_child(host)
	host.farm.hybrid_controller.set_process(false)
	host.game.road_tiles={"28,16":"stone","29,16":"brick","30,16":"stone","29,15":"stone","29,17":"moss"}
	host.farm.camera_center=Vector2(2360,1320)
	host.farm.camera_target=host.farm.camera_center
	host.farm.camera_zoom=1.8
	var coins=host.game.coins
	var tiles=P.visible_tiles(host.farm)
	check(tiles.size()==P.cells_in_view(host.farm,host.farm.visible_world_rect(90.0)).size(),"one owned cell renders one block without extra paving")
	var occupied={}
	var seen={}
	var cells=P.cells_in_view(host.farm,host.farm.visible_world_rect(70.0))
	var all_fit=true
	for tile in tiles:
		occupied[Vector2i(tile.u,tile.v)]=true
		seen[tile.style]=true
		if P.sample(host.farm,tile.at,cells).is_empty() or not host.farm.road_surface_clear_of_objects(tile.at,tile.at,host.farm.ROAD_HALF_WIDTH): all_fit=false
	check(occupied.size()==tiles.size(),"connected road cells do not draw duplicate tiles")
	check(all_fit,"paving follows owned road corridors and stays clear of objects")
	check(seen.has("stone") and seen.has("brick") and seen.has("moss"),"all three materials can meet at a junction")
	for id in ["stone","brick","moss"]:
		var data=P.sprite(id)
		check(not data.is_empty() and data.preview!=null,"authored path texture available "+id)
		if not data.is_empty(): check(maxi(data.texture.get_width(),data.texture.get_height())<=256,"mobile texture bound "+id)
	check(host.game.coins==coins,"rendering never charges coins or changes road ownership")
	host.queue_free();await process_frame
	print("ISOMETRIC ROAD FAILURES: ",failures)
	quit(failures)
