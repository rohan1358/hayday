extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
const PACKS=preload("res://scripts/seasonal_character_packs.gd")
class Sheet extends Control:
	func _draw():
		for season in 4:
			for column in 4:
				var gender="female" if column<2 else "male"
				var data={"gender":gender,"owned":[PACKS.key(gender,season)],"seasonal_pack_gender":{gender:season}}
				ART.paint(self,Rect2(column*200+10,season*310+25,180,280),data,{"direction":Vector2.UP if column%2 else Vector2.DOWN})
				draw_string(ThemeDB.fallback_font,Vector2(column*200+10,season*310+18),("Cewe" if gender=="female" else "Cowo")+(" belakang" if column%2 else " depan"),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("355b48"))
func _initialize(): call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(800,1240)
	var bg=ColorRect.new()
	bg.color=Color("b2da72")
	bg.size=Vector2(800,1240)
	root.add_child(bg)
	root.add_child(Sheet.new())
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/paket-musim-figur-utuh.png")
	print("SEASONAL PACK VISUAL PASS")
	quit()
