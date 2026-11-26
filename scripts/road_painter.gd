extends RefCounted
# Continuous paving on a shared isometric lattice; owned road cells, prices,
# inventory and collision checks remain compatible with existing farms.
const CATALOG=preload("res://scripts/road_catalog.gd")
const TILE_W=75.0
const TILE_H=44.0
static var sprites: Dictionary={}
static func sprite(id: String) -> Dictionary:
 if sprites.has(id): return sprites[id]
 var path="res://assets/roads/"+id+"_tile.png"
 if not ResourceLoader.exists(path): return {}
 var source=load(path) as Texture2D
 if source==null: return {}
 var region=Rect2(preload("res://scripts/wardrobe_assets.gd").visible_bounds(source.get_image()))
 var preview=AtlasTexture.new()
 preview.atlas=source
 preview.region=region
 sprites[id]={"texture":source,"region":region,"preview":preview}
 return sprites[id]
static func preview(id: String) -> Texture2D:
 return sprite(id).get("preview",null) as Texture2D
static func iso_position(u: int,v: int) -> Vector2:
 return Vector2((u-v)*TILE_W*0.5,(u+v)*TILE_H*0.5)
static func uv(at: Vector2) -> Vector2:
 return Vector2(at.x/TILE_W+at.y/TILE_H,-at.x/TILE_W+at.y/TILE_H)
static func cells_in_view(view: FarmView,visible: Rect2) -> Dictionary:
 var cells={}
 for key in view.game.road_tiles:
  var parts=str(key).split(",")
  if parts.size()!=2: continue
  var cell=Vector2i(int(parts[0]),int(parts[1]))
  var at=view.road_visual_center(cell)
  if not visible.grow(100).has_point(at) or not view.road_surface_clear_of_objects(at,at,view.ROAD_HALF_WIDTH): continue
  var links=[]
  for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if not view.game.road_tiles.has(view.road_key(cell+offset)): continue
   var other=view.road_visual_center(cell+offset)
   if view.road_surface_clear_of_objects(at,other,view.ROAD_HALF_WIDTH): links.append((at+other)*0.5)
  cells[cell]={"at":at,"links":links,"style":CATALOG.style(view.game,str(key))}
 return cells
static func sample(view: FarmView,at: Vector2,cells: Dictionary) -> Dictionary:
 var cell=view.road_cell_from_world(at)
 var distance=INF
 var style=""
 for y in range(-1,2):
  for x in range(-1,2):
   var entry: Dictionary=cells.get(cell+Vector2i(x,y),{})
   if entry.is_empty(): continue
   var d=at.distance_squared_to(entry.at)
   for end in entry.links: d=minf(d,Geometry2D.get_closest_point_to_segment(at,entry.at,end).distance_squared_to(at))
   if d<distance: distance=d;style=str(entry.style)
 if distance>view.ROAD_HALF_WIDTH*view.ROAD_HALF_WIDTH: return {}
 return {"style":style,"distance":distance}
static func tile_fits(view: FarmView,at: Vector2,cells: Dictionary) -> bool:
 for offset in [Vector2(-TILE_W*0.5,0),Vector2(TILE_W*0.5,0),Vector2(0,-TILE_H*0.5),Vector2(0,TILE_H*0.5)]:
  if sample(view,at+offset,cells).is_empty(): return false
 return true
static func visible_tiles(view: FarmView) -> Array:
 var tiles=[]
 for cell in cells_in_view(view,view.visible_world_rect(100.0)):
  tiles.append({"at":view.road_visual_center(cell),"style":CATALOG.style(view.game,view.road_key(cell)),"u":cell.x,"v":cell.y})
 tiles.sort_custom(func(a,b): return a.at.y<b.at.y if not is_equal_approx(a.at.y,b.at.y) else a.at.x<b.at.x)
 return tiles
static func paint(view: FarmView) -> void:
 var tiles=visible_tiles(view)
 var occupied={}
 for tile in tiles: occupied[Vector2i(tile.u,tile.v)]=true
 for tile in tiles:
  var at: Vector2=tile.at
  var asset=sprite(str(tile.style))
  if not asset.is_empty():
   view.draw_texture_rect_region(asset.texture,Rect2(at-Vector2(TILE_W*0.5+1.0,TILE_H*0.5+0.5),Vector2(TILE_W+2.0,TILE_H+3.0)),asset.region)
  else:
   view.poly(PackedVector2Array([at+Vector2(-TILE_W*0.5,0),at+Vector2(0,-TILE_H*0.5),at+Vector2(TILE_W*0.5,0),at+Vector2(0,TILE_H*0.5)]),CATALOG.ITEMS[tile.style].fill)
