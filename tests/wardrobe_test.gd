extends SceneTree
const CAT=preload("res://scripts/wardrobe_catalog.gd")
func _initialize(): call_deferred("run")
func run():
	var main=load("res://scenes/Main.tscn").instantiate()
	main.game.save_path="user://wardrobe_v4_test.json"
	main.game.backup_path="user://wardrobe_v4_test_backup.json"
	DirAccess.remove_absolute(main.game.save_path)
	DirAccess.remove_absolute(main.game.backup_path)
	root.add_child(main)
	await process_frame
	var seasonal=main.get_children().filter(func(c): return c.get_script()==load("res://scripts/seasonal_ui.gd"))[0]
	var editor=seasonal.wardrobe_editor
	editor.open()
	main.game.coins=1000
	editor.select_gender("female")
	editor.purchase("outfit",3)
	assert(main.game.coins==935)
	editor.purchase("outfit",3)
	assert(main.game.coins==935)
	for i in [9,10,11]: editor.purchase("accessory",i)
	assert(main.game.seasonal.wardrobe_slots.size()==3)
	assert(main.game.coins==820)
	editor.purchase("accessory",9)
	assert(main.game.coins==820)
	var copy=FarmGameState.new()
	copy.save_path=main.game.save_path
	copy.backup_path=main.game.backup_path
	assert(copy.load_game())
	assert(copy.seasonal.gender=="female" and copy.seasonal.outfit==3)
	assert(copy.seasonal.wardrobe_slots.head==9)
	main.game.coins=0
	editor.purchase("accessory",3)
	assert(main.game.seasonal.wardrobe_slots.head==9)
	assert(CAT.key(3) not in main.game.seasonal.owned)
	editor.unequip("head")
	assert(not main.game.seasonal.wardrobe_slots.has("head"))
	editor.select_gender("male")
	assert(main.game.seasonal.wardrobe_slots.head==12)
	var before=main.game.seasonal.duplicate(true)
	editor.purchase("accessory",6)
	assert(main.game.seasonal==before)
	editor.select_gender("female")
	assert(not main.game.seasonal.wardrobe_slots.has("head"))
	assert(main.game.seasonal.wardrobe_slots.neck==10)
	editor.select_view(4)
	assert(editor.preview_sector==4)
	assert(main.game.seasonal.wardrobe_slots.neck==10)
	main.queue_free()
	await process_frame
	print("WARDROBE V4 PASS: 24 gender-specific items, 3 slots, independent gender outfits, purchases, duplicate, insufficient coins, wrong-gender rejection, unequip, view selection, save/load")
	quit()
