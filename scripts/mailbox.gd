extends RefCounted
## Persistent, local inbox. Future system campaigns can use deliver() with stable IDs.
static func prepare(game):
 if not game.mailbox is Dictionary: game.mailbox={}
 if not game.mailbox.get("messages",[]) is Array: game.mailbox.messages=[]
 if not game.mailbox.has("messages"): game.mailbox.messages=[]
 game.mailbox.version=1
static func find(game,id: String) -> Dictionary:
 prepare(game)
 for message in game.mailbox.messages:
  if message is Dictionary and str(message.get("id",""))==id: return message
 return {}
static func valid_rewards(game,rewards: Dictionary) -> bool:
 for key in rewards:
  if key in ["coins","xp","diamonds"]:
   if not rewards[key] is int or rewards[key]<0 or rewards[key]>1000000: return false
  elif key in ["seeds","inventory"]:
   if not rewards[key] is Dictionary: return false
   for item in rewards[key]:
    if not rewards[key][item] is int or rewards[key][item]<0 or rewards[key][item]>10000: return false
    if key=="seeds" and not game.CROPS.has(item): return false
    if key=="inventory" and not game.inventory.has(item): return false
  else: return false
 return true
static func deliver(game,id: String,title: String,body: String,rewards: Dictionary={},announcement: bool=false) -> bool:
 prepare(game)
 if id.is_empty() or not find(game,id).is_empty() or not valid_rewards(game,rewards): return false
 game.mailbox.messages.append({"id":id,"title":title,"body":body,"sender":"Sistem","date":Time.get_date_string_from_system(),"read":false,"claimed":false,"announcement":announcement,"rewards":rewards.duplicate(true)})
 return true
static func ensure(game) -> bool:
 prepare(game)
 var changed=false
 if deliver(game,"welcome_v1","Selamat Datang!","Selamat datang di Cheerful Garden! Pesan berisi surat sistem dan informasi kebun. Pesanan berisi permintaan pelanggan. Aktivitas membantu menemukan pekerjaan yang siap diselesaikan."): changed=true
 if deliver(game,"tips_v1","Tips Mengelola Kebun","Panen tanaman matang, siapkan bahan produksi, dan periksa pesanan pelanggan. Gunakan Aktivitas untuk melihat hasil yang sudah siap."): changed=true
 if deliver(game,"mail_guide_v1","Panduan Pesan","Kotak Masuk menyimpan surat. Hadiah menampilkan lampiran yang belum diambil. Pengumuman berisi informasi resmi di dalam game.",{},true): changed=true
 var today=Time.get_date_string_from_system()
 var id="daily_"+today
 if find(game,id).is_empty():
  var p=game.daily_checkin_preview()
  deliver(game,id,"Hadiah Login Harian","Terima kasih sudah bermain Cheerful Garden! Ini adalah hadiah kunjungan harianmu. Hadiah ini sama dengan bonus kunjungan di menu Misi.",{"coins":int(p.coins),"diamonds":int(p.diamonds)})
  find(game,id).daily_date=today;changed=true
 for message in game.mailbox.messages:
  if message is Dictionary and message.has("daily_date") and game.checkin_date==message.daily_date and not message.get("claimed",false):
   message.claimed=true;changed=true
 return changed
static func unread(game) -> int:
 prepare(game);var count=0
 for message in game.mailbox.messages:
  if message is Dictionary and not message.get("read",false): count+=1
 return count
static func claimable(game,message: Dictionary) -> bool:
 if message.is_empty() or message.get("claimed",false) or (message.get("rewards",{}) as Dictionary).is_empty(): return false
 if message.has("daily_date"): return message.daily_date==Time.get_date_string_from_system() and bool(game.daily_checkin_preview().available)
 return true
static func mark_read(game,id: String):
 var message=find(game,id)
 if not message.is_empty() and not message.get("read",false): message.read=true;game.save_game()
static func claim(game,id: String) -> bool:
 var message=find(game,id)
 if not claimable(game,message): return false
 var rewards: Dictionary=message.get("rewards",{})
 if not valid_rewards(game,rewards): return false
 if message.has("daily_date"):
  if game.claim_daily_checkin().is_empty(): return false
 else:
  var required=0
  for amount in rewards.get("inventory",{}).values(): required+=int(amount)
  if game.storage_used()+required>game.storage_capacity: return false
  message.claimed=true
  game.coins+=int(rewards.get("coins",0));game.diamonds+=int(rewards.get("diamonds",0))
  for key in rewards.get("seeds",{}): game.seeds[key]+=int(rewards.seeds[key])
  for key in rewards.get("inventory",{}): game.inventory[key]+=int(rewards.inventory[key])
  game.award_xp(int(rewards.get("xp",0)))
 message.claimed=true;message.read=true;game.save_game();return true
static func date_label(message) -> String:
 var today=Time.get_date_string_from_system();var date=str(message.get("date",today))
 if date==today: return "Hari ini"
 var days=int((Time.get_unix_time_from_datetime_string(today+"T00:00:00")-Time.get_unix_time_from_datetime_string(date+"T00:00:00"))/86400)
 return "Kemarin" if days==1 else ("%d hari lalu"%days if days>1 else date)
