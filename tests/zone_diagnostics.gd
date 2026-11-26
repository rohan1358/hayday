extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://visible_districts.json";host.game.backup_path="user://visible_districts_backup.json";root.add_child(host)
 host.game.ftue.step="done";host.game.level=50
 for c in host.get_children():
  if c.get_script()==load("res://scripts/first_farm_ui.gd"):c.start_adventure()
  if c.get_script()==load("res://scripts/farm_progression.gd"):c.set_process(false)
 var f=host.farm;var p=load("res://scripts/asset_projection.gd");var t=load("res://scripts/reference_terrain.gd");var w=load("res://scripts/four_seasons.gd")
 for id in ["rumah_kaca","pemancingan","pelabuhan","berkuda","stasiun"]:
  var key="region_"+id;var at=f.object_position(key);var b=p.info(f,key,at).bounds;var half=f.object_half_size(key)
  print(id," pos=",at," blocked=",w.blocked(host.game,at)," ground=",t.asset_clear(at)," bounds=",t.bounds_clear(b.grow(24))," nature=",p.nature_clear(f,b)," sites=",p.region_sites_clear(f,b,key)," visual=",load("res://scripts/world_regions_painter.gd").visual_clear(f,id,at)," accessible=",f.accessible_world()," half=",half," can=",f.can_place(key,at))
  for index in 17:
   var k="starter_%d"%index;var art=p.info(f,k,f.object_position(k))
   if not art.is_empty() and b.grow(8).intersects(art.bounds):print("STARTER ",k," pos ",f.object_position(k))
  for i in f.WILD_TREES.size():
   if i not in host.game.cleared_wild_trees and b.grow(12).intersects(p.wild_tree_bounds(f,i)):print("TREE ",i," at ",f.wild_tree_position(i))
  for id2 in load("res://scripts/world_regions.gd").ORDER:
   var data=load("res://scripts/world_regions.gd").DATA[id2]
   if id2!=id and data.has("art") and load("res://scripts/world_regions.gd").purchased(host.game,id2):
    var other_art=f.farm_art.ground_bounds(data.art,f.object_position("region_"+id2),data.width)
    if b.intersects(other_art):print("REGION ART OVERLAP ",id2)
  for other in f.editable_keys():
   if other==key:continue
   var a=f.object_position(other);var h=f.object_half_size(other)
   if Rect2(at-half,half*2).intersects(Rect2(a-h,h*2)):print("OVERLAP ",other)
 host.queue_free();await process_frame;quit()
