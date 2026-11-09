class_name FarmView
extends Control

signal plot_pressed(index: int)
signal farm_swipe_requested(mode: String, plot_indices: PackedInt32Array)
signal blank_pressed
signal coop_pressed
signal cow_pressed
signal barn_pressed
signal factory_pressed
signal feed_mill_pressed
signal missions_pressed
signal market_pressed
signal visitor_pressed
signal orchard_pressed(index: int)
signal livestock_pressed
signal constructions_pressed
signal orders_pressed
signal layout_changed(key: String, at: Vector2)
signal decoration_placed(key: String, at: Vector2)
signal roads_changed
signal placement_rejected
signal wild_tree_chopped(tree_id: int)
signal wild_tree_started
signal wild_tree_struck
signal animal_tapped(kind: String)

const VIRTUAL_SIZE := Vector2(720, 780)
const WORLD_SIZE := Vector2(3600, 2900)
const MIN_ZOOM := 0.62
const MAX_ZOOM := 1.75
const DRAG_THRESHOLD := 13.0
const OBJECT_SNAP_DISTANCE := 26.0
const OBJECT_SNAP_GAP := 6.0
const PLOT_SNAP_OFFSETS := [
	Vector2(-100, -55), Vector2(100, -55),
	Vector2(-100, 55), Vector2(100, 55),
	Vector2(-200, 0), Vector2(200, 0),
	Vector2(0, -110), Vector2(0, 110)
]
const ROAD_GRID_SIZE := 80
const ROAD_WIDTH := 75.0
const ROAD_HALF_WIDTH := ROAD_WIDTH * 0.5
const DELIVERY_DOCK := Vector2(1360, 1235)
const DELIVERY_ANIMATION_SECONDS := 6.5
const SCENERY_CELL_SIZE := 74
const MEADOW_CLUSTER_SIZE := 218
const SCENERY_CACHE_CHUNK_SIZE := 800
const SCENERY_CACHE_MAX_CHUNKS := 12
const PLOT_CACHE_TEXTURE_SIZE := Vector2i(240, 280)
const PLOT_CACHE_TEXTURE_CENTER := Vector2(120, 180)
const ANIMAL_CACHE_TEXTURE_SIZE := Vector2i(240, 192)
const ANIMAL_CACHE_TEXTURE_CENTER := Vector2(120, 115)
const ANIMAL_CACHE_POSES := 4
const TERRAIN_PATCH_RECTS := [
	Rect2(150, 190, 790, 580), Rect2(1000, 170, 950, 570),
	Rect2(460, 1030, 1230, 750), Rect2(2220, 220, 1150, 850),
	Rect2(2130, 1540, 1080, 1110), Rect2(220, 2160, 1750, 460)
]
const UJANG_SCALE := 0.8
const UJANG_PLOT_HALF_SIZE := Vector2(92, 58)
const UJANG_NAV_CELL_SIZE := 40
const UJANG_TREE_RADIUS := 52.0
const UJANG_ORCHARD_RADIUS := 59.0
const UJANG_BUILDING_MARGIN := Vector2(13, 13)
const GRASS := Color("9bd974")
const DARK_GRASS := Color("6fbd63")
const DIRT := Color("a96236")
const COW_PEN_BOUNDS := Rect2(315, 1060, 375, 255)
const CHICKEN_RUN_BOUNDS := Rect2(1190, 265, 320, 330)
const PIG_PEN_CENTER := Vector2(395, 1480)
const GOAT_PEN_CENTER := Vector2(710, 1650)
const PIG_PEN_BOUNDS := Rect2(250, 1350, 290, 230)
const GOAT_PEN_BOUNDS := Rect2(565, 1520, 290, 230)
const WILD_TREES := [
	Vector2(300, 310), Vector2(260, 1050), Vector2(340, 1650),
	Vector2(740, 180), Vector2(1100, 180), Vector2(1540, 195),
	Vector2(1990, 340), Vector2(2120, 890), Vector2(2010, 1660),
	Vector2(1800, 1850), Vector2(1190, 2010), Vector2(570, 1890),
	Vector2(2520, 350), Vector2(2700, 550), Vector2(2910, 390),
	Vector2(3160, 720), Vector2(3370, 480), Vector2(2740, 1150),
	Vector2(3050, 1380), Vector2(3400, 1570), Vector2(2420, 1820),
	Vector2(2780, 2090), Vector2(3100, 2300), Vector2(3380, 2460),
	Vector2(2260, 2550), Vector2(1750, 2530), Vector2(870, 2590),
	Vector2(390, 2430), Vector2(2850, 2670)
]
const OBJECT_DEFAULTS := {
	"sapi": Vector2(500, 1200), "ayam": Vector2(1355, 370),
	"dapur": Vector2(500, 545), "gudang": Vector2(840, 355),
	"pasar": Vector2(1380, 685), "babi": PIG_PEN_CENTER,
	"kambing": GOAT_PEN_CENTER, "roti": Vector2(673, 590),
	"susu": Vector2(1510, 510), "pakan": Vector2(2130, 1180), "buah_0": Vector2(930, 1490),
	"buah_1": Vector2(1260, 1490)
}
const OBJECT_HALF_SIZES := {
	"sapi": Vector2(188, 132), "ayam": Vector2(158, 148),
	"dapur": Vector2(97, 94), "gudang": Vector2(95, 100),
	"pasar": Vector2(120, 83), "babi": Vector2(138, 110),
	"kambing": Vector2(138, 110), "roti": Vector2(56, 46),
	"susu": Vector2(56, 46), "pakan": Vector2(95, 83), "buah_0": Vector2(65, 75),
	"buah_1": Vector2(65, 75)
}
# Existing map illustrations get stable IDs so players can arrange them and
# their positions persist through layout_positions without duplicating purchases.
# Keep the order (garden accents first, handmade props second) for draw priority.
const MOVABLE_SCENERY := [
	["flowering_hedge", Vector2(620, 745), 124.0],
	["flowering_hedge", Vector2(695, 770), 124.0],
	["flowering_hedge", Vector2(770, 790), 124.0],
	["flowering_hedge", Vector2(1580, 1110), 124.0],
	["flowering_hedge", Vector2(1700, 1370), 124.0],
	["flowering_hedge", Vector2(1030, 1710), 124.0],
	["flowering_hedge", Vector2(1120, 1730), 124.0],
	["flowering_hedge", Vector2(1250, 1770), 124.0],
	["flowering_hedge", Vector2(1560, 725), 124.0],
	["fence_straight", Vector2(750, 730), 124.0],
	["fence_straight", Vector2(865, 754), 124.0],
	["fence_straight", Vector2(1190, 1740), 124.0],
	["fence_corner", Vector2(650, 727), 90.0],
	["fence_corner", Vector2(1305, 1748), 90.0],
	["flower_garden", Vector2(795, 1140), 145.0],
	["flower_garden", Vector2(1680, 1430), 145.0],
	["flower_garden", Vector2(1670, 875), 145.0],
	["wooden_crates", Vector2(790, 555), 147.0],
	["wooden_crates", Vector2(940, 1200), 116.0],
	["wooden_crates", Vector2(1630, 905), 145.0],
	["hay_stack", Vector2(1040, 440), 156.0],
	["hay_stack", Vector2(1600, 640), 130.0],
	["flower_patch", Vector2(690, 760), 195.0],
	["flower_patch", Vector2(1480, 1100), 173.0],
	["flower_patch", Vector2(1480, 1650), 175.0],
	["decorative_pond", Vector2(820, 1335), 253.0],
	["decorative_pond", Vector2(1840, 1320), 280.0],
	["rustic_lamp", Vector2(760, 638), 87.0],
	["rustic_lamp", Vector2(1195, 1205), 89.0],
	["rustic_lamp", Vector2(1690, 780), 92.0],
	["harvest_baskets", Vector2(710, 530), 160.0],
	["harvest_baskets", Vector2(1790, 1160), 125.0],
	["harvest_baskets", Vector2(1120, 1695), 135.0],
	["wooden_signpost", Vector2(550, 960), 90.0],
	["wooden_signpost", Vector2(1860, 970), 98.0],
	["wishing_well", Vector2(1925, 1520), 180.0],
	["flowering_bushes", Vector2(925, 1065), 165.0],
	["flowering_bushes", Vector2(1845, 1595), 176.0],
	["flowering_bushes", Vector2(1440, 1790), 154.0],
	["arched_fence", Vector2(1040, 1880), 185.0],
	["water_tower", Vector2(2070, 1060), 122.0],
	["flower_patch", Vector2(535, 2065), 162.0],
	["flowering_bushes", Vector2(680, 2040), 141.0],
	["flowering_hedge", Vector2(812, 2115), 132.0],
	["rustic_lamp", Vector2(915, 1950), 83.0],
	["flower_patch", Vector2(1005, 2080), 175.0],
	["wishing_well", Vector2(1150, 2135), 168.0],
	["flowering_bushes", Vector2(1270, 2075), 154.0],
	["flower_patch", Vector2(1460, 2100), 161.0],
	["arched_fence", Vector2(1555, 1950), 168.0],
	["harvest_baskets", Vector2(1445, 1900), 123.0],
	["flowering_hedge", Vector2(1705, 2120), 124.0],
	["wooden_signpost", Vector2(1890, 2060), 87.0],
	["pollinator_house", Vector2(660, 1860), 142.0],
	["herb_drying_rack", Vector2(900, 1930), 152.0],
	["rainwater_collector", Vector2(1120, 1660), 132.0],
	["wildflower_crescent", Vector2(1380, 1835), 174.0]
]
const BAKERY_TOUCH_BOUNDS := Rect2(-94, -150, 188, 207)
const DAIRY_TOUCH_BOUNDS := Rect2(-97, -145, 194, 201)
const FEED_MILL_TOUCH_BOUNDS := Rect2(-100, -145, 200, 215)
const READY_MARKERS := {
	"dapur": {"offset": Vector2(0, -186), "text": "HASIL SIAP!"},
	"pakan": {"offset": Vector2(0, -180), "text": "PAKAN SIAP!"},
	"sapi": {"offset": Vector2(125, -156), "text": "SUSU SIAP!"},
	"babi": {"offset": Vector2(75, -145), "text": "HASIL SIAP!"},
	"kambing": {"offset": Vector2(75, -145), "text": "HASIL SIAP!"}
}

var game: FarmGameState
static var shared_farm_art := FarmArt.new()
var farm_art: FarmArt = shared_farm_art
var selected_plot := 0
var guide_plot_index := -1
var guide_plot_action := ""
var shimmer := 0.0
var paint_timer := 0.0
var camera_center := Vector2(930, 950)
var camera_target := Vector2(930, 950)
var camera_zoom := 0.62
var zoom_target := 0.62
var pointers: Dictionary = {}
var press_position := Vector2.ZERO
var gesture_dragged := false
var mouse_down := false
var mouse_press_position := Vector2.ZERO
var mouse_dragged := false
var pinch_distance := 0.0
var pinch_started := false
var swipe_mode := ""
var swipe_active := false
var swipe_indices := PackedInt32Array()
var swipe_visited: Dictionary = {}
var swipe_last_position := Vector2.ZERO
var edit_mode := false
var road_tool := "object"
var road_stroke_active := false
var road_stroke_changed := false
var road_last_cell := Vector2i.ZERO
var edit_selected := ""
var drag_key := ""
var drag_original := Vector2.ZERO
var drag_grab_offset := Vector2.ZERO
var drag_preview := Vector2.ZERO
var drag_was_moved := false
var drag_snapped := false
var placement_decoration_key := ""
var placement_preview := Vector2.ZERO
var placement_snapped := false
var draw_offset := Vector2.ZERO
var ujang_position := Vector2(700, 980)
var ujang_patrol_index := 0
var ujang_pause := 0.5
var ujang_facing := 1.0
var ujang_walking := false
var ujang_path := PackedVector2Array()
var ujang_path_index := 0
var ujang_path_target := Vector2.INF
var ujang_layout_snapshot := ""
var ujang_navigation_grid: AStarGrid2D
var ujang_navigation_snapshot := ""
var chopping_tree := -1
var chop_progress := 0.0
var terrain_contours: Array[PackedVector2Array] = []
var terrain_insets: Array[PackedVector2Array] = []
var visual_feedback: Array[Dictionary] = []
var delivery_elapsed := -1.0
var panel_obscured := false
# Small Android renderers struggle with thousands of tiny decorative strokes.
# Keep the same layout, production buildings, crops and touch targets, while
# drawing fewer purely ambient grass/flower primitives on mobile.
var mobile_scenery_lite := OS.get_name() == "Android"
var mobile_draw_profile_index := 0
var scenery_only := false
var scenery_chunk_origin := Vector2.ZERO
var scenery_cache_root: Control
var scenery_chunks: Dictionary = {}
var scenery_capture_viewports: Dictionary = {}
var scenery_chunk_versions: Dictionary = {}
var scenery_revision := 0
var scenery_last_unlocked_count := -1
var scenery_last_visible_chunks := Rect2i()
var scenery_last_synced_revision := -1
var scenery_cache_sync_rebuild_count := 0
var buildings_only := false
var mobile_building_layer: FarmView
var mobile_building_signature := ""
var world_details_only := false
var mobile_world_details_layer: FarmView
var mobile_world_details_signature := ""
var mobile_world_details_redraw_count := 0
var ready_markers_only := false
var mobile_ready_markers_layer: FarmView
var mobile_ready_markers_signature := ""
var mobile_ready_markers_redraw_count := 0
var plot_cache_root: Control
var plot_caches: Array[FarmView] = []
var plot_capture_viewports: Array[SubViewport] = []
var plot_texture_caches: Array[TextureRect] = []
var plot_cache_signatures: Array[String] = []
var plot_cache_redraw_count := 0
var mobile_selected_plot_outline: FarmView
var plot_cache_timer := 0.0
var plot_render_only := false
var plot_render_index := -1
var plot_selection_only := false
var animation_only := false
var windmill_blades_only := false
var visitor_render_only := false
var ujang_render_only := false
var truck_render_only := false
var animation_source: FarmView
var mobile_animation_overlay: FarmView
var mobile_windmill_blades: FarmView
var mobile_animation_was_active := false
var mobile_visitor_layer: FarmView
var mobile_visitor_signature := ""
var mobile_ujang_layer: FarmView
var mobile_ujang_signature := ""
var mobile_ujang_redraw_timer := 0.0
var mobile_truck_layer: FarmView
var mobile_truck_signature := ""
var mobile_truck_redraw_timer := 0.0
var mobile_truck_redraw_count := 0
var mobile_livestock_overlay: FarmView
var livestock_only := false
var animal_render_only := false
var butterfly_render_only := false
var animal_kind := ""
var animal_scale := 1.0
var animal_walking := false
var animal_phase := 0.0
var mobile_animals: Array[Dictionary] = []
var mobile_butterflies: Array[Dictionary] = []
var animal_capture_viewports: Array[SubViewport] = []
var animal_frame_textures: Dictionary = {}
var live_paint_timer := 0.0
var ellipse_unit_cache: Dictionary = {}
var mobile_animation_profile_frames := 0
var mobile_animation_profile_total_us := 0
var mobile_animation_profile_setup_us := 0
var mobile_animation_profile_ujang_us := 0
var mobile_animation_profile_ready_us := 0
var mobile_animation_profile_character_us := 0
var mobile_animation_profile_visitor_us := 0
var mobile_animation_profile_feedback_us := 0
var mobile_tick_profile_frames := 0
var mobile_tick_profile_us := PackedInt64Array([0, 0, 0, 0, 0, 0, 0])


func _ready() -> void:
	if animation_only or windmill_blades_only or visitor_render_only or ujang_render_only or truck_render_only or livestock_only or animal_render_only or butterfly_render_only or plot_render_only or plot_selection_only or buildings_only or world_details_only or ready_markers_only:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)
		return
	if scenery_only:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		prepare_terrain_contours()
		set_process(false)
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	prepare_terrain_contours()
	set_process(true)
	reset_camera()
	if mobile_scenery_lite:
		scenery_cache_root = Control.new()
		scenery_cache_root.name = "SceneryCache"
		scenery_cache_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scenery_cache_root.show_behind_parent = true
		scenery_cache_root.size = WORLD_SIZE
		add_child(scenery_cache_root)
		scenery_last_unlocked_count = unlocked_count()
		sync_scenery_cache()
		# Retain buildings and owned constructions in world coordinates. Camera
		# movement transforms the cache without rebuilding expensive geometry.
		mobile_building_layer = FarmView.new()
		mobile_building_layer.name = "RetainedFarmBuildings"
		mobile_building_layer.game = game
		mobile_building_layer.buildings_only = true
		mobile_building_layer.mobile_scenery_lite = true
		mobile_building_layer.size = WORLD_SIZE
		mobile_building_layer.show_behind_parent = true
		add_child(mobile_building_layer)
		sync_mobile_building_layer()
		# The depot, orchard and sign drawings contain expensive vector geometry.
		# Keep them in world space and invalidate only for orchard/mission changes.
		mobile_world_details_layer = FarmView.new()
		mobile_world_details_layer.name = "RetainedWorldDetails"
		mobile_world_details_layer.game = game
		mobile_world_details_layer.world_details_only = true
		mobile_world_details_layer.mobile_scenery_lite = true
		mobile_world_details_layer.size = WORLD_SIZE
		mobile_world_details_layer.show_behind_parent = true
		add_child(mobile_world_details_layer)
		sync_mobile_world_details()
		plot_cache_root = Control.new()
		plot_cache_root.name = "RetainedFarmPlots"
		plot_cache_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plot_cache_root.size = WORLD_SIZE
		add_child(plot_cache_root)
		for index in game.plots.size():
			# Each crop is expensive vector art. Render it once to a small texture,
			# then move the texture while panning instead of replaying its geometry.
			var capture := SubViewport.new()
			capture.name = "PlotCapture_%02d" % index
			capture.size = PLOT_CACHE_TEXTURE_SIZE
			capture.transparent_bg = true
			capture.disable_3d = true
			capture.render_target_update_mode = SubViewport.UPDATE_DISABLED
			plot_cache_root.add_child(capture)
			var plot_view := FarmView.new()
			plot_view.name = "Plot_%02d" % index
			plot_view.game = game
			plot_view.plot_render_only = true
			plot_view.plot_render_index = index
			plot_view.size = Vector2.ONE
			plot_view.position = PLOT_CACHE_TEXTURE_CENTER
			capture.add_child(plot_view)
			var tile := TextureRect.new()
			tile.name = "PlotTile_%02d" % index
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.texture = capture.get_texture()
			tile.size = Vector2(PLOT_CACHE_TEXTURE_SIZE)
			plot_cache_root.add_child(tile)
			plot_caches.append(plot_view)
			plot_capture_viewports.append(capture)
			plot_texture_caches.append(tile)
			plot_cache_signatures.append("")
		# Animate the selected bed by changing the alpha of one retained outline.
		# The crop SubViewports no longer redraw four times a second for this pulse.
		mobile_selected_plot_outline = FarmView.new()
		mobile_selected_plot_outline.name = "RetainedSelectedPlotOutline"
		mobile_selected_plot_outline.game = game
		mobile_selected_plot_outline.plot_selection_only = true
		mobile_selected_plot_outline.size = Vector2(180, 112)
		mobile_selected_plot_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plot_cache_root.add_child(mobile_selected_plot_outline)
		sync_mobile_plot_cache(true)
		mobile_livestock_overlay = FarmView.new()
		mobile_livestock_overlay.name = "LiveFarmAnimals"
		mobile_livestock_overlay.game = game
		mobile_livestock_overlay.mobile_scenery_lite = true
		mobile_livestock_overlay.livestock_only = true
		mobile_livestock_overlay.animation_source = self
		add_child(mobile_livestock_overlay)
		mobile_livestock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Share eight pre-rendered poses per species between all moving animals.
		# Each visible animal is one textured quad rather than ~30 vector draws.
		create_mobile_animal_frames()
		add_mobile_animal("chicken", "ayam", Vector2(-68, 144), 0.68, 1.0, Vector2(14, 8), 0.18)
		add_mobile_animal("cow", "sapi", Vector2(408, 1241) - default_position("sapi"), 0.48, 1.2, Vector2(9, 6), 0.25)
		add_mobile_animal("cow", "sapi", Vector2(617, 1250) - default_position("sapi"), 0.40, 3.8, Vector2(7, 5), 0.25)
		# Butterfly wings are drawn once, then moved and scaled via CanvasItem
		# transforms. They no longer repaint the full livestock overlay at 8-15 FPS.
		add_mobile_butterfly(Vector2(845, 1220), 1.1)
		add_mobile_butterfly(Vector2(1520, 1260), 3.4)
		add_mobile_butterfly(Vector2(1740, 1480), 5.5)
		mobile_animation_overlay = FarmView.new()
		mobile_animation_overlay.name = "LiveFarmAnimation"
		mobile_animation_overlay.game = game
		mobile_animation_overlay.mobile_scenery_lite = true
		mobile_animation_overlay.animation_only = true
		mobile_animation_overlay.animation_source = self
		add_child(mobile_animation_overlay)
		mobile_animation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# The four blades have static draw commands. Rotate their CanvasItem
		# instead of rebuilding the whole 20 FPS animation overlay at idle.
		mobile_windmill_blades = FarmView.new()
		mobile_windmill_blades.name = "RetainedWindmillBlades"
		mobile_windmill_blades.game = game
		mobile_windmill_blades.windmill_blades_only = true
		mobile_windmill_blades.size = Vector2.ONE
		mobile_animation_overlay.add_child(mobile_windmill_blades)
		update_mobile_windmill_blades()
		# The five production badges are nearly static. Retain their bubble
		# geometry and move the entire layer to create the gentle idle bob.
		mobile_ready_markers_layer = FarmView.new()
		mobile_ready_markers_layer.name = "RetainedReadyMarkers"
		mobile_ready_markers_layer.game = game
		mobile_ready_markers_layer.ready_markers_only = true
		mobile_ready_markers_layer.size = WORLD_SIZE
		add_child(mobile_ready_markers_layer)
		sync_mobile_ready_markers()
		# Keep the detailed delivery truck cached between dispatches. Camera pans
		# and truck travel move its CanvasItem without rebuilding the parked sprite.
		mobile_truck_layer = FarmView.new()
		mobile_truck_layer.name = "RetainedDeliveryTruck"
		mobile_truck_layer.game = game
		mobile_truck_layer.truck_render_only = true
		mobile_truck_layer.size = Vector2.ONE
		add_child(mobile_truck_layer)
		sync_mobile_truck_layer(0.0)
		# Ujang's body is retained while his position follows the patrol path every
		# frame; only leg and axe poses need occasional vector repaints.
		mobile_ujang_layer = FarmView.new()
		mobile_ujang_layer.name = "RetainedFarmWorker"
		mobile_ujang_layer.game = game
		mobile_ujang_layer.ujang_render_only = true
		mobile_ujang_layer.size = Vector2.ONE
		add_child(mobile_ujang_layer)
		sync_mobile_ujang_layer(0.0)
		# The visiting neighbor's detailed drawing remains in a single CanvasItem.
		# Moving it for camera pans and idle bobbing costs no vector repaint.
		mobile_visitor_layer = FarmView.new()
		mobile_visitor_layer.name = "RetainedFarmVisitor"
		mobile_visitor_layer.game = game
		mobile_visitor_layer.visitor_render_only = true
		mobile_visitor_layer.size = Vector2.ONE
		add_child(mobile_visitor_layer)
		sync_mobile_visitor_layer()


func animal_frame_key(kind: String, walking: bool, pose: int) -> String:
	return "%s_%d_%d" % [kind, int(walking), pose]


func create_mobile_animal_frames() -> void:
	for kind in ["chicken", "cow"]:
		for walking in [false, true]:
			for pose in ANIMAL_CACHE_POSES:
				var capture := SubViewport.new()
				capture.name = "AnimalCapture_%s_%d_%d" % [kind, int(walking), pose]
				capture.size = ANIMAL_CACHE_TEXTURE_SIZE
				capture.transparent_bg = true
				capture.disable_3d = true
				capture.render_target_update_mode = SubViewport.UPDATE_ONCE
				var painter := FarmView.new()
				painter.name = "AnimalPosePainter"
				painter.game = game
				painter.animal_render_only = true
				painter.animal_kind = kind
				painter.animal_scale = 1.0
				painter.animal_walking = walking
				painter.animal_phase = float(pose) * TAU / float(ANIMAL_CACHE_POSES)
				painter.shimmer = float(pose) * 0.63
				painter.position = ANIMAL_CACHE_TEXTURE_CENTER
				capture.add_child(painter)
				add_child(capture)
				animal_capture_viewports.append(capture)
				animal_frame_textures[animal_frame_key(kind, walking, pose)] = capture.get_texture()


func add_mobile_animal(
	kind: String, anchor: String, offset: Vector2, art_scale: float,
	seed: float, radius: Vector2, redraw_interval: float
) -> void:
	var body := Sprite2D.new()
	body.name = "Retained_%s_%d" % [kind, mobile_animals.size()]
	body.centered = false
	body.offset = -ANIMAL_CACHE_TEXTURE_CENTER
	body.texture = animal_frame_textures[animal_frame_key(kind, false, 0)]
	mobile_livestock_overlay.add_child(body)
	mobile_animals.append({
		"node": body, "anchor": anchor, "offset": offset,
		"kind": kind, "art_scale": art_scale,
		"seed": seed, "radius": radius, "interval": redraw_interval,
		"timer": redraw_interval,
	})


func add_mobile_butterfly(anchor: Vector2, seed: float) -> void:
	var body := FarmView.new()
	body.name = "RetainedButterfly_%d" % mobile_butterflies.size()
	body.game = game
	body.butterfly_render_only = true
	body.size = Vector2.ONE
	mobile_livestock_overlay.add_child(body)
	mobile_butterflies.append({"node": body, "anchor": anchor, "seed": seed})


func update_mobile_butterflies() -> void:
	if mobile_butterflies.is_empty():
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	var visible_world := visible_world_rect(190.0)
	for butterfly in mobile_butterflies:
		var body: FarmView = butterfly["node"]
		var anchor: Vector2 = butterfly["anchor"]
		body.visible = visible_world.has_point(anchor)
		if not body.visible:
			continue
		var seed: float = butterfly["seed"]
		var flutter := anchor + Vector2(sin(shimmer * 1.4 + seed) * 21.0, cos(shimmer * 1.8 + seed) * 15.0)
		var wing_factor := (3.0 + 6.0 * absf(sin(shimmer * 11.0 + seed))) / 9.0
		body.position = (view_size * 0.5 - camera_center * camera_zoom + flutter * camera_zoom) * scaler
		body.scale = Vector2(wing_factor * camera_zoom * scaler.x, camera_zoom * scaler.y)


func update_mobile_windmill_blades() -> void:
	if mobile_windmill_blades == null:
		return
	var hub := Vector2(1860, 285)
	mobile_windmill_blades.visible = game.has_construction("kincir_angin") and visible_world_rect(120.0).has_point(hub)
	if not mobile_windmill_blades.visible:
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	mobile_windmill_blades.position = (view_size * 0.5 - camera_center * camera_zoom + hub * camera_zoom) * scaler
	mobile_windmill_blades.scale = scaler * camera_zoom
	mobile_windmill_blades.rotation = shimmer * 0.8


func mobile_animation_is_active() -> bool:
	if swipe_active and not swipe_indices.is_empty():
		return true
	if not edit_mode and guide_plot_index >= 0 and guide_plot_index < game.plots.size():
		if visible_world_rect(190.0).has_point(plot_center(guide_plot_index)):
			return true
	if chopping_tree >= 0 and visible_world_rect(190.0).has_point(WILD_TREES[chopping_tree]):
		return true
	return not visual_feedback.is_empty()


func update_mobile_animals(delta: float) -> void:
	if mobile_animals.is_empty():
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	var visible_world := visible_world_rect(190.0)
	for animal in mobile_animals:
		var body: Sprite2D = animal["node"]
		var motion := LivestockPainter.animal_motion(self, float(animal["seed"]), animal["radius"])
		var position: Vector2 = object_position(String(animal["anchor"])) + animal["offset"] + motion["offset"]
		var on_screen := visible_world.has_point(position)
		var became_visible := on_screen and not body.visible
		body.visible = on_screen
		if not on_screen:
			continue
		body.position = (view_size * 0.5 - camera_center * camera_zoom + position * camera_zoom) * scaler
		var art_scale: float = animal["art_scale"]
		body.scale = Vector2(
			float(motion["facing"]) * camera_zoom * scaler.x * art_scale,
			camera_zoom * scaler.y * art_scale
		)
		animal["timer"] = float(animal["timer"]) + delta
		if float(animal["timer"]) >= float(animal["interval"]) or became_visible:
			var pose := wrapi(floori(float(motion["phase"]) * float(ANIMAL_CACHE_POSES) / TAU), 0, ANIMAL_CACHE_POSES)
			body.texture = animal_frame_textures[animal_frame_key(
				String(animal["kind"]), bool(motion["walking"]), pose
			)]
			animal["timer"] = 0.0


func invalidate_scenery() -> void:
	# Live layout edits and chopped trees change which ambient props are visible.
	scenery_revision += 1


func sync_scenery_cache() -> void:
	if scenery_cache_root == null:
		return
	var count := unlocked_count()
	if count != scenery_last_unlocked_count:
		scenery_last_unlocked_count = count
		invalidate_scenery()
	var view_size := get_virtual_size()
	var scaler := size / view_size
	scenery_cache_root.position = (view_size * 0.5 - camera_center * camera_zoom) * scaler
	scenery_cache_root.scale = Vector2.ONE * camera_zoom * scaler
	var visible := visible_world_rect(220.0)
	var from_x := maxi(0, floori(visible.position.x / SCENERY_CACHE_CHUNK_SIZE))
	var from_y := maxi(0, floori(visible.position.y / SCENERY_CACHE_CHUNK_SIZE))
	var to_x := mini(ceili(WORLD_SIZE.x / SCENERY_CACHE_CHUNK_SIZE) - 1, floori(visible.end.x / SCENERY_CACHE_CHUNK_SIZE))
	var to_y := mini(ceili(WORLD_SIZE.y / SCENERY_CACHE_CHUNK_SIZE) - 1, floori(visible.end.y / SCENERY_CACHE_CHUNK_SIZE))
	# Only the root transform depends on sub-chunk camera movement. Rebuilding
	# the visible-set dictionary every frame is unnecessary until the camera
	# crosses a chunk boundary or a layout change invalidates the scenery.
	var visible_chunks := Rect2i(from_x, from_y, maxi(0, to_x - from_x + 1), maxi(0, to_y - from_y + 1))
	if scenery_last_visible_chunks == visible_chunks and scenery_last_synced_revision == scenery_revision:
		return
	scenery_last_visible_chunks = visible_chunks
	scenery_last_synced_revision = scenery_revision
	scenery_cache_sync_rebuild_count += 1
	var needed: Dictionary = {}
	for y in range(from_y, to_y + 1):
		for x in range(from_x, to_x + 1):
			var key := Vector2i(x, y)
			needed[key] = true
			var chunk: TextureRect
			if not scenery_chunks.has(key):
				# One viewport render turns thousands of static vector draw commands
				# into one textured quad in every subsequent frame on Android.
				var capture := SubViewport.new()
				capture.name = "SceneryCapture_%d_%d" % [x, y]
				capture.size = Vector2i.ONE * SCENERY_CACHE_CHUNK_SIZE
				capture.transparent_bg = true
				capture.disable_3d = true
				capture.render_target_update_mode = SubViewport.UPDATE_ONCE
				var painter := FarmView.new()
				painter.name = "SceneryPainter"
				painter.game = game
				painter.scenery_only = true
				painter.animation_source = self
				painter.mobile_scenery_lite = true
				painter.scenery_chunk_origin = Vector2(x, y) * SCENERY_CACHE_CHUNK_SIZE
				painter.size = Vector2.ONE * SCENERY_CACHE_CHUNK_SIZE
				painter.camera_zoom = 1.0
				capture.add_child(painter)
				scenery_cache_root.add_child(capture)
				chunk = TextureRect.new()
				chunk.name = "Scenery_%d_%d" % [x, y]
				chunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
				chunk.position = painter.scenery_chunk_origin
				chunk.size = Vector2.ONE * SCENERY_CACHE_CHUNK_SIZE
				chunk.texture = capture.get_texture()
				scenery_cache_root.add_child(chunk)
				scenery_chunks[key] = chunk
				scenery_capture_viewports[key] = capture
				scenery_chunk_versions[key] = scenery_revision
			else:
				chunk = scenery_chunks[key]
				if scenery_chunk_versions[key] != scenery_revision:
					var viewport: SubViewport = scenery_capture_viewports[key]
					(viewport.get_child(0) as FarmView).queue_redraw()
					viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
					scenery_chunk_versions[key] = scenery_revision
			chunk.visible = true
	for key in scenery_chunks:
		if not needed.has(key):
			(scenery_chunks[key] as TextureRect).visible = false
	# Each 800px SubViewport retains an RGBA render texture. A long camera
	# journey must not leave all map chunks allocated on Android. Keep a small
	# nearby reserve to avoid rebuilding textures at every camera boundary.
	while scenery_chunks.size() > maxi(SCENERY_CACHE_MAX_CHUNKS, needed.size()):
		var farthest_key := Vector2i(-1, -1)
		var farthest_distance := -1.0
		for key in scenery_chunks.keys():
			if needed.has(key):
				continue
			var center := (Vector2(key) + Vector2(0.5, 0.5)) * SCENERY_CACHE_CHUNK_SIZE
			var distance := center.distance_squared_to(visible.get_center())
			if distance > farthest_distance:
				farthest_distance = distance
				farthest_key = key
		if farthest_distance < 0.0:
			break
		(scenery_chunks[farthest_key] as TextureRect).queue_free()
		(scenery_capture_viewports[farthest_key] as SubViewport).queue_free()
		scenery_chunks.erase(farthest_key)
		scenery_capture_viewports.erase(farthest_key)
		scenery_chunk_versions.erase(farthest_key)


func sync_mobile_building_layer() -> void:
	if mobile_building_layer == null:
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	mobile_building_layer.position = (view_size * 0.5 - camera_center * camera_zoom) * scaler
	mobile_building_layer.scale = Vector2.ONE * camera_zoom * scaler
	var signature := "%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		str(game.layout_positions), str(game.constructions), str(edit_mode), str(game.production_ready()),
		str(game.cow_is_hungry()), str(game.cow_milk_ready()),
		drag_key, str(drag_preview) if drag_key != "" else "", str(game.decorations)
	]
	if signature != mobile_building_signature:
		mobile_building_layer.edit_mode = edit_mode
		mobile_building_layer.drag_key = drag_key
		mobile_building_layer.drag_preview = drag_preview
		mobile_building_layer.queue_redraw()
		mobile_building_signature = signature


func sync_mobile_world_details() -> void:
	if mobile_world_details_layer == null:
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	mobile_world_details_layer.position = (view_size * 0.5 - camera_center * camera_zoom) * scaler
	mobile_world_details_layer.scale = Vector2.ONE * camera_zoom * scaler
	var now := game.now()
	var has_growing_tree := false
	for index in FarmGameState.ORCHARD_SIZE:
		if game.orchard[index]["fruit"] != "" and not game.tree_ready(index, now):
			has_growing_tree = true
	var signature := "%s|%d|%d" % [
		str(game.orchard), game.daily_claimed_count(), now if has_growing_tree else 0
	]
	if signature != mobile_world_details_signature:
		mobile_world_details_layer.queue_redraw()
		mobile_world_details_signature = signature
		mobile_world_details_redraw_count += 1


func sync_mobile_ready_markers() -> void:
	if mobile_ready_markers_layer == null:
		return
	var scaler := size / get_virtual_size()
	var bob := sin(shimmer * 2.8) * 4.0
	mobile_ready_markers_layer.position = (
		get_virtual_size() * 0.5 - camera_center * camera_zoom + Vector2(0, bob) * camera_zoom
	) * scaler
	mobile_ready_markers_layer.scale = Vector2.ONE * camera_zoom * scaler
	# Ready states, placement and edit mode determine the actual badge shapes.
	# Camera movement and the idle bob only modify the CanvasItem transform.
	var signature := "%s|%s|%s|%s|%s|%s|%s" % [
		str(edit_mode), str(game.layout_positions),
		str(ready_marker_active("dapur")), str(ready_marker_active("pakan")),
		str(ready_marker_active("sapi")), str(ready_marker_active("babi")),
		str(ready_marker_active("kambing"))
	]
	if signature != mobile_ready_markers_signature:
		mobile_ready_markers_layer.edit_mode = edit_mode
		mobile_ready_markers_layer.queue_redraw()
		mobile_ready_markers_signature = signature
		mobile_ready_markers_redraw_count += 1


func sync_mobile_visitor_layer() -> void:
	if mobile_visitor_layer == null:
		return
	var signature := str(game.visitor_request)
	var at := visitor_world_position()
	var on_screen := not game.visitor_request.is_empty() and visible_world_rect(130.0).has_point(at)
	var became_visible := on_screen and not mobile_visitor_layer.visible
	mobile_visitor_layer.visible = on_screen
	if not on_screen:
		mobile_visitor_signature = signature
		return
	var scaler := size / get_virtual_size()
	var bounce := sin(shimmer * 2.6) * 1.7
	mobile_visitor_layer.position = (get_virtual_size() * 0.5 + (at - camera_center) * camera_zoom + Vector2(0, bounce) * camera_zoom) * scaler
	mobile_visitor_layer.scale = Vector2.ONE * camera_zoom * scaler
	if signature != mobile_visitor_signature or became_visible:
		mobile_visitor_layer.queue_redraw()
		mobile_visitor_signature = signature


func sync_mobile_ujang_layer(delta: float) -> void:
	if mobile_ujang_layer == null:
		return
	var on_screen := visible_world_rect(155.0).has_point(ujang_position)
	var became_visible := on_screen and not mobile_ujang_layer.visible
	mobile_ujang_layer.visible = on_screen
	if not on_screen:
		return
	var scaler := size / get_virtual_size()
	mobile_ujang_layer.position = (
		get_virtual_size() * 0.5 + (ujang_position - camera_center) * camera_zoom
	) * scaler
	mobile_ujang_layer.scale = Vector2.ONE * camera_zoom * scaler
	var swinging := chopping_tree >= 0 and chop_progress > 0.0 and chop_progress < 1.2
	var signature := "%s|%s|%s" % [str(ujang_walking), str(ujang_facing), str(swinging)]
	var is_animated := ujang_walking or swinging
	mobile_ujang_redraw_timer += delta
	var interval := 0.05 if swinging else 0.12
	if signature != mobile_ujang_signature or became_visible or (is_animated and mobile_ujang_redraw_timer >= interval):
		mobile_ujang_layer.shimmer = shimmer
		mobile_ujang_layer.ujang_walking = ujang_walking
		mobile_ujang_layer.ujang_facing = ujang_facing
		mobile_ujang_layer.chopping_tree = chopping_tree
		mobile_ujang_layer.chop_progress = chop_progress
		mobile_ujang_layer.queue_redraw()
		mobile_ujang_signature = signature
		mobile_ujang_redraw_timer = 0.0


func sync_mobile_truck_layer(delta: float) -> void:
	if mobile_truck_layer == null:
		return
	var at := delivery_truck_position()
	var travelling_out_of_view := delivery_elapsed >= 2.85 and delivery_elapsed < 3.75
	var on_screen := not travelling_out_of_view and visible_world_rect(190.0).has_point(at)
	var became_visible := on_screen and not mobile_truck_layer.visible
	mobile_truck_layer.visible = on_screen
	if not on_screen:
		return
	var scaler := size / get_virtual_size()
	mobile_truck_layer.position = (
		get_virtual_size() * 0.5 + (at - camera_center) * camera_zoom
	) * scaler
	mobile_truck_layer.scale = Vector2.ONE * camera_zoom * scaler
	var rolling := delivery_elapsed >= 0.0
	var facing := -1.0 if delivery_elapsed >= 3.75 else 1.0
	var signature := "%s|%s" % [str(rolling), str(facing)]
	mobile_truck_redraw_timer += delta
	if signature != mobile_truck_signature or became_visible or (rolling and mobile_truck_redraw_timer >= 0.05):
		mobile_truck_layer.delivery_elapsed = delivery_elapsed
		mobile_truck_layer.shimmer = shimmer
		mobile_truck_layer.queue_redraw()
		mobile_truck_signature = signature
		mobile_truck_redraw_timer = 0.0
		mobile_truck_redraw_count += 1


func sync_mobile_plot_cache(check_state: bool) -> void:
	if plot_cache_root == null:
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	plot_cache_root.position = (view_size * 0.5 - camera_center * camera_zoom) * scaler
	plot_cache_root.scale = Vector2.ONE * camera_zoom * scaler
	var visible_world := visible_world_rect(160.0)
	if mobile_selected_plot_outline != null:
		var valid_selection := selected_plot >= 0 and selected_plot < game.plots.size()
		mobile_selected_plot_outline.visible = valid_selection and visible_world.has_point(plot_center(selected_plot)) if valid_selection else false
		if valid_selection:
			mobile_selected_plot_outline.position = plot_center(selected_plot) - Vector2(90, 56)
			mobile_selected_plot_outline.modulate.a = 0.65 + 0.24 * sin(shimmer * 4.1)
	var now := game.now() if check_state else 0
	for index in plot_caches.size():
		var plot_view := plot_caches[index]
		var tile := plot_texture_caches[index]
		var capture := plot_capture_viewports[index]
		tile.position = plot_center(index) - PLOT_CACHE_TEXTURE_CENTER
		var on_screen := visible_world.has_point(plot_center(index))
		var became_visible := on_screen and not tile.visible
		tile.visible = on_screen
		if not on_screen or (not check_state and not became_visible):
			continue
		var plot: Dictionary = game.plots[index]
		var crop: String = plot["crop"]
		var growing_tick := 0
		if crop != "" and not game.is_ready(index):
			growing_tick = int(now / 2) if check_state else -1
		var signature := "%s|%s|%s|%s|%s|%d" % [
			str(plot["unlocked"]), crop, str(plot["planted_at"]),
			str(plot["ready_at"]), str(game.is_ready(index)), growing_tick
		]
		if signature != plot_cache_signatures[index] or became_visible:
			plot_view.shimmer = shimmer
			plot_view.queue_redraw()
			capture.render_target_update_mode = SubViewport.UPDATE_ONCE
			plot_cache_signatures[index] = signature
			plot_cache_redraw_count += 1


func _process(delta: float) -> void:
	var profile_start := Time.get_ticks_usec() if mobile_scenery_lite and OS.has_feature("debug") else 0
	shimmer += delta
	if delivery_elapsed >= 0.0:
		delivery_elapsed += delta
		if delivery_elapsed >= DELIVERY_ANIMATION_SECONDS:
			delivery_elapsed = -1.0
	# Short-lived VFX share the existing 20 FPS idle redraw schedule.
	for index in range(visual_feedback.size() - 1, -1, -1):
		visual_feedback[index]["age"] = float(visual_feedback[index]["age"]) + delta
		if float(visual_feedback[index]["age"]) >= float(visual_feedback[index]["duration"]):
			visual_feedback.remove_at(index)
	# A full isometric redraw is expensive on mobile. Keep the previously
	# painted farm behind modal sheets and resume animation on return.
	# Active tree-chopping still advances so changing tabs cannot stall it.
	if panel_obscured:
		if chopping_tree >= 0:
			update_ujang(delta)
		return
	update_ujang(delta)
	var profile_ujang := Time.get_ticks_usec() if profile_start > 0 else 0
	clamp_camera_target()
	var moving := (
		camera_center.distance_to(camera_target) > 0.3 or absf(camera_zoom - zoom_target) > 0.0003
	)
	var factor := 1.0 - exp(-delta * 12.0)
	camera_center = camera_center.lerp(camera_target, factor)
	camera_zoom = lerpf(camera_zoom, zoom_target, factor)
	camera_center = clamp_camera_center(camera_center, camera_zoom)
	var profile_camera := Time.get_ticks_usec() if profile_start > 0 else 0
	if mobile_scenery_lite:
		sync_scenery_cache()
		var profile_scenery := Time.get_ticks_usec() if profile_start > 0 else 0
		sync_mobile_building_layer()
		sync_mobile_world_details()
		sync_mobile_ready_markers()
		var profile_static := Time.get_ticks_usec() if profile_start > 0 else 0
		sync_mobile_visitor_layer()
		sync_mobile_ujang_layer(delta)
		sync_mobile_truck_layer(delta)
		var profile_actors := Time.get_ticks_usec() if profile_start > 0 else 0
		plot_cache_timer += delta
		var check_plots := plot_cache_timer >= 0.25
		sync_mobile_plot_cache(check_plots)
		if check_plots:
			plot_cache_timer = 0.0
		if profile_start > 0:
			var profile_plots := Time.get_ticks_usec()
			mobile_tick_profile_us[0] += profile_ujang - profile_start
			mobile_tick_profile_us[1] += profile_camera - profile_ujang
			mobile_tick_profile_us[2] += profile_scenery - profile_camera
			mobile_tick_profile_us[3] += profile_static - profile_scenery
			mobile_tick_profile_us[4] += profile_actors - profile_static
			mobile_tick_profile_us[5] += profile_plots - profile_actors
			mobile_tick_profile_us[6] += profile_plots - profile_start
			mobile_tick_profile_frames += 1
			if mobile_tick_profile_frames >= 120:
				print("KEBUN_TICK avg_ms=%.2f ujang=%.2f camera=%.2f scenery=%.2f static=%.2f actors=%.2f plots=%.2f" % [
					float(mobile_tick_profile_us[6]) / (1000.0 * mobile_tick_profile_frames),
					float(mobile_tick_profile_us[0]) / (1000.0 * mobile_tick_profile_frames),
					float(mobile_tick_profile_us[1]) / (1000.0 * mobile_tick_profile_frames),
					float(mobile_tick_profile_us[2]) / (1000.0 * mobile_tick_profile_frames),
					float(mobile_tick_profile_us[3]) / (1000.0 * mobile_tick_profile_frames),
					float(mobile_tick_profile_us[4]) / (1000.0 * mobile_tick_profile_frames),
					float(mobile_tick_profile_us[5]) / (1000.0 * mobile_tick_profile_frames)
				])
				mobile_tick_profile_frames = 0
				mobile_tick_profile_us.fill(0)
	paint_timer += delta
	# The world paint is far more expensive than UI on low-end Android GPUs.
	# Limit ambient animation updates while leaving the UI at native frame rate.
	# Static crops/buildings need updating only when state or the camera changes.
	# Moving characters and feedback use their own retained CanvasItem below.
	var paint_interval := (0.067 if moving else 0.90) if mobile_scenery_lite else (0.033 if moving else 0.05)
	if mobile_animation_overlay != null:
		update_mobile_windmill_blades()
		var animation_active := mobile_animation_is_active()
		if animation_active:
			live_paint_timer += delta
			if live_paint_timer >= 0.05:
				live_paint_timer = 0.0
				mobile_animation_overlay.queue_redraw()
		elif mobile_animation_was_active:
			# Clear the final drawn effect exactly once after it expires.
			mobile_animation_overlay.queue_redraw()
			live_paint_timer = 0.0
		mobile_animation_was_active = animation_active
	if mobile_livestock_overlay != null:
		update_mobile_animals(delta)
		update_mobile_butterflies()
	if paint_timer > paint_interval:
		paint_timer = 0.0
		queue_redraw()


func set_panel_obscured(obscured: bool) -> void:
	if panel_obscured == obscured:
		return
	panel_obscured = obscured
	paint_timer = 0.0
	if not panel_obscured:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_screen_touch(event)
		accept_event()
	elif event is InputEventScreenDrag:
		handle_screen_drag(event)
		accept_event()
	elif (
		event is InputEventMouseButton
		and pointers.is_empty()
		and event.device != InputEvent.DEVICE_ID_EMULATION
	):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_at(event.position, zoom_target * 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_at(event.position, zoom_target / 1.12)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_down = true
				mouse_dragged = false
				mouse_press_position = event.position
				if not edit_mode:
					begin_farm_swipe(event.position)
				if placement_decoration_key != "":
					update_decoration_preview(event.position)
				elif edit_mode:
					if road_tool == "draw" or road_tool == "erase":
						begin_road_stroke(event.position)
					elif road_tool == "object":
						begin_edit_drag(event.position)
			else:
				if placement_decoration_key != "":
					if not mouse_dragged:
						finish_decoration_placement(event.position)
				elif road_stroke_active:
					finish_road_stroke()
				elif edit_mode and drag_key != "":
					finish_edit_drag()
				elif swipe_active:
					finish_farm_swipe()
				elif mouse_down and not mouse_dragged and not edit_mode:
					activate_at(event.position)
				else:
					cancel_farm_swipe()
				mouse_down = false
		accept_event()
	elif (
		event is InputEventMouseMotion
		and mouse_down
		and pointers.is_empty()
		and event.device != InputEvent.DEVICE_ID_EMULATION
	):
		if event.position.distance_to(mouse_press_position) > DRAG_THRESHOLD:
			mouse_dragged = true
		if mouse_dragged:
			if road_stroke_active:
				extend_road_stroke(event.position)
			elif edit_mode and drag_key != "":
				move_edit_drag(event.position)
			elif swipe_mode != "":
				extend_farm_swipe(event.position)
			else:
				pan_by(event.relative)
		accept_event()
	elif event is InputEventMouseMotion and placement_decoration_key != "" and not mouse_down:
		update_decoration_preview(event.position)


func handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		pointers[event.index] = event.position
		if pointers.size() == 1:
			press_position = event.position
			gesture_dragged = false
			pinch_started = false
			if not edit_mode:
				begin_farm_swipe(event.position)
			if placement_decoration_key != "":
				update_decoration_preview(event.position)
			elif edit_mode:
				if road_tool == "draw" or road_tool == "erase":
					begin_road_stroke(event.position)
				elif road_tool == "object":
					begin_edit_drag(event.position)
		elif pointers.size() >= 2:
			finish_road_stroke()
			cancel_edit_drag()
			cancel_farm_swipe()
			pinch_distance = get_pinch_distance()
			pinch_started = true
			gesture_dragged = true
	else:
		var tap := pointers.size() == 1 and not gesture_dragged and not pinch_started
		if placement_decoration_key != "" and tap:
			finish_decoration_placement(event.position)
		elif road_stroke_active:
			finish_road_stroke()
		elif edit_mode and drag_key != "":
			finish_edit_drag()
		elif swipe_active and not pinch_started:
			finish_farm_swipe()
		else:
			cancel_farm_swipe()
		pointers.erase(event.index)
		if tap and not edit_mode:
			activate_at(event.position)
		if pointers.size() < 2:
			pinch_distance = 0.0
		if pointers.is_empty():
			pinch_started = false


func handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not pointers.has(event.index):
		return
	var previous: Vector2 = pointers[event.index]
	pointers[event.index] = event.position
	if pointers.size() >= 2:
		var distance := get_pinch_distance()
		if pinch_distance > 1.0 and distance > 1.0:
			zoom_at(get_pinch_midpoint(), zoom_target * distance / pinch_distance)
		pinch_distance = distance
		gesture_dragged = true
	elif pointers.size() == 1:
		if event.position.distance_to(press_position) > DRAG_THRESHOLD:
			gesture_dragged = true
		if gesture_dragged:
			if road_stroke_active:
				extend_road_stroke(event.position)
			elif edit_mode and drag_key != "":
				move_edit_drag(event.position)
			elif swipe_mode != "":
				extend_farm_swipe(event.position)
			else:
				pan_by(event.position - previous)


func plot_index_at(screen_at: Vector2) -> int:
	var at := screen_to_world(screen_at)
	for index in range(game.plots.size() - 1, -1, -1):
		var center := plot_center(index)
		if absf(at.x - center.x) / 74.0 + absf(at.y - center.y) / 40.0 <= 1.0:
			return index
	return -1


func begin_farm_swipe(screen_at: Vector2) -> void:
	cancel_farm_swipe()
	if edit_mode or game == null:
		return
	var index := plot_index_at(screen_at)
	if index < 0:
		return
	if game.is_ready(index):
		swipe_mode = "harvest"
	elif game.plots[index]["unlocked"] and game.plots[index]["crop"] == "":
		swipe_mode = "plant"
	swipe_last_position = screen_at


func extend_farm_swipe(screen_at: Vector2) -> void:
	if swipe_mode == "":
		return
	if not swipe_active:
		swipe_active = true
		collect_farm_swipe_segment(press_position if not pointers.is_empty() else mouse_press_position, screen_at)
	else:
		collect_farm_swipe_segment(swipe_last_position, screen_at)
	swipe_last_position = screen_at


func collect_farm_swipe_segment(from_screen: Vector2, to_screen: Vector2) -> void:
	# Sample between events so quick drags cannot skip narrow isometric plots.
	var samples := maxi(1, ceili(from_screen.distance_to(to_screen) / 8.0))
	for step in range(samples + 1):
		var index := plot_index_at(from_screen.lerp(to_screen, float(step) / float(samples)))
		if index >= 0 and not swipe_visited.has(index) and can_swipe_plot(index):
			swipe_visited[index] = true
			swipe_indices.append(index)
	if swipe_active:
		queue_redraw()


func can_swipe_plot(index: int) -> bool:
	if game == null or index < 0 or index >= game.plots.size():
		return false
	if swipe_mode == "harvest":
		return game.is_ready(index)
	if swipe_mode == "plant":
		return game.can_plant(index, game.selected_crop)
	return false


func finish_farm_swipe() -> void:
	if swipe_active and not swipe_indices.is_empty():
		farm_swipe_requested.emit(swipe_mode, swipe_indices)
	cancel_farm_swipe()


func cancel_farm_swipe() -> void:
	var had_preview := swipe_active and not swipe_indices.is_empty()
	swipe_mode = ""
	swipe_active = false
	swipe_indices = PackedInt32Array()
	swipe_visited.clear()
	if had_preview:
		queue_redraw()


func set_edit_mode(enabled: bool) -> void:
	finish_road_stroke()
	cancel_farm_swipe()
	edit_mode = enabled
	if not enabled:
		cancel_decoration_placement()
	road_tool = "object"
	cancel_edit_drag()
	edit_selected = ""
	queue_redraw()


func set_road_tool(tool: String) -> void:
	if not edit_mode or placement_decoration_key != "" or not ["object", "draw", "erase", "pan"].has(tool):
		return
	finish_road_stroke()
	cancel_edit_drag()
	road_tool = tool
	edit_selected = ""
	queue_redraw()


func begin_decoration_placement(key: String) -> void:
	var item := game.decoration_by_key(key)
	if item.is_empty() or not (item.get("position", []) as Array).is_empty():
		return
	set_edit_mode(true)
	placement_decoration_key = key
	placement_preview = camera_center.round()
	placement_snapped = false
	queue_redraw()


func cancel_decoration_placement() -> void:
	placement_decoration_key = ""
	placement_snapped = false
	queue_redraw()


func update_decoration_preview(screen_at: Vector2) -> void:
	if placement_decoration_key == "":
		return
	var raw := screen_to_world(screen_at).round()
	placement_preview = snap_edit_position(placement_decoration_key, raw)
	placement_snapped = placement_preview != raw
	queue_redraw()


func finish_decoration_placement(screen_at: Vector2) -> void:
	if placement_decoration_key == "":
		return
	update_decoration_preview(screen_at)
	var key := placement_decoration_key
	var at := placement_preview
	if not can_place(key, at):
		placement_rejected.emit()
		show_world_feedback("reject", at)
		return
	cancel_decoration_placement()
	decoration_placed.emit(key, at)
	show_world_feedback("move", at)


func road_cell_from_world(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / ROAD_GRID_SIZE), floori(at.y / ROAD_GRID_SIZE))


func road_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func road_segment_overlaps_rect(start: Vector2, finish: Vector2,
		footprint: Rect2, half_width: float) -> bool:
	# Road strokes are capsules. Expanding the rectangle is conservative near
	# corners, and includes both round endpoints and connecting road strokes.
	var expanded := footprint.grow(half_width)
	if expanded.has_point(start) or expanded.has_point(finish):
		return true
	var a := expanded.position
	var b := expanded.end
	return Geometry2D.segment_intersects_segment(start, finish, a,
			Vector2(b.x, a.y)) != null or \
		Geometry2D.segment_intersects_segment(start, finish, Vector2(b.x, a.y), b) != null or \
		Geometry2D.segment_intersects_segment(start, finish, b,
			Vector2(a.x, b.y)) != null or \
		Geometry2D.segment_intersects_segment(start, finish, Vector2(a.x, b.y), a) != null


func road_overlaps_rect(footprint: Rect2) -> bool:
	# Only roads explicitly placed by the player reserve land.
	if game == null:
		return false
	# Only inspect road tiles near this footprint, including neighboring links.
	var search := footprint.grow(float(ROAD_GRID_SIZE) + ROAD_HALF_WIDTH + 5.0)
	var from_cell := road_cell_from_world(search.position)
	var to_cell := road_cell_from_world(search.end)
	for y in range(from_cell.y, to_cell.y + 1):
		for x in range(from_cell.x, to_cell.x + 1):
			var cell := Vector2i(x, y)
			if not game.road_tiles.has(road_key(cell)):
				continue
			var center := road_visual_center(cell)
			if road_segment_overlaps_rect(center, center, footprint, ROAD_HALF_WIDTH):
				return true
			for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
				if game.road_tiles.has(road_key(cell + offset)) and \
						road_segment_overlaps_rect(center, road_visual_center(cell + offset),
							footprint, ROAD_HALF_WIDTH):
					return true
	return false


func road_surface_clear_of_objects(start: Vector2, finish: Vector2,
		half_width: float) -> bool:
	for key in editable_keys():
		var at := object_position(key)
		var half := object_half_size(key)
		if road_segment_overlaps_rect(start, finish,
				Rect2(at - half, half * 2.0), half_width):
			return false
	for index in WILD_TREES.size():
		if game.cleared_wild_trees.has(index):
			continue
		if road_segment_overlaps_rect(start, finish,
				Rect2(WILD_TREES[index] - Vector2(65, 138), Vector2(130, 154)),
				half_width):
			return false
	return true


func can_paint_road(cell: Vector2i) -> bool:
	var center := road_visual_center(cell)
	# Protect the border fence from the complete road width.
	if not accessible_world().grow(-50.0).has_point(center):
		return false
	if not road_surface_clear_of_objects(center, center, ROAD_HALF_WIDTH):
			return false
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if game.road_tiles.has(road_key(cell + offset)) and not \
				road_surface_clear_of_objects(center, road_visual_center(cell + offset), ROAD_HALF_WIDTH):
			return false
	return true


func paint_road_cell(cell: Vector2i) -> void:
	var key := road_key(cell)
	if road_tool == "erase":
		if game.road_tiles.erase(key):
			road_stroke_changed = true
	elif road_tool == "draw" and can_paint_road(cell):
		if not game.road_tiles.has(key):
			game.road_tiles[key] = true
			road_stroke_changed = true


func begin_road_stroke(screen_at: Vector2) -> void:
	if not edit_mode or not ["draw", "erase"].has(road_tool):
		return
	road_stroke_active = true
	road_stroke_changed = false
	road_last_cell = road_cell_from_world(screen_to_world(screen_at))
	paint_road_cell(road_last_cell)
	queue_redraw()


func extend_road_stroke(screen_at: Vector2) -> void:
	if not road_stroke_active:
		return
	var destination := road_cell_from_world(screen_to_world(screen_at))
	# Fill both axes at every step so fast diagonal swipes always connect.
	var cell := road_last_cell
	while cell != destination:
		if cell.x != destination.x:
			cell.x += 1 if cell.x < destination.x else -1
			paint_road_cell(cell)
		if cell.y != destination.y:
			cell.y += 1 if cell.y < destination.y else -1
			paint_road_cell(cell)
	road_last_cell = destination
	queue_redraw()


func finish_road_stroke() -> void:
	if not road_stroke_active:
		return
	road_stroke_active = false
	if road_stroke_changed:
		roads_changed.emit()
	road_stroke_changed = false
	queue_redraw()


func default_position(key: String) -> Vector2:
	if key.begins_with("scenery_"):
		var index := int(key.trim_prefix("scenery_"))
		if index >= 0 and index < MOVABLE_SCENERY.size():
			return MOVABLE_SCENERY[index][1]
	if key.begins_with("petak_"):
		var index := int(key.trim_prefix("petak_"))
		var col := index % 4
		var row := index / 4
		return Vector2(1060 + (col - row) * 100, 735 + (col + row) * 55)
	return OBJECT_DEFAULTS.get(key, Vector2.ZERO)


func object_position(key: String) -> Vector2:
	if key == drag_key:
		return drag_preview
	if key.begins_with("dekor_"):
		var position: Array = game.decoration_by_key(key).get("position", [])
		if position.size() == 2:
			return Vector2(float(position[0]), float(position[1]))
		return Vector2.ZERO
	var saved = game.layout_positions.get(key, null)
	if saved is Array and saved.size() == 2:
		return Vector2(float(saved[0]), float(saved[1]))
	return default_position(key)


func settled_object_position(key: String) -> Vector2:
	# Clearance must use committed positions: a dragged plot/building should
	# not hide scenery from editable_keys() and bypass collision checks.
	return drag_original if key == drag_key else object_position(key)


func scenery_visible_at(key: String, at: Vector2, footprint: Rect2) -> bool:
	if scenery_clear_of_farm(at, footprint):
		return true
	# Older landscaping was drawn when its ground anchor was clear, even if
	# the upper sprite extended near an orchard or another structure. Preserve
	# those existing arrangements, including saves created before scenery IDs.
	# New placements must satisfy the full footprint clearance in can_place().
	return at == default_position(key) and scenery_clear_of_farm(at) and \
		not road_overlaps_rect(footprint.grow(5.0))


func object_half_size(key: String) -> Vector2:
	if key.begins_with("scenery_"):
		var index := int(key.trim_prefix("scenery_"))
		if index >= 0 and index < MOVABLE_SCENERY.size():
			var width: float = MOVABLE_SCENERY[index][2]
			return Vector2(width * 0.43, width * 0.24)
	if key.begins_with("dekor_"):
		var kind := str(game.decoration_by_key(key).get("kind", ""))
		if FarmGameState.DECORATIONS.has(kind):
			return FarmGameState.DECORATIONS[kind]["half"]
	return Vector2(77, 43) if key.begins_with("petak_") else OBJECT_HALF_SIZES.get(key, Vector2(80, 80))


func editable_keys() -> Array[String]:
	var keys: Array[String] = ["sapi", "ayam", "dapur", "gudang", "pasar"]
	for index in game.plots.size():
		keys.append("petak_%d" % index)
	for index in FarmGameState.ORCHARD_SIZE:
		keys.append("buah_%d" % index)
	for pair in [["kandang_babi", "babi"], ["kandang_kambing", "kambing"],
		["toko_roti", "roti"], ["pabrik_susu", "susu"], ["pabrik_pakan", "pakan"]]:
		if game.has_construction(pair[0]):
			keys.append(pair[1])
	for index in MOVABLE_SCENERY.size():
		var key := "scenery_%d" % index
		var item: Array = MOVABLE_SCENERY[index]
		var at := object_position(key)
		if scenery_visible_at(key, at, farm_art.ground_bounds(str(item[0]), at, float(item[2]))):
			keys.append(key)
	for item in game.decorations:
		if (item.get("position", []) as Array).size() == 2:
			keys.append(str(item["key"]))
	return keys


func editable_at(at: Vector2) -> String:
	var keys := editable_keys()
	keys.reverse()
	for key in keys:
		var center := object_position(key)
		var radius := object_half_size(key)
		var delta := at - center
		if key.begins_with("scenery_"):
			var item: Array = MOVABLE_SCENERY[int(key.trim_prefix("scenery_"))]
			if farm_art.ground_bounds(str(item[0]), center, float(item[2])).has_point(at):
				return key
		elif key.begins_with("petak_"):
			if absf(delta.x) / radius.x + absf(delta.y) / radius.y <= 1.0:
				return key
		elif Rect2(center - radius, radius * 2.0).has_point(at):
			return key
	return ""


func can_place(key: String, at: Vector2) -> bool:
	var half := object_half_size(key)
	if key.begins_with("scenery_"):
		var item: Array = MOVABLE_SCENERY[int(key.trim_prefix("scenery_"))]
		if not scenery_clear_of_farm(at, farm_art.ground_bounds(str(item[0]), at, float(item[2]))):
			return false
	if not Rect2(Vector2(25, 25), WORLD_SIZE - Vector2(50, 50)).encloses(Rect2(at - half, half * 2.0)):
		return false
	if road_overlaps_rect(Rect2(at - half, half * 2.0)):
		return false
	for index in WILD_TREES.size():
		if game.cleared_wild_trees.has(index):
			continue
		var trunk: Vector2 = WILD_TREES[index]
		if Rect2(at - half, half * 2.0).intersects(Rect2(trunk - Vector2(34, 42), Vector2(68, 60))):
			return false
	for other in editable_keys():
		if other == key:
			continue
		var other_at := object_position(other)
		var other_half := object_half_size(other)
		if key.begins_with("petak_") and other.begins_with("petak_"):
			var delta := at - other_at
			if absf(delta.x) / (half.x + other_half.x) + absf(delta.y) / (half.y + other_half.y) < 1.02:
				return false
		elif Rect2(at - half, half * 2.0).intersects(Rect2(other_at - other_half, other_half * 2.0)):
			return false
	return true


func snap_edit_position(key: String, raw: Vector2) -> Vector2:
	# Snapping only affects the preview. Invalid targets never displace objects.
	if game == null:
		return raw
	var best := raw
	var best_distance := OBJECT_SNAP_DISTANCE * OBJECT_SNAP_DISTANCE
	var is_plot := key.begins_with("petak_")
	var is_scenery := key.begins_with("scenery_")
	var half := object_half_size(key)
	for other in editable_keys():
		if other == key or other.begins_with("petak_") != is_plot:
			continue
		# Existing scenery uses a separate alignment group so its many anchors
		# cannot unexpectedly shift players' buildings or purchased decorations.
		if other.begins_with("scenery_") != is_scenery:
			continue
		var other_at := object_position(other)
		if is_plot:
			# Align the diamonds along the farm's existing isometric rows.
			for offset in PLOT_SNAP_OFFSETS:
				var target: Vector2 = other_at + offset
				var distance := raw.distance_squared_to(target)
				if distance < best_distance and can_place(key, target):
					best = target
					best_distance = distance
			continue
		var other_half := object_half_size(other)
		var x_targets: Array[float] = []
		var y_targets: Array[float] = []
		# Nearby center lines help make tidy columns and rows.
		if absf(raw.y - other_at.y) < half.y + other_half.y + 190.0:
			x_targets.append(other_at.x)
		if absf(raw.x - other_at.x) < half.x + other_half.x + 190.0:
			y_targets.append(other_at.y)
		# Edge targets include a small visible gap between rectangular objects.
		if absf(raw.y - other_at.y) < half.y + other_half.y:
			x_targets.append(other_at.x - half.x - other_half.x - OBJECT_SNAP_GAP)
			x_targets.append(other_at.x + half.x + other_half.x + OBJECT_SNAP_GAP)
		if absf(raw.x - other_at.x) < half.x + other_half.x:
			y_targets.append(other_at.y - half.y - other_half.y - OBJECT_SNAP_GAP)
			y_targets.append(other_at.y + half.y + other_half.y + OBJECT_SNAP_GAP)
		# Prefer a valid two-axis alignment when both guides are close.
		for x in x_targets:
			if absf(raw.x - x) > OBJECT_SNAP_DISTANCE:
				continue
			for y in y_targets:
				if absf(raw.y - y) > OBJECT_SNAP_DISTANCE:
					continue
				var aligned := Vector2(x, y)
				if can_place(key, aligned):
					return aligned
		for x in x_targets:
			var candidate := Vector2(x, raw.y)
			var distance := raw.distance_squared_to(candidate)
			if distance < best_distance and can_place(key, candidate):
				best = candidate
				best_distance = distance
		for y in y_targets:
			var candidate := Vector2(raw.x, y)
			var distance := raw.distance_squared_to(candidate)
			if distance < best_distance and can_place(key, candidate):
				best = candidate
				best_distance = distance
	return best


func begin_edit_drag(screen_at: Vector2) -> void:
	# Read the stored/default position before enabling the drag preview.
	# object_position() returns the preview while drag_key is set.
	drag_key = ""
	var picked := editable_at(screen_to_world(screen_at))
	if picked == "":
		edit_selected = ""
		queue_redraw()
		return
	edit_selected = picked
	drag_original = object_position(picked)
	drag_key = picked
	drag_preview = drag_original
	drag_grab_offset = drag_original - screen_to_world(screen_at)
	drag_was_moved = false
	drag_snapped = false
	queue_redraw()


func move_edit_drag(screen_at: Vector2) -> void:
	if drag_key == "":
		return
	var raw := (screen_to_world(screen_at) + drag_grab_offset).round()
	drag_preview = snap_edit_position(drag_key, raw)
	drag_snapped = drag_preview != raw
	drag_was_moved = true
	queue_redraw()


func finish_edit_drag() -> void:
	if drag_key == "":
		return
	var key := drag_key
	var at := drag_preview
	var changed := drag_was_moved and at.distance_to(drag_original) > 1.0
	var valid := not changed or can_place(key, at)
	drag_key = ""
	drag_was_moved = false
	drag_snapped = false
	# One gesture moves one object. Deselect it on release so the next
	# gesture can immediately select another plot while ATUR stays active.
	edit_selected = ""
	if changed and valid:
		layout_changed.emit(key, at)
		show_world_feedback("move", at)
	elif changed:
		placement_rejected.emit()
		show_world_feedback("reject", at)
	queue_redraw()


func cancel_edit_drag() -> void:
	drag_key = ""
	drag_was_moved = false
	drag_snapped = false
	queue_redraw()


func get_pinch_distance() -> float:
	var keys := pointers.keys()
	return (pointers[keys[0]] as Vector2).distance_to(pointers[keys[1]])


func get_pinch_midpoint() -> Vector2:
	var keys := pointers.keys()
	return ((pointers[keys[0]] as Vector2) + (pointers[keys[1]] as Vector2)) * 0.5


func get_virtual_size() -> Vector2:
	# Use the full available height without stretching the map or its animals.
	return Vector2(VIRTUAL_SIZE.x, VIRTUAL_SIZE.x * maxf(size.y, 1.0) / maxf(size.x, 1.0))


func screen_to_world(screen_at: Vector2) -> Vector2:
	var view_size := get_virtual_size()
	var screen_virtual := screen_at * view_size / size
	return camera_center + (screen_virtual - view_size * 0.5) / camera_zoom


func pan_by(screen_delta: Vector2) -> void:
	camera_target -= screen_delta * get_virtual_size() / size / zoom_target
	clamp_camera_target()


func zoom_at(screen_at: Vector2, new_zoom: float) -> void:
	var view_size := get_virtual_size()
	var pivot := screen_at * view_size / size - view_size * 0.5
	var anchor := camera_target + pivot / zoom_target
	zoom_target = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	camera_target = anchor - pivot / zoom_target
	clamp_camera_target()


func reset_camera() -> void:
	# Frame the farmhouse, barn, chickens, plots and orchard together on mobile.
	camera_target = Vector2(930, 950)
	zoom_target = 0.62
	camera_center = clamp_camera_center(camera_target, zoom_target)
	camera_target = camera_center
	camera_zoom = zoom_target


func unlocked_count() -> int:
	if game == null:
		return 8
	var count := 0
	for plot in game.plots:
		if plot["unlocked"]:
			count += 1
	return count


func accessible_world() -> Rect2:
	var extra := maxi(0, unlocked_count() - 8)
	var margin := Vector2(200 - extra * 25, 130 - extra * 16)
	return Rect2(margin, WORLD_SIZE - margin * 2.0)


func clamp_camera_center(center: Vector2, zoom: float) -> Vector2:
	var bounds := accessible_world()
	var half_view := get_virtual_size() / (2.0 * zoom)
	var min_center := bounds.position + half_view
	var max_center := bounds.end - half_view
	# Tiny inner padding keeps float rounding from placing the camera outside
	# the accessible boundary at uncommon zoom ratios on mobile viewports.
	var epsilon := Vector2(0.1, 0.1)
	return Vector2(
		clampf(center.x, min_center.x + epsilon.x, maxf(min_center.x + epsilon.x, max_center.x - epsilon.x)),
		clampf(center.y, min_center.y + epsilon.y, maxf(min_center.y + epsilon.y, max_center.y - epsilon.y))
	)


func clamp_camera_target() -> void:
	camera_target = clamp_camera_center(camera_target, zoom_target)


func set_world_transform(offset := Vector2.ZERO) -> void:
	if scenery_only:
		draw_set_transform(offset + draw_offset - scenery_chunk_origin, 0.0, Vector2.ONE)
		return
	if buildings_only:
		draw_set_transform(offset + draw_offset, 0.0, Vector2.ONE)
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	draw_set_transform(
		(view_size * 0.5 - camera_center * camera_zoom + (offset + draw_offset) * camera_zoom) * scaler,
		0.0,
		Vector2.ONE * camera_zoom * scaler
	)


func visitor_world_position() -> Vector2:
	# Keep the neighbor close to the player's movable roadside stall.
	return object_position("pasar") + Vector2(175, 175)


func activate_at(screen_at: Vector2) -> void:
	if edit_mode:
		return
	var at := screen_to_world(screen_at)
	if not game.visitor_request.is_empty() and Rect2(visitor_world_position() - Vector2(65, 120), Vector2(130, 150)).has_point(at):
		visitor_pressed.emit()
		accept_event()
		return
	if delivery_depot_bounds().has_point(at):
		orders_pressed.emit()
		accept_event()
		return
	if handle_ready_marker_touch(at):
		accept_event()
		return
	if handle_shortcut_touch(at):
		accept_event()
		return
	var tree_id := wild_tree_at(at)
	if tree_id >= 0:
		start_chopping(tree_id)
		accept_event()
		return
	if Rect2(1680, 1096, 213, 99).has_point(at):
		missions_pressed.emit()
		accept_event()
		return
	if Rect2(object_position("pasar") + Vector2(-110, -115), Vector2(220, 175)).has_point(at):
		market_pressed.emit()
		accept_event()
		return
	for index in FarmGameState.ORCHARD_SIZE:
		var center := orchard_center(index)
		if Rect2(center + Vector2(-62, -117), Vector2(124, 137)).has_point(at):
			orchard_pressed.emit(index)
			accept_event()
			return
	for index in range(15, -1, -1):
		var cell := plot_center(index)
		if absf(at.x - cell.x) / 74.0 + absf(at.y - cell.y) / 40.0 <= 1.0:
			selected_plot = index
			plot_pressed.emit(index)
			queue_redraw()
			accept_event()
			return
	if COW_PEN_BOUNDS.has_point(at - (object_position("sapi") - default_position("sapi"))):
		animal_tapped.emit("sapi")
		cow_pressed.emit()
		accept_event()
	elif CHICKEN_RUN_BOUNDS.has_point(at - (object_position("ayam") - default_position("ayam"))):
		animal_tapped.emit("ayam")
		coop_pressed.emit()
		accept_event()
	elif Rect2(object_position("gudang") + Vector2(-110, -105), Vector2(215, 210)).has_point(at):
		barn_pressed.emit()
		accept_event()
	elif Rect2(object_position("dapur") + Vector2(-110, -140), Vector2(210, 210)).has_point(at):
		factory_pressed.emit()
		accept_event()
	else:
		blank_pressed.emit()
		accept_event()


func ready_marker_active(key: String) -> bool:
	if game == null:
		return false
	match key:
		"dapur": return game.production_ready()
		"pakan": return game.has_construction("pabrik_pakan") and game.feed_ready()
		"sapi": return game.cow_milk_ready()
		"babi", "kambing": return game.animal_ready(key)
	return false


func ready_marker_at(at: Vector2) -> String:
	if edit_mode:
		return ""
	for key in READY_MARKERS:
		if not ready_marker_active(key):
			continue
		var center: Vector2 = object_position(key) + READY_MARKERS[key]["offset"]
		# Includes the subtle vertical bob so the entire visual remains tappable.
		if Rect2(center + Vector2(-70, -53), Vector2(140, 72)).has_point(at):
			return key
	return ""


func handle_ready_marker_touch(at: Vector2) -> bool:
	var key := ready_marker_at(at)
	match key:
		"dapur":
			factory_pressed.emit()
		"pakan":
			feed_mill_pressed.emit()
		"sapi":
			animal_tapped.emit("sapi")
			cow_pressed.emit()
		"babi", "kambing":
			animal_tapped.emit(key)
			livestock_pressed.emit()
	return key != ""


func handle_shortcut_touch(at: Vector2) -> bool:
	if Rect2(275, 800, 156, 48).has_point(at):
		constructions_pressed.emit()
		return true
	if Rect2(1690, 800, 156, 48).has_point(at):
		livestock_pressed.emit()
		return true
	if game.has_construction("kandang_babi") and PIG_PEN_BOUNDS.has_point(at - (object_position("babi") - PIG_PEN_CENTER)):
		animal_tapped.emit("babi")
		livestock_pressed.emit()
		return true
	if game.has_construction("kandang_kambing") and GOAT_PEN_BOUNDS.has_point(at - (object_position("kambing") - GOAT_PEN_CENTER)):
		animal_tapped.emit("kambing")
		livestock_pressed.emit()
		return true
	if game.has_construction("pabrik_pakan") and FEED_MILL_TOUCH_BOUNDS.has_point(at - object_position("pakan")):
		feed_mill_pressed.emit()
		return true
	if (
		(game.has_construction("toko_roti") and BAKERY_TOUCH_BOUNDS.has_point(at - object_position("roti")))
		or (game.has_construction("pabrik_susu") and DAIRY_TOUCH_BOUNDS.has_point(at - object_position("susu")))
	):
		factory_pressed.emit()
		return true
	return false


func plot_center(index: int) -> Vector2:
	return object_position("petak_%d" % index)


func orchard_center(index: int) -> Vector2:
	return object_position("buah_%d" % index)


func wild_tree_at(at: Vector2) -> int:
	for index in range(WILD_TREES.size() - 1, -1, -1):
		if game.cleared_wild_trees.has(index):
			continue
		var center: Vector2 = WILD_TREES[index]
		if Rect2(center - Vector2(54, 112), Vector2(108, 135)).has_point(at):
			return index
	return -1


func start_chopping(index: int) -> bool:
	if index < 0 or index >= WILD_TREES.size() or game.cleared_wild_trees.has(index):
		return false
	if chopping_tree >= 0:
		return false
	chopping_tree = index
	if mobile_scenery_lite:
		invalidate_scenery()
	chop_progress = 0.0
	ujang_pause = 0.0
	show_world_feedback("target", WILD_TREES[index])
	wild_tree_started.emit()
	queue_redraw()
	return true


func ujang_patrol_points() -> Array[Vector2]:
	var points: Array[Vector2] = [
		object_position("sapi") + Vector2(215, 160),
		plot_center(4) + Vector2(130, 92),
		object_position("ayam") + Vector2(-185, 155),
		orchard_center(0) + Vector2(-110, 100),
		object_position("dapur") + Vector2(175, 95)
	]
	if game.has_construction("kandang_babi"):
		points.append(object_position("babi") + Vector2(165, 115))
	if game.has_construction("kandang_kambing"):
		points.append(object_position("kambing") + Vector2(160, 112))
	return points


func ujang_obstacle_rects() -> Array[Rect2]:
	var obstacles: Array[Rect2] = []
	for key in ["dapur", "gudang", "pasar"]:
		var half := object_half_size(key) + UJANG_BUILDING_MARGIN
		obstacles.append(Rect2(object_position(key) - half, half * 2.0))
	for item in [["toko_roti", "roti"], ["pabrik_susu", "susu"], ["pabrik_pakan", "pakan"]]:
		if game.has_construction(item[0]):
			var half := object_half_size(item[1]) + UJANG_BUILDING_MARGIN
			obstacles.append(Rect2(object_position(item[1]) - half, half * 2.0))
	for item in [
		["sapi", COW_PEN_BOUNDS], ["ayam", CHICKEN_RUN_BOUNDS]
	]:
		var key: String = item[0]
		var bounds: Rect2 = item[1]
		var shifted := bounds.grow(12.0)
		shifted.position += object_position(key) - default_position(key)
		obstacles.append(shifted)
	for item in [
		["kandang_babi", "babi", PIG_PEN_BOUNDS, PIG_PEN_CENTER],
		["kandang_kambing", "kambing", GOAT_PEN_BOUNDS, GOAT_PEN_CENTER]
	]:
		if game.has_construction(item[0]):
			var bounds: Rect2 = item[2]
			var shifted := bounds.grow(12.0)
			shifted.position += object_position(item[1]) - Vector2(item[3])
			obstacles.append(shifted)
	return obstacles


func ujang_point_blocked(at: Vector2, cached_obstacles: Array[Rect2] = []) -> bool:
	for index in game.plots.size():
		var diff := at - plot_center(index)
		if absf(diff.x) / UJANG_PLOT_HALF_SIZE.x + absf(diff.y) / UJANG_PLOT_HALF_SIZE.y < 1.0:
			return true
	var obstacles := cached_obstacles if not cached_obstacles.is_empty() else ujang_obstacle_rects()
	for rect in obstacles:
		if rect.has_point(at):
			return true
	for index in WILD_TREES.size():
		if not game.cleared_wild_trees.has(index) and at.distance_squared_to(WILD_TREES[index]) < UJANG_TREE_RADIUS * UJANG_TREE_RADIUS:
			return true
	for index in FarmGameState.ORCHARD_SIZE:
		if at.distance_squared_to(orchard_center(index)) < UJANG_ORCHARD_RADIUS * UJANG_ORCHARD_RADIUS:
			return true
	return false


func ujang_free_point(at: Vector2) -> Vector2:
	if not ujang_point_blocked(at):
		return at
	# A player may place a field under Ujang or over a patrol destination.
	for radius in range(16, 721, 16):
		for angle_index in 16:
			var angle := float(angle_index) * TAU / 16.0
			var candidate := at + Vector2(cos(angle), sin(angle)) * float(radius)
			if Rect2(Vector2.ZERO, WORLD_SIZE).has_point(candidate) and not ujang_point_blocked(candidate):
				return candidate
	return at


func ujang_segment_clear(start: Vector2, finish: Vector2) -> bool:
	# Clip against every field diamond. A segment touching an edge is allowed.
	for index in game.plots.size():
		var center := plot_center(index)
		var start_delta := start - center
		var direction := finish - start
		var lower := 0.0
		var upper := 1.0
		for sign_x in [-1.0, 1.0]:
			for sign_y in [-1.0, 1.0]:
				var base: float = sign_x * start_delta.x / UJANG_PLOT_HALF_SIZE.x + sign_y * start_delta.y / UJANG_PLOT_HALF_SIZE.y
				var slope: float = sign_x * direction.x / UJANG_PLOT_HALF_SIZE.x + sign_y * direction.y / UJANG_PLOT_HALF_SIZE.y
				if absf(slope) < 0.000001:
					if base >= 0.99999:
						upper = -1.0
				elif slope > 0.0:
					upper = minf(upper, (0.99999 - base) / slope)
				else:
					lower = maxf(lower, (0.99999 - base) / slope)
		if lower < upper - 0.000001:
			return false
	for rect in ujang_obstacle_rects():
		if ujang_segment_intersects_rect(start, finish, rect.grow(-0.05)):
			return false
	var direction := finish - start
	var segment_length_squared := direction.length_squared()
	for index in WILD_TREES.size():
		if game.cleared_wild_trees.has(index):
			continue
		var tree: Vector2 = WILD_TREES[index]
		var ratio := clampf((tree - start).dot(direction) / maxf(segment_length_squared, 0.00001), 0.0, 1.0)
		if (start + direction * ratio).distance_squared_to(tree) < UJANG_TREE_RADIUS * UJANG_TREE_RADIUS:
			return false
	for index in FarmGameState.ORCHARD_SIZE:
		var tree := orchard_center(index)
		var ratio := clampf((tree - start).dot(direction) / maxf(segment_length_squared, 0.00001), 0.0, 1.0)
		if (start + direction * ratio).distance_squared_to(tree) < UJANG_ORCHARD_RADIUS * UJANG_ORCHARD_RADIUS:
			return false
	return true


func ujang_segment_intersects_rect(start: Vector2, finish: Vector2, rect: Rect2) -> bool:
	if rect.has_point(start) or rect.has_point(finish):
		return true
	var delta := finish - start
	var entry := 0.0
	var exit := 1.0
	for axis in 2:
		var origin: float = start[axis]
		var speed: float = delta[axis]
		var lower: float = rect.position[axis]
		var upper: float = rect.end[axis]
		if absf(speed) < 0.000001:
			if origin < lower or origin > upper:
				return false
		else:
			var t1 := (lower - origin) / speed
			var t2 := (upper - origin) / speed
			entry = maxf(entry, minf(t1, t2))
			exit = minf(exit, maxf(t1, t2))
			if entry > exit:
				return false
	return entry <= exit


func ujang_obstacle_snapshot() -> String:
	return str(game.layout_positions) + "|" + str(game.cleared_wild_trees) + "|" + str(game.constructions)


func ujang_rebuild_navigation() -> void:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(
		ceili(WORLD_SIZE.x / UJANG_NAV_CELL_SIZE),
		ceili(WORLD_SIZE.y / UJANG_NAV_CELL_SIZE)
	))
	grid.cell_size = Vector2.ONE * UJANG_NAV_CELL_SIZE
	grid.offset = Vector2.ONE * (UJANG_NAV_CELL_SIZE * 0.5)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var obstacles := ujang_obstacle_rects()
	# Keep neighboring cell-to-cell steps outside obstacles, even at corners.
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var cell := Vector2i(x, y)
			var center := grid.get_point_position(cell)
			var solid := false
			for offset in [Vector2.ZERO, Vector2(19, 0), Vector2(-19, 0), Vector2(0, 19), Vector2(0, -19)]:
				if ujang_point_blocked(center + offset, obstacles):
					solid = true
					break
			if solid:
				grid.set_point_solid(cell, true)
	ujang_navigation_grid = grid
	ujang_navigation_snapshot = ujang_obstacle_snapshot()


func ujang_nearest_navigation_cell(at: Vector2, require_clear_segment := true) -> Vector2i:
	var start := Vector2i(floori(at.x / UJANG_NAV_CELL_SIZE), floori(at.y / UJANG_NAV_CELL_SIZE))
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for radius in 11:
		for y in range(start.y - radius, start.y + radius + 1):
			for x in range(start.x - radius, start.x + radius + 1):
				if maxi(absi(x - start.x), absi(y - start.y)) != radius:
					continue
				var cell := Vector2i(x, y)
				if not ujang_navigation_grid.region.has_point(cell) or ujang_navigation_grid.is_point_solid(cell):
					continue
				var center := ujang_navigation_grid.get_point_position(cell)
				var distance := at.distance_squared_to(center)
				if distance < best_distance and (not require_clear_segment or ujang_segment_clear(at, center)):
					best_distance = distance
					best = cell
		if best.x >= 0:
			break
	return best


func ujang_route_to(destination: Vector2) -> PackedVector2Array:
	if ujang_segment_clear(ujang_position, destination):
		return PackedVector2Array([ujang_position, destination])
	if ujang_navigation_grid == null or ujang_navigation_snapshot != ujang_obstacle_snapshot():
		ujang_rebuild_navigation()
	var start_cell := ujang_nearest_navigation_cell(ujang_position)
	var end_cell := ujang_nearest_navigation_cell(destination)
	var can_reach_exact_destination := end_cell.x >= 0
	if not can_reach_exact_destination:
		# A patrol marker may be caught in a narrow gap after moving a field.
		# Go to the closest grid cell instead of leaving Ujang stuck forever.
		end_cell = ujang_nearest_navigation_cell(destination, false)
	if start_cell.x < 0 or end_cell.x < 0:
		return PackedVector2Array()
	var cells := ujang_navigation_grid.get_id_path(start_cell, end_cell)
	if cells.is_empty():
		return PackedVector2Array()
	var raw := PackedVector2Array([ujang_position])
	for cell in cells:
		raw.append(ujang_navigation_grid.get_point_position(cell))
	if can_reach_exact_destination and ujang_segment_clear(raw[raw.size() - 1], destination):
		raw.append(destination)
	# Remove grid zigzags while checking actual obstacle edges again.
	var result := PackedVector2Array([raw[0]])
	var index := 0
	while index + 1 < raw.size():
		var furthest := index + 1
		for candidate in range(raw.size() - 1, index, -1):
			if ujang_segment_clear(raw[index], raw[candidate]):
				furthest = candidate
				break
		result.append(raw[furthest])
		index = furthest
	return result


func update_ujang(delta: float) -> void:
	if game == null:
		return
	var target := Vector2.ZERO
	if chopping_tree >= 0:
		target = WILD_TREES[chopping_tree] + Vector2(57, 24)
	else:
		var patrol := ujang_patrol_points()
		target = patrol[ujang_patrol_index % patrol.size()]
	var layout_now := ujang_obstacle_snapshot()
	var layout_changed := layout_now != ujang_layout_snapshot
	# Path segments are checked when routed. Recheck the worker's position
	# only when obstacles change or a building is being dragged over him.
	if (layout_changed or drag_key != "") and ujang_point_blocked(ujang_position):
		ujang_position = ujang_free_point(ujang_position)
	if ujang_pause > 0.0 and chopping_tree < 0:
		ujang_pause -= delta
		ujang_walking = false
		return
	if target != ujang_path_target or layout_changed:
		ujang_path_target = target
		ujang_layout_snapshot = layout_now
		ujang_path = ujang_route_to(ujang_free_point(target))
		ujang_path_index = 1
	if ujang_path.is_empty():
		ujang_walking = false
		return
	var goal := ujang_path[ujang_path.size() - 1]
	var delta_to_target := goal - ujang_position
	if delta_to_target.length() > 8.0:
		var speed := 380.0 if chopping_tree >= 0 else 105.0
		while ujang_path_index < ujang_path.size() and ujang_position.distance_to(ujang_path[ujang_path_index]) <= 5.0:
			ujang_path_index += 1
		if ujang_path_index < ujang_path.size():
			var step := ujang_path[ujang_path_index] - ujang_position
			var next_at := ujang_position + step.normalized() * minf(speed * delta, step.length())
			# Editing previews can introduce temporary obstacles between routes.
			# Stored-layout changes already force a new collision-safe route above.
			if drag_key != "" and not ujang_segment_clear(ujang_position, next_at):
				ujang_path_target = Vector2.INF
				ujang_walking = false
				return
			ujang_position = next_at
			ujang_facing = -1.0 if step.x < 0.0 else 1.0
			ujang_walking = true
		return
	ujang_walking = false
	if chopping_tree >= 0:
		var previous_chop_progress := chop_progress
		chop_progress += delta
		# Sync every chopping impact with Ujang's axe swing, never with his walk.
		# Check crossings so a low frame rate does not skip an impact.
		for strike_time in [0.18, 0.54, 0.90]:
			if previous_chop_progress < strike_time and chop_progress >= strike_time:
				show_world_feedback("chop_hit", WILD_TREES[chopping_tree] + Vector2(0, -33))
				wild_tree_struck.emit()
		if chop_progress >= 1.9:
			var completed := chopping_tree
			chopping_tree = -1
			chop_progress = 0.0
			ujang_pause = 1.0
			show_world_feedback("chop_done", WILD_TREES[completed], "+6")
			wild_tree_chopped.emit(completed)
	else:
		ujang_pause = 1.7
		ujang_patrol_index += 1


func _draw() -> void:
	if game == null:
		return
	if animal_render_only:
		match animal_kind:
			"chicken":
				LivestockPainter.paint_chicken(self, Vector2.ZERO, animal_scale, animal_walking, animal_phase)
			"cow":
				LivestockPainter.paint_cow(self, Vector2.ZERO, animal_scale, animal_walking, animal_phase)
		return
	if butterfly_render_only:
		LivestockPainter.paint_butterfly_shape(self)
		return
	if windmill_blades_only:
		for blade in 4:
			draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(blade * TAU / 4.0) * 46.0, Color("a37348"), 9.0, true)
		return
	if plot_render_only:
		paint_plot(plot_render_index, Vector2.ZERO)
		return
	if plot_selection_only:
		draw_polyline(PackedVector2Array([
			Vector2(90, 20), Vector2(168, 63), Vector2(90, 106),
			Vector2(12, 63), Vector2(90, 20)
		]), Color("fff8b3"), 5.0, true)
		return
	if visitor_render_only:
		paint_visitor()
		return
	if ujang_render_only:
		paint_ujang()
		return
	if truck_render_only:
		paint_retained_delivery_truck()
		return
	if world_details_only:
		# Cached CanvasItem uses world coordinates; camera movement only changes
		# its node transform. Orchard countdowns refresh once per second.
		paint_delivery_depot()
		paint_delivery_yard_details()
		for index in FarmGameState.ORCHARD_SIZE:
			paint_orchard(index, orchard_center(index))
		draw_set_transform(Vector2(1190, 430), 0.0, Vector2.ONE)
		paint_mission_board()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		paint_shortcut_sign(Vector2(275, 800), "BANGUN  ›", Color("f6d58e"))
		paint_shortcut_sign(Vector2(1690, 800), "TERNAK  ›", Color("f8e0a1"))
		return
	if ready_markers_only:
		paint_ready_markers(Rect2(Vector2.ZERO, WORLD_SIZE))
		return
	if animation_only:
		paint_live_animation()
		return
	if livestock_only:
		# Child CanvasItems retain the animals and butterflies. No per-frame paint.
		return
	if scenery_only:
		# The chunk's CanvasItem retains its draw commands until the scenery changes.
		chopping_tree = animation_source.chopping_tree if animation_source != null else -1
		draw_set_transform(-scenery_chunk_origin, 0.0, Vector2.ONE)
		paint_wide_landscape()
		return
	if buildings_only:
		set_world_transform()
		paint_movable_scenery_props()
		paint_spacious_buildings()
		paint_spacious_constructions()
		paint_owned_decorations()
		return
	var profile_start := Time.get_ticks_usec() if mobile_scenery_lite and OS.has_feature("debug") else 0
	set_world_transform()
	if not mobile_scenery_lite:
		paint_wide_landscape()
		paint_movable_scenery_props()
	var profile_landscape := Time.get_ticks_usec() if profile_start > 0 else 0
	if not mobile_scenery_lite:
		paint_spacious_buildings()
	var profile_buildings := Time.get_ticks_usec() if profile_start > 0 else 0
	var visible_objects := visible_world_rect(160.0)
	if not mobile_scenery_lite:
		for layer in 7:
			for row in 4:
				for col in 4:
					if row + col != layer:
						continue
					var index := row * 4 + col
					var at := plot_center(index)
					if visible_objects.has_point(at):
						paint_plot(index, at)
	var profile_plots := Time.get_ticks_usec() if profile_start > 0 else 0
	if not mobile_scenery_lite:
		paint_swipe_preview(visible_objects)
		paint_tutorial_plot(visible_objects)
	if not mobile_scenery_lite:
		paint_delivery_depot()
		paint_delivery_yard_details()
	if not mobile_scenery_lite:
		paint_delivery_truck()
	var profile_delivery := Time.get_ticks_usec() if profile_start > 0 else 0
	if not mobile_scenery_lite:
		for index in FarmGameState.ORCHARD_SIZE:
			var at := orchard_center(index)
			if visible_objects.has_point(at):
				paint_orchard(index, at)
	if not mobile_scenery_lite:
		paint_spacious_constructions()
		paint_owned_decorations()
	if placement_decoration_key != "":
		var item := game.decoration_by_key(placement_decoration_key)
		var kind := str(item.get("kind", ""))
		if FarmGameState.DECORATIONS.has(kind):
			farm_art.paint(self, kind, placement_preview, float(FarmGameState.DECORATIONS[kind]["width"]))
			var half := object_half_size(placement_decoration_key)
			var valid := can_place(placement_decoration_key, placement_preview)
			var tint := (Color("45d9f2") if placement_snapped else Color("56e5a0")) if valid else Color("ff7068")
			draw_rect(Rect2(placement_preview - half, half * 2.0), tint, false, 5.0)
	var profile_constructions := Time.get_ticks_usec() if profile_start > 0 else 0
	if not mobile_scenery_lite:
		paint_ready_markers(visible_objects)
		paint_ujang()
		paint_visitor()
		paint_visual_feedback()
	if edit_mode and edit_selected != "":
		var center := object_position(edit_selected)
		var half := object_half_size(edit_selected)
		var valid := drag_key == "" or can_place(edit_selected, center)
		var tint := (Color("45d9f2") if drag_snapped else Color("56e5a0")) if valid else Color("ff7068")
		if edit_selected.begins_with("petak_"):
			draw_polyline(PackedVector2Array([
				center + Vector2(0, -half.y), center + Vector2(half.x, 0),
				center + Vector2(0, half.y), center - Vector2(half.x, 0),
				center + Vector2(0, -half.y)
			]), tint, 6.0, true)
		else:
			draw_rect(Rect2(center - half, half * 2.0), tint, false, 6.0)
	if not mobile_scenery_lite:
		LivestockPainter.paint_butterfly(self, Vector2(845, 1220), 1.1)
		LivestockPainter.paint_butterfly(self, Vector2(1520, 1260), 3.4)
		LivestockPainter.paint_butterfly(self, Vector2(1740, 1480), 5.5)
	if not mobile_scenery_lite:
		set_world_transform(Vector2(1190, 430))
		paint_mission_board()
		set_world_transform()
		paint_shortcut_sign(Vector2(275, 800), "BANGUN  ›", Color("f6d58e"))
		paint_shortcut_sign(Vector2(1690, 800), "TERNAK  ›", Color("f8e0a1"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	paint_camera_hint()
	if profile_start > 0:
		mobile_draw_profile_index += 1
		if mobile_draw_profile_index == 1 or mobile_draw_profile_index % 16 == 0:
			print("KEBUN_DRAW total_ms=%.1f landscape=%.1f buildings=%.1f plots=%.1f delivery=%.1f constructions=%.1f misc=%.1f" % [
				float(Time.get_ticks_usec() - profile_start) / 1000.0,
				float(profile_landscape - profile_start) / 1000.0,
				float(profile_buildings - profile_landscape) / 1000.0,
				float(profile_plots - profile_buildings) / 1000.0,
				float(profile_delivery - profile_plots) / 1000.0,
				float(profile_constructions - profile_delivery) / 1000.0,
				float(Time.get_ticks_usec() - profile_constructions) / 1000.0
			])


func paint_live_animation() -> void:
	if animation_source == null:
		return
	var profile_start := Time.get_ticks_usec() if OS.has_feature("debug") else 0
	var source := animation_source
	camera_center = source.camera_center
	camera_zoom = source.camera_zoom
	shimmer = source.shimmer
	delivery_elapsed = source.delivery_elapsed
	ujang_position = source.ujang_position
	ujang_walking = source.ujang_walking
	ujang_facing = source.ujang_facing
	chopping_tree = source.chopping_tree
	chop_progress = source.chop_progress
	visual_feedback = source.visual_feedback
	edit_mode = source.edit_mode
	guide_plot_index = source.guide_plot_index
	guide_plot_action = source.guide_plot_action
	swipe_active = source.swipe_active
	swipe_indices = source.swipe_indices
	swipe_mode = source.swipe_mode
	set_world_transform()
	var visible := visible_world_rect(190.0)
	var profile_setup := Time.get_ticks_usec() if profile_start > 0 else 0
	if not mobile_scenery_lite:
		paint_windmill_blades()
	paint_swipe_preview(visible)
	paint_tutorial_plot(visible)
	if not mobile_scenery_lite:
		paint_ready_markers(visible)
	var profile_ready := Time.get_ticks_usec() if profile_start > 0 else 0
	if chopping_tree >= 0 and visible.has_point(WILD_TREES[chopping_tree]):
		paint_wild_tree(chopping_tree, WILD_TREES[chopping_tree])
	var profile_ujang := Time.get_ticks_usec() if profile_start > 0 else 0
	# Ujang is now rendered by his own CanvasItem, which moves every frame.
	var profile_visitor := Time.get_ticks_usec() if profile_start > 0 else 0
	# The mobile visitor has a separate retained CanvasItem.
	var profile_feedback := Time.get_ticks_usec() if profile_start > 0 else 0
	paint_visual_feedback()
	if profile_start > 0:
		mobile_animation_profile_frames += 1
		mobile_animation_profile_total_us += Time.get_ticks_usec() - profile_start
		mobile_animation_profile_setup_us += profile_setup - profile_start
		mobile_animation_profile_ujang_us += Time.get_ticks_usec() - profile_ujang
		mobile_animation_profile_ready_us += profile_ready - profile_setup
		mobile_animation_profile_character_us += profile_visitor - profile_ujang
		mobile_animation_profile_visitor_us += profile_feedback - profile_visitor
		mobile_animation_profile_feedback_us += Time.get_ticks_usec() - profile_feedback
		if mobile_animation_profile_frames >= 64:
			print("KEBUN_ANIM avg_ms=%.2f setup_ms=%.2f preactor_ms=%.2f ujang_ms=%.2f visitor_ms=%.2f fx_ms=%.2f frames=%d" % [
				float(mobile_animation_profile_total_us) / (1000.0 * mobile_animation_profile_frames),
				float(mobile_animation_profile_setup_us) / (1000.0 * mobile_animation_profile_frames),
				float(mobile_animation_profile_ready_us) / (1000.0 * mobile_animation_profile_frames),
				float(mobile_animation_profile_character_us) / (1000.0 * mobile_animation_profile_frames),
				float(mobile_animation_profile_visitor_us) / (1000.0 * mobile_animation_profile_frames),
				float(mobile_animation_profile_feedback_us) / (1000.0 * mobile_animation_profile_frames),
				mobile_animation_profile_frames
			])
			mobile_animation_profile_frames = 0
			mobile_animation_profile_total_us = 0
			mobile_animation_profile_setup_us = 0
			mobile_animation_profile_ujang_us = 0
			mobile_animation_profile_ready_us = 0
			mobile_animation_profile_character_us = 0
			mobile_animation_profile_visitor_us = 0
			mobile_animation_profile_feedback_us = 0


func show_world_feedback(kind: String, at: Vector2, text_value: String = "") -> void:
	# Purely presentational; never stored in the save game or used for hit testing.
	if visual_feedback.size() >= 12:
		visual_feedback.pop_front()
	var lifetime := 1.00 if kind == "harvest" or kind == "chop_done" else 0.76
	visual_feedback.append({
		"kind": kind, "at": at, "text": text_value,
		"age": 0.0, "duration": lifetime
	})
	queue_redraw()


func paint_swipe_preview(visible: Rect2) -> void:
	if not swipe_active or swipe_indices.is_empty():
		return
	var tint := Color("ffe18b") if swipe_mode == "harvest" else Color("83f0b4")
	var glow := 0.73 + 0.18 * sin(shimmer * 7.0)
	for position in swipe_indices.size():
		var index: int = swipe_indices[position]
		var center := plot_center(index) + Vector2(0, 7)
		if not visible.has_point(center):
			continue
		var points := PackedVector2Array([
			center + Vector2(0, -45), center + Vector2(80, 0),
			center + Vector2(0, 45), center - Vector2(80, 0),
			center + Vector2(0, -45)
		])
		var fill := tint
		fill.a = 0.23 * glow
		draw_colored_polygon(PackedVector2Array([points[0], points[1], points[2], points[3]]), fill)
		draw_polyline(points, Color("315e43", 0.70), 10.0, true)
		var outline := tint
		outline.a = glow
		draw_polyline(points, outline, 6.0, true)
		var shine := Color("fff9da", 0.68 * glow)
		draw_circle(center + Vector2(0, -43), 5.0, shine)
		var badge := center + Vector2(53, -43)
		draw_circle(badge + Vector2(0, 3), 22, Color("355a3a", 0.75))
		draw_circle(badge, 20, tint)
		draw_arc(badge, 18.5, 0, TAU, 24, Color("fff9dd", 0.80), 2.5, true)
		var ordinal := str(position + 1)
		var number_width := ThemeDB.fallback_font.get_string_size(ordinal, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x
		label(ordinal, badge + Vector2(-number_width * 0.5, 7), 23, Color("305543"))


func paint_tutorial_plot(visible: Rect2) -> void:
	if edit_mode or guide_plot_index < 0 or guide_plot_index >= game.plots.size():
		return
	var center := plot_center(guide_plot_index) + Vector2(0, 7)
	if not visible.has_point(center):
		return
	var phase := shimmer * 5.0
	var strength := 0.77 + 0.22 * sin(phase)
	var outer := 80.0 + 4.0 * sin(phase)
	var corners := PackedVector2Array([
		center + Vector2(0, -outer * 0.56),
		center + Vector2(outer, 0),
		center + Vector2(0, outer * 0.56),
		center + Vector2(-outer, 0),
		center + Vector2(0, -outer * 0.56)
	])
	var glow := Color("ffcb58", 0.18 * strength)
	draw_colored_polygon(PackedVector2Array([corners[0], corners[1], corners[2], corners[3]]), glow)
	draw_polyline(corners, Color("3c673e", 0.60), 10.0, true)
	draw_polyline(corners, Color("fff2aa", strength), 5.0, true)
	for i in 4:
		draw_circle(corners[i], 4.2, Color("fff9d6", strength))
	var bob := sin(shimmer * 4.0) * 5.0
	var badge_at := center + Vector2(0, -147 + bob)
	draw_circle(badge_at + Vector2(0, 5), 29, Color("3d653b", 0.36))
	draw_circle(badge_at, 28, Color("ffce64"))
	draw_arc(badge_at, 25, 0.0, TAU, 28, Color("fff8d9"), 2.0, true)
	var arrow := PackedVector2Array([
		badge_at + Vector2(-11, -6), badge_at + Vector2(11, -6),
		badge_at + Vector2(0, 12)
	])
	draw_colored_polygon(arrow, Color("3e7647"))
	var caption := "PANEN" if guide_plot_action == "harvest" else "TANAM"
	var text_width := ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	var ribbon := Rect2(badge_at.x - text_width * 0.5 - 14, badge_at.y - 63, text_width + 28, 27)
	draw_rect(ribbon.grow(2), Color("3c6742", 0.5))
	draw_rect(ribbon, Color("fff1bb"))
	label(caption, Vector2(ribbon.position.x + 14, ribbon.position.y + 20), 19, Color("326544"))


func show_plot_feedback(index: int, kind: String, quantity: int = 0) -> void:
	if index < 0 or index >= game.plots.size():
		return
	var display := "+%d" % quantity if quantity > 0 else ""
	show_world_feedback(kind, plot_center(index), display)


func show_orchard_feedback(index: int, kind: String, quantity: int = 0) -> void:
	if index < 0 or index >= FarmGameState.ORCHARD_SIZE:
		return
	var display := "+%d" % quantity if quantity > 0 else ""
	show_world_feedback(kind, orchard_center(index) + Vector2(0, -43), display)


func paint_visual_feedback() -> void:
	var visible := visible_world_rect(85.0)
	for feedback in visual_feedback:
		var at: Vector2 = feedback["at"]
		if not visible.has_point(at):
			continue
		var kind: String = feedback["kind"]
		var age: float = feedback["age"]
		var duration: float = feedback["duration"]
		var progress := clampf(age / duration, 0.0, 1.0)
		var opacity := pow(1.0 - progress, 1.35)
		var tone := Color("79d28a")
		if kind == "harvest" or kind == "chop_done":
			tone = Color("ffe3a0")
		elif kind == "chop_hit":
			tone = Color("edca8e")
		elif kind == "reject":
			tone = Color("f29f88")
		elif kind == "target":
			tone = Color("eee4a0")
		var halo := tone
		halo.a = opacity * 0.5
		var center := at + Vector2(0, 5) if kind != "chop_hit" else at
		var radius := 19.0 + 42.0 * (1.0 - pow(1.0 - progress, 2.0))
		draw_arc(center, radius, 0.0, TAU, 32, halo, 2.7, true)
		if kind == "move" or kind == "plant" or kind == "harvest":
			var close_halo := tone
			close_halo.a = opacity * 0.22
			ellipse(at + Vector2(0, 9), 27.0 + progress * 29.0, 10.0 + progress * 15.0, close_halo, 18)
		if kind == "target" or kind == "reject":
			continue
		# Five small drifting motes read well on a phone without particle nodes.
		var mote_count := 5 if camera_zoom < 0.85 else 7
		for i in mote_count:
			var phase := TAU * float(i) / float(mote_count) - PI * 0.5
			var displacement := Vector2(cos(phase) * 35.0, sin(phase) * 22.0 - 23.0)
			var mote_at := at + displacement * progress + Vector2(0, -12.0 * progress)
			var mote_color := tone
			mote_color.a = opacity * 0.9
			draw_circle(mote_at, (3.2 + float(i % 3)) * (0.7 + opacity * 0.3), mote_color)
		var caption: String = feedback["text"]
		if caption != "":
			var caption_color := Color("fff5d7")
			caption_color.a = opacity
			var text_at := at + Vector2(0, -57.0 - progress * 18.0)
			var text_width := ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			var label_at := text_at - Vector2(text_width * 0.5, 0)
			var shadow := Color("426343", opacity * 0.68)
			draw_string(ThemeDB.fallback_font, label_at + Vector2(1.8, 2.1),
				caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, shadow)
			draw_string(ThemeDB.fallback_font, label_at,
				caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, caption_color)


func paint_camera_hint() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / get_virtual_size())
	var hint_y := 70.0 if edit_mode else 14.0
	var hint := "USAP TANAM/PANEN  •  CUBIT ZOOM"
	var hint_width := 324.0
	if edit_mode:
		hint_width = 510.0
		match road_tool:
			"draw": hint = "JALAN: SENTUH & SERET UNTUK MEMBUAT JALAN"
			"erase": hint = "HAPUS: SENTUH & SERET UNTUK MENGHAPUS JALAN"
			"pan": hint = "GESER: JELAJAHI PETA DAN CUBIT UNTUK ZOOM"
			_: hint = "OBJEK: GESER BANGUNAN ATAU PETAK"
	elif swipe_active:
		var total := swipe_indices.size()
		hint = ("USAP PANEN" if swipe_mode == "harvest" else "USAP TANAM") + "  •  %d PETAK  •  LEPAS UNTUK PROSES" % total
		hint_width = 490.0
	draw_rect(Rect2(16, hint_y, hint_width, 39), Color("2f644a", 0.87))
	label(hint, Vector2(29, hint_y + 26), 16, Color("fff9dd"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func visible_world_rect(padding: float = 0.0) -> Rect2:
	if scenery_only:
		return Rect2(scenery_chunk_origin, Vector2.ONE * SCENERY_CACHE_CHUNK_SIZE).grow(padding)
	# Matches set_world_transform() at every camera zoom and portrait aspect ratio.
	var half_view := get_virtual_size() / (2.0 * maxf(camera_zoom, 0.01))
	return Rect2(camera_center - half_view, half_view * 2.0).grow(padding)


func make_terrain_contour(area: Rect2, seed: int, inset: float) -> PackedVector2Array:
	var contour := PackedVector2Array()
	var middle := area.get_center() + Vector2(11.0 * inset, -7.0 * inset)
	var half := area.size * (0.5 - inset * 0.075)
	var phase := float(seed) * 1.37
	# A rounded superellipse with multiple low-frequency ripples, never sharp corners.
	for i in 56:
		var angle := TAU * float(i) / 56.0
		var dx := cos(angle)
		var dy := sin(angle)
		var ripple := 1.0 + 0.055 * sin(3.0 * angle + phase)
		ripple += 0.036 * sin(7.0 * angle - phase * 0.9)
		ripple += 0.018 * cos(11.0 * angle + phase)
		contour.append(middle + Vector2(
			signf(dx) * pow(absf(dx), 0.77) * half.x,
			signf(dy) * pow(absf(dy), 0.77) * half.y
		) * ripple)
	return contour


func prepare_terrain_contours() -> void:
	terrain_contours.clear()
	terrain_insets.clear()
	for i in TERRAIN_PATCH_RECTS.size():
		var patch: Rect2 = TERRAIN_PATCH_RECTS[i]
		terrain_contours.append(make_terrain_contour(patch, i + 1, 0.0))
		terrain_insets.append(make_terrain_contour(patch, i + 1, 0.92))


func road_visual_center(cell: Vector2i) -> Vector2:
	# Small persistent offsets break up ruler-straight roads while retaining tile adjacency.
	var jitter := ((cell.x * 73856093) ^ (cell.y * 19349663)) & 0x7fffffff
	return (Vector2(cell) + Vector2(0.5, 0.5)) * ROAD_GRID_SIZE + Vector2(
		float(jitter % 9 - 4), float((jitter >> 6) % 9 - 4)
	)


func paint_roads() -> void:
	var visible := visible_world_rect(float(ROAD_GRID_SIZE) + 75.0)
	# Player roads use the old village footpath's layered, worn dirt finish.
	# The underlying grid is unchanged so existing player layouts still load.
	for layer in [
		[ROAD_WIDTH, Color("b7a16f")],
		[ROAD_WIDTH * 0.83, Color("d1ac77")],
		[ROAD_WIDTH * 0.53, Color("f0c98f", 0.32)]
	]:
		var width: float = layer[0]
		var tone: Color = layer[1]
		for id in game.road_tiles:
			var parts := str(id).split(",")
			if parts.size() != 2:
				continue
			var cell := Vector2i(int(parts[0]), int(parts[1]))
			var center := road_visual_center(cell)
			if not visible.has_point(center):
				continue
			for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
				if game.road_tiles.has(road_key(cell + offset)) and \
						road_surface_clear_of_objects(center, road_visual_center(cell + offset), ROAD_HALF_WIDTH):
					line(center, road_visual_center(cell + offset), tone, width)
			if road_surface_clear_of_objects(center, center, ROAD_HALF_WIDTH):
				draw_circle(center, width * 0.5, tone)
	# Sparse dust, worn patches and small stones make the surface less uniform.
	if camera_zoom >= 0.81:
		for id in game.road_tiles:
			var parts := str(id).split(",")
			if parts.size() != 2:
				continue
			var cell := Vector2i(int(parts[0]), int(parts[1]))
			var center := road_visual_center(cell)
			if not visible.has_point(center):
				continue
			var seed := ((cell.x * 27644437) ^ (cell.y * 908317)) & 0x7fffffff
			for j in 3:
				var spot := center + Vector2(
					float((seed >> (j * 5)) % 47 - 23),
					float((seed >> (j * 3 + 8)) % 43 - 21)
				)
				draw_circle(spot, 2.0 + float((seed >> j) % 3), Color("c69f6e", 0.36))
			if seed % 4 == 0:
				line(center + Vector2(-12, 7), center + Vector2(13, 3), Color("f9e0b0", 0.35), 2.0)
	if edit_mode and (road_tool == "draw" or road_tool == "erase"):
		for id in game.road_tiles:
			var parts := str(id).split(",")
			if parts.size() == 2:
				var cell := Vector2i(int(parts[0]), int(parts[1]))
				var center := (Vector2(cell) + Vector2(0.5, 0.5)) * ROAD_GRID_SIZE
				if visible.has_point(center):
					draw_circle(center, 2.5, Color("f9e5b8", 0.65))


func paint_meadow_detail(visible: Rect2) -> void:
	# Iterate only camera-visible cells; decor is deterministic and never saved.
	var from_x := maxi(0, floori(visible.position.x / SCENERY_CELL_SIZE))
	var from_y := maxi(0, floori(visible.position.y / SCENERY_CELL_SIZE))
	var to_x := mini(ceili(visible.end.x / SCENERY_CELL_SIZE), ceili(WORLD_SIZE.x / SCENERY_CELL_SIZE))
	var to_y := mini(ceili(visible.end.y / SCENERY_CELL_SIZE), ceili(WORLD_SIZE.y / SCENERY_CELL_SIZE))
	for gy in range(from_y, to_y + 1):
		for gx in range(from_x, to_x + 1):
			var seed := (gx * 73856093 ^ gy * 19349663 ^ gx * gy * 83492791) & 0x7fffffff
			if mobile_scenery_lite and seed % 4 != 0:
				continue
			if camera_zoom < 0.87 and seed % 3 == 0:
				continue
			var at := Vector2(
				float(gx * SCENERY_CELL_SIZE + 11 + seed % 50),
				float(gy * SCENERY_CELL_SIZE + 9 + (seed >> 7) % 53)
			)
			if at.x >= WORLD_SIZE.x or at.y >= WORLD_SIZE.y or not visible.has_point(at):
				continue
			var dark := Color("61b958") if seed % 5 == 0 else Color("79c364")
			var light := Color("d1eb9c") if seed % 4 == 0 else Color("a0db7a")
			line(at, at + Vector2(-4, -6 - float(seed % 5)), dark, 1.7)
			line(at, at + Vector2(2, -8 - float((seed >> 3) % 6)), light, 1.9)
			if seed % 3 == 0:
				line(at + Vector2(2, 1), at + Vector2(7, -5), dark, 1.6)
			if seed % 13 == 0:
				var blossom := at + Vector2(11, -8)
				var petal := Color("fff2ce") if seed % 2 == 0 else Color("f4a9a9")
				if camera_zoom >= 0.97:
					draw_circle(blossom + Vector2(-3, 0), 3.0, petal)
					draw_circle(blossom + Vector2(3, 0), 3.0, petal)
					draw_circle(blossom + Vector2(0, -3), 3.0, petal)
					draw_circle(blossom, 1.7, Color("f2c75d"))
				else:
					draw_circle(blossom, 3.4, petal)
			elif seed % 9 == 0:
				draw_circle(at + Vector2(14, 4), 2.8, Color("e3efba", 0.70))


func scenery_clear_of_farm(at: Vector2, sprite_footprint := Rect2()) -> bool:
	# Check the whole artwork footprint, not just its ground anchor. The same
	# clearance applies to all player-created roads.
	var footprint: Rect2 = sprite_footprint if sprite_footprint.has_area() else \
		Rect2(at - Vector2(18, 18), Vector2(36, 36))
	for key in OBJECT_DEFAULTS:
		var center := settled_object_position(String(key))
		var half: Vector2 = OBJECT_HALF_SIZES[key]
		if footprint.intersects(Rect2(center - half - Vector2(48, 32),
				(half + Vector2(48, 32)) * 2.0)):
			return false
	for index in 16:
		var center := settled_object_position("petak_%d" % index)
		if footprint.intersects(Rect2(center - Vector2(87, 54), Vector2(174, 108))):
			return false
	for item in game.decorations:
		var position: Array = item.get("position", [])
		if position.size() != 2:
			continue
		var key := str(item["key"])
		var center := settled_object_position(key)
		var half := object_half_size(key) + Vector2(12, 12)
		if footprint.intersects(Rect2(center - half, half * 2.0)):
			return false
	for index in WILD_TREES.size():
		if game.cleared_wild_trees.has(index):
			continue
		if footprint.intersects(Rect2(WILD_TREES[index] - Vector2(78, 78),
				Vector2(156, 156))):
			return false
	return not road_overlaps_rect(footprint.grow(5.0))


func paint_meadow_clusters(visible: Rect2) -> void:
	# The meadow has small islands of wildflowers, clover and rocks. Each island
	# is tied to a world-grid hash, so panning never rearranges the scenery.
	var start_x := maxi(0, floori(visible.position.x / MEADOW_CLUSTER_SIZE))
	var start_y := maxi(0, floori(visible.position.y / MEADOW_CLUSTER_SIZE))
	var end_x := mini(ceili(visible.end.x / MEADOW_CLUSTER_SIZE), ceili(WORLD_SIZE.x / MEADOW_CLUSTER_SIZE))
	var end_y := mini(ceili(visible.end.y / MEADOW_CLUSTER_SIZE), ceili(WORLD_SIZE.y / MEADOW_CLUSTER_SIZE))
	for gy in range(start_y, end_y + 1):
		for gx in range(start_x, end_x + 1):
			var seed := ((gx * 92837111) ^ (gy * 689287499) ^ (gx * gy * 104729)) & 0x7fffffff
			if mobile_scenery_lite and seed % 3 != 0:
				continue
			if seed % 6 == 0:
				continue
			var at := Vector2(
				float(gx * MEADOW_CLUSTER_SIZE + 45 + seed % 112),
				float(gy * MEADOW_CLUSTER_SIZE + 38 + (seed >> 8) % 132)
			)
			if at.x >= WORLD_SIZE.x - 40 or at.y >= WORLD_SIZE.y - 40:
				continue
			if not visible.grow(65.0).has_point(at) or not scenery_clear_of_farm(at):
				continue
			var radius := 31.0 + float(seed % 22)
			ellipse(at + Vector2(0, 7), radius * 1.16, 17.0, Color("64b45e", 0.12), 16)
			ellipse(at, radius, 12.0, Color("b9e88d", 0.24), 16)
			var variant := seed % 5
			for j in 7:
				var angle := float(j) * TAU / 7.0 + float(seed % 13) * 0.14
				var tuft := at + Vector2(cos(angle) * radius * 0.76, sin(angle) * 12.0)
				var height := 8.0 + float((seed >> (j + 2)) % 8)
				line(tuft, tuft + Vector2(-4, -height * 0.65), Color("4f9d51", 0.73), 2.0)
				line(tuft, tuft + Vector2(3, -height), Color("a2d76b", 0.94), 2.0)
			if variant == 0 or variant == 2 or variant == 4:
				if variant == 4 and seed % 3 == 1:
					# Layer a few original painted flower sprites into the empty meadow.
					farm_art.paint(self, "flower_patch", at, 125.0)
				else:
					for j in 3:
						var flower_at := at + Vector2(-22 + j * 19, -7 + (j % 2) * 12)
						var petal := Color("fff3cf") if variant == 0 else Color("efa8a7")
						paint_flower(flower_at, petal)
			elif variant == 1:
				# A low stone pile adds contrast without creating a new hit target.
				ellipse(at + Vector2(10, 0), 22, 8, Color("5a9861", 0.23), 12)
				poly(PackedVector2Array([
					at + Vector2(-13, -4), at + Vector2(-3, -19),
					at + Vector2(15, -15), at + Vector2(24, -2), at + Vector2(8, 5)
				]), Color("b2b3a1"))
				line(at + Vector2(-3, -17), at + Vector2(14, -14), Color("e0dbc1", 0.78), 2.5)
			else:
				for j in 3:
					var leaf := at + Vector2(-15 + j * 14, -5 - (j % 2) * 4)
					draw_circle(leaf, 6.0, Color("4da358"))
					draw_circle(leaf + Vector2(-2, -3), 4.5, Color("81ca6c"))
			if seed % 3 == 1:
				# Seed heads break up the low clover silhouette at every zoom level.
				for stalk in 5:
					var base := at + Vector2(-23 + stalk * 11, 3 + (stalk % 2) * 5)
					var height := 19.0 + float((seed >> (stalk + 3)) % 12)
					var top := base + Vector2(-4 + (stalk % 3) * 3, -height)
					line(base, top, Color("559c48"), 2.3)
					line(base + Vector2(0, -7), base + Vector2(7, -13), Color("8ac867"), 2.0)
					ellipse(top, 3.2, 6.5, Color("e5d17e"), 10)


func paint_wild_meadow_bands(visible: Rect2) -> void:
	# Tall grasses add a soft silhouette between the buildings and flower beds.
	# Cell hashes make positions stable while panning. Nothing enters the save.
	const BAND_SIZE := 260.0
	var start_x := maxi(0, floori(visible.position.x / BAND_SIZE))
	var start_y := maxi(0, floori(visible.position.y / BAND_SIZE))
	var end_x := mini(ceili(visible.end.x / BAND_SIZE), ceili(WORLD_SIZE.x / BAND_SIZE))
	var end_y := mini(ceili(visible.end.y / BAND_SIZE), ceili(WORLD_SIZE.y / BAND_SIZE))
	for gy in range(start_y, end_y + 1):
		for gx in range(start_x, end_x + 1):
			var seed := ((gx * 92821) ^ (gy * 68917) ^ (gx * gy * 10139)) & 0x7fffffff
			if mobile_scenery_lite and seed % 3 != 0:
				continue
			if seed % 4 == 0:
				continue
			var at := Vector2(
				float(gx) * BAND_SIZE + 50.0 + float(seed % 140),
				float(gy) * BAND_SIZE + 48.0 + float((seed >> 8) % 145)
			)
			if at.x > WORLD_SIZE.x - 48.0 or at.y > WORLD_SIZE.y - 45.0:
				continue
			if not visible.grow(75.0).has_point(at) or not scenery_clear_of_farm(at):
				continue
			var width := 37.0 + float((seed >> 3) % 16)
			ellipse(at + Vector2(0, 6), width, 15, Color("5ba74b", 0.16), 16)
			for blade in (7 if mobile_scenery_lite else 15):
				var hash_value := (seed + blade * 19937) & 0x7fffffff
				var x := (float(blade) - (3.0 if mobile_scenery_lite else 7.0)) * width / (4.0 if mobile_scenery_lite else 8.0)
				var base := at + Vector2(x, float(hash_value % 11) - 2.0)
				var height := 13.0 + float((hash_value >> 6) % 24)
				var tip := base + Vector2(float((hash_value >> 12) % 13) - 6.0, -height)
				line(base, tip, Color("469449", 0.86), 2.7)
				line(base + Vector2(0, -5), base + Vector2(7, -12), Color("a3d76d", 0.9), 2.0)
				if blade % 4 == 1:
					ellipse(tip, 3.1, 5.7, Color("eed98a"), 10)
				elif blade % 5 == 0:
					ellipse(tip + Vector2(-1, 2), 3.4, 4.5, Color("b7df81"), 10)
			if seed % 3 == 0:
				paint_flower(at + Vector2(-width + 8, -3), Color("ffedba"))
				paint_flower(at + Vector2(width - 9, 2), Color("f3b4c4"))


func delivery_depot_bounds() -> Rect2:
	# Include the isometric depot awning and the parked truck in the touch target.
	return Rect2(DELIVERY_DOCK + Vector2(-298, -199), Vector2(449, 260))


func start_delivery_animation() -> void:
	# A new successful order restarts the courier journey. Game rewards are
	# already settled by FarmGameState; this presentation is never saved.
	delivery_elapsed = 0.0
	show_world_feedback("harvest", DELIVERY_DOCK + Vector2(0, -90), "TERKIRIM!")


func delivery_truck_position() -> Vector2:
	if delivery_elapsed < 0.0:
		return DELIVERY_DOCK
	var progress := 0.0
	if delivery_elapsed < 2.85:
		progress = clampf(delivery_elapsed / 2.85, 0.0, 1.0)
	elif delivery_elapsed >= 3.75:
		progress = 1.0 - clampf((delivery_elapsed - 3.75) / 2.75, 0.0, 1.0)
	else:
		progress = 1.0
	return DELIVERY_DOCK + Vector2(940.0 * progress, 155.0 * progress)


func paint_delivery_depot() -> void:
	if not world_details_only and not visible_world_rect(220.0).has_point(DELIVERY_DOCK):
		return
	var at := DELIVERY_DOCK
	# Ground the depot separately from the truck; its larger roof anchors
	# the loading yard while the transparent PNG keeps the 3/4-view shape.
	var depot_ground := at + Vector2(-136, -25)
	paint_grounding(depot_ground + Vector2(0, 6), 142.0, 30.0)
	if farm_art.paint(self, "delivery_depot", depot_ground, 350.0):
		return
	# A small loading apron separates the truck from the planted diamonds.
	ellipse(at + Vector2(-19, 14), 188, 59, Color("629846", 0.24))
	ellipse(at + Vector2(-17, 12), 164, 48, Color("dbbb88", 0.84))
	for i in 3:
		var box := at + Vector2(-176 + 43 * i, -15 - (i % 2) * 13)
		draw_rect(Rect2(box, Vector2(38, 36)), Color("865c3c"))
		draw_rect(Rect2(box + Vector2(3, 3), Vector2(32, 28)), Color("c69156"))
		line(box + Vector2(4, 5), box + Vector2(33, 28), Color("8a643d", 0.7), 3.0)
		line(box + Vector2(34, 5), box + Vector2(5, 28), Color("f7d695", 0.55), 2.0)
	var sign := at + Vector2(-156, -142)
	line(sign + Vector2(16, 39), sign + Vector2(16, 112), Color("865c39"), 10.0)
	line(sign + Vector2(135, 39), sign + Vector2(135, 110), Color("865c39"), 10.0)
	draw_rect(Rect2(sign + Vector2(0, 0), Vector2(151, 58)), Color("805037"))
	draw_rect(Rect2(sign + Vector2(5, 5), Vector2(141, 47)), Color("f9d995"))
	label("PESANAN", sign + Vector2(18, 30), 22, Color("715039"))
	label("KIRIM  ›", sign + Vector2(34, 47), 14, Color("397a54"))
	for nail_x in [11, 139]:
		draw_circle(sign + Vector2(nail_x, 12), 2.9, Color("a36c40"))


func paint_delivery_yard_details() -> void:
	# Original Blender 3/4-view props echo the depot palette and use ground anchors.
	# Keep both footprints away from the traversable truck route and tap target.
	if not world_details_only and not visible_world_rect(240.0).has_point(DELIVERY_DOCK):
		return
	var sorting_at := DELIVERY_DOCK + Vector2(-316, 42)
	paint_grounding(sorting_at + Vector2(0, 5), 65, 13)
	farm_art.paint(self, "sorting_trolley", sorting_at, 128.0)
	var waypost_at := DELIVERY_DOCK + Vector2(225, 180)
	paint_grounding(waypost_at + Vector2(0, 6), 45, 11)
	farm_art.paint(self, "village_waypost", waypost_at, 98.0)


func paint_delivery_truck() -> void:
	if delivery_elapsed >= 2.85 and delivery_elapsed < 3.75:
		return
	var at := delivery_truck_position()
	if not visible_world_rect(190.0).has_point(at):
		return
	var facing := -1.0 if delivery_elapsed >= 3.75 else 1.0
	var rolling := delivery_elapsed >= 0.0
	var bounce := sin(shimmer * 22.0) * 2.0 if rolling else 0.0
	paint_grounding(at + Vector2(0, 9), 115, 25)
	if rolling:
		for i in 3:
			var dust := at + Vector2(-facing * (95 + i * 25), -4 - i * 4)
			draw_circle(dust, 7.0 - i * 1.4, Color("f5ddb2", 0.26))
	# Mirroring the full truck lets the same illustration drive both ways.
	set_animal_transform(at + Vector2(0, bounce), facing)
	paint_delivery_truck_body(rolling)
	set_world_transform()


func paint_retained_delivery_truck() -> void:
	# Local-space drawing lets the parent translate the truck every frame while
	# the same sprite, shadow and dust commands stay cached in this CanvasItem.
	var rolling := delivery_elapsed >= 0.0
	var facing := -1.0 if delivery_elapsed >= 3.75 else 1.0
	var bounce := sin(shimmer * 22.0) * 2.0 if rolling else 0.0
	paint_grounding(Vector2(0, 9), 115, 25)
	if rolling:
		for i in 3:
			var dust := Vector2(-facing * (95 + i * 25), -4 - i * 4)
			draw_circle(dust, 7.0 - i * 1.4, Color("f5ddb2", 0.26))
	draw_set_transform(Vector2(0, bounce), 0.0, Vector2(facing, 1.0))
	paint_delivery_truck_body(rolling)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func paint_delivery_truck_body(rolling: bool) -> void:
	if farm_art.paint(self, "delivery_truck", Vector2.ZERO, 210.0):
		return
	# Warm wood crates, roof rails and bright cabin identify the vehicle as a
	# produce delivery truck at the smallest phone zoom.
	var wheel_turn := shimmer * 21.0 if rolling else 0.0
	draw_rect(Rect2(-101, -91, 116, 66), Color("805437"))
	draw_rect(Rect2(-97, -86, 109, 58), Color("d59e55"))
	for i in 3:
		var left := -92.0 + float(i) * 34.0
		draw_rect(Rect2(left, -81, 30, 45), Color("bc8248"))
		line(Vector2(left + 4, -78), Vector2(left + 26, -40), Color("885b39", 0.83), 3.0)
		line(Vector2(left + 25, -78), Vector2(left + 5, -40), Color("efd19a", 0.65), 2.0)
	line(Vector2(-108, -94), Vector2(19, -94), Color("6d5036"), 7.0)
	# Hood, windscreen and door are separate silhouettes with thick outlines.
	poly(PackedVector2Array([
		Vector2(11, -80), Vector2(56, -80), Vector2(78, -57),
		Vector2(92, -54), Vector2(100, -20), Vector2(11, -20)
	]), Color("376f6b"))
	poly(PackedVector2Array([
		Vector2(17, -75), Vector2(54, -75), Vector2(72, -55), Vector2(17, -55)
	]), Color("c8f0db"))
	line(Vector2(19, -72), Vector2(34, -72), Color("f5fff0", 0.7), 4.0)
	draw_rect(Rect2(20, -50, 43, 29), Color("62a48f"))
	line(Vector2(69, -52), Vector2(69, -18), Color("2f6867"), 3.0)
	draw_circle(Vector2(52, -38), 3, Color("f6dfab"))
	draw_rect(Rect2(-112, -23, 216, 15), Color("604a39"))
	draw_rect(Rect2(-106, -20, 207, 8), Color("cba06a"))
	draw_rect(Rect2(95, -42, 11, 14), Color("ffe59c"))
	for wheel_x in [-71.0, 70.0]:
		var wheel := Vector2(wheel_x, -11)
		draw_circle(wheel, 21, Color("384340"))
		draw_circle(wheel, 13, Color("a0ada4"))
		draw_circle(wheel, 5, Color("5a726a"))
		for spoke in 4:
			var angle := wheel_turn + float(spoke) * TAU / 4.0
			line(wheel + Vector2(cos(angle), sin(angle)) * 6,
				wheel + Vector2(cos(angle), sin(angle)) * 11, Color("d6dfbe"), 2.0)


func paint_roadside_flower_borders(visible: Rect2) -> void:
	# Wildflowers now follow editable roads, with stable per-cell placement.
	# An empty farm or a deleted road leaves no vestigial roadside borders.
	for id in game.road_tiles:
		var parts := str(id).split(",")
		if parts.size() != 2:
			continue
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		var seed := ((cell.x * 9781) ^ (cell.y * 2089 + 317)) & 0x7fffffff
		if seed % 4 != 0:
			continue
		var tangent := Vector2.RIGHT
		if not game.road_tiles.has(road_key(cell + Vector2i.RIGHT)) and \
				not game.road_tiles.has(road_key(cell + Vector2i.LEFT)):
			tangent = Vector2.DOWN
		var outward := Vector2(-tangent.y, tangent.x)
		var side := -1.0 if (seed >> 3) % 2 == 0 else 1.0
		var at := road_visual_center(cell) + outward * side * (91.0 + float(seed % 19))
		at += tangent * float((seed >> 5) % 27 - 13)
		var visual := Rect2(at - Vector2(28, 19), Vector2(56, 38))
		if seed % 5 == 0:
			visual = farm_art.ground_bounds("flowering_hedge", at, 116.0)
		elif seed % 7 == 0:
			visual = farm_art.ground_bounds("flower_patch", at, 122.0)
		if not visible.grow(85.0).has_point(at) or not scenery_clear_of_farm(at, visual):
			continue
		if seed % 5 == 0:
			farm_art.paint(self, "flowering_hedge", at, 116.0)
		elif seed % 7 == 0:
			farm_art.paint(self, "flower_patch", at, 122.0)
		else:
			for blossom in 4:
				var off := Vector2(-16 + blossom * 10, -4 + blossom % 2 * 10)
				paint_flower(at + off, Color("ffe2a3") if seed % 3 == 0 else Color("f6b5d0"))


func paint_wide_landscape() -> void:
	# All scenery is rendered in world coordinates; contours are cached across frames.
	var visible := visible_world_rect(105.0)
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("95d56f"))
	for i in TERRAIN_PATCH_RECTS.size():
		var patch: Rect2 = TERRAIN_PATCH_RECTS[i]
		if not patch.grow(110.0).intersects(visible):
			continue
		poly(terrain_contours[i], Color("a6df7b"))
		poly(terrain_insets[i], Color("b5e68c", 0.52))
	paint_meadow_detail(visible)
	paint_meadow_clusters(visible)
	paint_wild_meadow_bands(visible)
	paint_roads()
	paint_roadside_flower_borders(visible)
	# Nature remains behind interactive buildings and plots, and costs nothing offscreen.
	for index in WILD_TREES.size():
		if visible.has_point(WILD_TREES[index]) and not game.cleared_wild_trees.has(index) and (not scenery_only or index != chopping_tree):
			paint_wild_tree(index, WILD_TREES[index])
	for pos in [
		Vector2(325, 960), Vector2(560, 320), Vector2(1150, 355),
		Vector2(1950, 690), Vector2(1980, 1200), Vector2(1380, 1840),
		Vector2(740, 1730), Vector2(260, 1450), Vector2(1570, 1240)
	]:
		if visible.has_point(pos) and scenery_clear_of_farm(pos,
				Rect2(pos - Vector2(55, 85), Vector2(110, 105))):
			paint_bush(pos)
	for i in 20:
		var flower := Vector2(880 + (i % 10) * 67, 1220 + (i / 10) * 32)
		if visible.has_point(flower) and scenery_clear_of_farm(flower):
			paint_flower(flower, Color("fff0c3"))
	for i in 32:
		var flower := Vector2(2300 + (i % 8) * 78, 1750 + (i / 8) * 90)
		if visible.has_point(flower) and scenery_clear_of_farm(flower):
			paint_flower(flower, Color("fff0c3"))
	# Keep the fence attached to unlocked land bounds, but draw only visible posts.
	var accessible := accessible_world()
	draw_rect(accessible, Color("5ba44d", 0.70), false, 8.0)
	for x in range(int(accessible.position.x) + 16, int(accessible.end.x), 73):
		if visible.has_point(Vector2(x, accessible.position.y)):
			paint_fence(Vector2(x, accessible.position.y))
		if visible.has_point(Vector2(x, accessible.end.y)):
			paint_fence(Vector2(x, accessible.end.y))
	for y in range(int(accessible.position.y) + 72, int(accessible.end.y), 73):
		if visible.has_point(Vector2(accessible.position.x, y)):
			paint_fence(Vector2(accessible.position.x, y))
		if visible.has_point(Vector2(accessible.end.x, y)):
			paint_fence(Vector2(accessible.end.x, y))


func paint_movable_scenery_props() -> void:
	# Map decorations render in the live building layer, allowing immediate
	# drag previews on Android while the background scenery stays cached.
	var visible := Rect2(Vector2.ZERO, WORLD_SIZE).grow(200.0) if buildings_only else visible_world_rect(200.0)
	for index in MOVABLE_SCENERY.size():
		var item: Array = MOVABLE_SCENERY[index]
		var key := "scenery_%d" % index
		var kind := str(item[0])
		var width := float(item[2])
		var at := object_position(key)
		if not visible.has_point(at):
			continue
		if key != drag_key and not scenery_visible_at(key, at, farm_art.ground_bounds(kind, at, width)):
			continue
		if kind in ["pollinator_house", "herb_drying_rack", "rainwater_collector", "wildflower_crescent"]:
			paint_grounding(at + Vector2(0, 3), width * 0.37, width * 0.095)
		farm_art.paint(self, kind, at, width)

func paint_spacious_buildings() -> void:
	var visible := (
		Rect2(Vector2.ZERO, WORLD_SIZE).grow(265.0)
		if buildings_only else visible_world_rect(265.0)
	)
	var kitchen := object_position("dapur")
	if visible.has_point(kitchen):
		paint_grounding(kitchen, 98.0, 31.0)
		paint_house(kitchen)
		if edit_mode or not game.production_ready():
			bubble("DAPUR", kitchen + Vector2(0, -186), Color("fff3cf"), Color("89552b"))
	var barn := object_position("gudang")
	if visible.has_point(barn):
		paint_grounding(barn, 104.0, 37.0)
		paint_barn(barn)
	var coop := object_position("ayam")
	if visible.has_point(coop):
		paint_grounding(coop + Vector2(0, 54), 148.0, 61.0)
		paint_coop(coop)
	var market := object_position("pasar")
	if visible.has_point(market):
		paint_grounding(market + Vector2(0, 26), 108.0, 31.0)
		paint_market_cart(market)
		bubble("PASAR", market + Vector2(0, -184), Color("fff3cf"), Color("89552b"))
	if visible.has_point(Vector2(358, 705)) and scenery_clear_of_farm(Vector2(358, 705),
			Rect2(300, 576, 116, 160)):
		paint_well(Vector2(358, 705))
	if visible.has_point(Vector2(1450, 580)) and scenery_clear_of_farm(Vector2(1450, 580),
			Rect2(1411, 521, 102, 95)):
		paint_hay_bale(Vector2(1450, 580), 1.0)
		paint_hay_bale(Vector2(1474, 605), 0.72)
	if visible.has_point(Vector2(975, 455)) and scenery_clear_of_farm(Vector2(975, 455),
			Rect2(945, 390, 60, 80)):
		paint_barrel(Vector2(975, 455))
	var cow_pen := object_position("sapi")
	if visible.has_point(cow_pen):
		paint_grounding(cow_pen + Vector2(0, 36), 195.0, 118.0)
		draw_offset = cow_pen - default_position("sapi")
		set_world_transform()
		LivestockPainter.paint_cow_pen(self)
		draw_offset = Vector2.ZERO
		set_world_transform()
	# Signposts keep the different work areas recognisable while panning.
	for item in [
		["LADANG", Vector2(1000, 620)],
		["KEBUN BUAH", Vector2(1100, 1340)],
		["DESA", Vector2(1840, 780)],
		["HUTAN LIAR", Vector2(2900, 870)],
		["PADANG RUMPUT", Vector2(2580, 2180)]
	]:
		var position: Vector2 = item[1]
		if not visible.has_point(position) or not scenery_clear_of_farm(position,
				Rect2(position + Vector2(-38, -24), Vector2(116, 74))):
			continue
		draw_rect(Rect2(position, Vector2(8, 50)), Color("9d693d"))
		draw_rect(Rect2(position + Vector2(-38, -24), Vector2(116, 36)), Color("f1d58c"))
		label(item[0], position + Vector2(-29, 0), 17, Color("795234"))


func paint_ready_markers(visible: Rect2) -> void:
	if edit_mode:
		return
	# On Android a retained layer handles bobbing via its CanvasItem transform.
	var bob := 0.0 if ready_markers_only else sin(shimmer * 2.8) * 4.0
	var glint := 1.0 if ready_markers_only else 0.65 + 0.35 * sin(shimmer * 4.0)
	for key in READY_MARKERS:
		if not ready_marker_active(key):
			continue
		var object_at := object_position(key)
		if not visible.has_point(object_at):
			continue
		var center: Vector2 = object_at + READY_MARKERS[key]["offset"] + Vector2(0, bob)
		bubble(READY_MARKERS[key]["text"], center, Color("fff0bd"), Color("735125"))
		var spark := center + Vector2(57, -36)
		draw_circle(spark, 5.0 + glint * 2.0, Color("ffe79c", 0.35 * glint))
		draw_line(spark + Vector2(-5, 0), spark + Vector2(5, 0), Color("fffde0", glint), 2.0)
		draw_line(spark + Vector2(0, -5), spark + Vector2(0, 5), Color("fffde0", glint), 2.0)


func paint_owned_decorations() -> void:
	var visible := Rect2(Vector2.ZERO, WORLD_SIZE).grow(180.0) if buildings_only else visible_world_rect(180.0)
	for item in game.decorations:
		var position: Array = item.get("position", [])
		if position.size() != 2:
			continue
		var kind := str(item.get("kind", ""))
		if not FarmGameState.DECORATIONS.has(kind):
			continue
		var at := object_position(str(item["key"]))
		if visible.has_point(at):
			farm_art.paint(self, kind, at, float(FarmGameState.DECORATIONS[kind]["width"]))


func paint_spacious_constructions() -> void:
	var visible := (
		Rect2(Vector2.ZERO, WORLD_SIZE).grow(170.0)
		if buildings_only else visible_world_rect(170.0)
	)
	if game.has_construction("kandang_babi"):
		var at := object_position("babi")
		if visible.has_point(at):
			paint_grounding(at + Vector2(0, 30), 137.0, 56.0)
			if not farm_art.paint(self, "pig_pen", at + Vector2(0, 30), 290.0):
				LivestockPainter.paint_small_paddock(self, at, Color("efb5bc"), "BABI")
	if game.has_construction("kandang_kambing"):
		var at := object_position("kambing")
		if visible.has_point(at):
			paint_grounding(at + Vector2(0, 30), 137.0, 56.0)
			if not farm_art.paint(self, "goat_pen", at + Vector2(0, 30), 290.0):
				LivestockPainter.paint_small_paddock(self, at, Color("e8dec5"), "KAMBING")
	if game.has_construction("toko_roti"):
		var at := object_position("roti")
		if visible.has_point(at):
			paint_grounding(at + Vector2(0, 10), 86.0, 30.0)
			if not farm_art.paint(self, "bakery_building", at, 190.0):
				paint_small_workshop(at, Color("e4a35d"), "ROTI")
	if game.has_construction("pabrik_susu"):
		var at := object_position("susu")
		if visible.has_point(at):
			paint_grounding(at + Vector2(0, 10), 88.0, 32.0)
			if not farm_art.paint(self, "dairy_building", at, 195.0):
				paint_small_workshop(at, Color("8dccd4"), "SUSU")
	if game.has_construction("pabrik_pakan"):
		var at := object_position("pakan")
		if visible.has_point(at):
			paint_grounding(at + Vector2(0, 13), 92.0, 32.0)
			if not farm_art.paint(self, "feed_mill_building", at, 195.0):
				paint_small_workshop(at, Color("c9aa73"), "PAKAN")
	for i in game.construction_count("petak_bunga"):
		var flower_at := Vector2(430 + i * 164, 775)
		if visible.has_point(flower_at):
			if not farm_art.paint(self, "flower_garden", flower_at, 150.0):
				for j in 3:
					paint_flower(
						flower_at + Vector2(j * 10, 0),
						Color("f0879c") if j % 2 == 0 else Color("f7dd7d")
					)
	if game.has_construction("gazebo"):
		var at := Vector2(1610, 1500)
		ellipse(at, 45, 14, Color("c49b61"))
		for side in [-28, 28]:
			line(at + Vector2(side, 0), at + Vector2(side, -48), Color("80552f"), 7)
		poly(
			PackedVector2Array(
				[at + Vector2(-53, -48), at + Vector2(0, -87), at + Vector2(53, -48)]
			),
			Color("bb7441")
		)
	if game.has_construction("kincir_angin"):
		var at := Vector2(1860, 365)
		poly(
			PackedVector2Array([at + Vector2(-19, 30), at + Vector2(0, -80), at + Vector2(19, 30)]),
			Color("f1e2b7")
		)
		if not mobile_scenery_lite:
			paint_windmill_blades()
	if game.has_construction("kolam"):
		var pond := Vector2(1550, 1660)
		ellipse(pond, 63, 31, Color("e1d4aa"))
		ellipse(pond + Vector2(0, -4), 54, 23, Color("6bc7d9"))


func poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)


func paint_windmill_blades() -> void:
	if not game.has_construction("kincir_angin"):
		return
	var at := Vector2(1860, 365)
	if not visible_world_rect(120.0).has_point(at):
		return
	for i in 4:
		var angle := shimmer * 0.8 + i * TAU / 4.0
		line(at + Vector2(0, -80), at + Vector2(cos(angle), sin(angle)) * 46 + Vector2(0, -80), Color("a37348"), 9)


func ellipse(center: Vector2, rx: float, ry: float, color: Color, steps: int = 24) -> void:
	if not ellipse_unit_cache.has(steps):
		var unit_points := PackedVector2Array()
		for i in steps:
			var angle := TAU * i / steps
			unit_points.append(Vector2(cos(angle), sin(angle)))
		ellipse_unit_cache[steps] = unit_points
	var units: PackedVector2Array = ellipse_unit_cache[steps]
	var points := PackedVector2Array()
	for point in units:
		points.append(center + Vector2(point.x * rx, point.y * ry))
	poly(points, color)


func paint_grounding(at: Vector2, rx: float, ry: float) -> void:
	# Two translucent contact layers soften the seam between art and terrain.
	ellipse(at + Vector2(6, 10), rx * 1.17, ry * 1.27, Color("48894b", 0.13), 18)
	ellipse(at + Vector2(3, 6), rx, ry, Color("56834b", 0.20), 18)


func diamond(center: Vector2, rx: float, ry: float, color: Color) -> void:
	poly(
		PackedVector2Array(
			[
				center + Vector2(0, -ry),
				center + Vector2(rx, 0),
				center + Vector2(0, ry),
				center + Vector2(-rx, 0),
			]
		),
		color
	)


func line(a: Vector2, b: Vector2, color: Color, thickness: float = 3.0) -> void:
	draw_line(a, b, color, thickness, true)


func set_animal_transform(at: Vector2, facing: float) -> void:
	var view_size := get_virtual_size()
	var scaler := size / view_size
	draw_set_transform(
		(view_size * 0.5 - camera_center * camera_zoom + (at + draw_offset) * camera_zoom) * scaler,
		0.0,
		Vector2(facing * camera_zoom * scaler.x, camera_zoom * scaler.y)
	)


func paint_roaming_animal(
	kind: String, at: Vector2, scale_factor: float, seed: float, radius: Vector2
) -> void:
	if mobile_scenery_lite and not animation_only and not livestock_only:
		return
	var motion := LivestockPainter.animal_motion(self, seed, radius)
	var position: Vector2 = at + motion["offset"]
	set_animal_transform(position, float(motion["facing"]))
	var walking: bool = motion["walking"]
	var phase: float = motion["phase"]
	match kind:
		"chicken":
			LivestockPainter.paint_chicken(self, Vector2.ZERO, scale_factor, walking, phase)
		"cow":
			LivestockPainter.paint_cow(self, Vector2.ZERO, scale_factor, walking, phase)
		"pig":
			LivestockPainter.paint_pig(self, Vector2.ZERO, scale_factor, walking, phase)
		"goat":
			LivestockPainter.paint_goat(self, Vector2.ZERO, scale_factor, walking, phase)
	set_world_transform()


func paint_landscape() -> void:
	draw_rect(Rect2(0, 0, 720, 780), GRASS)
	poly(
		PackedVector2Array(
			[
				Vector2(0, 0),
				Vector2(720, 0),
				Vector2(720, 128),
				Vector2(515, 81),
				Vector2(333, 114),
				Vector2(158, 70),
				Vector2(0, 107)
			]
		),
		Color("b3e58b")
	)
	poly(
		PackedVector2Array(
			[
				Vector2(0, 674),
				Vector2(110, 644),
				Vector2(278, 693),
				Vector2(500, 640),
				Vector2(720, 684),
				Vector2(720, 780),
				Vector2(0, 780)
			]
		),
		Color("80c66d")
	)
	paint_grass_detail()
	# Low hedges frame the garden without restricting player road layout.
	for i in 10:
		paint_hedge(Vector2(18 + i * 32, 319 + i * 3), 27)
	for i in 6:
		paint_hedge(Vector2(540 + i * 30, 366 + i * 9), 24)
	for i in 75:
		var x := float((i * 193 + 57) % 716)
		var y := float((i * 127 + 51) % 772)
		if y > 320 and x > 100 and x < 618:
			continue
		var c := Color("71b961") if i % 3 == 0 else Color("d5ed89")
		line(Vector2(x, y), Vector2(x - 3, y - 8), c, 2)
		line(Vector2(x, y), Vector2(x + 4, y - 7), c, 2)
	for i in 16:
		var x := 13 + i * 47.0
		paint_fence(Vector2(x, 69 + sin(i * 0.56) * 11))
	# Windy shrubs at the perimeter.
	for pos in [
		Vector2(25, 397), Vector2(676, 392), Vector2(41, 598), Vector2(650, 741), Vector2(85, 735)
	]:
		paint_bush(pos)
	for pos in [Vector2(39, 165), Vector2(683, 108), Vector2(665, 626), Vector2(32, 683)]:
		paint_tree(pos)
	# A little orchard and flower beds help the farm feel lived in.
	for pos in [Vector2(36, 510), Vector2(681, 528)]:
		paint_fruit_tree(pos)
	for i in 6:
		paint_flower(Vector2(54 + i * 16, 304 + sin(i * 1.7) * 5), Color("fff1e0"))
	for i in 8:
		paint_flower(Vector2(575 + i * 17, 352 + sin(i * 1.3) * 6), Color("ffb5aa"))


func paint_grass_detail() -> void:
	# Coordinates are deterministic so the scenery stays still while the crops animate.
	for i in 390:
		var at := Vector2(float((i * 173 + 31) % 718), float((i * 109 + 23) % 770))
		if at.x > 105 and at.x < 616 and at.y > 327 and at.y < 681:
			continue
		var tint := Color("6bbd52") if i % 3 == 0 else Color("d3ee92")
		line(at, at + Vector2(-2, -4 - (i % 4)), tint, 1.5)
		line(at, at + Vector2(3, -3 - (i % 3)), tint, 1.5)
		if i % 19 == 0:
			draw_circle(at + Vector2(5, -5), 2.2, Color("f7e99e"))
	for i in 36:
		var at := Vector2(float((i * 191 + 47) % 720), float((i * 83 + 29) % 765))
		if at.x > 85 and at.x < 630 and at.y > 313 and at.y < 668:
			continue
		ellipse(at, 4 + i % 3, 2.8, Color("ebf0b2", 0.8))


func paint_hedge(at: Vector2, width: float) -> void:
	ellipse(at + Vector2(0, 8), width * 0.55, 10, Color("4f9a47", 0.3))
	for i in 3:
		var pos := at + Vector2((i - 1) * width * 0.28, -i % 2 * 3)
		draw_circle(pos + Vector2(0, 2), width * 0.28, Color("348d46"))
		draw_circle(pos + Vector2(-3, -4), width * 0.21, Color("66bd57"))
		draw_circle(pos + Vector2(-6, -7), 2.5, Color("b7e278"))


func paint_fruit_tree(at: Vector2, fruit_color: Color = Color("ffd161"), ripe: bool = true) -> void:
	ellipse(at + Vector2(3, 19), 47, 14, Color("4a9950", 0.32))
	poly(
		PackedVector2Array(
			[at + Vector2(-8, 8), at + Vector2(-6, -49), at + Vector2(7, -49), at + Vector2(11, 8)]
		),
		Color("98613d")
	)
	line(at + Vector2(1, -37), at + Vector2(-21, -62), Color("98613d"), 7)
	for off in [Vector2(-26, -58), Vector2(5, -80), Vector2(30, -60), Vector2(-5, -53)]:
		draw_circle(at + off, 25, Color("378f48"))
		draw_circle(at + off + Vector2(-5, -5), 18, Color("6ac95c"))
	if ripe:
		for off in [
			Vector2(-31, -59),
			Vector2(10, -80),
			Vector2(29, -50),
			Vector2(-8, -46),
			Vector2(16, -61)
		]:
			draw_circle(at + off, 6, fruit_color)
			draw_circle(at + off + Vector2(-2, -2), 2, Color("fff1cf"))


func paint_orchard(index: int, at: Vector2) -> void:
	OrchardPainter.paint(self, game, index, at)


func paint_fence(at: Vector2) -> void:
	draw_rect(Rect2(at.x - 4, at.y - 19, 9, 40), Color("b8794e"))
	draw_rect(Rect2(at.x - 5, at.y - 21, 9, 34), Color("e9ba78"))
	poly(
		PackedVector2Array(
			[Vector2(at.x - 5, at.y - 21), Vector2(at.x, at.y - 28), Vector2(at.x + 4, at.y - 21)]
		),
		Color("f5d294")
	)
	line(at + Vector2(-25, -6), at + Vector2(25, -6), Color("f1c88c"), 6)
	line(at + Vector2(-25, 12), at + Vector2(25, 12), Color("db9c6b"), 5)


func paint_bush(at: Vector2) -> void:
	ellipse(at + Vector2(1, 5), 34, 14, Color("66ae61"))
	for off in [Vector2(-18, -6), Vector2(5, -16), Vector2(22, -5)]:
		draw_circle(at + off, 16, Color("439b57"))
		draw_circle(at + off + Vector2(-5, -6), 10, Color("79c76d"))
	for off in [Vector2(-12, -12), Vector2(13, -16), Vector2(26, -5)]:
		draw_circle(at + off, 3, Color("fae3a7"))


func paint_tree(at: Vector2) -> void:
	if farm_art.paint(self, "apple_tree", at, 116.0):
		return
	ellipse(at + Vector2(5, 16), 48, 17, Color("5dac5c", 0.44))
	draw_rect(Rect2(at.x - 9, at.y - 51, 18, 66), Color("a76a42"))
	draw_rect(Rect2(at.x - 4, at.y - 47, 7, 56), Color("d79a60"))
	for branch in [Vector2(-27, -49), Vector2(27, -51), Vector2(0, -79), Vector2(-3, -39)]:
		draw_circle(at + branch, 31, Color("429b53"))
		draw_circle(at + branch + Vector2(-7, -9), 23, Color("70ca64"))
	for fruit in [Vector2(-28, -53), Vector2(7, -89), Vector2(26, -39)]:
		draw_circle(at + fruit, 5, Color("ffcf67"))


func paint_wild_tree(index: int, at: Vector2) -> void:
	var angle := 0.0
	var chopping := index == chopping_tree and chop_progress > 0.0
	if chopping:
		angle = sin(chop_progress * 25.0) * 0.095
		if chop_progress > 1.15:
			angle = pow((chop_progress - 1.15) / 0.75, 1.8) * 1.35
	# Rotate the full trunk and canopy around the stump as it falls.
	if scenery_only:
		draw_set_transform(at - scenery_chunk_origin, angle, Vector2.ONE)
	else:
		var view_size := get_virtual_size()
		var scaler := size / view_size
		var screen_at := (view_size * 0.5 + (at - camera_center) * camera_zoom) * scaler
		draw_set_transform(screen_at, angle, scaler * camera_zoom)
	ellipse(Vector2(5, 12), 44, 13, Color("3c974d", 0.32))
	draw_rect(Rect2(-12, -65, 24, 78), Color("845535"))
	draw_rect(Rect2(-7, -64, 7, 69), Color("c18a4f"))
	line(Vector2(-3, -38), Vector2(-34, -64), Color("875a3b"), 8.0)
	line(Vector2(3, -52), Vector2(33, -82), Color("875a3b"), 8.0)
	var foliage := Color("38884f") if index % 3 == 0 else Color("438f49")
	for leaf in [Vector2(-29, -68), Vector2(25, -70), Vector2(-7, -101), Vector2(7, -53)]:
		draw_circle(leaf, 30, foliage)
		draw_circle(leaf + Vector2(-8, -7), 21, Color("65ba5f"))
		draw_circle(leaf + Vector2(-13, -17), 6, Color("8dd876", 0.7))
	set_world_transform()
	if chopping:
		# Flying woodchips mark the axe strikes.
		for i in 6:
			var theta := float(i) * TAU / 6.0 + chop_progress * 8.0
			var spread := 12.0 + fmod(chop_progress * 54.0 + float(i) * 7.0, 40.0)
			var chip := at + Vector2(cos(theta) * spread, -22 + sin(theta) * spread * 0.5)
			draw_circle(chip, 3.0, Color("f5cd7a"))
	if index == chopping_tree and chop_progress < 0.05:
		bubble("UJANG MENUJU POHON", at + Vector2(0, -133), Color("fff2c7"), Color("765633"))


func paint_ujang() -> void:
	var view_size := get_virtual_size()
	var scaler := size / view_size
	var screen_at := Vector2.ZERO if ujang_render_only else (view_size * 0.5 + (ujang_position - camera_center) * camera_zoom) * scaler
	# Scale the entire character around the feet; keep the name readable.
	draw_set_transform(screen_at, 0.0, Vector2.ONE * UJANG_SCALE if ujang_render_only else scaler * camera_zoom * UJANG_SCALE)
	var at := Vector2.ZERO
	var stepping := sin(shimmer * 11.0) * 7.0 if ujang_walking else 0.0
	var swinging := chopping_tree >= 0 and chop_progress > 0.0 and chop_progress < 1.2
	var axe_swing := sin(chop_progress * 17.0) if swinging else 0.0
	ellipse(at + Vector2(0, 5), 24, 8, Color("367d45", 0.34))
	# Boots, trousers and walking animation.
	line(at + Vector2(-9, -31), at + Vector2(-9 + stepping, -1), Color("3c5786"), 10)
	line(at + Vector2(9, -31), at + Vector2(9 - stepping, -1), Color("3c5786"), 10)
	line(at + Vector2(-10 + stepping, -1), at + Vector2(-2 + stepping, 1), Color("674532"), 9)
	line(at + Vector2(8 - stepping, -1), at + Vector2(17 - stepping, 1), Color("674532"), 9)
	draw_rect(Rect2(at + Vector2(-17, -65), Vector2(34, 37)), Color("f4ad4b"))
	draw_rect(Rect2(at + Vector2(-4, -65), Vector2(7, 37)), Color("e48b36"))
	var hand_l := at + Vector2(-23, -39)
	var hand_r := at + Vector2(24, -37)
	line(at + Vector2(-15, -59), hand_l + Vector2(0, stepping * 0.5), Color("b97a43"), 9)
	var raised_hand := hand_r + Vector2(axe_swing * 20.0, -absf(axe_swing) * 22.0)
	line(at + Vector2(14, -59), raised_hand, Color("b97a43"), 9)
	if swinging:
		var handle_top := raised_hand + Vector2(17 * ujang_facing, -32)
		line(raised_hand, handle_top, Color("986139"), 6)
		poly(PackedVector2Array([
			handle_top + Vector2(-15, -12), handle_top + Vector2(8, -14),
			handle_top + Vector2(10, 4), handle_top + Vector2(-17, 8)
		]), Color("dbe6e8"))
	# Friendly, recognizable farm worker with straw hat.
	draw_circle(at + Vector2(0, -82), 20, Color("d49b66"))
	draw_circle(at + Vector2(ujang_facing * 8, -84), 2.6, Color("49352e"))
	draw_arc(at + Vector2(ujang_facing * 6, -75), 5.0, 0.1, PI - 0.1, 8, Color("805134"), 2.0)
	draw_rect(Rect2(at + Vector2(-19, -107), Vector2(38, 10)), Color("bf8c41"))
	draw_rect(Rect2(at + Vector2(-30, -100), Vector2(60, 8)), Color("e7bc69"))
	draw_rect(Rect2(at + Vector2(-17, -103), Vector2(34, 5)), Color("6c9b59"))
	if ujang_render_only:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		bubble("UJANG", Vector2(0, -116), Color("fff3c9"), Color("4d6e39"))
	else:
		set_world_transform()
		bubble("UJANG", ujang_position + Vector2(0, -116), Color("fff3c9"), Color("4d6e39"))


func paint_visitor() -> void:
	if game.visitor_request.is_empty():
		return
	var at := visitor_world_position()
	if not visitor_render_only and not visible_world_rect(130.0).has_point(at):
		return
	var view_size := get_virtual_size()
	var scaler := size / view_size
	var screen_at := Vector2.ZERO if visitor_render_only else (view_size * 0.5 + (at - camera_center) * camera_zoom) * scaler
	# A distinct neighbor silhouette, with an idle bounce and shopping basket.
	draw_set_transform(screen_at, 0.0, Vector2.ONE * 0.88 if visitor_render_only else scaler * camera_zoom * 0.88)
	var bounce := 0.0 if visitor_render_only else sin(shimmer * 2.6) * 1.7
	ellipse(Vector2(0, 5), 29, 9, Color("367d45", 0.35))
	line(Vector2(-10, -34), Vector2(-10, -4), Color("58688f"), 12)
	line(Vector2(10, -34), Vector2(10, -4), Color("58688f"), 12)
	ellipse(Vector2(-12, -1), 13, 6, Color("724839"))
	ellipse(Vector2(12, -1), 13, 6, Color("724839"))
	poly(PackedVector2Array([
		Vector2(-20, -70 + bounce), Vector2(19, -70 + bounce),
		Vector2(25, -33 + bounce), Vector2(-24, -33 + bounce)
	]), Color("de7290"))
	draw_rect(Rect2(-4, -68 + bounce, 8, 35), Color("f2a3a8"))
	line(Vector2(-19, -63 + bounce), Vector2(-29, -41 + bounce), Color("d59a67"), 10)
	line(Vector2(19, -63 + bounce), Vector2(32, -43 + bounce), Color("d59a67"), 10)
	# Woven basket shows that the character is here to buy farm goods.
	draw_rect(Rect2(22, -40 + bounce, 26, 23), Color("c48b48"))
	draw_arc(Vector2(35, -40 + bounce), 11, PI, TAU, 12, Color("89633e"), 4)
	for i in 3:
		line(Vector2(26 + 9 * i, -37 + bounce), Vector2(26 + 9 * i, -19 + bounce), Color("e6bc73"), 2)
	draw_circle(Vector2(0, -88 + bounce), 21, Color("dca675"))
	draw_circle(Vector2(-8, -91 + bounce), 2.6, Color("453b35"))
	draw_circle(Vector2(9, -91 + bounce), 2.6, Color("453b35"))
	draw_arc(Vector2(0, -82 + bounce), 7, 0.15, PI - 0.15, 9, Color("995f50"), 2)
	draw_arc(Vector2(0, -101 + bounce), 22, PI, TAU, 15, Color("664f43"), 9)
	draw_circle(Vector2(19, -102 + bounce), 7, Color("664f43"))
	if visitor_render_only:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		bubble("ADA PESANAN!", Vector2(0, -125), Color("fff0b9"), Color("81562e"))
	else:
		set_world_transform()
		bubble("ADA PESANAN!", at + Vector2(0, -125), Color("fff0b9"), Color("81562e"))


func paint_farm_buildings() -> void:
	paint_house(Vector2(149, 181))
	bubble(
		"HASIL SIAP!" if game.production_ready() else "DAPUR",
		Vector2(149, 54),
		Color("fff3cf"),
		Color("89552b")
	)
	paint_barn(Vector2(385, 184))
	paint_coop(Vector2(599, 203))
	paint_well(Vector2(63, 346))
	paint_hay_bale(Vector2(490, 267), 1.0)
	paint_hay_bale(Vector2(507, 279), 0.7)
	paint_barrel(Vector2(303, 264))
	paint_market_cart(Vector2(649, 326))
	bubble("PASAR", Vector2(646, 234), Color("fff3cf"), Color("89552b"))
	LivestockPainter.paint_cow_pen(self)
	# A milk can, flower pots and the signpost make the buildings readable at small scale.
	ellipse(Vector2(265, 279), 20, 8, Color("a56a4b", 0.25))
	draw_rect(Rect2(249, 244, 24, 31), Color("d1e5e1"))
	draw_rect(Rect2(252, 239, 18, 9), Color("f4ffff"))
	draw_rect(Rect2(421, 288, 9, 36), Color("94613f"))
	poly(
		PackedVector2Array(
			[Vector2(418, 285), Vector2(485, 278), Vector2(482, 308), Vector2(418, 310)]
		),
		Color("f5d18b")
	)
	label("KEBUN", Vector2(428, 298), 15, Color("88533e"))
	draw_rect(Rect2(429, 301, 7, 5), Color("c77848"))
	draw_rect(Rect2(440, 301, 7, 5), Color("7fb96e"))
	for i in 3:
		paint_flower(Vector2(444 + i * 17, 317 + i * 2), Color("fff0c2"))


func paint_well(at: Vector2) -> void:
	# Stone well with wooden crank and a tiled canopy.
	ellipse(at + Vector2(0, 11), 51, 16, Color("3c9253", 0.34))
	ellipse(at + Vector2(0, 2), 32, 16, Color("7b827a"))
	ellipse(at + Vector2(0, -5), 31, 13, Color("e8ddbc"))
	ellipse(at + Vector2(0, -7), 23, 9, Color("427c8d"))
	for i in 6:
		var x := -27 + i * 10
		line(at + Vector2(x, -2), at + Vector2(x + 3, 5), Color("bdbaa6"), 2)
	line(at + Vector2(-26, -8), at + Vector2(-26, -52), Color("a36a40"), 8)
	line(at + Vector2(27, -8), at + Vector2(27, -52), Color("a36a40"), 8)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-43, -53),
				at + Vector2(0, -82),
				at + Vector2(43, -53),
				at + Vector2(32, -46),
				at + Vector2(0, -70),
				at + Vector2(-34, -46)
			]
		),
		Color("c95647")
	)
	line(at + Vector2(-38, -53), at + Vector2(0, -77), Color("f5a66a"), 3)
	line(at + Vector2(0, -77), at + Vector2(38, -53), Color("f5a66a"), 3)
	line(at + Vector2(-16, -29), at + Vector2(42, -29), Color("8e5d3d"), 5)
	draw_circle(at + Vector2(41, -29), 5, Color("f6d183"))
	line(at + Vector2(42, -29), at + Vector2(46, -18), Color("8e5d3d"), 3)
	line(at + Vector2(0, -29), at + Vector2(0, -15), Color("8b654b"), 2)
	draw_rect(Rect2(at.x - 9, at.y - 17, 18, 9), Color("c79d6a"))


func paint_hay_bale(at: Vector2, scale_factor: float) -> void:
	var sx := scale_factor
	ellipse(at + Vector2(0, 6) * sx, 28 * sx, 10 * sx, Color("6d8d4e", 0.30))
	poly(
		PackedVector2Array(
			[
				at + Vector2(-24, -7) * sx,
				at + Vector2(12, -12) * sx,
				at + Vector2(27, -3) * sx,
				at + Vector2(-10, 3) * sx
			]
		),
		Color("ffe091")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-10, 3) * sx,
				at + Vector2(27, -3) * sx,
				at + Vector2(27, 17) * sx,
				at + Vector2(-10, 22) * sx
			]
		),
		Color("d9a550")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-24, -7) * sx,
				at + Vector2(-10, 3) * sx,
				at + Vector2(-10, 22) * sx,
				at + Vector2(-24, 11) * sx
			]
		),
		Color("f1c56b")
	)
	for i in 4:
		line(
			at + Vector2(-21 + i * 10, -4) * sx,
			at + Vector2(-8 + i * 10, 0) * sx,
			Color("c68e40"),
			1.5
		)
	line(at + Vector2(-5, 2) * sx, at + Vector2(-5, 20) * sx, Color("f9e8b1"), 3 * sx)
	line(at + Vector2(13, -2) * sx, at + Vector2(13, 16) * sx, Color("f9e8b1"), 3 * sx)


func paint_barrel(at: Vector2) -> void:
	ellipse(at + Vector2(1, 8), 26, 9, Color("4d8c4f", 0.28))
	draw_rect(Rect2(at.x - 19, at.y - 29, 38, 37), Color("99613e"))
	poly(
		PackedVector2Array(
			[
				at + Vector2(-19, -24),
				at + Vector2(-12, -26),
				at + Vector2(-12, 7),
				at + Vector2(-19, 5)
			]
		),
		Color("c1864e")
	)
	for x in [-11, 0, 11]:
		line(at + Vector2(x, -27), at + Vector2(x, 7), Color("70482d"), 2)
	draw_rect(Rect2(at.x - 20, at.y - 24, 40, 5), Color("d5d7bc"))
	draw_rect(Rect2(at.x - 20, at.y - 3, 40, 5), Color("d5d7bc"))
	ellipse(at + Vector2(0, -29), 19, 7, Color("e5b775"))
	ellipse(at + Vector2(0, -30), 14, 4, Color("ae733f"))


func paint_market_cart(at: Vector2) -> void:
	# A small produce cart near the road, outside the clickable farm cells.
	if farm_art.paint(self, "market_cart", at + Vector2(0, 18), 182.0):
		return
	ellipse(at + Vector2(0, 24), 56, 15, Color("438e4a", 0.3))
	line(at + Vector2(-47, 13), at + Vector2(-62, 27), Color("925936"), 5)
	line(at + Vector2(37, 13), at + Vector2(51, 24), Color("925936"), 5)
	draw_rect(Rect2(at.x - 39, at.y - 18, 77, 32), Color("955d3d"))
	draw_rect(Rect2(at.x - 35, at.y - 17, 69, 21), Color("dfb66d"))
	for i in 6:
		draw_circle(
			at + Vector2(-23 + (i % 3) * 22, -13 - (i / 3) * 11),
			10,
			Color("f3bb43") if i % 2 == 0 else Color("ee6d48")
		)
		line(
			at + Vector2(-23 + (i % 3) * 22, -23 - (i / 3) * 11),
			at + Vector2(-20 + (i % 3) * 22, -27 - (i / 3) * 11),
			Color("409b4f"),
			3
		)
	for i in 2:
		draw_circle(at + Vector2(-27 + i * 59, 19), 14, Color("694936"))
		draw_circle(at + Vector2(-27 + i * 59, 19), 7, Color("d9c092"))
	line(at + Vector2(-39, -54), at + Vector2(-39, -20), Color("b17d51"), 5)
	line(at + Vector2(38, -54), at + Vector2(38, -20), Color("b17d51"), 5)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-50, -55),
				at + Vector2(49, -55),
				at + Vector2(39, -38),
				at + Vector2(-40, -38)
			]
		),
		Color("f7e9ba")
	)
	for i in 5:
		var px := -50 + i * 20
		poly(
			PackedVector2Array(
				[
					at + Vector2(px, -55),
					at + Vector2(px + 10, -55),
					at + Vector2(px + 8, -38),
					at + Vector2(px + 2, -38)
				]
			),
			Color("e66d53")
		)


func paint_house(at: Vector2) -> void:
	if farm_art.paint(self, "kitchen_cottage", at + Vector2(0, 20), 220.0):
		return
	ellipse(at + Vector2(0, 70), 109, 25, Color("478f4b", 0.34))
	poly(
		PackedVector2Array(
			[
				at + Vector2(-86, -23),
				at + Vector2(9, -46),
				at + Vector2(86, -16),
				at + Vector2(86, 74),
				at + Vector2(-86, 65)
			]
		),
		Color("d89d60")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-84, -30),
				at + Vector2(9, -49),
				at + Vector2(9, 69),
				at + Vector2(-84, 63)
			]
		),
		Color("f7d89c")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-106, -28),
				at + Vector2(-27, -115),
				at + Vector2(24, -111),
				at + Vector2(103, -25),
				at + Vector2(78, -9),
				at + Vector2(-28, -75),
				at + Vector2(-86, -8)
			]
		),
		Color("a94b42")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-106, -28),
				at + Vector2(-27, -115),
				at + Vector2(24, -111),
				at + Vector2(-66, -28)
			]
		),
		Color("ed8462")
	)
	line(at + Vector2(-99, -27), at + Vector2(-27, -105), Color("f8ad7b"), 6)
	# Roof shingles make the building less flat at phone resolution.
	for row in 3:
		for col in 4:
			var x := -84 + col * 13 + row * 6
			var y := -39 - col * 12 - row * 13
			line(at + Vector2(x, y), at + Vector2(x + 12, y + 5), Color("c76452", 0.7), 2)
	# Chimney, blue window, front door.
	draw_rect(Rect2(at.x + 40, at.y - 100, 18, 36), Color("a85f48"))
	draw_rect(Rect2(at.x + 37, at.y - 101, 24, 6), Color("e6b881"))
	draw_rect(Rect2(at.x - 58, at.y + 4, 39, 36), Color("6aacc1"))
	draw_rect(Rect2(at.x - 54, at.y + 7, 32, 28), Color("b7e6db"))
	line(at + Vector2(-38, 8), at + Vector2(-38, 34), Color("fff4cf"), 4)
	line(at + Vector2(-54, 21), at + Vector2(-23, 21), Color("fff4cf"), 4)
	# Window box, shutters and a short garden path.
	draw_rect(Rect2(at.x - 66, at.y + 2, 8, 42), Color("75a974"))
	draw_rect(Rect2(at.x - 17, at.y + 2, 8, 42), Color("75a974"))
	draw_rect(Rect2(at.x - 63, at.y + 39, 49, 10), Color("ae744d"))
	for off in [-54, -42, -29, -18]:
		paint_flower(at + Vector2(off, 38), Color("ff8d9b"))
	draw_rect(Rect2(at.x + 29, at.y + 15, 35, 55), Color("8c5539"))
	draw_rect(Rect2(at.x + 33, at.y + 19, 26, 49), Color("b4774e"))
	line(at + Vector2(43, 20), at + Vector2(43, 67), Color("e1a570"), 2)
	draw_circle(at + Vector2(55, 46), 3, Color("ffd77b"))
	for i in 3:
		ellipse(at + Vector2(27 + i * 14, 79 + i * 8), 25, 8, Color("f4d7a4"))
	paint_bush(at + Vector2(-75, 65))


func paint_barn(at: Vector2) -> void:
	if farm_art.paint(self, "village_barn", at + Vector2(0, 20), 194.0):
		return
	ellipse(at + Vector2(0, 70), 91, 22, Color("478f4b", 0.35))
	poly(
		PackedVector2Array(
			[
				at + Vector2(-72, -44),
				at + Vector2(-7, -89),
				at + Vector2(72, -42),
				at + Vector2(72, 68),
				at + Vector2(-72, 68)
			]
		),
		Color("c44d43")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-72, -44),
				at + Vector2(0, -119),
				at + Vector2(70, -43),
				at + Vector2(57, -34),
				at + Vector2(0, -95),
				at + Vector2(-59, -34)
			]
		),
		Color("e8895c")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-59, -30),
				at + Vector2(0, -95),
				at + Vector2(57, -34),
				at + Vector2(57, 68),
				at + Vector2(-59, 68)
			]
		),
		Color("ef7360")
	)
	line(at + Vector2(-65, -32), at + Vector2(0, -102), Color("ffe0a7"), 6)
	line(at + Vector2(0, -102), at + Vector2(65, -32), Color("ffe0a7"), 6)
	for i in 3:
		var y := -79 + i * 21
		line(at + Vector2(-39 + i * 13, y), at + Vector2(39 - i * 13, y), Color("c9574d", 0.8), 2)
	for i in 4:
		line(
			at + Vector2(-58, -17 + i * 18),
			at + Vector2(-31, -17 + i * 18),
			Color("f59a76", 0.6),
			2
		)
		line(
			at + Vector2(31, -17 + i * 18), at + Vector2(56, -17 + i * 18), Color("b84d42", 0.65), 2
		)
	draw_rect(Rect2(at.x - 30, at.y + 9, 60, 59), Color("874834"))
	draw_rect(Rect2(at.x - 25, at.y + 14, 50, 54), Color("be7450"))
	line(at + Vector2(-23, 17), at + Vector2(22, 65), Color("f6bc89"), 5)
	line(at + Vector2(22, 17), at + Vector2(-23, 65), Color("f6bc89"), 5)
	draw_circle(at + Vector2(0, -41), 15, Color("f5dcb4"))
	draw_circle(at + Vector2(0, -41), 9, Color("84c4cb"))
	for pos in [Vector2(-52, 42), Vector2(48, 38)]:
		draw_rect(Rect2(at.x + pos.x - 5, at.y + pos.y - 5, 10, 15), Color("f5d19b"))
		draw_circle(at + pos + Vector2(0, -5), 7, Color("6faf50"))


func paint_coop(at: Vector2) -> void:
	# The original rendered coop includes its own fences and resident chickens.
	if farm_art.paint(self, "chicken_coop", at + Vector2(0, 90), 300.0):
		paint_roaming_animal("chicken", at + Vector2(-68, 144), 0.68, 1.0, Vector2(14, 8))
		if game.ready_eggs():
			bubble("2 TELUR!", at + Vector2(0, -110), Color("fff7d6"), Color("76502f"))
		return
	# The large run extends in front of the house, with room for moving hens.
	poly(
		PackedVector2Array(
			[
				at + Vector2(-148, 79),
				at + Vector2(-110, 28),
				at + Vector2(110, 28),
				at + Vector2(150, 79),
				at + Vector2(125, 185),
				at + Vector2(-125, 185),
			]
		),
		Color("d7b77c")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-137, 83),
				at + Vector2(-102, 40),
				at + Vector2(102, 40),
				at + Vector2(138, 83),
				at + Vector2(116, 175),
				at + Vector2(-116, 175),
			]
		),
		Color("b98a58")
	)
	LivestockPainter.paint_pen_rail(self, at + Vector2(-141, 90), at + Vector2(-111, 45), 3)
	LivestockPainter.paint_pen_rail(self, at + Vector2(111, 45), at + Vector2(141, 90), 3)
	LivestockPainter.paint_pen_rail(self, at + Vector2(-111, 45), at + Vector2(111, 45), 6)
	ellipse(at + Vector2(0, 61), 89, 22, Color("478f4b", 0.33))
	poly(
		PackedVector2Array(
			[
				at + Vector2(-75, -13),
				at + Vector2(0, -67),
				at + Vector2(76, -13),
				at + Vector2(69, 55),
				at + Vector2(-70, 55)
			]
		),
		Color("df9d5b")
	)
	poly(
		PackedVector2Array(
			[
				at + Vector2(-82, -13),
				at + Vector2(0, -89),
				at + Vector2(81, -13),
				at + Vector2(65, -5),
				at + Vector2(0, -62),
				at + Vector2(-64, -5)
			]
		),
		Color("b77851")
	)
	for i in 5:
		line(
			at + Vector2(-69 + i * 16, -15 - (4 - abs(i - 2)) * 13),
			at + Vector2(-56 + i * 16, -8 - (4 - abs(i - 2)) * 13),
			Color("8f5e47", 0.72),
			2
		)
	draw_rect(Rect2(at.x - 26, at.y + 3, 52, 53), Color("8f5d3e"))
	draw_rect(Rect2(at.x - 22, at.y + 6, 44, 49), Color("ebc78b"))
	for i in 4:
		line(at + Vector2(-61 + i * 40, 30), at + Vector2(-41 + i * 40, 29), Color("f9e4b1"), 4)
	line(at + Vector2(-70, 42), at + Vector2(70, 42), Color("f5d19b"), 3)
	for x in [-63, 0, 63]:
		line(at + Vector2(x, 32), at + Vector2(x, 60), Color("e9c68a"), 4)
	LivestockPainter.paint_feed_trough(self, at + Vector2(-88, 129), 0.62)
	paint_roaming_animal("chicken", at + Vector2(-71, 112), 1.03, 1.0, Vector2(23, 12))
	paint_roaming_animal("chicken", at + Vector2(55, 120), 0.9, 2.5, Vector2(24, 13))
	paint_roaming_animal("chicken", at + Vector2(0, 154), 0.82, 4.2, Vector2(24, 10))
	LivestockPainter.paint_pen_rail(self, at + Vector2(-141, 90), at + Vector2(-125, 185), 4)
	LivestockPainter.paint_pen_rail(self, at + Vector2(141, 90), at + Vector2(125, 185), 4)
	LivestockPainter.paint_pen_rail(self, at + Vector2(-125, 185), at + Vector2(125, 185), 7)
	if game.ready_eggs():
		bubble("2 TELUR!", at + Vector2(0, -110), Color("fff7d6"), Color("76502f"))


func paint_plot(index: int, at: Vector2) -> void:
	var plot: Dictionary = game.plots[index]
	var unlocked: bool = plot["unlocked"]
	var is_selected := selected_plot == index
	var p := at + Vector2(0, 7)
	var locked_grass: Color = [Color("86c478"), Color("91cb7e"), Color("7ebd72")][index % 3]
	diamond(p + Vector2(0, 12), 76, 42, Color("458b4d", 0.25))
	diamond(p + Vector2(0, 8), 76, 42, Color("8b5632") if unlocked else Color("649e5f"))
	diamond(p, 74, 40, Color("bd7847") if unlocked else locked_grass)
	if unlocked:
		diamond(p, 66, 35, Color("a76139"))
		var crop: String = plot["crop"]
		var ready := crop != "" and game.is_ready(index)
		var elapsed := 0.0
		if crop != "":
			var growing := maxi(1, int(plot["ready_at"]) - int(plot["planted_at"]))
			elapsed = clampf(float(game.now() - int(plot["planted_at"])) / float(growing), 0.0, 1.0)
		var art_name := "soil_plot_empty"
		if ready:
			match crop:
				"gandum": art_name = "wheat_plot_ready"
				"jagung": art_name = "corn_plot_ready"
				"wortel": art_name = "carrot_plot_ready"
		elif crop != "" and elapsed >= 0.20 and elapsed < 0.45:
			art_name = "young_seedlings"
		var painted_crop_art := farm_art.paint(self, art_name, p, 149.0)
		if not painted_crop_art:
			for stripe in range(-2, 3):
				line(
					p + Vector2(stripe * 17 - 21, -10),
					p + Vector2(stripe * 17 + 7, 14),
					Color("c7814d"),
					2
				)
		if crop == "":
			# Faint furrows and flecks help empty plots look like worked soil.
			for ridge in 3:
				var dx := float(ridge - 1) * 19.0
				line(p + Vector2(dx - 15, -10), p + Vector2(dx + 12, 13), Color("f2b573", 0.48), 1.8)
				ellipse(p + Vector2(dx + 4, 6 - ridge * 3), 2.3, 1.2, Color("e2a16a", 0.54), 8)
		if crop != "":
			if art_name == "soil_plot_empty" or not painted_crop_art:
				for offset in [Vector2(-27, -6), Vector2(0, -17), Vector2(25, -5), Vector2(-5, 13)]:
					paint_crop(crop, p + offset, elapsed)
			if ready:
				var bubble_y := -96 if art_name != "soil_plot_empty" else -52
				ellipse(p + Vector2(1, bubble_y), 34, 16, Color("fff9d8"))
				label("SIAP!", p + Vector2(-22, bubble_y + 5), 16, Color("657542"))
			else:
				var ratio := clampf(elapsed, 0.0, 1.0)
				draw_rect(Rect2(p.x - 30, p.y - 47, 60, 9), Color("5e6d42"))
				draw_rect(Rect2(p.x - 28, p.y - 45, 56 * ratio, 5), Color("fff29d"))
				# Three quiet stage ticks help read growth even at small zoom.
				for marker in [0.22, 0.48, 0.80]:
					var marker_color := Color("f9e5ab") if elapsed >= marker else Color("926d48")
					draw_circle(p + Vector2(-28.0 + 56.0 * marker, -50.0), 2.3, marker_color)
	else:
		# Grass creeps across the locked beds without implying planted crops.
		for tuft in 7:
			var dx := float(tuft - 3) * 16.0
			var dy := 12.0 - absf(dx) * 0.17 + float((index + tuft) % 3) * 3.0
			var root := p + Vector2(dx, dy)
			var h := 8.0 + float((index * 7 + tuft * 3) % 7)
			line(root, root + Vector2(-5, -h), Color("579f58", 0.78), 2.2)
			line(root, root + Vector2(2, -h - 3), Color("c2e69b"), 2.2)
			if (index + tuft) % 4 == 0:
				draw_circle(root + Vector2(3, -h - 3), 2.8, Color("fff2c8"))
		# Locked land with a wooden price marker.
		draw_rect(Rect2(p.x - 5, p.y - 29, 10, 32), Color("805135"))
		line(p + Vector2(-2, -27), p + Vector2(-2, 0), Color("bc8756"), 2.0)
		ellipse(p + Vector2(0, -31), 21, 16, Color("b88950"))
		ellipse(p + Vector2(0, -34), 19, 14, Color("f4d69c"))
		label("+", p + Vector2(-7, -24), 24, Color("816245"))
	if is_selected and not plot_render_only:
		var pulse := 0.65 + 0.24 * sin(shimmer * 4.1)
		var corners := PackedVector2Array(
			[
				p + Vector2(0, -43),
				p + Vector2(78, 0),
				p + Vector2(0, 43),
				p + Vector2(-78, 0),
				p + Vector2(0, -43)
			]
		)
		draw_polyline(corners, Color(1.0, 0.97, 0.70, pulse), 5, true)


func paint_crop(id: String, at: Vector2, elapsed: float) -> void:
	# Visually distinct seed, sprout, leafy and mature stages; progression remains time-based.
	if elapsed < 0.20:
		ellipse(at + Vector2(0, 4), 11, 4, Color("5b422d", 0.28), 12)
		draw_circle(at + Vector2(0, -1.0 - elapsed * 21.0), 3.0, Color("b7db78"))
		return
	if elapsed < 0.45:
		var seedling_height := 6.0 + (elapsed - 0.20) * 49.0
		line(at + Vector2(0, 3), at + Vector2(0, -seedling_height), Color("479852"), 2.6)
		ellipse(at + Vector2(-6, -seedling_height * 0.55), 7.0, 3.5, Color("78c763"), 12)
		ellipse(at + Vector2(6, -seedling_height * 0.8), 7.0, 3.5, Color("a4dc70"), 12)
		return
	var grow := 0.3 + elapsed * 0.7
	var height := 19.0 * grow
	ellipse(at + Vector2(0, 3), 12, 4, Color("6c462d", 0.33))
	if elapsed >= 0.82:
		# A warm crown communicates that the crop is nearing harvest.
		draw_circle(at + Vector2(2, -height - 8), 2.7, Color("ffe99b", 0.74))
	match id:
		"gandum":
			for off in [-7, 0, 8]:
				var top := at + Vector2(off, -height - (abs(off) % 3))
				line(at + Vector2(off * 0.65, 0), top, Color("5b9d4b"), 3)
				if elapsed > 0.48:
					for leaf in 3:
						var y := float(leaf * 5)
						draw_circle(
							top + Vector2(-3 if leaf % 2 == 0 else 3, y), 3.4, Color("f9cf67")
						)
		"jagung":
			line(at, at + Vector2(0, -height - 5), Color("368e4f"), 4)
			poly(
				PackedVector2Array(
					[at, at + Vector2(-15, -height * 0.8), at + Vector2(-3, -height * 0.35)]
				),
				Color("54b65a")
			)
			poly(
				PackedVector2Array(
					[at, at + Vector2(16, -height * 0.85), at + Vector2(4, -height * 0.4)]
				),
				Color("74c05a")
			)
			if elapsed > 0.43:
				ellipse(at + Vector2(3, -height * 0.55), 6, 11 * grow, Color("f4d35f"))
		"wortel":
			for off in [-6, 0, 6]:
				line(at + Vector2(0, -3), at + Vector2(off, -height), Color("4f9a48"), 3)
			if elapsed > 0.48:
				poly(
					PackedVector2Array(
						[at + Vector2(-8, -5), at + Vector2(8, -5), at + Vector2(0, 13)]
					),
					Color("fa9342")
				)
		"tebu":
			for off in [-6, 6]:
				line(at + Vector2(off, 2), at + Vector2(off + 2, -height - 6), Color("8cc96b"), 5)
				line(
					at + Vector2(off, -height * 0.4),
					at + Vector2(off - 12, -height),
					Color("4c9d4d"),
					4
				)
				line(
					at + Vector2(off, -height * 0.7),
					at + Vector2(off + 11, -height - 10),
					Color("5cbb60"),
					4
				)
		"stroberi":
			for off in [-9, 0, 9]:
				line(at, at + Vector2(off * 1.4, -height), Color("3e9b4e"), 4)
				draw_circle(at + Vector2(off * 1.4, -height), 7, Color("50b459"))
			if elapsed > 0.6:
				for off in [-8, 8]:
					draw_circle(at + Vector2(off, -height * 0.5), 5, Color("e8585f"))
		"kedelai":
			for off in [-8, 0, 8]:
				line(at + Vector2(off * 0.5, 2), at + Vector2(off, -height), Color("4c9b4b"), 3)
				ellipse(at + Vector2(off - 4, -height * 0.65), 7 * grow, 4, Color("75bd59"))
				if elapsed > 0.5:
					for pod in range(2):
						ellipse(
							at + Vector2(off + 3, -height * 0.65 + pod * 6), 3.4, 5, Color("b5c65e")
						)
		"kentang":
			for off in [-7, 5]:
				line(at, at + Vector2(off, -height), Color("478e4c"), 3)
				for leaf in 3:
					ellipse(
						at + Vector2(off + (leaf - 1) * 6, -height + leaf * 7),
						6,
						3.8,
						Color("65b758")
					)
			if elapsed > 0.65:
				for off in [-7, 3, 10]:
					ellipse(at + Vector2(off, 1), 6, 4, Color("b99464"))
		"labu":
			line(at + Vector2(-12, 0), at + Vector2(10, -height * 0.45), Color("4e9950"), 3)
			ellipse(at + Vector2(-8, -height * 0.55), 11 * grow, 5, Color("63ac53"))
			ellipse(at + Vector2(12, -height * 0.8), 9 * grow, 5, Color("7ac45e"))
			if elapsed > 0.45:
				ellipse(at + Vector2(0, -4), 12 * grow, 10 * grow, Color("ee9b43"))
				for off in [-4, 4]:
					line(
						at + Vector2(off * grow, -12 * grow),
						at + Vector2(off * grow, 4 * grow),
						Color("d57936"),
						1.6
					)
				line(at + Vector2(0, -12 * grow), at + Vector2(0, -17 * grow), Color("51864b"), 3)
		"padi":
			for off in [-8, -2, 5, 11]:
				var tip := at + Vector2(off - 3, -height - 5)
				line(at + Vector2(off * 0.5, 1), tip, Color("499856"), 2.8)
				if elapsed > 0.45:
					for grain in 4:
						draw_circle(tip + Vector2(2 + grain * 2, grain * 4), 2.6, Color("dfca62"))
		"tomat":
			for off in [-10, 1, 10]:
				line(at, at + Vector2(off, -height), Color("4c9454"), 3.0)
				ellipse(at + Vector2(off, -height), 7.5, 4.5, Color("69b65d"))
				if elapsed > 0.55:
					draw_circle(at + Vector2(off, -height * 0.6), 5.8 * grow, Color("e45d54"))
					line(at + Vector2(off, -height * 0.6 - 4), at + Vector2(off + 3, -height * 0.6 - 6), Color("43824b"), 1.9)
		"cabai":
			for off in [-8, 0, 9]:
				line(at, at + Vector2(off, -height - 3), Color("43894c"), 3)
				ellipse(at + Vector2(off - 4, -height * 0.8), 7, 3.2, Color("70bf63"))
				if elapsed > 0.52:
					line(at + Vector2(off, -height * 0.55), at + Vector2(off + 3, -height * 0.15), Color("d63d48"), 4.5 * grow)
		"kopi":
			line(at, at + Vector2(0, -height - 6), Color("4e854b"), 4)
			for off in [-10, 10]:
				for row in 2:
					var tip := at + Vector2(off, -height * (0.48 + row * 0.28))
					line(at + Vector2(0, -height * 0.35), tip, Color("548f53"), 2.5)
					ellipse(tip, 8.5, 4.0, Color("619e50"))
					if elapsed > 0.58:
						draw_circle(tip + Vector2(-2, 3), 3.6 * grow, Color("aa5840"))
		"nanas":
			for off in [-9, -4, 3, 10]:
				line(at + Vector2(0, 1), at + Vector2(off, -height - 10), Color("4d9954"), 3.4)
			if elapsed > 0.48:
					ellipse(at + Vector2(0, -height * 0.35), 9 * grow, 13 * grow, Color("efc45a"))
					for stripe in [-4, 0, 4]:
						line(at + Vector2(stripe - 5, -height * 0.35 - 6), at + Vector2(stripe + 4, -height * 0.35 + 7), Color("c99740", 0.8), 1.3)


func paint_front_decor() -> void:
	# Flowers frame the farm, without hiding the playable plots.
	for i in 24:
		var x := float((i * 79 + 32) % 720)
		var y := float(681 + (i * 43) % 100)
		if absf(x - 355) < 155 and y < 706:
			continue
		paint_flower(Vector2(x, y), Color("fffaed") if i % 2 == 0 else Color("ef8c96"))
	for pos in [Vector2(110, 689), Vector2(590, 705), Vector2(502, 755)]:
		paint_bush(pos)
	paint_owned_constructions()
	# Small direction stone at the bottom edge.
	ellipse(Vector2(347, 750), 44, 17, Color("6bb367"))
	ellipse(Vector2(347, 742), 35, 15, Color("c7d6ac"))


func paint_owned_constructions() -> void:
	# Compact, recognisable miniatures keep the existing farm interaction areas clear.
	if game.has_construction("kandang_babi"):
		LivestockPainter.paint_small_paddock(self, Vector2(48, 459), Color("efb5bc"), "BABI")
	if game.has_construction("kandang_kambing"):
		LivestockPainter.paint_small_paddock(self, Vector2(671, 485), Color("e8dec5"), "KAMBING")
	if game.has_construction("toko_roti"):
		paint_small_workshop(Vector2(272, 246), Color("e4a35d"), "ROTI")
	if game.has_construction("pabrik_susu"):
		paint_small_workshop(Vector2(549, 264), Color("8dccd4"), "SUSU")
	for i in game.construction_count("petak_bunga"):
		var at := Vector2(68 + i * 24, 354)
		ellipse(at + Vector2(0, 6), 15, 6, Color("a36f4a"))
		for j in 3:
			paint_flower(
				at + Vector2(j * 8 - 8, 0), Color("f0879c") if j % 2 == 0 else Color("f7dd7d")
			)
	if game.has_construction("gazebo"):
		var at := Vector2(666, 614)
		ellipse(at + Vector2(0, 8), 35, 10, Color("c49b61"))
		for side in [-22, 22]:
			line(at + Vector2(side, 3), at + Vector2(side, -29), Color("80552f"), 5)
		poly(
			PackedVector2Array(
				[at + Vector2(-39, -29), at + Vector2(0, -56), at + Vector2(39, -29)]
			),
			Color("bb7441")
		)
	if game.has_construction("kincir_angin"):
		var at := Vector2(58, 301)
		poly(
			PackedVector2Array([at + Vector2(-9, 15), at + Vector2(0, -43), at + Vector2(9, 15)]),
			Color("f1e2b7")
		)
		for offset in [Vector2(0, -23), Vector2(20, -43), Vector2(0, -63), Vector2(-20, -43)]:
			line(at + Vector2(0, -43), at + offset, Color("a37348"), 7)
		draw_circle(at + Vector2(0, -43), 5, Color("fff4cc"))
	if game.has_construction("kolam"):
		var at := Vector2(649, 743)
		ellipse(at + Vector2(0, 0), 38, 17, Color("e1d4aa"))
		ellipse(at + Vector2(0, -3), 31, 12, Color("6bc7d9"))
		for offset in [Vector2(-11, -5), Vector2(12, -1)]:
			draw_circle(at + offset, 3, Color("f5fcdf"))


func paint_shortcut_sign(at: Vector2, title: String, fill: Color) -> void:
	var sign_size := Vector2(156, 48)
	# Raised wood signs remain legible above grass, hedges and decorations.
	draw_rect(Rect2(at + Vector2(3, 5), sign_size), Color("487d3e", 0.32))
	draw_rect(Rect2(at, sign_size), Color("825438"))
	draw_rect(Rect2(at + Vector2(4, 4), sign_size - Vector2(8, 8)), fill)
	draw_rect(Rect2(at + Vector2(8, 8), Vector2(140, 3)), Color("fff3cf", 0.7))
	draw_circle(at + Vector2(12, 25), 3, Color("ab784e"))
	draw_circle(at + Vector2(144, 25), 3, Color("ab784e"))
	var width := ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	label(title, at + Vector2((156 - width) * 0.5, 31), 18, Color("70462e"))


func paint_small_workshop(at: Vector2, wall: Color, title: String) -> void:
	ellipse(at + Vector2(0, 9), 34, 9, Color("447d4b", 0.28))
	draw_rect(Rect2(at + Vector2(-24, -21), Vector2(48, 30)), wall)
	poly(
		PackedVector2Array([at + Vector2(-31, -21), at + Vector2(0, -41), at + Vector2(31, -21)]),
		Color("a65f40")
	)
	draw_rect(Rect2(at + Vector2(-6, -11), Vector2(12, 20)), Color("765037"))
	label(title, at + Vector2(-20, -45), 12, Color("fff4d4"))


func paint_mission_board() -> void:
	# Accessible sign in the quiet, lower-right edge of the farm.
	ellipse(Vector2(599, 757), 108, 12, Color("417c3f", 0.38))
	for x in [515, 675]:
		draw_rect(Rect2(x, 727, 13, 35), Color("865b36"))
		draw_rect(Rect2(x + 2, 729, 4, 30), Color("c89456"))
	draw_rect(Rect2(490, 663, 212, 88), Color("745435"))
	draw_rect(Rect2(495, 668, 202, 78), Color("f6df9d"))
	draw_rect(Rect2(503, 675, 186, 64), Color("ffefbd"))
	draw_circle(Vector2(515, 687), 4, Color("bf8659"))
	draw_circle(Vector2(675, 687), 4, Color("bf8659"))
	label("★ MISI HARIAN", Vector2(513, 703), 20, Color("705536"))
	label("HADIAH  %d/3  ›" % game.daily_claimed_count(), Vector2(513, 730), 18, Color("368d5b"))


func paint_flower(at: Vector2, color: Color) -> void:
	line(at + Vector2(0, 8), at + Vector2(0, -2), Color("429854"), 2)
	for a in 5:
		var p := at + Vector2(cos(a * TAU / 5.0) * 5, sin(a * TAU / 5.0) * 5 - 4)
		draw_circle(p, 3.5, color)
	draw_circle(at + Vector2(0, -4), 3, Color("f3c755"))


func label(value: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func bubble(value: String, at: Vector2, background: Color, ink: Color) -> void:
	ellipse(at + Vector2(0, -12), 62, 23, Color("588e53", 0.2))
	ellipse(at + Vector2(0, -18), 61, 23, background)
	poly(
		PackedVector2Array([at + Vector2(-9, 0), at + Vector2(0, 15), at + Vector2(11, 0)]),
		background
	)
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	label(value, at + Vector2(-width * 0.5, -12), 17, ink)
