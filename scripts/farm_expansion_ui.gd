class_name FarmExpansionUI
extends RefCounted

const GREEN := Color("368d5b")
const INK := Color("344b39")
const MUTED := Color("72806d")
const DISABLED := Color("b9c5b3")
const BUILDING_PREVIEWS := {
	"gazebo":"res://assets/colorful_garden/gazebo.png",
	"kandang_babi": "res://assets/colorful_garden/pig_pen.png",
	"kandang_kambing": "res://assets/colorful_garden/goat_pen.png",
	"pabrik_pakan": "res://assets/colorful_garden/feed_mill_building.png",
	"toko_roti": "res://assets/colorful_garden/bakery_building.png",
	"pabrik_susu": "res://assets/colorful_garden/dairy_building.png",
	"petak_bunga": "res://assets/colorful_garden/flower_garden.png",
	"kolam": "res://assets/colorful_garden/decorative_pond.png"
}


static func populate_animals(
	ui: Control,
	parent: VBoxContainer,
	game: FarmGameState,
	action: Callable,
	buildings_action: Callable,
	selected: String=""
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var heading: Panel = ui.call(
		"callout",
		parent,
		"PETERNAKAN DESA",
		"Rawat hewan untuk bahan dapur dan pasar.",
		Color("e5f2d8")
	)
	heading.custom_minimum_size.y = 105
	var chicken_card: Panel = ui.call("row_card", parent, 172, Color("fff3df"))
	animal_picture(ui,chicken_card,"ayam",Vector2(16,20))
	ui.call("label", chicken_card, "AYAM KAMPUNG", Vector2(88, 20), Vector2(450, 38), 28, INK, true)
	ui.call(
		"label",
		chicken_card,
		"Hasil: 2 Telur tiap 38 detik",
		Vector2(24, 70),
		Vector2(550, 35),
		18,
		GREEN,
		true
	)
	var chicken_status: Label = ui.call(
		"label", chicken_card, "", Vector2(24, 111), Vector2(290, 40), 17, MUTED
	)
	var chicken_button: Button = ui.call(
		"button", chicken_card, "", Vector2(328, 106), Vector2(251, 51), GREEN, Color.WHITE, 18
	)
	chicken_button.pressed.connect(func() -> void: action.call("ayam"))
	rows.append({"id": "ayam", "status": chicken_status, "button": chicken_button})
	for id in FarmGameState.ANIMAL_ORDER:
		if selected!="" and id!=selected: continue
		var info: Dictionary = FarmGameState.ANIMALS[id]
		var owned: bool = game.has_construction(str(info["building"]))
		var card: Panel = ui.call("row_card", parent, 240, Color("fff3df"))
		animal_picture(ui,card,id,Vector2(16,23))
		ui.call(
			"label",
			card,
			str(info["name"]).to_upper(),
			Vector2(88, 20),
			Vector2(475, 38),
			28,
			INK,
			true
		)
		var feed_text := "Paket %d  /  Panen: " % int(game.inventory.get("pakan_" + id, 0))
		for ingredient in info["feed"]:
			feed_text += (
				"%s %d/%d  "
				% [
					str(game.item_info(ingredient)["name"]),
					int(game.inventory.get(ingredient, 0)),
					int(info["feed"][ingredient]),
				]
			)
		ui.call(
			"label", card, feed_text.strip_edges(), Vector2(24, 79), Vector2(560, 33), 17, MUTED
		)
		ui.call(
			"label",
			card,
			(
				"Hasil: %d %s  •  %d detik"
				% [
					int(info["yield"]),
					str(game.item_info(info["item"])["name"]),
					int(info["seconds"])
				]
			),
			Vector2(24, 117),
			Vector2(570, 32),
			18,
			GREEN,
			true
		)
		var status: Label = ui.call(
			"label", card, "", Vector2(24, 151), Vector2(559, 30), 17, MUTED
		)
		var button: Button = ui.call(
			"button", card, "", Vector2(325, 176), Vector2(256, 51), GREEN, Color.WHITE, 18
		)
		var current_id: String = id
		if owned:
			button.pressed.connect(func() -> void: action.call(current_id))
		else:
			button.pressed.connect(buildings_action)
		rows.append({"id": id, "status": status, "button": button})
	if selected!="":
		chicken_card.queue_free()
		rows=rows.filter(func(row): return str(row.id)==selected)
	refresh_animals(game, rows)
	return rows


static func refresh_animals(game: FarmGameState, rows: Array[Dictionary]) -> void:
	for row in rows:
		var id: String = row["id"]
		var status: Label = row["status"]
		var button: Button = row["button"]
		if not is_instance_valid(status) or not is_instance_valid(button):
			continue
		if id == "ayam":
			var ready := game.ready_eggs()
			var full := game.storage_used() + game.ranch_yield("ayam") > game.storage_capacity
			status.text = (
				"%d telur siap diambil!"%game.ranch_yield("ayam")
				if ready
				else "Siap %d detik lagi" % maxi(0, game.eggs_ready_at - game.now())
			)
			button.text = (
				"BUKA GUDANG ›" if ready and full else "AMBIL TELUR" if ready else "MENUNGGU TELUR"
			)
			button.disabled = not ready
			continue
		var info: Dictionary = FarmGameState.ANIMALS[id]
		if not game.has_construction(str(info["building"])):
			status.text = "Belum punya kandang. Beli di menu Bangun."
			button.text = "BANGUN KANDANG"
			button.disabled = false
		elif game.animal_hungry(id):
			var missing := game.missing_animal_feed(id)
			if missing.is_empty():
				status.text = "Pakan siap. Beri makan untuk mulai produksi."
			else:
				var shortages: Array[String] = []
				for ingredient in missing:
					shortages.append("%s +%d" % [game.item_info(ingredient)["name"], missing[ingredient]])
				status.text = "Kurang: %s" % ", ".join(shortages)
			button.text = "BERI PAKAN"
			button.disabled = not game.can_feed_animal(id)
		elif game.animal_ready(id):
			status.text = "Hasil ternak siap dikumpulkan!"
			button.text = (
				"BUKA GUDANG ›"
				if game.storage_used() + game.ranch_yield(id) > game.storage_capacity
				else "AMBIL HASIL"
			)
			button.disabled = false
		else:
			status.text = (
				"Hasil siap dalam %d detik" % maxi(0, int(game.livestock[id]) - game.now())
			)
			button.text = "SEDANG PRODUKSI"
			button.disabled = true


static func populate_buildings(
	ui: Control, parent: VBoxContainer, game: FarmGameState, purchase: Callable
) -> void:
	preload("res://scripts/farm_progression.gd").cow_shop(ui,parent,game)
	ui.call(
		"callout",
		parent,
		"BANGUN PERTANIAN",
		"Beli kandang, rumah produksi, dan dekorasi.",
		Color("e4f0d8")
	)
	_build_group(ui, parent, game, "BANGUNAN FUNGSIONAL", FarmGameState.BUILDING_ORDER, purchase)
	_build_group(ui, parent, game, "DEKORASI KEBUN", FarmGameState.DECOR_ORDER, purchase)
	ui.call(
		"callout",
		parent,
		"PERLUAS LAHAN",
		"Ketuk petak bertanda + di kebun untuk membeli lahan.",
		Color("fff0d4")
	)


static func _build_group(
	ui: Control,
	parent: VBoxContainer,
	game: FarmGameState,
	name: String,
	ids: Array,
	purchase: Callable
) -> void:
	var title: Panel = ui.call("row_card", parent, 57, Color("dcead3"))
	ui.call("label", title, name, Vector2(17, 11), Vector2(559, 34), 22, GREEN, true)
	for id in ids:
		var info: Dictionary = FarmGameState.CONSTRUCTIONS[id]
		var count := game.construction_count(id)
		var max_count := 3 if id == "petak_bunga" else 1
		var owned := count >= max_count
		var required_level: int = 1 if id in ["toko_roti","pabrik_susu"] else (maxi(3 if id.begins_with("kandang_") else 5,int(info["level"])) if not game.ftue.is_empty() else int(info["level"]))
		var unlocked := game.level >= required_level
		var can_buy := not owned and unlocked and game.coins >= int(info["cost"])
		var card: Panel = ui.call("row_card", parent, 157, Color("fff4e2"))
		if BUILDING_PREVIEWS.has(id) and ResourceLoader.exists(BUILDING_PREVIEWS[id]):
			var thumbnail := TextureRect.new()
			thumbnail.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			thumbnail.position = Vector2(5, 7)
			thumbnail.size = Vector2(78, 89)
			thumbnail.texture = load(BUILDING_PREVIEWS[id]) as Texture2D
			thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(thumbnail)
		else:
			preload("res://scripts/colorful_icons.gd").add(card,"bangun",Vector2(12,20),Vector2(62,62))
		ui.call("label", card, str(info["name"]), Vector2(87, 13), Vector2(345, 41), 25, INK, true)
		ui.call(
			"label", card, str(info["description"]), Vector2(87, 56), Vector2(477, 38), 17, MUTED
		)
		ui.call(
			"label",
			card,
			(
				"%d koin  •  Level %d  •  Dimiliki %d/%d"
				% [int(info["cost"]), required_level, count, max_count]
			),
			Vector2(23, 112),
			Vector2(425, 31),
			17,
			GREEN,
			true
		)
		var label_text := (
			"DIMILIKI" if owned else "LV %d" % required_level if not unlocked else "BELI"
		)
		var buy: Button = ui.call(
			"button",
			card,
			label_text,
			Vector2(447, 99),
			Vector2(135, 50),
			GREEN if can_buy else DISABLED,
			Color.WHITE,
			17
		)
		buy.disabled = not can_buy
		var current_id: String = id
		buy.pressed.connect(func() -> void: purchase.call(current_id))


static func animal_picture(ui,parent: Node,species: String,at: Vector2) -> void:
	var icon=preload("res://scripts/colorful_icons.gd").add(parent,"hewan",at,Vector2(60,60))
	if ui.farm.ranch_animator!=null: icon.texture=ui.farm.ranch_animator.frames.get(species+"0",icon.texture)
