extends SceneTree
func _initialize():
	var manifest={"version":1,"assets":[]}
	var ids: Array[String]=[]
	for name in DirAccess.get_files_at("res://assets/colorful_garden/"):
		if name.ends_with(".png"): ids.append(name.trim_suffix(".png"))
	ids.sort()
	for id in ids:
		var path="res://assets/colorful_garden/"+id+".png"
		if not ResourceLoader.exists(path): continue
		var image=(load(path) as Texture2D).get_image()
		var rect=image.get_used_rect()
		var anchor=Vector2(rect.size.x*0.5,rect.size.y*(0.94 if id=="colorful_oak" else 0.86))
		var ratios={"delivery_depot":0.72,"delivery_truck":0.95,"soil_plot_empty":0.50,"young_seedlings":0.64,"wheat_plot_ready":0.75,"corn_plot_ready":0.78,"carrot_plot_ready":0.64,"flower_garden":0.64,"flower_patch":0.72,"garden_grass_clump":0.82,"decorative_pond":0.61,"flowering_bushes":0.80,"flowering_hedge":0.80,"apple_tree":0.94,"orange_tree":0.94,"stone_path_tile":0.50}
		if ratios.has(id): anchor.y=rect.size.y*float(ratios[id])
		for pen in JSON.parse_string(FileAccess.get_file_as_string("res://assets/ranch/manifest.json")).pens:
			if str(pen.id)!=id: continue
			var old=(load(str(pen.path)) as Texture2D).get_size()
			var uv=(Vector2(pen.region[0],pen.region[1])+Vector2(pen.anchor[0],pen.anchor[1]))/old
			anchor=uv*Vector2(image.get_size())-Vector2(rect.position)
		manifest.assets.append({"id":id,"path":path,"region":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"anchor":[anchor.x,anchor.y]})
	var file=FileAccess.open("res://assets/colorful_garden/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	print("COLORFUL ASSETS: ",manifest.assets.size())
	quit()
