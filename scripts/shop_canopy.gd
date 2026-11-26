extends Control
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
 var width=size.x/12.0
 for i in 12:
  var color=Color("ed6043") if i%2==0 else Color("fff1cd")
  var x=i*width
  draw_rect(Rect2(x,0,width+1,35),color)
  draw_circle(Vector2(x+width/2,35),width/2,color)
  draw_line(Vector2(x,1),Vector2(x+width,1),Color("ffd592"),3)
