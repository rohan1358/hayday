extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var h=load("res://scenes/Main.tscn").instantiate()
 h.game.save_path="user://layout_diag_new.json"
 h.game.backup_path="user://layout_diag_backup.json"
 DirAccess.remove_absolute(h.game.save_path)
 DirAccess.remove_absolute(h.game.backup_path)
 root.add_child(h)
 for cell in preload("res://scripts/cheerful_layout.gd").ROUTE:
  var at=h.farm.road_visual_center(cell)
  for key in h.farm.editable_keys():
   var half=h.farm.object_half_size(key)
   if h.farm.road_segment_overlaps_rect(at,at,Rect2(h.farm.object_position(key)-half,half*2),h.farm.ROAD_HALF_WIDTH): print(cell," blocked ",key)
 h.queue_free()
 await process_frame
 quit()
