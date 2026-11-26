extends SceneTree
const TYPE=preload("res://scripts/typography.gd")
var issues=[]
var fonts={}
func _initialize(): call_deferred("run")
func inspect_node(node,page):
 if node is Control and node.is_visible_in_tree() and (node is Label or node is Button):
  var font=node.get_theme_font("font")
  var path=font.resource_path
  fonts[path]=int(fonts.get(path,0))+1
  if not path.begins_with("res://assets/fonts/"): issues.append({"page":page,"node":str(node.get_path()),"font":path})
 for child in node.get_children(): inspect_node(child,page)
func run():
 var ts=TextServerManager.get_primary_interface()
 for font in [TYPE.TITLE,TYPE.BOLD,TYPE.SEMIBOLD,TYPE.BODY]:
  print("FONT: ",font.resource_path," family=",font.get_font_name()," weight=",font.get_font_weight()," coordinates=",ts.font_get_variation_coordinates(font.get_rids()[0]))
 for font in [TYPE.TITLE,TYPE.BOLD,TYPE.SEMIBOLD,TYPE.BODY]:
  for code in [0x2713,0x25c6,0x25b6]: assert(font.has_char(code),"Bundled symbol fallback must cover UI glyphs")
 assert(float(ts.font_get_variation_coordinates(TYPE.BOLD.get_rids()[0]).get(2003265652,0))==700)
 assert(float(ts.font_get_variation_coordinates(TYPE.SEMIBOLD.get_rids()[0]).get(2003265652,0))==600)
 assert(float(ts.font_get_variation_coordinates(TYPE.BODY.get_rids()[0]).get(2003265652,0))==600)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://typography_test.json";host.game.backup_path="user://typography_test_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=6
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 for page in ["kebun","pesanan","toko","gudang","koleksi","ayam","sapi","ternak","produksi","pakan","upgrade","misi","pengaturan","jalan","bunga","pohon","rumput","gedung","dekorasi","aktivitas","pengunjung","pasar","kebun_buah"]:
  host.switch_tab(page)
  for i in 4: await process_frame
  inspect_node(host,page)
 var dynamic=Button.new();dynamic.text="Harga 123";host.add_child(dynamic)
 await process_frame;await process_frame
 assert(dynamic.get_theme_font("font")==TYPE.BOLD)
 var popup=preload("res://scripts/level_up_popup.gd").new();popup.host=host;host.add_child(popup)
 for i in 4: await process_frame
 inspect_node(popup,"level-up")
 FileAccess.open("res://../outputs/typography-font-audit.json",FileAccess.WRITE).store_string(JSON.stringify({"fonts":fonts,"issues":issues},"  "))
 assert(issues.is_empty(),"Every game control must use the bundled global font system")
 print("TYPOGRAPHY PASS: 23 pages, popup, dynamic controls; fonts ",fonts)
 host.queue_free();await process_frame;quit()
