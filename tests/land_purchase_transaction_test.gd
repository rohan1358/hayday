extends SceneTree
func _initialize(): call_deferred("run")
func run():
	for starter in [true,false]:
		var game=FarmGameState.new(starter)
		game.save_path="user://land_transaction_%s.json"%str(starter)
		game.backup_path="user://land_transaction_%s_backup.json"%str(starter)
		if starter:
			game.ftue.started=true
			game.ftue.step="done"
		game.level=4
		game.coins=50000
		assert(game.land_cost()==120,"First expansion uses positive base price on both profiles")
		var previous_price=35
		for i in game.plots.size():
			if game.plots[i].unlocked: continue
			var price=game.land_cost()
			assert(price==previous_price+85)
			var before=game.coins
			assert(game.unlock_plot(i) and game.coins==before-price)
			assert(not game.unlock_plot(i) and game.coins==before-price,"Repeat purchase cannot charge or grant coins")
			previous_price=price
		var copy=FarmGameState.new()
		copy.save_path=game.save_path;copy.backup_path=game.backup_path
		assert(copy.load_game() and copy.coins==game.coins)
		for plot in copy.plots: assert(plot.unlocked)
	var poor=FarmGameState.new()
	poor.save_path="user://land_transaction_poor.json"
	poor.backup_path="user://land_transaction_poor_backup.json"
	poor.ftue.started=true;poor.ftue.step="done";poor.level=2
	poor.coins=119
	assert(not poor.unlock_plot(3) and poor.coins==119 and not poor.plots[3].unlocked)
	poor.coins=120
	assert(poor.unlock_plot(3) and poor.coins==0)
	assert(not poor.unlock_plot(-1) and not poor.unlock_plot(999) and poor.coins==0)
	print("LAND TRANSACTION PASS: positive first price 120, +85 per expansion, exact deductions, repeat/insufficient/invalid guards, legacy profile and save/load")
	quit()
