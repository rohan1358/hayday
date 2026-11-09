class_name OrchardPainter
extends RefCounted


static func paint(view: FarmView, game: FarmGameState, index: int, at: Vector2) -> void:
	var slot: Dictionary = game.orchard[index]
	var fruit_id: String = slot["fruit"]
	view.ellipse(at + Vector2(0, 10), 58, 22, Color("75b65a"))
	view.ellipse(at + Vector2(0, 12), 45, 12, Color("c19a67"))
	if fruit_id == "":
		for dx in [-20, 0, 19]:
			view.line(at + Vector2(dx, 4), at + Vector2(dx + 9, -4), Color("855c3e"), 3)
		view.bubble("+ POHON", at + Vector2(0, -49), Color("fff1bd"), Color("78522b"))
	else:
		var info: Dictionary = FarmGameState.FRUITS[fruit_id]
		var ready := game.tree_ready(index)
		if view.farm_art.paint(view, "apple_tree", at, 145.0):
			# Ripe citrus reads as orange while sharing the authored orchard silhouette.
			if ready and fruit_id == "jeruk":
				for offset in [Vector2(-34, -80), Vector2(23, -97), Vector2(38, -54)]:
					view.draw_circle(at + offset, 7, Color("e89931"))
					view.draw_circle(at + offset + Vector2(-2, -2), 2.8, Color("ffdf83"))
		else:
			view.paint_fruit_tree(at, Color(info["color"]), ready)
		if ready:
			view.bubble("PANEN!", at + Vector2(0, -159), Color("fff2b6"), Color("8b5624"))
		else:
			var remaining := maxi(0, int(slot["ready_at"]) - game.now())
			view.bubble("%ds" % remaining, at + Vector2(0, -159), Color("f5fae3"), Color("3c7743"))
	view.draw_rect(Rect2(at.x - 31, at.y + 16, 62, 19), Color("946e43"))
	view.label("BUAH %d" % (index + 1), at + Vector2(-27, 30), 14, Color("fff9df"))
