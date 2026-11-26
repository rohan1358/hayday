extends Control

# World-space CanvasItem: the rocks share the same live camera transform as
# retained buildings, rather than lagging behind the 10 FPS actor overlay.
var source: FarmView
var _state_signature := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	size = source.WORLD_SIZE
	queue_redraw()

func _process(_delta: float) -> void:
	if source == null or source.game == null: return
	visible = source.get_parent().active_tab == "kebun" and not preload("res://scripts/first_farm.gd").active(source.game)
	if not visible: return
	var scaler := source.size / source.get_virtual_size()
	position = (source.get_virtual_size() * 0.5 - source.camera_center * source.camera_zoom) * scaler
	scale = scaler * source.camera_zoom
	var nodes: Array = source.game.building_upgrades.get("nodes", [])
	var states := str([source.drag_key,source.drag_preview,source.scenery_revision])
	for node in nodes:
		states += "%s:%s|" % [str(node.get("position", [])), str(int(node.get("ready_at", 0)) > source.game.now())]
	if states != _state_signature:
		_state_signature = states
		queue_redraw()

func _draw() -> void:
	if source == null or source.game == null: return
	for i in source.game.building_upgrades.get("nodes", []).size():
		var node: Dictionary=source.game.building_upgrades.nodes[i]
		if str(node.get("kind", "")) != "batu": continue
		var packed: Array = node.get("position", [])
		if packed.size() != 2: continue
		var at: Vector2 = source.object_position("resource_%d"%i)
		if at.y < 820: continue
		if int(node.get("ready_at", 0)) > source.game.now():
			for offset in [Vector2(-28, 5), Vector2(1, 10), Vector2(29, 3)]:
				source.farm_art.paint(self, "resource_boulder", at + offset, 43.0)
		else:
			source.farm_art.paint(self, "resource_boulder", at, 130.0)
