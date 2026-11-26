extends SceneTree
const UP=preload("res://scripts/building_upgrades.gd")
func _initialize():call_deferred("run")
func click(b):
 var point=b.get_global_transform_with_canvas()*(b.size*0.5)
 var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event)
  await process_frame
func settle():
 for i in 6: await process_frame
func screenshot(name):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+name+".png"))
func run():
 root.size=Vector2i(720,1600)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://bugfix_interactions.json";host.game.backup_path="user://bugfix_interactions_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 var start=Time.get_ticks_msec();root.add_child(host);print("FRESH START MS ",Time.get_ticks_msec()-start)
 var editor
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
  if child.get_script()==load("res://scripts/seasonal_ui.gd"):editor=child.wardrobe_editor
 assert(host.game.level==1 and host.game.has_construction("toko_roti") and host.game.has_construction("pabrik_susu"))
 host.switch_tab("roti");assert(host.active_tab=="roti")
 host.switch_tab("susu");assert(host.active_tab=="susu")
 host.game.ftue.step="done";host.game.level=7;host.game.coins=20000
 for id in host.game.inventory:host.game.inventory[id]=100
 host.game.storage_capacity=50000
 host.game.ftue.coop_built=true;host.game.ftue.cow_built=true
 for id in ["kandang_babi","kandang_kambing","pabrik_pakan"]:host.game.constructions[id]=1
 preload("res://scripts/ranch_state.gd").prepare(host.game)
 host.farm.hybrid_controller.animals.ensure_animals()
 for species in ["sapi","babi","kambing"]:
  host.switch_tab("kebun")
  var art=preload("res://scripts/asset_projection.gd").info(host.farm,species,host.farm.object_position(species))
  host.farm.hybrid_controller.tap_world(art.bounds.get_center())
  assert(host.active_tab==species,"Pen must open its own popup: "+species)
  await settle()
  await screenshot("fix-pen-"+species)
 editor.open()
 for i in 8:
  editor.select_gender("male" if i%2==0 else "female")
  editor.select_view(i%5);editor.filter_season(i%4)
  editor.scroll.scroll_vertical=10000
  await settle()
  var done=editor.find_child("WardrobeDone",true,false)
  assert(done.get_global_rect().end.y<root.size.y)
  await click(done)
  assert(not editor.visible,"Done must close editor after changes and scroll")
  editor.open()
 editor.close_editor()
 host.switch_tab("gudang");await create_timer(0.3).timeout
 await click(host.sheet.find_child("WarehouseUpgrade",true,false));await create_timer(0.3).timeout
 assert(host.active_tab=="upgrade","Warehouse upgrade actual click must open upgrade menu")
 # Start the warehouse mission by pointer, then satisfy its real gameplay counters and claim.
 var button=host.sheet.find_child("Upgrade_gudang",true,false)
 host.sheet_scroll.ensure_control_visible(button);await settle();await click(button);await settle()
 assert(UP.prepare(host.game).missions.has("gudang"),"Pointer must start warehouse mission")
 var spec=UP.spec(host.game,"gudang")
 for id in spec.materials:UP.prepare(host.game).materials[id]=spec.materials[id]
 for id in spec.tasks:host.game.achievement_progress[id]=int(host.game.achievement_progress.get(id,0))+int(spec.tasks[id])
 host.switch_tab("upgrade");await create_timer(0.3).timeout
 button=host.sheet.find_child("Upgrade_gudang",true,false);host.sheet_scroll.ensure_control_visible(button);await settle()
 var old=host.game.storage_capacity;await click(button);await settle()
 assert(UP.tier(host.game,"gudang")==2 and host.game.storage_capacity==old+30,"Claim must deduct materials and add storage")
 for station in ["roti","susu"]:
  host.game.level=1
  assert(UP.start(host.game,station))
  spec=UP.spec(host.game,station)
  for id in spec.materials:UP.prepare(host.game).materials[id]=spec.materials[id]
  for id in spec.tasks:host.game.achievement_progress[id]=int(host.game.achievement_progress.get(id,0))+int(spec.tasks[id])
  assert(UP.claim(host.game,station))
 assert(host.game.can_queue_product("roti") and host.game.can_queue_product("keju"))
 host.game.level=7;host.switch_tab("rumah");await settle();await screenshot("fix-house-menu")
 host.switch_tab("kebun")
 preload("res://scripts/safe_asset_placement.gd").repair_nature(host)
 var signature=str(host.game.building_upgrades.nature_signature)
 start=Time.get_ticks_msec();preload("res://scripts/safe_asset_placement.gd").repair_nature(host)
 print("CACHED NATURE MS ",Time.get_ticks_msec()-start)
 assert(str(host.game.building_upgrades.nature_signature)==signature)
 for level in [2,7,20,50]:
  var popup=load("res://scripts/level_up_popup.gd").new();popup.host=host;popup.reached_level=level;host.add_child(popup)
  await create_timer(0.6).timeout;await screenshot("fix-level-"+str(level));popup.finish(false);await process_frame
 print("BUGFIX INTERACTIONS PASS: species popups, persistent Done, warehouse start/claim by real clicks, starter workshops and tier benefits")
 host.queue_free();await process_frame;quit()

