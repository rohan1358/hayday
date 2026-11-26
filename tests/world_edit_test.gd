extends SceneTree
const EDIT=preload("res://scripts/asset_edit.gd")
const P=preload("res://scripts/asset_projection.gd")
func _initialize():call_deferred("run")
func click(control,local=Vector2.INF):
 var point=control.get_global_transform_with_canvas()*(control.size*.5 if local==Vector2.INF else local)
 var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func screen(farm,world):return (farm.get_virtual_size()*.5+(world-farm.camera_center)*farm.camera_zoom)*farm.size/farm.get_virtual_size()
func settle():
 for i in 10:await process_frame
func shot(name):
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+name+".png"))
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://world_edit_test.json";host.game.backup_path="user://world_edit_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path));root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 var f=host.farm;host.farm.hybrid_controller.set_process(false)
 assert(host.game.level==1 and host.game.feature_unlocked("decorations"),"World arrangement must be available from the first play")
 host.toggle_arrange_mode();await settle()
 for key in ["region_sekolah","ayam","sapi","roti","resource_0","bridge_0"]:assert(key in f.editable_keys(),"Unowned and environmental props must be editable: "+key)
 var wild_key=""
 for editable in f.editable_keys():
  if editable.begins_with("wild_"):wild_key=editable;break
 assert(wild_key!="","The populated forest must provide editable trees")
 f.frame_asset("dapur",true);await settle()
 var art=P.info(f,"dapur",f.object_position("dapur"))
 await click(f,screen(f,art.bounds.get_center()));await settle()
 assert(f.edit_selected=="dapur","Real pointer must keep the selected building after release")
 var rot=host.find_child("RotateWorldAsset",true,false);await click(rot);await settle()
 assert(EDIT.flipped(host.game,"dapur"),"The actual rotate button must flip the selected building")
 await shot("editor-putar-rumah")
 # Move a closed district without buying it or changing its level gate.
 var key="region_camping";var old=f.object_position(key);var target=Vector2.INF
 for radius in [40,80,120,160,240,320,480]:
  for i in 24:
   var point=old+Vector2.from_angle(i*TAU/24)*radius
   if f.can_place(key,point):
    EDIT.state(host.game)[key]=true
    var mirrored=P.info(f,key,point)
    var fits=P.nature_clear(f,mirrored.bounds)
    EDIT.state(host.game).erase(key)
    if fits:target=point;break
  if target!=Vector2.INF:break
 assert(target!=Vector2.INF,"A closed facility should have a valid nearby move destination")
 host.on_object_moved(key,target)
 assert(f.object_position(key)==target and not preload("res://scripts/world_regions.gd").purchased(host.game,"camping"))
 f.edit_selected=key;assert(EDIT.rotate(host,key))
 # Environmental assets use the same editor and retain their saved positions.
 var moved_nature={}
 for nature_key in [wild_key,"resource_0"]:
  var source=f.object_position(nature_key);var destination=Vector2.INF
  for radius in [5,10,20,40,80,120,180,260,360,500,720,1000,1400,1800,2400]:
   for step in 24:
    var candidate=source+Vector2.from_angle(step*TAU/24)*radius
    if f.can_place(nature_key,candidate):destination=candidate;break
   if destination!=Vector2.INF:break
  assert(destination!=Vector2.INF,"Environmental asset must have a legal move destination: "+nature_key)
  host.on_object_moved(nature_key,destination);moved_nature[nature_key]=destination
  assert(f.object_position(nature_key)==destination)
 preload("res://scripts/safe_asset_placement.gd").repair_nature(host)
 for nature_key in moved_nature:assert(f.object_position(nature_key)==moved_nature[nature_key],"Nature repair must retain manually placed assets")
 # The new native mill is large and has a transparent background.
 var mill=f.farm_art.sprites.region_mill.texture
 assert(mill.resource_path.ends_with("landmark_hd/flour_mill.png") and mill.get_width()>=1024)
 assert(mill.get_image().get_pixel(0,0).a<.1)
 f.frame_asset("region_penggilingan",true);await settle();await shot("penggilingan-baru-hd")
 f.frame_asset("region_stasiun",true);await settle();await shot("stasiun-rel-utuh")
 var terrain=preload("res://scripts/reference_terrain.gd");var backdrop=host.find_child("HDWorldTerrain",true,false)
 backdrop.sync_camera()
 for i in terrain.bridge_paths().size():
  var bridge=backdrop.get_node("RiverBridge%d"%i);var path=terrain.bridge_paths()[i]
  assert(bridge.texture.resource_path.ends_with("landmark_hd/wood_bridge.png"))
  var a=bridge.get_global_transform()*Vector2(bridge.get_meta("deck_left"));var b=bridge.get_global_transform()*Vector2(bridge.get_meta("deck_right"))
  var expected_a=backdrop.get_global_transform()*(path[0]/terrain.SOURCE*backdrop.texture.get_size())
  var expected_b=backdrop.get_global_transform()*(path[1]/terrain.SOURCE*backdrop.texture.get_size())
  assert(a.distance_to(expected_a)<.1 and b.distance_to(expected_b)<.1,"Bridge deck ends must meet their riverbank anchors")
  assert(bridge.texture.get_image().get_pixel(0,0).a<.1)
 var path=terrain.bridge_paths()[0];f.camera_center=(path[0]+path[1])*.5/terrain.SOURCE*terrain.SIZE;f.camera_target=f.camera_center;f.camera_zoom=.8;f.zoom_target=.8;f.queue_redraw();await settle();await shot("jembatan-sesuai-jalur")
 host.game.save_game();var restored=FarmGameState.new(false);restored.save_path=host.game.save_path;restored.backup_path=host.game.backup_path;assert(restored.load_game())
 assert(EDIT.flipped(restored,"dapur") and EDIT.flipped(restored,key))
 assert(Vector2(restored.layout_positions[key][0],restored.layout_positions[key][1])==target)
 print("WORLD EDIT PASS: actual first-level selection and rotate button, closed-building moves, saved facings, native transparent mill, continuous rail scene, bank-aligned bridge endpoints")
 host.queue_free();await process_frame;quit()

