class_name DailyMissionsUI
extends RefCounted

const INK := Color("344b39")
const SOFT_INK := Color("72806d")
const GREEN := Color("368d5b")


static func populate(
	ui: Control, list: VBoxContainer, game: FarmGameState, on_claim: Callable,
	on_checkin: Callable, on_achievement: Callable
) -> void:
	game.ensure_daily_tasks()
	var checkin := game.daily_checkin_preview()
	var checkin_day := int(checkin["day"])
	var claimed_today := bool(checkin["claimed_today"])
	var checkin_card: Panel = ui.call("row_card", list, 190, Color("e5f3d5"))
	ui.call("label", checkin_card, "HADIAH KUNJUNGAN HARIAN", Vector2(22, 12), Vector2(550, 38), 25, GREEN, true)
	var day_markers := ""
	for day in range(1, 8):
		day_markers += ("●" if day <= checkin_day and claimed_today else "◉" if day == checkin_day else "○")
		if day < 7:
			day_markers += "   "
	ui.call("label", checkin_card, day_markers, Vector2(22, 56), Vector2(555, 34), 26, GREEN, true)
	var reward_text := "HARI %d/7  ·  +%d KOIN" % [checkin_day, int(checkin["coins"])]
	if int(checkin["diamonds"]) > 0:
		reward_text += "  ·  +1 PERMATA"
	ui.call("label", checkin_card, reward_text, Vector2(22, 96), Vector2(565, 33), 20, INK, true)
	var checkin_button: Button = ui.call(
		"button", checkin_card,
		"SUDAH DIAMBIL" if claimed_today else "AMBIL HADIAH" if bool(checkin["available"]) else "BELUM TERSEDIA",
		Vector2(22, 133), Vector2(555, 48), GREEN if bool(checkin["available"]) else Color("9eaf93"), Color.WHITE, 19
	)
	checkin_button.disabled = not bool(checkin["available"])
	checkin_button.pressed.connect(func() -> void: on_checkin.call())
	ui.call(
		"callout",
		list,
		"TANTANGAN HARI INI  ·  " + game.daily_date,
		"Progres diperbarui setiap hari. Ambil hadiah sebelum berganti hari!",
		Color("e3f2d7")
	)
	for id in FarmGameState.DAILY_TASK_ORDER:
		var task: Dictionary = FarmGameState.DAILY_TASKS[id]
		var goal := int(task["goal"])
		var progress := int(game.daily_progress.get(id, 0))
		var claimed := bool(game.daily_claimed.get(id, false))
		var ready := progress >= goal and not claimed
		var card: Panel = ui.call(
			"row_card", list, 198, Color("fff2da") if not claimed else Color("edf0e6")
		)
		ui.call(
			"label",
			card,
			str(task["name"]).to_upper(),
			Vector2(22, 14),
			Vector2(455, 37),
			25,
			INK,
			true
		)
		ui.call(
			"label", card, str(task["description"]), Vector2(22, 53), Vector2(520, 29), 19, SOFT_INK
		)
		var progress_bar := ProgressBar.new()
		progress_bar.position = Vector2(22, 100)
		progress_bar.size = Vector2(380, 16)
		progress_bar.max_value = goal
		progress_bar.value = progress
		progress_bar.show_percentage = false
		progress_bar.add_theme_stylebox_override("background", ui.call("style", Color("d9dbbb"), 9))
		progress_bar.add_theme_stylebox_override("fill", ui.call("style", GREEN, 9))
		card.add_child(progress_bar)
		ui.call(
			"label",
			card,
			"%d / %d" % [progress, goal],
			Vector2(425, 88),
			Vector2(135, 37),
			23,
			GREEN,
			true
		)
		var reward := "+%d koin  ·  +%d XP" % [int(task["coins"]), int(task["xp"])]
		if int(task["diamonds"]) > 0:
			reward += "  ·  +%d ◆" % int(task["diamonds"])
		ui.call(
			"label", card, reward, Vector2(22, 147), Vector2(361, 37), 17, Color("9c7646"), true
		)
		var claim: Button = ui.call(
			"button",
			card,
			"DIKLAIM" if claimed else "KLAIM" if ready else "BELUM SIAP",
			Vector2(418, 130),
			Vector2(163, 55),
			GREEN if ready else Color("b4bfaa"),
			Color.WHITE,
			17
		)
		claim.disabled = not ready
		claim.pressed.connect(func() -> void: on_claim.call(id))
	ui.call(
		"callout", list, "PRESTASI KEBUN  ·  SELAMANYA",
		"Panen, masak, kirim, dan berdagang. Progres tetap tersimpan.",
		Color("e2f0d8")
	)
	for id in FarmGameState.ACHIEVEMENT_ORDER:
		var info: Dictionary = FarmGameState.ACHIEVEMENTS[id]
		var status := game.achievement_status(id)
		var completed := bool(status["completed"])
		var ready := bool(status["ready"])
		var goal := int(status["goal"])
		var progress := mini(goal, int(status["progress"]))
		var card: Panel = ui.call("row_card", list, 192, Color("e5f3d8") if ready else Color("f7f1da") if not completed else Color("edf0e6"))
		ui.call("label", card, str(info["name"]).to_upper(), Vector2(22, 12), Vector2(375, 38), 24, INK, true)
		ui.call(
			"label", card, "TUNTAS  ·  3/3" if completed else "TAHAP %d/3  ·  %s" % [int(status["tier"]), str(info["description"])],
			Vector2(22, 54), Vector2(555, 32), 18, SOFT_INK
		)
		var progress_bar := ProgressBar.new()
		progress_bar.position = Vector2(22, 104)
		progress_bar.size = Vector2(370, 17)
		progress_bar.max_value = goal
		progress_bar.value = progress
		progress_bar.show_percentage = false
		progress_bar.add_theme_stylebox_override("background", ui.call("style", Color("dadcc7"), 9))
		progress_bar.add_theme_stylebox_override("fill", ui.call("style", GREEN, 9))
		card.add_child(progress_bar)
		ui.call("label", card, "%d / %d" % [progress, goal], Vector2(405, 93), Vector2(166, 33), 21, GREEN, true)
		var achievement_reward := (
			"SELURUH TAHAP SELESAI" if completed else "+%d koin  ·  +%d XP" % [int(status["coins"]), int(status["xp"])]
		)
		if not completed and int(status["diamonds"]) > 0:
			achievement_reward += "  ·  +%d ◆" % int(status["diamonds"])
		ui.call("label", card, achievement_reward, Vector2(22, 144), Vector2(382, 32), 17, Color("9c7646"), true)
		var claim: Button = ui.call(
			"button", card,
			"TUNTAS" if completed else "KLAIM" if ready else "BELUM SIAP",
			Vector2(419, 132), Vector2(160, 49), GREEN if ready else Color("b4bfaa"), Color.WHITE, 17
		)
		claim.disabled = not ready
		claim.pressed.connect(func() -> void: on_achievement.call(id))
