extends SceneTree
const R=preload("res://scripts/world_regions.gd")
const T=preload("res://scripts/reference_terrain.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://visible_districts.json";host.game.backup_path="user://visible_districts_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path));root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 assert(load("res://scripts/island_layout.gd").state(host.game).get("zoning_version",0)==13,"Large-asset layout must complete")
 var before=host.game.coins;var xp=host.game.xp
 for id in R.ORDER:
  var info=R.DATA[id]
  if not info.has("cost"):continue
  assert(not R.purchased(host.game,id),"Preview must not grant ownership")
  var at=host.farm.object_position("region_"+id)
  var art=host.farm.farm_art.ground_bounds(info.art,at,info.width)
  assert(preload("res://scripts/waterfront.gd").supported("region_"+id,at) if id in ["pemancingan","pelabuhan"] else T.scene_supported(at,info.half),"Building base must be supported by dry ground: "+id)
  assert(not host.farm.hybrid_controller.navigation.path(host.farm.ujang_position,at).size(),"Locked building must obstruct movement")
  var hit=load("res://scripts/world_regions_painter.gd").hit(host.farm,art.get_center())
  assert(hit==id,"Full preview must be tappable: "+id+" got "+hit)
  if info.level>1:
   host.farm.hybrid_controller.tap_world(art.get_center())
   assert(host.active_tab=="kebun" and not R.purchased(host.game,id))
 assert(host.game.coins==before and host.game.xp==xp,"Viewing locked districts must not alter resources")
 host.farm.hybrid_controller.set_process(false);host.toast_layer.hide()
 host.farm.camera_target=Vector2(2160,4060);host.farm.camera_center=host.farm.camera_target;host.farm.camera_zoom=.15;host.farm.zoom_target=.15;host.farm.queue_redraw()
 for i in 14:await process_frame
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/kawasan-terkunci-level-1.png"))
 host.game.ftue.step="done";host.game.level=50;host.game.coins=1000000
 for id in R.ORDER:
  if not R.DATA[id].has("cost"):continue
  var at=host.farm.object_position("region_"+id)
  assert(load("res://scripts/island_layout.gd").purchase_spot(host,"region_"+id)!=Vector2.INF,"Large lot obstructed: "+id)
  host.on_world_region_action(id)
  assert(R.purchased(host.game,id) and host.farm.object_position("region_"+id)==at)
 print("VISIBLE DISTRICTS PASS: all locked large previews, full-art hits, terrain clearance, blocked navigation, no free ownership, 17 purchases retain position")
 host.queue_free();await process_frame;quit()
