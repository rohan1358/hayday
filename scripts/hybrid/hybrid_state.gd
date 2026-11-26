extends RefCounted
# Additive, versioned state. All coordinates are world-space [x,y] for JSON.
const VERSION = 4
const SPECIES = ["ayam", "sapi", "babi", "kambing", "domba"]
static func point(value: Variant, fallback = Vector2.ZERO) -> Vector2:
	if value is Array and value.size()==2:
		return Vector2(float(value[0]),float(value[1]))
	return fallback
static func array_point(value: Vector2) -> Array:
	return [value.x,value.y]
static func prepare(game) -> Dictionary:
	var data: Dictionary=game.hybrid
	var defaults={"version":VERSION,"player":[700,980],"jobs":[],"active":{},"next_job":1,"animals":[],"zones":[],"next_zone":1,"crop_care":{},"water":100,"fertilizer":8,"auto_work":false,"manager":false,"follow":true,"saved_at":game.now(),"sheep_owned":false,"history":[]}
	for key in defaults:
		if not data.has(key): data[key]=defaults[key]
	if not data.jobs is Array: data.jobs=[]
	if not data.active is Dictionary: data.active={}
	# An interrupted action has not committed any inventory mutation yet.
	if not data.active.is_empty():
		data.jobs.push_front(data.active.duplicate(true))
		data.active={}
	var valid: Array=[]
	for job in data.jobs:
		if job is Dictionary and str(job.get("action","")) in ["gather","move","plant","water","fertilize","harvest","feed","drink","collect","clean","pet","herd","orchard","open","chop","refill"]:
			valid.append(job)
		if valid.size()>=64: break
	data.jobs=valid
	if int(data.get("version",0))<2:
		for zone in data.zones:
			if zone is Dictionary and point(zone.get("position",[]))==Vector2(250,1430) and str(zone.get("name",""))=="Zona Sapi": zone.position=[520,1980]
	# Remove only the two generated starter paddocks; keep custom zones and progress.
	if int(data.get("version",0))<3:
		var retained: Array=[]
		for zone in data.zones:
			var at=point(zone.get("position",[]))
			var starter=(str(zone.get("name",""))=="Zona Ayam" and at==Vector2(1510,150)) or (str(zone.get("name",""))=="Zona Sapi" and at==Vector2(520,1980))
			if not starter: retained.append(zone)
		data.zones=retained
		for animal in data.animals:
			if str(animal.get("id","")) in ["ayam_1","sapi_1"]:
				animal.legacy_pen=true
				animal.zone=-1
	if int(data.get("version",0))<4:
		var kept: Array=[]
		for area in data.zones:
			var starter=(str(area.get("name",""))=="Zona Babi" and point(area.get("position",[]))==Vector2(1750,1630)) or (str(area.get("name",""))=="Zona Kambing" and point(area.get("position",[]))==Vector2(2290,1100))
			var occupied_by_other=false
			for animal in data.animals:
				if int(animal.get("zone",-1))==int(area.id) and str(animal.species) not in ["ayam","sapi","babi","kambing"]: occupied_by_other=true
			if not starter or occupied_by_other: kept.append(area)
		data.zones=kept
		for animal in data.animals:
			if str(animal.species) in ["ayam","sapi","babi","kambing"]:
				animal.legacy_pen=true
				animal.zone=-1
	data.version=VERSION
	data.water=clampi(int(data.water),0,100)
	data.fertilizer=maxi(0,int(data.fertilizer))
	return data
static func zone_rect(zone: Dictionary) -> Rect2:
	return Rect2(point(zone.get("position",[])),point(zone.get("size",[]),Vector2(400,300)))
static func needs_tick(animal: Dictionary, delta: float) -> void:
	animal.hunger=clampf(float(animal.get("hunger",85))-delta*0.022,0,100)
	animal.thirst=clampf(float(animal.get("thirst",85))-delta*0.032,0,100)
	animal.cleanliness=clampf(float(animal.get("cleanliness",85))-delta*0.014,0,100)
	animal.energy=clampf(float(animal.get("energy",85))+delta*(0.25 if animal.get("state","")=="sleep" else -0.015),0,100)
static func settle_offline(data: Dictionary, timestamp: int) -> void:
	var elapsed=clampi(timestamp-int(data.get("saved_at",timestamp)),0,21600)
	for animal in data.animals:
		if animal is Dictionary:
			needs_tick(animal,float(elapsed))
			animal.state="idle"
	data.saved_at=timestamp

static func zone_contains(zone: Dictionary,at: Vector2,margin:=0.0) -> bool:
	var rect:=zone_rect(zone)
	var half:=rect.size*0.5-Vector2.ONE*margin
	if half.x<=0 or half.y<=0: return false
	var delta: Vector2=(at-rect.get_center()).abs()
	return delta.x/half.x+delta.y/half.y<=1.0
static func zone_polygon(zone: Dictionary) -> PackedVector2Array:
	var rect:=zone_rect(zone)
	var center:=rect.get_center()
	var half:=rect.size*0.5
	return PackedVector2Array([center-Vector2(0,half.y),center+Vector2(half.x,0),center+Vector2(0,half.y),center-Vector2(half.x,0)])