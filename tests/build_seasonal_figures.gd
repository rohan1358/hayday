extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
func _initialize(): call_deferred("run")
# Extract supplied artwork only: preserve RGB; flood out connected paper.
func cut_paper(tile: Image) -> void:
	var w=tile.get_width()
	var h=tile.get_height()
	var bytes=tile.get_data()
	var seen=PackedByteArray()
	seen.resize(w*h)
	var stack=PackedInt32Array()
	for x in w: stack.append(x);stack.append((h-1)*w+x)
	for y in h: stack.append(y*w);stack.append(y*w+w-1)
	while not stack.is_empty():
		var p=stack[-1]
		stack.resize(stack.size()-1)
		if seen[p]: continue
		seen[p]=1
		var r=bytes[p*4]/255.0
		var g=bytes[p*4+1]/255.0
		var b=bytes[p*4+2]/255.0
		var is_paper=minf(r,minf(g,b))>=0.88 and maxf(r,maxf(g,b))-minf(r,minf(g,b))<=0.085
		var is_floor=int(p/w)>h*0.90 and minf(r,minf(g,b))>0.70 and maxf(r,maxf(g,b))-minf(r,minf(g,b))<0.17
		if not is_paper and not is_floor: continue
		bytes[p*4+3]=0
		var x=p%w
		for next in [p-1,p+1,p-w,p+w]:
			if next>=0 and next<w*h and absi(next%w-x)<=1 and not seen[next]: stack.append(next)
	tile.set_data(w,h,false,Image.FORMAT_RGBA8,bytes)
func run():
	var folder="res://assets/wardrobe/seasonal_figures"
	DirAccess.make_dir_recursive_absolute(folder)
	var source=Image.load_from_file("res://assets/wardrobe/seasonal_figures_source.png")
	source.convert(Image.FORMAT_RGBA8)
	var columns=[143,424,716,1003,1287]
	var rows=[50,342,633,908,1173]
	for gender in 2:
		for season in 4:
			for side in 2:
				var col=gender*2+side
				var bottom=[332,623,899,1173][season]
				var tile=source.get_region(Rect2i(columns[col]+3,rows[season],columns[col+1]-columns[col]-6,bottom-rows[season]))
				cut_paper(tile)
				var bounds=ART.visible_bounds(tile)
				tile=tile.get_region(bounds)
				tile.save_png(folder+"/%s_%d_%s.png"%["female" if gender==0 else "male",season,"front" if side==0 else "back"])
	print("SEASONAL FIGURES EXTRACTED: 16 original complete front/back figures")
	quit()
