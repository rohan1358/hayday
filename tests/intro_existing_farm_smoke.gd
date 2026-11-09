extends SceneTree

const STARTUP := preload("res://scenes/Startup.tscn")
const OPENING := preload("res://scripts/startup.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ProjectSettings.globalize_path("user://").to_lower().contains("intro_test_appdata"):
		_fail("Test must use an isolated player-data directory")
		return
	var game := FarmGameState.new()
	game.save_game()
	if not FileAccess.file_exists(FarmGameState.SAVE_PATH):
		_fail("Could not create a test farm save")
		return
	if OPENING.should_show_opening():
		_fail("Existing farm would be interrupted by a new opening")
		return
	root.add_child(STARTUP.instantiate())
	await create_timer(0.9).timeout
	if current_scene == null or current_scene.scene_file_path != "res://scenes/Main.tscn":
		_fail("Existing player did not reach farm directly")
		return
	print("INTRO_EXISTING_FARM_PASS old_save_bypasses_opening")
	quit(0)


func _fail(reason: String) -> void:
	push_error("INTRO_EXISTING_FARM_FAIL: " + reason)
	quit(1)
