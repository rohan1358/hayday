extends SceneTree
var failures=0
var checks=0
var host
var system
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		print("FAIL: ",message)
	else: print("PASS: ",message)
func _initialize(): call_deferred("run")
func drain(limit:=600) -> void:
	for i in limit:
		if system.active.is_empty() and system.data.jobs.is_empty(): return
		system.tick_jobs(0.1)
	check(false,"queue terminates within bounded time")
func run():
	host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://hybrid_test.json"
	host.game.backup_path="user://hybrid_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	host.game.new_game(false) # Legacy-farm regression fixture; FTUE has separate end-to-end tests.
	root.add_child(host)
	system=host.farm.hybrid_controller
	system.set_process(false)
	host.set_process(false)
	host.farm.set_process(false)
	system.ui.set_process(false)
	system.overlay.set_process(false)
	check(system!=null,"hybrid bootstrap")
	check(host.game.coins==400,"legacy economy preserved")
	check(system.data.animals.size()==2,"starter chicken/cow exist")
	check(system.data.zones.is_empty(),"no additional starter paddocks")
	var state=preload("res://scripts/hybrid/hybrid_state.gd")
	system.data.version=2
	system.data.zones=[{"id":1,"name":"Zona Ayam","position":[1510,150],"size":[430,310]}, {"id":2,"name":"Zona Sapi","position":[520,1980],"size":[460,330]}, {"id":99,"name":"Zona pribadi","position":[2300,2100],"size":[360,260]}]
	state.prepare(host.game)
	check(system.data.zones.size()==1 and system.data.zones[0].id==99,"migration preserves custom zones and removes generated pens")
	check(host.game.coins==400 and system.data.animals.size()==2,"migration preserves economy and original livestock")
	system.animals.ensure_animals()
	check(system.data.zones.size()==1,"removed starter paddocks do not respawn")
	check(system.actions.target({"target":"animal","animal":"sapi_1"})==host.farm.object_position("sapi"),"cow jobs target original pen")
	# Explicit roaming fixtures keep navigation and AI coverage independent of starter content.
	# Remove gather piles before placing artificial fences over their spawn area.
	host.game.building_upgrades.nodes=[]
	system.data.zones=[]
	for i in 2:
		var species="ayam" if i==0 else "sapi"
		var at=[1510,150] if i==0 else [520,1980]
		var size=[430,310] if i==0 else [460,330]
		var fixture={"id":i+1,"name":"Test "+species,"position":at,"size":size,"gate_open":false,"feed":0,"water":0}
		system.data.zones.append(fixture)
		var animal=system.animals.animal(species+"_1")
		animal.legacy_pen=false
		animal.zone=i+1
		animal.position=state.array_point(state.zone_rect(fixture).get_center())
	system.data.next_zone=3
	system.navigation.ensure()
	check(not system.navigation.blocked(host.farm.ujang_position),"player starts outside obstacles")
	var builds=system.navigation.build_count
	system.data.zones[0].feed=5
	system.navigation.ensure()
	check(system.navigation.build_count==builds,"feeding does not rebuild navigation")
	var zone: Dictionary=system.data.zones[0]
	var bounds=preload("res://scripts/hybrid/hybrid_state.gd").zone_rect(zone)
	var inside=system.animals.safe_point(zone,bounds.get_center())
	var outside=system.navigation.nearest(Vector2(bounds.get_center().x,bounds.end.y+100),150)
	zone.gate_open=false
	system.navigation.ensure()
	check(system.navigation.path(inside,outside).is_empty(),"closed gate blocks crossing")
	zone.gate_open=true
	system.navigation.ensure()
	check(not system.navigation.path(inside,outside).is_empty(),"open gate permits crossing")
	zone.gate_open=false
	system.navigation.ensure()
	# Dynamic blockers force a detour without invalidating the static grid.
	var dynamic_checked=false
	for y in range(1800,2400,80):
		if dynamic_checked: break
		for x in range(900,2100,80):
			var a=Vector2(x,y)
			var b=a+Vector2(180,0)
			if not system.navigation.clear_segment(a,b): continue
			var middle=(a+b)*0.5
			var detour=system.navigation.path(a,b,[{"at":middle,"radius":30.0}])
			if detour.is_empty(): continue
			var safe_route=true
			for i in range(1,detour.size()):
				if Geometry2D.get_closest_point_to_segment(middle,detour[i-1],detour[i]).distance_to(middle)<29.9: safe_route=false
			check(safe_route and detour.size()>2,"path avoids a moving animal")
			dynamic_checked=true
			break
	check(dynamic_checked,"dynamic avoidance fixture found")
	var blocked_target=host.farm.object_position("gudang")
	check(system.navigation.path(host.farm.ujang_position,blocked_target).is_empty(),"cannot walk through building")
	system.enqueue({"action":"move","position":[-100,-100]})
	drain()
	check(not system.data.history[-1].ok,"unreachable job reports failure")
	system.data.manager=true
	var index=5
	host.game.plots[index].unlocked=true
	host.game.plots[index].crop="gandum"
	host.game.plots[index].planted_at=host.game.now()-100
	host.game.plots[index].ready_at=host.game.now()-1
	var before=int(host.game.inventory.gandum)
	system.enqueue(system.actions.plot_job("harvest",index))
	drain()
	check(int(host.game.inventory.gandum)==before+2,"queued harvest uses existing inventory logic")
	system.enqueue(system.actions.plot_job("plant",index))
	drain()
	check(host.game.plots[index].crop=="gandum","queued planting")
	var ready=int(host.game.plots[index].ready_at)
	var water=int(system.data.water)
	system.enqueue(system.actions.plot_job("water",index))
	drain()
	check(int(system.data.water)==water-1 and int(host.game.plots[index].ready_at)<ready,"watering consumes water and accelerates growth")
	system.enqueue(system.actions.plot_job("water",index))
	drain()
	check(int(system.data.water)==water-1,"duplicate care does not consume water")
	var fertilizer=int(system.data.fertilizer)
	system.enqueue(system.actions.plot_job("fertilize",index))
	drain()
	check(int(system.data.fertilizer)==fertilizer-1,"fertilizer action")
	var stale=system.actions.plot_job("harvest",index)
	host.game.plots[index].crop=""
	system.enqueue(stale)
	drain()
	check(not system.data.history[-1].ok,"changed target safely skipped")
	var cow: Dictionary=system.animals.animal("sapi_1")
	host.game.inventory.gandum=20
	host.game.inventory.jagung=20
	cow.hunger=20.0
	system.enqueue({"action":"feed","target":"animal","animal":"sapi_1"})
	drain()
	check(cow.hunger==100.0 and host.game.cow_ready_at>0,"cow feeding starts existing milk production")
	cow.thirst=10.0
	system.enqueue({"action":"drink","target":"animal","animal":"sapi_1"})
	drain()
	check(cow.thirst==100.0,"animal drinking")
	cow.cleanliness=20.0
	system.enqueue({"action":"clean","target":"animal","animal":"sapi_1"})
	drain()
	check(cow.cleanliness==100.0 and int(system.data.fertilizer)==fertilizer,"cleaning gives compost once")
	system.enqueue({"action":"pet","target":"animal","animal":"sapi_1"})
	drain()
	check(cow.affection>0,"pet animal")
	host.game.cow_ready_at=host.game.now()-1
	before=int(host.game.inventory.susu)
	system.enqueue({"action":"collect","target":"animal","animal":"sapi_1"})
	drain()
	check(int(host.game.inventory.susu)==before+2,"milk collection")
	host.game.eggs_ready_at=host.game.now()-1
	var eggs_before=int(host.game.inventory.telur)
	system.enqueue({"action":"collect","target":"animal","animal":"ayam_1"})
	drain()
	check(int(host.game.inventory.telur)==eggs_before+2,"queued egg collection")
	system.data.sheep_owned=true
	system.animals.ensure_animals()
	var sheep: Dictionary=system.animals.animal("domba_1")
	system.enqueue({"action":"feed","target":"animal","animal":"domba_1"})
	drain()
	sheep.wool_ready_at=host.game.now()-1
	system.enqueue({"action":"collect","target":"animal","animal":"domba_1"})
	drain()
	check(int(host.game.inventory.get("wol",0))==2,"sheep wool integrated into inventory")
	# Additional ranch types keep the original ingredient and product rules.
	host.game.storage_capacity=300
	host.game.constructions["kandang_babi"]=1
	host.game.constructions["kandang_kambing"]=1
	host.game.inventory.kedelai=10
	host.game.inventory.wortel=10
	system.animals.ensure_animals()
	for species in ["babi","kambing"]:
		system.enqueue({"action":"feed","target":"animal","animal":species+"_1"})
		drain()
		check(int(host.game.livestock[species])>0,"feeding "+species+" starts legacy production")
		host.game.livestock[species]=host.game.now()-1
		system.enqueue({"action":"collect","target":"animal","animal":species+"_1"})
		drain()
		var product="daging_babi" if species=="babi" else "susu_kambing"
		check(int(host.game.inventory[product])==2,"collecting "+product)
	host.game.cow_ready_at=host.game.now()-1
	host.game.storage_capacity=host.game.storage_used()
	var milk_before=int(host.game.inventory.susu)
	system.enqueue({"action":"collect","target":"animal","animal":"sapi_1"})
	drain()
	check(int(host.game.inventory.susu)==milk_before and host.game.cow_milk_ready(),"full warehouse preserves uncollected produce")
	host.game.storage_capacity=300
	# Autonomous needs, rest and containment, using virtual simulation time.
	var cow_zone: Dictionary=system.animals.zone(int(cow.zone))
	cow_zone.feed=4
	cow_zone.water=4
	cow.hunger=15.0
	cow.thirst=15.0
	for i in 100: system.animals.tick(0.2)
	check(cow.hunger>40 and cow.thirst>40,"autonomous eating/drinking consumes trough stock")
	check(preload("res://scripts/hybrid/hybrid_state.gd").zone_contains(cow_zone,system.animals.position(cow)),"roaming remains inside permitted zone")
	cow.energy=10.0
	system.animals.agents.erase(str(cow.id))
	for i in 100: system.animals.tick(0.2)
	check(cow.energy>10 and cow.state=="sleep","animal sleep restores energy")
	# Open gate and guide a cow to a nearby empty zone.
	cow.energy=90.0
	cow_zone.gate_open=true
	var destination={"id":99,"name":"Test pasture","gate_edge":0,"position":[2350,2100],"size":[360,260],"gate_open":true,"feed":0,"water":0}
	system.data.zones.append(destination)
	system.navigation.ensure()
	var guided=system.animals.herd("sapi_1",99)
	check(guided,"herding creates collision-safe path through open gates")
	if guided:
		for i in 700: system.animals.tick(0.2)
		check(int(cow.zone)==99,"herding transfers animal to destination zone")
	# An action canceled partway through cannot consume resources.
	system.data.manager=false
	var canceled_before=int(system.data.water)
	system.enqueue({"action":"drink","target":"animal","animal":"sapi_1"})
	system.tick_jobs(0.1)
	system.action_time=0.1
	system.cancel_all("")
	check(int(system.data.water)==canceled_before,"cancel before commit preserves inventory")
	system.data.manager=false
	system.cancel_all("")
	var walking_start=system.navigation.nearest(Vector2(1200,1930),250)
	host.farm.ujang_position=walking_start
	var walking_finish=walking_start+Vector2(50,0)
	if system.navigation.blocked(walking_finish): walking_finish=system.navigation.nearest(walking_finish,100)
	system.enqueue({"action":"move","position":[walking_finish.x,walking_finish.y]})
	drain()
	check(host.farm.ujang_position.distance_to(walking_finish)<3,"tap-style automatic travel reaches destination")
	var start=system.navigation.nearest(Vector2(1200,1910),250)
	host.farm.ujang_position=start
	system.enqueue({"action":"move","position":preload("res://scripts/hybrid/hybrid_state.gd").array_point(start+Vector2(60,0))})
	check(not system.data.jobs.is_empty(),"movement queued")
	var key=InputEventKey.new()
	key.physical_keycode=KEY_D
	key.keycode=KEY_D
	key.pressed=true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	system._process(0.1)
	check(system.active.is_empty() and system.data.jobs.is_empty() and not system.data.auto_work,"manual input cancels all automatic commands")
	check(host.farm.ujang_position!=start,"WASD moves player")
	var release_key=InputEventKey.new()
	release_key.keycode=KEY_D
	release_key.physical_keycode=KEY_D
	release_key.pressed=false
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	var joy=system.ui.joystick
	joy.show()
	joy.set_axis(joy.size*0.5+Vector2(60,0))
	check(joy.axis.x>0.7,"virtual joystick axis")
	joy.release()
	check(joy.axis==Vector2.ZERO,"joystick release")
	# The joystick owns only its finger; another finger remains available to pan.
	var own_touch=InputEventScreenTouch.new()
	own_touch.index=7
	own_touch.pressed=true
	own_touch.position=joy.size*0.5
	joy._gui_input(own_touch)
	var foreign_release=InputEventScreenTouch.new()
	foreign_release.index=8
	foreign_release.pressed=false
	joy._input(foreign_release)
	check(joy.finger==7,"second touch cannot release joystick")
	var own_release=InputEventScreenTouch.new()
	own_release.index=7
	own_release.pressed=false
	joy._input(own_release)
	check(joy.finger==-1 and joy.axis==Vector2.ZERO,"owned touch releases joystick cleanly")
	system.data.follow=true
	system.farm.pan_by(Vector2(30,0))
	check(not system.data.follow,"panning switches to free camera")
	system.cancel_all("")
	var care=system.actions.plot_job("plant",index)
	system.enqueue(care)
	system.save_state()
	var loaded=FarmGameState.new(false)
	loaded.save_path=host.game.save_path
	loaded.backup_path=host.game.backup_path
	check(loaded.load_game(),"save remains readable")
	check(loaded.hybrid.jobs.size()==1 and loaded.hybrid.animals.size()==5,"job queue and livestock persist")
	check(int(loaded.inventory.get("wol",0))==2,"wool persists after reload")
	system.cancel_all("")
	for i in 80: system.enqueue({"action":"move","position":[1500+i,2000]})
	check(system.data.jobs.size()==64,"queue bounded to 64 jobs")
	system.cancel_all("")
	# Restart migration restores an uncommitted command exactly once.
	system.data.active={"id":990,"action":"move","position":[1500,2000]}
	var recovered=preload("res://scripts/hybrid/hybrid_state.gd").prepare(host.game)
	check(recovered.active.is_empty() and recovered.jobs.size()==1,"in-flight command resumes after restart")
	system.data.jobs=[]
	var generation_job=system.actions.plot_job("water",4)
	host.game.plots[4].crop=""
	host.game.plant(4,"gandum")
	check(not system.actions.valid(generation_job).is_empty(),"same-second replant invalidates stale commands")
	system.data.crop_care["4"]={"planted_at":int(host.game.plots[4].planted_at),"generation":int(host.game.hybrid.crop_generation["4"])-1,"water":true}
	check(system.actions.valid(system.actions.plot_job("water",4)).is_empty(),"fresh crop can be watered despite same-second previous care")
	system.cancel_all("")
	system.data.auto_work=true
	system.generate_work()
	check(not system.data.jobs.is_empty(),"recurring planner creates eligible farming/ranch tasks")
	system.cancel_all("")
	check(not system.data.auto_work and system.data.jobs.is_empty(),"cancel disables recurring work")
	joy.show()
	joy.set_axis(joy.size*0.5+Vector2(50,0))
	system._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(joy.axis==Vector2.ZERO,"background pause releases touch controls")
	host.game.new_game(false)
	system.reset_new_game()
	check(system.data.animals.size()==2 and system.data.jobs.is_empty(),"new-game reset rebuilds hybrid state cleanly")
	host.queue_free()
	await process_frame
	print("HYBRID CHECKS: ",checks," FAILURES: ",failures)
	quit(1 if failures else 0)
