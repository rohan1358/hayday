extends SceneTree

const STARTUP := preload("res://scenes/Startup.tscn")
const OPENING := preload("res://scripts/startup.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var data_directory := ProjectSettings.globalize_path("user://")
	if not data_directory.to_lower().contains("intro_test_appdata"):
		_fail("Refusing to use real player data: " + data_directory)
		return
	if not OPENING.should_show_opening():
		_fail("Expected intro on a fresh installation")
		return

	var startup := STARTUP.instantiate()
	root.add_child(startup)
	await create_timer(0.7).timeout
	var player := startup.get("opening_player") as VideoStreamPlayer
	if player == null or not player.is_playing():
		_fail("Intro video failed to start")
		return
	if player.stream_position <= 0.05:
		_fail("Intro did not advance: " + str(player.stream_position))
		return
	var observed_position := player.stream_position

	var skip: Button
	for node in startup.get_children():
		if node is Button and "LEWATI" in node.text:
			skip = node
			break
	if skip == null:
		_fail("Skip button is missing")
		return
	skip.pressed.emit()
	await create_timer(0.7).timeout
	if not FileAccess.file_exists("user://kebun_ceria_opening_seen_v1.flag"):
		_fail("Skip did not persist the intro marker")
		return
	if OPENING.should_show_opening():
		_fail("Opening would replay after its first display")
		return
	if current_scene == null or current_scene.scene_file_path != "res://scenes/Main.tscn":
		_fail("Skip did not reach the farm scene")
		return
	print("INTRO_SMOKE_PASS video_progress=%.2fs, skip, persistence, farm_scene" % observed_position)
	quit(0)


func _fail(reason: String) -> void:
	push_error("INTRO_SMOKE_FAIL: " + reason)
	quit(1)
