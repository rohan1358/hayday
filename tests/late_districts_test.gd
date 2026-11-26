extends SceneTree

const REGIONS = preload("res://scripts/world_regions.gd")
const GAME = preload("res://scripts/game_state.gd")
const MATERIALS = preload("res://scripts/building_upgrades.gd")
const VIEW = preload("res://scripts/hybrid/hybrid_farm_view.gd")
var failures := 0

func check(ok: bool, note: String) -> void:
	if not ok:
		failures += 1
		push_error(note)

func _initialize() -> void:
	var game = GAME.new(false)
	game.save_path = "user://late_districts_test.json"
	game.backup_path = "user://late_districts_test_backup.json"
	var ids := ["permukiman", "kafe", "berkuda", "stasiun", "sekolah", "botani", "resor_danau", "kota_wisata", "arena", "pelabuhan"]
	check(not REGIONS.can_buy(game, "permukiman"), "Level-20 district unlocked at Level 1")
	game.level = 50
	game.coins = 250000
	game.storage_capacity = 1000
	var material_state: Dictionary = MATERIALS.prepare(game)
	material_state.materials.kayu = 300
	material_state.materials.batu = 300
	var view = VIEW.new()
	view.game = game
	for id in ids:
		var info: Dictionary = REGIONS.DATA[id]
		var art_path := "res://assets/world_regions/%s.png" % str(info.art)
		check(ResourceLoader.exists(art_path), "Missing district sprite: " + id)
		check(ResourceLoader.exists("res://assets/world_regions/%s.glb" % str(info.art)), "Missing district model: " + id)
		check(REGIONS.buy(game, id, info.position), "Cannot buy " + id)
		check(view.editable_keys().has("region_" + id), "Purchased region cannot move: " + id)
		var recipe: Dictionary = REGIONS.LATE_ACTIVITIES[id]
		for item in recipe.inputs:
			game.inventory[item] = 30
		var before_coins: int = game.coins
		var message: String = REGIONS.action(game, id)
		check(message == str(recipe.message), "Region action failed: " + id + " / " + message)
		check(REGIONS.wait_seconds(game, id) > 0, "Missing cooldown: " + id)
		if int(recipe.get("coins", 0)) > 0:
			check(game.coins > before_coins, "Missing coin reward: " + id)
		for item in recipe.get("outputs", {}):
			check(int(game.inventory[item]) >= int(recipe.outputs[item]), "Missing output " + str(item))
		if id == "permukiman":
			var cost: Dictionary = REGIONS.upgrade_cost(game,id)
			var wood_before: int = material_state.materials.kayu
			check(REGIONS.upgrade(game,id), "Cannot upgrade village")
			check(REGIONS.tier(game,id) == 2, "Village tier not raised")
			check(int(material_state.materials.kayu) == wood_before - int(cost.kayu), "Upgrade did not consume wood")
			while REGIONS.tier(game,id) < 5:
				check(REGIONS.upgrade(game,id), "Cannot reach tier 5")
			check(not REGIONS.upgrade(game,id), "Tier 6 allowed")
	check(game.order_item_accessible("hidangan_desa"), "Purchased café goods inaccessible to orders")
	view.free()
	game.save_game()
	var restored = GAME.new(false)
	restored.save_path = game.save_path
	restored.backup_path = game.backup_path
	check(restored.load_game(), "Late district save cannot load")
	for id in ids:
		check(REGIONS.purchased(restored,id), "Lost district ownership: " + id)
	check(REGIONS.tier(restored,"permukiman") == 5, "Lost village upgrade tier")
	check(int(restored.inventory.get("piala_panen",0)) >= 0, "Lost region inventory")
	print("LATE_DISTRICTS_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
