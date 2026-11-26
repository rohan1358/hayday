extends RefCounted
# Composite district art uses the existing native atlas cells. Every part shares
# one world anchor and its projected bounds, including locked previews.
const WIDTHS={"kitchen_cottage":480.0,"village_barn":500.0,"bakery_building":420.0,"dairy_building":420.0,"feed_mill_building":420.0,"market_cart":400.0,"delivery_depot":390.0,"delivery_truck":250.0}
const PARTS={
 "region_fishing":[["scene_fishing_hut",Vector2(-.20,-.10),.45],["scene_dock",Vector2(.20,.12),.60]],
 "region_village":[["kitchen_cottage",Vector2(-.29,-.12),.45],["region_village",Vector2(.26,-.12),.50],["ref_air_mancur",Vector2(0,.16),.24],["ref_kotak_surat",Vector2(-.37,.18),.12]],
 "region_station":[["region_station",Vector2(-.27,-.10),.40],["scene_train",Vector2(.12,.13),.48],["scene_wagon",Vector2(-.29,.065),.29],["ref_sinyal_kereta",Vector2(-.43,.18),.12]],
 "region_harbor":[["region_harbor",Vector2(-.27,-.12),.43],["scene_dock",Vector2(.03,.12),.42],["ref_kapal_dagang",Vector2(.32,.13),.40],["scene_crane",Vector2(-.32,.18),.20]],
 "region_cafe":[["region_cafe",Vector2(-.13,-.05),.74],["ref_meja_kafe",Vector2(.32,.15),.25],["ref_meja_kafe",Vector2(.05,.24),.25]],
 "region_stable":[["region_stable",Vector2(-.34,-.20),.40],["scene_horse_arena",Vector2(.04,.17),.91],["scene_horse",Vector2(-.18,.02),.20],["scene_horse_white",Vector2(.10,.09),.21],["scene_horse_black",Vector2(.31,.015),.20]],
 "region_festival":[["region_festival",Vector2(0,0),.86],["scene_festival_tent",Vector2(-.33,.15),.27],["scene_festival_tent",Vector2(.33,.15),.27]],
 "region_camp":[["region_camp",Vector2(-.24,.08),.49],["ref_tenda",Vector2(.23,-.04),.43],["scene_campfire",Vector2(.08,.20),.23]],
 "region_botanical":[["lg_greenhouse",Vector2(-.25,-.05),.50],["region_botanical",Vector2(.24,.04),.50],["flowering_hedge",Vector2(0,.20),.40]],
 "region_tourism":[["region_village",Vector2(-.28,-.04),.43],["region_cafe",Vector2(.27,-.10),.43],["region_tourism",Vector2(.03,.23),.50]],
 "region_resort":[["region_resort",Vector2(0,.08),.76],["region_village",Vector2(-.40,-.20),.55]],
 "region_school":[["region_school",Vector2(0,0),.89],["ref_kotak_surat",Vector2(.34,.19),.19]],
}
static func parts(_art,asset,point,extent):
 if asset in ["region_harbor","region_fishing"]:return preload("res://scripts/waterfront.gd").parts(asset,point,extent)
 return PARTS[asset]
static func width(asset: String,original: float) -> float:return float(WIDTHS.get(asset,original))
static func paint(art,canvas,asset: String,point: Vector2,extent: float,tint: Color,flip: bool=false) -> void:
 if asset=="region_station":rails(canvas,point,extent,false)
 for part in parts(art,asset,point,extent):art.paint_single(canvas,str(part[0]),point+part[1]*extent*Vector2(-1 if flip and asset not in ["region_harbor","region_fishing"] else 1,1),extent*float(part[2]),tint,true,not flip if part[0]=="scene_train" else flip)
static func bounds(art,asset: String,point: Vector2,extent: float,flip: bool=false) -> Rect2:
 var result=Rect2();var first=true
 for part in parts(art,asset,point,extent):
  var rect=art.single_bounds(str(part[0]),point+part[1]*extent*Vector2(-1 if flip and asset not in ["region_harbor","region_fishing"] else 1,1),extent*float(part[2]),true,not flip if part[0]=="scene_train" else flip)
  result=rect if first else result.merge(rect);first=false
 if asset=="region_station":
  result=result.merge(Rect2(point+Vector2(-.54*extent,-.01*extent),Vector2(1.08*extent,.30*extent)))
  var terrain=preload("res://scripts/reference_terrain.gd");var bridges=terrain.bridge_paths()
  if bridges.size()>1:
   var a=point+Vector2(.53,.205)*extent;var b=bridges[1][1]/terrain.SOURCE*terrain.SIZE
   result=result.merge(Rect2(a.min(b),(a-b).abs()).grow(75))
 return result

static func rails(canvas,point: Vector2,extent: float,flip: bool) -> void:
 var mirror=Vector2(-1 if flip else 1,1)
 var path=[point+Vector2(-.51,.04)*extent*mirror,point+Vector2(.53,.205)*extent*mirror]
 var terrain=preload("res://scripts/reference_terrain.gd");var bridges=terrain.bridge_paths()
 if bridges.size()>1 and not flip:
  path.append(bridges[1][0]/terrain.SOURCE*terrain.SIZE);path.append(bridges[1][1]/terrain.SOURCE*terrain.SIZE)
 for section in range(1,path.size()):
  var start: Vector2=path[section-1];var end: Vector2=path[section]
  var direction=(end-start).normalized();var normal=Vector2(-direction.y,direction.x)
  var sleeper=extent*.033;var gauge=extent*.018
  var count=maxi(2,int(start.distance_to(end)/(extent*.035)))
  for i in range(count+1):
   var at=start.lerp(end,float(i)/count)
   canvas.draw_line(at-normal*sleeper,at+normal*sleeper,Color("6e4224"),extent*.011,true)
  for side in [-1,1]:
   var offset=normal*gauge*side
   canvas.draw_line(start+offset,end+offset,Color("414f59"),extent*.008,true)
   canvas.draw_line(start+offset,end+offset,Color("b7c6cb"),extent*.003,true)
