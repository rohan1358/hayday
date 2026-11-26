extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://orchard_ui_test.json"
 host.game.backup_path="user://orchard_ui_test_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"): child.opening.hide()
  if child.get_script()==load("res://scripts/farm_progression.gd"):
   child.set_process(false);child.pending.clear()
   if child.dialog!=null: child.dialog.hide()
 host.set_meta("first_farm_modal",false)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=30;host.game.coins=100000
 host.on_orchard_plant(2,"mangga")
 assert(host.game.orchard[2].fruit=="mangga")
 host.switch_tab("kebun_buah")
 assert(host.orchard_status_rows.size()>=2)
 var due=host.game.orchard[2].ready_at
 host.orchard_speedup={"id":"test_reward","index":2,"fruit":"mangga","ready_at":due}
 host._on_speedup_rewarded("incorrect_token")
 assert(host.game.orchard[2].ready_at==due)
 host._on_speedup_rewarded("test_reward")
 assert(host.game.tree_ready(2))
 host.on_orchard_harvest(2)
 assert(not host.game.tree_ready(2))
 assert(host.game.inventory.mangga==3)
 host.orchard_speedup={"id":"stale","index":2,"fruit":"mangga","ready_at":due}
 var current=host.game.orchard[2].ready_at
 host.game.orchard[2].ready_at=current+1
 host._on_speedup_rewarded("stale")
 assert(host.game.orchard[2].ready_at==current+1)
 host.switch_tab("toko")
 var entries=preload("res://scripts/garden_shop_ui.gd").catalog(host,1)
 var count=0
 for entry in entries:
  if entry.kind=="tree": count+=1
 assert(count==12)
 host.switch_tab("produksi")
 host.switch_tab("gudang")
 host.switch_tab("kebun_buah")
 if DisplayServer.get_name()!="headless":
  for i in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/kebun-buah-menu.png"))
 if DisplayServer.get_name()!="headless":
  host.switch_tab("kebun")
  for index in host.game.orchard.size():
   host.game.orchard[index].fruit=host.game.FRUITS.keys()[index]
   host.game.orchard[index].ready_at=host.game.now()-1 if index%2==0 else host.game.now()+180
   host.game.layout_positions["buah_%d"%index]=[2450+(index%4)*240,2050+floori(float(index)/4.0)*300]
  host.farm.camera_zoom=0.8;host.farm.zoom_target=0.8
  host.farm.camera_center=host.farm.clamp_camera_center(Vector2(2810,2220),0.8)
  host.farm.camera_target=host.farm.camera_center
  host.toast_layer.hide()
  for i in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/kebun-buah-pohon.png"))
 print("ORCHARD UI PASS: shop, planting placement, harvest, ad reward token and stale reward protection")
 host.queue_free();await process_frame;quit()
