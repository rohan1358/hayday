extends RefCounted

# The countryside is painted in farm coordinates, underneath every building and
# actor. The HUD remains transparent and fixed to its CanvasLayer.
static var countryside: Texture2D
const GRASS_START_Y := 640.0
# Leave room for the full canopy, not only the trunk's ground anchor.
const WILD_TREE_MIN_Y := GRASS_START_Y + 180.0

static func paint(view: FarmView, world_size: Vector2) -> void:
	if view.visible_world_rect(0).position.y > 650.0:
		return
	if countryside == null:
		countryside = load("res://assets/cheerful/countryside.png") as Texture2D
	if countryside == null:
		return
	var width := world_size.x
	var source_width := float(countryside.get_width())
	var source_height := float(countryside.get_height())
	# The horizon stays behind the HUD at the starter camera position. Its
	# meadow dissolves into the playable grass before reaching the farmhouse.
	view.draw_texture_rect_region(countryside,
		Rect2(0.0, 0.0, width, 430.0),
		Rect2(0.0, 0.0, source_width, source_height * 0.68))
	for step in 14:
		var top := 430.0 + float(step) * 15.0
		var source_top := source_height * (0.68 + float(step) * 0.32 / 14.0)
		var alpha := pow(1.0 - float(step + 1) / 15.0, 1.35)
		view.draw_texture_rect_region(countryside,
			Rect2(0.0, top, width, 15.5),
			Rect2(0.0, source_top, source_width, source_height * 0.32 / 14.0 + 0.5),
			Color(1.0, 1.0, 1.0, alpha))
