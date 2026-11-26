extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/Startup.tscn")
 for i in 120:
  await process_frame
  if current_scene!=null and current_scene.scene_file_path=="res://scenes/Main.tscn":break
 assert(current_scene!=null and current_scene.scene_file_path=="res://scenes/Main.tscn","Normal launch must reach the farm")
 assert(current_scene.farm!=null and current_scene.farm.hybrid_controller!=null)
 print("STARTUP PASS: normal loading scene reaches the interactive farm")
 quit()
