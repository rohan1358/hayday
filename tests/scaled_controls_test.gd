extends SceneTree
func _initialize(): call_deferred("run")
func click_at(at: Vector2):
	for down in [true,false]:
		var e=InputEventMouseButton.new()
		e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=at;e.global_position=at
		root.push_input(e,true)
		await process_frame
func touch_at(at: Vector2):
	for down in [true,false]:
		var e=InputEventScreenTouch.new()
		e.index=0;e.pressed=down;e.position=at
		Input.parse_input_event(e)
		for frame in 2: await process_frame
func run():
	root.size=Vector2i(720,1280)
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://scaled_controls_test.json"
	host.game.backup_path="user://scaled_controls_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	for frame in 4: await process_frame
	var guide=preload("res://scripts/cheerful_menus.gd").guide(host)
	guide.start_adventure()
	var system=host.farm.hybrid_controller
	for frame in 4: await process_frame
	assert(not system.controls_blocked())
	host.farm.ujang_position=Vector2(1200,780)
	var initial=host.farm.ujang_position
	var key=InputEventKey.new();key.physical_keycode=KEY_D;key.pressed=true
	Input.parse_input_event(key)
	await create_timer(0.3).timeout
	key=InputEventKey.new();key.physical_keycode=KEY_D;key.pressed=false;Input.parse_input_event(key)
	assert(host.farm.ujang_position.distance_to(initial)>5,"Actual WASD input must move the character")
	system.ui.open_seed_picker(0)
	for frame in 4: await process_frame
	var choose=system.ui.content.find_child("SeedChoice_gandum",true,false)
	assert(choose!=null and not choose.disabled)
	await click_at(choose.get_global_rect().get_center())
	assert(system.ui.first_seed_selected,"Actual seed click must select wheat")
	var plant=system.ui.content.find_child("ConfirmSeedPlant",true,false)
	assert(not plant.disabled)
	await click_at(plant.get_global_rect().get_center())
	assert(not system.ui.menu.visible,"Actual plant click must close the picker")
	assert(not system.data.jobs.is_empty() or not system.active.is_empty())
	system.cancel_all("")
	system.ui.open_seed_picker(0)
	for frame in 3: await process_frame
	choose=system.ui.content.find_child("SeedChoice_gandum",true,false)
	await touch_at(choose.get_global_rect().get_center())
	assert(system.ui.first_seed_selected,"Touch must select wheat")
	plant=system.ui.content.find_child("ConfirmSeedPlant",true,false)
	await touch_at(plant.get_global_rect().get_center())
	assert(not system.ui.menu.visible,"Touch must confirm planting")
	system.cancel_all("")
	system.ui.open_seed_picker(0)
	host.switch_tab("gudang")
	host.switch_tab("kebun")
	assert(not system.ui.menu.visible and not system.controls_blocked(),"Returning from a page must clear the hidden input lock")
	host.farm.ujang_position=Vector2(1200,780)
	for frame in 3: await process_frame
	system.ui.scale=Vector2(0.65,0.65)
	var stick=system.ui.joystick
	assert(stick.visible)
	initial=host.farm.ujang_position
	var finger=InputEventScreenTouch.new();finger.index=3;finger.pressed=true
	finger.position=stick.get_global_rect().get_center()
	Input.parse_input_event(finger)
	for frame in 2: await process_frame
	var drag=InputEventScreenDrag.new();drag.index=3;drag.position=stick.get_global_rect().get_center()+Vector2(45,0);drag.relative=Vector2(45,0)
	Input.parse_input_event(drag)
	await create_timer(0.3).timeout
	assert(stick.axis.x>0.5 and host.farm.ujang_position.distance_to(initial)>5,"Touch joystick must actually move the character")
	finger=InputEventScreenTouch.new();finger.index=3;finger.pressed=false;finger.position=stick.get_global_rect().get_center()
	Input.parse_input_event(finger)
	for frame in 2: await process_frame
	assert(stick.axis==Vector2.ZERO)
	initial=host.farm.ujang_position
	var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.position=stick.get_global_rect().get_center()
	Input.parse_input_event(mouse)
	for frame in 2: await process_frame
	var motion=InputEventMouseMotion.new();motion.button_mask=MOUSE_BUTTON_MASK_LEFT;motion.position=stick.get_global_rect().get_center()+Vector2(-45,0);motion.relative=Vector2(-45,0)
	Input.parse_input_event(motion)
	await create_timer(0.3).timeout
	assert(stick.axis.x< -0.5 and host.farm.ujang_position.distance_to(initial)>5,"Mouse drag from center must move the character")
	mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=false;mouse.position=motion.position;Input.parse_input_event(mouse)
	for frame in 2: await process_frame
	assert(stick.axis==Vector2.ZERO)
	host.queue_free();await process_frame
	print("REAL CONTROLS PASS: WASD, touch joystick, mouse/touch seed selection and planting, navigation unlock")
	quit()
