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
const ART_DIR_REGIONS := "res://assets/world_regions/"
const ART_IDS_REGIONS := ["region_mill", "region_playground", "region_fishing", "region_mine", "region_festival", "region_camp", "region_village", "region_cafe", "region_stable", "region_station", "region_school", "region_botanical", "region_resort", "region_tourism", "region_arena", "region_harbor"]

var sprites: Dictionary = {}
var ranch_game
var _reference_checked: Dictionary = {}


func ensure_reference(asset_id: String) -> void:
	if asset_id=="region_mill" and not _reference_checked.has(asset_id):
		var texture=load("res://assets/landmark_hd/flour_mill.png") as Texture2D
		var region=texture.get_image().get_used_rect()
		sprites[asset_id]={"texture":texture,"region":Rect2(region),"anchor":Vector2(region.size.x*.5,region.size.y*.96)}
		_reference_checked[asset_id]=true
		return
	if _reference_checked.has(asset_id): return
	_reference_checked[asset_id] = true
	# Keep the earlier colorful fenced pens. The reference atlas replaces them
	# with smaller standalone huts when these IDs are requested for painting.
	if asset_id in ["chicken_coop", "cow_pen", "pig_pen", "goat_pen"] and sprites.has(asset_id): return
	var sprite := ReferenceAssets.sprite(asset_id)
	if not sprite.is_empty(): sprites[asset_id] = sprite


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
	_load_collection(ART_DIR_REGIONS, ART_IDS_REGIONS)
	_load_living_garden()
	_load_ranch()
	_load_colorful()
	_load_garden_catalog()


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


func _load_living_garden() -> void:
	var path:="res://assets/living_garden/manifest.json"
	if not FileAccess.file_exists(path): return
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not manifest is Dictionary: return
	var atlases: Dictionary={}
	for entry in manifest.get("assets",[]):
		var atlas_path: String=entry.get("atlas","")
		if not atlases.has(atlas_path): atlases[atlas_path]=load(atlas_path) as Texture2D
		var source: Texture2D=atlases[atlas_path]
		if source==null: continue
		var packed: Array=entry.get("region",[])
		var anchor: Array=entry.get("anchor",[])
		if packed.size()!=4 or anchor.size()!=2: continue
		sprites[str(entry.id)]={"texture":source,"region":Rect2(float(packed[0]),float(packed[1]),float(packed[2]),float(packed[3])),"anchor":Vector2(float(anchor[0]),float(anchor[1]))}


func _load_ranch() -> void:
	var path="res://assets/ranch/manifest.json"
	if not FileAccess.file_exists(path): return
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not manifest is Dictionary: return
	for entry in manifest.get("pens",[]):
		var source=load(str(entry.path)) as Texture2D
		if source==null: continue
		var rect: Array=entry.region
		sprites[str(entry.id)]={"texture":source,"region":Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3])),"anchor":Vector2(float(entry.anchor[0]),float(entry.anchor[1]))}
func ranch_width(asset_id: String,width: float) -> float:
	if ranch_game==null: return preload("res://scripts/district_scenes.gd").width(asset_id,width)
	for species in preload("res://scripts/ranch_state.gd").SPECIES:
		if str(preload("res://scripts/ranch_state.gd").INFO[species].asset)==asset_id:
			return preload("res://scripts/ranch_state.gd").pen_width(ranch_game,species)
	return preload("res://scripts/district_scenes.gd").width(asset_id,width)

func paint(canvas: CanvasItem, asset_id: String, ground_at: Vector2, visible_width: float,tint: Color=Color.WHITE) -> bool:
	var scenes=preload("res://scripts/district_scenes.gd")
	if scenes.PARTS.has(asset_id):
		scenes.paint(self,canvas,asset_id,ground_at,visible_width,tint,preload("res://scripts/asset_edit.gd").facing_at(ranch_game,ground_at))
		return true
	return paint_single(canvas,asset_id,ground_at,visible_width,tint,false,preload("res://scripts/asset_edit.gd").facing_at(ranch_game,ground_at))

func paint_single(canvas: CanvasItem, asset_id: String, ground_at: Vector2, visible_width: float,tint: Color=Color.WHITE,exact: bool=false,flip: bool=false) -> bool:
	ensure_reference(asset_id)
	if not sprites.has(asset_id):
		return false
	var sprite: Dictionary = sprites[asset_id]
	var texture: Texture2D = sprite["texture"]
	var region: Rect2 = sprite["region"]
	var anchor: Vector2 = sprite["anchor"]
	var scale_factor := (visible_width if exact else ranch_width(asset_id,visible_width)) / region.size.x
	var draw_size := region.size * scale_factor
	canvas.draw_texture_rect_region(
		texture, mirrored_rect(Rect2(ground_at - anchor * scale_factor, draw_size),ground_at,flip,true), region,tint
	)
	return true


func ground_bounds(asset_id: String, ground_at: Vector2, visible_width: float) -> Rect2:
	var scenes=preload("res://scripts/district_scenes.gd")
	if scenes.PARTS.has(asset_id):return scenes.bounds(self,asset_id,ground_at,visible_width,preload("res://scripts/asset_edit.gd").facing_at(ranch_game,ground_at))
	return single_bounds(asset_id,ground_at,visible_width,false,preload("res://scripts/asset_edit.gd").facing_at(ranch_game,ground_at))

func single_bounds(asset_id: String, ground_at: Vector2, visible_width: float,exact: bool=false,flip: bool=false) -> Rect2:
	ensure_reference(asset_id)
	# The actual non-transparent sprite footprint, including its height above
	# the ground anchor. A point-only clearance can still bury a road in art.
	if not sprites.has(asset_id):
		return Rect2(ground_at - Vector2(visible_width * 0.5, visible_width),
			Vector2(visible_width, visible_width * 1.2))
	var sprite: Dictionary = sprites[asset_id]
	var region: Rect2 = sprite["region"]
	var scale_factor := (visible_width if exact else ranch_width(asset_id,visible_width)) / region.size.x
	return mirrored_rect(Rect2(ground_at - Vector2(sprite["anchor"]) * scale_factor,
		region.size * scale_factor),ground_at,flip,false)


func _load_colorful() -> void:
	var path="res://assets/colorful_garden/manifest.json"
	if not FileAccess.file_exists(path): return
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not manifest is Dictionary: return
	for entry in manifest.get("assets",[]):
		var texture=load(str(entry.path)) as Texture2D
		if texture==null: continue
		var r: Array=entry.region
		sprites[str(entry.id)]={"texture":texture,"region":Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])),"anchor":Vector2(float(entry.anchor[0]),float(entry.anchor[1]))}

func _load_garden_catalog() -> void:
	# The old mine atlas cell contains colored pixels from neighboring cells.
	# Keep resource rocks as a standalone sprite with a stable ground anchor.
	var boulder := load("res://assets/art_v11/resource_boulder_clean.png") as Texture2D
	if boulder != null:
		var extent := boulder.get_size()
		sprites["resource_boulder"] = {"texture": boulder,
			"region": Rect2(Vector2.ZERO, extent),
			"anchor": Vector2(extent.x * 0.5, extent.y * 0.96)}
		_reference_checked["resource_boulder"] = true
	for pair in [["garden_tree","apple_tree"],["garden_stall","market_cart"]]:
		if sprites.has(pair[1]): sprites[pair[0]]=sprites[pair[1]]
	var texture=load("res://assets/decor/grass_patch.svg") as Texture2D
	if texture!=null: sprites["grass_patch"]={"texture":texture,"region":Rect2(0,0,160,108),"anchor":Vector2(80,60)}

func mirrored_rect(rect: Rect2,point: Vector2,flip: bool,negative: bool) -> Rect2:
	if not flip:return rect
	var result=Rect2(Vector2(2*point.x-rect.end.x,rect.position.y),rect.size)
	if negative:result.size.x=-result.size.x
	return result
