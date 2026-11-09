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
		_fail("Opening was unexpectedly skipped on a fresh installation")
		return
	root.add_child(STARTUP.instantiate())
	await create_timer(9.5).timeout
	if not FileAccess.file_exists("user://kebun_ceria_opening_seen_v1.flag"):
		_fail("Opening did not persist its finish marker")
		return
	if current_scene == null or current_scene.scene_file_path != "res://scenes/Main.tscn":
		_fail("Opening did not proceed to farm after video finished")
		return
	print("INTRO_NATURAL_PASS video_finished, marker_written, farm_scene")
	quit(0)


func _fail(reason: String) -> void:
	push_error("INTRO_NATURAL_FAIL: " + reason)
	quit(1)
