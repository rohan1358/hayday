extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://truck_order_test.json"
 host.game.backup_path="user://truck_order_test_backup.json"
 DirAccess.remove_absolute(host.game.save_path)
 DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var game=host.game
 game.ftue.started=true;game.ftue.step="done";game.level=3
 var farm=host.farm
 assert(farm.editable_keys().has("delivery_truck"))
 assert(farm.editable_keys().has("delivery_depot"))
 var parked=farm.object_position("delivery_truck")
 assert(farm.editable_at(parked)=="delivery_truck")
 game.orders[0].merge({"items":{"gandum":3},"coins":50,"xp":1},true)
 game.inventory.gandum=6
 host.switch_tab("pesanan")
 var kirim: Button
 for node in host.sheet.find_children("*","Button",true,false):
  if node.text=="KIRIM" and not node.disabled: kirim=node;break
 assert(kirim!=null)
 var coins=game.coins
 var deliveries=game.deliveries
 kirim.pressed.emit()
 assert(host.active_tab=="kebun")
 assert(farm.delivery_elapsed==0.0)
 assert(game.inventory.gandum==3 and game.coins==coins+50 and game.deliveries==deliveries+1)
 farm.delivery_elapsed=1.2
 assert(farm.delivery_truck_position().distance_to(parked)>100)
 host.send_delivery(0)
 assert(game.coins==coins+50 and game.deliveries==deliveries+1)
 assert(farm.delivery_elapsed==1.2)
 farm.delivery_elapsed=6.49
 farm._process(0.02)
 assert(farm.delivery_elapsed<0 and farm.delivery_truck_position()==parked)
 game.orders[0].merge({"items":{"gandum":30},"coins":50,"xp":1},true)
 host.send_delivery(0)
 assert(farm.delivery_elapsed<0 and game.coins==coins+50)
 farm.camera_center=parked;farm.camera_target=parked
 farm.queue_redraw()
 await process_frame
 await process_frame
 if DisplayServer.get_name() != "headless":
  for node in host.find_children("*","",true,false):
   if node.name=="NewPlayerWelcome": node.hide()
   if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
    node.set_process(false)
    if is_instance_valid(node.dialog): node.dialog.hide()
  host.set_meta("first_farm_modal",false)
  farm.delivery_elapsed=0.35
  farm.set_process(false)
  farm.queue_redraw()
  for i in 4: await process_frame
  await RenderingServer.frame_post_draw
  get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/truk-pengiriman.png"))
 print("PASS: native Kirim, compact truck, movement, single reward, busy guard, return, invalid order")
 host.queue_free();await process_frame
 quit(0)
