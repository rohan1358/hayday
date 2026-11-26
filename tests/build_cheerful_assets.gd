extends SceneTree
const SOURCE="C:/Users/nuych/.codex/generated_images/01a1bf53-c896-7233-94b4-fbeb9e4e453b/"
func _initialize():
 DirAccess.make_dir_recursive_absolute("res://assets/cheerful")
 var names=["kebun","pesanan","toko","gudang","koleksi","bibit","hadiah","koin","permata","surat","notifikasi","pengaturan","bangun","bunga","pohon","pindah"]
 var atlas=Image.load_from_file(SOURCE+"exec-3c334e1c-5da0-41b6-a049-8dfa824e799b.png")
 var side=Vector2i(atlas.get_width()/4,atlas.get_height()/4)
 for i in names.size():
  var icon=atlas.get_region(Rect2i(Vector2i(i%4,int(i/4))*side,side))
  var used=icon.get_used_rect()
  if used.has_area(): icon=icon.get_region(used)
  icon.resize(128,128,Image.INTERPOLATE_LANCZOS)
  icon.save_png("res://assets/cheerful/"+names[i]+".png")
 var logo=Image.load_from_file(SOURCE+"exec-644986d0-d6dd-403a-9d81-0eef6593a4f3.png")
 logo=logo.get_region(logo.get_used_rect())
 logo.resize(768,roundi(logo.get_height()*768.0/logo.get_width()),Image.INTERPOLATE_LANCZOS)
 logo.save_png("res://assets/cheerful/logo.png")
 var backdrop=Image.load_from_file(SOURCE+"exec-4fa739ab-e47f-46d3-bed1-5353287f0794.png")
 backdrop.resize(1280,640,Image.INTERPOLATE_LANCZOS)
 backdrop.save_png("res://assets/cheerful/countryside.png")
 var app=Image.load_from_file(SOURCE+"exec-5186c938-b37b-408a-9911-04b9b004f068.png")
 app.resize(512,512,Image.INTERPOLATE_LANCZOS)
 app.save_png("res://assets/cheerful/app_icon.png")
 var grass=Image.load_from_file(SOURCE+"exec-256d968c-8735-4ebb-992f-c14e83ea8f34.png")
 grass.resize(512,512,Image.INTERPOLATE_LANCZOS)
 grass.save_png("res://assets/cheerful/grass.png")
 print("CHEERFUL ASSETS BUILT")
 quit()
