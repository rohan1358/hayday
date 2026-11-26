extends RefCounted
# A seasonal package is one complete, pre-dressed figure with two views.
const VERSION=1
const NAMES=["Paket Musim Semi","Paket Musim Panas","Paket Musim Gugur","Paket Musim Dingin"]
const PRICE=115
static var textures: Dictionary={}
static func valid(season: int) -> bool: return season>=0 and season<4
static func key(gender: String,season: int) -> String: return "seasonal_figure_"+gender+"_"+str(season)
static func equipped(data: Dictionary,gender: String="") -> int:
	if gender.is_empty(): gender=str(data.get("gender","male"))
	var season=int(data.get("seasonal_pack_gender",{}).get(gender,-1))
	return season if valid(season) and key(gender,season) in data.get("owned",[]) else -1
static func texture(gender: String,season: int,back: bool) -> Texture2D:
	if gender not in ["male","female"] or not valid(season): return null
	var path="res://assets/wardrobe/seasonal_figures/%s_%d_%s.png"%[gender,season,"back" if back else "front"]
	if not textures.has(path): textures[path]=load(path) as Texture2D
	return textures[path]
static func directional_texture(gender: String,season: int,sector: int) -> Texture2D:
	if gender not in ["male","female"]: return null
	if not valid(season): return null
	var path="res://assets/wardrobe/%s_five_views/%d_%d.png"%[gender,season,clampi(sector,0,4)]
	if not textures.has(path): textures[path]=load(path) as Texture2D
	return textures[path]
static func prepare(game) -> bool:
	var data: Dictionary=game.seasonal
	var changed=int(data.get("seasonal_pack_version",0))<VERSION
	if not data.get("owned",[]) is Array: data.owned=[]
	if not data.has("owned"): data.owned=[]
	if str(data.get("gender","male")) not in ["male","female"]: data.gender="male"
	if not data.has("gender"): data.gender="male"
	if changed:
		var kept: Array=[]
		var seen: Dictionary={}
		var refund=0
		for value in data.owned:
			var text=str(value)
			var old=false
			for prefix in ["wardrobe_v4_","wardrobe_v5_","wardrobe_v6_","wardrobe_v7_"]:
				if not text.begins_with(prefix): continue
				old=true
				var suffix=text.trim_prefix(prefix)
				if suffix.is_valid_int() and int(suffix)>=0 and int(suffix)<24 and int(int(suffix)%12/3)>0 and not seen.has(text):
					refund+=[45,30,40][int(suffix)%3]
					seen[text]=true
			if text.begins_with("accessory") or text.begins_with("wardrobe_acc_"): old=true
			if not old: kept.append(value)
		game.coins+=refund
		data.accessory_reset_refund=refund
		data.owned=kept
		data.wardrobe_slots={}
		data.wardrobe_gender_slots={}
		data.accessory=-1
		data.accessory_catalog_version=7
		data.seasonal_pack_gender={"female":0,"male":0}
		for gender in ["female","male"]:
			if key(gender,0) not in data.owned: data.owned.append(key(gender,0))
		data.seasonal_pack_version=VERSION
	if not data.get("seasonal_pack_gender",{}) is Dictionary: data.seasonal_pack_gender={}
	if not data.has("seasonal_pack_gender"): data.seasonal_pack_gender={}
	for gender in ["female","male"]: data.seasonal_pack_gender[gender]=equipped(data,gender)
	return changed
static func buy_and_equip(game,season: int) -> bool:
	if not valid(season): return false
	var data: Dictionary=game.seasonal
	var gender=str(data.get("gender","male"))
	var id=key(gender,season)
	if id not in data.owned:
		if game.coins<PRICE: return false
		game.coins-=PRICE
		data.owned.append(id)
	data.seasonal_pack_gender[gender]=season
	return true
