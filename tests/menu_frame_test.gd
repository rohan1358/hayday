extends SceneTree
const FRAME=preload("res://scripts/menu_frame.gd")
const TYPE=preload("res://scripts/typography.gd")
func _initialize(): call_deferred("run")
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://menu_frame_test.json";host.game.backup_path="user://menu_frame_test_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=6
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 for page in FRAME.TITLES:
  host.switch_tab(page)
  for i in 4: await process_frame
  var frame=host.sheet.find_child("GardenMenuFrame",true,false)
  var title=host.sheet.find_child("MenuTitle",true,false)
  var icon=host.sheet.find_child("MenuTitleIcon",true,false)
  var close=host.sheet.find_child("MenuClose",true,false)
  assert(frame!=null and title!=null and close!=null)
  assert(title.text==FRAME.TITLES[page] and title.get_theme_font("font")==TYPE.TITLE)
  assert(title.get_theme_constant("outline_size")==5)
  if page!="koleksi": assert(icon!=null and icon.texture!=null)
  assert(title.get_line_count()<=title.get_visible_line_count(),"Title must fit: "+page)
  close.pressed.emit();assert(host.active_tab=="kebun")
  print("PASS: frame/title/icon/close ",page)
 print("MENU FRAME PASS: ",FRAME.TITLES.size()," menus")
 host.queue_free();await process_frame;quit()
