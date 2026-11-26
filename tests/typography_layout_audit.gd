extends SceneTree
var problems=[]
var checked=0
func _initialize(): call_deferred("run")
func audit(node,page):
 if node is Label and node.is_visible_in_tree() and node.size.x>10 and not node.text.is_empty():
  checked+=1
  var font=node.get_theme_font("font");var size=node.get_theme_font_size("font_size")
  var width=float(node.get_meta("typography_extent",node.size).x)
  if node.autowrap_mode==TextServer.AUTOWRAP_OFF:
   var measured=0.0
   for line in node.text.split("\n"): measured=maxf(measured,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
   if measured>width+3: problems.append({"page":page,"path":str(node.get_path()),"text":node.text,"problem":"width","measured":measured,"extent":width})
  elif node.get_line_count()>node.get_visible_line_count():
   problems.append({"page":page,"path":str(node.get_path()),"text":node.text,"problem":"lines","lines":node.get_line_count(),"visible":node.get_visible_line_count(),"size":str(node.size)})
 if node is Button and node.is_visible_in_tree() and not node.text.is_empty() and node.size.x>10:
  checked+=1
  var font=node.get_theme_font("font");var size=node.get_theme_font_size("font_size")
  var box=node.get_theme_stylebox("normal")
  var width=node.size.x-maxf(12,box.get_minimum_size().x)
  var height=node.size.y-box.get_minimum_size().y
  if node.icon!=null and node.vertical_icon_alignment==VERTICAL_ALIGNMENT_CENTER: width-=node.get_theme_constant("icon_max_width")+node.get_theme_constant("h_separation")
  if node.autowrap_mode==TextServer.AUTOWRAP_OFF:
   var measured=0.0
   for line in node.text.split("\n"): measured=maxf(measured,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
   if measured>width+3: problems.append({"page":page,"path":str(node.get_path()),"text":node.text,"problem":"button_width","measured":measured,"extent":width,"size":str(node.size)})
  else:
   var text_size=font.get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_CENTER,width,size)
   if text_size.y>height+3: problems.append({"page":page,"path":str(node.get_path()),"text":node.text,"problem":"button_height","height":text_size.y,"extent":height,"size":str(node.size)})
 for child in node.get_children(): audit(child,page)
func run():
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://typography_layout.json";host.game.backup_path="user://typography_layout_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=6;host.game.coins=1000000
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 if "--english" in OS.get_cmdline_user_args(): root.get_node("GardenLanguage").set_language("en")
 else: root.get_node("GardenLanguage").set_language("id")
 host.refresh_all()
 for page in ["pesan","kebun","pesanan","toko","gudang","koleksi","ayam","sapi","ternak","produksi","pakan","upgrade","misi","pengaturan","jalan","bunga","pohon","rumput","gedung","dekorasi","aktivitas","pengunjung","pasar","kebun_buah"]:
  host.switch_tab(page)
  for i in 6: await process_frame
  audit(host,page)
 for category in 8:
  host.set_meta("settings_category",category);host.switch_tab("pengaturan")
  for i in 6: await process_frame
  audit(host,"settings_"+str(category))
 host.switch_tab("kebun")
 var popup=preload("res://scripts/level_up_popup.gd").new();popup.host=host;popup.reached_level=5;host.add_child(popup)
 await create_timer(0.6).timeout
 audit(popup,"level-up");popup.queue_free();await process_frame
 for node in host.find_children("*","",true,false):
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/wardrobe_editor.gd":
   node.open()
   for i in 6: await process_frame
   audit(node,"wardrobe");node.hide();break
 host.show_toast("Truk sedang mengirim pesanan. Tunggu sampai kembali ke kebun sebelum mengirim pesanan berikutnya.")
 for i in 6: await process_frame
 audit(host.toast_layer,"toast")
 var report={"checked":checked,"problems":problems}
 FileAccess.open("res://../outputs/typography-layout-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("LAYOUT AUDIT checked=",checked," issues=",problems.size())
 root.get_node("GardenLanguage").set_language("id")
 host.queue_free();await process_frame;quit()
