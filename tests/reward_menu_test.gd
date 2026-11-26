extends SceneTree
const J=preload("res://scripts/level_journey.gd")
var host
func _initialize(): call_deferred("run")
func screenshot(id):
 for toast in host.toast_layer.get_children(): toast.hide()
 for i in 4: await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+id+".png"))
func run():
 host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://reward_menu_test.json";host.game.backup_path="user://reward_menu_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var g=host.game;g.ftue.started=true;g.ftue.step="done";g.level=6;g.xp=0
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 J.prepare(g)
 host.refresh_all();host.switch_tab("hadiah_pemula")
 assert(host.sheet.find_child("MenuTitle",true,false).text=="Hadiah")
 assert(host.get_meta("reward_selected")==6)
 assert(host.sheet.find_child("ClaimLevelReward",true,false).disabled)
 for objective in J.goals(6):
  g.achievement_progress[objective.counter]=int(g.level_journey.entries["6"].baseline.get(objective.counter,0))+int(objective.goal)
 preload("res://scripts/reward_menu.gd").refresh(host)
 var claim=host.sheet.find_child("ClaimLevelReward",true,false)
 assert(not claim.disabled)
 await screenshot("hadiah-level-6")
 var coins=g.coins;var reward=J.reward(6)
 claim.pressed.emit();assert(g.coins==coins+reward.coins and g.level_journey.entries["6"].claimed)
 claim.pressed.emit();assert(g.coins==coins+reward.coins)
 g.save_game();var copy=FarmGameState.new(false);copy.save_path=g.save_path;copy.backup_path=g.backup_path
 assert(copy.load_game() and copy.level_journey.entries["6"].claimed and not J.claim(copy,6))
 g.award_xp(g.xp_target()-g.xp);host.refresh_all()
 assert(g.level==7 and host.get_meta("reward_selected")==7)
 assert(J.reward(7)!=reward and not J.status(g,7).ready)
 await screenshot("hadiah-level-7")
 var picker=host.sheet.find_child("RewardLevelPicker",true,false)
 var index=picker.get_item_index(6);picker.select(index);picker.item_selected.emit(index)
 assert(host.get_meta("reward_selected")==6 and host.sheet.find_child("ClaimLevelReward",true,false).disabled)
 g.ftue.step="reward";g.ftue.planted=[0,1,2];g.ftue.harvested=[0,1,2];g.ftue.sale_done=true;g.ftue.reward_claimed=false;g.level=2;g.coins=50;g.seeds.gandum=0
 host.refresh_all()
 claim=host.sheet.find_child("ClaimLevelReward",true,false)
 assert(not claim.disabled)
 claim.pressed.emit();assert(g.seeds.gandum==3 and g.coins==50 and g.ftue.reward_claimed)
 claim.pressed.emit();assert(g.seeds.gandum==3 and g.coins==50)
 print("REWARD MENU PASS: title, live progress, per-level rewards, level-up switch, old levels, claim once, reload protection, tutorial without double payment")
 host.queue_free();await process_frame;quit()
