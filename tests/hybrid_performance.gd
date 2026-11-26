extends SceneTree
var failures=0
func _initialize(): call_deferred("run")
func run():
	var main=load("res://scenes/Main.tscn").instantiate()
	main.game.save_path="user://hybrid_perf.json"
	main.game.backup_path="user://hybrid_perf_backup.json"
	DirAccess.remove_absolute(main.game.save_path)
	DirAccess.remove_absolute(main.game.backup_path)
	main.game.level=3
	main.game.constructions["kandang_babi"]=1
	main.game.constructions["kandang_kambing"]=1
	main.game.hybrid={"sheep_owned":true}
	root.add_child(main)
	main.game.skip_onboarding()
	main.refresh_all()
	var system=main.farm.hybrid_controller
	# Every accessible bed must have an approach, not just a direct click in a test.
	for i in main.game.plots.size():
		if not main.game.plots[i].unlocked: continue
		var route=system.navigation.approach(main.farm.ujang_position,main.farm.plot_center(i),215)
		if route.is_empty():
			failures+=1
			print("UNREACHABLE STARTER PLOT: ",i)
	print("STARTER PLOT APPROACH FAILURES: ",failures)
	for i in 30: await process_frame
	var start=Time.get_ticks_msec()
	var samples=0
	var process_total=0.0
	var draw_total=0.0
	var process_peak=0.0
	system.data.follow=false
	system.enqueue({"action":"move","position":[1200,1930]})
	while Time.get_ticks_msec()-start<2500:
		await process_frame
		var ms=float(Performance.get_monitor(Performance.TIME_PROCESS))*1000
		process_total+=ms
		process_peak=maxf(process_peak,ms)
		draw_total+=float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		samples+=1
	print("DESKTOP HYBRID PERF samples=%d avg_process_ms=%.2f peak_process_ms=%.2f avg_draw_calls=%.1f fps=%d animals=%d nav_builds=%d"%[samples,process_total/maxi(1,samples),process_peak,draw_total/maxi(1,samples),Engine.get_frames_per_second(),system.data.animals.size(),system.navigation.build_count])
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)
