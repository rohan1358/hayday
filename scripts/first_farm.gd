extends RefCounted
# Versioned FTUE. Empty state means a legacy farm: never migrate its layout,
# economy, crop requirements or tutorial into the new-player experience.
const STEPS = {
 "welcome": ["Misi Pertama · Tanam 3 Gandum · 0/3", "Selamat datang di Cheerful Garden! Yuk, mulai dengan menanam gandum terlebih dahulu! Ketuk petak yang bercahaya."],
 "plant": ["Misi pertama · Tanam 3 gandum", "Pilih bibit GANDUM, lalu TANAM. Petani akan berjalan ke petak dan menanamnya."],
 "grow": ["Kebunmu mulai tumbuh", "Lihat benih menjadi tunas, lalu gandum matang. Pertumbuhan pertama hanya 8 detik."],
 "harvest": ["Panen pertamamu", "Ketuk gandum bertanda SIAP. Panen ketiga petak untuk menyelesaikan misi."],
 "sale": ["Tetangga pertama datang", "Bu Sari ingin membeli 3 gandum. Ketuk tetangga atau tombol TAMU untuk menjualnya."],
 "reward": ["Misi selesai! · Naik ke Level 2", "Penjualan berhasil: +50 koin dan +30 XP. Lanjutkan untuk menyiapkan peternakan Level 3."],
 "done": ["Kebunmu mulai hidup!", "Semakin berkembang kebunmu, semakin banyak hal menarik yang bisa ditemukan."]
}
const FEATURE_LEVELS = {"house":1,"inventory":1,"visitors":1,"shop":1,"orders":3,"decorations":2,"roads":2,"expansion":2,"production":1,"ranch":3,"ecosystem":4,"evolution":20}
const TABS = {"prestasi":"inventory","upgrade":"house","gudang":"inventory","pengunjung":"visitors","toko":"shop","pesanan":"orders","produksi":"production","roti":"production","susu":"production","pakan":"ranch","sapi":"ranch","babi":"ranch","kambing":"ranch","ayam":"ranch","ternak":"ranch","bangun":"decorations","pasar":"orders","kebun_buah":"shop","jalan":"roads","dekorasi":"decorations","bunga":"decorations","pohon":"decorations","rumput":"decorations","gedung":"decorations","misi":"shop","aktivitas":"orders","kawasan":"inventory"}
static func enabled(game) -> bool: return int(game.ftue.get("version",0))==1
static func restore(game) -> void:
 if not enabled(game): return
 for key in ["planted","harvested"]:
  var indices=[]
  for value in game.ftue.get(key,[]):
   var index=int(value)
   if index in [0,1,2] and not indices.has(index): indices.append(index)
  game.ftue[key]=indices
 if not STEPS.has(str(game.ftue.get("step","done"))): game.ftue.step="done"
static func active(game) -> bool: return enabled(game) and str(game.ftue.get("step","done"))!="done"
static func compact(game) -> bool: return enabled(game)
static func feature(game,id: String) -> bool:
 if id=="decorations" and enabled(game):return bool(game.ftue.get("started",false))
 if not enabled(game): return true
 if active(game) and id not in ["inventory","visitors"]: return false
 return game.level>=int(FEATURE_LEVELS.get(id,1))
static func tab(game,id: String) -> bool:
 if enabled(game) and not bool(game.ftue.get("started",true)): return id=="kebun"
 if id in ["rumah","upgrade","roti","susu","produksi","ayam","sapi","babi","kambing","ternak"]: return true
 if id=="pasar" and not active(game):return true
 if active(game): return id in ["kebun","gudang","pengunjung","koleksi","pengaturan","hadiah_pemula","pesan"]
 if enabled(game) and id=="ayam": return game.level>=2 and not active(game)
 return feature(game,str(TABS.get(id,"inventory")))
static func spendable(game,id: String) -> int:
 var count=int(game.inventory.get(id,0))
 return maxi(0,count-3) if active(game) and id=="gandum" else count
static func crop_level(game,id: String) -> int:
 return int(game.CROPS[id].level)
static func start(game) -> void:
 game.ftue={"version":1,"started":false,"step":"welcome","planted":[],"harvested":[],"sale_done":false,"reward_claimed":false,"skipped":false,"coop_built":false,"poultry_step":"build"}
 game.coins=100
 game.diamonds=10
 game.selected_crop="gandum"
 for id in game.seeds: game.seeds[id]=0
 game.seeds.gandum=3
 for i in game.plots.size(): game.plots[i]={"crop":"","planted_at":0,"ready_at":0,"unlocked":i<3}
 game.layout_positions.merge({"dapur":[960,590],"buah_0":[1310,590],"petak_0":[1010,855],"petak_1":[1120,915],"petak_2":[1230,855],"pasar":[1180,800],"ayam":[1470,950]})
 game.hybrid={"player":[850,880],"follow":false}
 game.orchard[0].fruit="apel"
 game.road_tiles={"10,9":"stone","11,9":"stone","12,9":"stone"}
 game.eggs_ready_at=0
 game.inventory["pakan_ayam"]=0
 game.ranch.pens.ayam.count=0
 game.ranch.pens.sapi.count=0
 game.visitor_request.clear()
 game.onboarding_step=game.ONBOARDING_COMPLETE
 preload("res://scripts/cheerful_layout.gd").apply(game,true)
static func selected(game,index: int) -> void:
 if active(game) and game.ftue.step=="welcome" and index in [0,1,2]:
  game.ftue.step="plant"
  game.save_game()
static func allow_plant(game,index: int,id: String) -> bool:
 return not active(game) or (game.ftue.get("started",true) and game.ftue.step=="plant" and index in [0,1,2] and id=="gandum" and not game.ftue.planted.has(index))
static func planted(game,index: int) -> void:
 if not active(game): return
 game.ftue.planted.append(index)
 game.plots[index].ready_at=game.plots[index].planted_at+8
 game.award_xp(15 if game.ftue.planted.size()==3 else 20)
 if game.ftue.planted.size()==3: game.ftue.step="grow"
static func harvested(game,index: int) -> void:
 if not active(game) or not game.ftue.planted.has(index) or game.ftue.harvested.has(index): return
 game.ftue.harvested.append(index)
 if game.ftue.harvested.size()==3:
  game.ftue.step="sale"
  game.visitor_request={"name":"Bu Sari","item":"gandum","quantity":3,"coins":50,"xp":30,"first_farm":true}
static func tick(game) -> bool:
 if not active(game): return false
 if game.ftue.step=="grow":
  for index in game.ftue.planted:
   if game.is_ready(int(index)):
    game.ftue.step="harvest"
    game.save_game()
    return true
 return false
static func sold(game) -> void:
 if not active(game) or game.ftue.step!="sale": return
 game.ftue.sale_done=true
 game.ftue.step="reward"
static func claim(game) -> bool:
 if not active(game) or game.ftue.step!="reward" or bool(game.ftue.reward_claimed): return false
 # Stage and claim marker are committed in the same save as the economy.
 game.ftue.reward_claimed=true
 game.ftue.step="done"
 game.seeds.gandum=int(game.seeds.get("gandum",0))+3
 game.save_game()
 return true
static func skip(game) -> void:
 if not active(game): return
 game.ftue.step="done"
 game.ftue.skipped=true
 game.ftue.started=true
 game.onboarding_skipped=true
 # Free seeds already granted at new-game creation are never granted again.
 game.save_game()
static func target(game) -> int:
 if not active(game): return -1
 if game.ftue.step in ["welcome","plant"]:
  for i in 3:
   if game.plots[i].crop=="": return i
 if game.ftue.step in ["grow","harvest"]:
  for i in 3:
   if not game.ftue.harvested.has(i) and game.is_ready(i): return i
  for i in 3:
   if not game.ftue.harvested.has(i): return i
 return -1
