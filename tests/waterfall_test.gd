extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://waterfall_test.json"
 host.game.backup_path="user://waterfall_test_backup.json"
 root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"): child.opening.hide()
  if child.get_script()==load("res://scripts/farm_progression.gd"):
   child.set_process(false);child.pending.clear()
   if child.dialog!=null: child.dialog.hide()
 host.set_meta("first_farm_modal",false)
 var river=host.farm.get_node("ReferenceRiverFlow")
 host.farm.camera_center=Vector2(2160,3840)
 river._process(0.0)
 assert(river.visible)
 var before=river.position
 var scale_before=river.scale
 host.farm.camera_center+=Vector2(60,40)
 host.farm.camera_zoom=1.5
 river._process(0.0)
 assert(river.position!=before and river.scale!=scale_before,"Waterfall must share ground camera transform")
 assert(not host.farm.can_place("dapur",Vector2(500,450)/Vector2(1052,1495)*Vector2(4320,7680)))
 host.farm.camera_target=host.farm.camera_center
 host.farm.zoom_target=host.farm.camera_zoom
 host.toast_layer.hide()
 if DisplayServer.get_name()!="headless":
  for i in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/air-terjun-ujung-lahan.png"))
 print("WATERFALL PASS: world position follows ground across camera pan/zoom, reserved river land")
 host.queue_free();await process_frame;quit()
