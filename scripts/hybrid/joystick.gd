extends Control
signal changed(value: Vector2)
var finger=-1
var axis=Vector2.ZERO
var mouse_owned=false
func _ready() -> void:
	custom_minimum_size=Vector2(144,144)
	mouse_filter=Control.MOUSE_FILTER_STOP
func set_axis(at: Vector2) -> void:
	axis=(at-size*0.5)/(size.x*0.38)
	axis=axis.limit_length(1)
	if axis.length()<0.16: axis=Vector2.ZERO
	changed.emit(axis)
	queue_redraw()
func release() -> void:
	finger=-1
	mouse_owned=false
	axis=Vector2.ZERO
	changed.emit(axis)
	queue_redraw()
func _gui_input(event: InputEvent) -> void:
	# GUI events are already local to this Control, including viewport scaling.
	if event is InputEventScreenTouch and event.pressed and finger<0:
		finger=event.index
		set_axis(event.position)
		accept_event()
	elif event is InputEventScreenDrag and event.index==finger:
		set_axis(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and finger<0:
		mouse_owned=true
		set_axis(event.position)
		accept_event()
	elif event is InputEventMouseMotion and mouse_owned:
		set_axis(event.position)
		accept_event()
func _input(event: InputEvent) -> void:
	# Keep global release handling so lifting outside the circle cannot stick.
	# Do not consume drag/motion here: it must reach _gui_input for local coords.
	if not is_visible_in_tree():
		if finger>=0 or mouse_owned: release()
		return
	if event is InputEventScreenTouch and event.index==finger and not event.pressed:
		release()
		get_viewport().set_input_as_handled()
	elif mouse_owned and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		release()
		get_viewport().set_input_as_handled()
func _draw() -> void:
	var center=size*0.5
	draw_circle(center,size.x*0.46,Color("22575699"))
	draw_arc(center,size.x*0.45,0,TAU,40,Color("fff0c4cc"),3,true)
	draw_circle(center+axis*size.x*0.27,size.x*0.19,Color("ffdb85ee"))
