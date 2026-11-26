extends RefCounted
const T=preload("res://scripts/reference_terrain.gd")
static func river(y: float) -> Array:
 var first=-1.0;var last=-1.0
 for x in range(2350,4070,10):
  if T.water(Vector2(x,y),false):
   if first<0:first=float(x)
   last=float(x)
  elif first>=0 and float(x)-last>70:break
 return [first,last]
static func preferred(key: String) -> Vector2:
 if key=="region_pemancingan":
  var line=river(6650)
  return Vector2(float(line[0])-210,6650)
 return Vector2(2770,7040)
static func water_space(point: Vector2,width: float) -> bool:
 for dx in [-.38,0,.38]:
  for dy in [-.12,0,.12]:
   if not T.water(point+Vector2(dx,dy)*width,false):return false
 return true
static func boat_at(point: Vector2,width: float) -> Vector2:
 for dy in range(380,1001,30):
  for dx in [0,90,-90,180,-180,270,-270]:
   var candidate=point+Vector2(dx,dy)
   if candidate.y<7650 and water_space(candidate,width):return candidate
 return point+Vector2(0,600)
static var cache: Dictionary={}
static func parts(asset: String,point: Vector2,extent: float) -> Array:
 var key=str([asset,point,extent])
 if cache.has(key):return cache[key]
 if asset=="region_fishing":
  var line=river(point.y+70);var dock=Vector2((float(line[0])+float(line[1]))*.5,point.y+70)
  cache[key]=[["scene_fishing_hut",Vector2(-.12,-.10),.53],["scene_dock",(dock-point)/extent,.58]]
  return cache[key]
 var boat=boat_at(point,extent*.56)
 cache[key]=[["region_harbor",Vector2(-.10,-.12),.48],["scene_crane",Vector2(.25,.02),.24],["scene_dock",Vector2(0,.22),.52],["ref_kapal_dagang",(boat-point)/extent,.56]]
 return cache[key]
static func supported(key: String,point: Vector2) -> bool:
 if not T.scene_supported(point,Vector2(125,65)):return false
 if key=="region_pemancingan":
  var line=river(point.y+70)
  return float(line[0])>0 and absf(point.x-(float(line[0])-210))<70
 return water_space(boat_at(point,616),616)
