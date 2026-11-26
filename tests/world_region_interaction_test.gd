extends SceneTree

const REGIONS = preload("res://scripts/world_regions.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = "user://world_region_interaction_test.json"
	host.game.backup_path = "user://world_region_interaction_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.ftue.started = true
	host.game.ftue.step = "done"
	host.game.level = 18
	host.game.coins = 3000
	host.game.inventory.gandum = 3
	host.set_meta("first_farm_modal", false)
	for node in host.find_children("*", "", true, false):
		if node.name == "NewPlayerWelcome": node.hide()
	host.switch_tab("kawasan")
	var purchase_button: Button = host.find_child("RegionAction_penggilingan", true, false)
	check(purchase_button != null, "Mill purchase button missing")
	if purchase_button != null: purchase_button.pressed.emit()
	check(REGIONS.purchased(host.game, "penggilingan"), "Mill button did not buy region")
	check(host.game.coins < 3000, "Mill purchase did not deduct coins")
	var spot: Vector2 = host.farm.object_position("region_penggilingan")
	check(host.farm.can_place("region_penggilingan", spot), "Mill placement invalid")
	host.farm.ujang_position = host.farm.hybrid_controller.navigation.nearest(spot + Vector2(0, 240), 300)
	host.switch_tab("kawasan")
	var action_button: Button = host.find_child("RegionAction_penggilingan", true, false)
	check(action_button != null, "Mill action button missing")
	if action_button != null: action_button.pressed.emit()
	check(host.farm.hybrid_controller.data.jobs.size() + int(not host.farm.hybrid_controller.active.is_empty()) > 0, "Region action did not enter movement queue")
	check(int(host.game.inventory.tepung) == 0, "Mill rewarded before character arrived")
	var deadline := Time.get_ticks_msec() + 10000
	while int(host.game.inventory.tepung) == 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	check(int(host.game.inventory.tepung) == 1, "Character failed to reach and use mill")
	check(int(host.game.inventory.gandum) == 1, "Mill did not consume two wheat")
	print("WORLD_REGION_INTERACTION_TEST failures=", failures)
	host.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
