extends SceneTree
const SPEED=preload("res://scripts/rewarded_speedups.gd")
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new(false)
	game.save_path="user://rewarded_speed_test.json"
	game.backup_path="user://rewarded_speed_backup.json"
	game.plots[0].crop=""
	check(game.plant(0,"gandum"),"plant target")
	game.plots[0].ready_at=game.now()+1000
	var speed=SPEED.new()
	var id=speed.start(game,0)
	var gems=game.diamonds
	check(not id.is_empty() and speed.start(game,0).is_empty(),"one request at a time")
	check(not game.is_ready(0),"request alone never speeds up crop")
	check(not speed.complete(game,"wrong") and not game.is_ready(0),"wrong request cannot claim")
	check(speed.complete(game,id) and game.is_ready(0) and game.diamonds==gems,"completed ad makes original crop ready without gems")
	check(not speed.complete(game,id),"ticket consumed exactly once")
	game.plots[0].crop=""
	game.plant(0,"gandum")
	game.plots[0].ready_at=game.now()+1000
	id=speed.start(game,0)
	speed.cancel(id)
	check(not speed.complete(game,id) and not game.is_ready(0),"dismissed ad gives no speedup")
	id=speed.start(game,0)
	game.hybrid.crop_generation["0"]=int(game.hybrid.crop_generation["0"])+1
	check(not speed.complete(game,id) and not game.is_ready(0),"replanting same crop invalidates reward")
	id=speed.start(game,0)
	game.new_game(false)
	check(not speed.complete(game,id),"new game cannot receive previous world's reward")
	var ads=FarmAds.new()
	root.add_child(ads)
	var rewarded=[]
	var completed=[]
	var bonus=[]
	ads.speedup_rewarded.connect(func(request_id): rewarded.append(request_id))
	ads.speedup_finished.connect(func(request_id,earned): completed.append([request_id,earned]))
	ads.reward_granted.connect(func(amount): bonus.append(amount))
	check(not ads.request_speedup("unsupported") and rewarded.is_empty() and bonus.is_empty(),"unsupported or disabled ads cannot use free-gem fallback for speedup")
	# Exercise the real SDK listener dispatch and fullscreen cleanup without serving live ads.
	ads._speedup_request="sdk_crop"
	ads._pending_reward="rewarded"
	ads._fullscreen_active=true
	ads._reward_paid=false
	ads._grant_reward("rewarded_interstitial",3)
	check(rewarded.is_empty(),"wrong ad callback ignored")
	ads._grant_reward("rewarded",2)
	ads._grant_reward("rewarded",2)
	check(rewarded==["sdk_crop"] and bonus.is_empty(),"earned callback grants speedup once and never bonus gems")
	ads._cleanup_fullscreen("rewarded")
	check(completed==[["sdk_crop",true]] and ads._speedup_request.is_empty(),"completed ad clears request")
	ads._speedup_request="cancelled"
	ads._pending_reward="rewarded"
	ads._fullscreen_active=true
	ads._reward_paid=false
	ads._cleanup_fullscreen("rewarded")
	ads._grant_reward("rewarded",2)
	check(completed.back()==["cancelled",false] and rewarded.size()==1,"closed or failed ad cannot grant a late reward")
	ads.queue_free()
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://rewarded_speed_ui.json"
	host.game.backup_path="user://rewarded_speed_ui_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.plots[0].crop=""
	host.game.plant(0,"gandum")
	host.game.plots[0].ready_at=host.game.now()+1000
	host.selected_plot=0
	host.game.diamonds=0
	host.on_plot_pressed(0)
	host.farm.hybrid_controller.ui._process(0.0)
	await process_frame
	check(not host.farm.hybrid_controller.ui.controls_button.visible,"floating controls do not cover speedup button")
	var speed_button=find_speed_button(host.action_panel)
	check(speed_button!=null and not speed_button.disabled and "TONTON IKLAN" in speed_button.text,"speedup button offers ad even with zero gems")
	host.on_harvest_or_speed()
	check(not host.game.is_ready(0) and host.speedups.pending.is_empty(),"PC button never grants fake completion or leaves stuck ticket")
	id=host.speedups.start(host.game,0)
	host.ads._speedup_request=id
	host.ads._pending_reward="rewarded"
	host.ads._fullscreen_active=true
	host.ads._reward_paid=false
	host.selected_plot=1
	host.ads._grant_reward("rewarded",2)
	check(host.game.is_ready(0) and host.game.plots[1].crop=="" and host.game.diamonds==0,"real signal wiring rewards captured plot even if selection changed")
	host.ads._cleanup_fullscreen("rewarded")
	var loaded=FarmGameState.new(false)
	loaded.save_path=host.game.save_path
	loaded.backup_path=host.game.backup_path
	check(loaded.load_game() and loaded.is_ready(0),"ad speedup persists in save")
	host.queue_free()
	for i in 6: await process_frame
	host=null
	ads=null
	speed=null
	game=null
	loaded=null
	preload("res://tests/admob_mock_cleanup.gd").release()
	await process_frame
	print("REWARDED SPEEDUP FAILURES: ",failures)
	quit(failures)

func find_speed_button(node: Node) -> Button:
	if node is Button and "PERCEPAT" in node.text: return node
	for child in node.get_children():
		var found=find_speed_button(child)
		if found!=null: return found
	return null
