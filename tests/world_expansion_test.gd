extends SceneTree

const REGIONS = preload("res://scripts/world_regions.gd")
const GAME = preload("res://scripts/game_state.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var game = GAME.new(false)
	game.save_path = "user://world_expansion_test.json"
	game.backup_path = "user://world_expansion_test_backup.json"
	check(game.level == 1, "New farm should begin at level 1")
	check(not REGIONS.purchased(game,"pemancingan"), "Fishing must not auto appear")
	game.level = 18
	game.coins = 10000
	check(REGIONS.can_buy(game,"pemancingan"), "Fishing should be buyable at level 18")
	check(REGIONS.buy(game,"pemancingan",Vector2(3520,1840)), "Fishing purchase failed")
	check(not REGIONS.can_buy(game,"pemancingan"), "Duplicate fishing purchase allowed")
	var message: String = REGIONS.action(game,"pemancingan")
	check(message.contains("ikan"), "Fishing did not yield fish")
	check(int(game.inventory.ikan)==1, "Fish inventory incorrect")
	check(REGIONS.wait_seconds(game,"pemancingan")>0, "Fishing cooldown missing")
	check(not game.order_item_accessible("sup_ikan") == false, "Fishing recipe inaccessible after district purchase")
	check(REGIONS.buy(game,"penggilingan",Vector2(3200,560)), "Mill purchase failed")
	game.inventory.gandum = 2
	check(REGIONS.action(game,"penggilingan").contains("tepung"), "Mill did not craft flour")
	check(int(game.inventory.tepung)==1 and int(game.inventory.gandum)==0, "Mill ingredient accounting failed")
	check(REGIONS.buy(game,"taman_bermain",Vector2(2640,2000)), "Playground purchase failed")
	REGIONS.action(game,"taman_bermain")
	check(int(REGIONS.prepare(game).happiness)==12, "Playground happiness failed")
	check(REGIONS.buy(game,"tambang",Vector2(3520,2640)), "Mine purchase failed")
	REGIONS.action(game,"tambang")
	check(int(preload("res://scripts/building_upgrades.gd").prepare(game).materials.batu)==2, "Mine stone reward failed")
	var loaded = GAME.new(false)
	loaded.save_path = game.save_path
	loaded.backup_path = game.backup_path
	check(loaded.load_game(), "Could not reload expansion save")
	check(REGIONS.purchased(loaded,"pemancingan") and REGIONS.purchased(loaded,"tambang"), "Owned districts not restored")
	check(int(loaded.inventory.ikan)==1 and int(loaded.inventory.tepung)==1, "Region products not restored")
	check(int(REGIONS.prepare(loaded).happiness)==12, "Visitor happiness not restored")
	check(loaded.layout_positions.has("region_penggilingan"), "Purchased position not restored")
	var view = preload("res://scripts/hybrid/hybrid_farm_view.gd").new()
	view.game = loaded
	check(view.editable_keys().has("region_penggilingan"), "Owned mill cannot be moved")
	check(view.snap_edit_position("region_penggilingan",Vector2(3213,581))==Vector2(3200,560), "District does not snap to grid")
	check(view.ujang_obstacle_rects().any(func(rect: Rect2) -> bool: return rect.has_point(view.object_position("region_penggilingan"))), "Pathfinding obstacle missing")
	view.free()
	var legacy = GAME.new(false)
	legacy.save_path = "user://world_expansion_legacy_test.json"
	legacy.backup_path = "user://world_expansion_legacy_test_backup.json"
	legacy.save_game()
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(legacy.save_path))
	payload.erase("world_regions")
	var file := FileAccess.open(legacy.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()
	var restored = GAME.new(false)
	restored.save_path = legacy.save_path
	restored.backup_path = legacy.backup_path
	check(restored.load_game(), "Legacy save failed to load")
	check(not REGIONS.purchased(restored,"pemancingan"), "Legacy save spawned purchased district")
	check(restored.layout_positions==legacy.layout_positions, "Legacy layout changed")
	print("WORLD_EXPANSION_TEST failures=",failures)
	quit(1 if failures>0 else 0)
