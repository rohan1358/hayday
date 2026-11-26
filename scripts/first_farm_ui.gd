extends Control
const FLOW=preload("res://scripts/first_farm.gd")
var host
var card: PanelContainer
var title: Label
var hint: Label
var progress: ProgressBar
var claim: Button
var skip: Button
var signature=""
var last_step=""
var elapsed=0.0
var compact_at_start=false
var celebration: PanelContainer
var opening: PanelContainer
var poultry: Button
var level_modal: Control
var visitor: Button
func _ready() -> void:
 host=get_parent()
 if not FLOW.enabled(host.game): queue_free();return
 compact_at_start=FLOW.compact(host.game)
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 z_index=55
 card=PanelContainer.new()
 card.name="FirstMissionCard"
 card.mouse_filter=Control.MOUSE_FILTER_IGNORE
 card.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 card.offset_left=16;card.offset_right=-16;card.offset_top=157
 var paper=StyleBoxFlat.new()
 paper.bg_color=Color("fff8df")
 paper.border_color=Color("f5cb74")
 paper.set_border_width_all(2);paper.set_corner_radius_all(18)
 paper.content_margin_left=18;paper.content_margin_right=18
 paper.content_margin_top=12;paper.content_margin_bottom=12
 card.add_theme_stylebox_override("panel",paper)
 add_child(card)
 var stack=VBoxContainer.new()
 stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stack.add_theme_constant_override("separation",7)
 card.add_child(stack)
 title=Label.new();title.add_theme_font_size_override("font_size",21)
 title.add_theme_color_override("font_color",Color("28714d"))
 stack.add_child(title)
 hint=Label.new();hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 hint.add_theme_font_size_override("font_size",18)
 hint.add_theme_color_override("font_color",Color("62442f"))
 hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stack.add_child(hint)
 progress=ProgressBar.new();progress.custom_minimum_size.y=16
 progress.max_value=3;progress.show_percentage=false
 stack.add_child(progress)
 var row=HBoxContainer.new();stack.add_child(row)
 claim=Button.new();claim.name="ClaimFirstMission";claim.text="NAIK LEVEL! · LANJUTKAN"
 claim.custom_minimum_size.y=48;claim.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 claim.pressed.connect(claim_reward);row.add_child(claim)
 skip=Button.new();skip.text="LEWATI";skip.custom_minimum_size=Vector2(112,46)
 skip.pressed.connect(func(): FLOW.skip(host.game);host.refresh_all();refresh())
 skin(skip,false)
 skin(claim,true)
 row.add_child(skip)
 visitor=Button.new();visitor.name="FirstSaleShortcut";visitor.text="TAMU · JUAL 3 GANDUM"
 visitor.custom_minimum_size.y=48;visitor.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 skin(visitor,true)
 visitor.pressed.connect(func(): host.switch_tab("pengunjung"))
 row.add_child(visitor)
 poultry=Button.new();poultry.name="PoultryMission";poultry.text="KANDANG AYAM · TERBUKA LEVEL 3"
 poultry.custom_minimum_size.y=48
 poultry.pressed.connect(func(): host.switch_tab("ayam"))
 skin(poultry,true)
 stack.add_child(poultry)
 if not bool(host.game.ftue.get("started",true)): build_opening()
 refresh()
func _process(delta: float) -> void:
 elapsed+=delta
 if elapsed<0.2: return
 elapsed=0
 FLOW.tick(host.game)
 refresh()
func refresh() -> void:
 if not is_instance_valid(host.farm): return
 host.tutorial_panel.hide()
 var active=FLOW.active(host.game)
 var in_farm=host.active_tab=="kebun"
 var started=bool(host.game.ftue.get("started",true))
 card.visible=started and in_farm and not host.farm.edit_mode and (active or host.game.level<4)
 card.offset_top=157 if active else 222
 visitor.visible=active and host.game.ftue.step=="sale"
 host.arrange_button.visible=in_farm and host.game.feature_unlocked("decorations")
 host.visitor_shortcut.visible=in_farm and not active and not host.farm.edit_mode
 host.activity_shortcut.visible=in_farm and host.game.feature_unlocked("orders")
 host.mission_header_button.visible=not active
 for tile in host.navbar.get_children():
  if tile.has_meta("tab_id"): tile.visible=FLOW.tab(host.game,str(tile.get_meta("tab_id")))
 if compact_at_start and not FLOW.compact(host.game) and get_tree().current_scene==host:
  host.game.save_game()
  get_tree().call_deferred("reload_current_scene")
  compact_at_start=false
 poultry.visible=not active and host.game.level>=2
 if not active:
  host.farm.guide_plot_index=-1
  title.text="Proyek Berikutnya · Peternakan Ayam"
  hint.text="Gandum bukan hanya untuk dijual, lho! Nanti kita juga bisa mengolahnya menjadi pakan ayam."
  poultry.text="BANGUN KANDANG AYAM · LEVEL 3" if host.game.level>=3 else "LIHAT KANDANG · TERBUKA LEVEL 3"
  if preload("res://scripts/first_coop.gd").built(host.game): poultry.text="RAWAT AYAM · PAKAN & TELUR"
  progress.hide();claim.hide();skip.hide()
  return
 var step=str(host.game.ftue.step)
 var sig=str(host.game.ftue)+str(host.game.inventory)
 if sig==signature: return
 signature=sig
 var info=FLOW.STEPS[step]
 var count=host.game.ftue.harvested.size() if step in ["grow","harvest","sale","reward"] else host.game.ftue.planted.size()
 title.text=str(info[0])+ (" · %d/3" % count if step in ["plant","harvest"] else "")
 hint.text=str(info[1])
 progress.value=count
 progress.visible=step in ["plant","grow","harvest"]
 claim.visible=step=="reward"
 skip.visible=step!="reward"
 host.farm.guide_plot_index=FLOW.target(host.game)
 host.farm.guide_plot_action="harvest" if step in ["grow","harvest"] else "plant"
 if last_step!=step:
  if host.farm.hybrid_controller!=null: host.farm.hybrid_controller.data.follow=false
  host.farm.camera_target=preload("res://scripts/cheerful_layout.gd").CAMERA
  host.farm.zoom_target=preload("res://scripts/cheerful_layout.gd").ZOOM
  last_step=step
 host.farm.queue_redraw()
func claim_reward() -> void:
 if not FLOW.claim(host.game): return
 host.refresh_all()
 host.farm.show_world_feedback("harvest",host.farm.ujang_position,"LEVEL 2! +3 BIBIT GANDUM")
 host.show_toast("Naik level! +3 bibit gandum. Siapkan kandang ayam untuk Level 3.")
 refresh()
func build_opening() -> void:
 opening=PanelContainer.new();opening.name="NewPlayerWelcome"
 opening.set_meta("colorful_applied",true)
 opening.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var sky=StyleBoxFlat.new();sky.bg_color=Color("d8f5e8f8")
 sky.content_margin_left=28;sky.content_margin_right=28;sky.content_margin_top=30;sky.content_margin_bottom=30
 opening.add_theme_stylebox_override("panel",sky)
 add_child(opening)
 var cover_path="res://assets/onboarding/welcome.png"
 var has_cover=ResourceLoader.exists(cover_path)
 if has_cover:
  var background=TextureRect.new();background.texture=load(cover_path)
  background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  background.mouse_filter=Control.MOUSE_FILTER_IGNORE
  opening.add_child(background)
 var stack=VBoxContainer.new();stack.alignment=BoxContainer.ALIGNMENT_CENTER
 stack.add_theme_constant_override("separation",18);opening.add_child(stack)
 if has_cover: stack.alignment=BoxContainer.ALIGNMENT_BEGIN
 var logo=TextureRect.new();logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 logo.texture=load("res://assets/cheerful/logo.png")
 logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 logo.custom_minimum_size=Vector2(0,minf(210,size.y*0.20))
 stack.add_child(logo)
 var pair=HBoxContainer.new();pair.alignment=BoxContainer.ALIGNMENT_CENTER
 stack.add_child(pair)
 if has_cover:
  pair.size_flags_vertical=Control.SIZE_EXPAND_FILL
 for gender in ([] if has_cover else ["male","female"]):
  var actor=TextureRect.new();actor.texture=preload("res://scripts/wardrobe_assets.gd").character({"gender":gender,"outfit":0})
  actor.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;actor.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  actor.custom_minimum_size=Vector2(minf(240,size.x*0.37),minf(340,size.y*0.31))
  pair.add_child(actor)
 var tagline=Label.new();tagline.text="Berkebun • Beternak • Membangun Kebun yang Hidup"
 tagline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;tagline.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 tagline.add_theme_font_size_override("font_size",22);tagline.add_theme_color_override("font_color",Color("fff7dc") if has_cover else Color("35664a"));stack.add_child(tagline)
 var play=Button.new();play.name="StartAdventure";play.text="Mulai Petualangan";play.custom_minimum_size.y=64
 play.add_theme_font_size_override("font_size",27)
 skin(play,true)
 play.pressed.connect(start_adventure);stack.add_child(play)
func start_adventure() -> void:
 var layout=preload("res://scripts/cheerful_layout.gd")
 host.farm.camera_center=layout.CAMERA
 host.farm.camera_target=layout.CAMERA
 host.farm.camera_zoom=layout.ZOOM
 host.farm.zoom_target=layout.ZOOM
 host.farm.invalidate_scenery()
 host.farm.ujang_position=host.farm.plot_center(0)+Vector2(-160,-140)
 if host.farm.hybrid_controller!=null:
  host.farm.hybrid_controller.rescue_player()
  host.farm.hybrid_controller.data.follow=false
 host.game.ftue.started=true
 host.game.save_game()
 if is_instance_valid(opening): opening.queue_free()
 signature=""
 refresh()
static func skin(button: Button,primary: bool) -> void:
 button.set_meta("colorful_applied",true)
 for state in ["normal","hover","pressed","disabled"]:
  var style=StyleBoxFlat.new()
  style.bg_color=Color("2d9c56") if primary else Color("e8edd6")
  if state=="hover": style.bg_color=style.bg_color.lightened(0.1)
  if state=="pressed": style.bg_color=style.bg_color.darkened(0.12)
  if state=="disabled": style.bg_color=Color("d0dac3")
  style.border_color=Color("196e42") if primary else Color("bad0a8")
  style.set_border_width_all(2);style.set_corner_radius_all(15)
  style.content_margin_left=16;style.content_margin_right=16
  button.add_theme_stylebox_override(state,style)
 button.add_theme_color_override("font_color",Color("fff9dd") if primary else Color("35664a"))
