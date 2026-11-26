extends RefCounted
const T=preload("res://scripts/reference_terrain.gd")
const CORE=["pasar","gudang","delivery_depot","delivery_truck"]
static var banks: Dictionary={}
static var roads: Dictionary={}
static func bank(y: float) -> float:
 var row=roundi(y/16)*16
 if banks.has(row):return banks[row]
 var line=preload("res://scripts/waterfront.gd").river(float(row))
 banks[row]=float(line[0]) if float(line[0])>0 else 4070.0
 return banks[row]
static func road(y: float) -> float:
 var row=roundi(y/16)*16
 if roads.has(row):return roads[row]
 var hits=[]
 for x in range(800,2400,8):
  if T.main_road(Vector2(x,row)):hits.append(float(x))
 roads[row]=hits[int(hits.size()/2)] if not hits.is_empty() else 1400.0
 return roads[row]
static func allowed(farm,key: String,at: Vector2) -> bool:
 if key.begins_with("wild_") or key.begins_with("buah_") or key.begins_with("bridge_") or key=="starter_14":return true
 if key.begins_with("dekor_"):
  var kind=str(farm.game.decoration_by_key(key).get("kind",""))
  for token in ["tree","pohon","pine","oak","maple"]:
   if token in kind:return true
 var right=at.x+farm.object_half_size(key).x
 var art=preload("res://scripts/asset_projection.gd").info(farm,key,at)
 if not art.is_empty() and key not in ["region_pemancingan","region_pelabuhan","region_stasiun"]:right=maxf(right,float(art.bounds.end.x))
 return right<bank(at.y)-45
static func preferred(key: String) -> Vector2:
 match key:
  "pasar":return Vector2(1650,4100)
  "gudang":return Vector2(2150,4350)
  "delivery_depot":return Vector2(1900,3500)
  "delivery_truck":return Vector2(road(4350)+185,4350)
 return Vector2.INF
static func near_core(key: String,at: Vector2) -> bool:
 if key not in CORE:return true
 if at.distance_to(preferred(key))>(450 if key=="delivery_truck" else 800):return false
 return absf(at.x-road(at.y))<300 if key=="delivery_truck" else true
