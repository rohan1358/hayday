extends RefCounted
const STATE=preload("res://scripts/hybrid/hybrid_state.gd")
const DURATIONS={"gather":1.8,"move":0.0,"plant":1.0,"water":1.4,"fertilize":1.1,"harvest":1.2,"feed":1.4,"drink":1.3,"collect":2.0,"clean":2.0,"pet":1.5,"herd":0.3,"orchard":1.3,"open":0.1,"chop":1.5,"refill":1.4,"region":1.5}
const TITLES={"gather":"Memahat batu","milk":"Memerah susu","eggs":"Mengambil telur","shear":"Menggunting wol","idle":"Istirahat","walk":"Berjalan","run":"Berlari","sit":"Duduk","observe":"Mengamati kebun","watch_animals":"Melihat ternak","move":"Berjalan","plant":"Menanam","water":"Menyiram","fertilize":"Memupuk","harvest":"Memanen","feed":"Memberi pakan","drink":"Memberi minum","collect":"Mengambil hasil","clean":"Membersihkan kandang","pet":"Mengelus","herd":"Menggiring","orchard":"Memanen buah","open":"Membuka bangunan","chop":"Menebang","refill":"Mengisi air","region":"Mengelola kawasan"}
var system
func configure(owner_system) -> void: system=owner_system
func plot_job(action: String,index: int) -> Dictionary:
	var game=system.host.game
	if index<0 or index>=game.plots.size(): return {}
	var plot: Dictionary=game.plots[index]
	return {"action":action,"target":"plot","index":index,"crop":game.selected_crop if action=="plant" else str(plot.crop),"planted_at":int(plot.planted_at),"generation":int(game.hybrid.get("crop_generation",{}).get(str(index),0))}
func valid(job: Dictionary) -> String:
	var game=system.host.game
	var action=str(job.get("action",""))
	if not DURATIONS.has(action): return "Perintah tidak dikenal."
	if action=="region":
		var region_id := str(job.get("region", ""))
		var regions = preload("res://scripts/world_regions.gd")
		if not regions.purchased(game, region_id): return "Kawasan belum dibeli."
		if regions.wait_seconds(game, region_id)>0: return "Kawasan masih beristirahat."
	if action=="gather" and not preload("res://scripts/building_upgrades.gd").valid_node(game,job): return "Bahan sudah diambil; tunggu persediaan pulih."
	if action=="chop":
		var tree_index=int(job.get("index",-1))
		if tree_index<0 or tree_index>=system.farm.WILD_TREES.size() or not system.farm.wild_tree_active(tree_index): return "Pohon sudah ditebang."
	var target_kind=str(job.get("target",""))
	if action in ["plant","water","fertilize","harvest"] and target_kind!="plot": return "Target petak tidak valid."
	if action in ["feed","drink","collect","clean","pet","herd"] and target_kind!="animal": return "Target hewan tidak valid."
	if str(job.get("target",""))=="plot":
		var i=int(job.get("index",-1))
		if i<0 or i>=game.plots.size() or not game.plots[i].unlocked: return "Lahan belum dibuka. Gunakan mode Kelola untuk membeli lahan."
		var plot: Dictionary=game.plots[i]
		if action=="plant": return "Bibit habis, tanaman belum kosong, atau level belum cukup." if not game.can_plant(i,str(job.get("crop",""))) else ""
		if int(job.get("generation",-1))!=int(game.hybrid.get("crop_generation",{}).get(str(i),0)): return "Tanaman telah diganti; perintah lama dilewati."
		if str(plot.crop)=="" or str(plot.crop)!=str(job.get("crop","")) or int(plot.planted_at)!=int(job.get("planted_at",-1)): return "Tanaman telah berubah; perintah lama dilewati."
		if action=="harvest": return "Panen belum siap atau gudang penuh." if not game.is_ready(i) or game.storage_used()+int(game.CROPS[plot.crop].yield)>game.storage_capacity else ""
		if game.is_ready(i): return "Tanaman sudah matang."
		var care: Dictionary=system.data.crop_care.get(str(i),{})
		if int(care.get("planted_at",-1))==int(plot.planted_at) and int(care.get("generation",-1))==int(job.get("generation",0)) and bool(care.get(action,false)): return "Tanaman ini sudah dirawat dengan cara yang sama."
		if action=="water" and int(system.data.water)<=0: return "Air habis. Isi air di sumur."
		if action=="fertilize" and int(system.data.fertilizer)<=0: return "Pupuk habis. Beli pupuk atau bersihkan kandang."
	if str(job.get("target",""))=="animal":
		var animal: Dictionary=system.animals.animal(str(job.get("animal","")))
		if animal.is_empty(): return "Hewan tidak ditemukan."
		if action=="herd" and animal.get("legacy_pen",false): return "Hewan ini tinggal di kandang asli."
		if action=="drink" and int(system.data.water)<=0: return "Air habis."
		if action=="herd" and system.animals.zone(int(job.get("zone",-1))).is_empty(): return "Zona tujuan tidak ditemukan."
	return ""
func target(job: Dictionary) -> Vector2:
	match str(job.get("target","")):
		"plot": return system.farm.plot_center(int(job.index))
		"animal":
			var animal: Dictionary=system.animals.animal(str(job.get("animal","")))
			if str(job.get("action",""))=="clean" and not animal.is_empty():
				var zone: Dictionary=system.animals.zone(int(animal.zone))
				if not zone.is_empty(): return STATE.zone_rect(zone).position+Vector2(80,60)
			return system.animals.position(animal) if not animal.is_empty() else Vector2.INF
		"building": return system.farm.object_position(str(job.get("key","")))
		"region": return system.farm.object_position("region_" + str(job.get("region", "")))
		"orchard": return system.farm.orchard_center(int(job.index))
		"tree":
			var i=int(job.get("index",-1))
			return system.farm.wild_tree_position(i) if i>=0 and i<system.farm.WILD_TREES.size() else Vector2.INF
	return STATE.point(job.get("position",[]),Vector2.INF)
func reach(job: Dictionary) -> float:
	if job.get("target","")=="plot" and not system.host.game.ftue.is_empty(): return 120.0
	if job.get("target","")=="animal" and system.animals.animal(str(job.get("animal",""))).get("legacy_pen",false): return 270.0
	if str(job.get("key",""))=="ternak": return 270.0
	if job.get("target","")=="region": return 235.0
	return 215.0 if job.get("target","")=="plot" else (110.0 if job.get("target","")=="animal" else 165.0)
func execute(job: Dictionary) -> Dictionary:
	var error=valid(job)
	if not error.is_empty(): return {"ok":false,"message":error}
	var game=system.host.game
	var action=str(job.action)
	var ok=false
	var message=TITLES.get(action,action)+" selesai."
	if action=="gather":
		ok=preload("res://scripts/building_upgrades.gd").gather(game,job)
		if ok:
			system.farm.show_world_feedback("chop_done",target(job),"+3 batu")
			message="Bongkahan dipahat: +3 batu kecil."
	elif action=="region":
		var regions = preload("res://scripts/world_regions.gd")
		message=regions.action(game,str(job.get("region", "")))
		ok=regions.wait_seconds(game,str(job.get("region", "")))>0
	elif job.get("target","")=="plot":
		var index=int(job.index)
		if action=="plant": ok=game.plant(index,str(job.crop))
		elif action=="harvest": ok=game.harvest(index)>0
		else:
			var plot: Dictionary=game.plots[index]
			var care: Dictionary=system.data.crop_care.get(str(index),{})
			if int(care.get("planted_at",-1))!=int(plot.planted_at): care={"planted_at":int(plot.planted_at),"generation":int(game.hybrid.get("crop_generation",{}).get(str(index),0))}
			care[action]=true
			system.data.crop_care[str(index)]=care
			if action=="water": system.data.water=int(system.data.water)-1
			else: system.data.fertilizer=int(system.data.fertilizer)-1
			var remaining=maxi(0,int(plot.ready_at)-game.now())
			plot.ready_at=game.now()+maxi(1,ceili(remaining*(0.90 if action=="water" else 0.80)))
			ok=true
		if ok: system.farm.show_plot_feedback(index,"harvest" if action=="harvest" else "plant")
	elif job.get("target","")=="animal":
		var animal: Dictionary=system.animals.animal(str(job.animal))
		var species=str(animal.species)
		match action:
			"feed":
				if species=="ayam" and not game.ftue.is_empty():
					ok=game.feed_chickens()
					if not ok: message="Ayam memerlukan pakan olahan; buat pakan dari gandum di panel kandang."
				elif species=="ayam" and game.can_feed_chickens(): ok=game.feed_chickens()
				elif species=="sapi" and game.cow_is_hungry(): ok=game.feed_cow()
				elif species in ["babi","kambing"] and game.animal_hungry(species): ok=game.feed_animal(species)
				elif float(animal.hunger)<95 or species=="domba" and int(animal.get("wool_ready_at",0))==0:
					if int(game.inventory.get("gandum",0))>0:
						game.inventory.gandum=int(game.inventory.gandum)-1
						ok=true
				if ok:
					animal.hunger=100.0
					animal.state="eat"
					if species=="domba" and int(animal.get("wool_ready_at",0))==0: animal.wool_ready_at=game.now()+95
				else: message="Pakan belum cukup atau hewan belum lapar."
			"drink":
				if float(animal.thirst)<99:
					system.data.water=int(system.data.water)-1
					animal.thirst=100.0
					animal.state="drink"
					ok=true
			"clean":
				if float(animal.cleanliness)<99:
					animal.cleanliness=100.0
					system.data.fertilizer=int(system.data.fertilizer)+1
					ok=true
			"pet":
				animal.affection=minf(100,float(animal.get("affection",0))+10)
				animal.state="curious"
				ok=true
			"collect":
				match species:
					"ayam": ok=game.collect_eggs()
					"sapi": ok=game.collect_milk()
					"babi","kambing": ok=game.collect_animal(species)
					"domba":
						if int(animal.get("wool_ready_at",0))>0 and game.now()>=int(animal.wool_ready_at) and game.storage_used()+2<=game.storage_capacity:
							game.inventory["wol"]=int(game.inventory.get("wol",0))+2
							animal.wool_ready_at=0
							game.award_xp(12)
							ok=true
				if not ok: message="Hasil belum siap atau gudang penuh."
			"herd":
				ok=system.animals.herd(str(animal.id),int(job.zone))
				if not ok: message="Jalur menggiring tertutup. Buka gerbang zona asal dan tujuan."
	elif action=="orchard": ok=game.harvest_tree(int(job.index))>0
	elif action=="refill":
		system.data.water=100
		ok=true
	elif action=="chop":
		var index=int(job.get("index",-1))
		if index>=0 and index<system.farm.WILD_TREES.size():
			ok=game.clear_wild_tree(index)
			if ok:
				system.farm.invalidate_scenery()
				system.farm.show_world_feedback("chop_done",system.farm.wild_tree_position(index),"+6")
	elif action=="open":
		var key=str(job.get("key",""))
		var tabs={"dapur":"rumah","sapi":"sapi","ayam":"ayam","babi":"babi","kambing":"kambing","gudang":"gudang","pasar":"pasar","pakan":"pakan","roti":"roti","susu":"susu","ternak":"ternak","bangun":"bangun","misi":"misi","pesanan":"pesanan","pengunjung":"pengunjung","kebun_buah":"kebun_buah"}
		if tabs.has(key):
			system.host.switch_tab(tabs[key])
			ok=true
	else: ok=action=="move"
	if ok and action not in ["move","open"]: system.get_tree().call_group("garden_audio","play",action)
	return {"ok":ok,"message":message if ok else (message if message!=TITLES.get(action,action)+" selesai." else "Kondisi target berubah; pekerjaan dilewati.")}
