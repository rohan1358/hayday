extends Control
const FLOW=preload("res://scripts/first_farm.gd")
var host
var gift: Button
var mission: Button
var last_signature=""
var gift_clock=0.4
var farm_shortcuts: Array[Button]=[]
static func icon(parent,id: String,at: Vector2,dimensions: Vector2) -> TextureRect:
 return preload("res://scripts/colorful_icons.gd").add(parent,id,at,dimensions)
static func skin(button: Button,gold: bool=false) -> void:
 if button.has_meta("cheerful_skin") and bool(button.get_meta("cheerful_skin"))==gold: return
 button.set_meta("cheerful_skin",gold)
 button.set_meta("colorful_applied",true)
 for state in ["normal","hover","pressed","disabled"]:
  var style=StyleBoxFlat.new()
  style.bg_color=Color("ffc447") if gold else Color("fff3ce")
  if state=="hover": style.bg_color=style.bg_color.lightened(0.08)
  if state=="pressed": style.bg_color=style.bg_color.darkened(0.07)
  if state=="disabled": style.bg_color=Color("ded9be")
  style.border_color=Color("fffbdc");style.set_border_width_all(3);style.set_corner_radius_all(22)
  style.shadow_color=Color("70532566");style.shadow_size=3;style.shadow_offset=Vector2(0,3)
  button.add_theme_stylebox_override(state,style)
 button.add_theme_color_override("font_color",Color("4c3b22"))
 button.add_theme_color_override("font_hover_color",Color("4c3b22"))
static func header(ui) -> void:
 var header=Control.new();header.name="CheerfulHeader";header.size=Vector2(720,140)
 header.mouse_filter=Control.MOUSE_FILTER_IGNORE;header.z_index=45;ui.add_child(header)
 header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);header.offset_bottom=140
 var logo=TextureRect.new();logo.name="CheerfulLogo";logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 logo.texture=load("res://assets/cheerful/logo.png");logo.position=Vector2(8,8);logo.size=Vector2(224,116)
 logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;logo.mouse_filter=Control.MOUSE_FILTER_IGNORE;header.add_child(logo)
 var profile=ui.panel(header,Vector2(238,12),Vector2(212,75),Color("fff3ce"),30,3)
 var portrait=TextureRect.new();portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.texture=load("res://assets/cheerful/app_icon.png");portrait.position=Vector2(4,5);portrait.size=Vector2(62,62)
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;profile.add_child(portrait)
 var level=ui.panel(profile,Vector2(72,5),Vector2(76,30),Color("3aab58"),12,1)
 ui.top_level_text=ui.label(level,"LV 1",Vector2(3,2),Vector2(70,27),19,Color.WHITE,true)
 ui.top_xp_text=ui.label(profile,"0 / 100 XP",Vector2(76,37),Vector2(128,22),14,Color("594526"),true)
 ui.xp_track=ProgressBar.new();ui.xp_track.position=Vector2(74,61);ui.xp_track.size=Vector2(127,8)
 ui.xp_track.show_percentage=false;ui.xp_track.add_theme_stylebox_override("background",ui.style(Color("d9cf9a"),5))
 ui.xp_track.add_theme_stylebox_override("fill",ui.style(Color("72c751"),5));profile.add_child(ui.xp_track)
 ui.xp_track.size=Vector2(127,8)
 var coins=ui.panel(header,Vector2(460,12),Vector2(142,56),Color("fff3ce"),25,3)
 icon(coins,"koin",Vector2(3,5),Vector2(42,42))
 ui.top_coins_text=ui.label(coins,"100",Vector2(43,12),Vector2(70,32),22,Color("49391e"),true)
 var coin_plus=ui.button(coins,"+",Vector2(108,10),Vector2(28,32),Color("38aa56"),Color.WHITE,23)
 coin_plus.pressed.connect(func(): ui.switch_tab("toko"))
 var gems=ui.panel(header,Vector2(609,12),Vector2(103,56),Color("fff3ce"),25,3)
 icon(gems,"permata",Vector2(2,7),Vector2(35,35))
 ui.top_gems_text=ui.label(gems,"10",Vector2(36,12),Vector2(42,30),21,Color("49391e"),true)
 var gem_plus=ui.button(gems,"+",Vector2(73,10),Vector2(25,32),Color("38aa56"),Color.WHITE,22)
 gem_plus.pressed.connect(func(): ui.switch_tab("toko"))
 for i in 3:
  var id=["surat","notifikasi","pengaturan"][i]
  var tab=["pesan","aktivitas","pengaturan"][i]
  var b=ui.button(header,"",Vector2(552+i*54,80),Vector2(48,49),Color("fff3ce"),Color("49391e"),18)
  b.name="Cheerful_"+id;skin(b);icon(b,id,Vector2(7,7),Vector2(34,34))
  b.tooltip_text=["Pesan","Aktivitas Kebun","Pengaturan"][i]
  b.pressed.connect(ui.switch_tab.bind(tab))
 # Existing refresh code retains a valid mission button; the visible mission
 # card below owns the same action without duplicating rewards or progress.
 ui.mission_header_button=ui.button(header,"",Vector2.ZERO,Vector2.ONE,Color("fff3ce"),Color("49391e"),16)
 ui.mission_header_button.hide()
func _ready() -> void:
 host=get_parent();name="CheerfulPresentation"
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=60
 gift=task_button("hadiah","Hadiah",Vector2(16,148))
 gift.name="BeginnerGiftTask";gift.pressed.connect(func(): host.switch_tab("hadiah_pemula"))
 mission=task_button("pesanan","Misi\n0/3",Vector2(116,148))
 mission.name="MissionTask";mission.pressed.connect(func(): host.switch_tab("hadiah_pemula" if FLOW.active(host.game) else "misi"))
 for spec in [["ternak","Ternak"],["pasar","Pasar"]]:
  var shortcut=Button.new()
  shortcut.name="FarmShortcut_"+spec[0]
  shortcut.text=spec[1]
  shortcut.position=Vector2(226+farm_shortcuts.size()*132,148)
  shortcut.size=Vector2(122,64)
  shortcut.add_theme_font_size_override("font_size",20)
  skin(shortcut)
  shortcut.pressed.connect(host.switch_tab.bind(spec[0]))
  add_child(shortcut)
  farm_shortcuts.append(shortcut)
func task_button(id: String,text: String,at: Vector2) -> Button:
 var b=Button.new();b.position=at;b.size=Vector2(88,90);skin(b)
 b.add_theme_font_size_override("font_size",16);add_child(b)
 icon(b,id,Vector2(25,5),Vector2(38,38))
 var caption=Label.new();caption.name="Caption";caption.text=text;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.position=Vector2(4,44);caption.size=Vector2(80,42);caption.add_theme_font_size_override("font_size",18);caption.set_meta("typography_role","heading")
 caption.add_theme_color_override("font_color",Color("49391e"));caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(caption)
 var dot=Panel.new();dot.name="NotificationDot";dot.position=Vector2(68,-3);dot.size=Vector2(20,20)
 var red=StyleBoxFlat.new();red.bg_color=Color("ed4b42");red.border_color=Color("fff8df");red.set_border_width_all(2);red.set_corner_radius_all(10)
 dot.add_theme_stylebox_override("panel",red);dot.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(dot)
 return b
func _process(_delta: float) -> void:
 if not is_instance_valid(host.farm): return
 var in_farm=host.active_tab=="kebun"
 var opening=not host.game.ftue.is_empty() and not bool(host.game.ftue.get("started",true))
 var picker_open=host.farm.hybrid_controller!=null and host.farm.hybrid_controller.ui.menu.visible
 var show_tasks=in_farm and not picker_open and not host.farm.edit_mode and not opening and not host.get_meta("first_farm_modal",false)
 gift.visible=show_tasks;mission.visible=show_tasks
 for shortcut in farm_shortcuts: shortcut.visible=show_tasks and not FLOW.active(host.game)
 gift_clock+=_delta
 if gift_clock>=0.4:
  gift_clock=0
  gift.get_node("NotificationDot").visible=preload("res://scripts/reward_menu.gd").has_ready(host.game)
 var count=host.game.ftue.get("harvested",[]).size() if host.game.ftue.get("step","") in ["harvest","sale","reward"] else host.game.ftue.get("planted",[]).size()
 mission.get_node("Caption").text="Misi\n%d/%d" % [count if FLOW.active(host.game) else host.game.daily_claimed_count(),3 if FLOW.active(host.game) else maxi(1,host.game.daily_task_ids().size())]
 mission.get_node("NotificationDot").visible=FLOW.active(host.game) or host.game.claimable_rewards_count()>0
 host.mission_header_button.hide();host.activity_shortcut.hide();host.visitor_shortcut.hide()
 host.arrange_button.visible=in_farm and host.game.feature_unlocked("decorations") and not opening
 host.arrange_button.position=Vector2(532,140 if not host.farm.edit_mode else 158)
 for tile in host.navbar.get_children():
  if tile.has_meta("tab_id"): tile.visible=true
 var mail_button=host.find_child("Cheerful_surat",true,false)
 if mail_button!=null:
  var badge=mail_button.get_node_or_null("UnreadMailBadge")
  if badge==null:
   badge=Panel.new();badge.name="UnreadMailBadge";badge.position=Vector2(30,-5);badge.size=Vector2(26,24);badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
   badge.add_theme_stylebox_override("panel",host.style(Color("e74633"),12));mail_button.add_child(badge)
   var number=host.label(badge,"",Vector2.ZERO,Vector2(26,24),16,Color.WHITE,true);number.name="Count";number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var unread=preload("res://scripts/mailbox.gd").unread(host.game)
  badge.visible=unread>0;badge.get_node("Count").text=str(mini(99,unread))
 var guide=get_guide()
 if guide!=null:
  guide.poultry.hide();guide.skip.hide()
  guide.card.visible=FLOW.active(host.game) and show_tasks
  if guide.card.visible:
   guide.card.anchor_left=0;guide.card.anchor_right=0;guide.card.anchor_top=0;guide.card.anchor_bottom=0
   guide.card.offset_left=116;guide.card.offset_right=host.size.x-116
   var guide_height=maxf(112,guide.card.get_combined_minimum_size().y)
   guide.card.offset_top=maxf(248,host.navbar.position.y-guide_height-20)
   guide.card.offset_bottom=guide.card.offset_top+guide_height
   guide.title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   guide.title.add_theme_font_size_override("font_size",19)
   guide.hint.add_theme_font_size_override("font_size",16)
   guide.claim.add_theme_font_size_override("font_size",14);guide.visitor.add_theme_font_size_override("font_size",14)
   var step=str(host.game.ftue.step)
   var hints={"welcome":["Ayo tanam Gandum!","Selamat datang di Cheerful Garden! Ketuk petak bercahaya."],"plant":["Tanam %d/3 Gandum" % count,"Pilih bibit Gandum, lalu tekan Tanam."],"grow":["Gandum mulai tumbuh","Tunggu sampai muncul tanda SIAP!"],"harvest":["Panen %d/3 petak" % count,"Ketuk gandum matang. Petani akan menghampirinya."],"sale":["Pesanan pertama","Jual 3 gandum ke Bu Sari. Hadiah 50 koin dan 30 XP."],"reward":["Naik Level 2!","Lanjutkan dan ambil bibit gandum berikutnya."]}
   if hints.has(step): guide.title.text=hints[step][0];guide.hint.text=hints[step][1]
func get_guide():
 for node in host.get_children():
  if node.get_script()==load("res://scripts/first_farm_ui.gd"): return node
 return null
