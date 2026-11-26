extends Node

signal user_registered
signal registration_failed(message: String)

var firebase_ready := false
var user_uid := ""
var device_id := ""
var plugin
var retry_scheduled := false
var tree_retry_scheduled := false
var tree_write_in_flight := false
var requested_tree_count := -1
var last_synced_tree_count := -1
var observed_tree_count := 0
var pending_tree_chops := 0
var sync_error := ""
var last_reward_request_id := ""


func _ready() -> void:
	name = "FirestoreUser"
	observed_tree_count = maxi(0, get_parent().game.cash_reward_chops_today)
	get_parent().game.cash_reward_progress_changed.connect(_on_tree_progress_changed)
	if OS.get_name() != "Android" or not Engine.has_singleton("FarmUserFirestore"):
		return
	plugin = Engine.get_singleton("FarmUserFirestore")
	device_id = str(plugin.call("getDeviceId"))
	plugin.connect("user_ready", Callable(self, "_on_user_ready"))
	plugin.connect("user_error", Callable(self, "_on_user_error"))
	plugin.connect("cut_down_trees_saved", Callable(self, "_on_tree_sync_saved"))
	plugin.connect("cut_down_trees_error", Callable(self, "_on_tree_sync_error"))
	plugin.connect("cut_down_trees_conflict", Callable(self, "_on_tree_sync_conflict"))
	plugin.connect("user_tree_count_updated", Callable(self, "_on_remote_tree_count_updated"))
	plugin.call("initializeUser")


func _on_user_ready(json: String) -> void:
	var data = JSON.parse_string(json)
	if not data is Dictionary:
		_on_user_error("Respons Firebase pengguna tidak valid.")
		return
	if not data.has("CutDownTreesAmount") or not (data["CutDownTreesAmount"] is int or data["CutDownTreesAmount"] is float):
		_on_user_error("Jumlah pohon belum berhasil dibaca dari Firestore.")
		return
	var remote_tree_count := maxi(0, int(data["CutDownTreesAmount"]))
	user_uid = str(data.get("uid", ""))
	device_id = str(data.get("DeviceID", ""))
	last_reward_request_id = str(data.get("LastRewardRequestID", ""))
	firebase_ready = not user_uid.is_empty() and not device_id.is_empty()
	if firebase_ready:
		tree_write_in_flight = false
		requested_tree_count = -1
		last_synced_tree_count = remote_tree_count
		sync_error = ""
		var game = get_parent().game
		game.cash_reward_chops_today = remote_tree_count + pending_tree_chops
		observed_tree_count = game.cash_reward_chops_today
		pending_tree_chops = 0
		game.save_game()
		game.cash_reward_progress_changed.emit(game.cash_reward_chops_today)
		user_registered.emit()
	else:
		_on_user_error("Firebase belum memberikan identitas pengguna.")


func _on_user_error(message: String) -> void:
	firebase_ready = false
	tree_write_in_flight = false
	sync_error = message
	registration_failed.emit(message)
	push_warning("Firestore user: " + message)
	if plugin != null and not retry_scheduled and is_inside_tree():
		retry_scheduled = true
		get_tree().create_timer(30.0).timeout.connect(func():
			retry_scheduled = false
			if is_inside_tree() and not firebase_ready:
				plugin.call("initializeUser")
		)


func _on_tree_progress_changed(amount: int) -> void:
	if not firebase_ready:
		pending_tree_chops += maxi(0, amount - observed_tree_count)
		observed_tree_count = amount
		return
	observed_tree_count = amount
	_sync_tree_progress()


func _sync_tree_progress() -> void:
	if not firebase_ready or plugin == null or tree_write_in_flight:
		return
	var amount: int = maxi(0, get_parent().game.cash_reward_chops_today)
	if amount == last_synced_tree_count:
		return
	tree_write_in_flight = true
	requested_tree_count = amount
	plugin.call("updateCutDownTreesAmount", amount, last_synced_tree_count)


func _on_tree_sync_saved(amount_text: String) -> void:
	var amount := int(amount_text)
	if not tree_write_in_flight or amount != requested_tree_count:
		return
	tree_write_in_flight = false
	last_synced_tree_count = amount
	sync_error = ""
	print("Firestore User/%s CutDownTreesAmount = %d" % [user_uid, amount])
	# Send the newest value if more trees were chopped during the previous write.
	_sync_tree_progress()
	_refresh_remote_tree_count()


func _on_tree_sync_conflict(amount_text: String) -> void:
	if not tree_write_in_flight:
		return
	tree_write_in_flight = false
	_rebase_remote_tree_count(maxi(0, int(amount_text)))
	_refresh_remote_tree_count()


func _on_remote_tree_count_updated(json: String) -> void:
	var data = JSON.parse_string(json)
	if not data is Dictionary or not firebase_ready:
		return
	if tree_write_in_flight:
		return
	_apply_remote_tree_data(data)


func _apply_remote_tree_data(data: Dictionary) -> void:
	var remote_request_id := str(data.get("LastRewardRequestID", ""))
	if remote_request_id != last_reward_request_id:
		# Reconcile a server-side progress reset.
		last_reward_request_id = remote_request_id
	_rebase_remote_tree_count(maxi(0, int(data.get("CutDownTreesAmount", 0))))


func _refresh_remote_tree_count() -> void:
	if firebase_ready and plugin != null:
		plugin.call("refreshUserTrees")


func _rebase_remote_tree_count(remote_count: int) -> void:
	if remote_count == last_synced_tree_count:
		return
	var game = get_parent().game
	var unsynced_chops: int = maxi(0, game.cash_reward_chops_today - last_synced_tree_count)
	last_synced_tree_count = remote_count
	game.cash_reward_chops_today = remote_count + unsynced_chops
	observed_tree_count = game.cash_reward_chops_today
	sync_error = ""
	game.save_game()
	game.cash_reward_progress_changed.emit(game.cash_reward_chops_today)
	_sync_tree_progress()


func _on_tree_sync_error(message: String) -> void:
	tree_write_in_flight = false
	sync_error = message
	_refresh_remote_tree_count()
	push_warning("Firestore CutDownTreesAmount: " + message)
	if tree_retry_scheduled or not is_inside_tree():
		return
	tree_retry_scheduled = true
	get_tree().create_timer(30.0).timeout.connect(func():
		tree_retry_scheduled = false
		if is_inside_tree():
			_sync_tree_progress()
	)
