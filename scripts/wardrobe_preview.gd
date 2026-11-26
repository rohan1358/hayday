extends Control
const ART = preload("res://scripts/wardrobe_assets.gd")
var data: Dictionary = {}
var item := -1
var sector := 0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var bounds := Rect2(Vector2(12,18),size-Vector2(24,30))
	if item<0: ART.paint(self,bounds,data,{"direction":Vector2(sin(sector*PI/4),cos(sector*PI/4))})
	else:
		var texture := ART.directional_accessory(item,sector)
		if texture!=null: draw_texture_rect(texture,ART.fitted(texture,bounds),false)
