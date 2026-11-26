extends RefCounted
const SPECIES=["ayam","sapi","babi","kambing"]
const INFO={"ayam":{"name":"Ayam","level":1,"price":35,"baseline":1,"asset":"chicken_coop","width":300.0,"offset":Vector2(0,90)},"sapi":{"name":"Sapi","level":1,"price":120,"baseline":2,"asset":"cow_pen","width":315.0,"offset":Vector2(5,25)},"babi":{"name":"Babi","level":2,"price":140,"baseline":1,"asset":"pig_pen","width":290.0,"offset":Vector2(0,30)},"kambing":{"name":"Kambing","level":3,"price":180,"baseline":1,"asset":"goat_pen","width":290.0,"offset":Vector2(0,30)}}
# World-space proportions, shared by drawing, animation, picking and collision.
# A dressed farmer is about 120 units tall; the cottage is 300 units wide.
const PEN_WIDTHS={"ayam":480.0,"sapi":550.0,"babi":480.0,"kambing":480.0}
const ANIMAL_WIDTHS={"ayam":32.0,"sapi":128.0,"babi":90.0,"kambing":84.0}
const OLD_PEN_WIDTHS={"ayam":300.0,"sapi":315.0,"babi":290.0,"kambing":290.0}
static func pen_width(game,species: String) -> float:
	return float(PEN_WIDTHS.get(species,300.0))*scale(game,species)
static func animal_width(species: String) -> float: return float(ANIMAL_WIDTHS.get(species,60.0))
const CAPACITY=[3,6,9]
const SCALE=[1.0,1.25,1.50]
static func available(game,species: String) -> bool:
	if not game.ftue.is_empty():
		if species=="sapi": return game.level>=3 and bool(game.ftue.get("cow_built",false))
		if species=="ayam": return preload("res://scripts/first_coop.gd").built(game)
		if not game.feature_unlocked("ranch") or game.level<3: return false
	return species in ["ayam","sapi"] or INFO.has(species) and game.has_construction("kandang_"+species)
static func prepare(game) -> void:
	if not game.ranch is Dictionary: game.ranch={}
	if not game.ranch.get("pens",{}) is Dictionary: game.ranch.pens={}
	if not game.ranch.has("pens"): game.ranch.pens={}
	for species in SPECIES:
		if not game.ranch.pens.has(species) or not game.ranch.pens[species] is Dictionary: game.ranch.pens[species]={"tier":1,"count":int(INFO[species].baseline) if available(game,species) else 0}
		var pen: Dictionary=game.ranch.pens[species]
		pen.tier=clampi(int(pen.get("tier",1)),1,3)
		pen.count=clampi(int(pen.get("count",0)),0,CAPACITY[int(pen.tier)-1])
		# Existing barns keep their starter herd when migrating older saves.
		if game.ftue.is_empty() and available(game,species) and pen.count==0: pen.count=int(INFO[species].baseline)
	if not game.ranch.get("production_counts",{}) is Dictionary: game.ranch.production_counts={}
	if not game.ranch.has("production_counts"): game.ranch.production_counts={}
	for species in SPECIES:
		if not game.ranch.production_counts.has(species): game.ranch.production_counts[species]=int(game.ranch.pens[species].count)
		game.ranch.production_counts[species]=clampi(int(game.ranch.production_counts[species]),0,9)
	game.ranch.chicken_feed_cycle=maxi(0,int(game.ranch.get("chicken_feed_cycle",0)))
	game.ranch.version=1
static func count(game,species: String) -> int:
	prepare(game)
	return int(game.ranch.pens[species].count) if available(game,species) else 0
static func capacity(game,species: String) -> int:
	prepare(game)
	return CAPACITY[int(game.ranch.pens[species].tier)-1]
static func scale(game,species: String) -> float:
	prepare(game)
	return SCALE[int(game.ranch.pens[species].tier)-1]
static func buy_reason(game,species: String) -> String:
	if not INFO.has(species): return "Jenis hewan tidak dikenal."
	if not game.ftue.is_empty() and game.level<3: return "Terbuka pada Level 3."
	if not available(game,species): return "Bangun kandangnya dahulu."
	if game.level<int(INFO[species].level): return "Level belum cukup."
	if count(game,species)>=capacity(game,species): return "Kandang penuh. Perluas lahan kandang dahulu."
	if game.coins<int(INFO[species].price): return "Koin belum cukup."
	return ""
static func buy(game,species: String) -> bool:
	if not buy_reason(game,species).is_empty(): return false
	game.coins-=int(INFO[species].price)
	game.ranch.pens[species].count=int(game.ranch.pens[species].count)+1
	game.save_game()
	return true
static func upgrade_cost(game,species: String) -> int:
	prepare(game)
	return (120 if species=="ayam" else 220)*int(game.ranch.pens[species].tier)
static func upgrade_level(game,species: String) -> int:
	prepare(game)
	return 5 if int(game.ranch.pens[species].tier)==1 else 10
static func upgrade_reason(game,species: String) -> String:
	if not INFO.has(species) or not available(game,species): return "Bangun kandangnya dahulu."
	prepare(game)
	if int(game.ranch.pens[species].tier)>=3: return "Luas kandang sudah maksimal."
	if game.level<upgrade_level(game,species): return "Perlu level "+str(upgrade_level(game,species))+"."
	if game.coins<upgrade_cost(game,species): return "Koin belum cukup."
	return ""
static func upgrade(game,species: String) -> bool:
	if not upgrade_reason(game,species).is_empty(): return false
	game.coins-=upgrade_cost(game,species)
	game.ranch.pens[species].tier=int(game.ranch.pens[species].tier)+1
	game.save_game()
	return true
static func units(game,species: String,base: int) -> int:
	var current=count(game,species)
	var active=species=="ayam" or (species=="sapi" and game.cow_ready_at>0) or (species in ["babi","kambing"] and int(game.livestock.get(species,0))>0)
	var productive=int(game.ranch.production_counts.get(species,current)) if active else current
	return maxi(1,ceili(float(base)*maxi(1,productive)/float(INFO[species].baseline)))
static func feed_multiplier(game,species: String) -> int:
	return maxi(1,ceili(float(count(game,species))/float(INFO[species].baseline)))

static func start_cycle(game,species: String) -> void:
	prepare(game)
	game.ranch.production_counts[species]=count(game,species)
