class_name FarmGameState
extends RefCounted

const SAVE_PATH := "user://kebun_ceria_v1.json"
const BACKUP_PATH := "user://kebun_ceria_backup.json"
const DECORATION_ORDER := [
	"flower_patch", "flowering_bushes", "flower_garden", "flowering_hedge",
	"fence_straight", "arched_fence", "rustic_lamp", "harvest_baskets",
	"wooden_signpost", "wishing_well", "water_tower", "pollinator_house",
	"herb_drying_rack", "rainwater_collector", "wildflower_crescent",
	"decorative_pond"
]
const DECORATIONS := {
	"flower_patch": {"name": "Hamparan Bunga", "cost": 35, "width": 160.0, "half": Vector2(72, 30)},
	"flowering_bushes": {"name": "Semak Berbunga", "cost": 45, "width": 145.0, "half": Vector2(65, 32)},
	"flower_garden": {"name": "Taman Bunga", "cost": 55, "width": 145.0, "half": Vector2(67, 35)},
	"flowering_hedge": {"name": "Pagar Tanaman", "cost": 40, "width": 125.0, "half": Vector2(57, 29)},
	"fence_straight": {"name": "Pagar Kayu", "cost": 40, "width": 125.0, "half": Vector2(58, 28)},
	"arched_fence": {"name": "Gerbang Bunga", "cost": 90, "width": 160.0, "half": Vector2(70, 35)},
	"rustic_lamp": {"name": "Lampu Kebun", "cost": 65, "width": 85.0, "half": Vector2(31, 29)},
	"harvest_baskets": {"name": "Keranjang Panen", "cost": 60, "width": 135.0, "half": Vector2(55, 35)},
	"wooden_signpost": {"name": "Papan Petunjuk", "cost": 45, "width": 95.0, "half": Vector2(34, 31)},
	"wishing_well": {"name": "Sumur Harapan", "cost": 140, "width": 165.0, "half": Vector2(63, 52)},
	"water_tower": {"name": "Menara Air", "cost": 160, "width": 130.0, "half": Vector2(50, 43)},
	"pollinator_house": {"name": "Rumah Lebah", "cost": 95, "width": 145.0, "half": Vector2(56, 43)},
	"herb_drying_rack": {"name": "Rak Herbal", "cost": 90, "width": 150.0, "half": Vector2(60, 40)},
	"rainwater_collector": {"name": "Penampung Hujan", "cost": 110, "width": 130.0, "half": Vector2(48, 40)},
	"wildflower_crescent": {"name": "Bulan Sabit Bunga", "cost": 75, "width": 175.0, "half": Vector2(73, 34)},
	"decorative_pond": {"name": "Kolam Hias", "cost": 190, "width": 235.0, "half": Vector2(103, 65)}
}
const VISITOR_ACCEPT_COOLDOWN := 150
const VISITOR_DECLINE_COOLDOWN := 90
const VISITOR_NAMES := ["Bu Sari", "Pak Budi", "Kak Rina", "Pak Tono"]
const CROP_ORDER := [
	"gandum", "jagung", "wortel", "tebu", "stroberi", "kedelai", "kentang", "labu", "padi",
	"tomat", "cabai", "kopi", "nanas"
]
const CROPS := {
	"gandum":
	{
		"name": "Gandum",
		"grow": 12,
		"seed_cost": 3,
		"sell": 5,
		"xp": 5,
		"level": 1,
		"yield": 2,
		"color": "#efbf4f"
	},
	"jagung":
	{
		"name": "Jagung",
		"grow": 26,
		"seed_cost": 8,
		"sell": 13,
		"xp": 9,
		"level": 1,
		"yield": 2,
		"color": "#ffcf44"
	},
	"wortel":
	{
		"name": "Wortel",
		"grow": 42,
		"seed_cost": 12,
		"sell": 19,
		"xp": 13,
		"level": 2,
		"yield": 3,
		"color": "#f08f3d"
	},
	"tebu":
	{
		"name": "Tebu",
		"grow": 65,
		"seed_cost": 22,
		"sell": 30,
		"xp": 19,
		"level": 3,
		"yield": 3,
		"color": "#7cc96a"
	},
	"stroberi":
	{
		"name": "Stroberi",
		"grow": 90,
		"seed_cost": 34,
		"sell": 47,
		"xp": 26,
		"level": 4,
		"yield": 3,
		"color": "#e45b66"
	},
	"kedelai":
	{
		"name": "Kedelai",
		"grow": 52,
		"seed_cost": 15,
		"sell": 23,
		"xp": 15,
		"level": 2,
		"yield": 3,
		"color": "#9bbd58"
	},
	"kentang":
	{
		"name": "Kentang",
		"grow": 70,
		"seed_cost": 24,
		"sell": 36,
		"xp": 20,
		"level": 3,
		"yield": 3,
		"color": "#b78d5a"
	},
	"labu":
	{
		"name": "Labu",
		"grow": 105,
		"seed_cost": 38,
		"sell": 58,
		"xp": 29,
		"level": 4,
		"yield": 3,
		"color": "#e89a44"
	},
	"padi":
	{
		"name": "Padi",
		"grow": 135,
		"seed_cost": 46,
		"sell": 69,
		"xp": 34,
		"level": 5,
		"yield": 3,
		"color": "#d5be60"
	},
	"tomat": {"name": "Tomat", "grow": 150, "seed_cost": 60, "sell": 85, "xp": 37, "level": 6, "yield": 3, "color": "#e45d54"},
	"cabai": {"name": "Cabai Merah", "grow": 190, "seed_cost": 78, "sell": 108, "xp": 43, "level": 9, "yield": 3, "color": "#d8474e"},
	"kopi": {"name": "Biji Kopi", "grow": 240, "seed_cost": 95, "sell": 132, "xp": 50, "level": 13, "yield": 3, "color": "#a77550"},
	"nanas": {"name": "Nanas", "grow": 300, "seed_cost": 115, "sell": 162, "xp": 58, "level": 17, "yield": 3, "color": "#f1cb62"},
}
const PRODUCT_ORDER := [
	"roti",
	"popcorn",
	"jus_wortel",
	"keju",
	"mentega",
	"roti_manis",
	"keripik_kentang",
	"kue",
	"bacon",
	"yogurt_kambing",
	"saus_tomat", "sambal", "selai_nanas"
]
const COW_FEED := {"gandum": 2, "jagung": 1}
const FEED_ORDER := ["pakan_sapi", "pakan_babi", "pakan_kambing"]
const FEED_RECIPES := {
	"pakan_sapi": {"name": "Pakan Sapi", "ingredients": {"gandum": 3, "jagung": 2}, "seconds": 25, "yield": 2, "xp": 8, "sell": 13, "level": 2, "color": "#dec17a"},
	"pakan_babi": {"name": "Pakan Babi", "ingredients": {"jagung": 3, "kedelai": 2}, "seconds": 35, "yield": 2, "xp": 10, "sell": 21, "level": 2, "color": "#ddac91"},
	"pakan_kambing": {"name": "Pakan Kambing", "ingredients": {"wortel": 3, "gandum": 2}, "seconds": 40, "yield": 2, "xp": 12, "sell": 25, "level": 3, "color": "#b5d08e"}
}
const COW_PRODUCTION_SECONDS := 75
const COW_MILK_YIELD := 2
const ANIMAL_ORDER := ["babi", "kambing"]
const ANIMALS := {
	"babi":
	{
		"name": "Babi",
		"building": "kandang_babi",
		"feed": {"jagung": 2, "kedelai": 1},
		"seconds": 95,
		"item": "daging_babi",
		"yield": 2,
		"xp": 14,
		"color": "#e9abb4"
	},
	"kambing":
	{
		"name": "Kambing",
		"building": "kandang_kambing",
		"feed": {"wortel": 2, "gandum": 1},
		"seconds": 110,
		"item": "susu_kambing",
		"yield": 2,
		"xp": 16,
		"color": "#f5e4c4"
	},
}
const LIVESTOCK_PRODUCTS := {
	"telur": {"name": "Telur Ayam", "sell": 18, "color": "#f1d890"},
	"susu": {"name": "Susu Segar", "sell": 28, "color": "#e7f0ee"},
	"daging_babi": {"name": "Daging Babi", "sell": 44, "color": "#e9abb4"},
	"susu_kambing": {"name": "Susu Kambing", "sell": 48, "color": "#f4e4ca"},
}
const BUILDING_ORDER := ["pabrik_pakan", "kandang_babi", "kandang_kambing", "toko_roti", "pabrik_susu"]
const DECOR_ORDER := ["petak_bunga", "gazebo", "kincir_angin", "kolam"]
const CONSTRUCTIONS := {
	"pabrik_pakan":
	{
		"name": "Pabrik Pakan",
		"cost": 190,
		"level": 2,
		"description": "Racik dua porsi pakan siap pakai per produksi.",
		"color": "#c9aa73"
	},
	"kandang_babi":
	{
		"name": "Kandang Babi",
		"cost": 220,
		"level": 2,
		"description": "Pelihara babi dan hasilkan daging.",
		"color": "#eab8b8"
	},
	"kandang_kambing":
	{
		"name": "Kandang Kambing",
		"cost": 320,
		"level": 3,
		"description": "Pelihara kambing penghasil susu.",
		"color": "#e8d8ac"
	},
	"toko_roti":
	{
		"name": "Rumah Roti",
		"cost": 185,
		"level": 2,
		"description": "Produksi roti dan kue 20% lebih cepat.",
		"color": "#e9b971"
	},
	"pabrik_susu":
	{
		"name": "Rumah Susu",
		"cost": 240,
		"level": 2,
		"description": "Produk susu 20% lebih cepat.",
		"color": "#a3dbe4"
	},
	"petak_bunga":
	{
		"name": "Taman Bunga",
		"cost": 55,
		"level": 1,
		"description": "Taman warna-warni, maksimal 3.",
		"color": "#ea85a7"
	},
	"gazebo":
	{
		"name": "Gazebo Kayu",
		"cost": 130,
		"level": 2,
		"description": "Tempat bersantai di tepi kebun.",
		"color": "#cb9458"
	},
	"kincir_angin":
	{
		"name": "Kincir Angin",
		"cost": 250,
		"level": 3,
		"description": "Kincir kecil yang mempercantik kebun.",
		"color": "#f3d58e"
	},
	"kolam":
	{
		"name": "Kolam Ikan",
		"cost": 290,
		"level": 4,
		"description": "Kolam biru untuk suasana asri.",
		"color": "#72c6de"
	},
}
const MARKET_MAX_SLOTS := 3
const MARKET_SALE_SECONDS := 75
const ORDER_REFRESH_COST := 15
const SEED_RECOVERY_COUNT := 3
const SEED_RECOVERY_COOLDOWN := 600
const ONBOARDING_COMPLETE := 3
const ORDER_REFRESH_SECONDS := 45
const ORCHARD_SIZE := 2
const FRUITS := {
	"jeruk":
	{
		"name": "Jeruk Manis",
		"grow": 95,
		"cost": 120,
		"sell": 27,
		"xp": 18,
		"level": 1,
		"yield": 3,
		"color": "#ffad3c"
	},
	"apel":
	{
		"name": "Apel Merah",
		"grow": 155,
		"cost": 220,
		"sell": 41,
		"xp": 28,
		"level": 2,
		"yield": 3,
		"color": "#ed655a"
	},
}
const DAILY_TASK_ORDER := ["panen", "pesanan", "produksi"]
const ACHIEVEMENT_ORDER := ["panen", "produksi", "pengiriman", "dagang"]
const ACHIEVEMENTS := {
	"panen": {
		"name": "Ahli Panen", "description": "Kumpulkan hasil kebun dan buah",
		"goals": [30, 150, 500], "coins": [100, 350, 1050],
		"xp": [25, 75, 180], "diamonds": [0, 1, 2]
	},
	"produksi": {
		"name": "Juru Masak", "description": "Kumpulkan olahan dapur dan pakan",
		"goals": [5, 25, 100], "coins": [130, 450, 1250],
		"xp": [30, 90, 200], "diamonds": [0, 1, 2]
	},
	"pengiriman": {
		"name": "Kurir Andalan", "description": "Selesaikan pesanan truk",
		"goals": [3, 15, 50], "coins": [160, 550, 1650],
		"xp": [35, 105, 230], "diamonds": [0, 1, 2]
	},
	"dagang": {
		"name": "Sahabat Desa", "description": "Jual barang ke pasar, gudang, atau tamu",
		"goals": [5, 25, 90], "coins": [120, 440, 1250],
		"xp": [30, 90, 190], "diamonds": [0, 1, 2]
	},
}
const DAILY_TASKS := {
	"panen":
	{
		"name": "Petani Rajin",
		"description": "Panen 6 hasil tanaman",
		"goal": 6,
		"coins": 65,
		"xp": 12,
		"diamonds": 0
	},
	"pesanan":
	{
		"name": "Kurir Desa",
		"description": "Kirim 2 pesanan truk",
		"goal": 2,
		"coins": 100,
		"xp": 18,
		"diamonds": 1
	},
	"produksi":
	{
		"name": "Koki Kebun",
		"description": "Ambil 2 hasil olahan dapur",
		"goal": 2,
		"coins": 85,
		"xp": 20,
		"diamonds": 1
	},
}
const PRODUCTS := {
	"roti":
	{
		"name": "Roti Hangat",
		"ingredients": {"gandum": 3},
		"seconds": 32,
		"yield": 1,
		"sell": 24,
		"xp": 12,
		"level": 1,
		"color": "#dfa15d"
	},
	"popcorn":
	{
		"name": "Popcorn",
		"ingredients": {"jagung": 3},
		"seconds": 45,
		"yield": 1,
		"sell": 48,
		"xp": 17,
		"level": 1,
		"color": "#f4d982"
	},
	"jus_wortel":
	{
		"name": "Jus Wortel",
		"ingredients": {"wortel": 2},
		"seconds": 60,
		"yield": 1,
		"sell": 53,
		"xp": 22,
		"level": 2,
		"color": "#ed9247"
	},
	"keju":
	{
		"name": "Keju Desa",
		"ingredients": {"susu": 2, "jagung": 1},
		"seconds": 75,
		"yield": 1,
		"sell": 85,
		"xp": 25,
		"level": 2,
		"color": "#f7d474"
	},
	"mentega":
	{
		"name": "Mentega",
		"ingredients": {"susu": 2},
		"seconds": 60,
		"yield": 1,
		"sell": 70,
		"xp": 24,
		"level": 2,
		"color": "#f6cf78"
	},
	"roti_manis":
	{
		"name": "Roti Manis",
		"ingredients": {"gandum": 2, "tebu": 1},
		"seconds": 75,
		"yield": 1,
		"sell": 88,
		"xp": 25,
		"level": 3,
		"color": "#d68c50"
	},
	"keripik_kentang":
	{
		"name": "Keripik Kentang",
		"ingredients": {"kentang": 3},
		"seconds": 80,
		"yield": 1,
		"sell": 120,
		"xp": 30,
		"level": 3,
		"color": "#edbe5e"
	},
	"kue":
	{
		"name": "Kue Stroberi",
		"ingredients": {"gandum": 2, "telur": 2, "susu": 1, "stroberi": 1},
		"seconds": 125,
		"yield": 1,
		"sell": 195,
		"xp": 46,
		"level": 4,
		"color": "#ee91a5"
	},
	"bacon":
	{
		"name": "Bacon Panggang",
		"ingredients": {"daging_babi": 2, "jagung": 1},
		"seconds": 95,
		"yield": 1,
		"sell": 122,
		"xp": 35,
		"level": 3,
		"color": "#da8075"
	},
	"yogurt_kambing":
	{
		"name": "Yogurt Kambing",
		"ingredients": {"susu_kambing": 2, "stroberi": 1},
		"seconds": 110,
		"yield": 1,
		"sell": 158,
		"xp": 41,
		"level": 4,
		"color": "#f2d6e1"
	},
	"saus_tomat": {"name": "Saus Tomat", "ingredients": {"tomat": 2, "tebu": 1}, "seconds": 130, "yield": 1, "sell": 230, "xp": 55, "level": 8, "color": "#d76250"},
	"sambal": {"name": "Sambal Desa", "ingredients": {"cabai": 2, "tomat": 1}, "seconds": 170, "yield": 1, "sell": 340, "xp": 66, "level": 12, "color": "#d63f48"},
	"selai_nanas": {"name": "Selai Nanas", "ingredients": {"nanas": 2, "tebu": 1}, "seconds": 210, "yield": 1, "sell": 390, "xp": 82, "level": 18, "color": "#edbf50"},
}

var coins := 400
var diamonds := 12
var level := 1
var xp := 0
var selected_crop := "gandum"
var plots: Array[Dictionary] = []
var layout_positions: Dictionary = {}
var decorations: Array[Dictionary] = []
var next_decoration_id := 1
var road_tiles: Dictionary = {}
var cleared_wild_trees: Array[int] = []
var seeds := {
	"gandum": 8,
	"jagung": 5,
	"wortel": 0,
	"tebu": 0,
	"stroberi": 0,
	"kedelai": 0,
	"kentang": 0,
	"labu": 0,
	"padi": 0,
	"tomat": 0, "cabai": 0, "kopi": 0, "nanas": 0
}
var inventory := {
	"gandum": 0,
	"jagung": 0,
	"wortel": 0,
	"tebu": 0,
	"stroberi": 0,
	"kedelai": 0,
	"kentang": 0,
	"labu": 0,
	"padi": 0,
	"tomat": 0, "cabai": 0, "kopi": 0, "nanas": 0,
	"telur": 0,
	"susu": 0,
	"daging_babi": 0,
	"susu_kambing": 0,
	"roti": 0,
	"popcorn": 0,
	"jus_wortel": 0,
	"keju": 0,
	"mentega": 0,
	"roti_manis": 0,
	"keripik_kentang": 0,
	"kue": 0,
	"bacon": 0,
	"yogurt_kambing": 0,
	"saus_tomat": 0, "sambal": 0, "selai_nanas": 0,
	"jeruk": 0,
	"apel": 0,
	"pakan_sapi": 0,
	"pakan_babi": 0,
	"pakan_kambing": 0
}
var orchard: Array[Dictionary] = []
var storage_capacity := 60
var production_queue: Array[Dictionary] = []
var feed_queue: Array[Dictionary] = []
var eggs_ready_at := 0
var seed_recovery_ready_at := 0
var cow_ready_at := 0
var livestock := {"babi": 0, "kambing": 0}
var constructions: Dictionary = {}
var deliveries := 0
var orders: Array[Dictionary] = []
var order_refresh_until: Array[int] = [0, 0, 0]
var order_revision := 0
var market_listings: Array[Dictionary] = []
var market_sales_count := 0
var visitor_request: Dictionary = {}
var visitor_counter := 0
var visitor_next_at := 0
var first_visit := true
var onboarding_step := 0
var onboarding_plot_index := -1
var onboarding_skipped := false
var last_saved := 0
var daily_date := ""
var daily_progress: Dictionary = {}
var daily_claimed: Dictionary = {}
var checkin_date := ""
var checkin_day := 0
var achievement_progress: Dictionary = {}
var achievement_claimed_tiers: Dictionary = {}
var save_path := SAVE_PATH
var backup_path := BACKUP_PATH


func _init() -> void:
	new_game()


func new_game() -> void:
	coins = 400
	diamonds = 12
	level = 1
	xp = 0
	selected_crop = "gandum"
	seeds = {
		"gandum": 8,
		"jagung": 5,
		"wortel": 0,
		"tebu": 0,
		"stroberi": 0,
		"kedelai": 0,
		"kentang": 0,
		"labu": 0,
		"padi": 0,
		"tomat": 0, "cabai": 0, "kopi": 0, "nanas": 0
	}
	inventory = {
		"gandum": 0,
		"jagung": 0,
		"wortel": 0,
		"tebu": 0,
		"stroberi": 0,
		"kedelai": 0,
		"kentang": 0,
		"labu": 0,
		"padi": 0,
		"tomat": 0, "cabai": 0, "kopi": 0, "nanas": 0,
		"telur": 0,
		"susu": 0,
		"daging_babi": 0,
		"susu_kambing": 0,
		"roti": 0,
		"popcorn": 0,
		"jus_wortel": 0,
		"keju": 0,
		"mentega": 0,
		"roti_manis": 0,
		"keripik_kentang": 0,
		"kue": 0,
		"bacon": 0,
		"yogurt_kambing": 0,
		"saus_tomat": 0, "sambal": 0, "selai_nanas": 0,
		"jeruk": 0,
		"apel": 0,
		"pakan_sapi": 0,
		"pakan_babi": 0,
		"pakan_kambing": 0
	}
	orchard.clear()
	for index in ORCHARD_SIZE:
		orchard.append(
			{"fruit": "jeruk" if index == 0 else "", "ready_at": now() + 45 if index == 0 else 0}
		)
	storage_capacity = 60
	production_queue.clear()
	feed_queue.clear()
	eggs_ready_at = now() + 28
	seed_recovery_ready_at = 0
	cow_ready_at = 0
	livestock = {"babi": 0, "kambing": 0}
	constructions.clear()
	deliveries = 0
	order_refresh_until = [0, 0, 0]
	order_revision = 0
	market_listings.clear()
	market_sales_count = 0
	visitor_counter = 0
	visitor_next_at = 0
	visitor_request.clear()
	first_visit = true
	onboarding_step = 0
	onboarding_plot_index = -1
	onboarding_skipped = false
	plots.clear()
	layout_positions.clear()
	decorations.clear()
	next_decoration_id = 1
	road_tiles.clear()
	cleared_wild_trees.clear()
	for i in 16:
		plots.append({"crop": "", "ready_at": 0, "planted_at": 0, "unlocked": i < 8})
	# A new farm starts with a small harvestable demonstration patch. These
	# are real crops, with normal harvesting and storage rules, and are only
	# created by new_game(); existing saves load their own plot contents.
	var first_harvest_time := now()
	plots[5]["crop"] = "gandum"
	plots[5]["planted_at"] = first_harvest_time - int(CROPS["gandum"]["grow"])
	plots[5]["ready_at"] = first_harvest_time - 1
	plots[6]["crop"] = "jagung"
	plots[6]["planted_at"] = first_harvest_time - int(CROPS["jagung"]["grow"])
	plots[6]["ready_at"] = first_harvest_time - 1
	plots[7]["crop"] = "gandum"
	plots[7]["planted_at"] = first_harvest_time
	plots[7]["ready_at"] = first_harvest_time + int(CROPS["gandum"]["grow"])
	orders = [
		{"items": {"gandum": 4}, "coins": 42, "xp": 14, "title": "Roti pagi"},
		{"items": {"jagung": 4}, "coins": 92, "xp": 20, "title": "Pasar desa"},
		{"items": {"gandum": 4, "jagung": 2}, "coins": 115, "xp": 26, "title": "Warung Bu Sari"},
	]
	daily_date = ""
	daily_progress.clear()
	daily_claimed.clear()
	checkin_date = ""
	checkin_day = 0
	achievement_progress.clear()
	achievement_claimed_tiers.clear()
	for id in ACHIEVEMENT_ORDER:
		achievement_progress[id] = 0
		achievement_claimed_tiers[id] = 0
	ensure_daily_tasks()
	visitor_request = make_visitor_request()


func ensure_daily_tasks(date_override: String = "") -> bool:
	var today := (
		date_override if not date_override.is_empty() else Time.get_date_string_from_system()
	)
	if daily_date == today:
		return false
	daily_date = today
	daily_progress.clear()
	daily_claimed.clear()
	for id in DAILY_TASK_ORDER:
		daily_progress[id] = 0
		daily_claimed[id] = false
	return true


func add_daily_progress(id: String, amount: int = 1) -> void:
	ensure_daily_tasks()
	if not DAILY_TASKS.has(id) or amount <= 0:
		return
	daily_progress[id] = mini(int(DAILY_TASKS[id]["goal"]), int(daily_progress.get(id, 0)) + amount)


func claim_daily_task(id: String) -> bool:
	ensure_daily_tasks()
	if not DAILY_TASKS.has(id) or bool(daily_claimed.get(id, false)):
		return false
	var task: Dictionary = DAILY_TASKS[id]
	if int(daily_progress.get(id, 0)) < int(task["goal"]):
		return false
	daily_claimed[id] = true
	coins += int(task["coins"])
	diamonds += int(task["diamonds"])
	award_xp(int(task["xp"]))
	save_game()
	return true


func daily_claimed_count() -> int:
	ensure_daily_tasks()
	var count := 0
	for id in DAILY_TASK_ORDER:
		if bool(daily_claimed.get(id, false)):
			count += 1
	return count


func claimable_rewards_count() -> int:
	ensure_daily_tasks()
	var count := 1 if bool(daily_checkin_preview()["available"]) else 0
	for id in DAILY_TASK_ORDER:
		if int(daily_progress.get(id, 0)) >= int(DAILY_TASKS[id]["goal"]) and not bool(daily_claimed.get(id, false)):
			count += 1
	for id in ACHIEVEMENT_ORDER:
		if bool(achievement_status(id)["ready"]):
			count += 1
	return count


func daily_checkin_preview(date_override: String = "") -> Dictionary:
	var today := date_override if not date_override.is_empty() else Time.get_date_string_from_system()
	var already_claimed := checkin_date == today
	# ISO date strings sort chronologically. Reject a clock moved backwards.
	var date_is_valid := today.length() == 10 and today.substr(4, 1) == "-" and today.substr(7, 1) == "-"
	if not date_is_valid:
		return {"available": false, "claimed_today": false, "day": 1, "coins": 35, "diamonds": 0}
	var next_day := 1
	if not checkin_date.is_empty() and checkin_date < today:
		var previous_unix := Time.get_unix_time_from_datetime_string(checkin_date + "T00:00:00")
		var today_unix := Time.get_unix_time_from_datetime_string(today + "T00:00:00")
		if int((today_unix - previous_unix) / 86400.0) == 1:
			next_day = (checkin_day % 7) + 1
	if already_claimed:
		next_day = maxi(1, checkin_day)
	return {
		"available": not already_claimed and (checkin_date.is_empty() or checkin_date < today),
		"claimed_today": already_claimed,
		"day": next_day,
		"coins": 25 + 10 * next_day,
		"diamonds": 1 if next_day == 7 else 0,
	}


func claim_daily_checkin(date_override: String = "") -> Dictionary:
	var preview := daily_checkin_preview(date_override)
	if not bool(preview["available"]):
		return {}
	checkin_date = date_override if not date_override.is_empty() else Time.get_date_string_from_system()
	checkin_day = int(preview["day"])
	coins += int(preview["coins"])
	diamonds += int(preview["diamonds"])
	save_game()
	return preview


func add_achievement_progress(id: String, amount: int = 1) -> void:
	if not ACHIEVEMENTS.has(id) or amount <= 0:
		return
	# Lifetime counters never reset with daily tasks and are saved by the caller.
	achievement_progress[id] = mini(1000000000, int(achievement_progress.get(id, 0)) + amount)


func achievement_status(id: String) -> Dictionary:
	if not ACHIEVEMENTS.has(id):
		return {}
	var info: Dictionary = ACHIEVEMENTS[id]
	var claimed := clampi(int(achievement_claimed_tiers.get(id, 0)), 0, 3)
	var tier := mini(claimed, 2)
	var goal := int(info["goals"][tier])
	var progress := maxi(0, int(achievement_progress.get(id, 0)))
	return {
		"tier": tier + 1,
		"claimed_tiers": claimed,
		"progress": progress,
		"goal": goal,
		"ready": claimed < 3 and progress >= goal,
		"completed": claimed == 3,
		"coins": int(info["coins"][tier]),
		"xp": int(info["xp"][tier]),
		"diamonds": int(info["diamonds"][tier]),
	}


func claim_achievement(id: String) -> Dictionary:
	var status := achievement_status(id)
	if status.is_empty() or not bool(status["ready"]):
		return {}
	achievement_claimed_tiers[id] = int(status["claimed_tiers"]) + 1
	coins += int(status["coins"])
	diamonds += int(status["diamonds"])
	award_xp(int(status["xp"]))
	save_game()
	return status


func now() -> int:
	return int(Time.get_unix_time_from_system())


func crop_info(id: String) -> Dictionary:
	return CROPS.get(id, {})


func item_info(id: String) -> Dictionary:
	if FEED_RECIPES.has(id):
		return FEED_RECIPES[id]
	if LIVESTOCK_PRODUCTS.has(id):
		return LIVESTOCK_PRODUCTS[id]
	if CROPS.has(id):
		return CROPS[id]
	if FRUITS.has(id):
		return FRUITS[id]
	return PRODUCTS.get(id, {})


func construction_count(id: String) -> int:
	return int(constructions.get(id, 0))


func has_construction(id: String) -> bool:
	return construction_count(id) > 0


func buy_construction(id: String) -> bool:
	if not CONSTRUCTIONS.has(id):
		return false
	var info: Dictionary = CONSTRUCTIONS[id]
	var maximum := 3 if id == "petak_bunga" else 1
	if construction_count(id) >= maximum:
		return false
	if level < int(info["level"]) or coins < int(info["cost"]):
		return false
	coins -= int(info["cost"])
	constructions[id] = construction_count(id) + 1
	award_xp(12 if id in DECOR_ORDER else 20)
	save_game()
	return true


func animal_hungry(id: String) -> bool:
	return (
		ANIMALS.has(id)
		and has_construction(ANIMALS[id]["building"])
		and int(livestock.get(id, 0)) <= 0
	)


func animal_ready(id: String) -> bool:
	return (
		ANIMALS.has(id)
		and has_construction(ANIMALS[id]["building"])
		and int(livestock.get(id, 0)) > 0
		and now() >= int(livestock[id])
	)


func can_feed_animal(id: String) -> bool:
	if not animal_hungry(id):
		return false
	if int(inventory.get("pakan_" + id, 0)) > 0:
		return true
	return missing_animal_feed(id).is_empty()


func missing_animal_feed(id: String) -> Dictionary:
	var shortage := {}
	if not animal_hungry(id) or int(inventory.get("pakan_" + id, 0)) > 0:
		return shortage
	var feed: Dictionary = ANIMALS[id]["feed"]
	for ingredient in feed:
		var amount := int(feed[ingredient]) - int(inventory.get(ingredient, 0))
		if amount > 0:
			shortage[ingredient] = amount
	return shortage


func feed_animal(id: String) -> bool:
	if not can_feed_animal(id):
		return false
	var info: Dictionary = ANIMALS[id]
	var feed_id := "pakan_" + id
	if int(inventory.get(feed_id, 0)) > 0:
		inventory[feed_id] = int(inventory[feed_id]) - 1
	else:
		for ingredient in info["feed"]:
			inventory[ingredient] = int(inventory[ingredient]) - int(info["feed"][ingredient])
	livestock[id] = now() + int(info["seconds"])
	save_game()
	return true


func collect_animal(id: String) -> bool:
	if not animal_ready(id):
		return false
	var info: Dictionary = ANIMALS[id]
	var amount := int(info["yield"])
	if storage_used() + amount > storage_capacity:
		return false
	var item_id: String = info["item"]
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	livestock[id] = 0
	award_xp(int(info["xp"]))
	save_game()
	return true


func plant_tree(index: int, fruit_id: String) -> bool:
	if index < 0 or index >= orchard.size() or not FRUITS.has(fruit_id):
		return false
	var info: Dictionary = FRUITS[fruit_id]
	if orchard[index]["fruit"] != "" or level < int(info["level"]) or coins < int(info["cost"]):
		return false
	coins -= int(info["cost"])
	orchard[index] = {"fruit": fruit_id, "ready_at": now() + int(info["grow"])}
	save_game()
	return true


func tree_ready(index: int, timestamp: int = -1) -> bool:
	if index < 0 or index >= orchard.size():
		return false
	var slot: Dictionary = orchard[index]
	return slot["fruit"] != "" and (now() if timestamp < 0 else timestamp) >= int(slot["ready_at"])


# A read-only snapshot of actionable work. Keep it independent of save data so
# opening the dashboard never advances timers, spends resources, or collects.
func ready_activities() -> Array[Dictionary]:
	var activities: Array[Dictionary] = []
	var ready_plots := 0
	var first_ready_plot := -1
	for index in plots.size():
		if is_ready(index):
			ready_plots += 1
			if first_ready_plot == -1:
				first_ready_plot = index
	if ready_plots > 0:
		activities.append({"id": "petak", "title": "PANEN LAHAN", "detail": "%d petak sudah matang" % ready_plots, "count": ready_plots, "tab": "kebun", "plot": first_ready_plot})
	var ready_trees := 0
	for index in orchard.size():
		if tree_ready(index):
			ready_trees += 1
	if ready_trees > 0:
		activities.append({"id": "buah", "title": "KEBUN BUAH", "detail": "%d pohon siap dipanen" % ready_trees, "count": ready_trees, "tab": "kebun_buah"})
	if ready_eggs():
		activities.append({"id": "telur", "title": "TELUR AYAM", "detail": "2 telur siap dikumpulkan", "count": 1, "tab": "ternak"})
	if cow_milk_ready():
		activities.append({"id": "sapi", "title": "SUSU SAPI", "detail": "Susu siap diperah", "count": 1, "tab": "sapi"})
	for id in ANIMAL_ORDER:
		if animal_ready(id):
			activities.append({"id": id, "title": str(ANIMALS[id]["name"]).to_upper(), "detail": "Hasil ternak siap dikumpulkan", "count": 1, "tab": "ternak"})
	for queue_type in ["produksi", "pakan"]:
		var queue: Array[Dictionary] = production_queue if queue_type == "produksi" else feed_queue
		var count := 0
		for task in queue:
			if now() < int(task["ready_at"]):
				break
			count += 1
		if count > 0:
			activities.append({"id": queue_type, "title": "DAPUR PRODUKSI" if queue_type == "produksi" else "PABRIK PAKAN", "detail": "%d hasil selesai diproses" % count, "count": count, "tab": queue_type})
	var ready_orders := 0
	for index in orders.size():
		if not orders[index]["items"].is_empty() and order_can_fill(index):
			ready_orders += 1
	if ready_orders > 0:
		activities.append({"id": "pesanan", "title": "PESANAN TRUK", "detail": "%d pesanan siap dikirim" % ready_orders, "count": ready_orders, "tab": "pesanan"})
	var rewards := claimable_rewards_count()
	if rewards > 0:
		activities.append({"id": "misi", "title": "HADIAH MISI", "detail": "%d hadiah dapat diklaim" % rewards, "count": rewards, "tab": "misi"})
	if visitor_can_sell():
		activities.append({"id": "tamu", "title": "TAMU KEBUN", "detail": "Pesanan tamu dapat dipenuhi", "count": 1, "tab": "pengunjung"})
	return activities


func harvest_tree(index: int) -> int:
	if not tree_ready(index):
		return 0
	var fruit_id: String = orchard[index]["fruit"]
	var info: Dictionary = FRUITS[fruit_id]
	var quantity := int(info["yield"])
	if storage_used() + quantity > storage_capacity:
		return 0
	inventory[fruit_id] = int(inventory[fruit_id]) + quantity
	orchard[index]["ready_at"] = now() + int(info["grow"])
	award_xp(int(info["xp"]))
	add_daily_progress("panen", quantity)
	add_achievement_progress("panen", quantity)
	save_game()
	return quantity


func can_queue_product(id: String) -> bool:
	if not PRODUCTS.has(id) or production_queue.size() >= 3:
		return false
	var recipe: Dictionary = PRODUCTS[id]
	if level < int(recipe["level"]):
		return false
	for ingredient in recipe["ingredients"]:
		if int(inventory.get(ingredient, 0)) < int(recipe["ingredients"][ingredient]):
			return false
	return true


func queue_product(id: String) -> bool:
	if not can_queue_product(id):
		return false
	var recipe: Dictionary = PRODUCTS[id]
	for ingredient in recipe["ingredients"]:
		inventory[ingredient] = int(inventory[ingredient]) - int(recipe["ingredients"][ingredient])
	var start_at := now()
	if not production_queue.is_empty():
		start_at = maxi(start_at, int(production_queue.back()["ready_at"]))
	var duration := int(recipe["seconds"])
	if (
		(id in ["roti", "roti_manis", "kue"] and has_construction("toko_roti"))
		or (id in ["keju", "mentega", "yogurt_kambing"] and has_construction("pabrik_susu"))
	):
		duration = maxi(1, ceili(float(duration) * 0.8))
	production_queue.append(
		{"product": id, "started_at": start_at, "ready_at": start_at + duration}
	)
	save_game()
	return true


func production_ready() -> bool:
	return not production_queue.is_empty() and now() >= int(production_queue[0]["ready_at"])


func count_collectable_products() -> int:
	return _count_collectable_queue(production_queue, PRODUCTS, "product")


func collect_product() -> bool:
	return _collect_ready_queue(production_queue, PRODUCTS, "product", 1) > 0


func collect_ready_products() -> int:
	return _collect_ready_queue(production_queue, PRODUCTS, "product", production_queue.size())


func can_plant(index: int, id: String) -> bool:
	if index < 0 or index >= plots.size() or not CROPS.has(id):
		return false
	return (
		plots[index]["unlocked"]
		and plots[index]["crop"] == ""
		and level >= int(CROPS[id]["level"])
		and int(seeds.get(id, 0)) > 0
	)


func plant(index: int, id: String) -> bool:
	if not can_plant(index, id):
		return false
	var planted_at := now()
	plots[index]["crop"] = id
	plots[index]["planted_at"] = planted_at
	plots[index]["ready_at"] = planted_at + int(CROPS[id]["grow"])
	seeds[id] = int(seeds[id]) - 1
	first_visit = false
	if onboarding_step == 1 and id == "gandum" and index == onboarding_plot_index:
		onboarding_step = 2
	save_game()
	return true


func can_queue_feed(id: String) -> bool:
	if not has_construction("pabrik_pakan") or not FEED_RECIPES.has(id) or feed_queue.size() >= 3:
		return false
	var recipe: Dictionary = FEED_RECIPES[id]
	if level < int(recipe["level"]):
		return false
	for ingredient in recipe["ingredients"]:
		if int(inventory.get(ingredient, 0)) < int(recipe["ingredients"][ingredient]):
			return false
	return true


func queue_feed(id: String) -> bool:
	if not can_queue_feed(id):
		return false
	var recipe: Dictionary = FEED_RECIPES[id]
	for ingredient in recipe["ingredients"]:
		inventory[ingredient] = int(inventory[ingredient]) - int(recipe["ingredients"][ingredient])
	var start_at := now()
	if not feed_queue.is_empty():
		start_at = maxi(start_at, int(feed_queue.back()["ready_at"]))
	feed_queue.append({"feed": id, "started_at": start_at, "ready_at": start_at + int(recipe["seconds"])})
	save_game()
	return true


func feed_ready() -> bool:
	return not feed_queue.is_empty() and now() >= int(feed_queue[0]["ready_at"])


func count_collectable_feed() -> int:
	return _count_collectable_queue(feed_queue, FEED_RECIPES, "feed")


func collect_feed() -> bool:
	return _collect_ready_queue(feed_queue, FEED_RECIPES, "feed", 1) > 0


func collect_ready_feed() -> int:
	return _collect_ready_queue(feed_queue, FEED_RECIPES, "feed", feed_queue.size())


func _count_collectable_queue(queue: Array[Dictionary], recipes: Dictionary, item_key: String) -> int:
	var remaining := storage_capacity - storage_used()
	var current_time := now()
	var count := 0
	for task in queue:
		if int(task["ready_at"]) > current_time:
			break
		var id := str(task[item_key])
		if not recipes.has(id):
			break
		var quantity := int(recipes[id]["yield"])
		if quantity <= 0 or quantity > remaining:
			break
		remaining -= quantity
		count += 1
	return count


func _collect_ready_queue(queue: Array[Dictionary], recipes: Dictionary, item_key: String, limit: int) -> int:
	var count := mini(maxi(0, limit), _count_collectable_queue(queue, recipes, item_key))
	if count == 0:
		return 0
	var total_units := 0
	var total_xp := 0
	for i in count:
		var id := str(queue[0][item_key])
		var quantity := int(recipes[id]["yield"])
		inventory[id] = int(inventory.get(id, 0)) + quantity
		queue.pop_front()
		total_units += quantity
		total_xp += int(recipes[id]["xp"])
	award_xp(total_xp)
	add_daily_progress("produksi", total_units)
	add_achievement_progress("produksi", total_units)
	save_game()
	return count


func is_ready(index: int) -> bool:
	if index < 0 or index >= plots.size():
		return false
	return plots[index]["crop"] != "" and now() >= int(plots[index]["ready_at"])


func storage_used() -> int:
	var total := 0
	for key in inventory:
		total += int(inventory[key])
	return total


func harvest(index: int) -> int:
	if not is_ready(index):
		return 0
	var crop_id: String = plots[index]["crop"]
	var quantity := int(CROPS[crop_id]["yield"])
	# Never clear a crop after storing only part of its yield.
	if storage_used() + quantity > storage_capacity:
		return 0
	inventory[crop_id] = int(inventory[crop_id]) + quantity
	plots[index]["crop"] = ""
	plots[index]["planted_at"] = 0
	plots[index]["ready_at"] = 0
	award_xp(int(CROPS[crop_id]["xp"]))
	add_daily_progress("panen", quantity)
	add_achievement_progress("panen", quantity)
	if onboarding_step == 0 and crop_id == "gandum":
		onboarding_step = 1
		onboarding_plot_index = index
	save_game()
	return quantity


func onboarding_open_orders() -> void:
	if onboarding_step == 2:
		onboarding_step = ONBOARDING_COMPLETE
		save_game()


func skip_onboarding() -> void:
	if onboarding_step >= ONBOARDING_COMPLETE:
		return
	onboarding_step = ONBOARDING_COMPLETE
	onboarding_skipped = true
	save_game()


func award_xp(amount: int) -> bool:
	xp += amount
	var leveled_up := false
	while xp >= xp_target():
		xp -= xp_target()
		level += 1
		diamonds += 2
		leveled_up = true
	return leveled_up


func xp_target() -> int:
	return 30 + (level - 1) * 20


func buy_seeds(id: String, count: int = 5) -> bool:
	if not CROPS.has(id) or count <= 0 or level < int(CROPS[id]["level"]):
		return false
	var cost := int(CROPS[id]["seed_cost"]) * count
	if coins < cost:
		return false
	coins -= cost
	seeds[id] = int(seeds[id]) + count
	save_game()
	return true


func needs_seed_recovery() -> bool:
	if coins >= int(CROPS["gandum"]["seed_cost"]):
		return false
	var has_unlocked_plot := false
	for plot in plots:
		if str(plot.get("crop", "")) != "":
			return false
		if bool(plot.get("unlocked", false)):
			has_unlocked_plot = true
	if not has_unlocked_plot:
		return false
	for id in CROP_ORDER:
		if level >= int(CROPS[id]["level"]) and int(seeds.get(id, 0)) > 0:
			return false
	return true


func seed_recovery_seconds_left() -> int:
	return maxi(0, seed_recovery_ready_at - now())


func can_claim_seed_recovery() -> bool:
	return needs_seed_recovery() and seed_recovery_seconds_left() == 0


func claim_seed_recovery() -> bool:
	if not can_claim_seed_recovery():
		return false
	seeds["gandum"] = int(seeds.get("gandum", 0)) + SEED_RECOVERY_COUNT
	selected_crop = "gandum"
	seed_recovery_ready_at = now() + SEED_RECOVERY_COOLDOWN
	save_game()
	return true


func land_cost() -> int:
	var unlocked := 0
	for plot in plots:
		if plot["unlocked"]:
			unlocked += 1
	return 120 + (unlocked - 8) * 85


func unlock_plot(index: int) -> bool:
	if index < 0 or index >= plots.size() or plots[index]["unlocked"]:
		return false
	if coins < land_cost():
		return false
	coins -= land_cost()
	plots[index]["unlocked"] = true
	award_xp(10)
	save_game()
	return true


func ready_eggs() -> bool:
	return now() >= eggs_ready_at


func collect_eggs() -> bool:
	if not ready_eggs() or storage_used() + 2 > storage_capacity:
		return false
	inventory["telur"] = int(inventory["telur"]) + 2
	eggs_ready_at = now() + 38
	award_xp(8)
	save_game()
	return true


func cow_is_hungry() -> bool:
	return cow_ready_at <= 0


func cow_milk_ready() -> bool:
	return cow_ready_at > 0 and now() >= cow_ready_at


func can_feed_cow() -> bool:
	if not cow_is_hungry():
		return false
	if int(inventory.get("pakan_sapi", 0)) > 0:
		return true
	for ingredient in COW_FEED:
		if int(inventory.get(ingredient, 0)) < int(COW_FEED[ingredient]):
			return false
	return true


func feed_cow() -> bool:
	if not can_feed_cow():
		return false
	if int(inventory.get("pakan_sapi", 0)) > 0:
		inventory["pakan_sapi"] = int(inventory["pakan_sapi"]) - 1
	else:
		for ingredient in COW_FEED:
			inventory[ingredient] = int(inventory[ingredient]) - int(COW_FEED[ingredient])
	cow_ready_at = now() + COW_PRODUCTION_SECONDS
	save_game()
	return true


func collect_milk() -> bool:
	if not cow_milk_ready() or storage_used() + COW_MILK_YIELD > storage_capacity:
		return false
	inventory["susu"] = int(inventory.get("susu", 0)) + COW_MILK_YIELD
	cow_ready_at = 0
	award_xp(10)
	save_game()
	return true


func accelerate(index: int) -> bool:
	if index < 0 or index >= plots.size() or diamonds <= 0:
		return false
	if plots[index]["crop"] == "" or is_ready(index):
		return false
	diamonds -= 1
	plots[index]["ready_at"] = now()
	save_game()
	return true


func order_can_fill(index: int) -> bool:
	if index < 0 or index >= orders.size():
		return false
	for id in orders[index]["items"]:
		if int(inventory.get(id, 0)) < int(orders[index]["items"][id]):
			return false
	return true


func order_progress(index: int) -> float:
	if index < 0 or index >= orders.size():
		return 0.0
	var required := 0
	var available := 0
	for id in orders[index]["items"]:
		var amount := int(orders[index]["items"][id])
		if amount <= 0:
			continue
		required += amount
		available += mini(maxi(0, int(inventory.get(id, 0))), amount)
	return float(available) / float(required) if required > 0 else 0.0


func deliver_order(index: int) -> bool:
	if not order_can_fill(index):
		return false
	var order: Dictionary = orders[index]
	for id in order["items"]:
		inventory[id] = int(inventory[id]) - int(order["items"][id])
	coins += int(order["coins"])
	award_xp(int(order["xp"]))
	deliveries += 1
	add_achievement_progress("pengiriman")
	orders[index] = make_order(index, true)
	add_daily_progress("pesanan")
	save_game()
	return true


func can_refresh_order(index: int, timestamp: int = -1) -> bool:
	var current_time := timestamp if timestamp >= 0 else now()
	return (
		index >= 0
		and index < orders.size()
		and coins >= ORDER_REFRESH_COST
		and current_time >= order_refresh_until[index]
	)


func refresh_order(index: int) -> bool:
	if not can_refresh_order(index):
		return false
	coins -= ORDER_REFRESH_COST
	order_revision += 1
	orders[index] = make_order(index, true)
	order_refresh_until[index] = now() + ORDER_REFRESH_SECONDS
	save_game()
	return true


func make_order(slot: int, avoid_existing: bool = false) -> Dictionary:
	var order_step := deliveries + slot + order_revision
	var candidate := _make_order_for_step(order_step)
	if not avoid_existing:
		return candidate
	# Compare goods with every active contract, including the replaced slot.
	# This keeps paid refreshes and new deliveries from repeating a request.
	for attempt in 32:
		var duplicate := false
		for active_order in orders:
			if order_items_equal(active_order.get("items", {}), candidate["items"]):
				duplicate = true
				break
		if not duplicate:
			return candidate
		candidate = _make_order_for_step(order_step + attempt + 1)
	return candidate


func order_items_equal(left: Dictionary, right: Dictionary) -> bool:
	# JSON decodes numbers as floats; comparing Dictionaries directly may
	# treat {"gandum": 2.0} and {"gandum": 2} as different contracts.
	if left.size() != right.size():
		return false
	for id in left:
		if not right.has(id) or int(left[id]) != int(right[id]):
			return false
	return true


func repair_duplicate_orders() -> int:
	# Legacy saves could contain identical item requests in different slots.
	# Keep the earliest contract, along with all refresh cooldowns and rewards.
	var repaired := 0
	for index in orders.size():
		var items: Dictionary = orders[index].get("items", {})
		var duplicate := false
		for previous in index:
			if order_items_equal(orders[previous].get("items", {}), items):
				duplicate = true
				break
		if not duplicate:
			continue
		order_revision += 1
		var replacement := make_order(index, true)
		var unique := true
		for previous in index:
			if order_items_equal(orders[previous].get("items", {}), replacement["items"]):
				unique = false
				break
		if unique:
			orders[index] = replacement
			repaired += 1
	return repaired


func _make_order_for_step(order_step: int) -> Dictionary:
	var available: Array[String] = []
	for id in CROP_ORDER:
		if level >= int(CROPS[id]["level"]):
			available.append(id)
	# After the first deliveries, every third order asks for a crafted product.
	# This makes production relevant without making early orders impossible.
	if deliveries >= 2:
		var available_products: Array[String] = []
		for id in PRODUCT_ORDER:
			if level >= int(PRODUCTS[id]["level"]) and order_item_accessible(id):
				available_products.append(id)
		if not available_products.is_empty() and order_step % 3 == 0:
			available = available_products
	var id: String = available[order_step % available.size()]
	var qty := 1 + order_step % 2 if PRODUCTS.has(id) else 2 + order_step % 3
	var items := {id: qty}
	# Later contracts combine harvesting, livestock and cooking. Request only
	# items already accessible at the current level or through owned buildings.
	if deliveries >= 3 and order_step % 2 == 0:
		var extras: Array[String] = []
		for crop_id in CROP_ORDER:
			if crop_id != id and level >= int(CROPS[crop_id]["level"]):
				extras.append(crop_id)
		for fruit_id in FRUITS:
			if fruit_id != id and order_item_accessible(fruit_id):
				extras.append(fruit_id)
		for animal_id in ["telur", "susu"]:
			if animal_id != id:
				extras.append(animal_id)
		for animal_id in ANIMAL_ORDER:
			var animal: Dictionary = ANIMALS[animal_id]
			if has_construction(str(animal["building"])) and str(animal["item"]) != id:
				extras.append(str(animal["item"]))
		if not extras.is_empty():
			var extra_id := extras[(order_step / 2) % extras.size()]
			items[extra_id] = 1 if PRODUCTS.has(extra_id) else 2
	var price := 9
	for item_id in items:
		price += int(item_info(item_id)["sell"]) * int(items[item_id]) * 2
	return {
		"title": ["Kafe Pelangi", "Toko Bunga", "Restoran Kota", "Pasar Minggu"][order_step % 4],
		"items": items,
		"coins": price,
		"xp": 12 + items.size() * 6 + (qty * 5),
	}


func order_item_accessible(id: String) -> bool:
	if FRUITS.has(id):
		for tree in orchard:
			if str(tree.get("fruit", "")) == id:
				return true
		return false
	if PRODUCTS.has(id):
		for ingredient in PRODUCTS[id]["ingredients"]:
			for animal_id in ANIMAL_ORDER:
				var animal: Dictionary = ANIMALS[animal_id]
				if ingredient == animal["item"] and not has_construction(str(animal["building"])):
					return false
	return true


func make_visitor_request() -> Dictionary:
	var available: Array[String] = []
	for id in CROP_ORDER:
		if level >= int(CROPS[id]["level"]):
			available.append(id)
	# Every fourth visitor may request a locally craftable product once
	# deliveries introduce the player to the production loop.
	if deliveries >= 2 and visitor_counter % 4 == 3:
		var crafted: Array[String] = []
		for id in PRODUCT_ORDER:
			if level >= int(PRODUCTS[id]["level"]) and order_item_accessible(id):
				crafted.append(id)
		if not crafted.is_empty():
			available = crafted
	var item_id: String = available[visitor_counter % available.size()]
	var quantity := 1 if PRODUCTS.has(item_id) else 2 + visitor_counter % 2
	var offer := {
		"name": VISITOR_NAMES[visitor_counter % VISITOR_NAMES.size()],
		"item": item_id,
		"quantity": quantity,
		"coins": maxi(10, int(item_info(item_id)["sell"]) * quantity * 2),
		"xp": 6 + quantity * 3,
	}
	visitor_counter += 1
	return offer


func refresh_visitor(timestamp: int = -1) -> bool:
	var current_time := timestamp if timestamp >= 0 else now()
	if not visitor_request.is_empty() or current_time < visitor_next_at:
		return false
	visitor_request = make_visitor_request()
	save_game()
	return true


func visitor_can_sell() -> bool:
	if visitor_request.is_empty():
		return false
	var item_id := str(visitor_request.get("item", ""))
	var quantity := int(visitor_request.get("quantity", 0))
	return item_info(item_id).size() > 0 and quantity > 0 and int(inventory.get(item_id, 0)) >= quantity


func fulfill_visitor() -> bool:
	if not visitor_can_sell():
		return false
	var item_id := str(visitor_request["item"])
	var quantity := int(visitor_request["quantity"])
	inventory[item_id] = int(inventory[item_id]) - quantity
	coins += int(visitor_request["coins"])
	award_xp(int(visitor_request["xp"]))
	visitor_request.clear()
	add_achievement_progress("dagang")
	visitor_next_at = now() + VISITOR_ACCEPT_COOLDOWN
	save_game()
	return true


func decline_visitor() -> bool:
	if visitor_request.is_empty():
		return false
	visitor_request.clear()
	visitor_next_at = now() + VISITOR_DECLINE_COOLDOWN
	save_game()
	return true


func sell_quantity(id: String, quantity: int) -> int:
	if quantity <= 0 or not inventory.has(id) or int(inventory[id]) < quantity:
		return 0
	var info := item_info(id)
	var unit_price := int(info.get("sell", 0))
	if unit_price <= 0:
		return 0
	var total := quantity * unit_price
	coins += total
	inventory[id] = int(inventory[id]) - quantity
	add_achievement_progress("dagang")
	save_game()
	return total


func sell_all(id: String) -> int:
	return sell_quantity(id, int(inventory.get(id, 0)))


func list_market_item(id: String, quantity: int) -> bool:
	if not inventory.has(id) or item_info(id).is_empty():
		return false
	if quantity < 1 or quantity > 3 or market_listings.size() >= MARKET_MAX_SLOTS:
		return false
	if int(inventory[id]) < quantity:
		return false
	inventory[id] = int(inventory[id]) - quantity
	(
		market_listings
		. append(
			{
				"item": id,
				"quantity": quantity,
				"unit_price": int(item_info(id)["sell"]) * 2,
				"ready_at": now() + MARKET_SALE_SECONDS + market_listings.size() * 15,
			}
		)
	)
	save_game()
	return true


func cancel_market_listing(index: int) -> bool:
	if index < 0 or index >= market_listings.size():
		return false
	var listing: Dictionary = market_listings[index]
	if now() >= int(listing["ready_at"]):
		return false
	var quantity := int(listing["quantity"])
	if storage_used() + quantity > storage_capacity:
		return false
	var id: String = listing["item"]
	inventory[id] = int(inventory[id]) + quantity
	market_listings.remove_at(index)
	save_game()
	return true


func settle_market_sales(timestamp: int = -1) -> int:
	var current_time := timestamp if timestamp >= 0 else now()
	var earned := 0
	var sold_units := 0
	for index in range(market_listings.size() - 1, -1, -1):
		var listing: Dictionary = market_listings[index]
		if current_time < int(listing["ready_at"]):
			continue
		var quantity := int(listing["quantity"])
		earned += quantity * int(listing["unit_price"])
		sold_units += quantity
		market_sales_count += 1
		add_achievement_progress("dagang")
		market_listings.remove_at(index)
	if earned > 0:
		coins += earned
		award_xp(sold_units * 3)
		save_game()
	return earned


func upgrade_storage() -> bool:
	var cost := 180 + (storage_capacity - 60) * 3
	if coins < cost:
		return false
	coins -= cost
	storage_capacity += 30
	save_game()
	return true


func decoration_by_key(key: String) -> Dictionary:
	for item in decorations:
		if str(item.get("key", "")) == key:
			return item
	return {}


func stored_decoration_count(kind: String) -> int:
	var count := 0
	for item in decorations:
		if str(item.get("kind", "")) == kind and (item.get("position", []) as Array).is_empty():
			count += 1
	return count


func buy_decoration(kind: String) -> String:
	if not DECORATIONS.has(kind):
		return ""
	var price := int(DECORATIONS[kind]["cost"])
	if coins < price:
		return ""
	coins -= price
	var key := "dekor_%d" % next_decoration_id
	next_decoration_id += 1
	decorations.append({"key": key, "kind": kind, "position": []})
	save_game()
	return key


func set_decoration_position(key: String, at: Vector2) -> bool:
	if not at.is_finite() or at.x < 25.0 or at.x > 3575.0 or at.y < 25.0 or at.y > 2875.0:
		return false
	for item in decorations:
		if str(item.get("key", "")) == key:
			item["position"] = [at.x, at.y]
			save_game()
			return true
	return false


func store_decoration(key: String) -> bool:
	for item in decorations:
		if str(item.get("key", "")) == key:
			item["position"] = []
			save_game()
			return true
	return false


func save_game() -> void:
	ensure_daily_tasks()
	var data := {
		"version": 1,
		"coins": coins,
		"diamonds": diamonds,
		"level": level,
		"xp": xp,
		"selected_crop": selected_crop,
		"plots": plots,
		"layout_positions": layout_positions,
		"decorations": decorations,
		"next_decoration_id": next_decoration_id,
		"road_tiles": road_tiles.keys(),
		"cleared_wild_trees": cleared_wild_trees,
		"seeds": seeds,
		"inventory": inventory,
		"storage_capacity": storage_capacity,
		"production_queue": production_queue,
		"feed_queue": feed_queue,
		"eggs_ready_at": eggs_ready_at,
		"seed_recovery_ready_at": seed_recovery_ready_at,
		"cow_ready_at": cow_ready_at,
		"livestock": livestock,
		"constructions": constructions,
		"deliveries": deliveries,
		"orders": orders,
		"order_refresh_until": order_refresh_until,
		"order_revision": order_revision,
		"market_listings": market_listings,
		"market_sales_count": market_sales_count,
		"visitor_request": visitor_request,
		"visitor_counter": visitor_counter,
		"visitor_next_at": visitor_next_at,
		"orchard": orchard,
		"first_visit": first_visit,
		"onboarding_step": onboarding_step,
		"onboarding_plot_index": onboarding_plot_index,
		"onboarding_skipped": onboarding_skipped,
		"daily_date": daily_date,
		"daily_progress": daily_progress,
		"daily_claimed": daily_claimed,
		"checkin_date": checkin_date,
		"checkin_day": checkin_day,
		"achievement_progress": achievement_progress,
		"achievement_claimed_tiers": achievement_claimed_tiers,
		"last_saved": now(),
	}
	var path := save_path
	if FileAccess.file_exists(path):
		var existing := FileAccess.get_file_as_string(path)
		if JSON.parse_string(existing) is Dictionary:
			var backup := FileAccess.open(backup_path, FileAccess.WRITE)
			if backup:
				backup.store_string(existing)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	last_saved = now()


func load_game() -> bool:
	for path in [save_path, backup_path]:
		if not FileAccess.file_exists(path):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or int(data.get("version", 0)) != 1:
			continue
		if not data.get("plots", null) is Array or data["plots"].size() != 16:
			continue
		coins = maxi(0, int(data.get("coins", 400)))
		diamonds = maxi(0, int(data.get("diamonds", 12)))
		level = maxi(1, int(data.get("level", 1)))
		xp = maxi(0, int(data.get("xp", 0)))
		selected_crop = str(data.get("selected_crop", "gandum"))
		if not CROPS.has(selected_crop):
			selected_crop = "gandum"
		plots.clear()
		for item in data["plots"]:
			if not item is Dictionary:
				return false
			plots.append(item)
		layout_positions.clear()
		road_tiles.clear()
		cleared_wild_trees.clear()
		var saved_roads = data.get("road_tiles", [])
		if saved_roads is Array:
			for entry in saved_roads:
				if not entry is String:
					continue
				var parts := (entry as String).split(",")
				if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
					continue
				var column := int(parts[0])
				var row := int(parts[1])
				if column >= 0 and column < 45 and row >= 0 and row < 36:
					road_tiles["%d,%d" % [column, row]] = true
		var saved_cleared = data.get("cleared_wild_trees", [])
		if saved_cleared is Array:
			for entry in saved_cleared:
				if (entry is int or entry is float) and int(entry) >= 0 and int(entry) < 1000:
					var tree_id := int(entry)
					if not cleared_wild_trees.has(tree_id):
						cleared_wild_trees.append(tree_id)
		var stored_positions = data.get("layout_positions", {})
		if stored_positions is Dictionary:
			for key in stored_positions:
				var coords = stored_positions[key]
				if (
					coords is Array and coords.size() == 2
					and (coords[0] is float or coords[0] is int)
					and (coords[1] is float or coords[1] is int)
				):
					var point := Vector2(float(coords[0]), float(coords[1]))
					if point.is_finite() and point.x >= 0.0 and point.y >= 0.0:
						layout_positions[str(key)] = [point.x, point.y]
		decorations.clear()
		next_decoration_id = maxi(1, int(data.get("next_decoration_id", 1)))
		var saved_decorations = data.get("decorations", [])
		var seen_decorations := {}
		if saved_decorations is Array:
			for entry in saved_decorations:
				if not entry is Dictionary:
					continue
				var key := str(entry.get("key", ""))
				var kind := str(entry.get("kind", ""))
				if not key.begins_with("dekor_") or not key.trim_prefix("dekor_").is_valid_int() or not DECORATIONS.has(kind) or seen_decorations.has(key):
					continue
				var suffix := int(key.trim_prefix("dekor_"))
				if suffix <= 0:
					continue
				seen_decorations[key] = true
				next_decoration_id = maxi(next_decoration_id, suffix + 1)
				var position: Array = []
				var saved_at = entry.get("position", [])
				if saved_at is Array and saved_at.size() == 2 and (saved_at[0] is int or saved_at[0] is float) and (saved_at[1] is int or saved_at[1] is float):
					var at := Vector2(float(saved_at[0]), float(saved_at[1]))
					if at.is_finite() and at.x >= 25.0 and at.x <= 3575.0 and at.y >= 25.0 and at.y <= 2875.0:
						position = [at.x, at.y]
				decorations.append({"key": key, "kind": kind, "position": position})
		for id in seeds:
			seeds[id] = maxi(0, int(data.get("seeds", {}).get(id, seeds[id])))
		for id in inventory:
			inventory[id] = maxi(0, int(data.get("inventory", {}).get(id, 0)))
		orchard.clear()
		var saved_orchard = data.get("orchard", [])
		for index in ORCHARD_SIZE:
			var slot: Dictionary = (
				saved_orchard[index]
				if (
					saved_orchard is Array
					and index < saved_orchard.size()
					and saved_orchard[index] is Dictionary
				)
				else {}
			)
			var fruit_id := str(slot.get("fruit", ""))
			if not FRUITS.has(fruit_id):
				fruit_id = ""
			orchard.append(
				{
					"fruit": fruit_id,
					"ready_at": maxi(0, int(slot.get("ready_at", 0))) if fruit_id != "" else 0
				}
			)
		storage_capacity = maxi(60, int(data.get("storage_capacity", 60)))
		production_queue.clear()
		var saved_queue = data.get("production_queue", [])
		if saved_queue is Array:
			for task in saved_queue:
				if not task is Dictionary or production_queue.size() >= 3:
					break
				var product_id := str(task.get("product", ""))
				var started_at := int(task.get("started_at", 0))
				var ready_at := int(task.get("ready_at", 0))
				if PRODUCTS.has(product_id) and ready_at >= started_at and started_at > 0:
					production_queue.append(
						{"product": product_id, "started_at": started_at, "ready_at": ready_at}
					)
		feed_queue.clear()
		var saved_feed_queue = data.get("feed_queue", [])
		if saved_feed_queue is Array:
			for task in saved_feed_queue:
				if not task is Dictionary or feed_queue.size() >= 3:
					break
				var feed_id := str(task.get("feed", ""))
				var started_at := int(task.get("started_at", 0))
				var ready_at := int(task.get("ready_at", 0))
				if FEED_RECIPES.has(feed_id) and started_at > 0 and ready_at >= started_at:
					feed_queue.append({"feed": feed_id, "started_at": started_at, "ready_at": ready_at})
		eggs_ready_at = int(data.get("eggs_ready_at", now() + 28))
		seed_recovery_ready_at = maxi(0, int(data.get("seed_recovery_ready_at", 0)))
		cow_ready_at = maxi(0, int(data.get("cow_ready_at", 0)))
		var saved_animals = data.get("livestock", {})
		for id in ANIMAL_ORDER:
			livestock[id] = (
				maxi(0, int(saved_animals.get(id, 0))) if saved_animals is Dictionary else 0
			)
		constructions.clear()
		var saved_buildings = data.get("constructions", {})
		if saved_buildings is Dictionary:
			for id in CONSTRUCTIONS:
				var maximum := 3 if id == "petak_bunga" else 1
				var owned := clampi(int(saved_buildings.get(id, 0)), 0, maximum)
				if owned > 0:
					constructions[id] = owned
		deliveries = maxi(0, int(data.get("deliveries", 0)))
		order_revision = maxi(0, int(data.get("order_revision", 0)))
		order_refresh_until = [0, 0, 0]
		var saved_refresh = data.get("order_refresh_until", [])
		if saved_refresh is Array:
			for index in mini(3, saved_refresh.size()):
				order_refresh_until[index] = maxi(0, int(saved_refresh[index]))
		market_listings.clear()
		var saved_listings = data.get("market_listings", [])
		if saved_listings is Array:
			for listing in saved_listings:
				if not listing is Dictionary or market_listings.size() >= MARKET_MAX_SLOTS:
					continue
				var item_id := str(listing.get("item", ""))
				var quantity := int(listing.get("quantity", 0))
				var unit_price := int(listing.get("unit_price", 0))
				var ready_at := int(listing.get("ready_at", 0))
				if (
					inventory.has(item_id)
					and quantity in [1, 2, 3]
					and unit_price > 0
					and ready_at > 0
				):
					market_listings.append(
						{
							"item": item_id,
							"quantity": quantity,
							"unit_price": unit_price,
							"ready_at": ready_at
						}
					)
		market_sales_count = maxi(0, int(data.get("market_sales_count", 0)))
		visitor_counter = maxi(0, int(data.get("visitor_counter", 0)))
		visitor_next_at = maxi(0, int(data.get("visitor_next_at", 0)))
		visitor_request.clear()
		var stored_visitor = data.get("visitor_request", {})
		if stored_visitor is Dictionary:
			var item_id := str(stored_visitor.get("item", ""))
			var quantity := int(stored_visitor.get("quantity", 0))
			if (not item_info(item_id).is_empty() and quantity >= 1 and quantity <= 5
				and int(stored_visitor.get("coins", 0)) > 0
				and int(stored_visitor.get("xp", 0)) > 0):
				visitor_request = {
					"name": str(stored_visitor.get("name", "Tetangga")),
					"item": item_id,
					"quantity": quantity,
					"coins": int(stored_visitor["coins"]),
					"xp": int(stored_visitor["xp"]),
				}
		# Old saves have no visitor fields. They receive a visitor on the
		# next refresh without changing their existing crops or inventory.
		first_visit = bool(data.get("first_visit", false))
		# Saves from before onboarding belong to existing players: do not interrupt them.
		onboarding_step = clampi(int(data.get("onboarding_step", ONBOARDING_COMPLETE)), 0, ONBOARDING_COMPLETE)
		onboarding_plot_index = clampi(int(data.get("onboarding_plot_index", -1)), -1, plots.size() - 1)
		onboarding_skipped = bool(data.get("onboarding_skipped", false))
		if data.get("orders", null) is Array and data["orders"].size() == 3:
			orders.clear()
			for order in data["orders"]:
				orders.append(order)
		var repaired_orders := repair_duplicate_orders()
		# Old saves retain known delivery / NPC market totals. Other counters
		# start at zero because historical transactions were never recorded.
		var saved_achievements = data.get("achievement_progress", {})
		var saved_tiers = data.get("achievement_claimed_tiers", {})
		achievement_progress.clear()
		achievement_claimed_tiers.clear()
		for id in ACHIEVEMENT_ORDER:
			var baseline := deliveries if id == "pengiriman" else market_sales_count if id == "dagang" else 0
			var total := int(saved_achievements.get(id, baseline)) if saved_achievements is Dictionary else baseline
			achievement_progress[id] = clampi(maxi(baseline, total), 0, 1000000000)
			var claimed := int(saved_tiers.get(id, 0)) if saved_tiers is Dictionary else 0
			achievement_claimed_tiers[id] = clampi(claimed, 0, 3)
		daily_date = str(data.get("daily_date", ""))
		checkin_date = str(data.get("checkin_date", ""))
		checkin_day = clampi(int(data.get("checkin_day", 0)), 0, 7)
		if checkin_date.length() != 10 or checkin_date.substr(4, 1) != "-" or checkin_date.substr(7, 1) != "-" or checkin_day == 0:
			checkin_date = ""
			checkin_day = 0
		var saved_progress = data.get("daily_progress", {})
		var saved_claims = data.get("daily_claimed", {})
		daily_progress.clear()
		daily_claimed.clear()
		for id in DAILY_TASK_ORDER:
			var progress := int(saved_progress.get(id, 0)) if saved_progress is Dictionary else 0
			daily_progress[id] = clampi(progress, 0, int(DAILY_TASKS[id]["goal"]))
			daily_claimed[id] = (
				bool(saved_claims.get(id, false)) if saved_claims is Dictionary else false
			)
		ensure_daily_tasks()
		last_saved = int(data.get("last_saved", now()))
		if repaired_orders > 0:
			save_game()
		return true
	return false


func clear_wild_tree(tree_id: int) -> bool:
	if tree_id < 0 or tree_id >= 1000 or cleared_wild_trees.has(tree_id):
		return false
	cleared_wild_trees.append(tree_id)
	coins += 6
	award_xp(3)
	return true
