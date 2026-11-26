extends SceneTree
const T=preload("res://scripts/reference_terrain.gd")
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://reference_playability.json";host.game.backup_path="user://reference_playability_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 var ftue
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"): ftue=child
  if child.get_script()==load("res://scripts/farm_progression.gd"): child.set_process(false)
 ftue.start_adventure()
 for i in 3: await process_frame
 var system=host.farm.hybrid_controller
 assert(not T.solid(host.farm.ujang_position),"Start button must spawn on lawn, not mountains")
 assert(not system.navigation.blocked(host.farm.ujang_position))
 assert(not system.controls_blocked(),"Starting tutorial must permit joystick movement")
 var before=host.farm.ujang_position
 for axis in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
  system.ui.joystick.axis=axis
  for i in 20: system._process(1.0/60.0)
  if host.farm.ujang_position.distance_to(before)>15: break
 system.ui.joystick.axis=Vector2.ZERO
 assert(host.farm.ujang_position.distance_to(before)>15,"Real joystick update must move character")
 assert(host.game.road_tiles.is_empty(),"Baked roads must not receive duplicate road tiles")
 assert(host.farm.MAX_ZOOM>=1.0 and host.farm.MAX_ZOOM<=1.2)
 for index in host.farm.WILD_TREES.size():
  if index in host.game.cleared_wild_trees: continue
  assert(T.asset_clear(host.farm.wild_tree_position(index)),"Tree must stand on dry ground: "+str(index))
 if DisplayServer.get_name()!="headless":
  host.toast_layer.hide()
  for i in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/latar-detail-perbaikan-awal.png"))
 print("REFERENCE PLAYABILITY PASS: real start and joystick movement, dry tree anchors, no duplicate roads, bounded zoom")
 host.queue_free();await process_frame;quit()
