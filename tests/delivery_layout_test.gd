extends SceneTree
var failures=0
func check(ok: bool,message: String):
	if ok: print("PASS: ",message)
	else: failures+=1; printerr("FAIL: ",message)
func _initialize(): call_deferred("run")
func free_spot(farm,key: String,preferred: Vector2) -> Vector2:
	for radius in range(0,1200,80):
		for angle in 16:
			var p=preferred+Vector2.from_angle(angle*TAU/16.0)*radius
			if farm.can_place(key,p): return p
	return Vector2.INF
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://delivery_layout_test.json"
	host.game.backup_path="user://delivery_layout_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	host.game.new_game(false) # Legacy-farm regression fixture; FTUE has separate end-to-end tests.
	root.add_child(host)
	host.game.skip_onboarding()
	var farm=host.farm
	check(farm.editable_keys().has("delivery_depot") and farm.editable_keys().has("delivery_truck"),"depot and truck can be arranged independently")
	check(not farm.delivery_depot_bounds().intersects(farm.delivery_truck_bounds()),"default truck is completely clear of depot artwork")
	check(farm.editable_at(farm.object_position("delivery_depot"))=="delivery_depot","depot is selectable")
	check(farm.editable_at(farm.object_position("delivery_truck"))=="delivery_truck","truck is selectable independently")
	check(not farm.can_place("delivery_truck",farm.object_position("delivery_depot")),"truck cannot be placed on depot")
	check(not farm.can_place("delivery_depot",farm.object_position("delivery_truck")),"depot cannot be placed on truck")
	var depot_before=farm.object_position("delivery_depot")
	var truck_before=farm.object_position("delivery_truck")
	var depot_target=free_spot(farm,"delivery_depot",Vector2(2100,1900))
	check(depot_target!=Vector2.INF,"valid depot placement exists")
	farm.set_edit_mode(true)
	farm.begin_edit_drag(screen_point(farm,depot_before))
	check(farm.drag_key=="delivery_depot","drag gesture picks depot artwork")
	farm.drag_preview=depot_target;farm.drag_was_moved=true;farm.finish_edit_drag()
	check(farm.object_position("delivery_truck")==truck_before,"moving depot does not move parked truck")
	var truck_target=free_spot(farm,"delivery_truck",Vector2(2250,2200))
	check(truck_target!=Vector2.INF,"valid truck placement exists")
	farm.begin_edit_drag(screen_point(farm,truck_before))
	check(farm.drag_key=="delivery_truck","drag gesture picks truck independently")
	farm.drag_preview=truck_target;farm.drag_was_moved=true;farm.finish_edit_drag()
	check(farm.object_position("delivery_depot")==depot_target,"moving truck does not move depot")
	var copy=FarmGameState.new(false)
	copy.save_path=host.game.save_path;copy.backup_path=host.game.backup_path
	check(copy.load_game() and Vector2(copy.layout_positions.delivery_truck[0],copy.layout_positions.delivery_truck[1])==truck_target and Vector2(copy.layout_positions.delivery_depot[0],copy.layout_positions.delivery_depot[1])==depot_target,"both positions survive save/load")
	farm.delivery_elapsed=0
	check(farm.delivery_truck_position()==truck_target,"delivery departs from independently placed parking position")
	farm.delivery_elapsed=1.1
	check(farm.delivery_truck_position().x>truck_target.x+200,"delivery animation continues from new location")
	check(not farm.can_place("delivery_truck",truck_target),"moving truck cannot be repositioned mid-delivery")
	farm.delivery_elapsed=-1
	check(farm.delivery_truck_position()==truck_target,"truck returns to chosen parking position")
	farm.drag_key="delivery_depot";farm.drag_original=depot_target;farm.drag_preview=depot_target+Vector2(50,20)
	farm.sync_mobile_world_details()
	check(farm.mobile_world_details_layer.object_position("delivery_depot")==farm.drag_preview,"depot preview updates cached drawing during drag")
	farm.drag_key=""
	farm.sync_mobile_world_details()
	var route=preload("res://scripts/delivery_route.gd")
	var start=Vector2(800,1000)
	var depot_rect=Rect2(1000,900,290,230)
	var truck_rect=farm.delivery_sprite_rect("delivery_truck",Vector2.ZERO)
	var path=route.build(start,depot_rect,truck_rect)
	var clear_route=true
	for i in 101:
		if Rect2(route.point(path,float(i)/100)+truck_rect.position,truck_rect.size).intersects(depot_rect): clear_route=false
	check(path.size()>2 and clear_route,"courier route detours around a depot placed in front of the truck")
	var nav=farm.hybrid_controller.navigation
	nav.ensure()
	check(nav.blocked(truck_target) and nav.blocked(depot_target),"navigation respects relocated truck and depot")
	host.queue_free();await process_frame
	print("DELIVERY LAYOUT FAILURES: ",failures)
	quit(failures)

func screen_point(farm: FarmView,point: Vector2) -> Vector2:
	return (point-farm.camera_center)*farm.camera_zoom*farm.size/farm.get_virtual_size()+farm.size*0.5
