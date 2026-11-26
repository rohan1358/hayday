extends SceneTree

const SAVE_FILE := "user://firestore_user_sync_test_save.json"
const BACKUP_FILE := "user://firestore_user_sync_test_backup.json"

class TestHost extends Node:
	var game := FarmGameState.new(false)


class FakeFirestorePlugin extends RefCounted:
	var writes: Array[int] = []
	var expected_counts: Array[int] = []

	func updateCutDownTreesAmount(amount: int, expected_amount: int) -> void:
		writes.append(amount)
		expected_counts.append(expected_amount)

	func refreshUserTrees() -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := TestHost.new()
	host.game.save_path = SAVE_FILE
	host.game.backup_path = BACKUP_FILE
	host.game.cash_reward_chops_today = 19
	root.add_child(host)
	var user := preload("res://scripts/firestore_user.gd").new()
	host.add_child(user)
	var bridge := FakeFirestorePlugin.new()
	user.plugin = bridge

	# The value already saved in Firestore overrides the stale local save.
	user._on_user_ready('{"uid":"user_1","DeviceID":"device_1","CutDownTreesAmount":7}')
	assert(user.firebase_ready)
	assert(host.game.cash_reward_chops_today == 7)
	assert(user.last_synced_tree_count == 7)
	assert(bridge.writes.is_empty())

	host.game.cash_reward_chops_today = 8
	host.game.cash_reward_progress_changed.emit(8)
	assert(bridge.writes == [8])

	host.game.cash_reward_chops_today = 9
	host.game.cash_reward_progress_changed.emit(9)
	assert(bridge.writes == [8])
	user._on_tree_sync_saved("8")
	assert(bridge.writes == [8, 9])
	assert(bridge.expected_counts == [7, 8])

	user._on_tree_sync_error("PERMISSION_DENIED")
	assert(user.sync_error == "PERMISSION_DENIED")
	user._on_tree_sync_saved("9")
	assert(user.sync_error == "PERMISSION_DENIED")
	host.game.cash_reward_chops_today = 10
	user._sync_tree_progress()
	assert(bridge.writes == [8, 9, 10])
	user._on_tree_sync_saved("10")
	assert(user.sync_error.is_empty())
	assert(user.last_synced_tree_count == 10)

	# Chops made while the initial remote read is pending are applied afterward.
	user.firebase_ready = false
	user.observed_tree_count = host.game.cash_reward_chops_today
	host.game.cash_reward_chops_today = 11
	host.game.cash_reward_progress_changed.emit(11)
	assert(user.pending_tree_chops == 1)
	assert(bridge.writes == [8, 9, 10])
	user._on_user_ready('{"uid":"user_1","DeviceID":"device_1","CutDownTreesAmount":22}')
	assert(host.game.cash_reward_chops_today == 23)
	assert(bridge.writes == [8, 9, 10, 23])
	user._on_tree_sync_saved("23")

	# A newly initialized Firestore count of zero must not be overwritten on open.
	user._on_user_ready('{"uid":"user_1","DeviceID":"device_1","CutDownTreesAmount":0}')
	assert(host.game.cash_reward_chops_today == 0)
	assert(bridge.writes == [8, 9, 10, 23])

	# A server-side reset is reflected in the game.
	for count in range(1, 6):
		host.game.cash_reward_chops_today = count
		host.game.cash_reward_progress_changed.emit(count)
		user._on_tree_sync_saved(str(count))
	user._on_remote_tree_count_updated('{"CutDownTreesAmount":0,"LastRewardRequestID":"reset_1"}')
	assert(host.game.cash_reward_chops_today == 0)
	assert(user.last_synced_tree_count == 0)
	for count in range(1, 6):
		host.game.cash_reward_chops_today = count
		host.game.cash_reward_progress_changed.emit(count)
		user._on_tree_sync_saved(str(count))
	# Transaction conflict rebases unsaved chops on a concurrent admin reset.
	host.game.cash_reward_chops_today = 6
	host.game.cash_reward_progress_changed.emit(6)
	user._on_tree_sync_conflict("0")
	assert(host.game.cash_reward_chops_today == 1)
	assert(bridge.writes.back() == 1)
	assert(bridge.expected_counts.back() == 0)
	user._on_tree_sync_saved("1")

	print("FIRESTORE USER SYNC PASS: remote-first hydration, default zero, pending chops, sequential writes, remote reset and conflict reconciliation")
	host.queue_free()
	await process_frame
	for path in [SAVE_FILE, BACKUP_FILE]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()
