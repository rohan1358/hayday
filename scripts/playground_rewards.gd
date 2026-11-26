extends RefCounted
const MODES=["spin","ball","animals","fruit"]
static func prepare(game,date: String="") -> Dictionary:
 if date=="":date=Time.get_date_string_from_system()
 if not game.building_upgrades.has("playground_daily"):game.building_upgrades.playground_daily={}
 var data: Dictionary=game.building_upgrades.playground_daily
 if str(data.get("date",""))!=date:data.assign({"date":date,"claimed":{},"runs":{}})
 return data
static func can_play(game) -> bool:
 return preload("res://scripts/world_regions.gd").purchased(game,"taman_bermain") and preload("res://scripts/island_journey.gd").city_level(game)>=5
static func start(game,mode: String) -> String:
 if mode not in MODES or not can_play(game):return ""
 var token="%d-%d"%[Time.get_ticks_usec(),randi()]
 prepare(game).runs[mode]=token;game.save_game();return token
static func reward(mode: String,score: int) -> Dictionary:
 match mode:
  "spin":return {"coins":50+clampi(score,0,3)*50,"xp":0,"gems":0}
  "ball":return {"coins":100 if score>=50 else (50 if score>=30 else 20),"xp":10 if score>=50 else 0,"gems":0}
  "animals":return {"coins":10+mini(40,maxi(0,score)*4),"xp":mini(10,maxi(0,score)),"gems":0}
  "fruit":return {"coins":0,"xp":0,"gems":mini(20,5+maxi(0,score)) if score>0 else 0}
 return {}
static func claim(game,mode: String,token: String,score: int) -> Dictionary:
 var data=prepare(game)
 if mode not in MODES or token=="" or not can_play(game) or str(data.runs.get(mode,""))!=token:return {}
 data.runs.erase(mode)
 if data.claimed.has(mode):game.save_game();return {}
 var result=reward(mode,score)
 data.claimed[mode]=true
 game.coins+=int(result.coins);game.diamonds+=int(result.gems)
 game.award_xp(int(result.xp));game.save_game();return result
static func claimed(game,mode: String) -> bool:return prepare(game).claimed.has(mode)
static func cancel(game,mode: String,token: String) -> void:
 var data=prepare(game)
 if str(data.runs.get(mode,""))==token:data.runs.erase(mode);game.save_game()
