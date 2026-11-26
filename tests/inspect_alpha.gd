extends SceneTree
func _initialize():
	var im=Image.load_from_file("res://assets/wardrobe/reference_front_v5.png")
	for p in [Vector2i(15,226),Vector2i(30,225),Vector2i(50,140),Vector2i(72,85),Vector2i(200,80),Vector2i(200,90),Vector2i(500,135)]: print(p," ",im.get_pixelv(p))
	quit()
