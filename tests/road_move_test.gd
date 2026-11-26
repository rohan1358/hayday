extends SceneTree
var failures=0
func check(ok: bool,message: String):
 print("PASS: " if ok else "FAIL: ",message)
 if not ok: failures+=1
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://road_move_test.json"
 host.game.backup_path="user://road_move_test_backup.json"
 host.game.new_game(false) # Legacy-farm regression fixture; FTUE has separate end-to-end tests.
 root.add_child(host)
 host.game.new_game(false)
 host.game.road_tiles.clear()
 var farm=host.farm
 var game=host.game
 var catalog=preload("res://scripts/road_catalog.gd")
 var spots=[]
 for y in range(23,27):
  for x in range(3,8):
   var cell=Vector2i(x,y)
   if farm.can_paint_road(cell): spots.append(cell)
 check(spots.size()>4,"clear road destinations exist")
 var origin=spots[0]
 var target=spots[3]
 var source=farm.road_key(origin)
 var destination=farm.road_key(target)
 game.coins=200
 var before=game.coins
 check(catalog.buy(game,"brick",2),"new roads still bought with coins")
 check(game.coins==before-10,"purchase charges correct coins")
 catalog.place(game,source)
 var coins=game.coins
 var stock=catalog.prepare(game).stock.duplicate(true)
 farm.set_edit_mode(true)
 var pos=farm.road_visual_center(origin)
 var screen=(pos-farm.camera_center)*farm.camera_zoom*farm.size/farm.get_virtual_size()+farm.size*0.5
 farm.begin_edit_drag(screen)
 check(farm.drag_key=="road_"+source,"existing road can be selected by drag")
 var to=farm.road_visual_center(target)
 check(farm.can_place("road_"+source,to),"road accepts clear destination")
 check(not farm.can_place("road_"+source,Vector2(-50,-50)),"road rejects outside map")
 check(not farm.can_place("road_"+source,farm.object_position("dapur")),"road rejects building overlap")
 var destination_screen=(to-farm.camera_center)*farm.camera_zoom*farm.size/farm.get_virtual_size()+farm.size*0.5
 farm.move_edit_drag(destination_screen)
 farm.finish_edit_drag()
 check(not game.road_tiles.has(source) and game.road_tiles.get(destination)=="brick","drag commits road to new location preserving variant")
 check(game.coins==coins and catalog.prepare(game).stock==stock,"moving costs no coins or inventory")
 catalog.place(game,source)
 check(not farm.can_place("road_"+destination,farm.road_visual_center(origin)),"occupied road destination rejected")
 check(not catalog.move(game,destination,source),"failed move preserves both roads")
 game.save_game()
 var restored=preload("res://scripts/game_state.gd").new()
 restored.save_path=game.save_path
 restored.backup_path=game.backup_path
 restored.load_game()
 check(restored.road_tiles.get(destination)=="brick","moved road survives save/load")
 host.queue_free()
 await process_frame
 print("ROAD MOVE FAILURES: ",failures)
 quit(failures)
