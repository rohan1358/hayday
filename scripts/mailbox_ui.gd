extends RefCounted
const MAIL=preload("res://scripts/mailbox.gd")
const UI=preload("res://scripts/ranch_presentation.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
static func populate(host,list):
 if MAIL.ensure(host.game): host.game.save_game()
 host.set_meta("mail_signature",str(host.game.mailbox))
 var tab=str(host.get_meta("mail_tab","inbox"));var messages=[]
 var all=host.game.mailbox.messages.duplicate();all.reverse()
 for message in all:
  if not message is Dictionary: continue
  if tab=="rewards" and not MAIL.claimable(host.game,message): continue
  if tab=="announcements" and not message.get("announcement",false): continue
  messages.append(message)
 var tabs=host.row_card(list,62,Color("fff4d5"))
 for i in 3:
  var key=["inbox","rewards","announcements"][i]
  var b=host.button(tabs,["Kotak Masuk","Hadiah","Pengumuman"][i],Vector2(3+i*200,4),Vector2(193,52),host.GREEN if tab==key else Color("f7e5bc"),Color.WHITE if tab==key else host.INK,19)
  b.name="MailTab_"+key;b.icon=ICON.texture(["surat","hadiah","notifikasi"][i]);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",27)
  b.pressed.connect(func(): host.set_meta("mail_tab",key);host.set_meta("mail_selected","");host.show_sheet())
 if messages.is_empty(): host.callout(list,"BELUM ADA PESAN","Belum ada pesan untuk kategori ini.",Color("fff4da"));return
 var selected=str(host.get_meta("mail_selected",""))
 if selected.is_empty() or not messages.any(func(m): return m.id==selected): selected=str(messages[0].id);host.set_meta("mail_selected",selected)
 var columns=HBoxContainer.new();columns.add_theme_constant_override("separation",12);list.add_child(columns)
 var cards=VBoxContainer.new();cards.custom_minimum_size.x=237;cards.add_theme_constant_override("separation",12);columns.add_child(cards)
 var detail=VBoxContainer.new();detail.custom_minimum_size.x=350;detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation",12);columns.add_child(detail)
 for message in messages:
  var row=host.panel(cards,Vector2.ZERO,Vector2(237,120),Color("eaf4cf") if message.id==selected else Color("fff6df"),21,3)
  ICON.add(row,"hadiah" if not (message.get("rewards",{}) as Dictionary).is_empty() else ("notifikasi" if message.get("announcement",false) else "surat"),Vector2(9,18),Vector2(44,46))
  var title=host.label(row,str(message.title),Vector2(61,9),Vector2(165,48),19,host.INK,true);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  host.label(row,"Dari "+str(message.get("sender","Sistem")),Vector2(61,60),Vector2(165,23),15,host.SOFT_INK)
  host.label(row,MAIL.date_label(message),Vector2(61,86),Vector2(145,25),16,host.SOFT_INK)
  host.label(row,"✓" if message.get("read",false) else "●",Vector2(209,94),Vector2(20,21),18,host.GREEN if message.get("read",false) else Color("d64732"),true)
  var open=Button.new();open.name="OpenMail_"+str(message.id);open.flat=true;row.add_child(open);open.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  open.pressed.connect(func(): MAIL.mark_read(host.game,message.id);host.set_meta("mail_selected",message.id);host.show_sheet())
 var message=MAIL.find(host.game,selected)
 var body=host.panel(detail,Vector2.ZERO,Vector2(350,590),Color("fff8e5"),24,3)
 ICON.add(body,"hadiah" if not (message.rewards as Dictionary).is_empty() else "surat",Vector2(111,9),Vector2(112,96))
 host.label(body,str(message.title),Vector2(15,113),Vector2(318,68),25,host.INK,true).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 host.label(body,"Dari "+str(message.get("sender","Sistem"))+" · "+MAIL.date_label(message),Vector2(15,183),Vector2(318,46),17,host.SOFT_INK).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 host.label(body,str(message.body),Vector2(15,236),Vector2(318,195),18,host.INK).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var rewards=[]
 for key in ["coins","xp","diamonds"]:
  if int(message.rewards.get(key,0))>0: rewards.append([{"coins":"koin","xp":"misi","diamonds":"permata"}[key],{"coins":"Koin","xp":"XP","diamonds":"Permata"}[key],int(message.rewards[key])])
 for key in message.rewards.get("seeds",{}): rewards.append(["bibit",host.game.CROPS[key].name,int(message.rewards.seeds[key])])
 for key in message.rewards.get("inventory",{}): rewards.append(["gudang",str(key).replace("_"," ").capitalize(),int(message.rewards.inventory[key])])
 var reward_rows=ceili(rewards.size()/3.0)
 body.custom_minimum_size.y=590+maxi(0,reward_rows-1)*88
 for i in rewards.size():
  var reward=rewards[i];var tile=host.panel(body,Vector2(15+(i%3)*107,434+(i/3)*88),Vector2(101,82),Color("fff0c9"),15,2)
  ICON.add(tile,reward[0],Vector2(34,4),Vector2(32,32))
  host.label(tile,str(reward[2])+" "+reward[1],Vector2(4,39),Vector2(93,39),17,host.INK,true).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var b=host.button(body,"Sudah Diklaim" if message.get("claimed",false) else "Klaim Hadiah",Vector2(15,522+maxi(0,reward_rows-1)*88),Vector2(318,50),host.GREEN,Color.WHITE,20)
 b.name="ClaimMailReward";b.disabled=not MAIL.claimable(host.game,message)
 if (message.rewards as Dictionary).is_empty(): b.hide()
 b.pressed.connect(func():
  if MAIL.claim(host.game,message.id): host.show_toast("Hadiah pesan diterima!")
  else: host.show_toast("Hadiah sudah diambil, kedaluwarsa, atau gudang penuh.")
  host.refresh_all())
 host.set_meta("mail_signature",str(host.game.mailbox))
static func refresh(host):
 if MAIL.ensure(host.game): host.game.save_game()
 if str(host.game.mailbox)!=host.get_meta("mail_signature",""): host.show_sheet()
