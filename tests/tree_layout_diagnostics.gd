extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://tree_diagnostics.json";host.game.backup_path="user://tree_diagnostics_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 var t=load("res://scripts/reference_terrain.gd")
 var bad=0
 for i in host.farm.WILD_TREES.size():
  var at=host.farm.wild_tree_position(i)
  var bounds=t.tree_bounds(at,i)
  if not t.asset_clear(at) or not t.bounds_clear(bounds):
   bad+=1
   if bad<15:print("BAD ",i," at ",at," rect ",bounds," stored=",host.game.building_upgrades.tree_positions.get(str(i))," active=",load("res://scripts/four_seasons.gd").active_id)
 print("BAD COUNT ",bad)
 quit()
