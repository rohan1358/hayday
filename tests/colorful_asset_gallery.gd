extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.content_scale_size=Vector2i(1920,1500)
	root.size=Vector2i(1920,1500)
	var preview=Preview.new()
	root.add_child(preview)
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/colorful-environment-assets.png")
	print("COMPLETE ENVIRONMENT GALLERY PASS")
	preview.queue_free()
	await process_frame
	quit()
class Preview extends Control:
	var art=FarmArt.new()
	func _draw():
		draw_rect(get_viewport_rect(),Color("f6edda"))
		draw_string(ThemeDB.fallback_font,Vector2(35,45),"KEBUN CERIA · COLORFUL ENVIRONMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("68432b"))
		var entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/colorful_garden/manifest.json")).assets
		for i in entries.size():
			var x=25+(i%8)*237
			var y=75+(i/8)*235
			var box=StyleBoxFlat.new()
			box.bg_color=Color("fffbef")
			box.set_corner_radius_all(16)
			draw_style_box(box,Rect2(x,y,222,220))
			var sprite: Dictionary=art.sprites[str(entries[i].id)]
			var r: Rect2=sprite.region
			var factor=minf(190.0/r.size.x,166.0/r.size.y)
			var target=Rect2(Vector2(x+111,y+97)-r.size*factor*0.5,r.size*factor)
			draw_texture_rect_region(sprite.texture,target,r)
			draw_string(ThemeDB.fallback_font,Vector2(x+10,y+204),str(entries[i].id).replace("_"," "),HORIZONTAL_ALIGNMENT_LEFT,200,16,Color("674d36"))
