extends SceneTree
const LAYOUT=preload("res://scripts/cheerful_layout.gd")
var failures=0
func check(ok: bool,title: String):
 print("PASS: " if ok else "FAIL: ",title)
 if not ok: failures+=1
func _initialize(): call_deferred("run")
func run():
 check(ProjectSettings.get_setting("application/config/name")=="Cheerful Garden","project display name is Cheerful Garden")
 check(ProjectSettings.globalize_path("user://").replace("\\","/").trim_suffix("/").ends_with("Godot/app_userdata/Kebun Ceria"),"renaming preserves the previous user-data directory")
 var game=FarmGameState.new()
 game.save_path="user://cheerful_migration_test.json";game.backup_path="user://cheerful_migration_backup.json"
 check(game.layout_positions.dapur==[980,600] and game.layout_positions.ayam==[1450,600],"house and ranch match the reference composition")
 check(game.coins==100 and game.diamonds==10 and game.seeds.gandum==3,"visual redesign preserves the actual new-player economy")
 check(game.road_tiles.size()==LAYOUT.ROUTE.size(),"new farm gets a real owned starter walkway")
 game.ftue.erase("cheerful_layout");game.layout_positions.dapur=[750,580]
 game.road_tiles={"2,3":"moss","3,3":"brick","4,3":"stone"}
 var inventory=game.inventory.duplicate(true);var stock=game.road_inventory.duplicate(true)
 check(LAYOUT.ensure(game) and not LAYOUT.ensure(game),"layout migration applies once")
 check(game.coins==100 and game.inventory==inventory and game.road_inventory==stock and game.road_tiles.size()==3,"layout migration preserves currency, items, and road ownership")
 check(LAYOUT.restore(game) and game.layout_positions.dapur==[750,580] and game.road_tiles.has("2,3"),"previous positions can be restored")
 var legacy=FarmGameState.new(false)
 check(not LAYOUT.ensure(legacy),"legacy non-FTUE farms are not forcibly rearranged")
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://cheerful_ui_test.json";host.game.backup_path="user://cheerful_ui_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var guide=preload("res://scripts/cheerful_menus.gd").guide(host)
 guide.start_adventure()
 for i in 8: await process_frame
 var hud=host.get_node("CheerfulPresentation")
 check(host.get_node("CheerfulHeader/CheerfulLogo")!=null,"new logo is a live header asset")
 check(hud.gift.visible and hud.mission.visible,"gift and task cards are visible like the reference")
 var ids=[]
 for node in host.navbar.get_children():
  if node.has_meta("tab_id"): ids.append(str(node.get_meta("tab_id")))
 check(ids==["kebun","pesanan","toko","gudang","koleksi"],"bottom navigation matches reference ordering")
 check(host.farm.hybrid_controller.ui.seed_button.visible,"large wheat action button is visible during welcome")
 hud.gift.pressed.emit()
 check(host.active_tab=="hadiah_pemula" and host.sheet!=null,"gift card opens actual reward progression")
 host.switch_tab("koleksi")
 check(host.active_tab=="koleksi" and host.sheet!=null,"collection button opens real wardrobe and inventory links")
 host.switch_tab("pengaturan")
 check(host.active_tab=="pengaturan" and host.sheet!=null,"gear opens functional settings")
 host.switch_tab("kebun")
 host.farm.hybrid_controller.ui.seed_button.pressed.emit()
 check(host.farm.hybrid_controller.ui.menu.visible and host.farm.hybrid_controller.ui.seed_plot==0,"gold wheat action opens actual first-plot seed picker")
 for id in ["kebun","pesanan","toko","gudang","koleksi","bibit","hadiah","koin","permata","surat","notifikasi","pengaturan"]:
  var tex=preload("res://scripts/colorful_icons.gd").texture(id)
  check(tex!=null and tex.get_width()<=128,"new optimized 3D icon available: "+id)
 host.queue_free();await process_frame
 print("CHEERFUL DESIGN FAILURES: ",failures)
 quit(failures)
