extends SceneTree
const ICONS=preload("res://scripts/colorful_icons.gd")
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func run():
	for id in ["kebun","pesanan","toko","produksi","gudang","misi","karakter","bibit","air","pupuk","panen","hewan","bangun","upgrade","cuaca","koin","permata","batu","kayu","paku","palu","susu","telur","wol","daging","apel","jeruk","semi","panas","gugur","dingin","kacamata","syal"]:
		var icon=ICONS.texture(id)
		check(icon!=null and icon.get_width()>0,"load colorful SVG "+id)
	check(ICONS.for_caption("AKTIVITAS")=="misi","activity matcher avoids bag substring")
	check(ICONS.for_caption("Mata")=="kacamata" and ICONS.for_caption("Tas")=="tas","wardrobe slots map correctly")
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://colorful_icons_test.json"
	host.game.backup_path="user://colorful_icons_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	await process_frame
	for node in host.navbar.get_children():
		if not node.has_meta("tab_id"): continue
		check(not node.get_node("IconBg/Symbol").visible and node.get_node("IconBg/ColorfulIcon_"+str(node.get_meta("tab_id"))).texture!=null,"navigation uses pictures "+str(node.get_meta("tab_id")))
	var nav_icon=host.navbar.get_children()[1].get_node_or_null("IconBg/ColorfulIcon_kebun")
	if nav_icon==null:
		for tile in host.navbar.get_children():
			if tile.has_meta("tab_id") and tile.get_meta("tab_id")=="kebun": nav_icon=tile.get_node("IconBg/ColorfulIcon_kebun")
	check(nav_icon!=null and nav_icon.size.x<=54 and nav_icon.size.y<=54,"navigation icon stays within its tile")
	check(host.mission_header_button.icon!=null,"mission shortcut has image icon")
	check(host.farm.hybrid_controller.ui.character_button.icon!=null,"character button has picture")
	for id in host.game.inventory: check(host.inventory_icon_texture(str(id))!=null,"inventory item picture "+str(id))
	for tab in ["gudang","produksi","pakan","pesanan","upgrade","ternak","bangun","toko"]:
		host.switch_tab(tab)
		await process_frame
		check(is_instance_valid(host.sheet),"icon page opens "+tab)
	check(host.game.coins==400 and host.game.storage_capacity==60,"icons do not mutate progress")
	host.queue_free()
	await process_frame
	print("COLORFUL ICON FAILURES: ",failures)
	quit(failures)
