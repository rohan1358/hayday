extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
func _initialize(): call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/wardrobe/reference_v5")
	var columns=[0,288,490,768,1040,1250,1536]
	var rows=[0,285,515,755,1024]
	for view in ["front","back"]:
		var image=Image.load_from_file("res://assets/wardrobe/reference_"+view+"_v5.png")
		image.convert(Image.FORMAT_RGBA8)
		print(view," ",image.get_size()," corner=",image.get_pixel(0,0))
		for gender in 2:
			for season in 4:
				for slot in 3:
					var col=gender*3+slot
					var region=Rect2i(columns[col],rows[season],columns[col+1]-columns[col],rows[season+1]-rows[season])
					var tile=image.get_region(region)
					var bounds=ART.visible_bounds(tile)
					tile=tile.get_region(bounds)
					var id=gender*12+season*3+slot
					tile.save_png("res://assets/wardrobe/reference_v5/%02d_%s.png"%[id,view])
	print("REFERENCE ACCESSORIES EXTRACTED: 24 paired front/back items")
	quit()
