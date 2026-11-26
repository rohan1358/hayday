extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
class Sheet extends Control:
	var gender:="male"
	func _draw():
		for outfit in 4:
			for season in 4:
				var data={"gender":gender,"outfit":outfit,"wardrobe_slots":{"head":ART.CATALOG.items(gender,season)[0],"neck":ART.CATALOG.items(gender,season)[1],"bag":ART.CATALOG.items(gender,season)[2]}}
				ART.paint(self,Rect2(season*250+15,outfit*400+30,220,355),data)
				draw_string(ThemeDB.fallback_font,Vector2(season*250+15,outfit*400+20),"Kostum %d / Aksesori %d"%[outfit,season],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.BLACK)
func _initialize(): call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1000,1600)
	var bg=ColorRect.new()
	bg.color=Color("fff8e9")
	bg.size=Vector2(1000,1600)
	root.add_child(bg)
	var sheet=Sheet.new()
	root.add_child(sheet)
	for gender in ["male","female"]:
		sheet.gender=gender
		sheet.queue_redraw()
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/pas-aksesori-"+gender+".png")
	quit()
