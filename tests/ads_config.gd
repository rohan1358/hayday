extends SceneTree


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var ads := FarmAds.new()
	var granted: Array[int] = []
	ads.reward_granted.connect(func(gems: int) -> void: granted.append(gems))
	root.add_child(ads)

	# All flags are false until Firebase activates values; claiming a bonus is free.
	ads.show_rewarded("rewarded")
	ads.show_rewarded("rewarded_interstitial")
	if granted != [2, 3]:
		push_error("Disabled ad rewards should be granted instantly: %s" % [granted])
		ads.free()
		quit(1)
		return

	# An individual ad flag cannot override the global kill switch.
	ads._on_config_ready('{"EnableAdmob":false,"EnableAdmobReward":true}')
	if ads._config_flags["EnableAdmob"] or not ads._config_flags["EnableAdmobReward"]:
		push_error("Firebase flags were not decoded correctly")
		ads.free()
		quit(1)
		return
	ads.show_rewarded("rewarded")
	ads.show_rewarded("unexpected")
	if granted != [2, 3, 2]:
		push_error("Unexpected reward result: %s" % [granted])
		ads.free()
		quit(1)
		return

	print("AdMob Remote Config and free rewards: PASS")
	ads.free()
	quit(0)
