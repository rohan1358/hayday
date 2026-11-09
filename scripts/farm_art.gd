class_name FarmArt
extends RefCounted

# Draw the original isometric illustrations at world-space ground anchors.
# Use imported PNG subregions directly so we don't duplicate texture data in VRAM.
const ART_DIR_V2 := "res://assets/art_v2/"
const ART_IDS_V2 := [
	"kitchen_cottage", "village_barn", "apple_tree", "soil_plot_empty",
	"wheat_plot_ready", "flower_garden"
]
const ART_DIR_V3 := "res://assets/art_v3/"
const ART_IDS_V3 := [
	"chicken_coop", "cow_pen", "corn_plot_ready", "carrot_plot_ready", "young_seedlings"
]
const ART_DIR_V4 := "res://assets/art_v4/"
const ART_IDS_V4 := [
	"market_cart", "fence_straight", "fence_corner", "flowering_hedge", "stone_path_tile"
]
const ART_DIR_V5 := "res://assets/art_v5/"
const ART_IDS_V5 := [
	"wooden_crates", "hay_stack", "flower_patch", "decorative_pond", "rustic_lamp"
]
const ART_DIR_V6 := "res://assets/art_v6/"
const ART_IDS_V6 := [
	"harvest_baskets", "wooden_signpost", "wishing_well",
	"flowering_bushes", "arched_fence", "water_tower"
]
const ART_DIR_V7 := "res://assets/art_v7/"
const ART_IDS_V7 := ["bakery_building", "dairy_building", "feed_mill_building"]
const ART_DIR_V8 := "res://assets/art_v8/"
const ART_IDS_V8 := ["pig_pen", "goat_pen"]
const ART_DIR_V9 := "res://assets/art_v9/"
const ART_IDS_V9 := ["delivery_depot", "delivery_truck"]
const ART_DIR_V10 := "res://assets/art_v10/"
const ART_IDS_V10 := ["sorting_trolley", "village_waypost"]
const ART_DIR_V11 := "res://assets/art_v11/"
const ART_IDS_V11 := [
	"pollinator_house", "herb_drying_rack", "rainwater_collector", "wildflower_crescent"
]

var sprites: Dictionary = {}


func _init() -> void:
	_load_collection(ART_DIR_V2, ART_IDS_V2)
	_load_collection(ART_DIR_V3, ART_IDS_V3)
	_load_collection(ART_DIR_V4, ART_IDS_V4)
	_load_collection(ART_DIR_V5, ART_IDS_V5)
	_load_collection(ART_DIR_V6, ART_IDS_V6)
	_load_collection(ART_DIR_V7, ART_IDS_V7)
	_load_collection(ART_DIR_V8, ART_IDS_V8)
	_load_collection(ART_DIR_V9, ART_IDS_V9)
	_load_collection(ART_DIR_V10, ART_IDS_V10)
	_load_collection(ART_DIR_V11, ART_IDS_V11)


func _load_collection(directory: String, asset_ids: Array) -> void:
	var anchors: Dictionary = {}
	if FileAccess.file_exists(directory + "anchors.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory + "anchors.json"))
		if parsed is Dictionary:
			anchors = parsed
	var bounds_by_id: Dictionary = {}
	if FileAccess.file_exists(directory + "manifest.json"):
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory + "manifest.json"))
		if manifest is Dictionary and manifest.has("assets"):
			for entry in manifest["assets"]:
				if entry is Dictionary and entry.has("id") and entry.has("nontransparent_bounds_px"):
					bounds_by_id[String(entry["id"])] = entry["nontransparent_bounds_px"]
	for asset_id in asset_ids:
		var path: String = directory + String(asset_id) + ".png"
		if not ResourceLoader.exists(path):
			continue
		var source := load(path) as Texture2D
		if source == null:
			continue
		var opaque_bounds := Rect2(Vector2.ZERO, source.get_size())
		var packed_bounds: Variant = bounds_by_id.get(asset_id, [])
		if packed_bounds is Array and packed_bounds.size() == 4:
			opaque_bounds = Rect2(
				Vector2(float(packed_bounds[0]), float(packed_bounds[1])),
				Vector2(
					float(packed_bounds[2]) - float(packed_bounds[0]),
					float(packed_bounds[3]) - float(packed_bounds[1])
				)
			)
		if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
			continue
		var anchor := Vector2(source.get_width() * 0.5, source.get_height() * 0.78)
		if anchors.has(asset_id) and anchors[asset_id] is Array:
			var coords: Array = anchors[asset_id]
			if coords.size() == 2:
				anchor = Vector2(float(coords[0]), float(coords[1]))
		sprites[asset_id] = {
			"texture": source,
			"region": opaque_bounds,
			"anchor": anchor - Vector2(opaque_bounds.position)
		}


func paint(canvas: CanvasItem, asset_id: String, ground_at: Vector2, visible_width: float) -> bool:
	if not sprites.has(asset_id):
		return false
	var sprite: Dictionary = sprites[asset_id]
	var texture: Texture2D = sprite["texture"]
	var region: Rect2 = sprite["region"]
	var anchor: Vector2 = sprite["anchor"]
	var scale_factor := visible_width / region.size.x
	var draw_size := region.size * scale_factor
	canvas.draw_texture_rect_region(
		texture, Rect2(ground_at - anchor * scale_factor, draw_size), region
	)
	return true


func ground_bounds(asset_id: String, ground_at: Vector2, visible_width: float) -> Rect2:
	# The actual non-transparent sprite footprint, including its height above
	# the ground anchor. A point-only clearance can still bury a road in art.
	if not sprites.has(asset_id):
		return Rect2(ground_at - Vector2(visible_width * 0.5, visible_width),
			Vector2(visible_width, visible_width * 1.2))
	var sprite: Dictionary = sprites[asset_id]
	var region: Rect2 = sprite["region"]
	var scale_factor := visible_width / region.size.x
	return Rect2(ground_at - Vector2(sprite["anchor"]) * scale_factor,
		region.size * scale_factor)
