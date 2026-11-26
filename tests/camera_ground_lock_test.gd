extends SceneTree
const T=preload("res://scripts/reference_terrain.gd")
const REGIONS=preload("res://scripts/four_seasons.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://camera_ground_lock_test.json";host.game.backup_path="user://camera_ground_lock_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 host.farm.hybrid_controller.data.follow=false
 host.farm.hybrid_controller.set_process(false)
 assert(preload("res://scripts/island_journey.gd").can_enter(host.game,"summer"))
 assert(REGIONS.region(host.farm.object_position("dapur"))=="summer","Main farm must be Summer Meadow")
 for key in ["dapur","gudang","ayam","sapi","babi","kambing","pakan","susu","roti"]:
  assert(REGIONS.region(host.farm.object_position(key))=="summer","Primary building must stay in Summer: "+key)
 # An old misplaced cow marker must migrate back, even if another district is unlocked.
 host.game.layout_positions.sapi=[3300,2200]
 host.game.world_regions.playfield_repair=5
 T.repair_playfield(host)
 var cow=host.farm.object_position("sapi")
 assert(REGIONS.region(cow)=="summer","Saved cow marker drifted into another region")
 assert(cow.distance_to(load("res://scripts/island_layout.gd").preferred("sapi"))<=800,"Cow marker must remain inside the ranch district")
 assert(REGIONS.region(T.safe_anchor(cow,"summer"))=="summer","Cow sign must not search another region")
 var rock_count=0
 for y in range(300,1450,12):
  for x in range(70,1000,10):
   var at=Vector2(x,y)/T.SOURCE*T.SIZE
   var c=T.sample(at)
   if c.s<0.24 and c.v>0.35 and c.v<0.74 and not T.bridge_deck(at):
    assert(T.solid(at),"Rock cliff face must block walking")
    rock_count+=1
 assert(rock_count>10,"Must check actual river cliff pixels")
 assert(not T.solid(host.farm.ujang_position),"Starting player must remain on grass")
 var background=host.farm.get_node("HDWorldTerrain")
 var house=host.farm.object_position("dapur")
 var count=host.farm.world_paint_count
 if DisplayServer.get_name()!="headless":
  # Exercise the actual mobile redraw throttle as well as desktop rendering.
  for mobile in [false,true]:
   host.farm.mobile_scenery_lite=mobile
   for i in 28:
    host.farm.camera_target=Vector2(1200,2252)+Vector2(sin(i*0.20)*260,cos(i*0.20)*190)
    host.farm.zoom_target=0.80+sin(i*0.13)*0.34
    await process_frame
    await RenderingServer.frame_post_draw
    assert(host.farm.last_painted_camera.is_equal_approx(background.transform),"Ground and assets used different camera frames")
    var scaler=host.farm.size/host.farm.get_virtual_size()
    var expected=(host.farm.get_virtual_size()*0.5+(house-host.farm.camera_center)*host.farm.camera_zoom)*scaler
    var actual=background.transform*(house/T.SIZE*background.texture.get_size())
    assert(expected.distance_to(actual)<0.03,"World anchor floats while panning/zooming")
    assert(host.farm.object_position("dapur")==house and host.farm.object_position("sapi")==cow)
  assert(host.farm.world_paint_count-count>=50,"Camera motion must not reuse stale camera draw commands")
  host.farm.camera_target=Vector2(1200,2252);host.farm.camera_center=host.farm.camera_target;host.farm.camera_zoom=0.55;host.farm.zoom_target=0.55;host.farm.queue_redraw()
  for i in 8:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/summer-ground-lock.png"))
 print("GROUND LOCK PASS: 56 pan/zoom frames on desktop and mobile profile, Summer start, migrated cow sign, "+str(rock_count)+" cliff samples blocked")
 host.queue_free();await process_frame;quit()
