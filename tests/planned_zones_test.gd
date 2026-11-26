extends SceneTree
const L=preload("res://scripts/island_layout.gd")
const R=preload("res://scripts/world_regions.gd")
const T=preload("res://scripts/reference_terrain.gd")
func _initialize():call_deferred("run")
func shot(name):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+name+".png"))
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://planned_zones_test.json";host.game.backup_path="user://planned_zones_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 assert(L.state(host.game).get("zoning_version",0)==L.VERSION,"Zone plan must complete")
 host.game.ftue.step="done";host.game.level=50;host.game.coins=1000000
 host.farm.hybrid_controller.set_process(false)
 var before=host.game.layout_positions.duplicate(true)
 for id in ["pelabuhan","arena","tambang","stasiun","festival","rumah_kaca","penggilingan","permukiman","kafe","berkuda","sekolah","botani","resor_danau","kota_wisata","camping","pemancingan","taman_bermain"]:
  var key="region_"+id
  var at=host.farm.object_position(key)
  assert(at.distance_to(L.preferred(key))<=801,"Lot left its district: "+id)
  assert(T.asset_clear(at) and T.bounds_clear(L.bounds(host.farm,key,at)),"Lot must be entirely on land: "+id)
  assert(L.purchase_spot(host,key)!=Vector2.INF,"Reserved lot should be ready for purchase: "+id)
  host.on_world_region_action(id)
  assert(R.purchased(host.game,id),"Real purchase failed: "+id)
  assert(host.farm.object_position(key)==at,"Purchase must retain its reserved anchor")
 for i in host.farm.WILD_TREES.size():
  if i in host.game.cleared_wild_trees:continue
  assert(T.bounds_clear(T.tree_bounds(host.farm.wild_tree_position(i),i)),"Tree canopy must remain on land")
 for species in ["ayam","sapi"]:assert(L.purchase_spot(host,species)!=Vector2.INF,"Pen lot must be reserved: "+species)
 assert(preload("res://scripts/first_coop.gd").build(host.game))
 preload("res://scripts/animal_store.gd").purchase(host,"sapi",true)
 assert(host.game.ftue.cow_built)
 host.on_buy_construction("kandang_babi")
 host.on_buy_construction("kandang_kambing")
 host.on_buy_construction("pabrik_pakan")
 for species in ["babi","kambing"]:
  assert(host.game.has_construction("kandang_"+species))
  assert(host.farm.object_position(species)==Vector2(before[species][0],before[species][1]))
 assert(not L.ensure(host),"Migration must run only once per island")
 host.switch_tab("kebun");host.toast_layer.hide()
 host.farm.camera_center=Vector2(2160,4100);host.farm.camera_target=host.farm.camera_center
 host.farm.camera_zoom=0.145;host.farm.zoom_target=0.145;host.farm.hybrid_controller.data.follow=false;host.farm.queue_redraw()
 for i in 10:await process_frame
 await shot("susunan-kawasan-semua-bangunan")
 host.farm.reset_camera()
 for i in 12:await process_frame
 await shot("susunan-kawasan-awal")
 # A full-map render without HUD makes the whole spatial arrangement reviewable.
 for node in host.get_children():
  if node is CanvasItem and node!=host.farm and node.name!="HDWorldTerrain":node.hide()
 host.farm.camera_center=Vector2(2160,3840);host.farm.camera_target=host.farm.camera_center
 host.farm.camera_zoom=0.15;host.farm.zoom_target=0.15;host.farm.queue_redraw()
 for i in 10:await process_frame
 await shot("susunan-pulau-tanpa-menu")
 host.game.save_game()
 var positions=host.game.layout_positions.duplicate(true)
 var game=FarmGameState.new();game.save_path=host.game.save_path;game.backup_path=host.game.backup_path;assert(game.load_game())
 assert(game.layout_positions==positions,"Lots and purchased placements must survive reload")
 print("PLANNED ZONES PASS: all 17 district purchases in shuffled order, pens/workshops, dry bounds, one-time migration, saved anchors")
 host.queue_free();await process_frame;quit()
