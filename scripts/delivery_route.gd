extends RefCounted
# A tiny visibility graph keeps the courier sprite clear of the movable depot.
static func clear(a: Vector2,b: Vector2,rect: Rect2) -> bool:
 if rect.has_point(a) or rect.has_point(b): return false
 var p=rect.position
 var q=rect.end
 for edge in [[p,Vector2(q.x,p.y)],[Vector2(q.x,p.y),q],[q,Vector2(p.x,q.y)],[Vector2(p.x,q.y),p]]:
  if Geometry2D.segment_intersects_segment(a,b,edge[0],edge[1])!=null: return false
 return true
static func build(start: Vector2,depot: Rect2,truck: Rect2) -> PackedVector2Array:
 var obstacle=Rect2(depot.position-truck.end-Vector2.ONE*12,depot.size+truck.size+Vector2.ONE*24)
 var end=start+Vector2(940,155)
 end.x=maxf(end.x,obstacle.end.x+200)
 if clear(start,end,obstacle): return PackedVector2Array([start,end])
 var outer=obstacle.grow(5)
 var nodes=[start,end,outer.position,Vector2(outer.end.x,outer.position.y),outer.end,Vector2(outer.position.x,outer.end.y)]
 var distance=[0.0,INF,INF,INF,INF,INF]
 var previous=[-1,-1,-1,-1,-1,-1]
 var visited={}
 for step in 6:
  var best=-1
  for i in 6:
   if not visited.has(i) and (best<0 or float(distance[i])<float(distance[best])): best=i
  if best<0 or best==1 or is_inf(float(distance[best])): break
  visited[best]=true
  for i in 6:
   if visited.has(i) or i==best or not clear(nodes[best],nodes[i],obstacle): continue
   var cost=float(distance[best])+nodes[best].distance_to(nodes[i])
   if cost<float(distance[i]): distance[i]=cost;previous[i]=best
 if int(previous[1])<0: return PackedVector2Array([start,end])
 var path=PackedVector2Array()
 var cursor=1
 while cursor>=0:
  path.insert(0,nodes[cursor]);cursor=int(previous[cursor])
 return path
static func point(path: PackedVector2Array,progress: float) -> Vector2:
 if path.is_empty(): return Vector2.ZERO
 var total=0.0
 for i in range(1,path.size()): total+=path[i-1].distance_to(path[i])
 var remaining=clampf(progress,0,1)*total
 for i in range(1,path.size()):
  var length=path[i-1].distance_to(path[i])
  if remaining<=length: return path[i-1].lerp(path[i],remaining/maxf(length,0.001))
  remaining-=length
 return path[path.size()-1]

static func terrain_route(farm) -> PackedVector2Array:
 var terrain=preload("res://scripts/reference_terrain.gd")
 var start=farm.object_position("delivery_truck")
 var bridges=terrain.bridge_paths()
 if bridges.is_empty():return PackedVector2Array([start,start])
 var line=bridges[0];var a=line[0]/terrain.SOURCE*terrain.SIZE;var b=line[1]/terrain.SOURCE*terrain.SIZE
 var grid=AStarGrid2D.new();grid.region=Rect2i(0,0,69,121);grid.cell_size=Vector2(64,64);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 var depot=farm.delivery_depot_bounds().grow(45)
 for y in grid.region.size.y:
  for x in grid.region.size.x:
   var id=Vector2i(x,y);var at=grid.get_point_position(id)
   var valid=not depot.has_point(at)
   for offset in [Vector2.ZERO,Vector2(-28,0),Vector2(28,0),Vector2(0,25),Vector2(0,-25)]:
    if terrain.solid(at+offset):valid=false;break
   grid.set_point_solid(id,not valid)
   if valid:grid.set_point_weight_scale(id,1.0 if near_road(at) else 30.0)
 var from=nearest(grid,start);var to=nearest(grid,a-Vector2(100,0))
 if from.x<0 or to.x<0:return PackedVector2Array([start,start])
 var path=grid.get_point_path(from,to)
 if path.is_empty():return PackedVector2Array([start,start])
 path.insert(0,start)
 # Exact bank-to-bank deck centerline, never a straight shortcut over water.
 path.append(a);path.append(b)
 return path
static func nearest(grid: AStarGrid2D,point: Vector2) -> Vector2i:
 var base=Vector2i((point/grid.cell_size).round())
 for radius in range(0,9):
  for dy in range(-radius,radius+1):
   for dx in range(-radius,radius+1):
    var id=base+Vector2i(dx,dy)
    if grid.is_in_boundsv(id) and not grid.is_point_solid(id):return id
 return Vector2i(-1,-1)

static func near_road(at: Vector2) -> bool:
 var terrain=preload("res://scripts/reference_terrain.gd")
 for dy in [-40,0,40]:
  for dx in [-40,0,40]:
   if terrain.main_road(at+Vector2(dx,dy)):return true
 return false
