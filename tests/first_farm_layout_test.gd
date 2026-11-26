extends SceneTree
var failures=0
func check(ok: bool,title: String):
 print("PASS: " if ok else "FAIL: ",title)
 if not ok: failures+=1
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://ftue_layout_test.json"
 host.game.backup_path="user://ftue_layout_test_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var ui
 for node in host.get_children():
  if node.get_script()==load("res://scripts/first_farm_ui.gd"): ui=node
 for resolution in [Vector2i(360,640),Vector2i(720,1280),Vector2i(720,1600),Vector2i(1080,2400)]:
  root.size=resolution
  for i in 6: await process_frame
  var bounds=Rect2(Vector2.ZERO,host.size)
  check(bounds.grow(1).encloses(ui.opening.get_global_rect()),"opening fits Android "+str(resolution))
  var play=ui.opening.find_child("StartAdventure",true,false)
  check(bounds.encloses(play.get_global_rect()) and play.size.y>=48,"play button is visible and touch-sized "+str(resolution))
 ui.start_adventure()
 check(preload("res://scripts/road_painter.gd").visible_tiles(host.farm).size()>0,"starter path uses actual visible movable road tiles")
 for resolution in [Vector2i(360,640),Vector2i(720,1600)]:
  root.size=resolution
  for i in 6: await process_frame
  ui.refresh()
  check(Rect2(Vector2.ZERO,host.size).encloses(ui.card.get_global_rect()),"mission fits Android "+str(resolution))
 check(not host.game.feature_unlocked("ranch") and not host.game.feature_unlocked("production"),"complex features are blocked in actual game state")
 host.switch_tab("produksi")
 check(host.active_tab=="kebun","hidden production menu cannot bypass unlock")
 var system=host.farm.hybrid_controller
 var start=host.farm.ujang_position
 system.enqueue({"action":"move","target":"position","position":[900,1000]},false)
 system.cancel_all("")
 check(system.active.is_empty() and system.data.jobs.is_empty(),"manual cancellation safely clears a tutorial movement command")
 host.queue_free();await process_frame
 print("FIRST FARM LAYOUT FAILURES: ",failures)
 quit(failures)
