extends Control
var game
var dragging=false
var drag_start=Vector2.ZERO
var font=preload("res://assets/fonts/styles/fredoka_bold.tres")
var background = preload("res://assets/playground/scenes.png")
const SPRITES = preload("res://assets/playground/sprites.png")
const SCENES = {"spin": Vector2(0, 0), "ball": Vector2(1, 0), "animals": Vector2(0, 1), "fruit": Vector2(1, 1)}
func _ready():
 var language=get_node_or_null("/root/GardenLanguage")
 if language!=null: language.language_changed.connect(func(_code): queue_redraw())
 mouse_filter = MOUSE_FILTER_STOP
 if game.mode == "fruit":
  for index in 20:
   var tile = Button.new()
   tile.name = "FruitTile%d" % index
   tile.flat = true
   tile.focus_mode = Control.FOCUS_NONE
   tile.set_meta("colorful_applied", true)
   tile.pressed.connect(game.tap_fruit.bind(index))
   add_child(tile)
  resized.connect(place_fruit_buttons)
  place_fruit_buttons()

func fruit_rect(index: int) -> Rect2:
 return Rect2(42 + (index % 5) * 112, 82 + floori(index / 5.0) * 116, 106, 108)

func place_fruit_buttons() -> void:
 var transform = frame()
 for index in get_child_count():
  var tile = get_child(index)
  var rect = fruit_rect(index)
  tile.position = transform * rect.position
  tile.size = transform.basis_xform(rect.size)
func frame() -> Transform2D:
 var factor=minf(size.x/640.0,size.y/600.0)
 return Transform2D(0,Vector2.ONE*factor,0,Vector2((size.x-640*factor)/2,(size.y-600*factor)/2))
func text(value: String,at: Vector2,size_px: int=24,color: Color=Color("4d3a25")):
 value=preload("res://scripts/garden_language.gd").text(value)
 var width=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x
 draw_string(font,at-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)
func box(rect: Rect2,fill: Color):
 var style=StyleBoxFlat.new();style.bg_color=fill;style.border_color=Color("fce6aa");style.set_border_width_all(3);style.set_corner_radius_all(18);draw_style_box(style,rect)
func _draw():
 if game==null:return
 draw_set_transform_matrix(frame())
 var cell = Vector2(background.get_size()) / 2.0
 draw_texture_rect_region(background, Rect2(0,0,640,600), Rect2(SCENES[game.mode]*cell + Vector2.ONE, cell - Vector2.ONE*2))
 match game.mode:
  "spin":draw_spin()
  "ball":draw_ball_game()
  "animals":draw_animals()
  "fruit":draw_fruits()
func draw_spin():
 draw_set_transform_matrix(frame() * Transform2D(0, Vector2.ONE * 0.46, 0, Vector2(337, 214)))
 var center=Vector2(320,300);var radius=190.0
 var colors=[Color("f5ae35"),Color("f17a4b"),Color("6ac655"),Color("5fb9d2")]
 for i in 4:
  var points=PackedVector2Array([center])
  for j in 31:points.append(center+Vector2.from_angle(game.angle+i*PI*.5+j/30.0*PI*.5)*radius)
  draw_colored_polygon(points,colors[i])
  var at=center+Vector2.from_angle(game.angle+(i+.5)*PI*.5)*125
  draw_circle(at,29,Color("ffdb54"));draw_arc(at,29,0,TAU,32,Color("aa791b"),3,true)
  text(str(50+i*50),at+Vector2(0,8),25)
 draw_arc(center,radius,0,TAU,90,Color("985c24"),12,true)
 draw_arc(center,radius-8,0,TAU,90,Color("fff3b2"),4,true)
 draw_circle(center,40,Color("fff1b3"));text("PUTAR",center+Vector2(0,7),19)
 draw_colored_polygon(PackedVector2Array([Vector2(293,80),Vector2(347,80),Vector2(320,140)]),Color("e24e35"))
 text("50–200 KOIN",Vector2(320,550),33)
func draw_ball_game():
 text("★", Vector2(game.target, 95), 42, Color("fff0a6"))
 if not game.flying:
  var velocity=Vector2(game.aim*260,-(500+game.power*330))
  for i in range(1,27):
   var t=i*.055
   var p=Vector2(310,525)+velocity*t+Vector2(0,350*t*t)
   if p.y<60 or p.y>600:continue
   draw_circle(p,4,Color(1,1,.9,.9))
 sprite(Vector2(4, 1), Rect2(game.ball - Vector2(35, 35), Vector2(70, 70)))
 text("Sisa bola: %d"%game.balls,Vector2(320,585),24)
func oval(center: Vector2,radius: Vector2,color: Color):
 var points=PackedVector2Array()
 for i in 48:points.append(center+Vector2(cos(i*TAU/48),sin(i*TAU/48))*radius)
 draw_colored_polygon(points,color)
func draw_animals():
 for i in 6:
  var center=Vector2(145+(i%3)*175,270+int(i/3)*175)
  oval(center+Vector2(0,12),Vector2(73,35),Color("c49357"))
  oval(center,Vector2(62,27),Color("614424"))
  if i==game.hole:
   sprite(Vector2(game.animal, 1), Rect2(center - Vector2(66, 105), Vector2(132, 127)))
 text("KETUK HEWANNYA!",Vector2(320,125),33)
 text("Tertangkap: %d"%game.score,Vector2(320,560),30)
func sprite(cell_index: Vector2, destination: Rect2) -> void:
 var cell = Vector2(SPRITES.get_size()) / Vector2(5, 2)
 draw_texture_rect_region(SPRITES, destination, Rect2(cell_index * cell + Vector2.ONE, cell - Vector2.ONE * 2))

func fruit(kind: int, center: Vector2):
 sprite(Vector2(kind, 0), Rect2(center - Vector2(45, 48), Vector2(90, 90)))

func draw_fruits():
 box(Rect2(31, 71, 573, 475), Color("d6a264"))
 for i in 20:
  var rect=fruit_rect(i)
  box(rect,Color("caed8e") if i in game.selected else Color("ffedc5"))
  fruit(game.board[i],rect.get_center()+Vector2(0,8))
 text("Cocokkan 3 buah sejenis",Vector2(320,575),27)
func point_event(event) -> Vector2:
 return frame().affine_inverse()*event.position
func _gui_input(event):
 if game==null or not game.active:return
 var pointer=event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT or event is InputEventScreenTouch
 if not pointer:return
 var point=point_event(event)
 if game.mode=="ball":
  if event.pressed:dragging=true;drag_start=point
  elif dragging:dragging=false;game.flick(point-drag_start)
 elif event.pressed and game.mode=="animals":
  for i in 6:
   var center=Vector2(145+(i%3)*175,270+int(i/3)*175)
   if point.distance_to(center-Vector2(0,25))<75:game.tap_hole(i);break
 accept_event();queue_redraw()
