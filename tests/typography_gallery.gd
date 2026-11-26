extends SceneTree
var host
var folder="res://../outputs/typography-before"
func _initialize(): call_deferred("run")
func shot(id: String):
 for i in 4: await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"/"+id+".png"))
func run():
 if "--after" in OS.get_cmdline_user_args(): folder="res://../outputs/typography-after"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://typography_gallery.json";host.game.backup_path="user://typography_gallery_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var game=host.game;game.ftue.started=true;game.ftue.step="done";game.level=6;game.coins=10000
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 host.set_meta("first_farm_modal",false)
 preload("res://scripts/first_coop.gd").build(game)
 host.refresh_all()
 for tab in ["kebun","pesanan","toko","gudang","koleksi","ayam","sapi","ternak","produksi","pakan","upgrade","misi","pengaturan","jalan","bunga","pohon","rumput","gedung","dekorasi","aktivitas","pengunjung","pasar","kebun_buah"]:
  if "--production" in OS.get_cmdline_user_args() and tab!="produksi": continue
  host.switch_tab(tab)
  await shot(tab)
  print("PAGE: ",tab)
 if "--production" in OS.get_cmdline_user_args():
  host.queue_free();await process_frame;quit();return
 host.switch_tab("toko")
 for category in range(1,6):
  preload("res://scripts/garden_shop_ui.gd").select_category(host,category)
  await shot("shop-"+str(category))
 host.switch_tab("kebun")
 var popup=preload("res://scripts/level_up_popup.gd").new();popup.host=host;popup.reached_level=5;host.add_child(popup)
 await create_timer(0.65).timeout
 await shot("level-up");popup.queue_free();await process_frame
 for node in host.find_children("*","",true,false):
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/wardrobe_editor.gd":
   node.open();await shot("wardrobe");node.hide();break
 if "--after" in OS.get_cmdline_user_args():
  for dimensions in [Vector2i(360,640),Vector2i(390,844),Vector2i(720,1280)]:
   DisplayServer.window_set_size(dimensions)
   for tab in ["toko","pesanan","gudang","ayam"]:
    host.switch_tab(tab);await shot("%dx%d-%s"%[dimensions.x,dimensions.y,tab])
 print("GALLERY PASS ",folder)
 host.queue_free();await process_frame;quit()
