extends SceneTree
const PACKS=preload("res://scripts/seasonal_character_packs.gd")
func _initialize(): call_deferred("run")
func run():
	var main=load("res://scenes/Main.tscn").instantiate()
	main.game.save_path="user://seasonal_pack_test.json"
	main.game.backup_path="user://seasonal_pack_test_backup.json"
	DirAccess.remove_absolute(main.game.save_path)
	DirAccess.remove_absolute(main.game.backup_path)
	root.add_child(main)
	await process_frame
	var game=main.game
	assert(PACKS.equipped(game.seasonal)==0)
	game.coins=500
	var seasonal=main.get_children().filter(func(c): return c.get_script()==load("res://scripts/seasonal_ui.gd"))[0]
	var editor=seasonal.wardrobe_editor
	editor.open()
	editor.select_gender("female")
	editor.purchase("pack",2)
	assert(game.coins==385 and PACKS.equipped(game.seasonal)==2)
	editor.purchase("pack",2)
	assert(game.coins==385,"One purchase covers front and back, equip is free")
	editor.select_view(4)
	assert(PACKS.equipped(game.seasonal)==2)
	editor.select_gender("male")
	assert(PACKS.equipped(game.seasonal)==0,"Gender packs are independent")
	editor.select_gender("female")
	assert(PACKS.equipped(game.seasonal)==2)
	game.coins=0
	editor.purchase("pack",3)
	assert(PACKS.equipped(game.seasonal)==2)
	var copy=FarmGameState.new()
	copy.save_path=game.save_path
	copy.backup_path=game.backup_path
	assert(copy.load_game() and PACKS.equipped(copy.seasonal)==2)
	editor.reset_outfit()
	assert(PACKS.equipped(game.seasonal)==-1)
	editor.purchase("pack",2)
	assert(PACKS.equipped(game.seasonal)==2 and game.coins==0)
	for gender in ["male","female"]:
		for season in 4:
			for back in [false,true]:
				var tex=PACKS.texture(gender,season,back)
				assert(tex!=null and tex.get_height()>200)
	for gender in ["female","male"]:
		for season in 4:
			var hashes={}
			for sector in 5:
				var tex=PACKS.directional_texture(gender,season,sector)
				assert(tex!=null and tex.get_height()>200)
				hashes[tex.get_image().get_data().hex_encode().sha256_text()]=true
			assert(hashes.size()==5,"Each seasonal pack uses five distinct supplied directions")
	var old=FarmGameState.new(false)
	old.coins=100
	old.seasonal.erase("seasonal_pack_version")
	old.seasonal.owned=["wardrobe_v6_3","wardrobe_v6_3","wardrobe_v6_10","wardrobe_v6_0","outfit3"]
	assert(PACKS.prepare(old) and old.coins==175)
	assert(not PACKS.prepare(old) and old.coins==175)
	assert("outfit3" in old.seasonal.owned and old.seasonal.wardrobe_slots.is_empty())
	main.queue_free()
	await process_frame
	print("SEASONAL PACK PASS: 16 whole figures; paired buy/equip; gender; duplicate; insufficient coins; removal; save/load; one-time legacy refund")
	quit()
