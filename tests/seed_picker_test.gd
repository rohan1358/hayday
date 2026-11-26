extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://seed_picker_test.json"
	host.game.backup_path="user://seed_picker_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.new_game(false)
	var guide=preload("res://scripts/cheerful_menus.gd").guide(host)
	if guide!=null: guide.hide()
	var system=host.farm.hybrid_controller
	system.set_process(false)
	host.set_process(false)
	system.ui.set_process(false)
	host.game.level=2
	system.data.manager=false
	system.selected_tool="auto"
	system.tap_world(host.farm.plot_center(0))
	assert(system.ui.menu.visible and system.ui.section=="seeds" and system.ui.seed_plot==0)
	assert(system.data.jobs.is_empty() and host.game.plots[0].crop=="")
	var locked=system.ui.content.find_child("SeedChoice_stroberi_kristal",true,false) as Button
	assert(locked!=null and locked.disabled)
	system.ui.select_seed("stroberi_kristal")
	assert(host.game.selected_crop=="gandum")
	system.ui.select_seed("jagung")
	assert(host.game.selected_crop=="jagung" and system.data.jobs.is_empty())
	system.ui.confirm_seed_plant()
	assert(not system.ui.menu.visible and system.data.jobs.size()==1)
	assert(system.data.jobs[0].crop=="jagung")
	system.ui.select_seed("gandum")
	assert(system.data.jobs[0].crop=="jagung")
	system.data.manager=true
	for i in 40: system.tick_jobs(0.1)
	assert(host.game.plots[0].crop=="jagung")
	assert(system.data.jobs.is_empty() and system.active.is_empty())
	host.game.selected_crop="jagung"
	host.game.seeds.jagung=0
	host.game.coins=1
	system.ui.open_seed_picker(1)
	var confirm=system.ui.content.find_child("ConfirmSeedPlant",true,false) as Button
	assert(confirm!=null and confirm.disabled)
	system.ui.buy_seed("jagung")
	assert(host.game.coins==1 and host.game.seeds.jagung==0)
	host.game.coins=100
	system.ui.buy_seed("jagung")
	assert(host.game.coins==92 and host.game.seeds.jagung==1)
	host.game.plots[1].crop="gandum"
	system.ui.confirm_seed_plant()
	assert(system.data.jobs.is_empty() and system.ui.menu.visible)
	host.game.level=20
	system.ui.open_seed_picker(-1)
	locked=system.ui.content.find_child("SeedChoice_stroberi_kristal",true,false) as Button
	assert(not locked.disabled)
	system.ui.select_seed("stroberi_kristal")
	var copy=FarmGameState.new()
	copy.save_path=host.game.save_path
	copy.backup_path=host.game.backup_path
	assert(copy.load_game() and copy.selected_crop=="stroberi_kristal")
	system.ui._process(0.4)
	assert(system.ui.seed_button.visible and system.ui.seed_button.text.contains("Stroberi Kristal"))
	host.queue_free()
	await process_frame
	print("SEED PICKER PASS: empty-plot tap opens choice; level locks and stock; explicit plant confirmation; queued crop snapshot; buy/no-coins guard; occupied-target guard; Lv20 crystal selection; persistent shortcut and save/load")
	quit()
