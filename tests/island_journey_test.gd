extends SceneTree
const J=preload("res://scripts/island_journey.gd")
const W=preload("res://scripts/four_seasons.gd")
const R=preload("res://scripts/world_regions.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://island_progress_test.json";host.game.backup_path="user://island_progress_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 host.game.ftue.reward_claimed=true;host.game.ftue.step="done"
 host.farm.hybrid_controller.set_process(false)
 host.game.level=49
 assert(J.opened(host.game,"summer")<25 and not J.can_enter(host.game,"spring"))
 host.game.level=50
 assert(J.opened(host.game,"summer")==25 and J.can_enter(host.game,"spring"),"All opened regions, without mandatory purchases or tier 5, must unlock Spring")
 assert(not J.can_enter(host.game,"autumn"))
 R.prepare(host.game).owned.tambang=true;host.game.world_regions.tier.tambang=2
 var summer_house=host.farm.object_position("dapur")
 assert(J.enter(host,"spring"))
 assert(W.active_id=="spring" and J.city_level(host.game)==1)
 assert(J.opened(host.game)==4,"A new island must start its own district progression")
 assert(not R.purchased(host.game,"tambang"),"Spring must not inherit Summer city purchases")
 assert(not J.can_enter(host.game,"autumn"))
 host.game.award_xp(100)
 assert(J.city_level(host.game)==2,"New-city XP must work with an experienced farmer")
 host.game.world_regions.owned.rumah_kaca=true;host.game.world_regions.tier.rumah_kaca=1
 var before=host.game.coins
 host.game.save_game()
 assert(J.enter(host,"summer"))
 assert(R.purchased(host.game,"tambang") and R.tier(host.game,"tambang")==2)
 assert(not R.purchased(host.game,"rumah_kaca"))
 assert(host.farm.object_position("dapur")==summer_house)
 assert(host.game.coins==before)
 assert(J.enter(host,"spring"))
 assert(R.purchased(host.game,"rumah_kaca") and J.city_level(host.game)==2)
 var snapshot=host.game.world_regions.island_journey.duplicate(true)
 host.game.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(host.game.save_path))
 assert(saved.world_regions.island_journey.active=="spring")
 assert(saved.world_regions.island_journey.worlds.summer.owned.tambang)
 assert(saved.world_regions.island_journey.worlds.spring.owned.rumah_kaca)
 assert(J.enter(host,"summer"))
 host.farm.camera_center=Vector2(2160,3840);host.farm.camera_target=host.farm.camera_center
 host.farm.camera_zoom=0.14;host.farm.zoom_target=0.14;host.farm.hybrid_controller.data.follow=false;host.farm.queue_redraw()
 if DisplayServer.get_name()!="headless":
  for i in 10:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/summer-island-overview.png"))
 print("ISLAND JOURNEY PASS: 25-region unlock gate, complete Summer island, independent Spring city/XP/purchases, return travel and saved progress")
 host.queue_free();await process_frame;quit()
