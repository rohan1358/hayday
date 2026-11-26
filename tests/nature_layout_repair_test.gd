extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://nature_layout_test.json";host.game.backup_path="user://nature_layout_backup.json"
 root.add_child(host)
 var farm=host.farm
 var safe=preload("res://scripts/safe_asset_placement.gd")
 var projection=preload("res://scripts/asset_projection.gd")
 var tree=farm.wild_tree_position(0)
 host.game.layout_positions.dapur=[tree.x,tree.y]
 host.game.building_upgrades.nodes[0].position=[tree.x,tree.y]
 safe.repair_nature(host)
 var house=projection.info(farm,"dapur",tree)
 for i in farm.WILD_TREES.size():
  if i in host.game.cleared_wild_trees: continue
  assert(not house.bounds.grow(25).intersects(projection.wild_tree_bounds(farm,i)),"Tree must not overlap house")
 for i in host.game.building_upgrades.nodes.size():
  var point=host.game.building_upgrades.nodes[i].position
  assert(preload("res://scripts/building_upgrades.gd").boulder_clear(farm,Vector2(point[0],point[1]),i),"Boulders must stay clear of buildings and trees")
 var positions=host.game.building_upgrades.tree_positions.duplicate(true)
 safe.repair_nature(host)
 assert(positions==host.game.building_upgrades.tree_positions,"Repeated repair must preserve clear tree placements")
 print("NATURE LAYOUT PASS: legacy house/tree and rock overlaps repaired, stable persisted positions")
 host.queue_free();await process_frame;quit()
