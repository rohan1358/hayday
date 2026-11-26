extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://ranch_presentation_test.json";host.game.backup_path="user://ranch_presentation_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var game=host.game
 game.ftue.started=true;game.ftue.step="done";game.level=3;game.coins=10000
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 host.set_meta("first_farm_modal",false)
 assert(preload("res://scripts/first_coop.gd").build(game))
 game.inventory.gandum=20
 host.switch_tab("ayam")
 var controls=host.get_meta("first_coop_controls")
 assert(not controls.craft.disabled)
 controls.craft.pressed.emit()
 assert(game.feed_queue.size()==1)
 game.feed_queue[0].ready_at=game.now()-1
 preload("res://scripts/first_coop.gd").refresh(host)
 controls=host.get_meta("first_coop_controls")
 assert(not controls.collect.disabled)
 controls.collect.pressed.emit()
 controls=host.get_meta("first_coop_controls")
 assert(not controls.feed.disabled)
 assert(host.get_meta("ranch_heroes")[0].card.get_node("RanchProgress").value==2)
 if DisplayServer.get_name()!="headless":
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/peternakan-baru-ayam.png"))
 controls.feed.pressed.emit()
 assert(game.eggs_ready_at>game.now())
 game.eggs_ready_at=game.now()-1
 preload("res://scripts/first_coop.gd").refresh(host)
 controls=host.get_meta("first_coop_controls")
 assert(not controls.eggs.disabled)
 controls.eggs.pressed.emit()
 assert(game.inventory.telur>0)
 host.switch_tab("sapi")
 assert(host.get_meta("ranch_heroes").size()==1)
 host.switch_tab("ternak")
 assert(host.get_meta("ranch_heroes").size()==4)
 for entry in host.get_meta("ranch_heroes"):
  assert(entry.card.get_node("RanchProgress").value>=0)
 if DisplayServer.get_name()!="headless":
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/peternakan-baru-semua.png"))
 host.switch_tab("pakan")
 assert(host.sheet!=null)
 print("PASS: four species, native crafting/collect/feed/eggs, live progress, cow and feed pages")
 host.queue_free();await process_frame;quit()
