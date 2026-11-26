extends Node

const IP_COUNTRY_URL := "https://ipapi.co/country/"
const IP_COUNTRY_REFRESH_SECONDS := 300.0
const IP_COUNTRY_RETRY_SECONDS := 60.0

var host
var ip_country_request: HTTPRequest
var ip_country_timer: Timer
var ip_country_pending := false
var tracks_reward_region := false


func _ready() -> void:
	host = get_parent()
	name = "TreeCountConfig"
	ip_country_request = HTTPRequest.new()
	ip_country_request.timeout = 12.0
	ip_country_request.body_size_limit = 1024
	add_child(ip_country_request)
	ip_country_request.request_completed.connect(_on_ip_country_completed)
	ip_country_timer = Timer.new()
	ip_country_timer.one_shot = true
	add_child(ip_country_timer)
	ip_country_timer.timeout.connect(_refresh_ip_country)
	tracks_reward_region = OS.get_name() == "Android" and Engine.has_singleton("FarmRemoteConfig")
	if tracks_reward_region:
		var remote := Engine.get_singleton("FarmRemoteConfig")
		remote.connect("config_ready", Callable(self, "_on_config_ready"))
		_on_config_ready(str(remote.call("getConfigJson")))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(ip_country_request) and _should_refresh_ip_country():
		ip_country_request.cancel_request()
		ip_country_pending = false
		_refresh_ip_country()


func _normalize_country_code(value: Variant) -> String:
	if not value is String:
		return ""
	var code := str(value).strip_edges().to_upper()
	if code.length() != 2:
		return ""
	for character in code:
		if not "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(character):
			return ""
	return code


func _should_refresh_ip_country() -> bool:
	return tracks_reward_region and not host.game.cash_reward_allow_all_regions


func _apply_region_config(values: Dictionary) -> void:
	var previously_allowed_all: bool = host.game.cash_reward_allow_all_regions
	host.game.cash_reward_allow_all_regions = values.get("AllowAllRegion", false) == true
	var regions = values.get("AllowedRegion", [])
	if regions is String:
		var parser := JSON.new()
		regions = parser.data if parser.parse(regions) == OK else []
	var codes: Array[String] = []
	if regions is Array:
		for entry in regions:
			if entry is Dictionary:
				var code := _normalize_country_code(entry.get("code", ""))
				if not code.is_empty() and code not in codes:
					codes.append(code)
	host.game.cash_reward_allowed_regions = codes
	if is_instance_valid(ip_country_request):
		if not _should_refresh_ip_country():
			ip_country_request.cancel_request()
			ip_country_pending = false
			ip_country_timer.stop()
			host.game.cash_reward_ip_country = ""
		elif not ip_country_pending and (ip_country_timer.is_stopped() or (previously_allowed_all and not host.game.cash_reward_allow_all_regions)):
			_refresh_ip_country()


func _refresh_ip_country() -> void:
	if not _should_refresh_ip_country() or ip_country_pending:
		return
	ip_country_timer.stop()
	host.game.cash_reward_ip_country = ""
	var error := ip_country_request.request(IP_COUNTRY_URL)
	ip_country_pending = error == OK
	if error != OK:
		ip_country_timer.start(IP_COUNTRY_RETRY_SECONDS)


func _on_ip_country_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	ip_country_pending = false
	if not _should_refresh_ip_country():
		return
	var code := ""
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		code = _normalize_country_code(body.get_string_from_utf8())
	host.game.cash_reward_ip_country = code
	ip_country_timer.start(IP_COUNTRY_RETRY_SECONDS if code.is_empty() else IP_COUNTRY_REFRESH_SECONDS)


func _cooldown_range(value: Variant, defaults: Vector2i) -> Vector2i:
	if value is String:
		var parser := JSON.new()
		value = parser.data if parser.parse(value) == OK else {}
	if value is Dictionary:
		var remote_min: Variant = value.get("min")
		var remote_max: Variant = value.get("max")
		if (remote_min is int or remote_min is float) and (remote_max is int or remote_max is float):
			if remote_min >= 0 and remote_max >= remote_min and remote_max <= 2147483647:
				if floor(float(remote_min)) == remote_min and floor(float(remote_max)) == remote_max:
					return Vector2i(int(remote_min), int(remote_max))
	return defaults


func _apply_cooldown_config(value: Variant) -> void:
	var interval := _cooldown_range(value, Vector2i(FarmGameState.WILD_TREE_COOLDOWN_MIN_SECONDS, FarmGameState.WILD_TREE_COOLDOWN_MAX_SECONDS))
	host.game.wild_tree_cooldown_min_seconds = interval.x
	host.game.wild_tree_cooldown_max_seconds = interval.y


func _apply_spawn_cooldown_config(value: Variant) -> void:
	var interval := _cooldown_range(value, Vector2i(FarmGameState.WILD_TREE_SPAWN_MIN_SECONDS, FarmGameState.WILD_TREE_SPAWN_MAX_SECONDS))
	host.game.wild_tree_spawn_min_seconds = interval.x
	host.game.wild_tree_spawn_max_seconds = interval.y


func _apply_max_standing_trees(value: Variant) -> void:
	var maximum := FarmGameState.DEFAULT_MAX_STANDING_TREES
	if value is int or value is float:
		if value >= 0 and value <= FarmGameState.WILD_TREE_ID_CAPACITY and floor(float(value)) == value:
			maximum = int(value)
	host.game.max_standing_trees = maximum
	var farm = host.get("farm")
	if farm is FarmView:
		farm.reserve_wild_tree_slots(maximum)


func _apply_max_daily_free_tree_cuts(value: Variant) -> void:
	var maximum := FarmGameState.WILD_TREE_DAILY_LIMIT
	if value is int or value is float:
		if value >= 0 and value <= 2147483647 and floor(float(value)) == value:
			maximum = int(value)
	host.game.max_daily_free_tree_cuts = maximum
	if host is Node:
		var dialog = host.get("tree_chop_ad_dialog")
		if is_instance_valid(dialog) and dialog.visible:
			dialog.refresh_quota()


func _on_config_ready(json: String) -> void:
	var values = JSON.parse_string(json)
	if values is Dictionary:
		host.game.cash_reward_real_device = values.get("IsEmulator", true) == false
		host.game.cash_reward_allow_emulator = values.get("AllowEmulator", false) == true
		_apply_region_config(values)
		_apply_cooldown_config(values.get("CooldownCutDownTrees", {}))
		_apply_spawn_cooldown_config(values.get("CooldownSpawnTrees", {}))
		_apply_max_standing_trees(values.get("MaxStandingTrees"))
		_apply_max_daily_free_tree_cuts(values.get("MaxDailyFreeTreeCuts"))
		print("TreeCountConfig: real_device=%s AllowEmulator=%s" % [
			str(host.game.cash_reward_real_device), str(host.game.cash_reward_allow_emulator)
		])
