class_name FarmAds
extends Node

## Google test units are used for debug APKs. Release APKs use the owner's units.
signal reward_granted(gems: int)
signal message_requested(message: String)
signal config_changed
signal visible_ad_changed

const FLAG_FOR_KIND := {
	"banner": "EnableAdmobBanner",
	"interstitial": "EnableAdmobInterstisial",
	"rewarded_interstitial": "EnableAdmobIntermediaryBonus",
	"rewarded": "EnableAdmobReward",
	"native": "EnableAdmobNativeAdvance",
	"app_open": "EnableAdmobOpeningApp",
}

const PRODUCTION := {
	"banner": "ca-app-pub-4976994447971905/2631175294",
	"interstitial": "ca-app-pub-4976994447971905/3313701576",
	"rewarded_interstitial": "ca-app-pub-4976994447971905/8494535208",
	"rewarded": "ca-app-pub-4976994447971905/7181453530",
	"native": "ca-app-pub-4976994447971905/4059807035",
	"app_open": "ca-app-pub-4976994447971905/7061374891",
}
const TEST := {
	"banner": "ca-app-pub-3940256099942544/9214589741",
	"interstitial": "ca-app-pub-3940256099942544/1033173712",
	"rewarded_interstitial": "ca-app-pub-3940256099942544/5354046379",
	"rewarded": "ca-app-pub-3940256099942544/5224354917",
	"native": "ca-app-pub-3940256099942544/2247696110",
	"app_open": "ca-app-pub-3940256099942544/9257395921",
}

const INTERSTITIAL_COOLDOWN := 600
const RESUME_MIN_SECONDS := 180
const APP_OPEN_EXPIRATION := 4 * 3600
const NATIVE_TEMPLATE_SIZE := Vector2i(320, 70)

var _ready_for_ads := false
var _initializing := false
var _view_mode := "kebun"
var _fullscreen_active := false
var _pending_reward := ""
var _reward_paid := false
var _last_interstitial_at := 0
var _paused_at := 0
var _app_open_loaded_at := 0
var _consent_requested := false
var _remote_config: Object
var _config_flags := {
	"EnableAdmob": false,
	"EnableAdmobBanner": false,
	"EnableAdmobInterstisial": false,
	"EnableAdmobIntermediaryBonus": false,
	"EnableAdmobReward": false,
	"EnableAdmobNativeAdvance": false,
	"EnableAdmobOpeningApp": false,
}

var _banner: AdView
var _banner_loaded := false
var _native: NativeOverlayAd
var _interstitial: InterstitialAd
var _rewarded: RewardedAd
var _rewarded_interstitial: RewardedInterstitialAd
var _app_open: AppOpenAd

var _interstitial_loading := false
var _rewarded_loading := false
var _rewarded_interstitial_loading := false
var _app_open_loading := false
var _native_loading := false
var _native_failed := false

var _interstitial_cb := InterstitialAdLoadCallback.new()
var _rewarded_cb := RewardedAdLoadCallback.new()
var _rewarded_interstitial_cb := RewardedInterstitialAdLoadCallback.new()
var _app_open_cb := AppOpenAdLoadCallback.new()
var _banner_cb := AdListener.new()
var _reward_listener := OnUserEarnedRewardListener.new()
var _rewarded_interstitial_listener := OnUserEarnedRewardListener.new()
var _full_callbacks: Dictionary = {}


static func is_supported() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob")


static func ad_unit(kind: String) -> String:
	return str(TEST[kind] if OS.is_debug_build() else PRODUCTION[kind])


func _ready() -> void:
	if not is_supported():
		_setup_remote_config()
		return

	_interstitial_cb.on_ad_loaded = _on_interstitial_loaded
	_interstitial_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_interstitial_loading = false
		_log_failure("interstitial", error.message)
		_schedule_retry("interstitial")
	_rewarded_cb.on_ad_loaded = _on_rewarded_loaded
	_rewarded_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_loading = false
		_log_failure("rewarded", error.message)
		_schedule_retry("rewarded")
	_rewarded_interstitial_cb.on_ad_loaded = _on_rewarded_interstitial_loaded
	_rewarded_interstitial_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_interstitial_loading = false
		_log_failure("rewarded interstitial", error.message)
		_schedule_retry("rewarded_interstitial")
	_app_open_cb.on_ad_loaded = _on_app_open_loaded
	_app_open_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_app_open_loading = false
		_log_failure("app open", error.message)
		_schedule_retry("app_open")
	_banner_cb.on_ad_loaded = func() -> void:
		if not _banner or not can_show_kind("banner"):
			return
		_banner_loaded = true
		_update_persistent_ad()
		visible_ad_changed.emit()
	_banner_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_log_failure("banner", error.message)
		_banner_loaded = false
		if _banner:
			_banner.destroy()
			_banner = null
		_update_persistent_ad()
		visible_ad_changed.emit()
		_schedule_retry("banner")
	_reward_listener.on_user_earned_reward = func(_reward: RewardedItem) -> void:
		_grant_reward("rewarded", 2)
	_rewarded_interstitial_listener.on_user_earned_reward = func(_reward: RewardedItem) -> void:
		_grant_reward("rewarded_interstitial", 3)

	_setup_remote_config()


func can_show_kind(kind: String) -> bool:
	return (
		is_supported()
		and bool(_config_flags["EnableAdmob"])
		and bool(_config_flags.get(FLAG_FOR_KIND.get(kind, ""), false))
	)


func get_visible_ad_height_in_pixels() -> float:
	# AdMob overlays are measured in physical Android pixels, not Godot canvas units.
	# Reserve space only after an ad has loaded and is being displayed.
	if not _ready_for_ads:
		return 0.0
	if _view_mode == "toko" and can_show_kind("native") and _native:
		var native_height := _native.get_template_height_in_pixels()
		return native_height if native_height > 0.0 else _dp_to_pixels(NATIVE_TEMPLATE_SIZE.y)
	if can_show_kind("banner") and _banner and _banner_loaded:
		var banner_height := _banner.get_height_in_pixels()
		return float(banner_height) if banner_height > 0 else _dp_to_pixels(AdSize.BANNER.height)
	return 0.0


func _dp_to_pixels(height_dp: int) -> float:
	# Used only when the native plugin has not reported its measured height yet.
	return float(height_dp) * maxf(float(DisplayServer.screen_get_dpi()) / 160.0, 1.0)


func has_enabled_ads() -> bool:
	return _any_ads_enabled()


func _setup_remote_config() -> void:
	if OS.get_name() != "Android" or not Engine.has_singleton("FarmRemoteConfig"):
		return
	_remote_config = Engine.get_singleton("FarmRemoteConfig")
	_remote_config.connect("config_ready", Callable(self, "_on_config_ready"))
	_on_config_ready(str(_remote_config.call("getConfigJson")))
	_remote_config.call("refresh")


func _on_config_ready(json: String) -> void:
	var values: Variant = JSON.parse_string(json)
	if not values is Dictionary:
		push_warning("Firebase Remote Config: invalid response, ads remain disabled")
		return
	for key in _config_flags:
		if key == "EnableAdmob":
			# Only block ads when the optional master flag is explicitly false.
			_config_flags[key] = values.get(key, true) == true
		else:
			# Individual ad formats stay disabled unless enabled remotely.
			_config_flags[key] = values.get(key, false) == true
	if OS.is_debug_build():
		print("FarmAds: config master=%s (published=%s), enabled formats=%s" % [
			str(_config_flags["EnableAdmob"]), str(values.has("EnableAdmob")),
			str(_any_ads_enabled())
		])
	if is_supported():
		_release_disabled_ads()
		if _any_ads_enabled():
			if not _consent_requested:
				_consent_requested = true
				UserMessagingPlatform.consent_information.update(
					ConsentRequestParameters.new(), _on_consent_updated, _on_consent_failed
				)
			elif _ready_for_ads:
				_load_all_enabled_ads()
	config_changed.emit()


func _any_ads_enabled() -> bool:
	for kind in FLAG_FOR_KIND:
		if can_show_kind(kind):
			return true
	return false


func _release_disabled_ads() -> void:
	if not can_show_kind("banner") and _banner:
		_banner.destroy()
		_banner = null
		_banner_loaded = false
	if not can_show_kind("native") and _native:
		_native.destroy()
		_native = null
	if not can_show_kind("native"):
		_native_failed = false
	if not can_show_kind("interstitial") and _interstitial:
		_interstitial.destroy()
		_interstitial = null
	if not can_show_kind("rewarded") and _rewarded:
		_rewarded.destroy()
		_rewarded = null
	if not can_show_kind("rewarded_interstitial") and _rewarded_interstitial:
		_rewarded_interstitial.destroy()
		_rewarded_interstitial = null
	if not can_show_kind("app_open") and _app_open:
		_app_open.destroy()
		_app_open = null
	_update_persistent_ad()


func _load_all_enabled_ads() -> void:
	_load_banner()
	_load_interstitial()
	_load_rewarded()
	_load_rewarded_interstitial()
	_load_app_open()
	_update_persistent_ad()


func _on_consent_updated() -> void:
	if not _any_ads_enabled():
		return
	var consent := UserMessagingPlatform.consent_information
	if consent.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		if consent.get_is_consent_form_available():
			UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, _on_consent_failed)
		return
	_start_ads()


func _on_consent_form_loaded(form: ConsentForm) -> void:
	form.show(_on_consent_dismissed)


func _on_consent_dismissed(error: FormError) -> void:
	if not _any_ads_enabled():
		return
	if error:
		push_warning("AdMob consent: " + error.message)
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if (
		status == ConsentInformation.ConsentStatus.OBTAINED
		or status == ConsentInformation.ConsentStatus.NOT_REQUIRED
	):
		_start_ads()


func _on_consent_failed(error: FormError) -> void:
	if not _any_ads_enabled():
		return
	if error:
		push_warning("AdMob consent: " + error.message)
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if (
		status == ConsentInformation.ConsentStatus.OBTAINED
		or status == ConsentInformation.ConsentStatus.NOT_REQUIRED
	):
		_start_ads()
	elif OS.is_debug_build():
		# Debug APKs only request Google's demo units. This permits testing the
		# integration before the publisher has configured a UMP privacy form.
		push_warning("AdMob: UMP unavailable; loading Google test ads in debug build only.")
		_start_ads()


func show_privacy_options() -> void:
	if not is_supported():
		return
	UserMessagingPlatform.show_privacy_options_form(
		func(error: FormError) -> void:
			if error:
				message_requested.emit("Pengaturan privasi belum tersedia.")
	)


func _start_ads() -> void:
	if _ready_for_ads or _initializing or not _any_ads_enabled():
		return
	_initializing = true
	if OS.is_debug_build():
		print("FarmAds: initializing AdMob")
	var config := RequestConfiguration.new()
	config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	MobileAds.set_request_configuration(config)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_ready_for_ads = true
		_initializing = false
		if OS.is_debug_build():
			print("FarmAds: AdMob initialized; loading enabled ad units")
		_load_all_enabled_ads()
	MobileAds.initialize(listener)


func set_game_tab(tab: String) -> void:
	_view_mode = tab
	_update_persistent_ad()
	visible_ad_changed.emit()


func _load_banner() -> void:
	if _banner != null or not _ready_for_ads or not can_show_kind("banner"):
		return
	if OS.is_debug_build():
		print("FarmAds: requesting banner test ad")
	_banner = AdView.new(ad_unit("banner"), AdSize.BANNER, AdPosition.BOTTOM)
	_banner_loaded = false
	_banner.ad_listener = _banner_cb
	_banner.hide()
	_banner.load_ad(AdRequest.new())
	_update_persistent_ad()


func _update_persistent_ad() -> void:
	if not _ready_for_ads:
		return
	if _view_mode == "toko":
		if _banner:
			_banner.hide()
		if can_show_kind("native") and _native:
			_native.show()
		elif can_show_kind("native"):
			if not _native_loading and not _native_failed:
				_load_native()
			if _banner and _banner_loaded and can_show_kind("banner"):
				_banner.show()
		elif _banner and _banner_loaded and can_show_kind("banner"):
			_banner.show()
	else:
		if _native:
			_native.hide()
		if _banner and _banner_loaded and can_show_kind("banner"):
			_banner.show()


func _load_native() -> void:
	if _native_loading or _native or not _ready_for_ads or not can_show_kind("native"):
		return
	_native_failed = false
	_native_loading = true
	NativeOverlayAd.load(
		ad_unit("native"), AdRequest.new(), NativeAdOptions.new(), _on_native_loaded
	)


func _on_native_loaded(ad: NativeOverlayAd, error: LoadAdError) -> void:
	_native_loading = false
	if not can_show_kind("native"):
		if ad:
			ad.destroy()
		return
	if error:
		_log_failure("native", error.message)
		_native_failed = true
		_update_persistent_ad()
		visible_ad_changed.emit()
		_schedule_retry("native")
		return
	_native = ad
	var style := NativeTemplateStyle.new()
	style.template_id = NativeTemplateStyle.SMALL
	style.main_background_color = Color("fff9e8")
	_native.render_template(
		style, AdPosition.BOTTOM, AdSize.new(NATIVE_TEMPLATE_SIZE.x, NATIVE_TEMPLATE_SIZE.y)
	)
	_update_persistent_ad()
	visible_ad_changed.emit()
	# Android can report the actual measured native height after its layout pass.
	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		if is_inside_tree():
			visible_ad_changed.emit()
	)


func _load_interstitial() -> void:
	if (
		not _ready_for_ads
		or not can_show_kind("interstitial")
		or _interstitial
		or _interstitial_loading
	):
		return
	_interstitial_loading = true
	InterstitialAdLoader.new().load(ad_unit("interstitial"), AdRequest.new(), _interstitial_cb)


func _on_interstitial_loaded(ad: InterstitialAd) -> void:
	_interstitial_loading = false
	if not can_show_kind("interstitial"):
		ad.destroy()
		return
	_interstitial = ad
	ad.full_screen_content_callback = _make_fullscreen_callbacks("interstitial")


func maybe_show_interstitial(deliveries: int) -> void:
	if (
		not _ready_for_ads
		or not can_show_kind("interstitial")
		or _fullscreen_active
		or _interstitial == null
	):
		return
	if deliveries < 4 or deliveries % 4 != 0:
		return
	var now := int(Time.get_unix_time_from_system())
	if now - _last_interstitial_at < INTERSTITIAL_COOLDOWN:
		return
	_last_interstitial_at = now
	_fullscreen_active = true
	_interstitial.show()


func _load_rewarded() -> void:
	if not _ready_for_ads or not can_show_kind("rewarded") or _rewarded or _rewarded_loading:
		return
	_rewarded_loading = true
	RewardedAdLoader.new().load(ad_unit("rewarded"), AdRequest.new(), _rewarded_cb)


func _on_rewarded_loaded(ad: RewardedAd) -> void:
	_rewarded_loading = false
	if not can_show_kind("rewarded"):
		ad.destroy()
		return
	_rewarded = ad
	ad.full_screen_content_callback = _make_fullscreen_callbacks("rewarded")


func _load_rewarded_interstitial() -> void:
	if (
		not _ready_for_ads
		or not can_show_kind("rewarded_interstitial")
		or _rewarded_interstitial
		or _rewarded_interstitial_loading
	):
		return
	_rewarded_interstitial_loading = true
	RewardedInterstitialAdLoader.new().load(
		ad_unit("rewarded_interstitial"), AdRequest.new(), _rewarded_interstitial_cb
	)


func _on_rewarded_interstitial_loaded(ad: RewardedInterstitialAd) -> void:
	_rewarded_interstitial_loading = false
	if not can_show_kind("rewarded_interstitial"):
		ad.destroy()
		return
	_rewarded_interstitial = ad
	ad.full_screen_content_callback = _make_fullscreen_callbacks("rewarded_interstitial")


func show_rewarded(kind: String) -> void:
	if kind != "rewarded" and kind != "rewarded_interstitial":
		return
	if not can_show_kind(kind):
		reward_granted.emit(2 if kind == "rewarded" else 3)
		return
	if not _ready_for_ads or _fullscreen_active:
		message_requested.emit("Iklan belum siap. Coba lagi nanti.")
		return
	if kind == "rewarded" and _rewarded:
		_pending_reward = kind
		_reward_paid = false
		_fullscreen_active = true
		_rewarded.show(_reward_listener)
	elif kind == "rewarded_interstitial" and _rewarded_interstitial:
		_pending_reward = kind
		_reward_paid = false
		_fullscreen_active = true
		_rewarded_interstitial.show(_rewarded_interstitial_listener)
	else:
		message_requested.emit("Iklan belum tersedia. Periksa internet dan coba lagi.")


func _grant_reward(kind: String, gems: int) -> void:
	if _pending_reward != kind or _reward_paid or not _fullscreen_active:
		return
	_reward_paid = true
	reward_granted.emit(gems)


func _load_app_open() -> void:
	if not _ready_for_ads or not can_show_kind("app_open") or _app_open or _app_open_loading:
		return
	_app_open_loading = true
	AppOpenAdLoader.new().load(ad_unit("app_open"), AdRequest.new(), _app_open_cb)


func _on_app_open_loaded(ad: AppOpenAd) -> void:
	_app_open_loading = false
	if not can_show_kind("app_open"):
		ad.destroy()
		return
	_app_open = ad
	_app_open_loaded_at = int(Time.get_unix_time_from_system())
	ad.full_screen_content_callback = _make_fullscreen_callbacks("app_open")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_paused_at = int(Time.get_unix_time_from_system())
	elif what == NOTIFICATION_APPLICATION_RESUMED and _paused_at > 0:
		var now := int(Time.get_unix_time_from_system())
		var was_paused := now - _paused_at
		_paused_at = 0
		if (
			was_paused >= RESUME_MIN_SECONDS
			and _ready_for_ads
			and not _fullscreen_active
			and can_show_kind("app_open")
		):
			if _app_open and now - _app_open_loaded_at < APP_OPEN_EXPIRATION:
				_fullscreen_active = true
				_app_open.show()
			elif _app_open:
				_cleanup_fullscreen("app_open")
			else:
				_load_app_open()


func _make_fullscreen_callbacks(kind: String) -> FullScreenContentCallback:
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = func() -> void: _cleanup_fullscreen(kind)
	callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		_log_failure(kind, error.message)
		_cleanup_fullscreen(kind)
	_full_callbacks[kind] = callback
	return callback


func _cleanup_fullscreen(kind: String) -> void:
	_fullscreen_active = false
	_pending_reward = ""
	match kind:
		"interstitial":
			if _interstitial:
				_interstitial.destroy()
			_interstitial = null
			_load_interstitial()
		"rewarded":
			if _rewarded:
				_rewarded.destroy()
			_rewarded = null
			_load_rewarded()
		"rewarded_interstitial":
			if _rewarded_interstitial:
				_rewarded_interstitial.destroy()
			_rewarded_interstitial = null
			_load_rewarded_interstitial()
		"app_open":
			if _app_open:
				_app_open.destroy()
			_app_open = null
			_load_app_open()


func _log_failure(kind: String, error: String) -> void:
	push_warning("AdMob %s: %s" % [kind, error])


func _schedule_retry(kind: String) -> void:
	# A temporary network failure should not leave reward ads unavailable
	# for the entire session. Only retry native ads while the shop is open.
	get_tree().create_timer(60.0).timeout.connect(
		func() -> void:
			if not is_inside_tree() or not _ready_for_ads or not can_show_kind(kind):
				return
			match kind:
				"banner":
					_load_banner()
				"interstitial":
					_load_interstitial()
				"rewarded":
					_load_rewarded()
				"rewarded_interstitial":
					_load_rewarded_interstitial()
				"app_open":
					_load_app_open()
				"native":
					if _view_mode == "toko" and _native == null:
						_load_native()
	)


func _exit_tree() -> void:
	if _banner:
		_banner.destroy()
	if _native:
		_native.destroy()
	if _interstitial:
		_interstitial.destroy()
	if _rewarded:
		_rewarded.destroy()
	if _rewarded_interstitial:
		_rewarded_interstitial.destroy()
	if _app_open:
		_app_open.destroy()
