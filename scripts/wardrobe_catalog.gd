extends RefCounted
const VERSION=6
const SLOTS=["head","neck","bag"]
const SLOT_NAMES=["Kepala","Leher","Pinggang"]
const SEASONS=["Semi","Panas","Gugur","Dingin"]
const NAMES=["Topi Jerami Daisy","Bandana Krim","Sabuk Tas Tunas Hijau","Topi Jerami Pita Teal","Bandana Lemon","Sabuk Tas Tunas Pasir","Kupluk Rajut Jingga","Syal Krim","Sabuk Tas Cokelat","Kupluk Rajut Krim","Syal Pink","Sabuk Tas Tunas Madu","Topi Jerami Cokelat","Bandana Hijau","Sabuk Tas Kulit Cokelat","Topi Jerami Anyam","Bandana Biru Langit","Sabuk Tas Kulit Madu","Topi Pet Tweed","Syal Mustard","Sabuk Tas Kulit Panen","Kupluk Rajut Teal","Syal Krim Hangat","Sabuk Tas Kulit Musim Dingin"]
const BELT_COLORS=["58bea7","27a6bb","9c4b97","ec7788","367cdb","3569c9","338f96","365c92"]
static func gender_of(index: int) -> String: return "female" if index<12 else "male"
static func slot_of(index: int) -> String: return SLOTS[posmod(index,3)]
static func season_of(index: int) -> int: return int(posmod(index,12)/3)
static func valid(index: int) -> bool: return index>=0 and index<24
static func key(index: int) -> String: return "wardrobe_v6_"+str(index)
static func price(index: int) -> int: return [45,30,40][posmod(index,3)]
static func items(gender: String,season: int) -> Array:
	var start=(0 if gender=="female" else 12)+clampi(season,0,3)*3
	return [start,start+1,start+2]
static func defaults(gender: String) -> Dictionary:
	var ids=items(gender,0)
	return {"head":ids[0],"neck":ids[1],"bag":ids[2]}
static func slots_for(data: Dictionary,gender: String) -> Dictionary:
	var saved=data.get("wardrobe_slots",{}) if str(data.get("gender","male"))==gender else data.get("wardrobe_gender_slots",{}).get(gender,{})
	return saved if saved is Dictionary else {}
static func remember(data: Dictionary) -> void:
	if not data.has("wardrobe_gender_slots"): data.wardrobe_gender_slots={}
	data.wardrobe_gender_slots[str(data.get("gender","male"))]=data.get("wardrobe_slots",{}).duplicate(true)
static func select_gender(data: Dictionary,gender: String) -> void:
	if gender not in ["male","female"]: return
	remember(data)
	data.gender=gender
	data.wardrobe_slots=data.wardrobe_gender_slots.get(gender,{}).duplicate(true)
static func prepare(game) -> bool:
	return preload("res://scripts/seasonal_character_packs.gd").prepare(game)
