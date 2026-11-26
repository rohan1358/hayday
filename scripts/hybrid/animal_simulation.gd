extends RefCounted
const STATE=preload("res://scripts/hybrid/hybrid_state.gd")
var system
var agents: Dictionary={}
var clock=0.0
var rng=RandomNumberGenerator.new()
func configure(owner_system) -> void:
	system=owner_system
	rng.seed=813754
	ensure_animals()
func enabled(species: String) -> bool:
	if not system.host.game.ftue.is_empty():
		if not system.host.game.feature_unlocked("ranch"): return false
		if species=="ayam": return preload("res://scripts/first_coop.gd").built(system.host.game)
		if system.host.game.level<5: return false
	if species in ["ayam","sapi"]: return true
	if species=="domba": return bool(system.data.sheep_owned)
	return system.host.game.has_construction("kandang_"+species)
func animal(id: String) -> Dictionary:
	for value in system.data.animals:
		if str(value.id)==id: return value
	return {}
func zone(id: int) -> Dictionary:
	for value in system.data.zones:
		if int(value.id)==id: return value
	return {}
func position(value: Dictionary) -> Vector2:
	if value.get("legacy_pen",false):
		var animator=system.farm.ranch_animator
		var key=str(value.species)+"_0"
		if animator!=null and animator.agents.has(key) and animator.agents[key].world!=Vector2.ZERO: return animator.agents[key].world
		return system.farm.object_position(str(value.species))
	return STATE.point(value.get("position",[]))
func ensure_animals() -> void:
	var defaults={"ayam":Rect2(1510,150,430,310),"sapi":Rect2(520,1980,460,330),"babi":Rect2(1750,1630,450,320),"kambing":Rect2(2290,1100,450,320),"domba":Rect2(1690,2110,460,330)}
	for species in STATE.SPECIES:
		if not enabled(species): continue
		if not animal(species+"_1").is_empty(): continue
		if species in ["ayam","sapi","babi","kambing"]:
			system.data.animals.append({"id":species+"_1","species":species,"legacy_pen":true,"zone":-1,"position":[0,0],"hunger":85.0,"thirst":85.0,"energy":90.0,"cleanliness":90.0,"affection":0.0,"state":"idle","wool_ready_at":0})
			system.dirty=true
			continue
		var bounds: Rect2=defaults[species]
		var id=int(system.data.next_zone)
		system.data.next_zone=id+1
		var created={"id":id,"name":"Zona "+species.capitalize(),"position":STATE.array_point(bounds.position),"size":STATE.array_point(bounds.size),"gate_open":false,"feed":0,"water":0}
		system.data.zones.append(created)
		system.navigation.ensure()
		var spawn=safe_point(created,bounds.get_center())
		if spawn==Vector2.INF: spawn=bounds.get_center()
		system.data.animals.append({"id":species+"_1","species":species,"zone":id,"position":STATE.array_point(spawn),"hunger":85.0,"thirst":85.0,"energy":90.0,"cleanliness":90.0,"affection":0.0,"state":"idle","wool_ready_at":0})
		system.dirty=true
func safe_point(area: Dictionary,desired: Vector2,except_id: String="") -> Vector2:
	var bounds=STATE.zone_rect(area).grow(-24)
	if STATE.zone_contains(area,desired,24) and not system.navigation.blocked(desired) and not occupied(desired,except_id,38): return desired
	var best=Vector2.INF
	var best_distance=INF
	for y in range(int(bounds.position.y),int(bounds.end.y),20):
		for x in range(int(bounds.position.x),int(bounds.end.x),20):
			var point=Vector2(x,y)
			if not STATE.zone_contains(area,point,24) or system.navigation.blocked(point) or occupied(point,except_id,38): continue
			var distance=point.distance_squared_to(desired)
			if distance<best_distance:
				best_distance=distance
				best=point
	return best
func occupied(point: Vector2,except_id: String="",radius=26.0) -> bool:
	for value in system.data.animals:
		if str(value.id)!=except_id and position(value).distance_to(point)<radius: return true
	return false
func route(value: Dictionary,target: Vector2,allow_transit=false) -> bool:
	var area=zone(int(value.zone))
	if area.is_empty(): return false
	if not allow_transit and not STATE.zone_contains(area,target,20): return false
	var avoid: Array=[{"at":system.farm.ujang_position,"radius":32.0}]
	for other in system.data.animals:
		if str(other.id)!=str(value.id): avoid.append({"at":position(other),"radius":30.0})
	var path: PackedVector2Array=system.navigation.path(position(value),target,avoid)
	if path.is_empty(): return false
	var agent: Dictionary=agents.get(str(value.id),{})
	agent.path=path
	agent.cursor=1
	agent.destination=target
	agent.blocked_time=0.0
	agents[str(value.id)]=agent
	return true
func herd(id: String,target_zone: int) -> bool:
	var value=animal(id)
	var destination=zone(target_zone)
	if value.is_empty() or destination.is_empty(): return false
	var point=safe_point(destination,STATE.zone_rect(destination).get_center(),id)
	if point==Vector2.INF or not route(value,point,true): return false
	value.state="herd"
	agents[id].target_zone=target_zone
	agents[id].herding=true
	return true
func cancel_herd(id: String) -> void:
	var value=animal(id)
	if value.is_empty(): return
	agents.erase(id)
	value.state="idle"
func tick(delta: float) -> void:
	clock+=delta
	if clock<0.2: return
	var step=minf(clock,0.5)
	clock=0.0
	for value in system.data.animals:
		STATE.needs_tick(value,step)
		if value.get("legacy_pen",false):
			value.position=STATE.array_point(position(value))
			continue
		var id=str(value.id)
		if not agents.has(id): agents[id]={"decision":rng.randf_range(0.5,2.5),"path":PackedVector2Array(),"cursor":0,"herding":false,"blocked_time":0.0}
		var agent: Dictionary=agents[id]
		var area=zone(int(value.zone))
		if area.is_empty(): continue
		var at=position(value)
		if system.navigation.blocked(at) or not agent.get("herding",false) and not STATE.zone_contains(area,at,16):
			var replacement=safe_point(area,at,id)
			if replacement!=Vector2.INF:
				value.position=STATE.array_point(replacement)
				at=replacement
		var path: PackedVector2Array=agent.get("path",PackedVector2Array())
		var cursor=int(agent.get("cursor",0))
		if cursor<path.size():
			var waypoint=path[cursor]
			var next=at.move_toward(waypoint,step*(72 if agent.get("herding",false) else 38))
			var allowed: bool=agent.get("herding",false) or STATE.zone_contains(area,next,16)
			if allowed and system.navigation.clear_segment(at,next) and not occupied(next,id,30) and next.distance_to(system.farm.ujang_position)>30:
				value.position=STATE.array_point(next)
				value.facing=-1 if next.x<at.x else 1
				value.direction=STATE.array_point((next-at).normalized())
				value.state="herd" if agent.get("herding",false) else "walk"
				agent.blocked_time=0.0
				if next.distance_to(waypoint)<3: agent.cursor=cursor+1
			else:
				agent.blocked_time=float(agent.get("blocked_time",0))+step
				if float(agent.blocked_time)>1.5:
					if agent.get("herding",false):
						var destination_zone: Dictionary=zone(int(agent.get("target_zone",-1)))
						if not destination_zone.is_empty():
							var destination_point=safe_point(destination_zone,STATE.zone_rect(destination_zone).get_center(),id)
							if destination_point!=Vector2.INF and route(value,destination_point,true):
								agent.blocked_time=0.0
								continue
					agent.path=PackedVector2Array()
					value.state="blocked" if agent.get("herding",false) else "idle"
			continue
		if agent.get("herding",false):
			if value.state!="blocked":
				value.zone=int(agent.target_zone)
				value.state="idle"
			agent.herding=false
			system.dirty=true
		if str(value.state)=="sleep" and float(value.energy)<90: continue
		if value.state in ["eat","drink"]:
			agent.decision=float(agent.get("decision",0))-step
			if float(agent.decision)>0: continue
		agent.decision=float(agent.get("decision",0))-step
		if float(agent.decision)>0: continue
		agent.decision=rng.randf_range(3,6)
		if float(value.energy)<24:
			value.state="sleep"
			continue
		if float(value.hunger)<65 and int(area.feed)>0:
			area.feed=int(area.feed)-1
			value.hunger=minf(100,float(value.hunger)+40)
			value.state="eat"
			system.dirty=true
			continue
		if float(value.thirst)<65 and int(area.water)>0:
			area.water=int(area.water)-1
			value.thirst=minf(100,float(value.thirst)+45)
			value.state="drink"
			system.dirty=true
			continue
		# Curious animals turn toward a nearby quiet player; running scares them.
		if at.distance_to(system.farm.ujang_position)<105:
			value.facing=-1 if system.farm.ujang_position.x<at.x else 1
			value.state="curious"
			if system.running:
				var away: Vector2=at+(at-system.farm.ujang_position).normalized()*80
				route(value,away)
			continue
		value.state="idle"
		if rng.randf()<0.70:
			var bounds=STATE.zone_rect(area).grow(-35)
			var target=Vector2(rng.randf_range(bounds.position.x,bounds.end.x),rng.randf_range(bounds.position.y,bounds.end.y))
			if not system.navigation.blocked(target): route(value,target)
