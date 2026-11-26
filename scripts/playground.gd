extends Control
const REWARDS=preload("res://scripts/playground_rewards.gd")
const NAMES={"spin":"Komidi Putar","ball":"Lempar Bola","animals":"Tangkap Hewan","fruit":"Cocokkan Buah"}
var host
var mode=""
var token=""
var active=false
var finished=false
var claimed_result=false
var score=0
var balls=5
var angle=0.0
var ball=Vector2(310,525)
var velocity=Vector2.ZERO
var flying=false
const HOOPS = [173.0, 296.0, 446.0]
var target=296.0
var aim=0.0
var power=.72
var selected: Array[int]=[]
var board: Array[int]=[]
var hole=0
var animal=0
var pop_at=0
var deadline=0
var old_modal=false
var status: Label
var subtitle: Label
var scroll_view: ScrollContainer
var body: VBoxContainer
var arena
var primary: Button
var aim_slider: HSlider
var power_slider: HSlider
func _ready():
 z_index=125;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 old_modal=bool(host.get_meta("first_farm_modal",false));host.set_meta("first_farm_modal",true);host.farm.set_panel_obscured(true)
 var shade=ColorRect.new();shade.color=Color(.07,.2,.08,.65);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var paper=PanelContainer.new();paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper.offset_left=20;paper.offset_right=-20;paper.offset_top=155;paper.offset_bottom=-130
 var skin=StyleBoxFlat.new();skin.bg_color=Color("fff4d7");skin.border_color=Color("d89443");skin.set_border_width_all(6);skin.set_corner_radius_all(30);skin.content_margin_left=20;skin.content_margin_right=20;skin.content_margin_top=16;skin.content_margin_bottom=16;paper.add_theme_stylebox_override("panel",skin);add_child(paper)
 var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",12);paper.add_child(stack)
 var top=HBoxContainer.new();stack.add_child(top)
 var heading=Label.new();heading.text="TAMAN BERMAIN";heading.set_meta("typography_role","title");heading.add_theme_font_size_override("font_size",34);heading.add_theme_color_override("font_color",Color("3c6337"));heading.size_flags_horizontal=SIZE_EXPAND_FILL;heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;top.add_child(heading)
 var exit_button=make_button(top,"×",close);exit_button.custom_minimum_size=Vector2(55,55);exit_button.size_flags_horizontal=SIZE_SHRINK_END;exit_button.name="PlaygroundClose"
 var red=StyleBoxFlat.new();red.bg_color=Color("dd4d38");red.set_corner_radius_all(20);exit_button.add_theme_stylebox_override("normal",red);exit_button.set_meta("colorful_applied",true)
 subtitle=label(stack,"Empat wahana ringan. Hadiah setiap wahana satu kali per hari.",18)
 status=label(stack,"",21)
 var scroll=ScrollContainer.new();scroll_view=scroll;scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;stack.add_child(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",14);scroll.add_child(body)
 var bottom=HBoxContainer.new();stack.add_child(bottom)
 var back=make_button(bottom,"‹ DAFTAR WAHANA",show_menu);back.name="PlaygroundBack"
 make_button(bottom,"KEMBALI KE KEBUN",close)
 show_menu()
func label(parent,text: String,font: int) -> Label:
 var node=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.add_theme_font_size_override("font_size",font);node.add_theme_color_override("font_color",Color("4c4b30"));parent.add_child(node);return node
func make_button(parent,text: String,action: Callable) -> Button:
 var button=Button.new();button.text=text;button.custom_minimum_size=Vector2(0,55);button.size_flags_horizontal=SIZE_EXPAND_FILL
 var skin=StyleBoxFlat.new();skin.bg_color=Color("18a55e");skin.border_color=Color("e8b953");skin.set_border_width_all(3);skin.set_corner_radius_all(18)
 button.add_theme_stylebox_override("normal",skin);button.add_theme_font_size_override("font_size",21);button.add_theme_color_override("font_color",Color.WHITE);button.pressed.connect(action);parent.add_child(button);return button
func clear_body():
 if is_instance_valid(scroll_view):scroll_view.scroll_vertical=0
 for node in body.get_children():body.remove_child(node);node.queue_free()
 arena=null;primary=null;aim_slider=null;power_slider=null
func show_menu():
 if active or finished and not claimed_result:REWARDS.cancel(host.game,mode,token)
 active=false;finished=false;mode="";clear_body();scroll_view.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;status.text="HIBURAN OPSIONAL · HADIAH HARIAN"
 subtitle.text="Datang kapan saja. Hadiah harian yang sudah diambil berubah menjadi mode latihan."
 for id in REWARDS.MODES:
  var card=PanelContainer.new();card.custom_minimum_size.y=135;var style=StyleBoxFlat.new();style.bg_color=Color("ffe9b5");style.set_corner_radius_all(22);style.content_margin_left=18;style.content_margin_top=12;style.content_margin_bottom=12;style.content_margin_right=18;card.add_theme_stylebox_override("panel",style);body.add_child(card)
  var row=HBoxContainer.new();card.add_child(row)
  var art=TextureRect.new();art.custom_minimum_size=Vector2(95,95);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.mouse_filter=MOUSE_FILTER_IGNORE
  art.texture=preload("res://scripts/reference_assets.gd").icon("region_playground") if id=="spin" else preload("res://scripts/colorful_icons.gd").texture({"ball":"playground_ball","animals":"hewan","fruit":"apel"}[id]);row.add_child(art)
  var column=VBoxContainer.new();column.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_child(column)
  label(column,str(NAMES[id]),26)
  label(column,{"spin":"Hentikan putaran · 50–200 koin","ball":"5 bola · 20–100 koin, bonus 10 XP","animals":"30 detik · hingga 50 koin + 10 XP","fruit":"60 detik · 5–20 permata"}[id],17)
  var b=make_button(column,"LATIHAN" if REWARDS.claimed(host.game,id) else "MAIN SEKARANG",start.bind(id));b.name="Play_"+id
func start(id: String):
 if id not in NAMES:return
 if active:REWARDS.cancel(host.game,mode,token)
 clear_body();scroll_view.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;mode=id;score=0;balls=5;angle=0;selected.clear();active=true;finished=false;claimed_result=false;flying=false
 token=REWARDS.start(host.game,id)
 subtitle.text={"spin":"Ketuk HENTIKAN saat hadiah pilihan berada di penunjuk.","ball":"Geser arah dan kekuatan, lalu lempar. Atau sapukan bola ke atas menuju keranjang merah.","animals":"Ketuk hewan yang muncul sebelum masuk kembali ke lubang.","fruit":"Ketuk 3 buah sejenis. Cocokkan sebanyak mungkin dalam 60 detik."}[id]
 arena=preload("res://scripts/playground_canvas.gd").new();arena.game=self;arena.custom_minimum_size=Vector2(580,430 if id=="ball" else 500);body.add_child(arena)
 if id=="ball":
  label(body,"ARAH",17);aim_slider=HSlider.new();aim_slider.min_value=-1;aim_slider.max_value=1;aim_slider.step=.02;aim_slider.value=0;aim_slider.custom_minimum_size.y=30;body.add_child(aim_slider);aim_slider.value_changed.connect(func(v):aim=v)
  label(body,"KEKUATAN",17);power_slider=HSlider.new();power_slider.min_value=.1;power_slider.max_value=1;power_slider.step=.02;power_slider.value=.72;power_slider.custom_minimum_size.y=30;body.add_child(power_slider);power_slider.value_changed.connect(func(v):power=v)
  primary=make_button(body,"LEMPAR BOLA",launch);primary.name="ThrowBall"
  aim=0;power=.72;target=296;ball=Vector2(310,525)
 elif id=="spin":primary=make_button(body,"HENTIKAN",stop_spin);primary.name="StopSpin"
 elif id=="animals":deadline=Time.get_ticks_msec()+30000;next_animal()
 elif id=="fruit":
  deadline=Time.get_ticks_msec()+60000;board.clear()
  for i in 20:board.append(randi_range(0,4))
 update_status()
func update_status():
 if mode=="":return
 var practice=" · LATIHAN" if REWARDS.claimed(host.game,mode) else " · Hadiah harian tersedia"
 if mode=="ball":status.text="%s · Skor %d · Sisa bola %d%s"%[NAMES[mode],score,balls,practice]
 elif mode in ["animals","fruit"]:status.text="%s · Skor %d · %d dtk%s"%[NAMES[mode],score,maxi(0,ceili((deadline-Time.get_ticks_msec())/1000.0)),practice]
 else:status.text=str(NAMES[mode])+practice
func _process(dt):
 if not active:return
 if mode=="spin":angle=fposmod(angle+dt*3.7,TAU)
 if mode=="ball" and flying:
  var old=ball;velocity.y+=700*dt;ball+=velocity*dt
  var rim = 161.0 if is_equal_approx(target, 296.0) else 202.0
  if old.y<rim and ball.y>=rim and velocity.y>0 and absf(ball.x-target)<38:
   score+=10;finish_throw()
  elif ball.y>610 or ball.x< -30 or ball.x>670:finish_throw()
 if mode=="animals" and Time.get_ticks_msec()>=pop_at:next_animal()
 if mode in ["animals","fruit"] and Time.get_ticks_msec()>=deadline:finish()
 update_status()
 if is_instance_valid(arena):arena.queue_redraw()
func launch():
 if not active or mode!="ball" or flying or balls<=0:return
 ball=Vector2(310,525);velocity=Vector2(aim*260,-(500+power*330));flying=true;balls-=1;primary.disabled=true;update_status()
func finish_throw():
 flying=false;ball=Vector2(310,525)
 if balls<=0:finish();return
 target=HOOPS.pick_random();primary.disabled=false
func flick(delta: Vector2):
 if delta.length()<25:return
 aim=clampf(delta.x/220,-1,1);power=clampf(delta.length()/370,.1,1)
 if is_instance_valid(aim_slider):aim_slider.value=aim;power_slider.value=power
 launch()
func stop_spin():
 if not active or mode!="spin":return
 score=int(fposmod(-PI*.5-angle,TAU)/(PI*.5))%4;finish()
func next_animal():
 hole=randi_range(0,5);animal=randi_range(0,3);pop_at=Time.get_ticks_msec()+maxi(450,950-score*15)
func tap_hole(index: int):
 if not active or mode!="animals" or Time.get_ticks_msec()>=deadline or index!=hole:return
 score+=1;next_animal();update_status()
func tap_fruit(index: int):
 if not active or mode!="fruit" or Time.get_ticks_msec()>=deadline or index<0 or index>=20:return
 if index in selected:selected.erase(index);return
 if not selected.is_empty() and board[selected[0]]!=board[index]:selected.clear()
 selected.append(index)
 if selected.size()==3:
  score+=1
  for i in selected:board[i]=randi_range(0,4)
  selected.clear();update_status()
func finish():
 if not active:return
 active=false;finished=true;clear_body()
 var result=REWARDS.reward(mode,score)
 label(body,"PERMAINAN SELESAI",32).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label(body,"%s · Skor %d"%[NAMES[mode],score],25)
 var practice=REWARDS.claimed(host.game,mode)
 label(body,"Latihan selesai. Hadiah harian wahana ini sudah diambil." if practice else "Hadiah: %d koin · %d XP · %d permata"%[result.coins,result.xp,result.gems],23)
 var claim=make_button(body,"SELESAI LATIHAN" if practice else "AMBIL HADIAH",claim_reward);claim.name="ClaimPlaygroundReward"
func claim_reward():
 if not finished or claimed_result:return
 claimed_result=true
 var result=REWARDS.claim(host.game,mode,token,score)
 host.refresh_all()
 if not result.is_empty():host.show_toast("Hadiah Taman Bermain: +%d koin, +%d XP, +%d permata."%[result.coins,result.xp,result.gems])
 show_menu()
func close():
 if active or finished and not claimed_result:REWARDS.cancel(host.game,mode,token)
 host.set_meta("first_farm_modal",old_modal);host.farm.set_panel_obscured(host.active_tab!="kebun");queue_free()
func _notification(what):
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:close()
