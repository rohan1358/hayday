extends SceneTree
const PACK=preload("res://scripts/living_garden_assets.gd")
class Gallery extends Control:
	var art=FarmArt.new()
	func _draw():
		var entries=PACK.ITEMS.duplicate(true)
		for i in 4: entries.append({"id":PACK.GROWTH_IDS[i],"name":["Bibit Kristal","Tanaman Muda","Berbunga / Buah Muda","Siap Panen Kristal"][i],"level":20})
		for i in entries.size():
			var x=(i%4)*300
			var y=int(i/4)*290
			draw_style_box(panel_style(),Rect2(x+5,y+5,290,280))
			draw_string(ThemeDB.fallback_font,Vector2(x+16,y+28),str(entries[i].name),HORIZONTAL_ALIGNMENT_LEFT,270,18,Color("315c45"))
			draw_string(ThemeDB.fallback_font,Vector2(x+16,y+50),"TERBUKA LV "+str(entries[i].level),HORIZONTAL_ALIGNMENT_LEFT,270,13,Color("8c704e"))
			art.paint(self,str(entries[i].id),Vector2(x+150,y+257),225)
	func panel_style() -> StyleBoxFlat:
		var s=StyleBoxFlat.new()
		s.bg_color=Color("f6f4e6")
		s.set_corner_radius_all(14)
		return s
func _initialize(): call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1200,1160)
	var bg=ColorRect.new()
	bg.color=Color("dcead3")
	bg.size=Vector2(1200,1160)
	root.add_child(bg)
	var gallery=Gallery.new()
	root.add_child(gallery)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var path="C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/living-garden-assets.png"
	root.get_texture().get_image().save_png(path)
	print("LIVING VISUAL PASS: 12 decorations and four crystal crop growth stages")
	quit()
