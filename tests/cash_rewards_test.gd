extends SceneTree

const SAVE_FILE := "user://cash_rewards_test_save.json"
const BACKUP_FILE := "user://cash_rewards_test_backup.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in [SAVE_FILE, BACKUP_FILE]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = SAVE_FILE
	host.game.backup_path = BACKUP_FILE
	root.add_child(host)
	for i in 4:
		await process_frame

	var config = host.get_node("TreeCountConfig")
	var user = host.get_node("FirestoreUser")
	assert(host.get_node_or_null("CashRewardsUI") == null)
	assert(host.get_node_or_null("CashRewardsPopupLayer") == null)
	assert(host.get_node("CheerfulHeader").get_node_or_null("CashRewardsShortcut") == null)
	assert(not user.has_method("create_reward_request"))
	assert(not user.has_method("save_phone_number"))
	assert(not user.has_signal("reward_history_updated"))
	assert(not host.game.has_method("request_cash_reward_claim"))
	host.game.ftue.started = true
	host.game.ftue.step = "done"
	host.set_meta("first_farm_modal", false)
	host.switch_tab("hadiah_pemula")
	assert(host.sheet.find_child("OpenCashRewardsFromGift", true, false) == null)

	config._on_config_ready('{"IsEmulator":true,"AllowEmulator":true,"AllowAllRegion":true}')
	assert(not host.game.cash_reward_real_device and host.game.cash_reward_allow_emulator)
	assert(host.game.cash_reward_region_allowed())
	config._on_config_ready('{"IsEmulator":false,"AllowEmulator":false,"AllowAllRegion":false,"AllowedRegion":[{"code":"JP"}]}')
	assert(host.game.cash_reward_real_device and not host.game.cash_reward_allow_emulator)
	assert(not host.game.cash_reward_region_allowed())
	host.game.cash_reward_ip_country = "JP"
	assert(host.game.cash_reward_region_allowed())

	config._on_config_ready('{"AllowAllRegion":true}')
	host.set_meta("settings_category", 7)
	host.switch_tab("pengaturan")
	assert(host.sheet.find_child("SettingsCountryRegion", true, false) == null)
	assert(not config.ip_country_pending)
	# Simulate the region check used by the runtime, independently of settings.
	config._on_config_ready('{"AllowAllRegion":false,"AllowedRegion":[{"code":"JP"}]}')
	config.tracks_reward_region = true
	config._on_ip_country_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "jp\n".to_utf8_buffer())
	assert(host.game.cash_reward_ip_country == "JP")
	assert(host.game.cash_reward_region_allowed())
	config._on_ip_country_completed(HTTPRequest.RESULT_SUCCESS, 429, PackedStringArray(), PackedByteArray())
	assert(host.game.cash_reward_ip_country.is_empty())
	assert(not host.game.cash_reward_region_allowed())

	host.queue_free()
	await process_frame
	for path in [SAVE_FILE, BACKUP_FILE]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CASH REWARDS REMOVAL PASS")
	quit()
