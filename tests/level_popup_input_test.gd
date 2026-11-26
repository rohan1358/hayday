extends SceneTree
func _initialize(): call_deferred("run")
func click(button):
 var point=button.get_global_transform_with_canvas()* (button.size*0.5)
 var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://level_popup_input_test.json";host.game.backup_path="user://level_popup_input_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 var progression
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"): child.opening.hide()
  if child.get_script()==load("res://scripts/farm_progression.gd"): progression=child
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=4
 host.switch_tab("misi")
 progression.seen=3;host.game.level_journey.queue=[4]
 await create_timer(0.8).timeout
 assert(progression.dialog!=null)
 await click(progression.dialog.find_child("LevelUpMissions",true,false))
 await process_frame
 assert(progression.dialog==null,"Actual click on Lihat Misi must dismiss popup")
 assert(not bool(host.get_meta("first_farm_modal",true)))
 assert(host.active_tab=="misi")
 assert(not host.game.level_journey.queue.has(4))
 host.game.level_journey.queue=[5]
 await create_timer(0.8).timeout
 assert(progression.dialog!=null)
 await click(progression.dialog.find_child("LevelUpClose",true,false))
 await process_frame
 assert(progression.dialog==null,"Actual close click must dismiss popup")
 assert(not bool(host.get_meta("first_farm_modal",true)))
 print("LEVEL POPUP INPUT PASS: real mouse clicks dismiss both buttons and release modal")
 host.queue_free();await process_frame;quit()
