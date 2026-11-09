extends SceneTree

# Isolated texture-import and draw verification. No Main scene, save, APK or
# gameplay scripts are instantiated. Writes a screenshot in art_v11 only.

const ROOT_PATH := "res://assets/art_v11/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT_PATH + "manifest.json"))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("ART_V11 invalid manifest")
		quit(1)
		return
	var records: Dictionary = {}
	for entry in data["assets"]:
		records[String(entry["id"])] = entry

	# The project's logical canvas is 720x1280, while this QA screenshot is
	# captured at 450x800. Keep placements in 450x800 design coordinates.
	var logical_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 450)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 800))
	)
	var canvas := Node2D.new()
	canvas.scale = logical_size / Vector2(450.0, 800.0)
	root.add_child(canvas)

	var back := ColorRect.new()
	back.size = Vector2(450, 800)
	back.color = Color("#a2d47e")
	canvas.add_child(back)

	var world := Node2D.new()
	canvas.add_child(world)
	var lawn := Polygon2D.new()
	lawn.polygon = PackedVector2Array([
		Vector2(10, 220), Vector2(400, 220),
		Vector2(435, 520), Vector2(20, 560)
	])
	lawn.color = Color("#9bcf77")
	world.add_child(lawn)
	var lane := Polygon2D.new()
	lane.polygon = PackedVector2Array([
		Vector2(0, 460), Vector2(450, 508),
		Vector2(450, 587), Vector2(0, 555)
	])
	lane.color = Color("#e3c996")
	world.add_child(lane)

	var labels := Label.new()
	labels.text = "KEBUN CERIA  /  ART V11"
	labels.add_theme_color_override("font_color", Color("#31634b"))
	labels.add_theme_font_size_override("font_size", 21)
	labels.position = Vector2(20, 23)
	canvas.add_child(labels)
	var caption := Label.new()
	caption.text = "Godot 4.7 texture import • in-engine visual QA"
	caption.add_theme_color_override("font_color", Color("#52765c"))
	caption.add_theme_font_size_override("font_size", 13)
	caption.position = Vector2(20, 57)
	canvas.add_child(caption)

	var placements := [
		{"id":"pollinator_house", "foot":Vector2(128, 367), "width":156.0},
		{"id":"herb_drying_rack", "foot":Vector2(324, 382), "width":167.0},
		{"id":"rainwater_collector", "foot":Vector2(124, 682), "width":162.0},
		{"id":"wildflower_crescent", "foot":Vector2(322, 665), "width":176.0},
	]
	for placement in placements:
		var asset_id: String = placement["id"]
		var record: Dictionary = records.get(asset_id, {})
		if record.is_empty():
			push_error("ART_V11 missing asset in manifest: " + asset_id)
			quit(1)
			return
		var tex: Texture2D = load(ROOT_PATH + String(record["file"]))
		if tex == null:
			push_error("ART_V11 Godot import returned null: " + asset_id)
			quit(1)
			return
		if tex.get_width() != int(record["dimensions_px"][0]) or tex.get_height() != int(record["dimensions_px"][1]):
			push_error("ART_V11 size mismatch: " + asset_id)
			quit(1)
			return
		var scale_factor: float = float(placement["width"]) / tex.get_width()
		var anchor := Vector2(record["foot_anchor_px"][0],record["foot_anchor_px"][1])
		var at: Vector2 = placement["foot"]
		var shadow := Polygon2D.new()
		var verts := PackedVector2Array()
		for n in range(24):
			var angle := TAU * n / 24.0
			verts.append(Vector2(cos(angle)*placement["width"]*0.43,
								 sin(angle)*13.0))
		shadow.polygon = verts
		shadow.position = at + Vector2(0, 6)
		shadow.color = Color(0.16, 0.34, 0.19, 0.14)
		world.add_child(shadow)
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = tex
		sprite.scale = Vector2.ONE * scale_factor
		sprite.position = at - anchor * scale_factor
		world.add_child(sprite)
		print("ART_V11_GODOT_TEXTURE_OK ",asset_id," size=",tex.get_size(),
			  " foot=",anchor," scale=",scale_factor)

	await create_timer(0.55).timeout
	await RenderingServer.frame_post_draw
	var path := ROOT_PATH + "godot_sprite_preview.png"
	var screen := root.get_viewport().get_texture().get_image()
	var status := screen.save_png(path)
	print("ART_V11_GODOT_SCREENSHOT ",ProjectSettings.globalize_path(path),
		  " status=",status," size=",screen.get_size())
	quit(0 if status == OK else 1)
