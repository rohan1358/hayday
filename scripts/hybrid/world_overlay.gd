extends FarmView
const STATE=preload("res://scripts/hybrid/hybrid_state.gd")
var system
var timer=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents=true
	game=system.host.game
func _process(delta: float) -> void:
	timer+=delta
	visible=system.host.active_tab=="kebun"
	if visible and timer>0.1:
		timer=0
		queue_redraw()
func _draw() -> void:
	if system!=null and preload("res://scripts/first_farm.gd").active(system.host.game): return
	if system==null: return
	var source=system.farm
	var factor: Vector2=source.size/source.get_virtual_size()*source.camera_zoom
	var origin: Vector2=(source.get_virtual_size()*0.5-source.camera_center*source.camera_zoom)*source.size/source.get_virtual_size()
	draw_set_transform(origin,0,factor)
	var upgrades=preload("res://scripts/building_upgrades.gd")
	var cottage: Vector2=source.object_position("dapur")
	label("RUMAH %d · DAPUR %d" % [upgrades.tier(game,"rumah"),upgrades.tier(game,"dapur")],cottage+Vector2(-80,42),16,Color("355b48"))
	var barn: Vector2=source.object_position("gudang")
	label("GUDANG %d" % upgrades.tier(game,"gudang"),barn+Vector2(-45,42),16,Color("355b48"))
	if preload("res://scripts/first_farm.gd").compact(game): return
	for zone in system.data.zones:
		var bounds=STATE.zone_rect(zone)
		for edge in system.navigation.fence_edges(zone):
			line(edge[0],edge[1],Color("956b46"),5)
			var count=maxi(2,int(edge[0].distance_to(edge[1])/45))
			for i in range(count+1):
				var at: Vector2=edge[0].lerp(edge[1],float(i)/count)
				line(at,at-Vector2(0,25),Color("dcbd83"),5)
		var polygon=STATE.zone_polygon(zone)
		var edge=clampi(int(zone.get("gate_edge",1)),0,3)
		var gate=(polygon[edge]+polygon[(edge+1)%4])*0.5
		label("GERBANG "+("BUKA" if zone.gate_open else "TUTUP"),gate+Vector2(-55,25),15,Color("355b48"))
		label(str(zone.name),bounds.position+Vector2(15,25),18,Color("355b48"))
		ellipse(bounds.get_center()+Vector2(-45,20),24,10,Color("669ebb"))
		ellipse(bounds.get_center()+Vector2(45,20),24,10,Color("ae8652"))
	if not system.route.is_empty():
		var points=PackedVector2Array([source.ujang_position])
		for i in range(system.cursor,system.route.size()): points.append(system.route[i])
		if points.size()>1: draw_polyline(points,Color("ffefab88"),3,true)
	if system.zone_first!=Vector2.INF:
		draw_circle(system.zone_first,8,Color("fae092"))
	var values: Array=system.data.animals.duplicate()
	values.sort_custom(func(a,b): return STATE.point(a.position).y<STATE.point(b.position).y)
	for value in values:
		if value.get("legacy_pen",false): continue
		var at=STATE.point(value.position)
		if not source.visible_world_rect(170).has_point(at): continue
		var walking: bool=str(value.state) in ["walk","herd"]
		var phase=float(Time.get_ticks_msec())/1000*8
		var facing=float(value.get("facing",1))
		draw_set_transform(origin+at*factor,0,Vector2(factor.x*facing,factor.y))
		match str(value.species):
			"ayam": paint_cached_animal("chicken",0.65,walking,phase)
			"sapi": paint_cached_animal("cow",0.42,walking,phase)
			"babi": LivestockPainter.paint_pig(self,Vector2.ZERO,0.65,walking,phase)
			"kambing": LivestockPainter.paint_goat(self,Vector2.ZERO,0.65,walking,phase)
			"domba":
				for i in 4:
					var step=sin(phase+(i%2)*PI)*4 if walking else 0.0
					line(Vector2(-20+i*13,-7),Vector2(-20+i*13+step,14),Color("77614b"),6)
				for i in 9: ellipse(Vector2(cos(i*TAU/9)*25,-24+sin(i*TAU/9)*12),16,15,Color("f4eedc"))
				ellipse(Vector2(34,-24),15,19,Color("82705c"))
				draw_circle(Vector2(40,-29),2.4,Color("fff6df"))
		if value.state=="sleep": label("Z z",Vector2(15,-65),20,Color("516c89"))
		elif value.state in ["eat","drink"]:
			var tilt=sin(phase)*3
			ellipse(Vector2(35,-5+tilt),10,4,Color("73afc4") if value.state=="drink" else Color("c4aa65"))
		draw_set_transform(origin,0,factor)
		if str(value.id)==system.selected_animal:
			draw_arc(at,45,0,TAU,24,Color("ffe59d"),3,true)
		if minf(float(value.hunger),float(value.thirst))<30: label("!",at+Vector2(0,-80),24,Color("c66e4b"))
	for key in system.data.crop_care:
		var index=int(key)
		if index<0 or index>=game.plots.size() or game.plots[index].crop=="": continue
		var care: Dictionary=system.data.crop_care[key]
		if int(care.get("planted_at",-1))!=int(game.plots[index].planted_at) or int(care.get("generation",-1))!=int(game.hybrid.get("crop_generation",{}).get(str(index),0)): continue
		var at: Vector2=source.plot_center(index)+Vector2(0,26)
		if care.get("water",false): draw_circle(at-Vector2(8,0),4,Color("66c2e3"))
		if care.get("fertilize",false): draw_circle(at+Vector2(8,0),4,Color("ddbc6a"))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func paint_cached_animal(kind: String,art_scale: float,walking: bool,phase: float) -> void:
	var frame=wrapi(floori(phase*float(ANIMAL_CACHE_POSES)/TAU),0,ANIMAL_CACHE_POSES)
	var key=system.farm.animal_frame_key(kind,walking,frame)
	var texture=system.farm.animal_frame_textures.get(key,null)
	if texture!=null:
		draw_texture_rect(texture,Rect2(-ANIMAL_CACHE_TEXTURE_CENTER*art_scale,Vector2(ANIMAL_CACHE_TEXTURE_SIZE)*art_scale),false)
	elif kind=="cow": LivestockPainter.paint_cow(self,Vector2.ZERO,art_scale,walking,phase)
	else: LivestockPainter.paint_chicken(self,Vector2.ZERO,art_scale,walking,phase)
