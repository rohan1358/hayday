extends Control

## The intro is a one-time experience for genuinely new installations.
## Existing farms must keep opening straight into their saved game.
const OPENING_MARKER := "user://kebun_ceria_opening_seen_v1.flag"
const GAME_SCENE := "res://scenes/Main.tscn"
const INTRO_STREAM := preload("res://assets/video/kebun_ceria_opening.ogv")
const MAX_INTRO_SECONDS := 12.0

var opening_player: VideoStreamPlayer
var finishing := false


static func should_show_opening() -> bool:
	return (
		not FileAccess.file_exists(OPENING_MARKER)
		and not FileAccess.file_exists(FarmGameState.SAVE_PATH)
		and not FileAccess.file_exists(FarmGameState.BACKUP_PATH)
	)


func _ready() -> void:
	if not should_show_opening():
		call_deferred("_open_game")
		return

	_build_intro()
	# A damaged/unsupported stream cannot trap the player at the intro.
	get_tree().create_timer(MAX_INTRO_SECONDS).timeout.connect(_finish_intro)


func _build_intro() -> void:
	var background := ColorRect.new()
	background.color = Color("a9dfbc")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	opening_player = VideoStreamPlayer.new()
	opening_player.stream = INTRO_STREAM
	opening_player.expand = true
	opening_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_player.finished.connect(_finish_intro)
	add_child(opening_player)

	var skip_button := Button.new()
	skip_button.text = "LEWATI  ›"
	skip_button.add_theme_font_size_override("font_size", 22)
	skip_button.add_theme_color_override("font_color", Color("29573a"))
	skip_button.add_theme_color_override("font_hover_color", Color("29573a"))
	skip_button.add_theme_color_override("font_pressed_color", Color("29573a"))
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("fff9e5", 0.93)
	button_style.set_corner_radius_all(20)
	button_style.content_margin_left = 21
	button_style.content_margin_right = 21
	button_style.content_margin_top = 12
	button_style.content_margin_bottom = 12
	skip_button.add_theme_stylebox_override("normal", button_style)
	skip_button.add_theme_stylebox_override("hover", button_style)
	skip_button.add_theme_stylebox_override("pressed", button_style)
	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -165
	skip_button.offset_top = 45
	skip_button.offset_right = -20
	skip_button.offset_bottom = 102
	skip_button.pressed.connect(_finish_intro)
	add_child(skip_button)

	opening_player.play()


func _finish_intro() -> void:
	if finishing:
		return
	finishing = true
	if is_instance_valid(opening_player):
		opening_player.stop()
	var marker := FileAccess.open(OPENING_MARKER, FileAccess.WRITE)
	if marker != null:
		marker.store_string("seen\n")
	_open_game.call_deferred()


func _open_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
