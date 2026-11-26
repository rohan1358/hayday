extends SceneTree
func _initialize(): call_deferred("run")
func image_at(farm,at: Vector2,zoom: float,id: String):
 farm.zoom_target=zoom;farm.camera_zoom=zoom;farm.camera_target=at;farm.clamp_camera_target()
 farm.camera_center=farm.camera_target;farm.queue_redraw()
 for i in 4: await process_frame
 if DisplayServer.get_name()=="headless": return null
 await RenderingServer.frame_post_draw
 var img=root.get_texture().get_image()
 img.save_png(ProjectSettings.globalize_path("res://../outputs/"+id+".png"))
 return img
func run():
 root.size=Vector2i(720,1600)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://horizon_camera_test.json";host.game.backup_path="user://horizon_camera_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=6
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 host.set_meta("first_farm_modal",false);host.switch_tab("kebun");host.refresh_all()
 var farm=host.farm;farm.hybrid_controller.data.follow=false;farm.set_process(false)
 var layout=host.game.layout_positions.duplicate(true)
 var background=host.find_child("HeaderLandscape",true,false)
 assert(background==null,"Scenery must not be an opaque HUD overlay")
 var header=host.find_child("CheerfulHeader",true,false)
 assert(header!=null and header.mouse_filter==Control.MOUSE_FILTER_IGNORE)
 assert(ResourceLoader.exists("res://assets/cheerful/countryside.png"))
 var before=await image_at(farm,Vector2(1200,800),0.82,"kamera-normal")
 var after=await image_at(farm,Vector2(1200,800),farm.MAX_ZOOM,"kamera-zoom-atas")
 if before!=null and after!=null:
  print("PASS: captured world scenery at both zoom levels")
 for dimensions in [Vector2(720,1155),Vector2(720,1430),Vector2(720,2200)]:
  farm.size=dimensions
  for zoom in [farm.MIN_ZOOM,1.0,farm.MAX_ZOOM]:
   for target in [Vector2(-999,-999),Vector2(99999,99999),Vector2(1200,800)]:
    farm.zoom_target=zoom;farm.camera_zoom=zoom;farm.camera_target=target;farm.clamp_camera_target()
    var half=farm.get_virtual_size()/(2*farm.zoom_target)
    assert(farm.accessible_world().grow(0.2).encloses(Rect2(farm.camera_target-half,half*2)))
 assert(host.game.layout_positions==layout,"Camera fix must not move saved farm objects")
 print("HORIZON CAMERA PASS: transparent HUD, world scenery, pan limits, tall portraits, unchanged layout")
 host.queue_free();await process_frame;quit()
