extends SceneTree
const FLOW=preload("res://scripts/first_farm.gd")
const COOP=preload("res://scripts/first_coop.gd")
class ClockGame extends FarmGameState:
 var clock=1800000000
 func now() -> int: return clock
var failures=0
func check(ok: bool,message: String):
 print("PASS: " if ok else "FAIL: ",message)
 if not ok: failures+=1
func fresh(name: String):
 var game=ClockGame.new()
 game.new_game()
 game.save_path="user://ftue_test_"+name+".json"
 game.backup_path="user://ftue_test_"+name+"_backup.json"
 return game
func _initialize(): call_deferred("run")
func run():
 var game=fresh("complete")
 check(game.level==1 and game.xp==0 and game.xp_target()==100,"new player starts at Level 1 / 0 of 100 XP")
 check(game.coins==100 and game.seeds.gandum==3,"100 coins and three free wheat seeds")
 check(game.plots.filter(func(p): return p.unlocked).size()==3 and game.plots.all(func(p): return p.crop==""),"exactly three unlocked empty plots")
 check(not game.ready_eggs() and not COOP.built(game),"no premature chicken pen or free eggs")
 check(game.visitor_request.is_empty() and not game.refresh_visitor(),"no unrelated visitor interrupts welcome")
 check(not game.can_plant(0,"gandum"),"welcome requires a real start and plot selection")
 game.ftue.started=true
 FLOW.selected(game,0)
 check(game.ftue.step=="plant","selecting plot advances to seed selection")
 check(not game.plant(3,"gandum") and not game.plant(0,"jagung"),"locked plot and wrong crop cannot bypass tutorial")
 check(game.plant(0,"gandum") and not game.plant(0,"gandum"),"successful planting consumes one seed and rejects duplicate")
 var resumed=fresh("resume")
 resumed.save_path=game.save_path;resumed.backup_path=game.backup_path
 check(resumed.load_game() and resumed.ftue.planted==[0] and resumed.seeds.gandum==2,"mid-plant tutorial resumes without duplicate seeds")
 check(game.plant(1,"gandum") and game.plant(2,"gandum"),"all three wheat plots plant successfully")
 check(game.coins==100 and game.seeds.gandum==0 and game.xp==55 and game.ftue.step=="grow","free seeds, persisted mission progress, and planting XP are real")
 check(game.plots[0].ready_at-game.plots[0].planted_at==8,"tutorial duration uses real plant timestamps and is faster than normal wheat")
 game.clock+=3
 check(not game.is_ready(0) and not FLOW.tick(game),"tutorial cannot skip growth before plants mature")
 game.clock+=5
 FLOW.tick(game)
 check(game.is_ready(0) and game.ftue.step=="harvest","real growth completion enables harvesting")
 var quantity=game.harvest(0)
 check(quantity>0 and game.inventory.gandum==quantity and game.harvest(0)==0,"harvest updates inventory exactly once")
 game.harvest(1);game.harvest(2)
 check(game.ftue.step=="sale" and game.visitor_request.quantity==3,"NPC appears only after all three plots are harvested")
 check(game.visitor_request.coins==50 and game.visitor_request.xp==30,"first sale offers exactly 50 coins and 30 XP")
 check(not game.decline_visitor(),"required first NPC cannot be dismissed into a dead end")
 var wheat=game.inventory.gandum
 check(game.sell_quantity("gandum",wheat)==0 and not game.list_market_item("gandum",3),"first-sale wheat cannot be spent in another system and strand the tutorial")
 check(game.fulfill_visitor() and game.inventory.gandum==wheat-3 and game.coins==150,"first sale atomically subtracts wheat and credits 50 coins")
 check(game.level==2 and game.xp==0 and game.ftue.step=="reward","plant, harvest and sale XP total exactly 100, reaching Level 2")
 check(not game.fulfill_visitor() and game.coins==150,"first transaction cannot be claimed twice")
 check(FLOW.claim(game) and not FLOW.claim(game) and game.seeds.gandum==3,"level continuation grants three wheat seeds once")
 resumed.load_game()
 check(not FLOW.active(resumed) and resumed.level==2 and resumed.coins==150 and not FLOW.claim(resumed),"finished tutorial does not repeat after restart")
 check(not COOP.build(game) and not game.can_feed_chickens() and not game.ready_eggs(),"Level 2 is a preview, not a usable chicken pen")
 # Progress naturally through ordinary wheat crops after onboarding, without
 # injecting XP or coins to reach the poultry unlock.
 var cycles=0
 while game.level<3 and cycles<30:
  if game.seeds.gandum==0: game.buy_seeds("gandum",1)
  check(game.plant(0,"gandum"),"post-tutorial wheat remains playable")
  game.clock+=int(game.CROPS.gandum.grow)
  game.harvest(0)
  cycles+=1
 var building_coins=game.coins
 check(game.level==3 and COOP.build(game) and not COOP.build(game),"Level 3 unlocks a one-time actual chicken pen build")
 check(game.coins==building_coins-80 and preload("res://scripts/ranch_state.gd").count(game,"ayam")==2,"building costs 80 coins and introduces two chickens")
 var grain=game.inventory.gandum
 check(game.queue_feed("pakan_ayam") and game.inventory.gandum==grain-2,"wheat really becomes queued chicken feed")
 check(not game.collect_feed(),"feed cannot be collected early")
 game.clock+=8
 check(game.collect_feed() and int(game.inventory.pakan_ayam)==1,"finished feed enters inventory")
 check(game.feed_chickens() and not game.feed_chickens() and int(game.inventory.pakan_ayam)==0,"feeding consumes feed once and starts egg production")
 check(not game.collect_eggs(),"eggs cannot be collected before real production timer")
 game.clock+=38
 check(game.collect_eggs() and game.inventory.telur>0 and not game.collect_eggs(),"two chickens produce collectible eggs without duplicate collection")
 check(game.ftue.poultry_step=="done" and game.eggs_ready_at==0,"poultry mission completes and next cycle requires feed")
 resumed.load_game()
 check(COOP.built(resumed) and resumed.inventory.telur==game.inventory.telur,"poultry production and mission survive reload")
 var skipped=fresh("skip")
 FLOW.skip(skipped)
 check(not FLOW.active(skipped) and skipped.coins==100 and skipped.seeds.gandum==3 and skipped.level==1,"skip is safe and invents no tutorial reward")
 var old=fresh("legacy")
 old.ftue={};old.level=17;old.coins=987;old.layout_positions["dapur"]=[400,800];old.plots[8].unlocked=true
 old.save_game()
 var data=JSON.parse_string(FileAccess.get_file_as_string(old.save_path));data.erase("ftue")
 var file=FileAccess.open(old.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 var migrated=fresh("legacy_read");migrated.save_path=old.save_path;migrated.backup_path=old.backup_path
 check(migrated.load_game() and migrated.ftue.is_empty() and migrated.level==17 and migrated.coins==987,"pre-FTUE save keeps economy and level without forced tutorial")
 check(Vector2(migrated.layout_positions.dapur[0],migrated.layout_positions.dapur[1])==Vector2(400,800) and migrated.plots[8].unlocked,"legacy layout and expansion are unchanged")
 check(migrated.feature_unlocked("ranch") and migrated.crop_level("stroberi_kristal")==20,"legacy feature and crop unlocks remain compatible")
 print("FIRST FARM FAILURES: ",failures)
 quit(failures)
