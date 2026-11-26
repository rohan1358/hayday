extends RefCounted
const CATALOG=preload("res://scripts/wardrobe_catalog.gd")
const CHARACTER_PATH="res://assets/wardrobe/characters.png"
const ATLAS_PATHS=["res://assets/wardrobe/colorful_spring_v4.png","res://assets/wardrobe/colorful_summer_v4.png","res://assets/wardrobe/colorful_autumn_v4.png","res://assets/wardrobe/colorful_winter_v4.png"]
const SLOTS=CATALOG.SLOTS
const SLOT_NAMES=CATALOG.SLOT_NAMES
const NAMES=CATALOG.NAMES
static var cache: Dictionary={}
static func cell(path: String, columns: int, rows: int, index: int) -> Texture2D:
	var key := path+str(index)
	if cache.has(key): return cache[key]
	var image: Image
	var imported := load(path) as Texture2D
	if imported != null: image = imported.get_image()
	else: image = Image.load_from_file(path)
	if image == null: return null
	var size := Vector2i(image.get_width()/columns,image.get_height()/rows)
	var tile := image.get_region(Rect2i(Vector2i(index%columns,int(index/columns))*size,size))
	var used := visible_bounds(tile)
	if used.has_area(): tile=tile.get_region(used)
	var texture := ImageTexture.create_from_image(tile)
	cache[key]=texture
	return texture

# Atlas cells can contain near-transparent dust outside the sprite. Anchor all
# wearables to the largest connected visible silhouette, never that dust.
static func visible_bounds(image: Image) -> Rect2i:
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width*height)
	var best_pixels:=PackedInt32Array()
	var best_count := 0
	var best := image.get_used_rect()
	for seed in width*height:
		if visited[seed] or bytes[seed*4+3]<64: continue
		var stack := PackedInt32Array([seed])
		visited[seed]=1
		var component:=PackedInt32Array()
		var count := 0
		var low := Vector2i(width,height)
		var high := Vector2i.ZERO
		while not stack.is_empty():
			var pixel := stack[stack.size()-1]
			stack.resize(stack.size()-1)
			var x := pixel%width
			var y := int(pixel/width)
			low=Vector2i(mini(low.x,x),mini(low.y,y))
			high=Vector2i(maxi(high.x,x),maxi(high.y,y))
			component.append(pixel)
			count+=1
			for next in [pixel-1,pixel+1,pixel-width,pixel+width]:
				if next<0 or next>=width*height: continue
				if absi(next%width-x)>1: continue
				if visited[next] or bytes[next*4+3]<64: continue
				visited[next]=1
				stack.append(next)
		if count>best_count:
			best_count=count
			best_pixels=component
			best=Rect2i(low,high-low+Vector2i.ONE)
	# Keep only this sprite's connected silhouette and its antialiased edge.
	# Cropping alone leaves pieces of neighbouring atlas cells inside the bounds.
	var keep:=PackedByteArray()
	keep.resize(width*height)
	for pixel in best_pixels: keep[pixel]=1
	for pixel in width*height:
		if keep[pixel] or bytes[pixel*4+3]==0: continue
		var edge:=false
		if bytes[pixel*4+3]<64:
			var x:=pixel%width
			var y:=int(pixel/width)
			for dy in range(-2,3):
				for dx in range(-2,3):
					if x+dx>=0 and x+dx<width and y+dy>=0 and y+dy<height and keep[(y+dy)*width+x+dx]: edge=true
		if not edge: bytes[pixel*4+3]=0
	image.set_data(width,height,false,Image.FORMAT_RGBA8,bytes)
	return best.grow(1).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
static func character(data: Dictionary) -> Texture2D:
	var row := 1 if str(data.get("gender","male"))=="female" else 0
	return cell(CHARACTER_PATH,4,2,row*4+clampi(int(data.get("outfit",-1)),0,3))

static func accessory(index: int) -> Texture2D: return directional_accessory(index,0)
static func silhouette_bands(image: Image,horizontal: bool,region: Rect2i) -> Array:
	var bytes:=image.get_data()
	var width:=image.get_width()
	var length:=region.size.y if horizontal else region.size.x
	var breadth:=region.size.x if horizontal else region.size.y
	var bands: Array=[]
	var start:=-1
	var last:=-1
	for line in length:
		var count:=0
		for pixel in breadth:
			var x:=region.position.x+(pixel if horizontal else line)
			var y:=region.position.y+(line if horizontal else pixel)
			if bytes[(y*width+x)*4+3]>=160: count+=1
		if count>=maxi(4,int(breadth*0.055)):
			if start<0: start=line
			last=line
		elif start>=0 and line-last>10:
			bands.append(Vector2i(maxi(0,start-3),mini(length,last+4)))
			start=-1
	if start>=0: bands.append(Vector2i(maxi(0,start-3),mini(length,last+4)))
	return bands
# Front and back are the exact paired artwork supplied by the player.
# Intermediate directions reuse these two views; no replacement designs.
static func accessory_view(sector: int) -> String:
	return "back" if sector>=3 else "front"
static func directional_accessory(index: int,sector: int) -> Texture2D:
	if not CATALOG.valid(index): return null
	var path:="res://assets/wardrobe/reference_v6/%02d_%s.png"%[index,accessory_view(sector)]
	if not cache.has(path): cache[path]=load(path) as Texture2D
	return cache[path]
static func view_sector(pose: Dictionary) -> int:
	var direction: Vector2=pose.get("direction",Vector2.DOWN)
	if direction.length_squared()<0.001: return 0
	return clampi(roundi(atan2(absf(direction.x),direction.y)/(PI/4)),0,4)
static func directional_character(data: Dictionary,pose: Dictionary) -> Texture2D:
	var sector:=view_sector(pose)
	if sector==0: return character(data)
	var gender:="female" if str(data.get("gender","male"))=="female" else "male"
	return cell("res://assets/wardrobe/"+gender+"_directions.png",5,4,clampi(int(data.get("outfit",-1)),0,3)*5+sector)
static func fitted(texture: Texture2D,target: Rect2) -> Rect2:
	if texture==null: return target
	var factor:=minf(target.size.x/texture.get_width(),target.size.y/texture.get_height())
	var size:=texture.get_size()*factor
	return Rect2(target.position+(target.size-size)*0.5,size)
static func waist_y(data: Dictionary) -> float:
	return 0.60 if int(data.get("outfit",0))==3 else 0.585
static func pouch_mount(body: Rect2,sector: int,data: Dictionary) -> Vector2:
	return body.position+Vector2(0.55,waist_y(data))*body.size
static func directional_transform(index: int,body: Rect2,data: Dictionary,sector: int) -> Transform2D:
	var item:=directional_accessory(index,sector)
	var slot:=CATALOG.slot_of(index)
	var season:=CATALOG.season_of(index)
	var width:=1.10 if season<2 else 1.0
	var anchor:=Vector2(0.5,0.92)
	var destination:=body.position+Vector2(0.50,0.205)*body.size
	if slot=="neck":
		width=[0.43,0.42,0.40,0.46,0.46][sector]
		anchor=Vector2(0.5,0.16)
		var necks=[Vector2(0.56,0.393),Vector2(0.59,0.393),Vector2(0.62,0.393),Vector2(0.51,0.40),Vector2(0.50,0.40)]
		destination=body.position+necks[sector]*body.size
	elif slot=="bag":
		width=[0.55,0.49,0.36,0.52,0.55][sector]
		anchor=Vector2(0.5,0.30)
		destination=pouch_mount(body,sector,data)
	var factor:=body.size.x*width/item.get_width()
	var vertical_factor:=factor
	if slot=="head":
		factor=maxf(factor,body.size.y*0.235/item.get_height())
		vertical_factor=minf(factor,body.size.y*0.28/item.get_height()) if season>=2 else factor
	
	var transform:=Transform2D(0,Vector2.ZERO).scaled(Vector2(factor,vertical_factor))
	transform.origin=destination-transform.basis_xform(anchor*item.get_size())
	return transform
static func paint_wearable(canvas: CanvasItem,index: int,body: Rect2,data: Dictionary,sector: int) -> void:
	var item:=directional_accessory(index,sector)
	if item==null: return
	var transform:=directional_transform(index,body,data,sector)
	var points:=PackedVector2Array([transform*Vector2.ZERO,transform*Vector2(item.get_width(),0),transform*item.get_size(),transform*Vector2(0,item.get_height())])
	canvas.draw_polygon(points,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),item)
static func belt_path(body: Rect2,data: Dictionary,sector: int,back_layer:=false) -> PackedVector2Array:
	var ends=[Vector2(0.28,0.82),Vector2(0.24,0.78),Vector2(0.29,0.73),Vector2(0.24,0.82),Vector2(0.24,0.82)]
	var edge: Vector2=ends[sector]
	var y:=waist_y(data)
	var points:=PackedVector2Array()
	for i in 13:
		var t:=float(i)/12
		var uv:=Vector2(lerpf(edge.x,edge.y,t),y+sin(t*PI)*(-0.012 if back_layer else 0.012))
		points.append(body.position+uv*body.size)
	return points
static func paint_belt(canvas: CanvasItem,index: int,body: Rect2,data: Dictionary,sector: int,back_layer:=false) -> void:
	var path:=belt_path(body,data,sector,back_layer)
	var color:=Color("9c6845")
	var width:=body.size.y*0.018
	canvas.draw_polyline(path,Color("4f463866"),width+1.5,true)
	canvas.draw_polyline(path,color,width,true)
	canvas.draw_polyline(path,Color("ffffff55"),maxf(0.5,width*0.18),true)
	if not back_layer and sector<=1:
		var center:=body.position+Vector2(0.53 if sector==0 else 0.55,waist_y(data)+0.012)*body.size
		canvas.draw_rect(Rect2(center-Vector2(body.size.x*0.045,width*0.7),Vector2(body.size.x*0.09,width*1.4)),Color("e9b64e"),false,maxf(1,body.size.x*0.016))
static func paint_body_region(canvas: CanvasItem,texture: Texture2D,body: Rect2,pose: Dictionary,uv: Rect2) -> void:
	var part:=pose.duplicate()
	part.uv_region=uv
	preload("res://scripts/hybrid/character_animation.gd").body(canvas,texture,body,part)

static func restore_hair(canvas: CanvasItem,texture: Texture2D,body: Rect2,data: Dictionary,pose: Dictionary,sector: int) -> void:
	# Scarf/strap passes underneath the existing head and long braids.
	paint_body_region(canvas,texture,body,pose,Rect2(0,0.22,1,0.155))
	if str(data.get("gender","male"))!="female": return
	var braids: Array=[]
	match sector:
		0: braids=[Rect2(0.08,0.375,0.25,0.19),Rect2(0.73,0.375,0.22,0.19)]
		1: braids=[Rect2(0.05,0.375,0.28,0.19)]
		2: braids=[Rect2(0.03,0.375,0.39,0.19)]
		3: braids=[Rect2(0.13,0.375,0.25,0.19),Rect2(0.70,0.375,0.19,0.19)]
		4: braids=[Rect2(0.16,0.375,0.25,0.19),Rect2(0.63,0.375,0.25,0.19)]
	for braid in braids: paint_body_region(canvas,texture,body,pose,braid)

static func restore_near_arm(canvas: CanvasItem,texture: Texture2D,body: Rect2,pose: Dictionary,sector: int) -> void:
	var arms=[Rect2(0.80,0.49,0.20,0.22),Rect2(0.17,0.49,0.21,0.22),Rect2(0.40,0.49,0.21,0.22),Rect2(0.72,0.49,0.22,0.22),Rect2(0.02,0.49,0.20,0.22)]
	paint_body_region(canvas,texture,body,pose,arms[sector])

static func paint(canvas: CanvasItem,target: Rect2,data: Dictionary,pose: Dictionary={}) -> void:
	var packs=preload("res://scripts/seasonal_character_packs.gd")
	var season=packs.equipped(data)
	if season>=0:
		var figure=packs.directional_texture(str(data.get("gender","male")),season,view_sector(pose))
		if figure!=null:
			# Full supplied figure: accessories are already fitted in the artwork.
			# Keep feet at the same ground anchor in both views and every season.
			var height=target.size.y*0.94
			var width=height*figure.get_width()/figure.get_height()
			var rect=Rect2(Vector2(target.get_center().x-width*0.5,target.end.y-height),Vector2(width,height))
			preload("res://scripts/hybrid/character_animation.gd").body(canvas,figure,rect,pose)
		return
	var texture:=directional_character(data,pose)
	if texture==null: return
	var body:=fitted(texture,Rect2(target.position+Vector2(0,target.size.y*0.20),Vector2(target.size.x*0.94,target.size.y*0.80)))
	paint_body_region(canvas,texture,body,pose,Rect2(0,0,1,1))
