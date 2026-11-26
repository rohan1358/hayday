extends SceneTree
const T=preload("res://scripts/reference_terrain.gd")
const W=preload("res://scripts/four_seasons.gd")
func _initialize(): call_deferred("run")
func run():
 var g=FarmGameState.new(false)
 g.save_path="user://reference_terrain_migration.json";g.backup_path="user://reference_terrain_migration_backup.json"
 g.layout_positions.dapur=[980,600];g.hybrid.player=[1170,760];g.coins=567;g.inventory.gandum=19
 g.road_tiles={"30,52":"stone"}
 assert(T.migrate(g))
 assert(g.layout_positions.dapur[1]==2052)
 assert(g.road_tiles.has("63,85"))
 assert(g.coins==567 and g.inventory.gandum==19)
 assert(not T.migrate(g))
 assert(T.water(Vector2(500,450)/T.SOURCE*T.SIZE))
 assert(T.water(Vector2(680,1165)/T.SOURCE*T.SIZE))
 assert(not T.water(Vector2(405,698)/T.SOURCE*T.SIZE))
 assert(T.solid(Vector2(1100,500)))
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://reference_terrain_visual.json";host.game.backup_path="user://reference_terrain_visual_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd") and child.opening!=null: child.opening.hide()
  if child.get_script()==load("res://scripts/farm_progression.gd"):
   child.set_process(false);child.pending.clear()
   if child.dialog!=null: child.dialog.hide()
 host.set_meta("first_farm_modal",false)
 host.game.ftue.started=true;host.game.ftue.step="done"
 host.farm.hybrid_controller.data.follow=false
 host.toast_layer.hide()
 if DisplayServer.get_name()!="headless":
  for pair in [["overview",W.SIZE*0.5,host.farm.minimum_camera_zoom()],["spring",host.farm.plot_center(0),0.7]]:
   host.farm.camera_zoom=pair[2];host.farm.zoom_target=pair[2]
   host.farm.camera_center=host.farm.clamp_camera_center(pair[1],pair[2]);host.farm.camera_target=host.farm.camera_center
   host.farm.queue_redraw()
   for i in 8: await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/reference-terrain-"+pair[0]+".png"))
 print("REFERENCE TERRAIN PASS: reference background, winding water and bridge masks, safe migration, preserved economy")
 host.queue_free();await process_frame;quit()
