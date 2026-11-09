class_name OrchardUI
extends RefCounted

const GREEN := Color("368d5b")
const INK := Color("344b39")
const MUTED := Color("72806d")


static func populate(
	ui: Control,
	list: VBoxContainer,
	game: FarmGameState,
	plant_action: Callable,
	harvest_action: Callable
) -> Array[Dictionary]:
	var status_rows: Array[Dictionary] = []
	var introduction: Panel = ui.call("row_card", list, 146, Color("e3f3d9"))
	ui.call("label", introduction, "KEBUN BUAH", Vector2(20, 15), Vector2(530, 33), 25, GREEN, true)
	ui.call(
		"label",
		introduction,
		"Sentuh pohon di kebun untuk melihat panen.",
		Vector2(20, 55),
		Vector2(550, 31),
		18,
		INK
	)
	ui.call(
		"label",
		introduction,
		"Sekali ditanam, pohon terus berbuah!",
		Vector2(20, 99),
		Vector2(550, 29),
		18,
		MUTED
	)
	for index in FarmGameState.ORCHARD_SIZE:
		var slot: Dictionary = game.orchard[index]
		var fruit_id: String = slot["fruit"]
		var card: Panel = ui.call("row_card", list, 227, Color("fff2d8"))
		if fruit_id == "":
			ui.call(
				"label",
				card,
				"PETAK POHON %d  •  KOSONG" % (index + 1),
				Vector2(20, 15),
				Vector2(570, 39),
				22,
				INK,
				true
			)
			ui.call(
				"label",
				card,
				"Tanam pohon permanen dengan koin.",
				Vector2(21, 62),
				Vector2(550, 28),
				18,
				MUTED
			)
			for fruit_index in FarmGameState.FRUITS.size():
				var id: String = FarmGameState.FRUITS.keys()[fruit_index]
				var info: Dictionary = FarmGameState.FRUITS[id]
				var allowed := game.coins >= int(info["cost"]) and game.level >= int(info["level"])
				var button_x := 21 + fruit_index * 286
				var buy: Button = ui.call(
					"button",
					card,
					"%s  •  %d KOIN" % [info["name"], info["cost"]],
					Vector2(button_x, 124),
					Vector2(272, 69),
					GREEN if allowed else Color("bac5b7"),
					Color.WHITE,
					17
				)
				buy.disabled = not allowed
				buy.pressed.connect(func() -> void: plant_action.call(index, id))
			continue
		var info: Dictionary = FarmGameState.FRUITS[fruit_id]
		ui.call(
			"label",
			card,
			str(info["name"]).to_upper(),
			Vector2(20, 15),
			Vector2(415, 39),
			26,
			GREEN,
			true
		)
		ui.call(
			"label",
			card,
			"Pohon %d  •  %d buah / panen" % [index + 1, info["yield"]],
			Vector2(20, 66),
			Vector2(555, 30),
			18,
			INK
		)
		ui.call(
			"label",
			card,
			"%d koin / buah  •  +%d XP" % [info["sell"], info["xp"]],
			Vector2(20, 103),
			Vector2(555, 29),
			17,
			MUTED
		)
		var status: Label = ui.call(
			"label", card, "", Vector2(20, 172), Vector2(270, 27), 17, GREEN, true
		)
		var collect: Button = ui.call(
			"button",
			card,
			"PANEN BUAH",
			Vector2(326, 148),
			Vector2(254, 61),
			GREEN,
			Color.WHITE,
			19
		)
		collect.pressed.connect(func() -> void: harvest_action.call(index))
		status_rows.append({"index": index, "label": status, "button": collect})
	ui.call(
		"callout",
		list,
		"HASIL PANEN",
		"Buah masuk gudang, dapat dijual di pasar atau gudang.",
		Color("e7f0df")
	)
	refresh_status(game, status_rows)
	return status_rows


static func refresh_status(game: FarmGameState, rows: Array[Dictionary]) -> void:
	for row in rows:
		var index: int = row["index"]
		var status: Label = row["label"]
		var collect: Button = row["button"]
		if not is_instance_valid(status) or not is_instance_valid(collect):
			continue
		var ready := game.tree_ready(index)
		var remaining := maxi(0, int(game.orchard[index]["ready_at"]) - game.now())
		var full := (
			game.storage_used() + int(FarmGameState.FRUITS[game.orchard[index]["fruit"]]["yield"])
			> game.storage_capacity
		)
		status.text = (
			"Gudang penuh!"
			if ready and full
			else "Siap dipanen!" if ready else "Tumbuh %d detik" % remaining
		)
		collect.disabled = not ready or full
		collect.add_theme_stylebox_override("disabled", ui_style(Color("b6c6b0")))


static func ui_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(17)
	return s
