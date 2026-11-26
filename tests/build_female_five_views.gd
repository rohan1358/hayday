extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
func _initialize(): call_deferred("run")
func run():
	var source=Image.load_from_file("res://assets/wardrobe/female_five_views_source.png")
	source.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute("res://assets/wardrobe/female_five_views")
	for season in 4:
		for sector in 5:
			var x0=roundi(float(sector)*source.get_width()/5)
			var x1=roundi(float(sector+1)*source.get_width()/5)
			var y0=roundi(float(season)*source.get_height()/4)
			var y1=roundi(float(season+1)*source.get_height()/4)
			var tile=source.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
			var bounds=ART.visible_bounds(tile)
			tile=tile.get_region(bounds)
			tile.save_png("res://assets/wardrobe/female_five_views/%d_%d.png"%[season,sector])
	print("FEMALE FIVE VIEWS EXTRACTED: twenty original seasonal figures")
	quit()
