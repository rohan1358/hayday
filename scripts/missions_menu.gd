extends RefCounted
const UI=preload("res://scripts/ranch_presentation.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
static func signature(game) -> String:
 return str([game.level,game.daily_date,game.daily_progress,game.daily_claimed,game.daily_specs,game.achievement_progress,game.achievement_claimed_tiers,game.checkin_date])
static func refresh(host):
 if signature(host.game)!=host.get_meta("missions_signature",""): host.show_sheet();return
 var clock=host.get_meta("mission_clock",null)
 if is_instance_valid(clock): clock.text=countdown()
static func countdown() -> String:
 var t=Time.get_time_dict_from_system();var seconds=86400-int(t.hour)*3600-int(t.minute)*60-int(t.second)
 return "Reset: %02d:%02d:%02d"%[seconds/3600,(seconds%3600)/60,seconds%60]
static func populate(host,list):
 var g=host.game;g.ensure_daily_tasks()
 var tab=str(host.get_meta("missions_tab","daily"))
 host.set_meta("mission_clock",null)
 var tabs=host.row_card(list,62,Color("fff5dc"))
 for i in 2:
  var key="daily" if i==0 else "achievements"
  var b=host.button(tabs,"Harian" if i==0 else "Prestasi",Vector2(6+i*298,3),Vector2(289,53),host.GREEN if key==tab else Color("f8e4b7"),Color.WHITE if key==tab else host.INK,25)
  b.name="MissionsDailyTab" if i==0 else "MissionsAchievementsTab";b.icon=ICON.texture("misi" if i==0 else "trophy");b.expand_icon=true;b.add_theme_constant_override("icon_max_width",38)
  b.pressed.connect(func(): host.set_meta("missions_tab",key);host.show_sheet())
 var intro=host.row_card(list,54,Color("fff7df"))
 host.label(intro,"Misi Harian · Level %d"%g.level if tab=="daily" else "Prestasi Kebun",Vector2(12,10),Vector2(340,34),21,host.GREEN,true)
 var clock=host.label(intro,countdown() if tab=="daily" else "Progres tetap tersimpan",Vector2(337,12),Vector2(251,31),17,host.INK)
 if tab=="daily": host.set_meta("mission_clock",clock)
 if tab=="daily":
  for id in g.daily_task_ids():
   var spec=g.daily_task_definition(id);var progress=int(g.daily_progress.get(id,0));var claimed=bool(g.daily_claimed.get(id,false))
   row(host,list,id,spec.name,spec.description,progress,int(spec.goal),spec,progress>=int(spec.goal) and not claimed,claimed,host.claim_mission.bind(id))
  var preview=g.daily_checkin_preview()
  var card=host.row_card(list,93,Color("eaf2d9"))
  host.label(card,"Kunjungan Harian · Hari %d"%int(preview.day),Vector2(14,7),Vector2(365,32),22,host.GREEN,true)
  host.label(card,"+%d koin%s"%[preview.coins," · +%d permata"%preview.diamonds if int(preview.diamonds)>0 else ""],Vector2(14,46),Vector2(350,28),18,host.INK)
  var claim=host.button(card,"Diambil" if preview.claimed_today else "Klaim",Vector2(425,22),Vector2(160,48),host.GREEN,Color.WHITE,20)
  claim.disabled=not preview.available;claim.pressed.connect(host.claim_checkin)
  host.callout(list,"SESUAI LEVELMU","Pesanan mulai Lv3, produksi mulai Lv5. Tugas yang sudah dikerjakan tetap sampai reset harian.",Color("fff0d0"))
 else:
  for id in g.ACHIEVEMENT_ORDER:
   var spec=g.ACHIEVEMENTS[id];var status=g.achievement_status(id)
   row(host,list,id,spec.name,spec.description,int(status.progress),int(status.goal),status,bool(status.ready),bool(status.completed),host.claim_achievement.bind(id))
 host.set_meta("missions_signature",signature(g))
static func row(host,list,id: String,title: String,description: String,progress: int,goal: int,reward: Dictionary,ready: bool,claimed: bool,callback: Callable):
 var card=host.row_card(list,142,Color("fff7df"));card.add_theme_stylebox_override("panel",UI.style(Color("fff8e5"),Color("e6d1a6"),22))
 var kind="panen" if "panen" in id else ("pesanan" if "pesanan" in id or "pengiriman" in id else ("produksi" if "produksi" in id else "toko"))
 ICON.add(card,kind,Vector2(9,34),Vector2(64,68))
 host.label(card,title,Vector2(85,9),Vector2(286,32),23,host.INK,true)
 var detail=host.label(card,description,Vector2(85,46),Vector2(287,44),17,host.SOFT_INK);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var bar=ProgressBar.new();bar.position=Vector2(86,105);bar.size=Vector2(208,18);bar.max_value=maxi(1,goal);bar.value=mini(progress,goal);bar.show_percentage=false
 bar.add_theme_stylebox_override("background",UI.style(Color("d7e3bd"),Color("edf4d8"),9));bar.add_theme_stylebox_override("fill",UI.style(Color("20a346"),Color("9bce67"),9));card.add_child(bar)
 host.label(card,"%d/%d"%[mini(progress,goal),goal],Vector2(299,99),Vector2(77,29),18,host.GREEN,true)
 host.label(card,"+%d Koin"%int(reward.coins),Vector2(387,18),Vector2(194,28),19,host.INK,true)
 host.label(card,"+%d XP%s"%[reward.xp," · +%d ◆"%reward.diamonds if int(reward.diamonds)>0 else ""],Vector2(387,51),Vector2(197,30),17,host.INK,true)
 var claim=host.button(card,"Diambil" if claimed else ("Klaim" if ready else "Belum Siap"),Vector2(389,90),Vector2(193,40),host.GREEN if ready else Color("9eb17b"),Color.WHITE,18)
 claim.name="MissionClaim_"+id;claim.disabled=not ready;claim.pressed.connect(callback)
