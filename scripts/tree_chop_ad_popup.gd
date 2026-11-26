extends Control

signal confirmed
signal canceled

const CARD_SIZE := Vector2(610, 654)
const INK := Color("62442f")
const SOFT_INK := Color("8e765a")

var host
var card: Panel
var quota_label: Label
var shown_scale := 1.0
var previous_modal := false
var previous_farm_obscured := false


func _ready() -> void:
	name = "TreeChopAdPopup"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var shade := ColorRect.new()
	shade.name = "DimBackground"
	shade.color = Color(0.08, 0.15, 0.08, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	card = _panel(self, "ConfirmationCard", Vector2.ZERO, CARD_SIZE, Color("fff3d2"), Color("bc8243"), 32, 6)
	card.pivot_offset = CARD_SIZE * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	_panel(card, "TitleBoard", Vector2(23, 24), Vector2(564, 102), Color("de9b42"), Color("a76330"), 23, 4)
	var heading := _label(card, "Batas tebang pohon harian", Vector2(45, 51), Vector2(480, 52), 29, Color("fff9e8"), true)
	heading.add_theme_color_override("font_outline_color", Color("80501b"))
	heading.add_theme_constant_override("outline_size", 3)

	var close_button := _button("CloseButton", "×", Vector2(544, 43), Vector2(41, 42), Color("e7503f"), Color("ffc4a2"), Color.WHITE, 28)
	card.add_child(close_button)
	close_button.pressed.connect(_cancel)

	_panel(card, "TreeIconBackdrop", Vector2(231, 150), Vector2(148, 140), Color("dfedcc"), Color("b1d18d"), 65, 3)
	var tree_icon := TextureRect.new()
	tree_icon.name = "TreeIcon"
	tree_icon.texture = preload("res://assets/cheerful/pohon.png")
	tree_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tree_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tree_icon.position = Vector2(239, 155)
	tree_icon.size = Vector2(132, 129)
	tree_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tree_icon)

	_panel(card, "DailyLimitBadge", Vector2(135, 305), Vector2(340, 48), Color("ffdf94"), Color("d7a64a"), 24, 2)
	quota_label = _label(card, "", Vector2(146, 314), Vector2(318, 29), 19, INK, true)
	quota_label.name = "DailyLimitLabel"

	var explanation := _label(card, "Jatah tebang gratis hari ini sudah habis.\nTonton iklan berhadiah untuk melanjutkan?", Vector2(42, 371), Vector2(526, 79), 23, INK)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_panel(card, "RewardInfo", Vector2(47, 461), Vector2(516, 57), Color("e8f3d8"), Color("c8dfac"), 19, 2)
	_label(card, "1 iklan = 1 kesempatan tebang tambahan", Vector2(61, 474), Vector2(488, 31), 21, SOFT_INK, true)

	var watch_button := _button("WatchRewardedAd", "TONTON IKLAN BERHADIAH", Vector2(54, 530), Vector2(502, 62), Color("239b61"), Color("f3cb68"), Color.WHITE, 24)
	card.add_child(watch_button)
	watch_button.pressed.connect(_confirm)

	var cancel_button := _button("CancelButton", "Batal", Vector2(175, 600), Vector2(260, 40), Color("fff4d9"), Color("dfc69c"), INK, 21)
	card.add_child(cancel_button)
	cancel_button.pressed.connect(_cancel)

	resized.connect(_arrange)
	_arrange()


func show_offer() -> void:
	if visible:
		return
	_update_quota_label()
	previous_modal = bool(host.get_meta("first_farm_modal", false))
	previous_farm_obscured = host.farm.panel_obscured
	host.set_meta("first_farm_modal", true)
	host.farm.set_panel_obscured(true)
	show()
	_arrange()
	card.modulate.a = 0.0
	card.scale = Vector2.ONE * shown_scale * 0.90
	var entrance := card.create_tween().set_parallel(true)
	entrance.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(card, "scale", Vector2.ONE * shown_scale, 0.26)
	entrance.tween_property(card, "modulate:a", 1.0, 0.18)


func _update_quota_label() -> void:
	var limit: int = host.game.max_daily_free_tree_cuts
	quota_label.text = "%d/%d TEBANG GRATIS TERPAKAI" % [mini(host.game.wild_tree_chops_today, limit), limit]


func refresh_quota() -> void:
	if host.game.can_chop_wild_tree() or host.game.wild_tree_chop_cooling_down():
		_cancel()
	else:
		_update_quota_label()


func _arrange() -> void:
	if card == null:
		return
	shown_scale = clampf(minf((size.x - 36.0) / CARD_SIZE.x, (size.y - 70.0) / CARD_SIZE.y), 0.25, 1.0)
	card.scale = Vector2.ONE * shown_scale
	card.position = (size - CARD_SIZE) * 0.5


func _confirm() -> void:
	_close()
	confirmed.emit()


func _cancel() -> void:
	_close()
	canceled.emit()


func _close() -> void:
	if not visible:
		return
	hide()
	host.set_meta("first_farm_modal", previous_modal)
	host.farm.set_panel_obscured(previous_farm_obscured)


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()


func _panel(parent: Control, node_name: String, at: Vector2, dimensions: Vector2, background: Color, border: Color, radius: int, border_width: int) -> Panel:
	var result := Panel.new()
	result.name = node_name
	result.set_meta("colorful_applied", true)
	result.position = at
	result.size = dimensions
	var skin := StyleBoxFlat.new()
	skin.bg_color = background
	skin.border_color = border
	skin.set_corner_radius_all(radius)
	skin.set_border_width_all(border_width)
	if node_name == "ConfirmationCard":
		skin.shadow_color = Color(0.20, 0.12, 0.06, 0.26)
		skin.shadow_size = 16
		skin.shadow_offset = Vector2(0, 10)
	result.add_theme_stylebox_override("panel", skin)
	parent.add_child(result)
	return result


func _label(parent: Control, content: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color, bold: bool = false) -> Label:
	var result := Label.new()
	result.set_meta("typography_extent", dimensions)
	result.text = content
	result.position = at
	result.size = dimensions
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	if bold:
		result.add_theme_font_override("font", preload("res://assets/fonts/styles/fredoka_bold.tres"))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


func _button(node_name: String, caption: String, at: Vector2, dimensions: Vector2, background: Color, border: Color, text_color: Color, font_size: int) -> Button:
	var result := Button.new()
	result.name = node_name
	result.set_meta("colorful_applied", true)
	result.text = caption
	result.position = at
	result.size = dimensions
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		result.add_theme_color_override(state, text_color)
	for state in ["normal", "hover", "pressed"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = background.lightened(0.08) if state == "hover" else (background.darkened(0.09) if state == "pressed" else background)
		skin.border_color = border
		skin.set_corner_radius_all(18)
		skin.set_border_width_all(3)
		result.add_theme_stylebox_override(state, skin)
	return result
