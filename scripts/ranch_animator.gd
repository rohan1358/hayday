extends RefCounted
const RANCH=preload("res://scripts/ranch_state.gd")
var farm
var agents: Dictionary={}
var frames: Dictionary={}
var clock=0.0
var step_timer=0.0
var sync_timer=0.0
var rng=RandomNumberGenerator.new()
func configure(view) -> void:
	farm=view
	rng.seed=462913
	var path="res://assets/ranch/animal_poses.png"
	if not ResourceLoader.exists(path): return
	var source=(load(path) as Texture2D).get_image()
	var size=Vector2i(source.get_width()/4,source.get_height()/4)
	for row in 4:
		for pose in 4:
			var tile=source.get_region(Rect2i(Vector2i(pose,row)*size,size))
			var bounds=preload("res://scripts/wardrobe_assets.gd").visible_bounds(tile)
			if bounds.has_area(): tile=tile.get_region(bounds)
			frames[RANCH.SPECIES[row]+str(pose)]=ImageTexture.create_from_image(tile)
	sync()
func sync() -> void:
	if farm.mobile_livestock_overlay==null: return
	var wanted: Dictionary={}
	for species in RANCH.SPECIES:
		for i in RANCH.count(farm.game,species):
			var key=species+"_"+str(i)
			wanted[key]=true
			if agents.has(key): continue
			var node=Sprite2D.new()
			node.name="Herd_"+key
			node.centered=false
			farm.mobile_livestock_overlay.add_child(node)
			var uv=free_spawn(species)
			agents[key]={"species":species,"node":node,"uv":uv,"target":uv,"wait":rng.randf_range(0.2,1.2),"state":"idle","facing":1.0,"world":Vector2.ZERO}
	for key in agents.keys():
		if not wanted.has(key):
			agents[key].node.queue_free()
			agents.erase(key)
func local_floor(uv: Vector2) -> Vector2:
	return Vector2(0.38,0.68)+Vector2(0.28,0.16)*uv.x+Vector2(0.21,-0.14)*uv.y
func allowed(species: String,uv: Vector2) -> bool:
	var margin=clampf(RANCH.animal_width(species)/RANCH.pen_width(farm.game,species)*0.9,0.10,0.23)
	if uv.x<margin or uv.x>1.0-margin or uv.y<margin or uv.y>1.0-margin: return false
	var p:=local_floor(uv)
	var forbidden: Array=[]
	if species=="sapi": forbidden=[Rect2(0.77,0.62,0.13,0.13)]
	elif species=="ayam": forbidden=[Rect2(0.70,0.58,0.16,0.12)]
	elif species=="babi": forbidden=[Rect2(0.56,0.77,0.16,0.14)]
	elif species=="kambing": forbidden=[Rect2(0.47,0.45,0.20,0.16),Rect2(0.76,0.56,0.16,0.15),Rect2(0.56,0.77,0.16,0.14)]
	for rect in forbidden:
		if rect.has_point(p): return false
	return true
func free_spawn(species: String) -> Vector2:
	var best=Vector2(0.5,0.5)
	var clearance=-1.0
	for i in 45:
		var uv=Vector2(rng.randf_range(0.10,0.90),rng.randf_range(0.10,0.90))
		if not allowed(species,uv): continue
		var distance=INF
		for other in agents.values():
			if other.species==species: distance=minf(distance,pen_point(species,uv).distance_squared_to(pen_point(species,other.uv)))
		if distance>clearance:
			clearance=distance
			best=uv
	return best
func pen_point(species: String,uv: Vector2) -> Vector2:
	var info: Dictionary=RANCH.INFO[species]
	var sprite: Dictionary=farm.farm_art.sprites.get(info.asset,{})
	if sprite.is_empty(): return farm.object_position(species)
	var region: Rect2=sprite.region
	var width=RANCH.pen_width(farm.game,species)
	var offset: Vector2=info.offset
	if preload("res://scripts/first_farm.gd").compact(farm.game) and species in ["ayam","sapi"]: offset=Vector2.ZERO
	var factor=width/region.size.x
	var origin: Vector2=farm.object_position(species)+offset-Vector2(sprite.anchor)*factor
	var local:=local_floor(uv)
	var result=origin+local*region.size*factor
	if preload("res://scripts/asset_edit.gd").flipped(farm.game,species):result.x=2*farm.object_position(species).x-result.x
	return result
func tick(delta: float) -> void:
	clock+=delta
	step_timer+=delta
	sync_timer+=delta
	if sync_timer>=0.5:
		sync_timer=0
		sync()
	if step_timer>=0.05:
		var step=minf(step_timer,0.2)
		step_timer=0
		for key in agents:
			var animal: Dictionary=agents[key]
			var uv: Vector2=animal.uv
			if animal.state=="walk":
				var next=uv.move_toward(animal.target,step*0.20)
				var blocked=not allowed(animal.species,next)
				for other_key in agents:
					if other_key==key or agents[other_key].species!=animal.species: continue
					var separation: Vector2=(pen_point(animal.species,next)-pen_point(animal.species,agents[other_key].uv))/Vector2(0.9,0.5)
					if separation.length()<(RANCH.animal_width(str(animal.species))*0.78): blocked=true; break
				if blocked:
					animal.state="idle"
					animal.wait=rng.randf_range(0.2,0.8)
				else:
					animal.facing=-1.0 if pen_point(animal.species,next).x<pen_point(animal.species,uv).x else 1.0
					animal.uv=next.clamp(Vector2.ONE*0.08,Vector2.ONE*0.92)
					if next.distance_to(animal.target)<0.01:
						animal.state="graze"
						animal.wait=rng.randf_range(1.0,2.5)
			else:
				animal.wait=float(animal.wait)-step
				if animal.wait<=0:
					if animal.state=="graze" and rng.randf()<0.45:
						animal.state="rest"
						animal.wait=rng.randf_range(2.0,5.0)
						continue
					for attempt in 12:
						animal.target=Vector2(rng.randf_range(0.10,0.90),rng.randf_range(0.10,0.90))
						if allowed(animal.species,animal.target): break
					animal.state="walk"
		var sorted=agents.values()
		sorted.sort_custom(func(a,b): return pen_point(a.species,a.uv).y<pen_point(b.species,b.uv).y)
		for animal in sorted: animal.node.move_to_front()
	if farm.hybrid_controller!=null:
		for value in farm.hybrid_controller.data.animals:
			var key=str(value.species)+"_0"
			if value.get("legacy_pen",false) and agents.has(key): value.state="eat" if agents[key].state=="graze" else agents[key].state
	var view=farm.get_virtual_size()
	var scaler: Vector2=farm.size/view
	var visible=farm.visible_world_rect(100)
	for animal in agents.values():
		var world=pen_point(animal.species,animal.uv)
		animal.world=world
		var node: Sprite2D=animal.node
		node.visible=visible.has_point(world)
		if not node.visible: continue
		var pose=2+posmod(int(clock*7),2) if animal.state=="walk" else (1 if animal.state=="graze" else 0)
		var texture: Texture2D=frames.get(str(animal.species)+str(pose),null)
		if texture==null: continue
		node.texture=texture
		node.offset=-Vector2(texture.get_width()*0.5,texture.get_height()*0.97)
		var width=RANCH.animal_width(str(animal.species))
		var scale_factor=width/texture.get_width()
		node.scale=Vector2(-float(animal.facing)*scale_factor*farm.camera_zoom*scaler.x,scale_factor*farm.camera_zoom*scaler.y)
		node.position=(view*0.5-farm.camera_center*farm.camera_zoom+world*farm.camera_zoom)*scaler
