extends SceneTree
const J=preload("res://scripts/level_journey.gd")
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new()
	game.save_path="user://level_notification_test.json";game.backup_path="user://level_notification_backup.json"
	game.ftue.started=true;game.ftue.step="done"
	for level in range(2,102):
		game.level=level;J.reached(game,level);J.reached(game,level)
		assert(game.level_journey.queue.count(level)==1)
		assert(not J.unlocks(game,level).is_empty())
		assert(not J.goals(level).is_empty() and J.reward(level).coins>0)
		assert(not J.claim(game,level),"Unfinished tasks cannot grant rewards")
	assert(game.level_journey.queue.size()==100)
	game.achievement_progress.panen=100000
	game.achievement_progress.pengiriman=100000
	game.achievement_progress.produksi=100000
	var coins=game.coins
	assert(J.claim(game,20))
	assert(game.coins==coins+J.reward(20).coins)
	assert(not J.claim(game,20),"A mission reward is granted once")
	var copy=FarmGameState.new();copy.save_path=game.save_path;copy.backup_path=game.backup_path
	assert(copy.load_game() and not J.claim(copy,20))
	assert(not J.claim(copy,copy.level+1))
	print("LEVEL NOTIFICATION PASS: 100 levels, true unlock metadata, queued notifications without duplicates, gated rewards and save/load claim protection")
	if "--visual" in OS.get_cmdline_user_args():
		root.size=Vector2i(720,1280)
		var host=load("res://scenes/Main.tscn").instantiate()
		host.game.save_path="user://level_popup_visual.json";host.game.backup_path="user://level_popup_visual_backup.json"
		root.add_child(host)
		host.game.ftue.started=true;host.game.ftue.step="done"
		var guide=preload("res://scripts/cheerful_menus.gd").guide(host)
		if guide!=null: guide.hide()
		for node in host.get_children():
			if node.get_script()==load("res://scripts/farm_progression.gd"): node.set_process(false)
		host.toast_layer.hide();host.farm.reset_camera()
		for level in [2,5,20,101]:
			var popup=load("res://scripts/level_up_popup.gd").new();popup.host=host;popup.reached_level=level
			host.add_child(popup)
			await create_timer(0.7).timeout
			assert(popup.get_node(".").find_child("DynamicLevelNumber",true,false).text==str(level))
			assert(popup.find_child("LevelMissionReward",true,false).text.contains(str(J.reward(level).coins)))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/outputs/notif-naik-level-%d.png"%level)
			popup.finish(false);await process_frame
		host.queue_free();await process_frame
	quit()
