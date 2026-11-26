extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var art:=FarmArt.new()
	var ids=["colorful_oak","lg_blossom_tree","autumn_maple","snow_pine","sunflower_patch","flower_patch","flowering_bushes","flower_garden","resource_boulder","soil_plot_empty","wheat_plot_ready","corn_plot_ready","carrot_plot_ready","lg_greenhouse","snow_greenhouse","snow_cabin","frozen_lake","decorative_pond","kitchen_cottage","village_barn","market_cart","fence_straight","fence_corner","arched_fence","bakery_building","dairy_building","feed_mill_building","delivery_truck","delivery_depot","rustic_lamp","wooden_crates"]
	for id in ["apel","jeruk","mangga","pisang","ceri","lemon","alpukat","kelapa","persik","pir","kakao","biji_kopi"]:
		ids.append("fruit_tree_"+id+"_ripe")
		ids.append("fruit_tree_"+id+"_bare")
	var plants=load("res://assets/crop_illustrations/plants.png") as Texture2D
	var cell_size=plants.get_size()/4.0
	var plant_ids=FarmGameState.CROP_ORDER.duplicate()
	plant_ids.append_array(["young_leaves","tiny_sprouts"])
	for i in plant_ids.size():
		var id="plant_"+str(plant_ids[i])
		art.sprites[id]={"texture":plants,"region":Rect2(Vector2(i%4,floori(float(i)/4.0))*cell_size,cell_size),"anchor":Vector2(cell_size.x*0.5,cell_size.y*0.96)}
		ids.append(id)
	var catalog={"version":1,"tile_world_size":256,"materials":[],"sprites":[],"sources":[]}
	for id in preload("res://scripts/terrain_asset_kit.gd").MATERIALS:
		var path="res://assets/terrain_kit/materials/"+id+".png"
		var source=load(path) as Texture2D
		assert(source!=null,"Missing material: "+id)
		assert(source.get_width()>=1024 and source.get_height()>=1024)
		catalog.materials.append({"id":id,"file":"materials/"+id+".png","width":source.get_width(),"height":source.get_height(),"world_tile":256,"minimum_texels_per_world_unit":float(mini(source.get_width(),source.get_height()))/256.0})
	for id in ids:
		art.ensure_reference(id)
		assert(art.sprites.has(id),"Missing sprite: "+id)
		var sprite: Dictionary=art.sprites[id]
		var rect: Rect2=sprite.region
		var anchor: Vector2=sprite.anchor
		var source: Texture2D=sprite.texture
		var path=source.resource_path
		var preferred_width=150.0 if "tree" in id or "pine" in id or "maple" in id else 220.0
		var world_width=minf(preferred_width,rect.size.x/2.0)
		catalog.sprites.append({"id":id,"source":path,"region":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"anchor":[anchor.x,anchor.y],"recommended_width":world_width,"max_zoom_at_native_resolution":rect.size.x/world_width})
		if not catalog.sources.has(path): catalog.sources.append(path)
	var mountains=load("res://assets/terrain_kit/backdrops/distant_mountains.png") as Texture2D
	catalog["backdrops"]=[{"id":"distant_mountains","file":"backdrops/distant_mountains.png","width":mountains.get_width(),"height":mountains.get_height(),"usage":"Distant scenery only; never place playable objects on this image."}]
	var file=FileAccess.open("res://assets/terrain_kit/catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog,"\t"))
	file.close()
	print("TERRAIN CATALOG PASS: ",catalog.materials.size()," high-resolution materials; ",catalog.sprites.size()," reusable sprite definitions")
	quit()
