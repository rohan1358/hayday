extends SceneTree
func _initialize(): call_deferred("run")
func shot(host,id):
 for i in 5: await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+id+".png"))
func run():
 var g=FarmGameState.new(false)
 g.save_path="user://leveled_daily.json";g.backup_path="user://leveled_daily_backup.json"
 g.new_game(false)
 g.level=1;g.ensure_daily_tasks("2000-01-01");g.ensure_daily_tasks()
 assert(g.daily_task_ids()==["panen"] and not g.claim_daily_task("pesanan"))
 var goal=int(g.daily_task_definition("panen").goal)
 g.level=2;g.ensure_daily_tasks()
 assert(g.daily_task_definition("panen").goal>goal)
 g.add_daily_progress("panen",1);var spec=g.daily_task_definition("panen")
 g.level=6;g.ensure_daily_tasks()
 assert(g.daily_task_ids().size()==3 and g.daily_task_definition("panen").goal==spec.goal and g.daily_progress.panen==1)
 var old_goal=int(g.daily_task_definition("panen").goal)
 g.save_game()
 var copy=FarmGameState.new(false);copy.save_path=g.save_path;copy.backup_path=g.backup_path
 assert(copy.load_game() and copy.daily_task_definition("panen").goal==old_goal and copy.daily_progress.panen==1)
 g.add_daily_progress("panen",999);var coins=g.coins
 assert(g.claim_daily_task("panen") and g.coins==coins+int(spec.coins))
 assert(not g.claim_daily_task("panen"))
 g.save_game();assert(copy.load_game() and not copy.claim_daily_task("panen"))
 g.ensure_daily_tasks("2000-01-01");g.ensure_daily_tasks()
 assert(g.daily_progress.panen==0 and not g.daily_claimed.panen and g.daily_task_definition("panen").goal>old_goal)
 # Legacy saves with started tasks retain their original goals and rewards.
 g.daily_specs.clear();g.daily_progress.panen=3;g.ensure_daily_tasks()
 assert(g.daily_task_definition("panen").goal==g.DAILY_TASKS.panen.goal)
 var legacy=FarmGameState.new(false)
 legacy.level=1;legacy.daily_specs.clear();legacy.daily_progress.produksi=1;legacy.ensure_daily_tasks()
 assert("produksi" in legacy.daily_task_ids() and legacy.daily_task_definition("produksi").goal==2)
 legacy.ensure_daily_tasks("2000-01-01");legacy.ensure_daily_tasks()
 assert("produksi" not in legacy.daily_task_ids())
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://missions_ui.json";host.game.backup_path="user://missions_ui_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=6
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 host.refresh_all();host.switch_tab("misi")
 assert(host.sheet.find_child("MenuTitle",true,false).text=="Misi")
 assert(host.sheet.find_children("MissionClaim_*","Button",true,false).size()==3)
 await shot(host,"misi-harian-baru")
 var caption=host.find_child("MissionTask",true,false).get_node("Caption")
 assert(caption.get_theme_font("font")==preload("res://scripts/typography.gd").BOLD and caption.get_theme_font_size("font_size")>=18)
 var needed=int(host.game.daily_task_definition("panen").goal)
 host.game.add_daily_progress("panen",needed)
 preload("res://scripts/missions_menu.gd").refresh(host)
 var claim=host.sheet.find_child("MissionClaim_panen",true,false)
 assert(not claim.disabled);claim.pressed.emit();assert(host.game.daily_claimed.panen)
 assert(str(host.get_meta("mission_clock").text).begins_with("Reset:"))
 for toast in host.toast_layer.get_children(): toast.hide()
 host.sheet.find_child("MissionsAchievementsTab",true,false).pressed.emit()
 assert(host.sheet.find_children("MissionClaim_*","Button",true,false).size()==host.game.ACHIEVEMENT_ORDER.size())
 await shot(host,"misi-prestasi-baru")
 print("LEVELED MISSIONS PASS: gates, scaling, in-progress preservation, reset, migration, save/load, single claim, daily/achievement tabs")
 host.queue_free();await process_frame;quit()
