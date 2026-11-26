extends RefCounted

# New districts extend the existing save. The first six entries describe the
# working farm; only entries with a cost create an additional owned building.
const ORDER := ["desa", "ladang", "hutan", "peternakan", "produksi", "logistik", "kebun_buah", "penggilingan", "rumah_kaca", "taman_bermain", "pasar_desa", "pemancingan", "tambang", "festival", "camping", "permukiman", "kafe", "berkuda", "stasiun", "sekolah", "botani", "resor_danau", "kota_wisata", "arena", "pelabuhan"]
const DATA := {
	"desa": {"name":"Desa Utama", "level":1, "position":Vector2(560, 560), "description":"Rumah, tetangga, dan papan pesanan."},
	"ladang": {"name":"Pertanian", "level":1, "position":Vector2(1120, 900), "description":"Tanam, rawat, dan panen tanaman."},
	"hutan": {"name":"Hutan", "level":1, "position":Vector2(480, 2640), "description":"Tebang pohon liar untuk memperoleh kayu."},
	"peternakan": {"name":"Peternakan", "level":3, "position":Vector2(1680, 1560), "description":"Beli kandang, rawat hewan, dan kumpulkan hasil."},
	"produksi": {"name":"Produksi", "level":5, "position":Vector2(2800, 1120), "description":"Olah panen di dapur dan pabrik pakan."},
	"logistik": {"name":"Gudang & Logistik", "level":5, "position":Vector2(1840, 1200), "description":"Simpan barang dan kirim pesanan truk."},
	"kebun_buah": {"name":"Kebun Buah", "level":1, "position":Vector2(1120, 1520), "description":"Rawat dan panen pohon buah yang sudah ada."},
	"penggilingan": {"name":"Penggilingan", "level":2, "cost":650, "position":Vector2(650, 2450), "half":Vector2(167, 83), "art":"region_mill", "width":440.0, "description":"Giling 2 gandum menjadi tepung untuk dapur."},
	"rumah_kaca": {"name":"Rumah Kaca", "level":9, "cost":720, "position":Vector2(1600, 2500), "half":Vector2(174, 87), "art":"lg_greenhouse", "width":460.0, "description":"Budidayakan bibit stroberi setiap musim."},
	"taman_bermain": {"name":"Taman Bermain", "level":5, "cost":680, "position":Vector2(1650, 3170), "half":Vector2(201, 100), "art":"region_playground", "width":530.0, "description":"Sambut pengunjung dan kumpulkan kebahagiaan."},
	"pasar_desa": {"name":"Pasar Desa", "level":1, "position":Vector2(1440, 800), "description":"Jual hasil kebun dan olahan melalui pasar yang sudah ada."},
	"pemancingan": {"name":"Pemancingan", "level":11, "cost":900, "position":Vector2(3500, 2800), "half":Vector2(190, 95), "art":"region_fishing", "width":800.0, "description":"Tangkap ikan untuk dimasak dan dikirim."},
	"tambang": {"name":"Tambang", "level":2, "cost":150, "position":Vector2(1750, 2850), "half":Vector2(167, 83), "art":"region_mine", "width":440.0, "description":"Tambang untuk memperoleh palu dan batu bagi upgrade bangunan."},
	"festival": {"name":"Pusat Festival", "level":15, "cost":1300, "position":Vector2(1400, 6400), "half":Vector2(235, 117), "art":"region_festival", "width":620.0, "description":"Tukar kebahagiaan dan panen untuk hadiah."},
	"camping": {"name":"Area Camping", "level":18, "cost":850, "position":Vector2(650, 6050), "half":Vector2(205, 102), "art":"region_camp", "width":540.0, "description":"Ajak pengunjung berkemah di alam."},
	"permukiman": {"name":"Permukiman NPC", "level":20, "cost":1800, "position":Vector2(1820, 3950), "half":Vector2(247, 123), "art":"region_village", "width":950.0, "description":"Penuhi kebutuhan tetangga dan bangun komunitas."},
	"kafe": {"name":"Kafe & Restoran", "level":22, "cost":2100, "position":Vector2(2500, 3950), "half":Vector2(212, 106), "art":"region_cafe", "width":560.0, "description":"Olah tepung dan susu menjadi hidangan desa."},
	"berkuda": {"name":"Pusat Berkuda", "level":24, "cost":2300, "position":Vector2(3600, 1900), "half":Vector2(440, 220), "art":"region_stable", "width":1050.0, "description":"Rawat kuda dan ajak wisatawan berkuda."},
	"stasiun": {"name":"Stasiun Kereta", "level":26, "cost":2600, "position":Vector2(2450, 3500), "half":Vector2(273, 136), "art":"region_station", "width":1100.0, "description":"Kirim ikan dan makanan ke desa lain."},
	"sekolah": {"name":"Sekolah Desa", "level":28, "cost":2900, "position":Vector2(1770, 3500), "half":Vector2(228, 114), "art":"region_school", "width":600.0, "description":"Bantu kegiatan belajar dan raih wawasan."},
	"botani": {"name":"Taman Botani", "level":30, "cost":3200, "position":Vector2(3600, 5400), "half":Vector2(228, 114), "art":"region_botanical", "width":800.0, "description":"Teliti tanaman untuk bunga langka."},
	"resor_danau": {"name":"Resor Danau", "level":35, "cost":3900, "position":Vector2(3100, 6300), "half":Vector2(228, 114), "art":"region_resort", "width":700.0, "description":"Siapkan paket wisata danau untuk tamu."},
	"kota_wisata": {"name":"Kota Wisata", "level":40, "cost":4700, "position":Vector2(3700, 6800), "half":Vector2(258, 129), "art":"region_tourism", "width":950.0, "description":"Layani wisatawan dengan makanan dan paket wisata."},
	"arena": {"name":"Arena Kompetisi", "level":45, "cost":5300, "position":Vector2(650, 6900), "half":Vector2(239, 119), "art":"region_arena", "width":630.0, "description":"Ikuti lomba panen untuk mendapatkan piala."},
	"pelabuhan": {"name":"Pelabuhan Dagang", "level":50, "cost":6200, "position":Vector2(2700, 7130), "half":Vector2(258, 129), "art":"region_harbor", "width":1100.0, "description":"Kirim barang langka untuk kontrak besar."},
}

const LATE_ACTIVITIES := {
	"permukiman": {"inputs":{"gandum":3}, "outputs":{"surat_tetangga":1}, "coins":80, "xp":20, "seconds":75, "message":"Tetangga menerima gandum dan mengirim surat persahabatan."},
	"kafe": {"inputs":{"tepung":1,"susu":1}, "outputs":{"hidangan_desa":1}, "xp":25, "seconds":90, "message":"Kafe menyajikan hidangan desa."},
	"berkuda": {"inputs":{"gandum":2}, "happiness":12, "coins":55, "xp":25, "seconds":100, "message":"Wisata berkuda menambah kebahagiaan pengunjung."},
	"stasiun": {"inputs":{"ikan":1,"hidangan_desa":1}, "coins":240, "xp":34, "seconds":130, "message":"Kereta mengirim ikan dan hidangan ke desa tetangga."},
	"sekolah": {"inputs":{"roti":1}, "outputs":{"wawasan":1}, "happiness":6, "xp":30, "seconds":120, "message":"Kegiatan sekolah menghasilkan wawasan."},
	"botani": {"inputs":{"stroberi":1,"wawasan":1}, "outputs":{"bunga_langka":1}, "xp":36, "seconds":150, "message":"Penelitian botani menghasilkan bunga langka."},
	"resor_danau": {"inputs":{"ikan":1,"bunga_langka":1}, "outputs":{"paket_wisata":1}, "happiness":10, "xp":40, "seconds":170, "message":"Resor menyiapkan paket wisata danau."},
	"kota_wisata": {"inputs":{"hidangan_desa":1,"paket_wisata":1}, "coins":460, "happiness":14, "xp":45, "seconds":180, "message":"Kota wisata ramai oleh tamu desa."},
	"arena": {"inputs":{"gandum":5}, "outputs":{"piala_panen":1}, "coins":180, "xp":50, "seconds":200, "message":"Kompetisi panen menghasilkan piala."},
	"pelabuhan": {"inputs":{"piala_panen":1,"bunga_langka":1}, "coins":900, "gems":1, "xp":65, "seconds":240, "message":"Kontrak pelabuhan selesai: koin dan permata diterima."},
}

static func prepare(game) -> Dictionary:
	if not game.world_regions is Dictionary:
		game.world_regions = {}
	for key in ["owned", "ready_at", "tier"]:
		if not game.world_regions.get(key, {}) is Dictionary:
			game.world_regions[key] = {}
	if not game.world_regions.has("owned"):
		game.world_regions.owned = {}
	if not game.world_regions.has("ready_at"):
		game.world_regions.ready_at = {}
	if not game.world_regions.has("tier"):
		game.world_regions.tier = {}
	game.world_regions["happiness"] = clampi(int(game.world_regions.get("happiness", 0)), 0, 100)
	return game.world_regions

static func purchased(game, id: String) -> bool:
	return bool(prepare(game).owned.get(id, false))

static func can_buy(game, id: String) -> bool:
	if not DATA.has(id) or not DATA[id].has("cost"):
		return false
	return preload("res://scripts/four_seasons.gd").unlocked(game,DATA[id].position) and preload("res://scripts/island_journey.gd").city_level(game) >= int(DATA[id].level) and game.coins >= int(DATA[id].cost) and not purchased(game, id) and not preload("res://scripts/first_farm.gd").active(game)

static func buy(game, id: String, at: Vector2) -> bool:
	if not can_buy(game, id):
		return false
	game.coins -= int(DATA[id].cost)
	prepare(game).owned[id] = true
	prepare(game).tier[id] = 1
	game.layout_positions["region_" + id] = [at.x, at.y]
	game.award_xp(25)
	game.save_game()
	return true

static func wait_seconds(game, id: String) -> int:
	if id=="taman_bermain":return 0
	if id in ["penggilingan","tambang"]:return load("res://scripts/industry_jobs.gd").remaining(game,id)
	return maxi(0, int(prepare(game).ready_at.get(id, 0)) - game.now())

static func tier(game, id: String) -> int:
	return clampi(int(prepare(game).tier.get(id, 1)), 1, 5)

static func upgrade_cost(game, id: String) -> Dictionary:
	if not DATA.has(id) or not DATA[id].has("cost") or not purchased(game, id) or tier(game,id)>=5:
		return {}
	var current := tier(game,id)
	return {"coins":int(DATA[id].cost) * current, "kayu":current * 2, "batu":current}

static func can_upgrade(game, id: String) -> bool:
	var cost := upgrade_cost(game,id)
	if cost.is_empty() or game.coins < int(cost.coins): return false
	var materials: Dictionary = preload("res://scripts/building_upgrades.gd").prepare(game).materials
	return int(materials.get("kayu",0)) >= int(cost.kayu) and int(materials.get("batu",0)) >= int(cost.batu)

static func upgrade(game, id: String) -> bool:
	if not can_upgrade(game,id): return false
	var cost := upgrade_cost(game,id)
	var materials: Dictionary = preload("res://scripts/building_upgrades.gd").prepare(game).materials
	game.coins -= int(cost.coins)
	materials.kayu = int(materials.kayu) - int(cost.kayu)
	materials.batu = int(materials.batu) - int(cost.batu)
	prepare(game).tier[id] = tier(game,id) + 1
	game.award_xp(15 * tier(game,id))
	game.save_game()
	return true

static func late_action(game, id: String) -> String:
	var recipe: Dictionary = LATE_ACTIVITIES[id]
	var level_bonus := tier(game,id) - 1
	for item in recipe.inputs:
		if int(game.inventory.get(item,0)) < int(recipe.inputs[item]):
			return "Bahan kurang: %s ×%d." % [str(game.item_info(str(item)).get("name",item)), int(recipe.inputs[item])]
	var output_count := 0
	for item in recipe.get("outputs",{}): output_count += int(recipe.outputs[item]) + (1 if level_bonus>=2 else 0)
	var consumed := 0
	for item in recipe.inputs: consumed += int(recipe.inputs[item])
	if game.storage_used() - consumed + output_count > game.storage_capacity:
		return "Gudang penuh. Kosongkan ruang sebelum memulai."
	for item in recipe.inputs: game.inventory[item] = int(game.inventory[item]) - int(recipe.inputs[item])
	for item in recipe.get("outputs",{}): game.inventory[item] = int(game.inventory.get(item,0)) + int(recipe.outputs[item]) + (1 if level_bonus>=2 else 0)
	game.coins += int(recipe.get("coins",0)) * (100 + level_bonus * 15) / 100
	game.diamonds += int(recipe.get("gems",0))
	var state := prepare(game)
	state.happiness = mini(100,int(state.happiness)+int(recipe.get("happiness",0)))
	state.ready_at[id] = game.now() + maxi(20, int(recipe.seconds) * (100 - level_bonus * 10) / 100)
	game.award_xp(int(recipe.xp) + level_bonus * 5)
	game.save_game()
	return str(recipe.message)

static func action(game, id: String) -> String:
	if not purchased(game, id) or wait_seconds(game, id) > 0:
		return "Kawasan belum dibeli atau masih beristirahat."
	var state := prepare(game)
	if LATE_ACTIVITIES.has(id): return late_action(game,id)
	match id:
		"penggilingan":
			return load("res://scripts/industry_jobs.gd").start(game,id)
		"rumah_kaca":
			game.seeds.stroberi = int(game.seeds.get("stroberi", 0)) + 2
			state.ready_at[id] = game.now() + 120
			game.award_xp(6)
			game.save_game()
			return "Rumah kaca menghasilkan 2 bibit stroberi."
		"taman_bermain":
			return "Kunjungi Taman Bermain untuk memainkan empat wahana dan meraih hadiah harian."
		"pemancingan":
			if game.storage_used() >= game.storage_capacity:
				return "Gudang penuh. Jual barang sebelum memancing."
			game.inventory.ikan = int(game.inventory.get("ikan", 0)) + 1
			state.ready_at[id] = game.now() + 45
			game.award_xp(7)
			game.save_game()
			return "Dapat 1 ikan! Olah di dapur atau jual di gudang."
		"tambang":
			return load("res://scripts/industry_jobs.gd").start(game,id)
		"camping":
			state.happiness = mini(100, int(state.happiness) + 10)
			state.ready_at[id] = game.now() + 100
			game.award_xp(7)
			game.save_game()
			return "Wisata camping selesai. Kebahagiaan +10."
		"festival":
			if int(state.happiness) < 20 or int(game.inventory.get("gandum", 0)) < 3:
				return "Festival perlu 20 kebahagiaan dan 3 gandum."
			state.happiness = int(state.happiness) - 20
			game.inventory.gandum = int(game.inventory.gandum) - 3
			game.coins += 140
			state.ready_at[id] = game.now() + 180
			game.award_xp(30)
			game.save_game()
			return "Festival ramai! +140 koin dan +30 XP."
	return "Buka fasilitas pada menu kawasan ini."
