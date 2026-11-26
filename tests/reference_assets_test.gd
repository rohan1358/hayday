extends SceneTree

const GAME = preload("res://scripts/game_state.gd")
const ART = preload("res://scripts/farm_art.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var art := ART.new()
	for key in ReferenceAssets.ALIASES:
		art.ensure_reference(key)
		check(art.sprites.has(key), "Missing world sprite: " + key)
	for key in ReferenceAssets.DECOR_CELLS:
		art.ensure_reference(key)
		check(art.sprites.has(key), "Missing catalog sprite: " + key)
		if art.sprites.has(key):
			check(art.sprites[key].region.has_area(), "Empty atlas region: " + key)
	for key in ReferenceAssets.CROPS:
		check(ReferenceAssets.icon("ref_crop_" + key) != null, "Missing crop icon: " + key)
	for key in ReferenceAssets.CROP_STAGES:
		for stage in 3:
			check(not ReferenceAssets.sprite("ref_stage_%s_%d" % [key,stage]).is_empty(), "Missing crop stage: " + key)
	for key in GAME.DECORATION_ORDER:
		check(GAME.DECORATIONS.has(key), "Catalog entry lacks metadata: " + key)
	var game := GAME.new(false)
	game.save_path = "user://reference_assets_test.json"
	game.backup_path = "user://reference_assets_test_backup.json"
	game.level = 50
	game.coins = 10000
	game.ftue.started = true
	game.ftue.step = "done"
	var owned_key := game.buy_decoration("ref_tenda")
	check(owned_key != "", "New atlas decoration cannot be purchased")
	check(game.stored_decoration_count("ref_tenda") == 1, "Purchased decoration absent from inventory")
	check(game.set_decoration_position(owned_key, Vector2(2100, 2700)), "New decoration cannot be placed")
	game.save_game()
	var restored := GAME.new(false)
	restored.save_path = game.save_path
	restored.backup_path = game.backup_path
	check(restored.load_game(), "Cannot load decoration save")
	var found := false
	for entry in restored.decorations:
		if str(entry.get("key", "")) == owned_key:
			var packed: Array = entry.get("position", [])
			found = packed.size() == 2 and Vector2(float(packed[0]),float(packed[1])).distance_to(Vector2(2100,2700)) < 1.0
	check(found, "Atlas decoration position lost")
	print("REFERENCE_ASSETS_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
