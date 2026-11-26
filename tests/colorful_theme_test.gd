extends SceneTree
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func run():
	var art=FarmArt.new()
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/colorful_garden/manifest.json"))
	check(manifest.assets.size()>=46,"complete colorful environment asset set available")
	for entry in manifest.assets:
		check(art.sprites.has(str(entry.id)),"sprite registered "+str(entry.id))
		var texture: Texture2D=art.sprites[str(entry.id)].texture
		check(maxi(texture.get_width(),texture.get_height())<=768,"Android texture bound "+str(entry.id))
		if str(entry.id)!="grass_meadow": check(texture.get_image().get_pixel(0,0).a<0.1,"transparent background "+str(entry.id))
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://colorful_theme_test.json"
	host.game.backup_path="user://colorful_theme_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	await process_frame
	check(host.game.coins==400 and host.game.storage_capacity==60,"theme preserves economy and storage")
	check(host.farm.material is ShaderMaterial,"farm render receives shared grade")
	check(host.farm.mobile_ujang_layer.material==host.farm.material,"character and accessory render share grade")
	check(host.farm.mobile_building_layer.material==host.farm.material,"buildings share same inexpensive material")
	for animal in host.farm.ranch_animator.agents.values(): check(animal.node.material==host.farm.material,"live animal receives matching grade")
	var original=host.game.seasonal.duplicate(true)
	for tab in ["toko","produksi","gudang","misi","upgrade","ternak","bangun","pesanan"]:
		host.switch_tab(tab)
		await process_frame
		check(is_instance_valid(host.sheet),"styled feature page opens "+tab)
	check(host.game.seasonal==original,"style never resets character or equipped accessories")
	var colors=[]
	for node in host.navbar.get_children():
		if node.has_meta("tab_id"): colors.append(node.get_node("IconBg/Symbol").get_theme_color("font_color").to_html())
	var distinct={}
	for color in colors: distinct[color]=true
	check(distinct.size()==5,"five navigation categories have distinct accents")
	host.queue_free()
	await process_frame
	print("COLORFUL THEME FAILURES: ",failures)
	quit(failures)
