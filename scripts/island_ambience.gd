extends Node2D
const TERRAIN=preload("res://scripts/reference_terrain.gd")
var farm: FarmView
var elapsed=0.0
var redraw_clock=0.0
var last_butterflies: Array[Vector2]=[]
func _process(delta: float) -> void:
 if farm==null:return
 elapsed+=delta
 var scaler=farm.size/farm.get_virtual_size()
 position=(farm.get_virtual_size()*0.5-farm.camera_center*farm.camera_zoom)*scaler
 scale=scaler*farm.camera_zoom
 redraw_clock+=delta
 if redraw_clock>=0.033:redraw_clock=0;queue_redraw()
static func butterfly(canvas: CanvasItem,at: Vector2,phase: float,angle: float=0.0,scaler: float=1.0) -> void:
 var wing=3.0+10.0*absf(sin(phase*10.0))
 for side in [-1,1]:
  canvas.draw_set_transform(at+Vector2(side*5,-2).rotated(angle)*scaler,angle,Vector2(wing,9)*scaler)
  canvas.draw_circle(Vector2.ZERO,1.0,Color("79c9ff") if side<0 else Color("ffdf78"))
  canvas.draw_circle(Vector2(0.25,-0.2),0.22,Color("fff4d2"))
 canvas.draw_set_transform(at,angle,Vector2.ONE*scaler)
 canvas.draw_line(Vector2(0,-7),Vector2(0,8),Color("64513a"),2.5,true)
 canvas.draw_line(Vector2(0,-5),Vector2(-4,-10),Color("64513a"),1.5,true)
 canvas.draw_line(Vector2(0,-5),Vector2(4,-10),Color("64513a"),1.5,true)
 canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func _draw() -> void:
 if farm==null:return
 last_butterflies.clear()
 var season=preload("res://scripts/four_seasons.gd").active_id
 var visible=farm.visible_world_rect(90)
 if season!="winter":
  for i in (18 if season in ["summer","spring"] else 8):
   var origin=Vector2(700+(i%4)*800,1850+floori(i/4.0)*1050)
   if i<3:origin=farm.plot_center(0)+Vector2(-190+i*130,150+i*50)
   var at=origin+Vector2(sin(elapsed*0.65+i)*75,cos(elapsed*0.85+i)*45)
   if not visible.has_point(at) or not TERRAIN.ground_surface(at):continue
   last_butterflies.append(at)
   butterfly(self,at,elapsed+i,sin(elapsed*0.6+i)*0.35)
 # Mist and falling streaks are grounded in the two waterfall faces.
 for waterfall in [[Vector2(0.85,0.157),Vector2(0.85,0.185)],[Vector2(0.894,0.852),Vector2(0.884,0.878)]]:
  var top: Vector2=waterfall[0]*farm.WORLD_SIZE
  var bottom: Vector2=waterfall[1]*farm.WORLD_SIZE
  if not visible.grow(180).has_point(bottom):continue
  for i in 14:
   var progress=fposmod(elapsed*0.80+float(i)/14.0,1.0)
   var at=top.lerp(bottom,progress)+Vector2(sin(i*4.3)*52,0)
   var c=TERRAIN.sample(at)
   if c.b>c.r*1.05 or (c.r>0.8 and c.g>0.85):
    draw_line(at,at+Vector2(-2,22),Color(0.84,0.98,1.0,sin(progress*PI)*0.50),2.5,true)
   var mist=bottom+Vector2(sin(i*3.7+elapsed)*70,-progress*42)
   draw_circle(mist,3+float(i%3)*2,Color(0.92,0.99,1.0,(1-progress)*0.15))
