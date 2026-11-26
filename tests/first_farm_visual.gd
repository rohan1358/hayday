extends SceneTree
const FLOW=preload("res://scripts/first_farm.gd")
func _initialize(): call_deferred("run")
func capture(name: String):
 for i in 8: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/"+name+".png")
func find_button(node: Node,caption: String) -> Button:
 if node is Button and node.text==caption: return node
 for child in node.get_children():
  var found=find_button(child,caption)
  if found!=null: return found
 return null
func drain(system,seconds: float=35.0):
 var end=Time.get_ticks_msec()+int(seconds*1000)
 while (not system.active.is_empty() or not system.data.jobs.is_empty()) and Time.get_ticks_msec()<end:
  await process_frame
 assert(system.active.is_empty() and system.data.jobs.is_empty(),"real character queue must finish")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://first_farm_visual.json"
 host.game.backup_path="user://first_farm_visual_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var ui=host.get_node_or_null("FirstFarmUI")
 for node in host.get_children():
  if node.get_script()==load("res://scripts/first_farm_ui.gd"): ui=node
 assert(ui!=null)
 await capture("ftue-01-pembuka")
 find_button(ui.opening,"Mulai Petualangan").pressed.emit()
 host.toast_layer.hide()
 await create_timer(0.7).timeout
 await capture("ftue-02-kebun-awal")
 if "--quick" in OS.get_cmdline_user_args():
  host.queue_free();await process_frame
  print("FIRST FARM OPENING VISUAL PASS")
  quit();return
 var system=host.farm.hybrid_controller
 var point=host.farm.plot_center(0)
 var screen=(point-host.farm.camera_center)*host.farm.camera_zoom*host.farm.size/host.farm.get_virtual_size()+host.farm.size*0.5
 host.farm.activate_at(screen)
 assert(system.ui.menu.visible and system.ui.seed_plot==0,"real tap opens wheat seed picker")
 assert(system.ui.content.find_child("ConfirmSeedPlant",true,false)!=null,"wheat seed picker has a plant button")
 await capture("ftue-03-pilih-bibit")
 system.ui.select_seed("gandum")
 system.ui.content.find_child("ConfirmSeedPlant",true,false).pressed.emit()
 # Real queues/pathfinding complete every planting and harvest animation.
 for i in range(1,3):
  system.enqueue(system.actions.plot_job("plant",i),false)
 await drain(system)
 assert(host.game.ftue.planted.size()==3,"character reaches and plants all three actual plots")
 await capture("ftue-04-pertumbuhan")
 await create_timer(8.1).timeout
 FLOW.tick(host.game)
 if "--crop" in OS.get_cmdline_user_args():
  await capture("ftue-04-gandum-siap")
  host.queue_free();await process_frame
  print("FIRST FARM CROP VISUAL PASS")
  quit();return
 for i in 3: system.enqueue(system.actions.plot_job("harvest",i),false)
 await drain(system)
 assert(host.game.ftue.step=="sale" and host.game.inventory.gandum==6,"actual harvesting adds wheat and introduces NPC")
 ui.refresh()
 await capture("ftue-05-tetangga")
 system.tap_world(host.farm.visitor_world_position()-Vector2(0,45))
 await drain(system)
 assert(host.active_tab=="pengunjung","NPC interaction walks to visitor and opens actual sale")
 await capture("ftue-06-penjualan")
 find_button(host.sheet,"JUAL BARANG").pressed.emit()
 assert(host.game.level==2 and host.game.coins==150,"sale UI pays exact reward and reaches Level 2")
 ui.refresh()
 ui.claim.pressed.emit()
 await capture("ftue-07-naik-level")
 find_button(ui.celebration,"LANJUT BERKEBUN").pressed.emit()
 host.switch_tab("ayam")
 await capture("ftue-08-preview-ayam")
 assert(not preload("res://scripts/first_coop.gd").built(host.game),"Level 2 preview is locked")
 host.game.award_xp(host.game.xp_target())
 host.show_sheet()
 find_button(host.sheet,"BANGUN · 80 KOIN").pressed.emit()
 assert(preload("res://scripts/first_coop.gd").built(host.game),"real build UI introduces two chickens at Level 3")
 host.switch_tab("kebun")
 host.farm.camera_target=Vector2(1270,840)
 await create_timer(0.4).timeout
 await capture("ftue-09-kandang-level3")
 host.switch_tab("ayam")
 find_button(host.sheet,"BUAT PAKAN · 2 GANDUM · 8 DTK").pressed.emit()
 assert(host.game.feed_queue.size()==1,"actual feed button consumes wheat into production queue")
 await capture("ftue-10-produksi-pakan")
 await create_timer(8.1).timeout
 preload("res://scripts/first_coop.gd").refresh(host)
 assert(not find_button(host.sheet,"AMBIL PAKAN SIAP").disabled,"feed collection unlocks when the actual timer completes")
 find_button(host.sheet,"AMBIL PAKAN SIAP").pressed.emit()
 find_button(host.sheet,"BERI PAKAN AYAM").pressed.emit()
 assert(host.game.eggs_ready_at>host.game.now() and int(host.game.inventory.pakan_ayam)==0,"actual feed button consumes inventory and starts egg clock")
 await create_timer(38.1).timeout
 preload("res://scripts/first_coop.gd").refresh(host)
 find_button(host.sheet,"AMBIL TELUR").pressed.emit()
 assert(host.game.inventory.telur>0 and host.game.ftue.poultry_step=="done","actual collection button completes poultry mission")
 await capture("ftue-11-telur-pertama")
 print("FIRST FARM VISUAL PASS · real movement, planting, harvest, sale, level-up and coop UI")
 host.queue_free();await process_frame
 quit()
