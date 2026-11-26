extends Sprite2D

# Far end of the land. This rectangle is shared with placement and navigation.
const WORLD_RECT := Rect2(2700, 6540, 1420, 947)
var farm: FarmView

func _ready() -> void:
	texture = preload("res://assets/waterfall/river_waterfall.png")
	centered = false
	var flow := ShaderMaterial.new()
	flow.shader = preload("res://assets/waterfall/flow.gdshader")
	material = flow
	_sync()

func _process(_delta: float) -> void:
	_sync()

func _sync() -> void:
	if farm == null or texture == null: return
	visible = false # The reference terrain already includes the remote waterfall.
	if not visible: return
	var scaler := farm.size / farm.get_virtual_size()
	position = ((WORLD_RECT.position - farm.camera_center) * farm.camera_zoom + farm.get_virtual_size() * 0.5) * scaler
	scale = WORLD_RECT.size / texture.get_size() * farm.camera_zoom * scaler

static func contains(at: Vector2, margin: float = 0.0) -> bool:
	# Follow the diagonal river silhouette rather than reserving empty corners.
	var uv := (at - WORLD_RECT.position) / WORLD_RECT.size
	return WORLD_RECT.grow(margin).has_point(at) and absf(uv.x + uv.y - 1.0) < 0.27 + margin / WORLD_RECT.size.x
