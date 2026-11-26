extends RefCounted
const J=preload("res://scripts/level_journey.gd")
const FLOW=preload("res://scripts/first_farm.gd")
const ART=preload("res://scripts/ranch_presentation.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
static func signature(game) -> String:
 return str([game.level,game.achievement_progress,game.ftue.get("step",""),game.ftue.get("planted",[]),game.ftue.get("harvested",[]),game.ftue.get("sale_done",false),game.ftue.get("reward_claimed",false),game.level_journey.get("entries",{})])
static func has_ready(game) -> bool:
 if FLOW.active(game): return game.ftue.get("step","")=="reward"
 J.prepare(game)
 for key in game.level_journey.entries:
  if int(key)<=game.level and J.status(game,int(key)).ready: return true
 return false
static func refresh(host):
 if signature(host.game)!=str(host.get_meta("reward_signature","")): host.show_sheet()
static func populate(host,list):
 var game=host.game;var first=FLOW.active(game)
 J.prepare(game)
 if int(host.get_meta("reward_seen_level",-1))!=game.level:
  host.set_meta("reward_seen_level",game.level);host.set_meta("reward_selected",game.level)
 var level=int(host.get_meta("reward_selected",game.level))
 var info={};var rows=[]
 if first:
  rows=[{"name":"Tanam 3 petak gandum","progress":game.ftue.get("planted",[]).size(),"goal":3,"icon":"bibit"},{"name":"Panen 3 petak gandum","progress":game.ftue.get("harvested",[]).size(),"goal":3,"icon":"panen"},{"name":"Jual hasil panen pertama","progress":3 if game.ftue.get("sale_done",false) else 0,"goal":3,"icon":"toko"}]
  info={"ready":game.ftue.get("step","")=="reward","claimed":bool(game.ftue.get("reward_claimed",false)),"reward":{"coins":50,"xp":30}}
 else:
  var levels=[]
  for key in game.level_journey.entries:
   if int(key)>=1 and int(key)<=game.level: levels.append(int(key))
  levels.sort();levels.reverse()
  if level not in levels: level=game.level;host.set_meta("reward_selected",level)
  var picker=OptionButton.new();picker.name="RewardLevelPicker";picker.custom_minimum_size.y=46
  for state in ["normal","hover","pressed"]: picker.add_theme_stylebox_override(state,ART.style(Color("fff1cd"),Color("d9b779"),16))
  picker.add_theme_color_override("font_color",host.INK);picker.add_theme_color_override("font_hover_color",host.INK)
  picker.add_theme_font_size_override("font_size",20);list.add_child(picker)
  for number in levels: picker.add_item("Hadiah Level %d%s"%[number," · Diambil" if J.status(game,number).claimed else ""],number)
  picker.select(picker.get_item_index(level))
  picker.item_selected.connect(func(index): host.set_meta("reward_selected",picker.get_item_id(index));host.show_sheet())
  info=J.status(game,level);rows=info.rows
 var banner=host.row_card(list,150,Color("d5edbd"));banner.clip_contents=true
 var background=TextureRect.new();background.texture=load("res://assets/cheerful/countryside.png");background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 background.size=Vector2(601,150);background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;background.mouse_filter=Control.MOUSE_FILTER_IGNORE;banner.add_child(background)
 ICON.add(banner,"app_icon",Vector2(5,10),Vector2(125,125))
 var bubble=Panel.new();bubble.position=Vector2(137,14);bubble.size=Vector2(315,122);bubble.add_theme_stylebox_override("panel",ART.style(Color("fff9dd"),Color("fffdf0"),27));banner.add_child(bubble)
 host.label(bubble,"Hadiah Pertama" if first else "Hadiah Level %d"%level,Vector2(14,12),Vector2(285,35),25,host.GREEN,true)
 var text="Tuntaskan tugas pertama berkebun dan ambil hadiahnya!" if first else "Selesaikan tugas level ini untuk mendapatkan hadiah."
 var hint=host.label(bubble,text,Vector2(14,54),Vector2(285,61),19,host.INK);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var wheat=ICON.add(banner,"bibit",Vector2(466,22),Vector2(119,110));wheat.texture=host.seed_icon_texture("gandum")
 for row in rows:
  var card=host.row_card(list,91,Color("fff8e4"));card.add_theme_stylebox_override("panel",ART.style(Color("fff8e4"),Color("ebd2a3"),22))
  ICON.add(card,str(row.icon),Vector2(10,13),Vector2(59,59))
  host.label(card,str(row.name),Vector2(83,8),Vector2(446,34),23,host.INK,true)
  var bar=ProgressBar.new();bar.name="RewardProgress_"+str(row.get("counter",row.name));bar.position=Vector2(83,49);bar.size=Vector2(445,26)
  bar.max_value=int(row.goal);bar.value=int(row.progress);bar.show_percentage=false
  bar.add_theme_stylebox_override("background",ART.style(Color("dfdfb1"),Color("fffce5"),13));bar.add_theme_stylebox_override("fill",ART.style(Color("25ad35"),Color("98db5f"),13));card.add_child(bar)
  var count=host.label(card,"%d / %d"%[row.progress,row.goal],Vector2(83,46),Vector2(445,32),19,host.GREEN,true);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  count.add_theme_color_override("font_outline_color",Color("fffbe8"));count.add_theme_constant_override("outline_size",2)
  host.label(card,"✓" if int(row.progress)>=int(row.goal) else "○",Vector2(542,23),Vector2(44,49),31,host.GREEN,true)
 var rewards=host.row_card(list,154,Color("fff0c9"));rewards.name="LevelRewardSummary"
 host.label(rewards,"Hadiah" if first else "Hadiah Level %d"%level,Vector2(16,4),Vector2(570,35),27,host.GREEN,true).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var values=[["koin",str(info.reward.coins),"Koin"],["trophy",str(info.reward.xp),"XP"]]
 if first: values.append(["bibit","3","Bibit Gandum"])
 var cell=570.0/values.size()
 for i in values.size():
  var x=16+i*cell
  ICON.add(rewards,values[i][0],Vector2(x+cell/2-25,42),Vector2(50,50))
  host.label(rewards,values[i][1],Vector2(x,94),Vector2(cell,28),24,host.INK,true).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  host.label(rewards,values[i][2],Vector2(x,123),Vector2(cell,25),18,host.INK).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if first: host.callout(list,"HADIAH PENJUALAN","50 koin dan 30 XP diberikan saat penjualan pertama. Ambil hadiah untuk menerima 3 bibit gandum.",Color("eaf2d4"))
 var claim=host.button(list,"SUDAH DIAMBIL" if info.claimed else "AMBIL HADIAH",Vector2.ZERO,Vector2(601,58),host.GREEN,Color.WHITE,25)
 claim.name="ClaimLevelReward";claim.disabled=not bool(info.ready)
 claim.icon=ICON.texture("hadiah");claim.expand_icon=true;claim.add_theme_constant_override("icon_max_width",32)
 claim.pressed.connect(func():
  var ok=FLOW.claim(game) if first else J.claim(game,level)
  if ok:
   host.show_toast("Hadiah diterima!" if first else "Hadiah Level %d diterima!"%level)
   host.refresh_all()
  else: host.show_toast("Tugas belum selesai atau hadiah sudah diambil.");host.show_sheet())
 if not first: host.label(list,"Hadiah level sebelumnya tetap tersedia melalui pilihan level.",Vector2.ZERO,Vector2(590,42),17,host.SOFT_INK).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var back=host.button(list,"KEMBALI KE KEBUN",Vector2.ZERO,Vector2(601,51),Color("f7e6be"),host.INK,21);back.pressed.connect(func(): host.switch_tab("kebun"))
 host.set_meta("reward_signature",signature(game))
