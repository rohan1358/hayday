extends SceneTree
func _initialize():
 var image=Image.load_from_file("res://assets/colorful_garden/neighbor_source.png")
 var bounds=image.get_used_rect()
 image=image.get_region(bounds)
 image.resize(roundi(image.get_width()*512.0/image.get_height()),512,Image.INTERPOLATE_LANCZOS)
 image.save_png("res://assets/colorful_garden/neighbor.png")
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/colorful_garden/manifest.json"))
 var entries=[]
 for entry in manifest.assets:
  if entry.id!="neighbor": entries.append(entry)
 entries.append({"id":"neighbor","path":"res://assets/colorful_garden/neighbor.png","region":[0,0,image.get_width(),image.get_height()],"anchor":[image.get_width()*0.41,image.get_height()-2]})
 manifest.assets=entries
 var file=FileAccess.open("res://assets/colorful_garden/manifest.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(manifest,"  "))
 print("NEIGHBOR ASSET: ",image.get_size()," alpha=",image.get_pixel(0,0).a)
 quit()
