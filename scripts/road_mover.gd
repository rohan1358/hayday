extends RefCounted
const CATALOG=preload("res://scripts/road_catalog.gd")
static func cell(key: String) -> Vector2i:
 var parts=key.trim_prefix("road_").split(",")
 return Vector2i(int(parts[0]),int(parts[1]))
static func pick(view,at: Vector2) -> String:
 var base=view.road_cell_from_world(at)
 var nearest=""
 var distance=INF
 for y in range(-1,2):
  for x in range(-1,2):
   var candidate=base+Vector2i(x,y)
   var key=view.road_key(candidate)
   if not view.game.road_tiles.has(key): continue
   var center=view.road_visual_center(candidate)
   var d=at.distance_squared_to(center)
   if d<distance and d<=pow(view.ROAD_HALF_WIDTH+preload("res://scripts/road_painter.gd").TILE_W*0.5,2):
    distance=d
    nearest="road_"+key
 return nearest
static func valid(view,key: String,at: Vector2) -> bool:
 var source=key.trim_prefix("road_")
 var destination=view.road_key(view.road_cell_from_world(at))
 if not view.game.road_tiles.has(source) or not CATALOG.valid_key(destination): return false
 if source==destination: return true
 if view.game.road_tiles.has(destination): return false
 # Validate the complete new surface without the source's outgoing links.
 var value=view.game.road_tiles[source]
 view.game.road_tiles.erase(source)
 var allowed=view.can_paint_road(view.road_cell_from_world(at))
 view.game.road_tiles[source]=value
 return allowed
static func preview(view) -> void:
 if not view.drag_key.begins_with("road_"): return
 var style=CATALOG.style(view.game,view.drag_key.trim_prefix("road_"))
 var sprite=preload("res://scripts/road_painter.gd").sprite(style)
 if sprite.is_empty(): return
 var at=view.drag_preview
 var painter=preload("res://scripts/road_painter.gd")
 view.draw_texture_rect_region(sprite.texture,Rect2(at-Vector2(painter.TILE_W*0.5,painter.TILE_H*0.5),Vector2(painter.TILE_W,painter.TILE_H+2)),sprite.region,Color(1,1,1,0.8))
