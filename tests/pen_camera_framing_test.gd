extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://pen_frame_test.json";host.game.backup_path="user://pen_frame_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.ftue.coop_built=true;host.game.level=3
 host.farm.set_process(false);host.farm.hybrid_controller.set_process(false)
 host.game.layout_positions.ayam=[1450,270]
 host.game.ftue.asset_overlap_repair=2
 preload("res://scripts/safe_asset_placement.gd").repair_owned_pens(host)
 var saved=host.game.layout_positions.duplicate(true)
 for view in [Vector2(720,1600),Vector2(720,1280),Vector2(1080,2400)]:
  host.farm.size=view
  host.farm.zoom_target=1.4
  host.farm.frame_asset("ayam",true)
  var bounds=preload("res://scripts/asset_projection.gd").info(host.farm,"ayam",host.farm.object_position("ayam")).bounds
  var virtual=host.farm.get_virtual_size()
  var screen=Rect2(virtual*0.5+(bounds.position-host.farm.camera_center)*host.farm.camera_zoom,bounds.size*host.farm.camera_zoom)
  assert(screen.position.y>=170 and screen.end.y<=virtual.y-130,str(screen))
  assert(screen.position.x>=105 and screen.end.x<=virtual.x-20,str(screen))
  host.farm.reset_camera()
  screen=Rect2(virtual*0.5+(bounds.position-host.farm.camera_center)*host.farm.camera_zoom,bounds.size*host.farm.camera_zoom)
  assert(screen.position.y>=170 and screen.end.y<=virtual.y-130,str(screen))
 assert(saved==host.game.layout_positions,"Camera must not relocate purchased assets")
 print("PEN FRAMING PASS: tall/wide mobile, zoomed focus, initial camera, HUD margins, layout unchanged")
 host.queue_free();await process_frame;quit()
