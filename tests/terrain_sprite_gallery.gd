extends SceneTree
class Gallery extends Node2D:
	var catalog: Dictionary
	var textures: Dictionary={}
	func _ready() -> void:
		for item in catalog.sprites:
			if not textures.has(item.source): textures[item.source]=load(item.source) as Texture2D
	func _draw() -> void:
		draw_rect(Rect2(0,0,1400,2200),Color("d9e7ce"))
		for i in catalog.sprites.size():
			var item=catalog.sprites[i]
			var source: Texture2D=textures[item.source]
			var values: Array=item.region
			var area=Rect2(values[0],values[1],values[2],values[3])
			var factor=minf(175.0/area.size.x,145.0/area.size.y)
			var center=Vector2(100+(i%7)*200,85+floori(float(i)/7)*195)
			draw_texture_rect_region(source,Rect2(center-area.size*factor*0.5,area.size*factor),area)
			draw_string(ThemeDB.fallback_font,center+Vector2(-90,88),str(item.id),HORIZONTAL_ALIGNMENT_LEFT,180,12,Color("243e29"))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1400,2200)
	root.content_scale_size=root.size
	var gallery=Gallery.new()
	gallery.catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/terrain_kit/catalog.json"))
	root.add_child(gallery)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/terrain-kit-sprites.png"))
	print("SPRITE GALLERY PASS: ",gallery.catalog.sprites.size()," sprite regions rendered")
	gallery.queue_free();await process_frame;quit()
