extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
func _initialize(): call_deferred("run")
func run():
	var layout={"version":4,"atlas_sizes":{},"regions":{}}
	for index in 24:
		for sector in 5:
			var texture=ART.directional_accessory(index,sector)
			assert(texture!=null)
			var key=str(index)+"_"+str(sector)
			layout.regions[key]=ART.cache["crop_"+key]
	for path in ART.ATLAS_PATHS:
		var image: Image=ART.cache["raw_"+path]
		layout.atlas_sizes[path]=[image.get_width(),image.get_height()]
	var file=FileAccess.open("res://assets/wardrobe/colorful_regions_v4.json",FileAccess.WRITE)
	assert(file!=null)
	file.store_string(JSON.stringify(layout))
	file.close()
	print("COLORFUL REGIONS PASS: 120 precomputed sprite crops, avoids repeated atlas scans on Android")
	quit()
