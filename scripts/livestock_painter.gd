class_name LivestockPainter

extends RefCounted


static func animal_waypoint(stage: int, seed: float, radius: Vector2) -> Vector2:
	return Vector2(
		sin(float(stage) * 2.17 + seed * 1.37) * radius.x,
		cos(float(stage) * 1.63 + seed * 2.19) * radius.y
	)


static func animal_motion(view: FarmView, seed: float, radius: Vector2) -> Dictionary:
	# Deterministic wandering, with a pause between strolls. No state needs saving.
	var duration := 6.2 + fposmod(seed, 2.6)
	var clock := view.shimmer + seed * 3.7
	var stage := floori(clock / duration)
	var progress := fposmod(clock, duration) / duration
	var travel := clampf(progress / 0.74, 0.0, 1.0)
	var eased := travel * travel * (3.0 - 2.0 * travel)
	var start := animal_waypoint(stage, seed, radius)
	var finish := animal_waypoint(stage + 1, seed, radius)
	return {
		"offset": start.lerp(finish, eased),
		"walking": progress < 0.74 and progress > 0.04,
		"facing": -1.0 if finish.x < start.x else 1.0,
		"phase": view.shimmer * 8.0 + seed * 2.0,
	}


static func paint_pen_rail(view: FarmView, start: Vector2, finish: Vector2, posts: int = 6) -> void:
	# Draw back rails before the animals, and near rails afterward for depth.
	for height in [-27.0, -10.0]:
		view.line(
			start + Vector2(0, height + 3), finish + Vector2(0, height + 3), Color("9c613d"), 9
		)
		view.line(start + Vector2(0, height), finish + Vector2(0, height), Color("f2c98b"), 4)
	for i in posts:
		var post := start.lerp(finish, float(i) / float(posts - 1))
		view.line(post + Vector2(0, 4), post + Vector2(0, -38), Color("93603b"), 10)
		view.line(post + Vector2(-2, 1), post + Vector2(-2, -35), Color("eac18a"), 4)
		view.poly(
			PackedVector2Array(
				[post + Vector2(-6, -37), post + Vector2(0, -46), post + Vector2(6, -37)]
			),
			Color("f5d7a0")
		)


static func paint_feed_trough(view: FarmView, at: Vector2, scale_factor: float = 1.0) -> void:
	var s := scale_factor
	view.ellipse(at + Vector2(0, 8) * s, 32 * s, 10 * s, Color("795a3e", 0.25))
	view.poly(
		PackedVector2Array(
			[
				at + Vector2(-35, -5) * s,
				at + Vector2(35, -5) * s,
				at + Vector2(26, 13) * s,
				at + Vector2(-26, 13) * s
			]
		),
		Color("995c37")
	)
	view.ellipse(at + Vector2(0, -6) * s, 33 * s, 10 * s, Color("efc378"))
	view.ellipse(at + Vector2(0, -8) * s, 26 * s, 5 * s, Color("a1ba60"))


static func paint_butterfly(view: FarmView, at: Vector2, seed: float) -> void:
	var flutter := (
		at + Vector2(sin(view.shimmer * 1.4 + seed) * 21.0, cos(view.shimmer * 1.8 + seed) * 15.0)
	)
	var wing := 3.0 + 6.0 * absf(sin(view.shimmer * 11.0 + seed))
	paint_butterfly_shape(view, flutter, wing)


static func paint_butterfly_shape(view: FarmView, at: Vector2 = Vector2.ZERO, wing: float = 9.0) -> void:
	# Retained Android butterflies use this full-open pose and animate by scaling
	# their CanvasItems, avoiding repeated vector geometry allocation.
	view.ellipse(at + Vector2(-wing * 0.8, -3), wing, 8, Color("ffdf78", 0.93))
	view.ellipse(at + Vector2(wing * 0.8, -3), wing, 8, Color("ff93aa", 0.93))
	view.line(at + Vector2(0, -7), at + Vector2(0, 6), Color("694b40"), 2.5)


static func paint_chicken(
	view: FarmView, at: Vector2, scale_factor: float, walking: bool = false, phase: float = 0.0
) -> void:
	var s := scale_factor
	var step := sin(phase) * (5.0 if walking else 0.45)
	var bob := absf(sin(phase)) * (3.0 if walking else 0.7)
	var breathe := sin(phase * 0.37) * 0.9
	var peck := 5.0 * maxf(0.0, sin(view.shimmer * 2.8 + phase * 0.13)) if not walking else 0.0
	# Shadows stay under the toes while the body bobs independently.
	view.ellipse(at + Vector2(1, 25) * s, 30 * s, 10 * s, Color("314a32", 0.10), 16)
	view.ellipse(at + Vector2(1, 25) * s, 21 * s, 6 * s, Color("344b32", 0.22), 16)
	var body := at + Vector2(0, -bob + breathe) * s
	# Three tall tail feathers make chickens recognizable even at game zoom.
	for tip in [Vector2(-35, -28), Vector2(-29, -34), Vector2(-24, -29)]:
		view.line(body + Vector2(-15, -1) * s, body + tip * s, Color("e4d7c4"), 7 * s)
	view.ellipse(body + Vector2(-2, 1) * s, 21 * s, 19 * s, Color("e5d8c4"))
	view.ellipse(body + Vector2(0, -3) * s, 20 * s, 19 * s, Color("fff7e8"))
	# Wing, layered feathers and the moving neck/head silhouette.
	view.ellipse(body + Vector2(-9, 1) * s, 11 * s, 12 * s, Color("e8dcc8"))
	view.ellipse(body + Vector2(-7, -2) * s, 9 * s, 9 * s, Color("f5ebda"))
	view.line(body + Vector2(-14, 3) * s, body + Vector2(-6, 8) * s, Color("d8cab5", 1.7 * s))
	var head := body + Vector2(11, -13 + peck) * s
	view.draw_circle(head, 12 * s, Color("fff8e9"))
	view.ellipse(head + Vector2(4, 8) * s, 4.0 * s, 5.4 * s, Color("ed947a"))
	view.poly(
		PackedVector2Array(
			[
				head + Vector2(7, 1) * s,
				head + Vector2(21, 6) * s,
				head + Vector2(7, 9) * s
			]
		),
		Color("e6a73f")
	)
	if fposmod(view.shimmer + phase * 0.1, 4.3) > 0.13:
		view.draw_circle(head + Vector2(4, -4) * s, 2.7 * s, Color("473c33"))
		view.draw_circle(head + Vector2(4.8, -4.8) * s, 0.9 * s, Color("fffaf1"))
	else:
		view.line(
			head + Vector2(1, -4) * s,
			head + Vector2(7, -4) * s,
			Color("473c33"),
			2 * s
		)
	for off in [Vector2(-6, -11), Vector2(0, -16), Vector2(6, -11)]:
		view.draw_circle(head + off * s, 4.8 * s, Color("df6653"))
	view.line(
		at + Vector2(-6, 14) * s,
		at + Vector2(-7 + step, 26) * s,
		Color("c68643"),
		2.7 * s
	)
	view.line(
		at + Vector2(7, 14) * s,
		at + Vector2(7 - step, 26) * s,
		Color("c68643"),
		2.7 * s
	)
	for x in [-7.0 + step, 7.0 - step]:
		view.line(at + Vector2(x - 5, 26) * s, at + Vector2(x + 6, 26) * s, Color("bd803e"), 2 * s)
		view.line(at + Vector2(x + 1, 26) * s, at + Vector2(x + 4, 29) * s, Color("bd803e"), 1.7 * s)


static func paint_cow_pen(view: FarmView) -> void:
	# A prerendered original pen provides consistent depth and shading.
	# Keep live animals and production bubbles above the illustration.
	if view.farm_art.paint(view, "cow_pen", Vector2(505, 1225), 315.0):
		view.paint_roaming_animal("cow", Vector2(408, 1241), 0.48, 1.2, Vector2(9, 6))
		view.paint_roaming_animal("cow", Vector2(617, 1250), 0.40, 3.8, Vector2(7, 5))
		if view.game.cow_is_hungry():
			view.bubble("BERI PAKAN", Vector2(505, 1088), Color("fff1ca"), Color("8d5b31"))
		elif view.game.cow_milk_ready():
			view.bubble("SUSU SIAP!", Vector2(505, 1088), Color("f2ffe3"), Color("3b8849"))
		else:
			view.bubble("SAPI PERAH", Vector2(505, 1088), Color("fff9e8"), Color("805c3e"))
		return
	# Wide pasture and layered rails make three cows feel at home.
	(
		view
		. poly(
			PackedVector2Array(
				[
					Vector2(331, 1161),
					Vector2(375, 1116),
					Vector2(629, 1116),
					Vector2(666, 1161),
					Vector2(676, 1293),
					Vector2(328, 1293),
				]
			),
			Color("ddc28b")
		)
	)
	(
		view
		. poly(
			PackedVector2Array(
				[
					Vector2(343, 1164),
					Vector2(383, 1131),
					Vector2(620, 1131),
					Vector2(654, 1164),
					Vector2(661, 1279),
					Vector2(344, 1279),
				]
			),
			Color("ae935b")
		)
	)
	for i in 12:
		var speck := Vector2(365 + (i * 37) % 273, 1172 + (i * 43) % 90)
		view.line(speck, speck + Vector2(8, 2), Color("e8c88a", 0.62), 2.0)
	LivestockPainter.paint_pen_rail(view, Vector2(335, 1162), Vector2(376, 1124), 3)
	LivestockPainter.paint_pen_rail(view, Vector2(376, 1124), Vector2(629, 1124), 7)
	LivestockPainter.paint_pen_rail(view, Vector2(629, 1124), Vector2(666, 1162), 3)
	view.paint_hay_bale(Vector2(381, 1202), 0.8)
	LivestockPainter.paint_feed_trough(view, Vector2(627, 1201), 0.68)
	view.paint_roaming_animal("cow", Vector2(425, 1218), 0.74, 1.2, Vector2(21, 11))
	view.paint_roaming_animal("cow", Vector2(560, 1211), 0.67, 3.8, Vector2(19, 11))
	view.paint_roaming_animal("cow", Vector2(510, 1250), 0.43, 7.4, Vector2(19, 8))
	LivestockPainter.paint_pen_rail(view, Vector2(335, 1162), Vector2(328, 1293), 4)
	LivestockPainter.paint_pen_rail(view, Vector2(666, 1162), Vector2(676, 1293), 4)
	LivestockPainter.paint_pen_rail(view, Vector2(328, 1293), Vector2(676, 1293), 9)
	view.ellipse(Vector2(376, 1320), 18, 7, Color("4b855c", 0.32))
	view.draw_rect(Rect2(365, 1295, 23, 25), Color("cbdfe0"))
	view.ellipse(Vector2(376, 1295), 12, 5, Color("f4f9e7"))
	view.line(Vector2(364, 1300), Vector2(366, 1288), Color("e8f6f4"), 3)
	view.line(Vector2(389, 1300), Vector2(387, 1288), Color("e8f6f4"), 3)
	if view.game.cow_is_hungry():
		view.bubble("BERI PAKAN", Vector2(505, 1088), Color("fff1ca"), Color("8d5b31"))
	elif view.game.cow_milk_ready():
		view.bubble("SUSU SIAP!", Vector2(505, 1088), Color("f2ffe3"), Color("3b8849"))
	else:
		view.bubble("SAPI PERAH", Vector2(505, 1088), Color("fff9e8"), Color("805c3e"))


static func paint_cow(
	view: FarmView, at: Vector2, scale_factor: float, walking: bool = false, phase: float = 0.0
) -> void:
	var s := scale_factor
	var step := sin(phase) * (6.0 if walking else 0.0)
	var bob := absf(sin(phase)) * (3.0 if walking else 0.6)
	var breathe := sin(phase * 0.32) * (0.5 if walking else 1.2)
	view.ellipse(at + Vector2(2, 35) * s, 65 * s, 14 * s, Color("304d35", 0.10), 18)
	view.ellipse(at + Vector2(0, 35) * s, 52 * s, 8 * s, Color("334832", 0.23), 18)
	# Tail behind the body, sturdy legs and rounded Holstein coat.
	var tail_swing := sin(phase * 0.4) * 11.0
	view.line(
		at + Vector2(-48, -10) * s,
		at + Vector2(-61, -23 + tail_swing) * s,
		Color("e9e6d9"),
		6 * s
	)
	view.line(
		at + Vector2(-61, -23 + tail_swing) * s,
		at + Vector2(-65, -12 + tail_swing) * s,
		Color("524b40"),
		5 * s
	)
	for x in [-34, -10, 29, 47]:
		var stride := step if x < 0 else -step
		var rear_leg: bool = x == -10 or x == 47
		view.draw_rect(
			Rect2(at + Vector2(x - 5 + stride * 0.4, 5) * s, Vector2(11, 29) * s),
			Color("d8d7cd") if rear_leg else Color("f2ede0")
		)
		view.draw_rect(
			Rect2(at + Vector2(x - 6 + stride, 29) * s, Vector2(13, 7) * s), Color("65574b")
		)
		view.line(at + Vector2(x + stride, 31) * s, at + Vector2(x + stride, 36) * s, Color("b5a99b", 1.2 * s))
	var body := at + Vector2(0, -bob + breathe) * s
	view.ellipse(body + Vector2(-4, -12) * s, 54 * s, 31 * s, Color("deddd3"))
	view.ellipse(body + Vector2(-4, -16) * s, 54 * s, 30 * s, Color("f5f0e5"))
	view.ellipse(body + Vector2(-18, -33) * s, 29 * s, 9 * s, Color("fff9ee", 0.60))
	view.ellipse(body + Vector2(-29, -24) * s, 18 * s, 19 * s, Color("4d514d"))
	view.ellipse(body + Vector2(8, -6) * s, 24 * s, 14 * s, Color("565a56"))
	view.ellipse(body + Vector2(1, -33) * s, 8 * s, 7 * s, Color("555956"))
	view.ellipse(body + Vector2(15, 10) * s, 12 * s, 9 * s, Color("d9979e"))
	for x in [-2, 7, 15]:
		view.draw_circle(body + Vector2(x, 12) * s, 3 * s, Color("e8b8b8"))
	# Distinct friendly face and ears.
	var head := body + Vector2(0, sin(phase * 0.3) * (1.2 if walking else 3.0)) * s
	view.ellipse(head + Vector2(46, -35) * s, 26 * s, 28 * s, Color("f9f2e7"))
	view.ellipse(head + Vector2(44, -53) * s, 15 * s, 7 * s, Color("ede6d9"))
	view.ellipse(head + Vector2(22, -52) * s, 15 * s, 8 * s, Color("f1e4d3"))
	view.ellipse(head + Vector2(69, -54) * s, 15 * s, 8 * s, Color("f1e4d3"))
	view.ellipse(head + Vector2(22, -53) * s, 10 * s, 4 * s, Color("dba5a2"))
	view.ellipse(head + Vector2(69, -55) * s, 10 * s, 4 * s, Color("dba5a2"))
	view.line(head + Vector2(35, -57) * s, head + Vector2(34, -65) * s, Color("e7dbbb"), 6 * s)
	view.line(head + Vector2(57, -57) * s, head + Vector2(60, -64) * s, Color("e7dbbb"), 6 * s)
	if fposmod(view.shimmer + phase * 0.11, 5.0) < 0.17:
		view.line(head + Vector2(34, -40) * s, head + Vector2(42, -40) * s, Color("443b35"), 2 * s)
		view.line(head + Vector2(51, -40) * s, head + Vector2(59, -40) * s, Color("443b35"), 2 * s)
	else:
		view.draw_circle(head + Vector2(38, -40) * s, 4 * s, Color("443b35"))
		view.draw_circle(head + Vector2(55, -40) * s, 4 * s, Color("443b35"))
	view.ellipse(head + Vector2(46, -22 + sin(phase * 0.46) * 1.1) * s, 23 * s, 14 * s, Color("efb5b3"))
	view.ellipse(head + Vector2(45, -26) * s, 15 * s, 5 * s, Color("f8cfcb", 0.55))
	for x in [36, 55]:
		view.draw_circle(head + Vector2(x, -23) * s, 3.2 * s, Color("9c7470"))


static func paint_small_paddock(view: FarmView, at: Vector2, _coat: Color, title: String) -> void:
	(
		view
		. poly(
			PackedVector2Array(
				[
					at + Vector2(-133, -65),
					at + Vector2(-100, -105),
					at + Vector2(98, -105),
					at + Vector2(132, -65),
					at + Vector2(130, 88),
					at + Vector2(-133, 88),
				]
			),
			Color("e5ca91")
		)
	)
	(
		view
		. poly(
			PackedVector2Array(
				[
					at + Vector2(-120, -59),
					at + Vector2(-93, -89),
					at + Vector2(91, -89),
					at + Vector2(118, -59),
					at + Vector2(117, 77),
					at + Vector2(-120, 77),
				]
			),
			Color("bb975f") if title == "BABI" else Color("b4be7a")
		)
	)
	LivestockPainter.paint_pen_rail(view, at + Vector2(-129, -60), at + Vector2(-100, -96), 3)
	LivestockPainter.paint_pen_rail(view, at + Vector2(-100, -96), at + Vector2(100, -96), 6)
	LivestockPainter.paint_pen_rail(view, at + Vector2(100, -96), at + Vector2(129, -60), 3)
	LivestockPainter.paint_feed_trough(view, at + Vector2(-94, 6), 0.5)
	var kind := "pig" if title == "BABI" else "goat"
	var seed_offset := 0.0 if kind == "pig" else 10.0
	view.paint_roaming_animal(kind, at + Vector2(-56, -9), 0.88, 2.1 + seed_offset, Vector2(15, 13))
	view.paint_roaming_animal(kind, at + Vector2(46, 1), 0.79, 4.7 + seed_offset, Vector2(16, 14))
	view.paint_roaming_animal(kind, at + Vector2(0, 43), 0.65, 7.2 + seed_offset, Vector2(15, 9))
	LivestockPainter.paint_pen_rail(view, at + Vector2(-129, -60), at + Vector2(-133, 88), 5)
	LivestockPainter.paint_pen_rail(view, at + Vector2(129, -60), at + Vector2(130, 88), 5)
	LivestockPainter.paint_pen_rail(view, at + Vector2(-133, 88), at + Vector2(130, 88), 7)
	view.draw_rect(Rect2(at + Vector2(-52, -119), Vector2(104, 28)), Color("966339"))
	view.draw_rect(Rect2(at + Vector2(-48, -116), Vector2(96, 22)), Color("ffda98"))
	view.label(title, at + Vector2(-43, -99), 17, Color("755336"))


static func paint_pig(
	view: FarmView, at: Vector2, scale_factor: float, walking: bool, phase: float
) -> void:
	var s := scale_factor
	var step := sin(phase) * (6.0 if walking else 0.0)
	var bob := absf(sin(phase)) * (3.0 if walking else 0.5)
	var breathe := sin(phase * 0.34) * 1.0
	view.ellipse(at + Vector2(1, 27) * s, 45 * s, 12 * s, Color("583b39", 0.10), 16)
	view.ellipse(at + Vector2(0, 27) * s, 36 * s, 7 * s, Color("583b39", 0.22), 16)
	for x in [-25, -3, 22, 32]:
		var stride := step if x < 0 else -step
		view.line(at + Vector2(x, 4) * s, at + Vector2(x + stride, 25) * s,
			Color("c98591") if x == -3 or x == 32 else Color("e39ca5"), 10 * s)
		view.line(
			at + Vector2(x + stride - 5, 25) * s,
			at + Vector2(x + stride + 4, 25) * s,
			Color("a26770"),
			4 * s
		)
		view.line(at + Vector2(x + stride, 23) * s, at + Vector2(x + stride, 27) * s,
			Color("f4bec0"), 1.2 * s)
	var body := at + Vector2(0, -bob + breathe) * s
	# A visible spiral gives the pig its characteristic curled tail.
	var tail_lift := sin(phase * 0.52) * 3.0
	view.line(
		body + Vector2(-36, -8) * s,
		body + Vector2(-47, -18 + tail_lift) * s,
		Color("e99caa"),
		4 * s
	)
	view.line(body + Vector2(-47, -18 + tail_lift) * s,
		body + Vector2(-54, -24 + tail_lift) * s, Color("d98998"), 3 * s)
	view.line(body + Vector2(-54, -24 + tail_lift) * s,
		body + Vector2(-58, -17 + tail_lift) * s, Color("d98998"), 3 * s)
	view.line(body + Vector2(-58, -17 + tail_lift) * s,
		body + Vector2(-53, -14 + tail_lift) * s, Color("d98998"), 3 * s)
	view.ellipse(body + Vector2(-8, -6) * s, 40 * s, 24 * s, Color("df9ca5"))
	view.ellipse(body + Vector2(-8, -10) * s, 40 * s, 24 * s, Color("f3b2b9"))
	view.ellipse(body + Vector2(-21, -20) * s, 16 * s, 10 * s, Color("f9c6c8", 0.65))
	view.ellipse(body + Vector2(-11, 4) * s, 21 * s, 8 * s, Color("f8c6c6", 0.35))
	var head := body + Vector2(0, sin(phase * 0.38) * (1.0 if walking else 2.1)) * s
	view.ellipse(head + Vector2(24, -18) * s, 23 * s, 21 * s, Color("efabb2"))
	view.poly(
		PackedVector2Array(
			[head + Vector2(12, -32) * s, head + Vector2(10, -53) * s, head + Vector2(27, -37) * s]
		),
		Color("e894a0")
	)
	view.poly(
		PackedVector2Array(
			[head + Vector2(28, -37) * s, head + Vector2(37, -51) * s, head + Vector2(44, -28) * s]
		),
		Color("f6bfc3")
	)
	view.poly(PackedVector2Array([
		head + Vector2(16, -34) * s, head + Vector2(13, -45) * s,
		head + Vector2(23, -36) * s
	]), Color("c97e8e"))
	view.poly(PackedVector2Array([
		head + Vector2(31, -35) * s, head + Vector2(37, -45) * s,
		head + Vector2(40, -32) * s
	]), Color("e99da8"))
	view.ellipse(head + Vector2(40, -9) * s, 16 * s, 11 * s, Color("d98694"))
	view.ellipse(head + Vector2(40, -11) * s, 15 * s, 9 * s, Color("f2aeba"))
	for dx in [35, 45]:
		view.draw_circle(head + Vector2(dx, -9) * s, 2.7 * s, Color("aa6471"))
	if fposmod(view.shimmer + phase * 0.12, 4.7) < 0.15:
		view.line(head + Vector2(25, -22) * s, head + Vector2(32, -22) * s,
			Color("5d4542"), 2 * s)
	else:
		view.draw_circle(head + Vector2(28, -22) * s, 3.2 * s, Color("5d4542"))
		view.draw_circle(head + Vector2(29, -23) * s, 0.9 * s, Color("fff0e8"))
	view.ellipse(head + Vector2(21, -9) * s, 6 * s, 3 * s, Color("f8c3c6", 0.6))


static func paint_goat(
	view: FarmView, at: Vector2, scale_factor: float, walking: bool, phase: float
) -> void:
	var s := scale_factor
	var step := sin(phase) * (6.0 if walking else 0.0)
	var bob := absf(sin(phase)) * (2.5 if walking else 0.5)
	var breathe := sin(phase * 0.29) * 0.9
	view.ellipse(at + Vector2(1, 30) * s, 48 * s, 12 * s, Color("384a32", 0.10), 16)
	view.ellipse(at + Vector2(0, 30) * s, 38 * s, 7 * s, Color("384a32", 0.21), 16)
	for x in [-23, -7, 16, 30]:
		var stride := step if x < 0 else -step
		view.line(at + Vector2(x, -5) * s, at + Vector2(x + stride, 28) * s,
			Color("c4b092") if x == -7 or x == 30 else Color("e5d4b7"), 9 * s)
		view.line(
			at + Vector2(x + stride - 5, 28) * s,
			at + Vector2(x + stride + 4, 28) * s,
			Color("695b4c"),
			5 * s
		)
		view.line(at + Vector2(x + stride, 26) * s, at + Vector2(x + stride, 30) * s,
			Color("a39786"), 1.2 * s)
	var body := at + Vector2(0, -bob + breathe) * s
	var tail_lift := sin(phase * 0.4) * 5.0
	view.line(
		body + Vector2(-37, -18) * s,
		body + Vector2(-49, -30 + tail_lift) * s,
		Color("e3d1b1"),
		7 * s
	)
	view.ellipse(body + Vector2(-49, -31 + tail_lift) * s, 8 * s, 5 * s, Color("f0e1c6"))
	view.ellipse(body + Vector2(-5, -16) * s, 38 * s, 23 * s, Color("ccbea4"))
	view.ellipse(body + Vector2(-5, -20) * s, 38 * s, 23 * s, Color("ece2c9"))
	view.ellipse(body + Vector2(-13, -32) * s, 23 * s, 7 * s, Color("faf0dc", 0.62))
	view.ellipse(body + Vector2(-21, -14) * s, 13 * s, 15 * s, Color("c49b79"))
	view.ellipse(body + Vector2(13, -25) * s, 14 * s, 19 * s, Color("f6ead4"))
	# Tiny chest tufts and a swinging beard distinguish goats from sheep.
	for x in [10.0, 17.0, 24.0]:
		view.poly(PackedVector2Array([
			body + Vector2(x - 5, -14) * s, body + Vector2(x, -5) * s,
			body + Vector2(x + 5, -16) * s
		]), Color("f1e5cc"))
	var head := body + Vector2(0, sin(phase * 0.35) * (1.0 if walking else 2.4)) * s
	view.ellipse(head + Vector2(25, -33) * s, 16 * s, 23 * s, Color("f4e8d0"))
	# Curved horn tips and wide ears remain readable at small scale.
	view.line(head + Vector2(16, -50) * s, head + Vector2(11, -63) * s, Color("ad9474"), 6 * s)
	view.line(head + Vector2(11, -63) * s, head + Vector2(15, -73) * s, Color("c6af87"), 4 * s)
	view.line(head + Vector2(31, -50) * s, head + Vector2(37, -63) * s, Color("ad9474"), 6 * s)
	view.line(head + Vector2(37, -63) * s, head + Vector2(35, -72) * s, Color("c6af87"), 4 * s)
	var ear_twitch := sin(phase * 0.47) * 1.6
	view.ellipse(head + Vector2(8, -43 + ear_twitch) * s, 15 * s, 7 * s, Color("e3d1b1"))
	view.ellipse(head + Vector2(41, -43 - ear_twitch) * s, 14 * s, 7 * s, Color("e3d1b1"))
	view.ellipse(head + Vector2(7, -43 + ear_twitch) * s, 10 * s, 3.3 * s, Color("d1a995"))
	view.ellipse(head + Vector2(42, -43 - ear_twitch) * s, 9 * s, 3.3 * s, Color("d1a995"))
	view.ellipse(head + Vector2(35, -23) * s, 13 * s, 11 * s, Color("e5cfb2"))
	view.ellipse(head + Vector2(38, -26) * s, 9 * s, 5 * s, Color("f5e0c6", 0.8))
	view.poly(
		PackedVector2Array(
			[head + Vector2(22, -16) * s, head + Vector2(29 + sin(phase * 0.5), 3) * s,
			 head + Vector2(33, -16) * s]
		),
		Color("c4aa8a")
	)
	if fposmod(view.shimmer + phase * 0.09, 5.4) < 0.15:
		view.line(head + Vector2(25, -38) * s, head + Vector2(32, -38) * s,
			Color("58473b"), 2 * s)
	else:
		view.draw_circle(head + Vector2(29, -38) * s, 3 * s, Color("58473b"))
		view.draw_circle(head + Vector2(30, -39) * s, 0.9 * s, Color("fffaf0"))
	view.draw_circle(head + Vector2(40, -24) * s, 2.5 * s, Color("816b5a"))
