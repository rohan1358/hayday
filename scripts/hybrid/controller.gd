extends Node
const STATE=preload("res://scripts/hybrid/hybrid_state.gd")
const NAV=preload("res://scripts/hybrid/navigation.gd")
const ACTIONS=preload("res://scripts/hybrid/job_actions.gd")
const ANIMALS=preload("res://scripts/hybrid/animal_simulation.gd")
var host
var farm
var data: Dictionary
var navigation
var actions
var animals
var ui
var overlay
var boulder_layer
var active: Dictionary={}
var route=PackedVector2Array()
var cursor=0
var elapsed=0.0
var action_time=0.0
var phase="idle"
var activity="idle"
var direction=Vector2.DOWN
var running=false
var idle_clock=0.0
var idle_activity="idle"
var manual=Vector2.ZERO
var blocked_time=0.0
var retry_count=0
var last_target=Vector2.ZERO
var last_revision=""
var save_clock=0.0
var auto_clock=0.0
var dirty=false
var selected_tool="auto"
var append_jobs=true
var zone_tool=""
var zone_first=Vector2.INF
var selected_animal=""
var tick_clock=0.0
var layout_checked=""
var herd_repath=0.0
var pose_timer=0.0
var last_pose_activity=""
signal job_finished(job: Dictionary,result: Dictionary)
func _ready() -> void:
	host=get_parent()
	farm=host.farm
	data=STATE.prepare(host.game)
	STATE.settle_offline(data,host.game.now())
	navigation=NAV.new()
	navigation.configure(farm)
	navigation.ensure()
	animals=ANIMALS.new()
	animals.configure(self)
	actions=ACTIONS.new()
	actions.configure(self)
	preload("res://scripts/building_upgrades.gd").setup_nodes(self)
	farm.hybrid_controller=self
	farm.ujang_position=STATE.point(data.player,Vector2(700,980))
	rescue_player()
	ui=preload("res://scripts/hybrid/control_ui.gd").new()
	ui.system=self
	host.add_child(ui)
	boulder_layer=preload("res://scripts/hybrid/resource_boulder_layer.gd").new()
	boulder_layer.source=farm
	farm.add_child(boulder_layer)
	overlay=preload("res://scripts/hybrid/world_overlay.gd").new()
	overlay.system=self
	farm.add_child(overlay)
	farm.set_meta("hybrid_system",self)
	host.toast_layer.z_index=120
	for node in host.get_children():
		if node.get_script()==load("res://scripts/seasonal_ui.gd"): node.badge.hide()
	save_state()
func manager_mode() -> bool:
	if preload("res://scripts/first_farm.gd").active(host.game): return false
	return bool(data.get("manager",false)) and zone_tool.is_empty()
func controls_blocked() -> bool:
	if host.get_meta("first_farm_modal",false): return true
	if not host.game.ftue.is_empty() and not bool(host.game.ftue.get("started",true)): return true
	if host.active_tab!="kebun" or farm.edit_mode or ui.menu.visible: return true
	var focus=get_viewport().gui_get_focus_owner()
	if (focus is LineEdit or focus is TextEdit) and focus.is_visible_in_tree(): return true
	for node in host.get_children():
		if node.get_script()==load("res://scripts/seasonal_ui.gd"):
			if node.panel.visible or node.wardrobe_editor.visible: return true
	return false
func _process(delta: float) -> void:
	if farm==null: return
	if host.game.hybrid.is_empty(): reset_new_game()
	var step=minf(delta,0.1)
	navigation.ensure()
	if navigation.revision!=layout_checked:
		layout_checked=navigation.revision
		if navigation.blocked(farm.ujang_position):
			rescue_player()
	animals.tick(delta)
	var axis=Vector2.ZERO
	if not controls_blocked():
		axis=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		if ui.joystick.axis.length()>axis.length(): axis=ui.joystick.axis
		axis=axis.limit_length(1)
	manual=axis
	running=axis.length()>0.88 and (Input.is_physical_key_pressed(KEY_SHIFT) or ui.joystick.axis.length()>0.88)
	if axis.length()>0.05:
		if not active.is_empty() or not data.jobs.is_empty() or bool(data.auto_work) or phase=="idle_walk" or farm.chopping_tree>=0: cancel_all("")
		idle_clock=0
		idle_activity="idle"
		activity="run" if running else "walk"
		direction=axis.normalized()
		move_manual(axis,step)
	elif farm.chopping_tree>=0:
		activity="chop" if farm.chop_progress>0 else "walk"
	elif not farm.edit_mode:
		tick_jobs(step)
	if bool(data.follow) and not controls_blocked() and (not manager_mode() or axis.length()>0):
		farm.camera_target=farm.ujang_position
		farm.clamp_camera_target()
	farm.ujang_walking=activity in ["walk","run"]
	farm.ujang_facing=-1.0 if direction.x<0 else 1.0
	farm.set_meta("hybrid_pose",{"activity":activity,"direction":direction,"time":action_time,"target":last_target,"phase":phase,"clock":float(Time.get_ticks_msec())/1000.0,"tool_action":"herd" if phase=="herd" else activity})
	if farm.mobile_ujang_layer!=null:
		farm.mobile_ujang_layer.set_meta("hybrid_pose",farm.get_meta("hybrid_pose"))
		pose_timer+=delta
		if activity!=last_pose_activity or activity not in ["idle","observe","sit","watch_animals"] and pose_timer>=0.05:
			farm.mobile_ujang_layer.queue_redraw()
			pose_timer=0.0
			last_pose_activity=activity
	save_clock+=delta
	auto_clock+=delta
	if auto_clock>5:
		auto_clock=0
		animals.ensure_animals()
		if bool(data.auto_work) and active.is_empty() and data.jobs.is_empty(): generate_work()
	if save_clock>10:
		save_clock=0
		save_state()
func move_manual(axis: Vector2,delta: float) -> void:
	navigation.ensure()
	var movement=axis*(230.0 if running else 140.0)*delta
	var start: Vector2=farm.ujang_position
	var finish=start+movement
	if collision_free(start,finish): farm.ujang_position=finish
	else:
		var x=start+Vector2(movement.x,0)
		var y=start+Vector2(0,movement.y)
		if collision_free(start,x): farm.ujang_position=x
		elif collision_free(start,y): farm.ujang_position=y
func collision_free(start: Vector2,finish: Vector2) -> bool:
	return navigation.clear_segment(start,finish) and not animals.occupied(finish,"",25)
func enqueue(job: Dictionary,replace=false) -> bool:
	if job.is_empty(): return false
	if str(job.get("action", "")) == "chop" and host.game.wild_tree_chop_cooling_down():
		host.show_toast(FarmGameState.WILD_TREE_COOLDOWN_NOTICE)
		return false
	if str(job.get("action", "")) == "chop" and not host.game.can_chop_wild_tree():
		host.prompt_tree_chop_ad(int(job.get("index", -1)), true, replace)
		return false
	if replace: cancel_all("")
	if data.jobs.size()>=64:
		host.show_toast("Antrean penuh (maksimal 64).")
		return false
	# Duplicate target/action/crop commands do not waste water or inventory.
	for existing in data.jobs+[active]:
		if existing.is_empty(): continue
		var left: Dictionary=existing.duplicate(true)
		var right: Dictionary=job.duplicate(true)
		left.erase("id")
		right.erase("id")
		if left==right: return false
	var value=job.duplicate(true)
	value.id=int(data.next_job)
	data.next_job=int(data.next_job)+1
	data.jobs.append(value)
	idle_clock=0
	idle_activity="idle"
	if phase=="idle_walk":
		route.clear()
		phase="idle"
	dirty=true
	save_state()
	return true
func cancel_all(message: String="Antrean dibatalkan.") -> void:
	if not active.is_empty() and str(active.get("action",""))=="herd": animals.cancel_herd(str(active.get("animal","")))
	active={}
	data.active={}
	data.jobs=[]
	data.auto_work=false
	route.clear()
	phase="idle"
	activity="idle"
	action_time=0
	idle_clock=0
	idle_activity="idle"
	farm.chopping_tree=-1
	if not message.is_empty(): host.show_toast(message)
	save_state()
func tick_jobs(delta: float) -> void:
	if active.is_empty():
		if not data.jobs.is_empty():
			active=data.jobs.pop_front()
			data.active=active
			elapsed=0
			action_time=0
			retry_count=0
			begin_job()
		else:
			idle_tick(delta)
			return
	if active.is_empty(): return
	elapsed+=delta
	if elapsed>maxf(40.0,float(route.size())*2+30) and phase!="herd":
		finish({"ok":false,"message":"Batas waktu jalur terlampaui; pekerjaan dilewati."})
		return
	if phase=="travel":
		navigation.ensure()
		var target: Vector2=actions.target(active)
		if target==Vector2.INF:
			finish({"ok":false,"message":"Target sudah tidak ada."})
			return
		if navigation.revision!=last_revision or target.distance_to(last_target)>65:
			begin_job()
			return
		if follow_route(delta):
			phase="action"
			direction=(actions.target(active)-farm.ujang_position).normalized()
			activity=job_activity(active)
			action_time=0
		elif blocked_time>0.8:
			retry_count+=1
			if retry_count>3: finish({"ok":false,"message":"Jalur terhalang; pekerjaan dilewati."})
			else: begin_job()
	elif phase=="action":
		if not manager_mode() and str(active.action)!="move" and farm.ujang_position.distance_to(actions.target(active))>actions.reach(active)+15:
			begin_job()
			return
		var previous_time=action_time
		action_time+=delta
		if str(active.action)=="chop":
			for strike in [0.25,0.65,1.05]:
				if previous_time<strike and action_time>=strike:
					farm.wild_tree_struck.emit()
					farm.show_world_feedback("chop_hit",last_target)
		activity=job_activity(active)
		if action_time>=float(actions.DURATIONS.get(str(active.action),1)):
			var job=active.duplicate(true)
			# Remove the in-flight marker before legacy methods perform atomic saves.
			# A crash cannot replay an inventory-changing command after its commit.
			data.active={}
			var result: Dictionary=actions.execute(job)
			if job.action=="herd" and result.ok:
				data.active=job
				phase="herd"
				action_time=0
			else: finish(result)
	elif phase=="herd":
		action_time+=delta
		var animal: Dictionary=animals.animal(str(active.animal))
		if animal.is_empty() or animal.state=="blocked" or action_time>120:
			animals.cancel_herd(str(active.animal))
			finish({"ok":false,"message":"Menggiring terhenti. Periksa gerbang dan jalur."})
		elif int(animal.zone)==int(active.zone) and animal.state!="herd": finish({"ok":true,"message":"Hewan tiba di zona tujuan."})
		else:
			activity="herd"
			last_target=animals.position(animal)
			herd_repath+=delta
			if not manager_mode() and farm.ujang_position.distance_to(last_target)>95:
				if herd_repath>0.7 or route.is_empty():
					herd_repath=0
					route=navigation.approach(farm.ujang_position,last_target,95,[{"at":last_target,"radius":30.0}])
					cursor=1
				follow_route(delta)
func begin_job() -> void:
	var error: String=actions.valid(active)
	if not error.is_empty():
		if str(active.get("action", "")) == "chop" and not host.game.can_chop_wild_tree() and not host.game.wild_tree_chop_cooling_down():
			host.prompt_tree_chop_ad(int(active.get("index", -1)), true)
		finish({"ok":false,"message":error})
		return
	navigation.ensure()
	last_revision=navigation.revision
	last_target=actions.target(active)
	if last_target==Vector2.INF:
		finish({"ok":false,"message":"Target tidak ditemukan."})
		return
	if manager_mode():
		phase="action"
		action_time=float(actions.DURATIONS.get(str(active.action),0))
		return
	var avoid: Array=[]
	for animal in data.animals: avoid.append({"at":animals.position(animal),"radius":28.0})
	if active.action=="move": route=navigation.path(farm.ujang_position,last_target,avoid)
	else: route=navigation.approach(farm.ujang_position,last_target,actions.reach(active),avoid)
	if route.is_empty():
		finish({"ok":false,"message":"Target tidak dapat dijangkau. Buka gerbang atau pindahkan penghalang."})
		return
	cursor=1
	blocked_time=0
	phase="travel"
	activity="walk"
func follow_route(delta: float) -> bool:
	if cursor>=route.size(): return true
	var start: Vector2=farm.ujang_position
	var destination=route[cursor]
	var next=start.move_toward(destination,145*delta)
	if collision_free(start,next):
		farm.ujang_position=next
		if next.distance_to(destination)<2: cursor+=1
		if next!=start: direction=(next-start).normalized()
		activity="walk"
		blocked_time=0
	else:
		blocked_time+=delta
		activity="idle"
	return cursor>=route.size()
func finish(result: Dictionary) -> void:
	var completed=active.duplicate(true)
	data.history.append({"id":active.get("id",0),"action":active.get("action",""),"ok":bool(result.get("ok",false)),"message":str(result.get("message",""))})
	while data.history.size()>20: data.history.pop_front()
	active={}
	data.active={}
	route.clear()
	phase="idle"
	activity="idle"
	action_time=0
	idle_clock=0
	if not str(result.get("message","")).is_empty(): host.show_toast(str(result.message))
	host.refresh_all()
	save_state()
	job_finished.emit(completed,result)
func idle_tick(delta: float) -> void:
	if preload("res://scripts/first_farm.gd").active(host.game):
		activity="wave" if host.game.ftue.step=="welcome" else "observe"
		return
	idle_clock+=delta
	if phase=="idle_walk":
		if follow_route(delta) or blocked_time>0.4:
			phase="idle"
			activity="observe"
			idle_clock=0
		return
	activity=idle_activity
	if idle_clock<9: return
	idle_clock=0
	var choices: Array=["sit","observe","watch_animals","stroll"]
	idle_activity=str(choices[int(Time.get_ticks_msec()/9000)%choices.size()])
	if idle_activity=="stroll":
		navigation.ensure()
		var destination: Vector2=farm.ujang_position+Vector2.from_angle(float(Time.get_ticks_msec()%628)/100)*90
		route=navigation.path(farm.ujang_position,destination)
		if not route.is_empty():
			cursor=1
			phase="idle_walk"
			activity="walk"
		else: idle_activity="observe"
func tap_world(at: Vector2) -> void:
	if preload("res://scripts/first_farm.gd").compact(host.game):
		preload("res://scripts/first_farm_input.gd").tap(self,at)
		return
	if not controls_blocked() and zone_tool.is_empty() and farm.ready_marker_at(at).is_empty():
		var upgrades=preload("res://scripts/building_upgrades.gd")
		var boulder=upgrades.boulder_at(farm,at)
		if boulder>=0:
			enqueue(upgrades.node_job(host.game,boulder))
			return
	if not zone_tool.is_empty():
		handle_zone_tap(at)
		return
	if not controls_blocked() and not manager_mode():
		idle_clock=0
		for animal in data.animals:
			if Rect2(animals.position(animal)-Vector2(60,105),Vector2(120,140)).has_point(at):
				selected_animal=str(animal.id)
				if str(animal.species)!="domba": farm.animal_tapped.emit(str(animal.species))
				var action=selected_tool if selected_tool in ["feed","drink","collect","clean","pet"] else "pet"
				if selected_tool=="auto":
					var species=str(animal.species)
					if species=="ayam" and host.game.ready_eggs() or species=="sapi" and host.game.cow_milk_ready() or species in ["babi","kambing"] and host.game.animal_ready(species) or species=="domba" and int(animal.get("wool_ready_at",0))>0 and host.game.now()>=int(animal.get("wool_ready_at",0)): action="collect"
					elif float(animal.hunger)<65 or species=="sapi" and host.game.cow_is_hungry() or species in ["babi","kambing"] and host.game.animal_hungry(species) or species=="domba" and int(animal.get("wool_ready_at",0))==0: action="feed"
					elif float(animal.thirst)<40: action="drink"
					elif float(animal.cleanliness)<50: action="clean"
				enqueue({"action":action,"target":"animal","animal":str(animal.id)},not append_jobs)
				return
		var marker= farm.ready_marker_at(at)
		if marker in ["sapi","babi","kambing"]:
			enqueue({"action":"collect","target":"animal","animal":marker+"_1"},not append_jobs)
			return
		elif marker in ["dapur","pakan"]:
			enqueue({"action":"open","target":"building","key":marker},not append_jobs)
			return
		for i in host.game.plots.size():
			var diff: Vector2=(at-farm.plot_center(i)).abs()
			if diff.x/90+diff.y/55<=1:
				var action=selected_tool
				if action=="auto": action="harvest" if host.game.is_ready(i) else ("plant" if host.game.plots[i].crop=="" else "water")
				if action=="plant" and bool(host.game.plots[i].unlocked) and str(host.game.plots[i].crop)=="":
					ui.open_seed_picker(i)
					return
				if action in ["plant","water","fertilize","harvest"]: enqueue(actions.plot_job(action,i),not append_jobs)
				else: host.show_toast("Pilih alat berkebun untuk petak tanaman.")
				return
		if not host.game.visitor_request.is_empty() and Rect2(farm.visitor_world_position()-Vector2(65,120),Vector2(130,150)).has_point(at):
			enqueue({"action":"open","target":"position","key":"pengunjung","position":STATE.array_point(farm.visitor_world_position())},not append_jobs)
			return
		for board in [[Rect2(275,800,156,48),"bangun"],[Rect2(1690,800,156,48),"ternak"],[Rect2(1680,1096,213,99),"misi"],[farm.delivery_depot_bounds(),"pesanan"],[farm.delivery_truck_bounds(),"pesanan"]]:
			if board[0].has_point(at):
				enqueue({"action":"open","target":"position","key":board[1],"position":STATE.array_point(board[0].get_center())},not append_jobs)
				return
		for species in ["sapi","ayam","babi","kambing"]:
			if preload("res://scripts/asset_projection.gd").info(farm,species,farm.object_position(species)).bounds.grow(10).has_point(at):
				host.switch_tab(species)
				return
		for key in ["dapur","gudang","pasar","pakan","roti","susu"]:
			if key in ["pakan","roti","susu"] and not host.game.has_construction({"pakan":"pabrik_pakan","roti":"toko_roti","susu":"pabrik_susu"}[key]): continue
			var hits=at.distance_to(farm.object_position(key))<95
			if key in ["dapur","gudang","pasar","pakan","roti","susu"]:
				hits=preload("res://scripts/asset_projection.gd").info(farm,key,farm.object_position(key)).bounds.grow(8).has_point(at)
			if hits:
				enqueue({"action":"open","target":"building","key":key},not append_jobs)
				return
		for i in host.game.ORCHARD_SIZE:
			if at.distance_to(farm.orchard_center(i))<75:
				enqueue({"action":"orchard" if host.game.tree_ready(i) else "open","target":"orchard","index":i,"key":"kebun_buah"},not append_jobs)
				return
		var tree: int=farm.wild_tree_at(at)
		if tree>=0:
			enqueue({"action":"chop","target":"tree","index":tree},not append_jobs)
			return
		enqueue({"action":"move","position":STATE.array_point(at)},true)
func batch_plots(action: String) -> void:
	for i in host.game.plots.size():
		var job: Dictionary=actions.plot_job(action,i)
		if actions.valid(job).is_empty(): enqueue(job)
func batch_animals(action: String) -> void:
	for animal in data.animals: enqueue({"action":action,"target":"animal","animal":str(animal.id)})
func generate_work() -> void:
	batch_plots("harvest")
	batch_plots("plant")
	for animal in data.animals:
		var species=str(animal.species)
		var ready: bool=host.game.ready_eggs() if species=="ayam" else host.game.cow_milk_ready() if species=="sapi" else host.game.animal_ready(species) if species in ["babi","kambing"] else int(animal.get("wool_ready_at",0))>0 and host.game.now()>=int(animal.get("wool_ready_at",0))
		if ready: enqueue({"action":"collect","target":"animal","animal":str(animal.id)})
		elif float(animal.hunger)<65 or species=="sapi" and host.game.cow_is_hungry() or species in ["babi","kambing"] and host.game.animal_hungry(species) or species=="domba" and int(animal.get("wool_ready_at",0))==0: enqueue({"action":"feed","target":"animal","animal":str(animal.id)})
func save_state() -> void:
	if host==null or farm==null: return
	data.player=STATE.array_point(farm.ujang_position)
	data.active=active
	data.saved_at=host.game.now()
	host.game.save_game()
	dirty=false
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and ui!=null: ui.joystick.release()
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST: save_state()
	if what==NOTIFICATION_WM_GO_BACK_REQUEST and ui!=null:
		if ui.menu.visible: ui.menu.hide()
		else: cancel_all()
func handle_zone_tap(at: Vector2) -> void:
	if data.zones.size()>=12:
		host.show_toast("Maksimal 12 zona untuk menjaga kelancaran game.")
		zone_tool=""
		zone_first=Vector2.INF
		return
	if zone_first==Vector2.INF:
		zone_first=at
		host.show_toast("Ketuk sudut berlawanan zona. Gerbang dibuat di sisi bawah.")
		return
	var rect=Rect2(zone_first.min(at),(at-zone_first).abs())
	if rect.size.x<180 or rect.size.y<160 or not Rect2(Vector2.ONE*30,farm.WORLD_SIZE-Vector2.ONE*60).encloses(rect):
		host.show_toast("Zona minimal 180×160 dan harus di dalam peta.")
		return
	for animal in data.animals:
		if rect.has_point(animals.position(animal)):
			host.show_toast("Buat zona kosong; jangan menutup pagar di atas hewan.")
			return
	data.zones.append({"id":int(data.next_zone),"name":"Zona "+str(data.next_zone),"position":STATE.array_point(rect.position),"size":STATE.array_point(rect.size),"gate_open":false,"feed":0,"water":0})
	data.next_zone=int(data.next_zone)+1
	zone_tool=""
	zone_first=Vector2.INF
	navigation.ensure()
	save_state()
	host.show_toast("Zona berpagar dibuat. Buka gerbang untuk menggiring hewan masuk.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if ui.menu.visible: ui.menu.hide()
		else:
			zone_tool=""
			zone_first=Vector2.INF
			cancel_all()
		get_viewport().set_input_as_handled()

func reset_new_game() -> void:
	active={}
	route.clear()
	phase="idle"
	activity="idle"
	data=STATE.prepare(host.game)
	animals.agents.clear()
	navigation.revision=""
	animals.ensure_animals()
	navigation.ensure()
	preload("res://scripts/building_upgrades.gd").setup_nodes(self)
	navigation.ensure()
	var safe: Vector2=navigation.nearest(Vector2(700,980),350)
	if safe!=Vector2.INF: farm.ujang_position=safe
	ui.menu.hide()
	save_state()
func job_activity(job: Dictionary) -> String:
	if job.get("action","")=="gather": return "harvest"
	if str(job.get("action",""))=="collect" and job.get("target","")=="animal":
		var value: Dictionary=animals.animal(str(job.get("animal","")))
		match str(value.get("species","")):
			"ayam": return "eggs"
			"sapi","kambing": return "milk"
			"domba": return "shear"
	return str(job.get("action","idle"))

func rescue_player() -> void:
	var point: Vector2=navigation.nearest(farm.ujang_position,350)
	if point==Vector2.INF:
		point=navigation.nearest(farm.plot_center(0)+Vector2(-160,-140),900)
	if point!=Vector2.INF:
		farm.ujang_position=point
		data.player=STATE.array_point(point)
