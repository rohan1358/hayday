extends SceneTree
const JOBS=preload("res://scripts/industry_jobs.gd")
func _initialize():call_deferred("run")
func settle():
 for i in 8:await process_frame
func click(control):
 var p=control.get_global_rect().get_center()
 var motion=InputEventMouseMotion.new();motion.position=p;Input.parse_input_event(motion)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=p;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func shot(name):
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+name+".png"))
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://industry_panel_test.json";host.game.backup_path="user://industry_panel_backup.json"
 DirAccess.copy_absolute(ProjectSettings.globalize_path("user://visible_districts.json"),ProjectSettings.globalize_path(host.game.save_path));root.add_child(host)
 host.game.ftue.step="done";host.game.level=50;host.farm.hybrid_controller.set_process(false)
 for c in host.get_children():
  if c.get_script()==load("res://scripts/first_farm_ui.gd"):c.start_adventure()
  if c.get_script()==load("res://scripts/farm_progression.gd"):c.set_process(false)
 JOBS.jobs(host.game).clear()
 for crop in JOBS.RECIPES:host.game.inventory[crop]=4
 host.on_world_region_pressed("penggilingan");await settle()
 var panel=host.get_node("IndustryPanel");assert(panel.kind=="penggilingan");await shot("popup-penggilingan-baru")
 for crop in JOBS.RECIPES:
  var old=int(host.game.inventory[crop]);var output=JOBS.RECIPES[crop].output;var before=int(host.game.inventory.get(output,0))
  await click(panel.find_child("MillProduce_"+crop,true,false));await settle()
  assert(host.game.inventory[crop]==old-2 and JOBS.jobs(host.game).has("penggilingan"),"Actual production button must start one batch")
  assert(JOBS.remaining(host.game,"penggilingan")>0 and panel.claim_button.disabled)
  JOBS.claim(host.game,"penggilingan");assert(host.game.inventory.get(output,0)==before,"No early production reward")
  JOBS.jobs(host.game).penggilingan.ready_at=host.game.now()-1;panel.update_state();await click(panel.claim_button);await settle()
  assert(host.game.inventory[output]==before+1)
  JOBS.claim(host.game,"penggilingan");assert(host.game.inventory[output]==before+1,"Duplicate collection must not duplicate output")
 panel.close();await settle();host.on_world_region_pressed("tambang");await settle();panel=host.get_node("IndustryPanel")
 var materials=preload("res://scripts/building_upgrades.gd").prepare(host.game).materials;var stone=int(materials.batu);var hammer=int(materials.palu)
 await click(panel.find_child("StartMining",true,false));await settle();assert(JOBS.remaining(host.game,"tambang")>0)
 await shot("tambang-animasi-dan-waktu")
 var old=JOBS.jobs(host.game).tambang.ready_at;panel.close();await settle();host.game.save_game()
 var restored=FarmGameState.new(false);restored.save_path=host.game.save_path;restored.backup_path=host.game.backup_path;assert(restored.load_game());assert(JOBS.jobs(restored).tambang.ready_at==old)
 host.open_industry("tambang");await settle();panel=host.get_node("IndustryPanel");assert(materials.batu==stone and materials.palu==hammer)
 JOBS.jobs(host.game).tambang.ready_at=host.game.now()-1;await settle();await shot("tambang-hasil-batu-palu")
 await click(panel.claim_button);await settle();assert(materials.batu==stone+2 and materials.palu==hammer+1)
 JOBS.claim(host.game,"tambang");assert(materials.batu==stone+2 and materials.palu==hammer+1)
 panel.close();await settle();assert(not bool(host.get_meta("first_farm_modal",true)))
 print("INDUSTRY PASS: actual mill/mine opening and buttons, four timed recipes, mining countdown, persistent job, early/duplicate claims blocked, materials and modal restoration")
 host.queue_free();await process_frame;quit()
