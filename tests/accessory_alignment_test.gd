extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
func _initialize(): call_deferred("run")
func run():
	var fixture=Image.create(100,100,false,Image.FORMAT_RGBA8)
	fixture.fill(Color.TRANSPARENT)
	fixture.fill_rect(Rect2i(30,20,40,60),Color.WHITE)
	fixture.set_pixel(1,1,Color(1,0,0,0.01))
	fixture.set_pixel(95,95,Color.WHITE)
	assert(ART.visible_bounds(fixture)==Rect2i(29,19,42,62))
	for sector in 5:
		for outfit in 4:
			var data={"outfit":outfit}
			var large=Rect2(40,30,180,400)
			var small=Rect2(0,0,18,40)
			var a=ART.belt_path(large,data,sector)
			var b=ART.belt_path(small,data,sector)
			for i in a.size(): assert(((a[i]-large.position)/10).distance_to(b[i])<0.01)
	print("ALIGNMENT V4 PASS: sprite speck removal; belt geometry scales consistently in 20 costume/view combinations")
	quit()
