extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var host=load("res://scenes/Main.tscn").instantiate()
	host.game.save_path="user://garden_audio_test.json"
	host.game.backup_path="user://garden_audio_test_backup.json"
	DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	await process_frame
	var audio=host.get_node("GardenAudio")
	audio.set_process(false)
	var saved=audio.volumes.duplicate();var was_muted=audio.muted
	assert(audio.music.stream!=null and audio.music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
	assert(audio.music.stream.get_length()>40 and audio.ambience.stream.get_length()>20)
	assert(host.animal_audio.bus=="GardenSfx" and host.axe_audio.bus=="GardenSfx")
	audio.muted=false;audio.set_volume("sfx",0.75)
	for id in ["click","open","close","plant","water","fertilize","harvest","coin","build","move","error","level","mission","feed","collect","clean","pet","milk","step","gather"]:
		var stream=load("res://assets/audio/garden/"+id+".wav")
		assert(stream!=null and stream.get_length()>0 and stream.get_length()<2)
		audio.play(id)
	assert(audio.pool.size()==8,"SFX voice count stays bounded on Android")
	audio.set_volume("sfx",0)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("GardenSfx")))
	var new_button=Button.new();host.add_child(new_button)
	assert(new_button.has_meta("garden_audio_bound"),"New dynamic buttons receive click audio")
	host.game.ftue.started=true
	host.game.ftue.step="done"
	host.switch_tab("pengaturan")
	assert(host.sheet.find_child("Audio_music",true,false)!=null)
	var slider=host.sheet.find_child("Audio_ambience",true,false) as HSlider
	slider.value=23
	assert(is_equal_approx(audio.volumes.ambience,0.23))
	audio.save_settings()
	var cfg=ConfigFile.new();assert(cfg.load(audio.CONFIG)==OK)
	assert(is_equal_approx(float(cfg.get_value("audio","ambience")),0.23))
	var previous_weather=audio.seasons.weather
	audio.seasons.weather="Hujan";audio._process(1.1)
	assert(audio.weather_id=="rain_ambience" and audio.ambience.stream!=null)
	audio.seasons.weather="Berangin";audio._process(1.1)
	assert(audio.weather_id=="wind_ambience")
	audio.seasons.weather=previous_weather
	audio.volumes=saved;audio.muted=was_muted;audio.apply_volumes();audio.save_settings()
	host.queue_free();await process_frame
	print("GARDEN AUDIO PASS: original looped music/ambience, 20 SFX, bounded voices, native animal buses, dynamic buttons, settings, volume/mute and persistence")
	quit()
