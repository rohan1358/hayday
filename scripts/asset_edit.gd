extends RefCounted
static func state(game) -> Dictionary:
 var journey=game.world_regions.get("island_journey",{})
 var id=str(journey.get("active","summer"))
 if not journey.get("worlds",{}).has(id):return {}
 var world: Dictionary=journey.worlds[id]
 if not world.has("facings"):world.facings={}
 return world.facings
static func flipped(game,key: String) -> bool:return bool(state(game).get(key,false))
static func position(game,key: String) -> Vector2:
 if key.begins_with("wild_"):
  var p=game.building_upgrades.get("tree_positions",{}).get(key.trim_prefix("wild_"),[])
  return Vector2(p[0],p[1]) if p.size()==2 else Vector2.INF
 if key.begins_with("resource_"):
  var i=int(key.trim_prefix("resource_"));var nodes=game.building_upgrades.get("nodes",[])
  if i<nodes.size():return Vector2(nodes[i].position[0],nodes[i].position[1])
 if key.begins_with("dekor_"):
  var p=game.decoration_by_key(key).get("position",[])
  return Vector2(p[0],p[1]) if p.size()==2 else Vector2.INF
 var p=game.layout_positions.get(key,[])
 return Vector2(p[0],p[1]) if p.size()==2 else Vector2.INF
static func facing_at(game,point: Vector2) -> bool:
 if game==null:return false
 var values=state(game)
 if values.is_empty():return false
 var preview: Dictionary=game.get_meta("asset_preview",{})
 if not preview.is_empty() and point.distance_squared_to(preview.point)<4:return bool(values.get(preview.key,false))
 for key in values:
  if bool(values[key]) and point.distance_squared_to(position(game,key))<4:return true
 return false
static func extra_keys(farm) -> Array[String]:
 var out: Array[String]=[]
 for id in preload("res://scripts/world_regions.gd").ORDER:
  if preload("res://scripts/world_regions.gd").DATA[id].has("cost"):out.append("region_"+id)
 out.append_array(["ayam","sapi","babi","kambing","roti","susu","pakan","pasar","delivery_depot","delivery_truck"])
 for i in farm.WILD_TREES.size():
  if farm.wild_tree_active(i):out.append("wild_%d"%i)
 for i in farm.game.building_upgrades.get("nodes",[]).size():out.append("resource_%d"%i)
 for i in preload("res://scripts/reference_terrain.gd").bridge_paths().size():out.append("bridge_%d"%i)
 return out
static func special(key: String) -> bool:return key.begins_with("wild_") or key.begins_with("resource_") or key.begins_with("bridge_")
static func info(farm,key: String,point: Vector2) -> Dictionary:
 if key.begins_with("bridge_"):
  var terrain=preload("res://scripts/reference_terrain.gd");terrain.bridge_paths()
  var line=terrain.BRIDGES[int(key.trim_prefix("bridge_"))]
  var extent=(line[1]-line[0])/terrain.SOURCE*terrain.SIZE
  return {"asset":"","width":extent.length(),"ground":point,"bounds":Rect2(point-Vector2(absf(extent.x)*.6,110),Vector2(absf(extent.x)*1.2,220))}
 if key.begins_with("wild_"):
  var index=int(key.trim_prefix("wild_"));var bounds=preload("res://scripts/reference_terrain.gd").tree_bounds(point,index)
  if flipped(farm.game,key):bounds.position.x=2*point.x-bounds.end.x
  return {"asset":"","width":bounds.size.x,"ground":point,"bounds":bounds}
 if key.begins_with("resource_"):
  return {"asset":"resource_boulder","width":130.0,"ground":point,"bounds":farm.farm_art.ground_bounds("resource_boulder",point,130)}
 return {}
static func valid(farm,key: String,point: Vector2) -> bool:
 if key.begins_with("bridge_"):
  var terrain=preload("res://scripts/reference_terrain.gd");terrain.bridge_paths()
  var line=terrain.BRIDGES[int(key.trim_prefix("bridge_"))]
  var base=(line[0]+line[1])*.5/terrain.SOURCE*terrain.SIZE
  var shift=point-base
  var a=line[0]/terrain.SOURCE*terrain.SIZE+shift;var b=line[1]/terrain.SOURCE*terrain.SIZE+shift
  return terrain.water(point,false) and terrain.dry_ground(a) and terrain.dry_ground(b)
 if key.begins_with("resource_"):return preload("res://scripts/building_upgrades.gd").boulder_clear(farm,point,int(key.trim_prefix("resource_")))
 if not preload("res://scripts/reference_terrain.gd").asset_clear(point):return false
 var bounds=info(farm,key,point).bounds
 var projection=preload("res://scripts/asset_projection.gd")
 if not preload("res://scripts/reference_terrain.gd").bounds_clear(bounds) or not projection.region_sites_clear(farm,bounds.grow(40),key):return false
 for i in farm.WILD_TREES.size():
  if "wild_%d"%i!=key and farm.wild_tree_active(i) and point.distance_to(farm.wild_tree_position(i))<100:return false
 for i in farm.game.plots.size():
  if bounds.intersects(Rect2(farm.plot_center(i)-Vector2(100,100),Vector2(200,165))):return false
 for node in farm.game.building_upgrades.get("nodes",[]):
  var rock=Vector2(node.position[0],node.position[1])
  if bounds.grow(70).intersects(farm.farm_art.ground_bounds("resource_boulder",rock,130)):return false
 for other in farm.editable_keys():
  if other==key or special(other):continue
  var art=projection.info(farm,other,farm.object_position(other))
  if not art.is_empty() and bounds.grow(60).intersects(art.bounds):return false
 return true
static func commit(host,key: String,point: Vector2) -> void:
 if key.begins_with("wild_"):
  host.game.building_upgrades.tree_positions[key.trim_prefix("wild_")]=[point.x,point.y]
  if not host.game.building_upgrades.has("manual_trees"):host.game.building_upgrades.manual_trees={}
  host.game.building_upgrades.manual_trees[key.trim_prefix("wild_")]=true
 elif key.begins_with("resource_"):host.game.building_upgrades.nodes[int(key.trim_prefix("resource_"))].position=[point.x,point.y]
 host.game.layout_positions[key]=[point.x,point.y]
 host.farm.invalidate_scenery()
 if host.farm.hybrid_controller!=null:host.farm.hybrid_controller.navigation.revision=""
 host.game.save_game()
static func rotate(host,key: String) -> bool:
 if key=="" or key.begins_with("road_"):return false
 var values=state(host.game);var old=bool(values.get(key,false));values[key]=not old
 var at=host.farm.object_position(key)
 var art=preload("res://scripts/asset_projection.gd").info(host.farm,key,at)
 if not special(key) and not art.is_empty() and not preload("res://scripts/asset_projection.gd").nature_clear(host.farm,art.bounds):
  values[key]=old;host.show_toast("Arah ini terhalang pohon atau batu. Geser aset dahulu.");return false
 if not bool(values[key]):values.erase(key)
 host.game.save_game();host.farm.invalidate_scenery();host.farm.queue_redraw()
 host.show_toast("Arah hadap diubah dan disimpan.")
 return true
