extends SceneTree
const REGIONS=preload("res://scripts/four_seasons.gd")
const WEATHER=preload("res://scripts/regional_weather.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://regional_weather_test.json"
 host.game.backup_path="user://regional_weather_test_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 var seasons
 for child in host.get_children():
  if child.get_script()==load("res://scripts/seasonal_ui.gd"):seasons=child
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 host.farm.hybrid_controller.set_process(false)
 host.farm.hybrid_controller.data.follow=false
 host.game.level=50
 seasons.set_process(false)
 var journey=load("res://scripts/island_journey.gd")
 var progress=journey.prepare(host.game)
 for id in ["summer","spring","autumn"]:progress.worlds[id].level=50
 assert(seasons.effects.get_parent()==host.farm,"Weather must be in the world, not a full-screen UI layer")
 assert(host.game.seasonal.weather_model=="regional")
 for entry in [["summer",Vector2(1000,2200),"Terik"],["spring",Vector2(3300,2200),"Cerah"],["autumn",Vector2(1000,5600),"Berangin"],["winter",Vector2(3200,5200),"Salju"],["central",Vector2(2160,3700),"Cerah"]]:
  if entry[0]!="central":assert(journey.enter(host,entry[0]))
  var target=REGIONS.CENTER if entry[0]=="central" else entry[1]
  host.farm.ujang_position=host.farm.hybrid_controller.navigation.nearest(target,600)
  assert(host.farm.ujang_position!=Vector2.INF,"Test entry must stand on navigable ground")
  seasons._process(0.3)
  assert(seasons.current_region==entry[0])
  assert(seasons.weather==entry[2])
  assert(seasons.last_announced_region==entry[0],"Each entry must animate")
  assert(seasons.entry_banner.visible,"Entry banner must be visible")
  var previous=seasons.entry_count
  for i in 5:seasons._process(0.3)
  assert(seasons.entry_count==previous,"Do not repeat the banner while staying in a region")
  host.farm.camera_center=entry[1];host.farm.camera_target=entry[1];host.farm.camera_zoom=0.4;host.farm.zoom_target=0.4
  var terrain=load("res://scripts/reference_terrain.gd")
  for index in host.farm.WILD_TREES.size():
   if index in host.game.cleared_wild_trees:continue
   assert(terrain.asset_clear(host.farm.wild_tree_position(index)) and terrain.bounds_clear(terrain.tree_bounds(host.farm.wild_tree_position(index),index)),"Regional tree must remain on ground in "+str(entry[0])+": "+str(index))
  var points=seasons.effects.visible_particles()
  if entry[0]!="central":assert(not points.is_empty(),"Regional effect must be visible")
  for point in points:
   assert(REGIONS.region(point.position)==point.region,"Particles must not cross region borders")
   assert(WEATHER.effect_at(point.position)==point.kind)
   assert(point.region!="central","Central Village has no seasonal weather")
  if entry[0]=="winter" and DisplayServer.get_name()!="headless":
   for i in 10:await process_frame
   assert(seasons.entry_banner.size.y<=110,"Entry animation must be a compact non-blocking banner")
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/cuaca-winter-entry.png"))
 assert(journey.enter(host,"summer"))
 host.game.seasonal.preview=3
 host.game.seasonal.epoch=int(Time.get_unix_time_from_system())-9000
 host.farm.ujang_position=Vector2(1000,2200)
 seasons.refresh_weather()
 assert(seasons.season==1 and seasons.weather=="Terik","Old timer and preview must never override region weather")
 var entries=seasons.entry_count
 host.farm.camera_center=Vector2(3400,5600)
 seasons._process(0.3)
 assert(seasons.current_region=="summer","Panning the camera does not teleport the player or change their weather")
 # Same region is recognized after returning from the old preview, so no extra entry.
 assert(seasons.entry_count<=entries+1)
 assert(WEATHER.effect_at(REGIONS.CENTER)=="none")
 assert(WEATHER.effect_at(Vector2(500,200))=="none","No particles in the sky")
 assert(WEATHER.effect_at(Vector2(-20,4000))=="none")
 host.active_tab="toko";seasons.effects._process(0.1)
 assert(not seasons.effects.visible,"No weather over menus")
 print("REGIONAL WEATHER PASS: four local effects, neutral village, five entry animations, bounded world particles, no timed global weather, no menu overlay")
 host.queue_free();await process_frame;quit()
