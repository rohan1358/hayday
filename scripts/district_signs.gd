extends RefCounted
static func rect(point: Vector2,art_bounds: Rect2) -> Rect2:
 return Rect2(Vector2(point.x-210,art_bounds.end.y+20),Vector2(420,132))
static func paint(view,point: Vector2,art_bounds: Rect2,title: String,caption: String,locked: bool) -> void:
 var area=rect(point,art_bounds)
 var style=StyleBoxFlat.new();style.bg_color=Color("89562e");style.border_color=Color("f4d18c");style.set_border_width_all(5);style.set_corner_radius_all(17)
 view.draw_rect(Rect2(area.get_center()+Vector2(-5,55),Vector2(10,55)),Color("744726"))
 view.draw_style_box(style,area)
 var font=preload("res://assets/fonts/styles/fredoka_bold.tres")
 var size=36
 while font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>390 and size>24:size-=1
 var extent=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 view.draw_string(font,Vector2(area.get_center().x-extent/2,area.position.y+49),title,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("fff3d1"))
 var text=("Level " if locked else "")+caption
 var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,29).x
 view.draw_string(font,Vector2(area.get_center().x-width/2,area.position.y+96),text,HORIZONTAL_ALIGNMENT_LEFT,-1,29,Color("ffe3a5"))
 if locked:
  var at=Vector2(area.position.x+29,area.position.y-16)
  view.draw_arc(at+Vector2(0,-12),15,PI,TAU,16,Color("ffe194"),6,true)
  var box=StyleBoxFlat.new();box.bg_color=Color("e6af28");box.set_corner_radius_all(6)
  view.draw_style_box(box,Rect2(at-Vector2(22,10),Vector2(44,38)))
  view.draw_circle(at+Vector2(0,5),4,Color("855b21"))
