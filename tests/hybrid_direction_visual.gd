extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
class Sheet extends Control:
	var gender="male"
	func _draw():
		for outfit in 4:
			for sector in 5:
				var data={"gender":gender,"outfit":outfit,"wardrobe_slots":ART.CATALOG.defaults(gender)}
				var dir=Vector2(sin(sector*PI/4),cos(sector*PI/4))
				ART.paint(self,Rect2(sector*200+10,outfit*330+25,180,295),data,{"direction":dir,"activity":"walk","clock":0.1})
				draw_string(ThemeDB.fallback_font,Vector2(sector*200+10,outfit*330+18),"Kostum %d • Arah %d"%[outfit,sector],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.BLACK)
func _initialize(): call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1000,1320)
	var bg=ColorRect.new()
	bg.color=Color("fff8e9")
	bg.size=Vector2(1000,1320)
	root.add_child(bg)
	var sheet=Sheet.new()
	root.add_child(sheet)
	for gender in ["male","female"]:
		sheet.gender=gender
		sheet.queue_redraw()
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/hybrid-directions-"+gender+".png")
	print("DIRECTIONAL VISUAL PASS: forty costumes/views with worn accessories")
	quit()
