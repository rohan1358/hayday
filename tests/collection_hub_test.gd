extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://collection_hub_test.json";host.game.backup_path="user://collection_hub_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 var g=host.game;g.ftue.started=true;g.ftue.step="done";g.level=6;g.coins=1001;g.diamonds=22
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 host.set_meta("first_farm_modal",false);host.refresh_all();host.switch_tab("koleksi")
 assert(host.sheet.find_children("CollectionCard*","Panel",true,false).size()==3)
 for label in host.sheet.find_children("*","Label",true,false): assert(not label.text.contains("Gudang"),"No warehouse card in collection")
 if DisplayServer.get_name()!="headless":
  for i in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/koleksi-tiga-menu.png"))
 host.sheet.find_child("CollectionCharacter",true,false).pressed.emit()
 assert(host.active_tab=="kebun")
 var editor=host.find_children("*","PanelContainer",true,false).filter(func(n): return n.get_script()!=null and n.get_script().resource_path=="res://scripts/wardrobe_editor.gd")[0]
 assert(editor.visible);editor.hide()
 var key=g.buy_decoration("flower_patch");assert(not key.is_empty())
 host.switch_tab("koleksi")
 host.sheet.find_child("CollectionDecorations",true,false).pressed.emit()
 assert(host.active_tab=="aset")
 var place: Button
 for button in host.sheet.find_children("*","Button",true,false):
  if button.text=="PASANG": place=button;break
 assert(place!=null);place.pressed.emit()
 assert(host.active_tab=="kebun" and host.farm.placement_decoration_key==key)
 host.farm.cancel_decoration_placement()
 host.switch_tab("koleksi")
 host.sheet.find_child("CollectionAchievements",true,false).pressed.emit()
 assert(host.active_tab=="prestasi" and host.sheet!=null)
 var claims=0
 for button in host.sheet.find_children("*","Button",true,false):
  if button.text in ["BELUM SIAP","KLAIM","TUNTAS"]: claims+=1
 assert(claims==g.ACHIEVEMENT_ORDER.size())
 host.switch_tab("gudang");assert(host.active_tab=="gudang")
 print("COLLECTION HUB PASS: three cards, no warehouse card, character editor, stored decoration placement, achievements, existing warehouse retained")
 host.queue_free();await process_frame;quit()
