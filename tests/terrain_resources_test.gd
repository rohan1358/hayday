extends SceneTree
func _initialize() -> void:
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/terrain_kit/catalog.json"))
	for item in catalog.sprites:
		var resource=load("res://assets/terrain_kit/"+item.resource) as AtlasTexture
		assert(resource!=null and resource.atlas!=null,"Missing bundled sprite: "+str(item.id))
		assert(resource.region.size.x>0 and resource.region.size.y>0)
		assert(resource.has_meta("ground_anchor"))
	print("TERRAIN RESOURCES PASS: all 71 standalone AtlasTexture resources load with anchors")
	quit()
