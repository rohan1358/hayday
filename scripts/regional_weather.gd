extends Node2D
# World-space regional weather. No screen-wide particle overlay or timed season rotation.
const REGIONS=preload("res://scripts/four_seasons.gd")
const TERRAIN=preload("res://scripts/reference_terrain.gd")
const EFFECTS={"spring":"petals","summer":"sunlight","autumn":"leaves","winter":"snow","central":"none"}
var farm: FarmView
var host
var elapsed=0.0
var redraw_clock=0.0
var entry_region=""
var entry_strength=0.0
var last_points: Array[Dictionary]=[]
func enter_region(id: String) -> void:
 entry_region=id
 entry_strength=1.0
static func effect_at(at: Vector2) -> String:
 if not Rect2(Vector2.ZERO,REGIONS.SIZE).has_point(at) or TERRAIN.solid(at):return "none"
 return str(EFFECTS[REGIONS.region(at)])
func _process(delta: float) -> void:
 if farm==null:return
 elapsed+=delta
 entry_strength=maxf(0,entry_strength-delta*0.65)
 visible=host.active_tab=="kebun" and not farm.edit_mode
 var scaler=farm.size/farm.get_virtual_size()
 position=(farm.get_virtual_size()*0.5-farm.camera_center*farm.camera_zoom)*scaler
 scale=scaler*farm.camera_zoom
 redraw_clock+=delta
 if redraw_clock>=0.033:
  redraw_clock=0
  queue_redraw()
func visible_particles() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if farm==null:return result
 var area=farm.visible_world_rect(80).intersection(Rect2(Vector2(100,1250),REGIONS.SIZE-Vector2(200,1550)))
 if not area.has_area():return result
 var grid=230.0
 for row in range(floori(area.position.y/grid),ceili(area.end.y/grid)+1):
  for col in range(floori(area.position.x/grid),ceili(area.end.x/grid)+1):
   var seed=abs(col*73856093^row*19349663)
   var origin=Vector2(col*grid+float(seed%193),row*grid+float((seed/193)%181))
   var id=REGIONS.region(origin)
   if id=="central":continue
   var speed=48.0 if id=="winter" else (36.0 if id=="autumn" else 25.0)
   var at=Vector2(origin.x+sin(elapsed*0.65+seed)*34.0,row*grid+fposmod(origin.y-row*grid+elapsed*speed,grid))
   if REGIONS.region(at)!=id or effect_at(at)!=str(EFFECTS[id]):continue
   result.append({"position":at,"region":id,"kind":EFFECTS[id],"seed":seed})
 return result
func _draw() -> void:
 last_points=visible_particles()
 for particle in last_points:
  var at: Vector2=particle.position
  var kind: String=particle.kind
  var seed: int=particle.seed
  var angle=elapsed*0.5+float(seed%60)
  var alpha=0.48+sin(elapsed+seed)*0.12
  if particle.region==entry_region:alpha+=entry_strength*0.18
  draw_set_transform(at,angle,Vector2.ONE)
  if kind=="snow":
   draw_circle(Vector2.ZERO,4.0,Color(0.97,0.99,1,alpha))
   for i in 3:
    var direction=Vector2.from_angle(PI*i/3.0)*8.0
    draw_line(-direction,direction,Color(0.91,0.98,1,alpha),1.8,true)
  elif kind=="petals":
   draw_set_transform(at,angle,Vector2(1,0.65))
   draw_circle(Vector2.ZERO,7.0,Color(1,0.64,0.79,alpha))
   draw_line(Vector2(-3,0),Vector2(4,0),Color(1,0.88,0.92,alpha),1.6,true)
  elif kind=="leaves":
   draw_colored_polygon(PackedVector2Array([Vector2(-10,0),Vector2(-2,-6),Vector2(10,-1),Vector2(3,6)]),Color(0.94,0.43+float(seed%3)*0.09,0.12,alpha))
   draw_line(Vector2(-8,0),Vector2(9,0),Color(1,0.81,0.39,alpha),1.4,true)
  else:
   # Sparse warm motes: no heavy rain or snow in Summer Meadow.
   var pulse=(sin(elapsed*1.5+seed)+1.0)*0.5
   draw_circle(Vector2.ZERO,3.0+pulse*2.0,Color(1,0.93,0.57,alpha*pulse*0.65))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
