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
		if minf(r,minf(g,b))<0.88 or maxf(r,maxf(g,b))-minf(r,minf(g,b))>0.085: continue
		bytes[p*4+3]=0
		var x=p%w
		for next in [p-1,p+1,p-w,p+w]:
			if next>=0 and next<w*h and absi(next%w-x)<=1 and not seen[next]: stack.append(next)
	tile.set_data(w,h,false,Image.FORMAT_RGBA8,bytes)
func run():
	var folder="res://assets/wardrobe/reference_v6"
	DirAccess.make_dir_recursive_absolute(folder)
	var source=Image.load_from_file("res://assets/wardrobe/reference_sheet_v6.png")
	source.convert(Image.FORMAT_RGBA8)
	print("SOURCE ",source.get_size())
	var columns=[135,417,708,995,1295]
	var slots=[[50,150,154,212,220,275],[341,440,445,503,514,569],[630,733,737,800,804,858],[904,1015,1019,1086,1089,1138]]
	for gender in 2:
		for season in 4:
			for slot in 3:
				for side in 2:
					var col=gender*2+side
					var region=Rect2i(columns[col]+2,slots[season][slot*2],columns[col+1]-columns[col]-4,slots[season][slot*2+1]-slots[season][slot*2])
					var tile=source.get_region(region)
					cut_paper(tile)
					var bounds=ART.visible_bounds(tile)
					tile=tile.get_region(bounds)
					tile.save_png(folder+"/%02d_%s.png"%[gender*12+season*3+slot,"front" if side==0 else "back"])
	print("V6 EXTRACTION PASS: 48 original sprites, paper removed without redesign")
	quit()
