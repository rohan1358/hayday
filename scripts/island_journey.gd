extends RefCounted
# Separate island settlements; farmer inventory and main farm facilities travel with the player.
const ORDER=["summer","spring","autumn","winter"]
const REGION_KEYS=["owned","tier","ready_at","happiness","industry_jobs"]
static var changing=false
static func prepare(game) -> Dictionary:
 if not game.world_regions.get("island_journey",{}) is Dictionary:game.world_regions.island_journey={}
 if not game.world_regions.has("island_journey"):game.world_regions.island_journey={}
 var journey: Dictionary=game.world_regions.island_journey
 if not journey.has("active"):journey.active="summer"
 if journey.active not in ORDER:journey.active="summer"
 if not journey.get("worlds",{}) is Dictionary:journey.worlds={}
 if not journey.has("worlds"):journey.worlds={}
 for id in ORDER:
  if not journey.worlds.has(id):journey.worlds[id]={"level":1,"xp":0}
 journey.worlds.summer.level=clampi(game.level,1,50)
 preload("res://scripts/four_seasons.gd").active_id=str(journey.active)
 return journey
static func city_level(game,id: String="") -> int:
 var data=prepare(game)
 if id=="":id=str(data.active)
 return clampi(int(data.worlds[id].level),1,50)
static func opened(game,id: String="") -> int:
 var level=city_level(game,id)
 var count=0
 var regions=load("res://scripts/world_regions.gd")
 for key in regions.ORDER:
  if level>=int(regions.DATA[key].level):count+=1
 return count
static func can_enter(game,id: String) -> bool:
 if id not in ORDER:return false
 var index=ORDER.find(id)
 for i in index:
  if opened(game,ORDER[i])<25:return false
 return true
static func capture(game) -> void:
 if changing:return
 var journey=prepare(game)
 var state: Dictionary=journey.worlds[journey.active]
 state.positions=game.layout_positions.duplicate(true)
 state.roads=game.road_tiles.duplicate(true)
 state.decorations=game.decorations.duplicate(true)
 state.tree_positions=game.building_upgrades.get("tree_positions",{}).duplicate(true)
 state.hidden_trees=game.building_upgrades.get("hidden_trees",{}).duplicate(true)
 state.manual_trees=game.building_upgrades.get("manual_trees",{}).duplicate(true)
 state.nodes=game.building_upgrades.get("nodes",[]).duplicate(true)
 state.cleared=game.cleared_wild_trees.duplicate()
 state.player=game.hybrid.get("player",[1170,2212]).duplicate()
 state.playfield_repair=int(game.world_regions.get("playfield_repair",0))
 for key in REGION_KEYS:
  var value=game.world_regions.get(key,{} if key!="happiness" else 0)
  state[key]=value.duplicate(true) if value is Dictionary else value
static func award_city_xp(game,amount: int) -> void:
 var journey=prepare(game)
 if journey.active=="summer" or amount<=0:return
 var town: Dictionary=journey.worlds[journey.active]
 town.xp=int(town.get("xp",0))+amount
 while int(town.level)<50 and int(town.xp)>=100+(int(town.level)-1)*25:
  town.xp=int(town.xp)-(100+(int(town.level)-1)*25)
  town.level=int(town.level)+1
static func enter(host,id: String) -> bool:
 var game=host.game
 var journey=prepare(game)
 if not can_enter(game,id):
  var previous=ORDER[maxi(0,ORDER.find(id)-1)]
  host.show_toast("Buka seluruh 25 kawasan %s dahulu (%d/25)."%[preload("res://scripts/four_seasons.gd").DATA[previous].name,opened(game,previous)])
  return false
 if journey.active==id:
  host.farm.reset_camera();host.switch_tab("kebun");return true
 host.farm.hybrid_controller.cancel_all("")
 capture(game)
 var target: Dictionary=journey.worlds[id]
 changing=true
 if not target.has("positions"):
  target.positions=game.layout_positions.duplicate(true)
  target.decorations=[]
  target.roads={}
  target.tree_positions={};target.nodes=[];target.cleared=[]
  target.player=[1170,2212];target.playfield_repair=0
  target.owned={};target.tier={};target.ready_at={};target.happiness=0
 journey.active=id
 preload("res://scripts/four_seasons.gd").active_id=id
 game.layout_positions=target.positions.duplicate(true)
 game.road_tiles=target.get("roads",{}).duplicate(true)
 game.decorations.assign(target.get("decorations",[]).duplicate(true))
 game.building_upgrades.tree_positions=target.get("tree_positions",{}).duplicate(true)
 game.building_upgrades.hidden_trees=target.get("hidden_trees",{}).duplicate(true)
 game.building_upgrades.manual_trees=target.get("manual_trees",{}).duplicate(true)
 game.building_upgrades.nodes=target.get("nodes",[]).duplicate(true)
 game.cleared_wild_trees.assign(target.get("cleared",[]))
 for key in REGION_KEYS:game.world_regions[key]=target.get(key,{} if key!="happiness" else 0).duplicate(true) if target.get(key,{}) is Dictionary else target.get(key,0)
 game.world_regions.playfield_repair=int(target.get("playfield_repair",0))
 game.hybrid.jobs=[]
 game.hybrid.player=target.get("player",[1170,2212]).duplicate()
 host.farm.ujang_position=Vector2(game.hybrid.player[0],game.hybrid.player[1])
 host.farm.hybrid_controller.data.follow=false
 host.farm.hybrid_controller.navigation.revision=""
 changing=false
 preload("res://scripts/reference_terrain.gd").repair_playfield(host)
 host.farm.invalidate_scenery();host.farm.reset_camera()
 for child in host.get_children():
  if child.get_script()==load("res://scripts/seasonal_ui.gd"):
   child.last_announced_region="";child.pending_region="";child.refresh_weather()
 host.switch_tab("kebun");host.refresh_all();game.save_game()
 host.show_toast("Selamat datang di pulau "+str(preload("res://scripts/four_seasons.gd").DATA[id].name)+"!")
 return true
