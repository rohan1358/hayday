extends SceneTree
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize():
	var art=FarmArt.new()
	var expected=[]
	for group in [FarmArt.ART_IDS_V2,FarmArt.ART_IDS_V3,FarmArt.ART_IDS_V4,FarmArt.ART_IDS_V5,FarmArt.ART_IDS_V6,FarmArt.ART_IDS_V7,FarmArt.ART_IDS_V8,FarmArt.ART_IDS_V9,FarmArt.ART_IDS_V10,FarmArt.ART_IDS_V11]: expected.append_array(group)
	for id in expected:
		check(art.sprites.has(id) and str(art.sprites[id].texture.resource_path).begins_with("res://assets/colorful_garden/"),"legacy asset replaced "+str(id))
	var grass=preload("res://scripts/colorful_environment.gd").grass(art)
	check(grass!=null,"authored grass texture registered")
	if grass!=null:
		var image=grass.get_image()
		var colors={}
		for y in range(0,image.get_height(),32):
			for x in range(0,image.get_width(),32): colors[image.get_pixel(x,y).to_html()]=true
		check(colors.size()>30,"grass contains leaf and flower texture instead of a flat fill")
		check(maxi(image.get_width(),image.get_height())<=512,"grass is bounded for Android")
	check(art.sprites.has("orange_tree") and art.sprites.has("garden_grass_clump") and art.sprites.has("gazebo"),"primitive environment replacements available")
	print("ENVIRONMENT COVERAGE: ",expected.size()," FAILURES: ",failures)
	quit(failures)
