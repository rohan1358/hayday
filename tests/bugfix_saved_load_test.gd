extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://bugfix_interactions.json";host.game.backup_path="user://bugfix_interactions_backup.json"
 var start=Time.get_ticks_msec();root.add_child(host)
 print("SAVED LOAD MS ",Time.get_ticks_msec()-start)
 var signature=str(host.game.building_upgrades.get("nature_signature",""))
 start=Time.get_ticks_msec();preload("res://scripts/safe_asset_placement.gd").repair_nature(host)
 assert(str(host.game.building_upgrades.nature_signature)==signature)
 assert(Time.get_ticks_msec()-start<100,"Unchanged nature must use the validated cache")
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 host.switch_tab("kebun")
 host.farm.zoom_at(host.farm.size*0.5,1.15)
 for i in 16:await process_frame
 assert(host.farm.zoom_target>1.0,"Closer zoom should be available")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/fix-close-zoom.png"))
 print("SAVED LOADING PASS: geometry cache reused and zoom beyond 1x available")
 host.queue_free();await process_frame;quit()

