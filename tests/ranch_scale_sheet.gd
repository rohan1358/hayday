extends SceneTree
const R=preload("res://scripts/ranch_state.gd")
class Sheet extends Control:
	var art
	var frames
	func _draw():
		draw_string(ThemeDB.fallback_font,Vector2(32,38),"PERBANDINGAN SKALA · rumah 300 · karakter ±120",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("355b48"))
		art.paint(self,"kitchen_cottage",Vector2(240,340),300)
		draw_string(ThemeDB.fallback_font,Vector2(160,375),"Rumah petani",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("355b48"))
		var data={"gender":"female","owned":["seasonal_figure_female_0"],"seasonal_pack_gender":{"female":0}}
		preload("res://scripts/wardrobe_assets.gd").paint(self,Rect2(410,220,100,125),data)
		var at_list=[Vector2(800,340),Vector2(790,720),Vector2(265,720),Vector2(550,1120)]
		for i in 4:
			var species=R.SPECIES[i]
			var at=at_list[i]
			art.paint(self,R.INFO[species].asset,at,R.PEN_WIDTHS[species])
			var sprite=art.sprites[R.INFO[species].asset]
			var factor=R.PEN_WIDTHS[species]/sprite.region.size.x
			var floor=at-sprite.anchor*factor+Vector2(0.64,0.73)*sprite.region.size*factor
			var texture=frames[species+"0"]
			var size=texture.get_size()*R.animal_width(species)/texture.get_width()
			draw_texture_rect(texture,Rect2(floor-Vector2(size.x*0.5,size.y*0.97),size),false)
			draw_string(ThemeDB.fallback_font,at+Vector2(-100,-R.PEN_WIDTHS[species]*0.5),species.to_upper()+" · kandang %d · hewan %d"%[R.PEN_WIDTHS[species],R.animal_width(species)],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("355b48"))
func _initialize(): call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1100,1250)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://ranch_scale_sheet.json";host.game.backup_path="user://ranch_scale_sheet_backup.json"
	root.add_child(host);host.hide()
	for species in R.SPECIES: host.game.ranch.pens[species].tier=1
	var bg=ColorRect.new();bg.color=Color("eff5df");bg.size=Vector2(1100,1250);root.add_child(bg)
	var sheet=Sheet.new();sheet.art=host.farm.farm_art;sheet.frames=host.farm.ranch_animator.frames
	root.add_child(sheet)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/skala-kandang-hewan-rumah.png")
	print("RANCH SCALE SHEET PASS")
	quit()
