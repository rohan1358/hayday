extends SceneTree
func _initialize():call_deferred("run")
func run():
 var terrain=load("res://scripts/reference_terrain.gd")
 for i in 9:
  var data=terrain.tree_info("summer",i)
  print("ATLAS ",i," ",data.number," size=",data.size," anchor=",data.anchor," rect=",data.texture.region," bounds=",terrain.tree_bounds(Vector2(1000,2400),i))
 quit()
