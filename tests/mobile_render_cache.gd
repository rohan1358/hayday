extends SceneTree

# Emulates the Android retained-render path with isolated, unsaved gameplay data.
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, description: String) -> void:
	if condition:
		print("OK: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)


func run_tests() -> void:
	var state := FarmGameState.new()
	state.new_game()
	var farm := FarmView.new()
	farm.size = Vector2(450, 800)
	farm.game = state
	farm.mobile_scenery_lite = true
	root.add_child(farm)
	await process_frame
	check(
		farm.plot_capture_viewports.size() == state.plots.size()
		and farm.plot_texture_caches.size() == state.plots.size(),
		"Android caches every farm plot as an individually refreshed texture"
	)
	var plot_capture: SubViewport = farm.plot_capture_viewports[0]
	var plot_tile: TextureRect = farm.plot_texture_caches[0]
	check(
		plot_capture.get_child(0) == farm.plot_caches[0]
		and plot_tile.texture == plot_capture.get_texture()
		and plot_capture.size == FarmView.PLOT_CACHE_TEXTURE_SIZE,
		"Plot painter renders inside a transparent SubViewport used by its tile"
	)
	check(
		farm.mobile_selected_plot_outline != null
		and farm.mobile_selected_plot_outline.plot_selection_only
		and farm.mobile_selected_plot_outline.get_parent() == farm.plot_cache_root,
		"Selected plot highlight is a separate retained overlay above crop textures"
	)
	var original_plot_camera := farm.camera_center
	var plot_at := farm.plot_center(0)
	farm.camera_center = plot_at
	farm.camera_target = plot_at
	check(
		farm.mobile_windmill_blades != null
		and farm.mobile_windmill_blades.windmill_blades_only
		and farm.mobile_windmill_blades.get_parent() == farm.mobile_animation_overlay,
		"Windmill blades use their own retained CanvasItem"
	)
	check(not farm.mobile_animation_is_active(), "Idle farm has no active animation overlay effects")
	farm.guide_plot_index = 0
	check(farm.mobile_animation_is_active(), "Visible tutorial still refreshes animated guidance")
	farm.guide_plot_index = -1
	farm.swipe_active = true
	farm.swipe_indices = [0]
	check(farm.mobile_animation_is_active(), "Swipe preview still refreshes")
	farm.swipe_active = false
	farm.swipe_indices.clear()
	farm.show_world_feedback("plant", plot_at)
	check(farm.mobile_animation_is_active(), "Harvest and planting feedback still refreshes")
	farm.visual_feedback.clear()
	check(not farm.mobile_animation_is_active(), "Expired effects allow idle overlay redraw to stop")
	farm.sync_mobile_plot_cache(true)
	check(plot_tile.visible, "A nearby plot texture is visible")
	var original_plot_signature := farm.plot_cache_signatures[0]
	var original_root_position := farm.plot_cache_root.position
	farm.camera_center += Vector2(85, 15)
	farm.camera_target = farm.camera_center
	farm.sync_mobile_plot_cache(false)
	check(
		farm.plot_cache_root.position != original_root_position
		and farm.plot_cache_signatures[0] == original_plot_signature,
		"Camera panning moves cached plot tiles without changing crop state"
	)
	var outline := farm.mobile_selected_plot_outline
	var outline_alpha := outline.modulate.a
	var outline_position := outline.position
	var redraws_before_pulse := farm.plot_cache_redraw_count
	for pulse in 5:
		farm.shimmer += 0.3
		farm.sync_mobile_plot_cache(true)
	check(
		farm.plot_cache_redraw_count == redraws_before_pulse
		and farm.plot_cache_signatures[0] == original_plot_signature
		and not is_equal_approx(outline.modulate.a, outline_alpha)
		and outline.position == outline_position and outline.visible,
		"Idle selection pulse animates without recapturing any plot textures"
	)
	farm.selected_plot = 1
	farm.sync_mobile_plot_cache(true)
	check(
		farm.plot_cache_redraw_count == redraws_before_pulse
		and outline.position == farm.plot_center(1) - Vector2(90, 56),
		"Changing selection moves the highlight without rerendering the crops"
	)
	farm.selected_plot = 0
	farm.sync_mobile_plot_cache(true)
	check(
		outline.position == outline_position
		and outline.get_parent().scale == farm.plot_cache_root.scale,
		"Restoring the selected plot preserves the camera-transformed overlay"
	)
	state.plots[0]["crop"] = "gandum"
	state.plots[0]["planted_at"] = state.now() - 60
	state.plots[0]["ready_at"] = state.now() - 1
	farm.sync_mobile_plot_cache(true)
	check(
		farm.plot_cache_signatures[0] != original_plot_signature
		and plot_capture.render_target_update_mode == SubViewport.UPDATE_ONCE,
		"Harvest-ready transition refreshes its cached crop texture"
	)
	farm.camera_center = original_plot_camera
	farm.camera_target = original_plot_camera
	farm.sync_mobile_plot_cache(true)
	check(
		farm.animal_capture_viewports.size() == 16
		and farm.animal_frame_textures.size() == 16
		and farm.mobile_animals.size() == 3,
		"Android precaptures eight shared idle/walk poses per livestock species"
	)
	var cow_a: Sprite2D = farm.mobile_animals[1]["node"]
	var cow_b: Sprite2D = farm.mobile_animals[2]["node"]
	var chicken: Sprite2D = farm.mobile_animals[0]["node"]
	check(
		cow_a.texture == cow_b.texture
		and chicken.texture != cow_a.texture
		and cow_a.texture.get_size() == Vector2(FarmView.ANIMAL_CACHE_TEXTURE_SIZE),
		"Animals reuse one texture per species and pose, keeping individual scale"
	)
	check(
		cow_a.offset == -FarmView.ANIMAL_CACHE_TEXTURE_CENTER
		and cow_a.get_parent() == farm.mobile_livestock_overlay,
		"Sprite origin remains aligned with original livestock world coordinates"
	)
	farm.camera_center = farm.object_position("sapi")
	farm.camera_target = farm.camera_center
	farm.shimmer = 1.2
	farm.update_mobile_animals(1.0)
	check(cow_a.visible and cow_a.texture != null, "Cow stays visible and animated near its pen")
	var first_pose_texture := cow_a.texture
	farm.shimmer += 1.0
	farm.update_mobile_animals(1.0)
	check(
		cow_a.texture != first_pose_texture,
		"Animal animation swaps cached poses without vector repaint"
	)
	farm.camera_center = Vector2(3200, 2400)
	farm.camera_target = farm.camera_center
	farm.update_mobile_animals(1.0)
	check(not cow_a.visible, "Off-screen livestock sprite is culled")
	farm.camera_center = original_plot_camera
	farm.camera_target = original_plot_camera
	check(farm.mobile_butterflies.size() == 3, "Three animated butterflies have retained CanvasItems")
	var butterfly: FarmView = farm.mobile_butterflies[0]["node"]
	check(
		butterfly.butterfly_render_only and butterfly.get_parent() == farm.mobile_livestock_overlay,
		"Butterfly drawing is cached under the livestock layer"
	)
	var previous_camera := farm.camera_center
	var previous_target := farm.camera_target
	farm.camera_center = Vector2(845, 1220)
	farm.camera_target = farm.camera_center
	farm.update_mobile_butterflies()
	await process_frame
	check(butterfly.visible, "Butterfly appears when its world anchor is on screen")
	var butterfly_position := butterfly.position
	var butterfly_scale := butterfly.scale.x
	farm.camera_center += Vector2(100, 32)
	farm.camera_target = farm.camera_center
	farm.shimmer += 0.2
	farm.update_mobile_butterflies()
	await process_frame
	await process_frame
	check(
		butterfly.position != butterfly_position and not is_equal_approx(butterfly.scale.x, butterfly_scale),
		"Camera and wing phase move butterfly through transforms"
	)
	farm.camera_center = Vector2(3200, 2400)
	farm.camera_target = farm.camera_center
	farm.update_mobile_butterflies()
	check(not butterfly.visible, "Off-screen butterflies are culled")
	farm.camera_center = previous_camera
	farm.camera_target = previous_target
	farm.update_mobile_butterflies()
	for decoration in [
		["pollinator_house", Vector2(725, 2290)],
		["herb_drying_rack", Vector2(1100, 2355)],
		["rainwater_collector", Vector2(1455, 2355)],
		["wildflower_crescent", Vector2(1780, 2340)]
	]:
		check(
			farm.farm_art.sprites.has(decoration[0]),
			"New meadow decoration is imported: " + String(decoration[0])
		)
		check(
			farm.scenery_clear_of_farm(decoration[1]),
			"New meadow decoration has free ground space: " + String(decoration[0])
		)
	var scenery_rebuilds := farm.scenery_cache_sync_rebuild_count
	farm.sync_scenery_cache()
	check(
		farm.scenery_cache_sync_rebuild_count == scenery_rebuilds,
		"Idle camera reuses the previously resolved scenery chunk set"
	)
	farm.invalidate_scenery()
	farm.sync_scenery_cache()
	check(
		farm.scenery_cache_sync_rebuild_count == scenery_rebuilds + 1,
		"Scenery invalidation rebuilds the visible chunk set"
	)
	check(farm.mobile_building_layer != null, "Android retains a separate building layer")
	check(
		(
			farm.mobile_world_details_layer != null
			and farm.mobile_world_details_layer.world_details_only
		),
		"Android retains the delivery depot, orchard and signs in world coordinates"
	)
	check(farm.mobile_world_details_signature != "", "World-detail cache has initial state")
	check(
		farm.mobile_ready_markers_layer != null and farm.mobile_ready_markers_layer.ready_markers_only,
		"Android retains ready-product badges in their own CanvasItem"
	)
	var badge_redraws := farm.mobile_ready_markers_redraw_count
	var badge_position := farm.mobile_ready_markers_layer.position
	farm.camera_center += Vector2(75, 20)
	farm.shimmer += 0.75
	farm.sync_mobile_ready_markers()
	check(
		farm.mobile_ready_markers_layer.position != badge_position
		and farm.mobile_ready_markers_redraw_count == badge_redraws,
		"Camera and idle bob move badges without rebuilding their geometry"
	)
	state.production_queue.append({"product": "roti", "ready_at": state.now() - 1})
	farm.sync_mobile_ready_markers()
	check(
		farm.mobile_ready_markers_redraw_count == badge_redraws + 1,
		"Ready production invalidates the retained badges"
	)
	badge_redraws = farm.mobile_ready_markers_redraw_count
	state.production_queue.clear()
	farm.sync_mobile_ready_markers()
	check(
		farm.mobile_ready_markers_redraw_count == badge_redraws + 1,
		"Collected production removes the retained ready badge"
	)
	var world_details_position := farm.mobile_world_details_layer.position
	var world_details_signature := farm.mobile_world_details_signature
	var world_details_redraws := farm.mobile_world_details_redraw_count
	farm.camera_center += Vector2(105, 55)
	farm.sync_mobile_world_details()
	check(
		(
			farm.mobile_world_details_layer.position != world_details_position
			and farm.mobile_world_details_signature == world_details_signature
			and farm.mobile_world_details_redraw_count == world_details_redraws
		),
		"Panning repositions static world details without rebuilding them"
	)
	state.orchard[0] = {"fruit": "apel", "ready_at": state.now() + 12}
	farm.sync_mobile_world_details()
	check(
		farm.mobile_world_details_redraw_count > world_details_redraws,
		"Planting a fruit tree invalidates world details"
	)
	world_details_redraws = farm.mobile_world_details_redraw_count
	state.orchard[0]["ready_at"] = state.now() - 1
	farm.sync_mobile_world_details()
	check(
		farm.mobile_world_details_redraw_count > world_details_redraws,
		"Fruit tree becoming harvest-ready invalidates world details"
	)
	state.orchard[0] = {"fruit": "", "ready_at": 0}
	farm.sync_mobile_world_details()
	check(
		farm.mobile_visitor_layer != null and farm.mobile_visitor_layer.visitor_render_only,
		"Android retains the visitor's vector drawing independently"
	)
	check(
		farm.mobile_ujang_layer != null and farm.mobile_ujang_layer.ujang_render_only,
		"Android retains the farm worker's vector drawing independently"
	)
	check(
		farm.mobile_truck_layer != null and farm.mobile_truck_layer.truck_render_only,
		"Android retains the delivery truck independently of live animations"
	)
	farm.camera_center = FarmView.DELIVERY_DOCK
	farm.sync_mobile_truck_layer(0.016)
	check(farm.mobile_truck_layer.visible, "Parked delivery truck is visible near its depot")
	var old_truck_position := farm.mobile_truck_layer.position
	var parked_truck_signature := farm.mobile_truck_signature
	var parked_redraw_count := farm.mobile_truck_redraw_count
	farm.camera_center += Vector2(90, 35)
	farm.sync_mobile_truck_layer(0.016)
	check(
		(
			farm.mobile_truck_layer.position != old_truck_position
			and farm.mobile_truck_signature == parked_truck_signature
			and farm.mobile_truck_redraw_count == parked_redraw_count
		),
		"Panning moves the parked truck without repainting it"
	)
	farm.delivery_elapsed = 0.0
	farm.sync_mobile_truck_layer(0.016)
	check(
		(
			farm.mobile_truck_redraw_count > parked_redraw_count
			and farm.mobile_truck_layer.delivery_elapsed >= 0.0
		),
		"Dispatch changes the cached truck to its animated state"
	)
	var moving_redraw_count := farm.mobile_truck_redraw_count
	farm.delivery_elapsed = 1.2
	farm.sync_mobile_truck_layer(0.08)
	check(
		farm.mobile_truck_redraw_count > moving_redraw_count,
		"Travelling truck refreshes its animated dust and bounce"
	)
	farm.delivery_elapsed = 3.1
	farm.sync_mobile_truck_layer(0.016)
	check(not farm.mobile_truck_layer.visible, "Truck hides during its off-screen turnaround")
	farm.delivery_elapsed = 4.1
	farm.camera_center = farm.delivery_truck_position()
	farm.sync_mobile_truck_layer(0.016)
	check(
		farm.mobile_truck_layer.visible and farm.mobile_truck_layer.delivery_elapsed >= 3.75,
		"Returning truck becomes visible and faces the opposite direction"
	)
	farm.delivery_elapsed = -1.0
	farm.camera_center = FarmView.DELIVERY_DOCK
	farm.sync_mobile_truck_layer(0.016)
	check(
		farm.mobile_truck_layer.visible and farm.mobile_truck_signature == parked_truck_signature,
		"Truck reverts to a stationary cached illustration after delivery"
	)
	var starting_camera := farm.camera_center
	farm.camera_center = farm.ujang_position
	farm.sync_mobile_ujang_layer(0.016)
	check(farm.mobile_ujang_layer.visible, "Worker cache becomes visible near the worker")
	var old_worker_position := farm.mobile_ujang_layer.position
	var worker_signature := farm.mobile_ujang_signature
	farm.camera_center += Vector2(92, 31)
	farm.sync_mobile_ujang_layer(0.016)
	check(
		(
			farm.mobile_ujang_layer.position != old_worker_position
			and farm.mobile_ujang_signature == worker_signature
		),
		"Camera pans reposition the worker without rebuilding the character"
	)
	farm.ujang_walking = true
	farm.sync_mobile_ujang_layer(0.16)
	check(
		farm.mobile_ujang_signature != worker_signature,
		"Worker redraws when the walking pose starts"
	)
	farm.ujang_walking = false
	farm.sync_mobile_ujang_layer(0.016)
	check(
		(
			farm.mobile_ujang_signature == worker_signature
			and not farm.mobile_ujang_layer.ujang_walking
		),
		"Worker returns to a resting pose after walking"
	)
	farm.camera_center = starting_camera
	var starting_visitor := state.visitor_request.duplicate(true)
	check(not state.visitor_request.is_empty(), "New game includes a visitor for render testing")
	farm.camera_center = farm.visitor_world_position()
	farm.sync_mobile_visitor_layer()
	check(farm.mobile_visitor_layer.visible, "Visitor cache becomes visible near the market")
	var old_visitor_position := farm.mobile_visitor_layer.position
	var visitor_signature := farm.mobile_visitor_signature
	farm.camera_center += Vector2(95, 35)
	farm.sync_mobile_visitor_layer()
	check(
		(
			farm.mobile_visitor_layer.position != old_visitor_position
			and farm.mobile_visitor_signature == visitor_signature
		),
		"Camera pans reposition the visitor without rebuilding its geometry"
	)
	state.visitor_request.clear()
	farm.sync_mobile_visitor_layer()
	check(not farm.mobile_visitor_layer.visible, "Visitor cache hides after request is cleared")
	state.visitor_request = starting_visitor
	farm.camera_center = starting_camera
	farm.sync_mobile_visitor_layer()
	check(farm.mobile_building_layer.buildings_only, "Building cache renders in world coordinates")
	check(farm.mobile_building_signature != "", "Building state has initial signature")
	check(
		farm.mobile_building_layer.game == state,
		"Building and construction cache share the live game state"
	)
	var old_signature := farm.mobile_building_signature
	var old_position := farm.mobile_building_layer.position
	farm.camera_center += Vector2(210, 120)
	farm.sync_mobile_building_layer()
	check(
		(
			farm.mobile_building_layer.position != old_position
			and farm.mobile_building_signature == old_signature
		),
		"Camera pan moves the retained layer without invalidating its drawings"
	)
	state.layout_positions["dapur"] = [580.0, 530.0]
	farm.sync_mobile_building_layer()
	check(
		farm.mobile_building_signature != old_signature, "Moving a building invalidates the cache"
	)
	old_signature = farm.mobile_building_signature
	state.constructions["gazebo"] = 1
	farm.sync_mobile_building_layer()
	check(
		(
			farm.mobile_building_signature != old_signature
			and farm.mobile_building_layer.game.has_construction("gazebo")
		),
		"Buying a construction invalidates its retained drawing"
	)
	old_signature = farm.mobile_building_signature
	farm.set_edit_mode(true)
	farm.sync_mobile_building_layer()
	check(
		farm.mobile_building_layer.edit_mode and farm.mobile_building_signature != old_signature,
		"Layout editing updates building signs"
	)
	old_signature = farm.mobile_building_signature
	farm.drag_key = "dapur"
	farm.drag_preview = Vector2(650, 520)
	farm.sync_mobile_building_layer()
	check(
		(
			farm.mobile_building_layer.drag_key == "dapur"
			and farm.mobile_building_layer.object_position("dapur") == Vector2(650, 520)
			and farm.mobile_building_signature != old_signature
		),
		"Moving a building refreshes its retained preview"
	)
	farm.drag_key = ""
	farm.chopping_tree = 0
	farm.invalidate_scenery()
	farm.sync_scenery_cache()
	var visible_key: Vector2i = farm.scenery_chunks.keys()[0]
	var captured: SubViewport = farm.scenery_capture_viewports[visible_key]
	var chunk_painter := captured.get_child(0) as FarmView
	check(
		(
			farm.scenery_chunk_versions[visible_key] == farm.scenery_revision
			and chunk_painter.animation_source == farm
		),
		"Chopping tree invalidates the cached scenery with access to live animation"
	)
	# Explore the map horizontally and vertically. Previously every visited
	# scenery SubViewport survived until the game exited, consuming GPU memory.
	for camera_at in [
		Vector2(600, 480), Vector2(2850, 450), Vector2(2900, 2200),
		Vector2(600, 2220), Vector2(930, 950)
	]:
		farm.camera_center = camera_at
		farm.sync_scenery_cache()
		check(
			farm.scenery_chunks.size() <= FarmView.SCENERY_CACHE_MAX_CHUNKS,
			"Scenery cache stays bounded while traversing the farm"
		)
	var visible := farm.visible_world_rect(220.0)
	var current_chunk := Vector2i(
		floori(visible.get_center().x / FarmView.SCENERY_CACHE_CHUNK_SIZE),
		floori(visible.get_center().y / FarmView.SCENERY_CACHE_CHUNK_SIZE)
	)
	check(
		farm.scenery_chunks.has(current_chunk)
		and farm.scenery_capture_viewports.has(current_chunk),
		"Returning to the first area restores its cached landscape"
	)
	farm.queue_free()
	await process_frame
	print("TOTAL FAILURES: ", failures)
	quit(1 if failures > 0 else 0)
