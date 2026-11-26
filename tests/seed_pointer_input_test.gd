extends SceneTree
func _initialize(): call_deferred("run")
func click(control):
 var point=control.get_global_rect().get_center()
 var move=InputEventMouseMotion.new();move.position=point;root.push_input(move,true)
 await process_frame
 var hovered=root.gui_get_hovered_control()
 assert(hovered==control,"Pointer blocked by "+str(hovered)+" instead of "+str(control))
 var down=InputEventMouseButton.new();down.position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;root.push_input(down,true)
 var up=InputEventMouseButton.new();up.position=point;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;root.push_input(up,true)
 for i in 4: await process_frame
func touch(control):
 var point=control.get_global_rect().get_center()
 var down=InputEventScreenTouch.new();down.index=0;down.position=point;down.pressed=true;root.push_input(down,true)
 var up=InputEventScreenTouch.new();up.index=0;up.position=point;up.pressed=false;root.push_input(up,true)
 for i in 4: await process_frame
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://seed_pointer_test.json";host.game.backup_path="user://seed_pointer_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="plant";host.game.level=1
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 var system=host.farm.hybrid_controller;system.set_process(false);system.cancel_all("")
 var ui=system.ui;ui.open_seed_picker(0)
 for i in 8: await process_frame
 await click(ui.menu.find_child("SeedChoice_gandum",true,false))
 assert(ui.first_seed_selected)
 await click(ui.menu.find_child("ConfirmSeedPlant",true,false))
 assert(not ui.menu.visible and system.data.jobs.size()==1)
 assert(system.actions.execute(system.data.jobs[0]).ok)
 assert(host.game.plots[0].crop=="gandum" and host.game.seeds.gandum==2)
 system.cancel_all("")
 ui.open_seed_picker(1)
 for i in 8: await process_frame
 await touch(ui.menu.find_child("SeedChoice_gandum",true,false))
 await touch(ui.menu.find_child("ConfirmSeedPlant",true,false))
 assert(not ui.menu.visible and system.data.jobs.size()==1,"Touch must activate Plant")
 assert(system.actions.execute(system.data.jobs[0]).ok)
 assert(host.game.plots[1].crop=="gandum" and host.game.seeds.gandum==1)
 print("POINTER INPUT PASS: actual viewport pointer hits wheat and plant, queues and plants wheat")
 host.queue_free();await process_frame;quit()
