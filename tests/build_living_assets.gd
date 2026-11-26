extends SceneTree
const PACK=preload("res://scripts/living_garden_assets.gd")
func _initialize(): call_deferred("run")
func run():
	var manifest={"version":1,"contains_crop_stages":true,"assets":[]}
	var output_dir="C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/LivingGarden-Aset"
	DirAccess.make_dir_recursive_absolute(output_dir)
	var images={}
	var entries=PACK.ITEMS.duplicate(true)
	for stage in 4: entries.append({"id":PACK.GROWTH_IDS[stage],"name":"Stroberi Kristal Tahap "+str(stage),"pack":"strawberry_growth","cell":stage+4,"anchor_y":0.87})
	for entry in entries:
		var atlas_path=PACK.DIRECTORY+str(entry.pack)+".png"
		if not images.has(atlas_path):
			var texture=load(atlas_path) as Texture2D
			assert(texture!=null)
			var image=texture.get_image()
			image.convert(Image.FORMAT_RGBA8)
			images[atlas_path]=image
		var image: Image=images[atlas_path]
		var size=Vector2i(image.get_width()/4,image.get_height()/2)
		var origin=Vector2i(int(entry.cell)%4,int(int(entry.cell)/4))*size
		var tile=image.get_region(Rect2i(origin,size))
		var bytes=tile.get_data()
		var low=size
		var high=Vector2i.ZERO
		var opaque=0
		for y in size.y:
			for x in size.x:
				if bytes[(y*size.x+x)*4+3]<128: continue
				opaque+=1
				low=Vector2i(mini(low.x,x),mini(low.y,y))
				high=Vector2i(maxi(high.x,x),maxi(high.y,y))
		assert(opaque>200)
		var bounds=Rect2i(low,high-low+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,size))
		assert(tile.get_region(bounds).save_png(output_dir+"/"+str(entry.id)+".png")==OK)
		manifest.assets.append({"level":int(entry.get("level",20)),"usage":"crop_stage" if str(entry.id).begins_with("lg_crystal_stage_") else "decoration","id":entry.id,"name":entry.name,"atlas":atlas_path,"region":[origin.x+bounds.position.x,origin.y+bounds.position.y,bounds.size.x,bounds.size.y],"anchor":[bounds.size.x*0.5,bounds.size.y*float(entry.anchor_y)]})
	var file=FileAccess.open(PACK.DIRECTORY+"manifest.json",FileAccess.WRITE)
	assert(file!=null)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	var exported=FileAccess.open(output_dir+"/manifest.json",FileAccess.WRITE)
	var standalone=manifest.duplicate(true)
	for entry in standalone.assets:
		entry.file=str(entry.id)+".png"
		entry.erase("atlas")
		entry.region=[0,0,entry.region[2],entry.region[3]]
	exported.store_string(JSON.stringify(standalone,"\t"))
	exported.close()
	print("LIVING ASSETS BUILD PASS: 12 decorations + 4 crystal growth stages, shared atlases, grounded anchors")
	quit()
