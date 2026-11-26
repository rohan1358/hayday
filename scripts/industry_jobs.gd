extends RefCounted
const RECIPES={"gandum":{"output":"tepung","seconds":60},"jagung":{"output":"tepung_jagung","seconds":60},"kedelai":{"output":"tepung_kedelai","seconds":120},"padi":{"output":"tepung_beras","seconds":120}}
static func jobs(game) -> Dictionary:
 if not game.world_regions.has("industry_jobs"):game.world_regions.industry_jobs={}
 return game.world_regions.industry_jobs
static func remaining(game,kind: String) -> int:
 return maxi(0,int(jobs(game).get(kind,{}).get("ready_at",0))-game.now())
static func start(game,kind: String,crop: String="gandum") -> String:
 var regions=load("res://scripts/world_regions.gd")
 if kind not in ["penggilingan","tambang"] or not regions.purchased(game,kind):return "Bangun fasilitas dahulu."
 if jobs(game).has(kind):return "Mesin sedang dipakai. Ambil hasil sebelum memulai lagi."
 var seconds=75;var output=""
 if kind=="penggilingan":
  if not RECIPES.has(crop):return "Bahan tidak tersedia."
  if int(game.inventory.get(crop,0))<2:return "Perlu 2 "+str(game.item_info(crop).name)+"."
  if game.storage_used()-2+1>game.storage_capacity:return "Gudang penuh."
  seconds=int(RECIPES[crop].seconds);output=str(RECIPES[crop].output);game.inventory[crop]-=2
 jobs(game)[kind]={"crop":crop,"output":output,"seconds":seconds,"started_at":game.now(),"ready_at":game.now()+seconds}
 game.save_game();return "Produksi dimulai." if kind=="penggilingan" else "Penambang mulai memahat. Hasil siap dalam 1 menit 15 detik."
static func claim(game,kind: String) -> String:
 if not jobs(game).has(kind):return "Belum ada hasil."
 if remaining(game,kind)>0:return "Proses belum selesai."
 var job: Dictionary=jobs(game)[kind]
 if kind=="penggilingan" and game.storage_used()+1>game.storage_capacity:return "Gudang penuh. Hasil tetap tersimpan di mesin."
 jobs(game).erase(kind)
 if kind=="tambang":
  var materials=load("res://scripts/building_upgrades.gd").prepare(game).materials
  materials.batu=int(materials.batu)+2;materials.palu=int(materials.palu)+1
 else:
  game.inventory[job.output]=int(game.inventory.get(job.output,0))+1
  game.add_daily_progress("produksi");game.add_achievement_progress("produksi")
 game.award_xp(8);game.save_game()
 return "+2 batu dan +1 palu untuk upgrade." if kind=="tambang" else "+1 "+str(game.item_info(job.output).name)+" masuk Gudang."
