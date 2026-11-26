extends RefCounted

const REGIONS = preload("res://scripts/world_regions.gd")
const UI = preload("res://scripts/ranch_presentation.gd")
const INK := Color("62442f")
const GREEN := Color("239b61")
const CARD_ART := {"sekolah":"region_card_school", "produksi":"region_card_production", "arena":"region_card_arena", "permukiman":"region_card_neighbor"}

static func recipe_text(game, id: String) -> String:
	if not REGIONS.LATE_ACTIVITIES.has(id):
		return ""
	var recipe: Dictionary = REGIONS.LATE_ACTIVITIES[id]
	var inputs: Array[String] = []
	for item in recipe.inputs:
		inputs.append("%s ×%d" % [str(game.item_info(str(item)).get("name", item)), int(recipe.inputs[item])])
	var outputs: Array[String] = []
	for item in recipe.get("outputs", {}):
		outputs.append("%s ×%d" % [str(game.item_info(str(item)).get("name", item)), int(recipe.outputs[item])])
	if int(recipe.get("coins", 0)) > 0:
		outputs.append("%d koin" % int(recipe.coins))
	if int(recipe.get("happiness", 0)) > 0:
		outputs.append("%d bahagia" % int(recipe.happiness))
	return "%s  →  %s" % [", ".join(inputs), ", ".join(outputs)]

static func populate(host, list: VBoxContainer) -> void:
	var state: Dictionary = REGIONS.prepare(host.game)
	host.callout(list, "KAWASAN PULAU", "Bangunan yang dibeli otomatis ditempatkan di area masing-masing. Buka seluruh 25 kawasan untuk menuju pulau musim berikutnya.", Color("fff1cc"))
	var journey=preload("res://scripts/island_journey.gd")
	var world=preload("res://scripts/four_seasons.gd")
	var joy: Panel = host.row_card(list, 76, Color("e7f3d7"))
	host.label(joy, "%s · %d/25 terbuka"%[world.DATA[world.active_id].name,journey.opened(host.game)], Vector2(18, 10), Vector2(430, 30), 21, GREEN, true)
	host.label(joy, "Bahagia %d/100" % int(state.happiness), Vector2(450, 13), Vector2(130, 32), 17, INK, true)
	var priority := str(host.get_meta("selected_region", ""))
	var order: Array = REGIONS.ORDER.duplicate()
	if priority in order:
		order.erase(priority)
		order.push_front(priority)
	for id in order:
		var info: Dictionary = REGIONS.DATA[id]
		var owned: bool = REGIONS.purchased(host.game, str(id))
		var locked: bool = preload("res://scripts/island_journey.gd").city_level(host.game) < int(info.level)
		var has_recipe: bool = REGIONS.LATE_ACTIVITIES.has(id)
		var height := 202 if owned and info.has("cost") else (177 if has_recipe else 142)
		var card: Panel = host.row_card(list, height, Color("f1eddf") if locked else Color("fff7df"))
		card.name = "Region_" + id
		var card_art := str(CARD_ART.get(id, info.get("art", "")))
		if card_art != "": UI.art(host, card, card_art, Vector2(486, 7), Vector2(92, 75))
		var title := str(info.name)
		if owned and info.has("cost"):
			title += "  ·  Tingkat %d/5" % REGIONS.tier(host.game,id)
		host.label(card, title, Vector2(17, 9), Vector2(466 if card_art != "" else 568, 33), 23, INK, true)
		var description: Label = host.label(card, str(info.description), Vector2(18, 44), Vector2(465 if card_art != "" else 565, 35), 17, Color("79684e"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if has_recipe:
			var recipe_label: Label = host.label(card, recipe_text(host.game,id), Vector2(18, 79), Vector2(565, 43), 14, INK)
			recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var status := "TERKUNCI · KOTA LV %d" % int(info.level) if locked else ("SUDAH DIBANGUN" if owned else "TERBUKA · BELUM DIBELI")
		if not info.has("cost") and not locked:
			status = "KAWASAN AKTIF"
		var status_y := 126 if has_recipe else 99
		host.label(card, status, Vector2(18, status_y), Vector2(330, 30), 16, Color("a06535") if locked else GREEN, true)
		var caption := "LIHAT"
		if info.has("cost"):
			caption = "KOTA LV %d" % int(info.level) if locked else ("BELI %d KOIN" % int(info.cost) if not owned else "GUNAKAN")
		var action_y := 111 if has_recipe else 83
		var button: Button = host.button(card, caption, Vector2(360, action_y), Vector2(225, 49), Color("ccbfa4") if locked else GREEN, Color.WHITE, 16)
		button.name = "RegionAction_" + id
		button.disabled = locked
		button.pressed.connect(func() -> void: host.on_world_region_action(id))
		if owned and REGIONS.wait_seconds(host.game, id) > 0 and id not in ["penggilingan","tambang"]:
			button.text = "%d DTK" % REGIONS.wait_seconds(host.game, id)
			button.disabled = true
		if owned and info.has("cost"):
			var upgrade_y := 164
			var cost: Dictionary = REGIONS.upgrade_cost(host.game,id)
			var upgrade_label := "MAKS. TINGKAT 5" if cost.is_empty() else "TINGKAT BERIKUT: %d koin · %d kayu · %d batu" % [int(cost.coins), int(cost.kayu), int(cost.batu)]
			host.label(card, upgrade_label, Vector2(18, upgrade_y), Vector2(370, 27), 14, INK, true)
			if not cost.is_empty():
				var upgrade_button: Button = host.button(card, "TINGKATKAN", Vector2(404, upgrade_y - 4), Vector2(181, 34), GREEN if REGIONS.can_upgrade(host.game,id) else Color("b9aa89"), Color.WHITE, 14)
				upgrade_button.disabled = not REGIONS.can_upgrade(host.game,id)
				upgrade_button.pressed.connect(func() -> void: host.on_world_region_upgrade(id))
