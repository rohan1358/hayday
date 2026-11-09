class_name MarketUI
extends RefCounted

const INK := Color("344b39")
const MUTED := Color("72806d")
const GREEN := Color("368d5b")


static func populate(
	ui: Control,
	list: VBoxContainer,
	game: FarmGameState,
	list_action: Callable,
	cancel_action: Callable
) -> Array[Label]:
	var timers: Array[Label] = []
	var intro: Panel = ui.call("row_card", list, 127, Color("e5f1da"))
	ui.call("label", intro, "LAPAK TETANGGA", Vector2(20, 13), Vector2(560, 35), 24, GREEN, true)
	ui.call(
		"label",
		intro,
		"Pasang hingga 3 barang. Harga 2x jual gudang!",
		Vector2(20, 55),
		Vector2(564, 32),
		17,
		INK
	)
	ui.call(
		"label",
		intro,
		"Transaksi tetap berjalan saat game ditutup.",
		Vector2(20, 88),
		Vector2(565, 25),
		16,
		MUTED
	)
	for index in FarmGameState.MARKET_MAX_SLOTS:
		var slot: Panel = ui.call("row_card", list, 119, Color("fff1d5"))
		if index >= game.market_listings.size():
			ui.call(
				"label",
				slot,
				"LAPAK %d  •  KOSONG" % (index + 1),
				Vector2(22, 17),
				Vector2(555, 38),
				23,
				GREEN,
				true
			)
			ui.call(
				"label",
				slot,
				"Pilih hasil kebun di bawah untuk menjual.",
				Vector2(22, 62),
				Vector2(555, 29),
				16,
				MUTED
			)
			continue
		var sale: Dictionary = game.market_listings[index]
		var info: Dictionary = game.item_info(str(sale["item"]))
		var quantity := int(sale["quantity"])
		var revenue := quantity * int(sale["unit_price"])
		ui.call(
			"label",
			slot,
			"%dx %s" % [quantity, info["name"]],
			Vector2(22, 13),
			Vector2(342, 35),
			22,
			INK,
			true
		)
		ui.call(
			"label", slot, "+%d KOIN" % revenue, Vector2(22, 53), Vector2(235, 29), 19, GREEN, true
		)
		var remaining: Label = ui.call(
			"label", slot, "", Vector2(258, 55), Vector2(145, 26), 16, MUTED
		)
		timers.append(remaining)
		var cancel: Button = ui.call(
			"button", slot, "BATALKAN", Vector2(424, 30), Vector2(154, 58), Color("ead5b3"), INK, 17
		)
		cancel.pressed.connect(func() -> void: cancel_action.call(index))
	ui.call(
		"callout",
		list,
		"PILIH BARANG",
		"Barang berpindah dari gudang saat dipasang.",
		Color("e9f0df")
	)
	for id in game.inventory:
		var item_id: String = id
		var info: Dictionary = game.item_info(item_id)
		var stock := int(game.inventory[item_id])
		var price := int(info["sell"]) * 2
		var card: Panel = ui.call("row_card", list, 113, Color("fff7e6"))
		ui.call("label", card, str(info["name"]), Vector2(20, 10), Vector2(305, 34), 22, INK, true)
		ui.call(
			"label",
			card,
			"%d stok  •  %d koin / barang" % [stock, price],
			Vector2(20, 57),
			Vector2(300, 28),
			16,
			MUTED
		)
		var open_slots := game.market_listings.size() < FarmGameState.MARKET_MAX_SLOTS
		var one: Button = ui.call(
			"button",
			card,
			"PASANG 1",
			Vector2(321, 27),
			Vector2(124, 59),
			GREEN if stock >= 1 and open_slots else Color("b8c5b5"),
			Color.WHITE,
			15
		)
		one.disabled = stock < 1 or not open_slots
		one.pressed.connect(func() -> void: list_action.call(item_id, 1))
		var three: Button = ui.call(
			"button",
			card,
			"PASANG 3",
			Vector2(455, 27),
			Vector2(125, 59),
			GREEN if stock >= 3 and open_slots else Color("b8c5b5"),
			Color.WHITE,
			15
		)
		three.disabled = stock < 3 or not open_slots
		three.pressed.connect(func() -> void: list_action.call(item_id, 3))
	refresh_timers(game, timers)
	return timers


static func refresh_timers(game: FarmGameState, timers: Array[Label]) -> void:
	for index in timers.size():
		if not is_instance_valid(timers[index]) or index >= game.market_listings.size():
			continue
		var left := maxi(0, int(game.market_listings[index]["ready_at"]) - game.now())
		timers[index].text = "%d detik" % left if left > 0 else "TERJUAL!"
