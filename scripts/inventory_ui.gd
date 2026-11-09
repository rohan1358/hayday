class_name InventoryUI
extends RefCounted

const GREEN := Color("368d5b")
const INK := Color("344b39")
const SOFT_INK := Color("72806d")


static func populate(
	ui: Control,
	list: VBoxContainer,
	game: FarmGameState,
	upgrade_action: Callable,
	sell_action: Callable,
	reset_action: Callable
) -> void:
	var capacity_card: Panel = ui.call("row_card", list, 163, Color("e5f2d8"))
	ui.call(
		"label",
		capacity_card,
		"KAPASITAS GUDANG",
		Vector2(22, 19),
		Vector2(400, 26),
		17,
		GREEN,
		true
	)
	ui.call(
		"label",
		capacity_card,
		str(game.storage_used()) + " / " + str(game.storage_capacity),
		Vector2(21, 52),
		Vector2(310, 41),
		31,
		INK,
		true
	)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.position = Vector2(21, 115)
	bar.size = Vector2(358, 17)
	bar.max_value = game.storage_capacity
	bar.value = game.storage_used()
	bar.add_theme_stylebox_override("background", ui.call("style", Color("c7dac0"), 10))
	var usage: float = float(game.storage_used()) / float(maxi(1, game.storage_capacity))
	var bar_color := Color("c65d4b") if usage >= 1.0 else Color("dc9845") if usage >= 0.85 else GREEN
	bar.add_theme_stylebox_override("fill", ui.call("style", bar_color, 10))
	capacity_card.add_child(bar)
	if usage >= 0.85:
		var warning := "GUDANG PENUH!" if usage >= 1.0 else "HAMPIR PENUH"
		ui.call("label", capacity_card, warning, Vector2(191, 89), Vector2(200, 24), 16, bar_color, true)
	var up_cost := 180 + (game.storage_capacity - 60) * 3
	var upgrade: Button = ui.call(
		"button",
		capacity_card,
		"+30  •  " + str(up_cost) + " KOIN",
		Vector2(391, 61),
		Vector2(196, 57),
		GREEN if game.coins >= up_cost else Color("b9c5b3"),
		Color.WHITE,
		16
	)
	upgrade.disabled = game.coins < up_cost
	upgrade.pressed.connect(upgrade_action)
	var groups := group_items(game)
	var stocked: Array[String] = groups["stocked"]
	var empty: Array[String] = groups["empty"]
	var stock_header: Panel = ui.call("row_card", list, 70, Color("e5f2d8"))
	ui.call(
		"label", stock_header, "BARANG TERSEDIA  •  %d JENIS" % stocked.size(),
		Vector2(20, 16), Vector2(560, 40), 20, GREEN, true
	)
	if stocked.is_empty():
		var empty_notice: Panel = ui.call("row_card", list, 88, Color("fff4df"))
		ui.call(
			"label", empty_notice, "Belum ada stok. Panen atau ambil hasil produksi.",
			Vector2(20, 20), Vector2(565, 52), 18, SOFT_INK
		)
	for id in stocked:
		add_item_row(ui, list, game, id, sell_action, false)
	if not empty.is_empty():
		var toggle_card: Panel = ui.call("row_card", list, 89, Color("edf1e8"))
		var toggle: Button = ui.call(
			"button", toggle_card, "LIHAT BARANG KOSONG (%d)" % empty.size(),
			Vector2(20, 12), Vector2(561, 65), Color("d7e4d2"), INK, 18
		)
		toggle.name = "ToggleEmptyStock"
		var empty_group := VBoxContainer.new()
		empty_group.name = "EmptyStockRows"
		empty_group.add_theme_constant_override("separation", 17)
		empty_group.visible = false
		list.add_child(empty_group)
		# The empty item controls are only created on demand to keep the
		# inventory responsive on Android, especially with many recipes.
		toggle.pressed.connect(func() -> void:
			if empty_group.get_child_count() == 0:
				for item_id in empty:
					add_item_row(ui, empty_group, game, item_id, sell_action, true)
			empty_group.visible = not empty_group.visible
			toggle.text = "SEMBUNYIKAN BARANG KOSONG" if empty_group.visible else "LIHAT BARANG KOSONG (%d)" % empty.size()
		)
	var reset_row: Panel = ui.call("row_card", list, 108, Color("f8e9db"))
	ui.call(
		"label", reset_row, "Mulai dari awal?", Vector2(20, 22), Vector2(326, 45), 21, INK, true
	)
	var reset: Button = ui.call(
		"button",
		reset_row,
		"GAME BARU",
		Vector2(395, 22),
		Vector2(187, 57),
		Color("d7987d"),
		Color.WHITE,
		17
	)
	reset.pressed.connect(reset_action)


static func group_items(game: FarmGameState) -> Dictionary:
	var stocked: Array[String] = []
	var empty: Array[String] = []
	for id in game.inventory:
		if int(game.inventory[id]) > 0:
			stocked.append(str(id))
		else:
			empty.append(str(id))
	return {"stocked": stocked, "empty": empty}


static func add_item_row(
	ui: Control, list: VBoxContainer, game: FarmGameState, id: String,
	sell_action: Callable, is_empty: bool
) -> void:
	var amount: int = game.inventory[id]
	var info: Dictionary = game.item_info(id)
	var name: String = str(info["name"])
	var price: int = int(info["sell"])
	var item: Panel = ui.call("row_card", list, 192, Color("fff4df"))
	item.name = ("EmptyRow_" if is_empty else "StockRow_") + id
	item.add_child(ui.call("circle", Vector2(43, 45), 24, Color(info["color"])))
	ui.call("label", item, name, Vector2(79, 16), Vector2(278, 32), 23, INK, true)
	ui.call(
		"label", item, str(amount) + " stok  ·  " + str(price) + " koin/satuan",
		Vector2(79, 51), Vector2(450, 27), 17, SOFT_INK
	)
	var order_need := 0
	for order in game.orders:
		order_need += int(order.get("items", {}).get(id, 0))
	if order_need > 0 and not is_empty:
		ui.call(
			"label", item, "DIBUTUHKAN PESANAN: %d" % order_need,
			Vector2(79, 78), Vector2(480, 22), 15, Color("aa762f"), true
		)
	for option in [
		{"label": "JUAL 1", "quantity": 1, "x": 20},
		{"label": "JUAL 5", "quantity": 5, "x": 217},
		{"label": "JUAL SEMUA", "quantity": amount, "x": 414},
	]:
		var quantity: int = option["quantity"]
		var free_quantity: int = maxi(0, amount - order_need)
		var enabled := quantity > 0 and amount >= quantity
		var sell: Button = ui.call(
			"button", item, str(option["label"]),
			Vector2(float(option["x"]), 104 if order_need > 0 and not is_empty else 90),
			Vector2(175, 72 if order_need > 0 and not is_empty else 86),
			GREEN if enabled else Color("c1caba"), Color.WHITE if enabled else INK, 17
		)
		sell.disabled = not enabled
		sell.tooltip_text = "Jual %d %s (+%d koin)" % [quantity, name, quantity * price]
		sell.pressed.connect(func() -> void:
			if quantity <= free_quantity:
				sell_action.call(id, quantity)
				return
			var confirmation := ConfirmationDialog.new()
			confirmation.name = "ConfirmSaleReservedStock"
			confirmation.title = "Barang diperlukan pesanan"
			confirmation.dialog_text = (
				"Menjual %d %s akan menyisakan %d stok, sedangkan pesanan aktif "
				+ "membutuhkan %d. Tetap jual?"
			) % [quantity, name, amount - quantity, order_need]
			confirmation.ok_button_text = "Tetap jual"
			confirmation.cancel_button_text = "Batal"
			confirmation.min_size = Vector2i(480, 220)
			ui.add_child(confirmation)
			confirmation.confirmed.connect(func() -> void: sell_action.call(id, quantity))
			confirmation.confirmed.connect(confirmation.queue_free)
			confirmation.canceled.connect(confirmation.queue_free)
			confirmation.popup_centered()
		)
