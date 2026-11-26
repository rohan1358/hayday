extends SceneTree
const T=preload("res://scripts/reference_terrain.gd")
func _initialize():call_deferred("run")
func shot(host,key,name,zoom=.6):
 var f=host.farm;f.camera_target=f.object_position(key)-Vector2(0,140);f.camera_center=f.camera_target;f.camera_zoom=zoom;f.zoom_target=zoom;f.queue_redraw()
 for i in 10:await process_frame
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+name+".png"))
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://visible_districts.json";host.game.backup_path="user://visible_districts_backup.json";root.add_child(host)
 host.game.ftue.step="done";host.game.level=50;host.farm.hybrid_controller.set_process(false)
 for c in host.get_children():
  if c.get_script()==load("res://scripts/first_farm_ui.gd"):c.start_adventure()
  if c.get_script()==load("res://scripts/farm_progression.gd"):c.set_process(false)
 var f=host.farm
 for id in ["pemancingan","pelabuhan"]:
  var at=f.object_position("region_"+id)
  assert(preload("res://scripts/waterfront.gd").supported("region_"+id,at))
 var ship=preload("res://scripts/waterfront.gd").boat_at(f.object_position("region_pelabuhan"),616)
 assert(preload("res://scripts/waterfront.gd").water_space(ship,616),"The ship must have water below its hull")
 for i in 3:
  assert(f.plot_center(i).distance_to(f.object_position("dapur"))<850,"Initial fields must stay near the home")
  for j in 3:assert(f.plot_center(i).distance_to(f.plot_center(j))<400,"Initial fields must form one compact group")
 var front_y=f.object_position("starter_8").y
 for i in range(8,13):
  assert(absf(f.object_position("starter_%d"%i).y-front_y)<1,"Front fences must remain aligned")
  assert(T.bounds_clear(f.farm_art.ground_bounds("fence_straight",f.object_position("starter_%d"%i),145)),"Front fences need supported grass")
 for i in host.game.plots.size():
  var at=f.plot_center(i)
  var edge=2200.0
  for x in range(800,2200,4):
   var c=T.sample(Vector2(x,at.y+40))
   if c.r>.82 and c.g>.64 and c.b<c.g*.85 and c.r>c.g*1.03:edge=float(x);break
  assert(at.x+80<edge-15,"Field must remain on the home side of the main road")
 var path=preload("res://scripts/delivery_route.gd").terrain_route(f)
 assert(path.size()>3,"Truck must have a real route through the road bridge")
 print("DELIVERY ROUTE ",path)
 var crossings=0
 for i in range(1,path.size()):
  var steps=maxi(1,ceili(path[i-1].distance_to(path[i])/10))
  for j in range(steps+1):
   var point=path[i-1].lerp(path[i],float(j)/steps)
   assert(not T.solid(point),"Truck route leaves land or bridge: "+str(point))
   if T.water(point,false):crossings+=1
 assert(crossings>0,"Delivery must cross the bridge centerline")
 for item in host.game.orders[0].items:host.game.inventory[item]=999
 host.send_delivery(0)
 assert(f.hybrid_controller.data.follow and f.camera_target.distance_to(f.ujang_position)<1,"Delivery camera must return immediately to the character")
 f.delivery_elapsed=-1;host.toast_layer.hide()
 await shot(host,"dapur","kebun-rapat-tanpa-papan",.62)
 await shot(host,"region_berkuda","lapangan-kuda-dan-kuda",.62)
 await shot(host,"region_stasiun","rel-kereta-ke-jembatan",.43)
 await shot(host,"region_pemancingan","pemancingan-tepi-sungai",.63)
 await shot(host,"region_pelabuhan","pelabuhan-kapal-di-air",.55)
 await shot(host,"region_resor_danau","resor-crop-bersih",.8)
 print("WATERFRONT PASS: clean cropped waterfront assets, ship supported by water, compact home fields, truck stays on land and bridge, immediate character camera")
 host.queue_free();await process_frame;quit()
