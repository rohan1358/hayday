extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
class Sheet extends Control:
	func _draw():
		for g in 2:
			for s in 4:
				var data={"gender":"female" if g else "male","outfit":s}
				var tex=ART.character(data)
				var target=Rect2(s*300+30,g*540+35,240,480)
				var body=ART.fitted(tex,target)
				draw_texture_rect(tex,body,false)
				draw_string(ThemeDB.fallback_font,Vector2(s*300+20,g*540+25),str(g)+":"+str(s),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.BLACK)
				for k in range(1,6):
					var y=body.position.y+body.size.y*k*0.1
					draw_line(Vector2(s*300,y),Vector2((s+1)*300,y),Color(0,0.5,0.8,0.4))
					draw_string(ThemeDB.fallback_font,Vector2(s*300,y),str(k*0.1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.BLUE)
				print("BODY ",g,":",s," ",body," texture ",tex.get_size())
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1200,1080)
	var bg=ColorRect.new()
	bg.color=Color("fff8e9")
	bg.size=Vector2(1200,1080)
	root.add_child(bg)
	root.add_child(Sheet.new())
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/character-fit-base.png")
	quit()
