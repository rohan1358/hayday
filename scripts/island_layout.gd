extends RefCounted
# World-space lots follow the reference island. Every future purchase reserves
# its full illustrated bounds, so buying in a different order never scatters it.
const VERSION=13
const LOTS={
 "dapur":Vector2(650,4350),"gudang":Vector2(2700,3100),
 "ayam":Vector2(650,2800),"sapi":Vector2(1250,2800),"babi":Vector2(650,3220),"kambing":Vector2(1300,3220),
 "roti":Vector2(1900,2750),"susu":Vector2(2350,2750),"pakan":Vector2(1900,3200),
 "delivery_depot":Vector2(2650,3510),"delivery_truck":Vector2(3000,3510),"pasar":Vector2(2250,3880),
 "region_desa":Vector2(650,4350),"region_ladang":Vector2(1100,3650),"region_hutan":Vector2(850,1700),
 "region_peternakan":Vector2(950,2900),"region_produksi":Vector2(2050,2900),"region_logistik":Vector2(2700,3100),
 "region_kebun_buah":Vector2(2050,1900),"region_pasar_desa":Vector2(2250,3880),
 "region_festival":Vector2(2800,1780),"region_rumah_kaca":Vector2(1900,2100),"region_tambang":Vector2(3150,2450),
 "region_permukiman":Vector2(700,2300),"region_penggilingan":Vector2(2800,3900),"region_kafe":Vector2(1700,3950),
 "region_berkuda":Vector2(1850,4550),"region_sekolah":Vector2(2650,4500),"region_kota_wisata":Vector2(3150,4800),
 "region_botani":Vector2(850,4950),"region_stasiun":Vector2(2350,5250),
 "region_taman_bermain":Vector2(850,5550),"region_resor_danau":Vector2(2250,5800),"region_arena":Vector2(2950,6000),
 "region_camping":Vector2(850,6500),"region_pemancingan":Vector2(2000,6950),"region_pelabuhan":Vector2(2750,6900)
}
static func preferred(key: String) -> Vector2:
 if key in preload("res://scripts/mainland_layout.gd").CORE:return preload("res://scripts/mainland_layout.gd").preferred(key)
 if key in ["region_pemancingan","region_pelabuhan"]:return preload("res://scripts/waterfront.gd").preferred(key)
 if key=="region_stasiun":
  var terrain=preload("res://scripts/reference_terrain.gd");var lines=terrain.bridge_paths()
  if lines.size()>1:return lines[1][0]/terrain.SOURCE*terrain.SIZE-Vector2(700,220)
 if LOTS.has(key):return LOTS[key]
 if key.begins_with("resource_"):
  return [Vector2(650,1600),Vector2(3450,2700),Vector2(1450,5400),Vector2(3350,6400),Vector2(700,4000),Vector2(2150,7150)][int(key.trim_prefix("resource_"))%6]
 if key.begins_with("petak_"):
  var i=int(key.trim_prefix("petak_"))
  if i<3:return [Vector2(1060,4320),Vector2(940,4415),Vector2(1180,4415)][i]
  return Vector2(900+(i-3)%3*160,4850+int((i-3)/3)*125)
 if key.begins_with("buah_"):
  var i=int(key.trim_prefix("buah_"))
  return Vector2(1900+i%4*260,1540+int(i/4)*300)
 return Vector2.INF
static func bounds(farm,key: String,point: Vector2) -> Rect2:
 var art=preload("res://scripts/asset_projection.gd").info(farm,key,point)
 if not art.is_empty():return art.bounds.merge(Rect2(point-farm.object_half_size(key),farm.object_half_size(key)*2)).merge(preload("res://scripts/district_signs.gd").rect(point,art.bounds) if key.begins_with("region_") else art.bounds).grow(25)
 return Rect2(point-Vector2(110,70),Vector2(220,140))
static func resolve(farm,key: String,point: Vector2,reserved: Array[Rect2]) -> Vector2:
 var terrain=preload("res://scripts/reference_terrain.gd")
 var base=bounds(farm,key,point)
 var candidates=[]
 for radius in range(0,4201,60):
  for step in (1 if radius==0 else 32):candidates.append(point+Vector2.from_angle(TAU*step/32.0)*radius)
 # A dense final pass finds remaining lots between already reserved districts.
 for y in range(1300,7180,100):
  for x in range(350,3960,100):candidates.append(Vector2(x,y))
 for candidate in candidates:
  if not preload("res://scripts/mainland_layout.gd").near_core(key,candidate) or not preload("res://scripts/mainland_layout.gd").allowed(farm,key,candidate):continue
  var rect=bounds(farm,key,candidate) if key in ["region_stasiun","region_pemancingan","region_pelabuhan"] else Rect2(base.position+candidate-point,base.size)
  if key.begins_with("region_") or key in ["dapur","gudang","roti","susu","pakan","pasar","delivery_depot","delivery_truck","ayam","sapi","babi","kambing"]:
   if key in ["region_pemancingan","region_pelabuhan"]:
    if not preload("res://scripts/waterfront.gd").supported(key,candidate):continue
   elif not terrain.scene_supported(candidate,farm.object_half_size(key)):continue
  elif not terrain.asset_clear(candidate) or not terrain.bounds_clear(rect):continue
  var blocked=false
  for other in reserved:
   if rect.intersects(other):blocked=true;break
  if not blocked:return candidate
 return Vector2.INF
static func state(game) -> Dictionary:
 var journey=preload("res://scripts/island_journey.gd").prepare(game)
 return journey.worlds[journey.active]
static func ensure(host) -> bool:
 var game=host.game
 var data=state(game)
 if int(data.get("zoning_version",0))>=VERSION:return false
 var farm=host.farm
 data.zoning_backup={"positions":game.layout_positions.duplicate(true),"player":game.hybrid.get("player",[]).duplicate(),"decorations":game.decorations.duplicate(true),"nodes":game.building_upgrades.get("nodes",[]).duplicate(true)}
 var reserved: Array[Rect2]=[]
 # Reserve the complete compact field as one group before any future facility.
 var field=[]
 for i in game.plots.size():
  var key="petak_%d"%i;var point=preferred(key)
  game.layout_positions[key]=[point.x,point.y];field.append(bounds(farm,key,point).grow(-20))
 for rect in field:reserved.append(rect)
 var home_at=resolve(farm,"dapur",LOTS.dapur,reserved)
 if home_at==Vector2.INF:return false
 game.layout_positions.dapur=[home_at.x,home_at.y];reserved.append(bounds(farm,"dapur",home_at))
 # The working market, warehouse and courier yard take priority near the farm.
 for core in preload("res://scripts/mainland_layout.gd").CORE:
  var at=resolve(farm,core,preferred(core),reserved)
  if at==Vector2.INF:
   game.layout_positions=data.zoning_backup.positions.duplicate(true);game.decorations.assign(data.zoning_backup.decorations.duplicate(true));game.building_upgrades.nodes=data.zoning_backup.nodes.duplicate(true);push_error("No nearby home-bank lot for "+core);return false
  game.layout_positions[core]=[at.x,at.y];reserved.append(bounds(farm,core,at))
 # Reserve front landscaping before any district can occupy it.
 var scenery_order=[8,9,10,11,12,0,1,2,3,4,5,6,7,13,14,15,16]
 for i in scenery_order:
  var point=home_at+Vector2(-330+(i%4)*220,480+int(i/4)*180)
  if i in range(8,13):point=home_at+Vector2([-300,-145,145,300,455][i-8],180)
  var actual=point if i in range(8,13) else resolve(farm,"starter_%d"%i,point,reserved)
  if actual!=Vector2.INF:
   game.layout_positions["starter_%d"%i]=[actual.x,actual.y];reserved.append(bounds(farm,"starter_%d"%i,actual))
 var keys: Array=[]
 for id in ["pelabuhan","stasiun","pemancingan","festival","tambang","permukiman","rumah_kaca","penggilingan","taman_bermain","kafe","berkuda","sekolah","kota_wisata","botani","resor_danau","arena","camping"]:keys.append("region_"+id)
 keys.append_array(["ayam","sapi","babi","kambing","roti","susu","pakan"])
 for i in game.orchard.size():
  if not str(game.orchard[i].fruit).is_empty() or i<2:keys.append("buah_%d"%i)
 for i in game.building_upgrades.get("nodes",[]).size():keys.append("resource_%d"%i)
 for key in keys:
  var point=resolve(farm,key,preferred(key),reserved)
  if point==Vector2.INF:
   game.layout_positions=data.zoning_backup.positions.duplicate(true);game.decorations.assign(data.zoning_backup.decorations.duplicate(true));game.building_upgrades.nodes=data.zoning_backup.nodes.duplicate(true)
   push_error("No safe lot for "+key)
   return false
  game.layout_positions[key]=[point.x,point.y]
  if key.begins_with("resource_"):game.building_upgrades.nodes[int(key.trim_prefix("resource_"))].position=[point.x,point.y]
  reserved.append(bounds(farm,key,point))
 # Retain every owned decoration, relocating it around the completed lots.
 for item in game.decorations:
  if item.get("position",[]).size()!=2:continue
  var name=str(item.key);var at=resolve(farm,name,farm.object_position(name),reserved)
  if at==Vector2.INF:
   game.layout_positions=data.zoning_backup.positions.duplicate(true);game.decorations.assign(data.zoning_backup.decorations.duplicate(true));game.building_upgrades.nodes=data.zoning_backup.nodes.duplicate(true)
   push_error("No safe home-bank decoration lot for "+name);return false
  item.position=[at.x,at.y];game.layout_positions[name]=[at.x,at.y];reserved.append(bounds(farm,name,at))
 for key in LOTS:
  if not game.layout_positions.has(key) or key in ["region_desa","region_ladang","region_hutan","region_peternakan","region_produksi","region_logistik","region_kebun_buah","region_pasar_desa"]:
   var point=LOTS[key];game.layout_positions[key]=[point.x,point.y]
 for i in mini(24,farm.WILD_TREES.size()):
  var point=Vector2(520+(i%4)*230,1500+int(i/4)*230)
  game.building_upgrades.get_or_add("tree_positions",{})[str(i)]=[point.x,point.y]
 var player=home_at+Vector2(0,100)
 farm.ujang_position=player;game.hybrid.player=[player.x,player.y]
 if int(game.world_regions.get("playfield_repair",0))<9:
  var stock=preload("res://scripts/road_catalog.gd").prepare(game).stock
  for cell in game.road_tiles:
   var style=preload("res://scripts/road_catalog.gd").style(game,str(cell));stock[style]=int(stock.get(style,0))+1
  game.road_tiles.clear()
 game.world_regions.playfield_repair=9
 game.world_regions.home_layout_v2=true;game.world_regions.front_fence_v1=true
 data.zoning_version=VERSION
 farm.invalidate_scenery()
 return true
static func purchase_spot(host,key: String) -> Vector2:
 # Never search around the camera or migrate a new purchase to another district.
 var point=host.farm.object_position(key)
 return point if host.farm.can_place(key,point) else Vector2.INF
