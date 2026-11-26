extends SceneTree
var failures=0
func check(ok: bool,title: String):
 print("PASS: " if ok else "FAIL: ",title)
 if not ok: failures+=1
func _initialize(): call_deferred("run")
func screen(farm,point: Vector2) -> Vector2:
 return (point-farm.camera_center)*farm.camera_zoom*farm.size/farm.get_virtual_size()+farm.size*0.5
func free_point(farm,key: String) -> Vector2:
 for y in range(650,1300,40):
  for x in range(680,1540,40):
   var at=Vector2(x,y)
   if farm.visible_world_rect().has_point(at) and farm.can_place(key,at): return at
 return Vector2.INF
func find_button(node: Node,title: String) -> Button:
 if node is Button and node.text==title: return node
 for child in node.get_children():
  var found=find_button(child,title)
  if found!=null: return found
 return null
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://garden_access_test.json"
 host.game.backup_path="user://garden_access_test_backup.json"
 host.game.ftue.started=true;host.game.ftue.step="done"
 host.game.level=3;host.game.coins=1000
 preload("res://scripts/first_coop.gd").build(host.game)
 host.game.save_game()
 root.add_child(host)
 var farm=host.farm
 var ui
 for node in host.get_children():
  if node.get_script()==load("res://scripts/first_farm_ui.gd"): ui=node
 host.toast_layer.hide()
 if "--visual" in OS.get_cmdline_user_args():
  farm.hybrid_controller.set_process(false)
  farm.ujang_position=Vector2(1240,1050)
  farm.camera_center=Vector2(1250,900);farm.camera_target=farm.camera_center
  farm.camera_zoom=1.15;farm.zoom_target=1.15
  for frame in 12: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/garden-character-scale.png")
  host.switch_tab("toko")
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/garden-shop-categories.png")
  host.switch_tab("pohon")
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/garden-tree-shop.png")
  host.switch_tab("kebun")
  host.toggle_arrange_mode();ui.refresh()
  farm.camera_center=Vector2(1050,700);farm.camera_target=farm.camera_center
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/garden-one-road-tile.png")
  host.queue_free();await process_frame
  print("GARDEN VISUAL PASS")
  quit();return
 var npc=farm.farm_art.ground_bounds("neighbor",Vector2.ZERO,100.0).size.y*0.88
 check(absf(151*farm.UJANG_SCALE-npc)<3,"farmer and neighbor have matching world heights")
 check(host.arrange_button.text=="PINDAH ASET","clear move-assets button exists")
 host.arrange_button.pressed.emit();ui.refresh()
 check(farm.edit_mode and not ui.card.visible and host.road_tool_buttons.object.visible,"move button opens usable editing tools without mission overlay")
 check(farm.editable_keys().has("starter_3") and farm.editable_keys().has("starter_8"),"original flowers and fences are editable objects")
 var source=farm.object_position("starter_3")
 farm.begin_edit_drag(screen(farm,source))
 check(farm.drag_key=="starter_3","tap selects original flower artwork")
 var destination=free_point(farm,"starter_3")
 check(destination!=Vector2.INF,"valid flower relocation exists")
 farm.move_edit_drag(screen(farm,destination));farm.finish_edit_drag()
 check(farm.object_position("starter_3")!=source and host.game.layout_positions.has("starter_3"),"dragging flowers commits a saved individual position")
 host.toggle_arrange_mode()
 for category in preload("res://scripts/garden_catalog.gd").CATEGORIES:
  host.switch_tab("toko")
  var button=host.sheet.find_child("GardenCategory_"+category[0],true,false)
  check(button!=null,"shop category visible: "+category[0])
  if button!=null: button.pressed.emit()
  check(host.active_tab==category[0],"category opens at Level 3: "+category[0])
 host.switch_tab("rumput")
 var coins=host.game.coins
 find_button(host.sheet,"BELI & PASANG").pressed.emit()
 var key=farm.placement_decoration_key
 check(key!="" and host.game.coins==coins-10,"grass purchase charges exactly ten coins and starts placement")
 check(farm.farm_art.sprites.has("grass_patch"),"grass uses an actual imported isometric asset")
 destination=free_point(farm,key)
 farm.finish_decoration_placement(screen(farm,destination))
 check(host.game.decoration_by_key(key).position.size()==2 and farm.editable_keys().has(key),"purchased grass is placed and movable")
 host.switch_tab("pohon")
 coins=host.game.coins
 find_button(host.sheet,"BELI & PASANG").pressed.emit()
 key=farm.placement_decoration_key
 check(host.game.coins==coins-90 and host.game.decoration_by_key(key).kind=="garden_tree","tree category purchases the tree shown in the shop")
 destination=free_point(farm,key)
 farm.finish_decoration_placement(screen(farm,destination))
 check(host.game.decoration_by_key(key).position.size()==2,"purchased tree is placed in the world")
 host.game.level=5
 check(farm.editable_keys().has("starter_3"),"original movable landscaping persists beyond the starter world")
 host.game.save_game()
 var restored=FarmGameState.new();restored.save_path=host.game.save_path;restored.backup_path=host.game.backup_path
 check(restored.load_game() and restored.layout_positions.has("starter_3") and restored.decorations.size()==2,"moved flowers and purchased grass/tree survive reload")
 host.queue_free();await process_frame
 print("GARDEN ACCESS FAILURES: ",failures)
 quit(failures)
