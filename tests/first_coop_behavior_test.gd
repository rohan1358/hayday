extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://first_coop_behavior.json"
	host.game.backup_path="user://first_coop_behavior_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	for frame in 3: await process_frame
	host.game.ftue.started=true
	host.game.ftue.step="done"
	host.game.level=3
	host.game.coins=500
	assert(preload("res://scripts/first_coop.gd").build(host.game))
	var animator=host.farm.ranch_animator
	animator.sync()
	print("AGENTS ",animator.agents.keys())
	assert(animator.agents.values().filter(func(a): return a.species=="ayam").size()==2)
	var states={}
	var spots={}
	var last={}
	for step in 2400:
		animator.tick(0.05)
		for key in animator.agents:
			var bird=animator.agents[key]
			if bird.species!="ayam": continue
			assert(animator.allowed("ayam",bird.uv),"Chicken stays inside the fenced floor")
			states[bird.state]=true
			spots[str(bird.uv.snapped(Vector2.ONE*0.1))]=true
			if bird.state!="walk" and last.has(key): assert(bird.uv.distance_to(last[key])<0.02,"Pausing birds must not orbit")
			last[key]=bird.uv
	assert(states.has("walk") and states.has("graze") and states.has("rest"))
	assert(spots.size()>10)
	var bird=animator.agents.values().filter(func(a): return a.species=="ayam")[0]
	var before=animator.pen_point("ayam",bird.uv)
	host.game.layout_positions.ayam=[1600,900]
	var after=animator.pen_point("ayam",bird.uv)
	assert(before!=after and animator.allowed("ayam",bird.uv),"Moving the coop moves its animals with it")
	host.queue_free();await process_frame
	print("FIRST COOP BEHAVIOR PASS: 120 simulated seconds; walk, peck, rest, bounded floor, no orbit while paused, movable coop")
	quit()
