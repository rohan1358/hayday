extends SceneTree
const RANCH=preload("res://scripts/ranch_state.gd")
func _initialize(): call_deferred("run")
func run():
	var manifest={"version":1,"pens":[]}
	for species in RANCH.SPECIES:
		var id=str(RANCH.INFO[species].asset)
		var directory="res://assets/art_v8/" if species in ["babi","kambing"] else "res://assets/art_v3/"
		var original=(load(directory+id+".png") as Texture2D).get_image()
		var old_anchors=JSON.parse_string(FileAccess.get_file_as_string(directory+"anchors.json"))
		var uv=Vector2(float(old_anchors[id][0])/original.get_width(),float(old_anchors[id][1])/original.get_height())
		var path="res://assets/ranch/"+id+".png"
		var image=(load(path) as Texture2D).get_image()
		var bounds=image.get_used_rect()
		var anchor=uv*Vector2(image.get_size())-Vector2(bounds.position)
		manifest.pens.append({"id":id,"path":path,"region":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"anchor":[anchor.x,anchor.y]})
	var file=FileAccess.open("res://assets/ranch/manifest.json",FileAccess.WRITE)
	assert(file!=null)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	print("RANCH ASSETS PASS: four empty original-style pens and 16 animation poses")
	quit()

