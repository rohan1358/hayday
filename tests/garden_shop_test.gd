extends SceneTree
const SHOP=preload("res://scripts/garden_shop_ui.gd")
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://garden_shop_test.json";host.game.backup_path="user://garden_shop_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var g=host.game;g.ftue.started=true;g.ftue.step="done";g.level=6;g.coins=10000
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 host.set_meta("first_farm_modal",false)
 host.switch_tab("toko")
 host.refresh_all()
 for category in 6:
  var tab=host.sheet.find_child("ShopTab"+str(category),true,false)
  assert(tab!=null)
  tab.pressed.emit()
  assert(host.get_meta("shop_category")==category)
  assert(host.sheet.find_children("ShopItem_*","Panel",true,false).size()>0)
  if DisplayServer.get_name()!="headless":
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/toko-kategori-%d.png"%category))
  print("PASS: shop category ",category)
 SHOP.select_category(host,1)
 var before=int(g.seeds.gandum);var coins=g.coins
 host.sheet.find_child("Buy_seed_gandum",true,false).pressed.emit()
 assert(int(g.seeds.gandum)==before+1 and g.coins==coins-int(g.CROPS.gandum.seed_cost))
 host.sheet.find_child("Detail_seed_gandum",true,false).pressed.emit()
 host.sheet.find_child("QuantityPlus",true,false).pressed.emit()
 assert(host.get_meta("shop_quantity")==2)
 before=int(g.seeds.gandum);coins=g.coins
 host.sheet.find_child("DetailBuy",true,false).pressed.emit()
 assert(int(g.seeds.gandum)==before+2 and g.coins==coins-2*int(g.CROPS.gandum.seed_cost))
 SHOP.select_category(host,3)
 coins=g.coins
 host.sheet.find_child("Buy_building_pabrik_pakan",true,false).pressed.emit()
 assert(g.has_construction("pabrik_pakan") and g.coins==coins-int(g.CONSTRUCTIONS.pabrik_pakan.cost))
 SHOP.select_category(host,4)
 var stock=int(preload("res://scripts/road_catalog.gd").prepare(g).stock.stone);coins=g.coins
 host.sheet.find_child("Buy_road_stone",true,false).pressed.emit()
 assert(int(g.road_inventory.stock.stone)==stock+1 and g.coins==coins-3)
 SHOP.select_category(host,2)
 host.sheet.find_child("Buy_pen_sapi",true,false).pressed.emit()
 assert(g.ftue.cow_built and g.ranch.pens.sapi.count==0)
 host.sheet.find_child("Buy_animal_sapi",true,false).pressed.emit()
 assert(g.ranch.pens.sapi.count==1)
 coins=g.coins
 var cow=SHOP.catalog(host,2)[1]
 SHOP.purchase(host,cow,1)
 assert(g.coins==coins)
 g.level=1
 SHOP.select_category(host,2)
 assert(host.sheet.find_child("Buy_pen_kambing",true,false).disabled)
 g.level=6
 SHOP.select_category(host,5)
 host.sheet.find_child("Buy_decor_flower_patch",true,false).pressed.emit()
 assert(g.decorations.size()>0)
 g.save_game()
 var copy=FarmGameState.new(false);copy.save_path=g.save_path;copy.backup_path=g.backup_path
 assert(copy.load_game() and copy.ranch.pens.sapi.count==1 and copy.road_inventory.stock.stone==stock+1)
 print("PASS: seed/road/pen/animal/decor purchases, duplicate guard, locked level, persistence")
 host.queue_free();await process_frame;quit()
