class_name ReferenceAssets
extends RefCounted

# The supplied sheets stay intact. AtlasTexture/texture regions select a cell
# at runtime, so the artwork is neither redrawn nor duplicated into many PNGs.
const GRIDS := {
	"season_scenery":Vector2i(3,2),
	"crops":Vector2i(5,4), "ranch":Vector2i(6,4),
	"production":Vector2i(6,4), "logistics":Vector2i(4,4),
	"orchard":Vector2i(4,4), "orchard_harvested":Vector2i(4,4), "greenhouse":Vector2i(4,4),
	"playground":Vector2i(4,4), "market":Vector2i(4,4),
	"fishing":Vector2i(4,4), "mine":Vector2i(4,5),
	"festival":Vector2i(4,4), "forest":Vector2i(4,4),
	"camping":Vector2i(4,4), "decoration":Vector2i(4,4),
	"village":Vector2i(4,4), "cafe":Vector2i(4,4),
	"horse":Vector2i(4,4), "train":Vector2i(4,4),
	"school":Vector2i(4,4), "people":Vector2i(4,4),
	"festival_extra":Vector2i(4,4), "harbor":Vector2i(4,4),
	"crop_stages":Vector2i(3,8), "upgrades":Vector2i(5,4),
	"terrain":Vector2i(4,4),
}
const CROPS := {
	"gandum":[0,0], "jagung":[1,0], "wortel":[2,0],
	"kentang":[3,0], "tebu":[4,0], "stroberi":[0,1],
	"kedelai":[1,1], "padi":[2,1], "tomat":[3,1],
	"cabai":[4,1], "labu":[0,2],
}
const ALIASES := {
	"scene_train":["train",1,0],"scene_wagon":["train",2,0],"scene_rail":["train",0,1],"scene_dock":["harbor",1,0],"scene_crane":["harbor",0,1],"scene_horse":["horse",0,1],"scene_horse_white":["horse",1,1],"scene_horse_black":["horse",2,1],"scene_horse_arena":["horse",1,0],"scene_fishing_hut":["fishing",2,2],"scene_festival_tent":["festival",0,0],"scene_campfire":["camping",1,0],
	"autumn_maple":["season_scenery",0,0], "snow_pine":["season_scenery",1,0], "sunflower_patch":["season_scenery",2,0],
	"snow_cabin":["season_scenery",0,1], "snow_greenhouse":["season_scenery",1,1], "frozen_lake":["season_scenery",2,1],
	"wheat_plot_ready":["crops",0,0],
	"corn_plot_ready":["crops",1,0],
	"carrot_plot_ready":["crops",2,0],
	"chicken_coop":["ranch",4,1], "cow_pen":["ranch",5,1],
	"pig_pen":["ranch",0,2], "goat_pen":["ranch",2,2],
	"resource_boulder":["mine",1,1], "resource_logs":["forest",1,1],
	"apple_tree":["orchard",0,0],
	"region_playground":["playground",3,0],
	"region_fishing":["fishing",1,2],
	"region_mine":["mine",1,0],
	"region_festival":["festival",1,0],
	"region_camp":["camping",0,0],
	"region_village":["village",0,0],
	"region_cafe":["cafe",0,0],
	"region_stable":["horse",0,0],
	"region_station":["train",0,0],
	"region_botanical":["greenhouse",3,2],
	"region_resort":["fishing",0,2],
	"region_tourism":["market",2,1],
	"region_arena":["festival",3,0],
	"region_school":["village",2,0],
	"region_harbor":["harbor",0,0],
	"region_card_school":["school",0,0],
	"region_card_production":["production",1,0],
	"region_card_arena":["festival_extra",0,0],
	"region_card_neighbor":["people",2,0],
}
const CROP_STAGES := {
	"gandum":0, "jagung":1, "wortel":2, "padi":3,
	"tomat":4, "labu":5, "stroberi":6,
}
const DECOR_CELLS := {
	"ref_sprinkler":["crops",1,3],
	"ref_tractor":["crops",2,3],
	"ref_kolam_bebek":["ranch",3,2],
	"ref_pengolah_gula":["production",0,1],
	"ref_silo":["logistics",2,0],
	"ref_sortir_buah":["orchard",3,3],
	"ref_pengatur_iklim":["greenhouse",2,0],
	"ref_ayunan":["playground",0,0],
	"ref_kios_bunga":["market",2,0],
	"ref_dermaga":["fishing",1,2],
	"ref_bengkel_tambang":["mine",2,0],
	"ref_panggung_festival":["festival",1,0],
	"ref_penggergajian":["forest",1,0],
	"ref_tenda":["camping",0,0],
	"ref_air_mancur":["decoration",0,1],
	"ref_kotak_surat":["village",0,1],
	"ref_meja_kafe":["cafe",2,0],
	"ref_istal_kuda":["horse",0,0],
	"ref_sinyal_kereta":["train",2,1],
	"ref_sekolah":["school",0,0],
	"ref_papan_sekolah":["school",3,0],
	"ref_npc_petani":["people",1,0],
	"ref_arena_panen":["festival_extra",0,0],
	"ref_kapal_dagang":["harbor",2,0],
	"ref_rumah_kaca_besar":["upgrades",4,3],
	"ref_jembatan_batu":["terrain",3,2],
}

static func cell_for(id: String) -> Array:
	if id.begins_with("fruit_tree_"):
		var parts := id.trim_prefix("fruit_tree_").rsplit("_", true, 1)
		var order := ["apel", "jeruk", "mangga", "pisang", "ceri", "lemon", "alpukat", "kelapa", "persik", "pir", "kakao", "biji_kopi"]
		var index := order.find(parts[0]) if parts.size() == 2 else -1
		if index >= 0: return ["orchard" if parts[1] == "ripe" else "orchard_harvested", index % 4, floori(float(index) / 4.0)]
	if DECOR_CELLS.has(id): return DECOR_CELLS[id]
	if id.begins_with("ref_crop_"):
		var crop := id.trim_prefix("ref_crop_")
		if CROPS.has(crop):
			var cell: Array = CROPS[crop]
			return ["crops",cell[0],cell[1]]
	if id.begins_with("ref_stage_"):
		var parts := id.trim_prefix("ref_stage_").rsplit("_", true, 1)
		if parts.size() == 2 and CROP_STAGES.has(parts[0]) and parts[1].is_valid_int():
			return ["crop_stages",int(parts[1]),CROP_STAGES[parts[0]]]
	return ALIASES.get(id, [])

static var clean_cache: Dictionary={}
static func sprite(id: String) -> Dictionary:
	if clean_cache.has(id):return clean_cache[id]
	var clean_path="res://assets/clean_reference/"+id+".png"
	if ResourceLoader.exists(clean_path):
		var cleaned=load(clean_path) as Texture2D
		var result={"texture":cleaned,"region":Rect2(Vector2.ZERO,cleaned.get_size()),"anchor":Vector2(cleaned.get_width()*.5,cleaned.get_height()*.96)}
		clean_cache[id]=result;return result
	var cell := cell_for(id)
	if cell.is_empty(): return {}
	var sheet := str(cell[0])
	var texture := load("res://assets/reference_atlases/%s.png" % sheet) as Texture2D
	if texture == null: return {}
	var grid: Vector2i = GRIDS[sheet]
	var width := float(texture.get_width()) / float(grid.x)
	var height := float(texture.get_height()) / float(grid.y)
	var region := Rect2(float(cell[1])*width + 2.0, float(cell[2])*height + 2.0, width - 4.0, height - 4.0)
	if sheet in ["orchard", "orchard_harvested"] and int(cell[2]) < 3:
		# The authored tree rows are tighter than the decorative bottom row.
		# Keep neighboring trees and the sorting-stall roof out of each sprite.
		region.position.y = float([0, 310, 610][int(cell[2])])
		region.size.y = 290.0 if int(cell[2]) == 2 else 300.0
	if sheet == "crop_stages":
		# Each growth-stage illustration occupies only ~220 of its 362-pixel
		# atlas cell. Trim the transparent sides before fitting it to a bed.
		# The three columns have different offsets but share the same footprint.
		var left: int = [84, 69, 55][int(cell[1])]
		region = Rect2(float(cell[1])*width + float(left), float(cell[2])*height, 220.0, height)
		if int(cell[2]) == CROP_STAGES["stroberi"]:
			# The next atlas row starts inside this cell's bottom padding.
			region.size.y = 140.0
	if sheet in ["fishing","horse","harbor","train","village","cafe","camping","festival","market","greenhouse"]:
		var rows={"fishing":[0,232,446,716,1024],"horse":[0,276,512,747,1024],"harbor":[0,300,560,790,1024]}.get(sheet,[0,256,512,768,1024])
		var ry=int(cell[2]);var scale_y=float(texture.get_height())/1024.0
		region.position.y=float(rows[ry])*scale_y;region.size.y=float(rows[ry+1]-rows[ry])*scale_y
		var source=texture.get_image().get_region(Rect2i(region))
		var cleaned=primary_component(source)
		var used=cleaned.get_used_rect()
		if used.has_area():cleaned=cleaned.get_region(used)
		var result={"texture":ImageTexture.create_from_image(cleaned),"region":Rect2(Vector2.ZERO,cleaned.get_size()),"anchor":Vector2(cleaned.get_width()*.5,cleaned.get_height()*.96)}
		clean_cache[id]=result;return result
	return {"texture":texture, "region":region, "anchor":Vector2(region.size.x * 0.5,region.size.y * 0.88)}

# Isolate the selected illustration; transparent padding can contain fragments
# of the adjacent authored cell. Retain the primary connected silhouette only.
static func primary_component(source: Image) -> Image:
	var w=source.get_width();var h=source.get_height();var visited=PackedByteArray();visited.resize(w*h)
	var best=PackedInt32Array()
	for y in h:
		for x in w:
			var index=y*w+x
			if visited[index]!=0 or source.get_pixel(x,y).a<.08:continue
			var queue=PackedInt32Array([index]);visited[index]=1;var cursor=0
			while cursor<queue.size():
				var item=queue[cursor];cursor+=1;var px=item%w;var py=int(item/w)
				for delta in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
					var nx=px+delta.x;var ny=py+delta.y
					if nx<0 or ny<0 or nx>=w or ny>=h:continue
					var next=ny*w+nx
					if visited[next]!=0 or source.get_pixel(nx,ny).a<.08:continue
					visited[next]=1;queue.append(next)
			if queue.size()>best.size():best=queue
	var keep=PackedByteArray();keep.resize(w*h)
	for index in best:keep[index]=1
	for y in h:
		for x in w:
			if keep[y*w+x]==0:source.set_pixel(x,y,Color.TRANSPARENT)
	return source

static func icon(id: String) -> Texture2D:
	var data := sprite(id)
	if data.is_empty(): return null
	var atlas := AtlasTexture.new()
	atlas.atlas = data.texture
	atlas.region = data.region
	return atlas
