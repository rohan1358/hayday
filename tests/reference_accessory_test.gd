extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
const CAT=preload("res://scripts/wardrobe_catalog.gd")
func _initialize(): call_deferred("run")
func run():
	var game=FarmGameState.new(false)
	game.coins=100
	game.seasonal.accessory_catalog_version=5
	game.seasonal.owned=["wardrobe_v5_3","wardrobe_v5_3","wardrobe_v5_10","outfit3"]
	game.seasonal.wardrobe_slots={"head":3,"neck":10}
	assert(CAT.prepare(game))
	assert(game.coins==175,"Removed paid items refunded once, duplicate ownership is not refunded twice")
	assert("outfit3" in game.seasonal.owned,"Existing costume ownership survives accessory reset")
	assert(game.seasonal.accessory_catalog_version==6)
	assert(game.seasonal.wardrobe_slots==CAT.defaults(game.seasonal.gender))
	assert(not CAT.prepare(game) and game.coins==175,"Migration is idempotent")
	for index in 24:
		var front=ART.directional_accessory(index,0)
		var back=ART.directional_accessory(index,4)
		assert(front!=null and back!=null)
		assert(ART.directional_accessory(index,1)==front)
		assert(ART.directional_accessory(index,3)==back)
		assert(front.get_image().get_data()!=back.get_image().get_data())

	print("REFERENCE ACCESSORY PASS: 24 original paired items, 48 textures, correct view switching, reset/refund once, costume ownership preserved")
	quit()
