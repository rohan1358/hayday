extends SceneTree
func _initialize():call_deferred("run")
func run():
 var assets=preload("res://scripts/reference_assets.gd")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/clean_reference"))
 var count=0
 for table in [assets.ALIASES,assets.DECOR_CELLS]:
  for id in table:
   var cell=table[id]
   if cell[0] not in ["fishing","horse","harbor","train","village","cafe","camping","festival","market","greenhouse"]:continue
   var data=assets.sprite(id)
   var image=data.texture.get_image()
   if data.texture is ImageTexture:image.save_png("res://assets/clean_reference/"+id+".png");count+=1
 print("CROPS BAKED: ",count," isolated sprites")
 quit()
