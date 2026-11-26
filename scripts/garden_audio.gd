extends Node
# Presentation-only audio: no timers, purchases or gameplay rewards depend on it.
const FOLDER="res://assets/audio/garden/"
const CONFIG="user://garden_audio.cfg"
const BUSES=["GardenMusic","GardenSfx","GardenAmbience"]
var volumes={"music":0.55,"sfx":0.75,"ambience":0.4}
var muted=false
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var pool: Array[AudioStreamPlayer]=[]
var cursor=0
var cache: Dictionary={}
var last: Dictionary={}
var host
var level=1
var coins=0
var step_time=0.0
var save_timer=0.0
var weather_timer=0.0
var weather_id="garden_ambience"
var seasons: Node
func _ready():
	name="GardenAudio"
	add_to_group("garden_audio")
	host=get_parent();level=host.game.level;coins=host.game.coins
	var cfg=ConfigFile.new()
	if cfg.load(CONFIG)==OK:
		for key in volumes: volumes[key]=clampf(float(cfg.get_value("audio",key,volumes[key])),0,1)
		muted=bool(cfg.get_value("audio","muted",false))
	for bus in BUSES:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
			AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
	apply_volumes()
	for i in 8: pool.append(player("GardenSfx"))
	music=player("GardenMusic");music.stream=loop_stream("meadow_morning");music.play()
	ambience=player("GardenAmbience");ambience.stream=loop_stream("garden_ambience");ambience.play()
	if host.animal_audio!=null: host.animal_audio.bus="GardenSfx"
	if host.axe_audio!=null: host.axe_audio.bus="GardenSfx"
	for child in host.get_children():
		if child.get_script()==load("res://scripts/seasonal_ui.gd"): seasons=child
	bind_tree(host)
	get_tree().node_added.connect(on_node_added)
func player(bus: String) -> AudioStreamPlayer:
	var node=AudioStreamPlayer.new();node.bus=bus;add_child(node);return node
func loop_stream(id: String) -> AudioStream:
	var stream=load(FOLDER+id+".wav") as AudioStreamWAV
	if stream==null: return null
	stream=stream.duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=int(stream.get_length()*stream.mix_rate)
	return stream
func bind_tree(node: Node):
	bind_button(node)
	for child in node.get_children(): bind_tree(child)
func on_node_added(node: Node):
	if host.is_ancestor_of(node): bind_button(node)
func bind_button(node: Node):
	if node is BaseButton and not node.has_meta("garden_audio_bound"):
		node.set_meta("garden_audio_bound",true)
		node.pressed.connect(play.bind("click"))
func play(id: String):
	var aliases={"refill":"water","drink":"water","eggs":"collect","shear":"collect","orchard":"harvest","chop_done":"gather","chop_hit":"gather","reject":"error","purchase":"coin","harvest_ready":"collect","herd":"pet"}
	id=str(aliases.get(id,id))
	if id in ["open","move"]: pass
	if not ResourceLoader.exists(FOLDER+id+".wav"): return
	var now=Time.get_ticks_msec()
	if now-int(last.get(id,-10000))<90: return
	last[id]=now
	if muted or volumes.sfx<=0 or pool.is_empty(): return
	if not cache.has(id): cache[id]=load(FOLDER+id+".wav")
	var node=pool[cursor];cursor=(cursor+1)%pool.size()
	node.stop();node.stream=cache[id]
	node.pitch_scale=1.0 if id in ["level","mission"] else randf_range(0.97,1.03)
	node.play()
func notify(message: String):
	var text=message.to_lower()
	if "belum cukup" in text or "tidak bisa" in text or "gagal" in text: play("error")
	elif "upgrade" in text and ("selesai" in text or "berhasil" in text): play("build")
	elif "hadiah" in text or "misi selesai" in text: play("mission")
	elif "terjual" in text or "pesanan dikirim" in text: play("coin")
	elif "dipakai" in text or "terpasang" in text: play("move")
	elif "dibangun" in text or "diperluas" in text: play("build")
	elif "panen" in text and "selamat datang" not in text: play("harvest")
	elif "produksi" in text and "selesai" in text: play("collect")
	elif "pakan" in text or "makan" in text: play("feed")
	elif "siram" in text or "minum" in text: play("water")
func _process(dt):
	 # Level-up fanfare is played once by the animated popup when it appears.
	level=host.game.level
	if host.game.coins<coins: play("coin")
	coins=host.game.coins
	weather_timer+=dt
	if weather_timer>=1.0 and is_instance_valid(seasons):
		weather_timer=0.0
		var next="rain_ambience" if seasons.weather=="Hujan" else ("wind_ambience" if seasons.weather in ["Berangin","Salju","Berkabut"] else "garden_ambience")
		if next!=weather_id:
			weather_id=next;ambience.stream=loop_stream(next);ambience.play()
	step_time+=dt
	if host.active_tab=="kebun" and host.farm.hybrid_controller!=null:
		if host.farm.hybrid_controller.activity in ["walk","run"] and step_time>0.36:
			step_time=0;play("step")
	if save_timer>0:
		save_timer-=dt
		if save_timer<=0: save_settings()
func _notification(what):
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_RESUMED]:
		var pause=what==NOTIFICATION_APPLICATION_PAUSED
		if music!=null: music.stream_paused=pause
		if ambience!=null: ambience.stream_paused=pause
func set_volume(key: String,value: float):
	if not volumes.has(key): return
	volumes[key]=clampf(value,0,1);apply_volumes();save_timer=0.25
func apply_volumes():
	for pair in [["music","GardenMusic"],["sfx","GardenSfx"],["ambience","GardenAmbience"]]:
		var index=AudioServer.get_bus_index(pair[1])
		if index<0: continue
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,volumes[pair[0]])))
		AudioServer.set_bus_mute(index,muted or volumes[pair[0]]<=0)
func save_settings():
	var cfg=ConfigFile.new()
	for key in volumes: cfg.set_value("audio",key,volumes[key])
	cfg.set_value("audio","muted",muted);cfg.save(CONFIG)
func _exit_tree():
	if host!=null: save_settings()
static func settings(ui,list):
	var audio=ui.get_node_or_null("GardenAudio")
	if audio==null: return
	ui.callout(list,"MUSIK & SUARA","Atur musik kebun, efek tindakan, dan suasana alam.",Color("fff0cd"))
	for pair in [["music","Musik"],["sfx","Efek suara"],["ambience","Suasana alam"]]:
		var row=ui.row_card(list,95,Color("e7efdb"))
		var title=ui.label(row,pair[1]+" · %d%%"%int(audio.volumes[pair[0]]*100),Vector2(16,6),Vector2(560,28),18,ui.GREEN,true)
		var slider=HSlider.new();slider.name="Audio_"+pair[0]
		slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=audio.volumes[pair[0]]*100
		slider.position=Vector2(18,40);slider.size=Vector2(560,42);row.add_child(slider)
		slider.value_changed.connect(func(value): audio.set_volume(pair[0],value/100);title.text=pair[1]+" · %d%%"%int(value))
	var row=ui.row_card(list,76,Color("fff0cd"))
	var mute=ui.button(row,"AKTIFKAN SUARA" if audio.muted else "MATIKAN SEMUA SUARA",Vector2(14,10),Vector2(575,50),ui.GREEN,Color.WHITE,18)
	mute.pressed.connect(func(): audio.muted=not audio.muted;audio.apply_volumes();audio.save_settings();mute.text="AKTIFKAN SUARA" if audio.muted else "MATIKAN SEMUA SUARA")
