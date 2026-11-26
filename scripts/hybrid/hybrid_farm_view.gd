extends FarmView
var hybrid_controller
var ranch_animator
func _ready() -> void:
	# Retain scenery, fields and actor layers on desktop as well as Android.
	mobile_scenery_lite=not preload("res://scripts/first_farm.gd").compact(game)
	super._ready()
	if mobile_livestock_overlay==null:
		mobile_livestock_overlay=FarmView.new()
		mobile_livestock_overlay.name="LiveFarmAnimals"
		mobile_livestock_overlay.game=game
		mobile_livestock_overlay.livestock_only=true
		mobile_livestock_overlay.animation_source=self
		mobile_livestock_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(mobile_livestock_overlay)
		mobile_livestock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ranch_animator=preload("res://scripts/ranch_animator.gd").new()
	ranch_animator.configure(self)
func update_ujang(delta: float) -> void:
	if hybrid_controller==null or chopping_tree>=0: super.update_ujang(delta)
func begin_farm_swipe(at: Vector2) -> void:
	if hybrid_controller==null or hybrid_controller.manager_mode(): super.begin_farm_swipe(at)
func activate_at(at: Vector2) -> void:
	if not edit_mode:
		var region_id: String = preload("res://scripts/world_regions_painter.gd").hit(self, screen_to_world(at))
		if not region_id.is_empty():
			region_pressed.emit(region_id)
			accept_event()
			return
	if hybrid_controller!=null and not edit_mode and preload("res://scripts/first_farm.gd").compact(game):
		hybrid_controller.tap_world(screen_to_world(at))
		return
	if hybrid_controller!=null and not edit_mode:
		var world=screen_to_world(at)
		for node in game.building_upgrades.get("nodes",[]):
			if ready_marker_at(world).is_empty() and world.distance_to(Vector2(node.position[0],node.position[1]))<45:
				hybrid_controller.tap_world(world)
				return
	if hybrid_controller==null or hybrid_controller.manager_mode():
		super.activate_at(at)
		return
	hybrid_controller.tap_world(screen_to_world(at))
func pan_by(movement: Vector2) -> void:
	if hybrid_controller!=null: hybrid_controller.data.follow=false
	super.pan_by(movement)
func update_mobile_animals(delta: float) -> void:
	for animal in mobile_animals: animal.node.visible=false
	if ranch_animator!=null: ranch_animator.tick(delta)
func set_edit_mode(enabled: bool) -> void:
	if hybrid_controller!=null and enabled: hybrid_controller.cancel_all("Mengatur kebun")
	super.set_edit_mode(enabled)
