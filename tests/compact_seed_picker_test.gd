extends SceneTree
const PICKER=preload("res://scripts/hybrid/seed_picker.gd")
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://compact_seed_picker.json";host.game.backup_path="user://compact_seed_picker_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var g=host.game;g.ftue.started=true;g.ftue.step="done";g.level=6;g.seeds.gandum=8;g.seeds.jagung=4
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 var system=host.farm.hybrid_controller;system.set_process(false);system.cancel_all("")
 var ui=system.ui
 for i in 3: g.plots[i].crop=""
 ui.open_seed_picker(0)
 for i in 4: await process_frame
 assert(ui.menu.size.y<=ui.size.y*0.65 and ui.menu.size.x<ui.size.x-20)
 assert(ui.menu.find_child("SeedChoice_stroberi_kristal",true,false).disabled)
 ui.menu.find_child("SeedChoice_gandum",true,false).pressed.emit()
 ui.menu.find_child("SeedQuantityPlus",true,false).pressed.emit()
 assert(ui.seed_quantity==2)
 if DisplayServer.get_name()!="headless":
  for i in 4: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/pilih-bibit-ringkas.png"))
 ui.menu.find_child("ConfirmSeedPlant",true,false).pressed.emit()
 assert(not ui.menu.visible and system.data.jobs.size()==2)
 assert(system.data.jobs[0].index==0 and system.data.jobs[1].index!=0)
 assert(g.seeds.gandum==8,"Seeds are consumed only when the actual job executes")
 for job in system.data.jobs.duplicate(): assert(system.actions.execute(job).ok)
 system.cancel_all("")
 assert(g.seeds.gandum==6 and g.plots[0].crop=="gandum")
 g.seeds.jagung=0
 ui.open_seed_picker(2);ui.select_seed("jagung")
 assert(ui.menu.find_child("ConfirmSeedPlant",true,false).disabled)
 var before=g.coins
 ui.menu.find_child("BuySeed_jagung",true,false).pressed.emit()
 assert(g.seeds.jagung==1 and g.coins==before-g.CROPS.jagung.seed_cost)
 ui.menu.find_child("CloseSeedPicker",true,false).pressed.emit();assert(not ui.menu.visible)
 ui.open_menu();assert(ui.menu.size.y>650)
 system.cancel_all("");g.ftue.step="plant";g.ftue.planted=[];g.level=1;g.seeds.gandum=3
 for i in 3: g.plots[i].crop=""
 ui.open_seed_picker(0)
 assert(ui.menu.find_children("SeedChoice_*","Button",true,false).size()==1)
 assert(ui.first_seed_selected and g.selected_crop=="gandum")
 assert(not ui.menu.find_child("ConfirmSeedPlant",true,false).disabled)
 # Plant works immediately without tapping the already selected wheat card.
 assert(not ui.menu.find_child("ConfirmSeedPlant",true,false).disabled)
 ui.menu.find_child("ConfirmSeedPlant",true,false).pressed.emit()
 assert(system.data.jobs.size()==1)
 assert(system.actions.execute(system.data.jobs[0]).ok and g.seeds.gandum==2)
 assert(g.ftue.planted.has(0))
 assert(not ui.get_node("SeedPickerDim").visible)
 print("COMPACT SEED PICKER PASS: compact bounds, crop selection, quantity, queued planting, stock, purchase, close and controls menu")
 host.queue_free();await process_frame;quit()
