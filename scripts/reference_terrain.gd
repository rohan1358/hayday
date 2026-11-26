extends RefCounted

const SIZE := Vector2(4320,7680)
const SOURCE := Vector2(1052,1495)
static var texture: Texture2D
const RIVERS := [
	[Vector2(810,165),Vector2(740,205),Vector2(660,235),Vector2(620,270),Vector2(570,300),Vector2(545,340),Vector2(535,375),Vector2(500,415),Vector2(500,450),Vector2(510,490),Vector2(480,530),Vector2(470,570),Vector2(420,630),Vector2(400,665),Vector2(380,695)],
	[Vector2(0,635),Vector2(120,662),Vector2(260,695),Vector2(350,720),Vector2(375,770),Vector2(435,815),Vector2(540,840)],
	[Vector2(1052,630),Vector2(950,680),Vector2(780,710),Vector2(670,740),Vector2(645,795),Vector2(590,825),Vector2(540,840)],
	[Vector2(540,840),Vector2(490,900),Vector2(520,970),Vector2(560,1040),Vector2(520,1100),Vector2(500,1190),Vector2(480,1260),Vector2(450,1340),Vector2(410,1400),Vector2(400,1495)]
]
static var BRIDGES: Array=[]
static var bridge_game
static func bridge_paths() -> Array:
	if not BRIDGES.is_empty():return active_bridges()
	if hd_image==null:sample(Vector2.ZERO)
	var dim=hd_image.get_size()
	for fraction in [0.39,0.75]:
		var row=int(dim.y*fraction)
		var first=-1;var last=-1;var gap=0
		for x in range(int(dim.x*0.60),int(dim.x*0.94)):
			var c=hd_image.get_pixel(x,row)
			var wet=c.r<0.38 and c.g-c.r>0.16 and c.b-c.r>0.22
			if wet:
				if first<0:first=x
				last=x;gap=0
			elif first>=0:
				gap+=1
				if gap>12:break
		if first>=0 and last-first>8:
			BRIDGES.append([Vector2(first-12,row)/Vector2(dim)*SOURCE,Vector2(last+12,row)/Vector2(dim)*SOURCE])
	return active_bridges()

static func active_bridges() -> Array:
	if bridge_game==null:return BRIDGES
	var result=[]
	for i in BRIDGES.size():
		var line=BRIDGES[i]
		var base=(line[0]+line[1])*.5
		var coords=bridge_game.layout_positions.get("bridge_%d"%i,[])
		var preview: Dictionary=bridge_game.get_meta("asset_preview",{})
		if str(preview.get("key",""))=="bridge_%d"%i:coords=[preview.point.x,preview.point.y]
		var shift=Vector2(coords[0],coords[1])/SIZE*SOURCE-base if coords.size()==2 else Vector2.ZERO
		result.append([line[0]+shift,line[1]+shift])
	return result

static func uv(at: Vector2) -> Vector2: return at/SIZE*SOURCE

static var hd_image: Image
static func sample(at: Vector2) -> Color:
	if hd_image==null: hd_image=load("res://assets/world_background/summer_island_v2.png").get_image()
	var pixel=Vector2i(at/SIZE*Vector2(hd_image.get_size()))
	if pixel.x<0 or pixel.y<0 or pixel.x>=hd_image.get_width() or pixel.y>=hd_image.get_height(): return Color(0,0.5,1)
	return hd_image.get_pixelv(pixel)

static func water(at: Vector2, allow_bridge: bool=true) -> bool:
	var point=uv(at)
	for bridge in bridge_paths():
		if allow_bridge and Geometry2D.get_closest_point_to_segment(point,bridge[0],bridge[1]).distance_to(point)<12: return false
	var color=sample(at)
	return color.r<0.38 and color.b-color.r>0.22 and color.g-color.r>0.16

static func bridge_deck(at: Vector2) -> bool:
	for bridge in bridge_paths():
		if Geometry2D.get_closest_point_to_segment(uv(at),bridge[0],bridge[1]).distance_to(uv(at))<6.5:return true
	return false

static var support_cache=PackedByteArray()
static func ground_surface(at: Vector2) -> bool:
	var point=at/SIZE
	if point.y<0.16 or point.y>0.94 or point.x<0.035 or point.x>0.965:return false
	if hd_image==null: sample(at)
	var pixel=Vector2i(at/SIZE*Vector2(hd_image.get_size()))
	var index=pixel.y*hd_image.get_width()+pixel.x
	if support_cache.is_empty():support_cache.resize(hd_image.get_width()*hd_image.get_height());support_cache.fill(0)
	if support_cache[index]!=0:return support_cache[index]==1
	var c=hd_image.get_pixelv(pixel)
	var grass=c.g>c.r*0.97 and c.g>c.b*1.7
	var autumn=c.r>c.g*1.04 and c.g>c.b*1.5
	var snow=c.r>0.74 and c.g>0.81 and c.b>0.88 and c.b>=c.g*0.98
	var road=c.r>0.80 and c.g>0.64 and c.b<c.g*0.85
	var valid=(grass or road) and not (c.r<0.38 and c.b-c.r>0.22 and c.g-c.r>0.16)
	support_cache[index]=1 if valid else 2
	return valid

static func solid(at: Vector2) -> bool:
	if bridge_deck(at):return false
	# Test the player's whole ground contact, not only a blue-water pixel.
	for offset in [Vector2.ZERO,Vector2(-20,0),Vector2(20,0),Vector2(0,-20),Vector2(0,20),Vector2(-14,-14),Vector2(14,-14),Vector2(-14,14),Vector2(14,14)]:
		if not ground_surface(at+offset):return true
	return false

static var layers: Dictionary = {}

static func layer(name: String) -> Texture2D:
	if not layers.has(name): layers[name]=load("res://assets/world_background/elemen/"+name+".png")
	return layers[name] as Texture2D

static func sprite(view, name: String, at: Vector2, width: float) -> void:
	var tex=layer(name)
	var height=width*tex.get_height()/float(tex.get_width())
	view.draw_texture_rect(tex,Rect2(at-Vector2(width*0.5,height),Vector2(width,height)),false)

static func paint(_view) -> void:
	# HDWorldTerrain draws once in world space, outside low-resolution scenery caches.
	pass

static var tree_sprites: Dictionary={}
static func tree_number(district: String,index: int) -> int:
	if district=="summer" or district=="central":return 4 if index%3==0 else 7+index%2
	if district=="autumn":return 5+index%2
	if district=="winter":return 9
	return 1+index%3

static func tree_info(district: String,index: int) -> Dictionary:
	var number=tree_number(district,index)
	if tree_sprites.has(number):return tree_sprites[number]
	# The source rows have different heights; uniform 341px crops included the next tree.
	var texture=layer("pohon")
	var row=int((number-1)/3);var col=(number-1)%3
	var origin=Vector2i(col*512,[0,310,620][row])
	var cell=Rect2i(origin,Vector2i(512,[310,310,404][row]))
	var image=texture.get_image().get_region(cell)
	var bitmap=BitMap.new();bitmap.create_from_image_alpha(image,0.55)
	var polygons=bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),1.0)
	var largest=PackedVector2Array();var best_area=0.0
	for polygon in polygons:
		var area=0.0
		for i in polygon.size():
			var next=polygon[(i+1)%polygon.size()]
			area+=polygon[i].x*next.y-next.x*polygon[i].y
		if absf(area)>best_area:best_area=absf(area);largest=polygon
	var min_point=Vector2(image.get_size());var max_point=Vector2.ZERO
	for point in largest:min_point=min_point.min(point);max_point=max_point.max(point)
	var left=maxi(0,floori(min_point.x));var top=maxi(0,floori(min_point.y))
	var right=mini(image.get_width()-1,ceili(max_point.x)-1);var bottom=mini(image.get_height()-1,ceili(max_point.y)-1)
	var region=Rect2i(maxi(0,left-3),maxi(0,top-3),mini(image.get_width()-maxi(0,left-3),right-left+7),mini(image.get_height()-maxi(0,top-3),bottom-top+7))
	var sum=0.0;var count=0
	for y in range(maxi(top,bottom-8),bottom+1):
		for x in range(left,right+1):
			if image.get_pixel(x,y).a>=0.55:sum+=x;count+=1
	var root_x=sum/maxi(1,count)
	var atlas=AtlasTexture.new();atlas.atlas=texture;atlas.region=Rect2i(region.position+origin,region.size);atlas.filter_clip=true
	var anchor=Vector2(root_x-region.position.x,bottom+1-region.position.y)
	tree_sprites[number]={"texture":atlas,"size":Vector2(region.size),"anchor":anchor,"number":number}
	return tree_sprites[number]

static func tree_width(index: int,district: String="") -> float:
	if district=="":district=preload("res://scripts/four_seasons.gd").active_id
	return 128.0+float(index%3)*7 if tree_number(district,index)>=7 else 180.0+float(index%3)*8

static func tree_bounds(at: Vector2,index: int,district: String="") -> Rect2:
	if district=="":district=preload("res://scripts/four_seasons.gd").active_id
	var info=tree_info(district,index)
	var scaler=tree_width(index,district)/info.size.x
	return Rect2(at+Vector2(0,12)-info.anchor*scaler,info.size*scaler)

static func paint_tree(view,district: String,index: int) -> bool:
	var info=tree_info(district,index)
	var scaler=tree_width(index,district)/info.size.x
	var shade=PackedVector2Array()
	for i in 16:shade.append(Vector2(cos(TAU*i/16.0)*42,sin(TAU*i/16.0)*12)+Vector2(0,8))
	view.draw_colored_polygon(shade,Color(0.16,0.30,0.10,0.14))
	var rect=Rect2(Vector2(0,12)-info.anchor*scaler,info.size*scaler)
	if preload("res://scripts/asset_edit.gd").flipped(view.game,"wild_%d"%index):rect.position.x=-rect.end.x;rect.size.x=-rect.size.x
	view.draw_texture_rect(info.texture,rect,false)
	return true

static func migrate(game) -> bool:
	if int(game.world_regions.get("reference_terrain_version",0))>=1: return false
	game.world_regions.reference_terrain_backup={"positions":game.layout_positions.duplicate(true),"roads":game.road_tiles.duplicate(true),"player":game.hybrid.get("player",[]).duplicate()}
	# Lift the starting farm out of the distant mountain band onto Spring's lawn.
	for key in game.layout_positions:
		var at=game.layout_positions[key]
		if at is Array and at.size()==2 and float(at[1])<1700:
			game.layout_positions[key]=[at[0],float(at[1])+1452]
	for i in preload("res://scripts/first_farm_world.gd").SCENERY.size():
		var key="starter_%d"%i
		if not game.layout_positions.has(key):
			var at: Vector2=preload("res://scripts/first_farm_world.gd").SCENERY[i][1]
			game.layout_positions[key]=[at.x,at.y+1452]
	var shifted={}
	for key in game.road_tiles:
		var parts=str(key).split(",")
		if parts.size()==2: shifted["%d,%d"%[int(parts[0])+33,int(parts[1])+33]]=game.road_tiles[key]
	game.road_tiles=shifted
	var player=game.hybrid.get("player",[1170,760])
	if player.size()==2 and float(player[1])<1700: game.hybrid.player=[player[0],float(player[1])+1452]
	if not game.ftue.is_empty(): game.ftue.asset_overlap_repair=4
	game.world_regions.reference_terrain_version=1
	game.save_game()
	return true

static func dry_ground(at: Vector2) -> bool:
	return not bridge_deck(at) and not solid(at)

const PRIMARY_KEYS=["dapur","gudang","ayam","sapi","babi","kambing","roti","susu","pakan","delivery_depot","delivery_truck"]
static func primary_key(key: String) -> bool:
	return key in PRIMARY_KEYS or key.begins_with("petak_") or key.begins_with("starter_") or key in ["buah_0","buah_1"]

static func allowed_region(key: String,at: Vector2) -> bool:
	return not primary_key(key) or preload("res://scripts/four_seasons.gd").region(at)==preload("res://scripts/four_seasons.gd").active_id

static func main_road(at: Vector2) -> bool:
	var c=sample(at)
	return c.r>.82 and c.g>.64 and c.b<c.g*.85 and c.r>c.g*1.03

static func asset_clear(at: Vector2) -> bool:
	for bridge in bridge_paths():
		if Geometry2D.get_closest_point_to_segment(uv(at),bridge[0],bridge[1]).distance_to(uv(at))<40:return false
	for y in [-70,0,70]:
		for x in [-100,0,100]:
			if not dry_ground(at+Vector2(x,y)) or water(at+Vector2(x,y),false) or main_road(at+Vector2(x,y)): return false
	return true

static func scene_supported(at: Vector2,half: Vector2) -> bool:
	# Isometric roofs can project above a shoreline; the complete ground-contact
	# base must remain dry. Test the base rather than treating roofs as feet.
	if not asset_clear(at):return false
	for y in [-0.7,0.0,0.7]:
		for x in [-0.8,0.0,0.8]:
			if not dry_ground(at+Vector2(x*half.x,y*half.y)) or main_road(at+Vector2(x*half.x,y*half.y)):return false
	return true

static func bounds_clear(bounds: Rect2) -> bool:
	for y in 5:
		for x in 5:
			var at=bounds.position+bounds.size*Vector2(x/4.0,y/4.0)
			if not ground_surface(at):return false
	return true

static var anchor_cache: Dictionary={}
static func safe_anchor(preferred: Vector2,region_id: String="") -> Vector2:
	var cache_key=str(preferred)+region_id
	if anchor_cache.has(cache_key):return anchor_cache[cache_key]
	if asset_clear(preferred) and bounds_clear(Rect2(preferred-Vector2(260,140),Vector2(520,220))):anchor_cache[cache_key]=preferred;return preferred
	for radius in range(80,1601,80):
		for i in 24:
			var candidate=preferred+Vector2.from_angle(TAU*i/24.0)*radius
			if region_id!="" and preload("res://scripts/four_seasons.gd").region(candidate)!=region_id:continue
			if asset_clear(candidate) and bounds_clear(Rect2(candidate-Vector2(260,140),Vector2(520,220))):anchor_cache[cache_key]=candidate;return candidate
	anchor_cache[cache_key]=preferred
	return preferred

static func art_anchor(farm,key: String,preferred: Vector2) -> Vector2:
	var projection=preload("res://scripts/asset_projection.gd")
	var art=projection.info(farm,key,preferred)
	if art.is_empty():return safe_anchor(preferred)
	var offsets=[Vector2.ZERO]
	for radius in range(120,2401,120):
		for i in 24: offsets.append(Vector2.from_angle(TAU*i/24.0)*radius)
	for offset in offsets:
		var candidate=preferred+offset
		if key=="sapi" and candidate.distance_to(load("res://scripts/island_layout.gd").preferred("sapi"))>800:continue
		if allowed_region(key,candidate) and asset_clear(candidate) and bounds_clear(Rect2(art.bounds.position+offset,art.bounds.size).grow(24)):return candidate
	return safe_anchor(preferred)

static func repair_playfield(host) -> void:
	var game=host.game
	var safe=preload("res://scripts/safe_asset_placement.gd")
	load("res://scripts/island_layout.gd").ensure(host)
	if not bool(game.world_regions.get("home_layout_v2",false)):
		game.world_regions.home_layout_backup=game.layout_positions.duplicate(true)
		for key in ["dapur","gudang","roti","susu"]:
			var preferred={"dapur":Vector2(980,2052),"gudang":Vector2(1950,2300),"roti":Vector2(1010,1600),"susu":Vector2(1510,1650)}[key]
			var at=art_anchor(host.farm,key,preferred)
			game.layout_positions[key]=[at.x,at.y]
		game.world_regions.home_layout_v2=true
		game.world_regions.front_fence_v1=false
	if int(game.world_regions.get("playfield_repair",0))<9:
		var stock=preload("res://scripts/road_catalog.gd").prepare(game).stock
		for key in game.road_tiles:
			var style=preload("res://scripts/road_catalog.gd").style(game,str(key))
			stock[style]=int(stock.get(style,0))+1
		game.road_tiles.clear()
		var repair_keys=host.farm.editable_keys()
		for key in game.layout_positions:
			if key not in repair_keys: repair_keys.append(key)
		for key in ["ayam","sapi","babi","kambing","roti","susu","pakan"]:
			if key not in repair_keys:repair_keys.append(key)
		for key in repair_keys:
			var original=host.farm.object_position(key)
			var artwork=preload("res://scripts/asset_projection.gd").info(host.farm,key,original)
			if allowed_region(key,original) and asset_clear(original) and (artwork.is_empty() or bounds_clear(artwork.bounds.grow(24))) and (key!="sapi" or original.distance_to(load("res://scripts/island_layout.gd").preferred("sapi"))<=800): continue
			if key=="sapi" and original.distance_to(load("res://scripts/island_layout.gd").preferred("sapi"))>800:original=load("res://scripts/island_layout.gd").preferred("sapi")
			if primary_key(key) and not allowed_region(key,original):original=Vector2(1200,2300)
			var dry=safe.find(host.farm,key,original)
			if dry==Vector2.INF: dry=art_anchor(host.farm,key,original)
			if dry!=Vector2.INF:
				if key.begins_with("dekor_"): game.decoration_by_key(key).position=[dry.x,dry.y]
				else: game.layout_positions[key]=[dry.x,dry.y]
		for id in preload("res://scripts/four_seasons.gd").SITES:
			var key="region_"+id
			var site=art_anchor(host.farm,key,host.farm.object_position(key))
			game.layout_positions[key]=[site.x,site.y]
		game.world_regions.playfield_repair=9
	if not bool(game.world_regions.get("front_fence_v1",false)):
		var home=host.farm.object_position("dapur")
		for i in 5:
			var at=home+Vector2(-280+i*140,150)
			if i>=2: at.x+=140
			var key="starter_%d"%(8+i)
			var art=preload("res://scripts/asset_projection.gd").info(host.farm,key,at)
			if asset_clear(at) and not art.is_empty() and bounds_clear(art.bounds): game.layout_positions[key]=[at.x,at.y]
		game.world_regions.front_fence_v1=true
	load("res://scripts/island_layout.gd").ensure(host)
	safe.repair_nature(host)
	if host.farm.hybrid_controller!=null:
		host.farm.hybrid_controller.navigation.ensure()
		host.farm.hybrid_controller.rescue_player()
	game.save_game()
