extends SceneTree
const M=preload("res://scripts/mainland_layout.gd")
func _initialize():call_deferred("run")
func settle():
 for i in 10:await process_frame
func click_at(point):
 var move=InputEventMouseMotion.new();move.position=point;Input.parse_input_event(move)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func click(node):await click_at(node.get_global_rect().get_center())
func run():
 root.size=Vector2i(720,1280)
 var source=JSON.parse_string(FileAccess.get_file_as_string("user://visible_districts.json"))
 source.world_regions.island_journey.worlds.summer.zoning_version=12
 source.decorations.append({"key":"dekor_999","kind":"flower_patch","position":[4000,5000]});source.next_decoration_id=1000
 source.layout_positions.pasar=[4000,5000];source.layout_positions.gudang=[3900,3000]
 var file=FileAccess.open("user://mainland_market_test.json",FileAccess.WRITE);file.store_string(JSON.stringify(source));file.close()
 var host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://mainland_market_test.json";host.game.backup_path="user://mainland_market_backup.json";root.add_child(host)
 assert(host.game.coins==int(source.coins) and host.game.level==int(source.level),"Layout migration must retain currency and level")
 var f=host.farm;f.hybrid_controller.set_process(false)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 for key in f.editable_keys():
  if key.begins_with("wild_") or key.begins_with("buah_") or key.begins_with("bridge_") or key=="starter_14":continue
  assert(M.allowed(f,key,f.object_position(key)),"Non-tree asset must stay on the home bank: "+key)
 assert(not host.game.decoration_by_key("dekor_999").is_empty(),"Owned decorations must be retained")
 assert(f.object_position("pasar").distance_to(f.plot_center(0))<1100)
 assert(f.object_position("gudang").distance_to(f.plot_center(0))<1500)
 var truck=f.object_position("delivery_truck");assert(absf(truck.x-M.road(truck.y))<300)
 var remote=Vector2(M.bank(4400)+300,4400);assert(not f.can_place("gudang",remote),"Editor must reject a warehouse on the tree bank")
 host.game.level=1;host.game.xp=70;host.game.ftue.step="sale";host.game.ftue.started=true;host.game.inventory.gandum=3
 host.game.visitor_request={"name":"Bu Sari","item":"gandum","quantity":3,"coins":50,"xp":30,"first_farm":true};host.refresh_all();await settle()
 f.frame_asset("pasar",true);await settle()
 var art=preload("res://scripts/asset_projection.gd").info(f,"pasar",f.object_position("pasar"))
 var screen=(f.get_virtual_size()*.5+(art.bounds.get_center()-f.camera_center)*f.camera_zoom)*f.size/f.get_virtual_size()
 await click_at(screen);await settle();assert(host.active_tab=="pengunjung","A real market tap at Level 1 must open the first sale")
 host.switch_tab("kebun");await settle();await click(host.find_child("SeedPickerShortcut",true,false));await settle();assert(host.active_tab=="pengunjung","Jual Gandum footer must open sale immediately")
 host.switch_tab("kebun");await settle();await click(host.find_child("FirstSaleShortcut",true,false));await settle();assert(host.active_tab=="pengunjung","Tamu sale shortcut must open sale immediately")
 var old=host.game.coins;await click(host.find_child("SellVisitorGoods",true,false));await settle()
 assert(host.game.inventory.gandum==0 and host.game.coins==old+50 and host.game.ftue.step=="reward","First sale must work through the real sell button")
 preload("res://scripts/first_farm.gd").claim(host.game);host.game.level=2;host.game.inventory.gandum=6;host.game.market_listings.clear();host.switch_tab("pasar");await settle()
 assert(host.active_tab=="pasar","Regular market must open before truck orders unlock")
 var sell_three=host.find_child("MarketSellThree_gandum",true,false);host.sheet_scroll.ensure_control_visible(sell_three);await settle()
 await click(sell_three);await settle()
 assert(host.game.market_listings.size()==1 and host.game.inventory.gandum==3,"Regular sell button must work at Level 2")
 old=host.game.coins;var price=int(host.game.item_info("gandum").sell)*6;host.game.settle_market_sales(host.game.now()+1000)
 assert(host.game.coins==old+price and host.game.market_listings.is_empty())
 host.switch_tab("kebun");f.camera_center=Vector2(1600,4150);f.camera_target=f.camera_center;f.camera_zoom=.42;f.zoom_target=.42;host.toast_layer.hide();await settle()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/pasar-gudang-truk-dekat-kebun.png"))
 print("MAINLAND MARKET PASS: progress preserved, all non-tree assets on home bank, nearby market/warehouse, road-side truck, actual Level 1 and Level 2 sale buttons")
 host.queue_free();await process_frame;quit()
