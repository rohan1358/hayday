extends SceneTree
const REWARDS=preload("res://scripts/playground_rewards.gd")
func _initialize():call_deferred("run")
func click(control,local=Vector2.INF):
 var point=control.get_global_transform_with_canvas()*(control.size*.5 if local==Vector2.INF else local)
 var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func arena_click(pg,point):await click(pg.arena,pg.arena.frame()*point)
func settle():
 for i in 6:await process_frame
func shot(name):
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+name+".png"))
func run():
 root.size=Vector2i(720,1280)
 var game=FarmGameState.new(false);game.save_path="user://playground_rewards_test.json";game.backup_path="user://playground_rewards_backup.json"
 assert(REWARDS.start(game,"fruit")=="","Locked playground must not issue reward tokens")
 game.level=5;preload("res://scripts/world_regions.gd").prepare(game).owned.taman_bermain=true
 var token=REWARDS.start(game,"spin");var old=game.coins
 assert(REWARDS.claim(game,"spin",token,3).coins==200 and game.coins==old+200)
 assert(REWARDS.claim(game,"spin",token,3).is_empty())
 token=REWARDS.start(game,"spin");assert(REWARDS.claim(game,"spin",token,3).is_empty() and game.coins==old+200)
 assert(REWARDS.reward("ball",20).coins==20 and REWARDS.reward("ball",40).coins==50 and REWARDS.reward("ball",50).xp==10)
 assert(REWARDS.reward("fruit",999).gems==20 and REWARDS.reward("fruit",0).gems==0)
 REWARDS.prepare(game,"2099-01-01");assert(not REWARDS.prepare(game,"2099-01-01").claimed.has("spin"))
 var host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://playground_live_test.json";host.game.backup_path="user://playground_live_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path));root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
 host.game.ftue.step="done";host.game.level=5;host.game.world_regions.owned.taman_bermain=true
 host.open_playground();await settle();var pg=host.get_node("Playground");pg.set_process(false)
 assert(host.get_meta("first_farm_modal") and host.farm.hybrid_controller.controls_blocked())
 await shot("taman-bermain-menu")
 await click(pg.find_child("Play_spin",true,false));await settle();assert(pg.mode=="spin")
 await shot("taman-komidi-putar")
 await click(pg.find_child("StopSpin",true,false));await settle();assert(pg.finished)
 await click(pg.find_child("ClaimPlaygroundReward",true,false));await settle();assert(REWARDS.claimed(host.game,"spin"))
 pg.start("ball");await settle();await shot("taman-lempar-bola")
 for i in 5:
  pg.target=296;pg.aim=0;pg.power=.72
  await click(pg.find_child("ThrowBall",true,false))
  for frame in 150:
   pg._process(1.0/60)
   if not pg.flying:break
  await settle()
 assert(pg.finished and pg.score==50,"Five actual throws should land using the displayed trajectory")
 old=host.game.coins;var xp=host.game.xp;await click(pg.find_child("ClaimPlaygroundReward",true,false));await settle()
 assert(host.game.coins==old+100 and host.game.xp==xp+10)
 pg.start("animals");await settle();await shot("taman-tangkap-hewan")
 for i in 10:
  var point=Vector2(145+(pg.hole%3)*175,270+int(pg.hole/3)*175)-Vector2(0,25)
  await arena_click(pg,point)
 assert(pg.score==10,"Pointer taps must catch the currently visible animals")
 pg.deadline=Time.get_ticks_msec()-1;pg._process(.1);await settle();assert(pg.finished)
 await click(pg.find_child("ClaimPlaygroundReward",true,false));await settle()
 pg.start("fruit");await settle();await shot("taman-cocokkan-buah")
 for match_index in 15:
  var found=[]
  for fruit in 5:
   var indices=[]
   for i in 20:
    if pg.board[i]==fruit:indices.append(i)
   if indices.size()>=3:found=indices.slice(0,3);break
  for i in found:await arena_click(pg,pg.arena.fruit_rect(i).get_center())
 assert(pg.score==15,"Three matching visible fruit tiles must form each match")
 pg.deadline=Time.get_ticks_msec()-1;pg._process(.1);await settle();old=host.game.diamonds
 await click(pg.find_child("ClaimPlaygroundReward",true,false));await settle();assert(host.game.diamonds==old+20)
 pg.start("fruit");pg.score=15;pg.finish();await settle();await click(pg.find_child("ClaimPlaygroundReward",true,false));await settle();assert(host.game.diamonds==old+20,"Practice must never duplicate daily gems")
 pg.close();await process_frame;assert(not bool(host.get_meta("first_farm_modal",true)))
 var loaded=FarmGameState.new(false);loaded.save_path=host.game.save_path;loaded.backup_path=host.game.backup_path;assert(loaded.load_game())
 assert(REWARDS.claimed(loaded,"fruit") and REWARDS.claimed(loaded,"ball"),"Daily claims must survive restart")
 print("PLAYGROUND PASS: four actual games, ball physics, timed animal taps, triple fruit matching, daily idempotence, practice, save persistence and modal release")
 host.queue_free();await process_frame;quit()
