extends RefCounted
const VERSION=5
const CAMERA=Vector2(1100,3900)
const ZOOM=0.58
const CORE={"dapur":[980,600],"buah_0":[1510,760],"ayam":[1450,600],"pasar":[1220,650],"gudang":[1840,700],"sapi":[2050,1150],"delivery_depot":[1780,1470],"delivery_truck":[2100,1570]}
const FIRST_PLOTS=[[1320,900],[1210,960],[1430,960],[1320,1020]]
const ROUTE=[Vector2i(30,52),Vector2i(31,52),Vector2i(32,52),Vector2i(33,52),Vector2i(34,52),Vector2i(35,52),Vector2i(36,52),Vector2i(36,53),Vector2i(36,54),Vector2i(36,55),Vector2i(36,56),Vector2i(36,57),Vector2i(36,58),Vector2i(36,59),Vector2i(36,60),Vector2i(36,61),Vector2i(37,61),Vector2i(38,61),Vector2i(39,61),Vector2i(40,61),Vector2i(41,61),Vector2i(42,61),Vector2i(43,61),Vector2i(44,61),Vector2i(45,61),Vector2i(46,61)]
static func ensure(game) -> bool:
 if game.ftue.is_empty() or int(game.ftue.get("cheerful_layout",0))>=VERSION: return false
 apply(game,false)
 return true
static func apply(game,starting: bool=false) -> void:
 if game.ftue.is_empty(): return
 if not starting:
  game.ftue.layout_backup={"positions":game.layout_positions.duplicate(true),"roads":game.road_tiles.duplicate(true),"road_inventory":game.road_inventory.duplicate(true),"player":game.hybrid.get("player",[1170,760]).duplicate()}
 var styles: Array=game.road_tiles.values()
 if starting:
  styles=[]
  for cell in ROUTE: styles.append("stone")
 for key in game.layout_positions.keys():
  if str(key).begins_with("starter_"): game.layout_positions.erase(key)
 game.layout_positions.merge(CORE,true)
 for i in game.plots.size():
  game.layout_positions["petak_%d" % i]=FIRST_PLOTS[i].duplicate() if i<4 else [860+((i-4)%4-int((i-4)/4))*110,1300+((i-4)%4+int((i-4)/4))*60]
 game.hybrid.player=[1170,760]
 game.hybrid.follow=false
 game.road_tiles.clear()
 for i in styles.size():
  if i<ROUTE.size():
   var cell: Vector2i=ROUTE[i]
   game.road_tiles["%d,%d" % [cell.x,cell.y]]=styles[i]
  else:
   var stock=preload("res://scripts/road_catalog.gd").prepare(game).stock
   var style=str(styles[i])
   stock[style]=int(stock.get(style,0))+1
 if int(game.world_regions.get("reference_terrain_version",0))>=1:
  for key in game.layout_positions:
   var at=game.layout_positions[key]
   if at is Array and at.size()==2 and float(at[1])<1700: game.layout_positions[key]=[at[0],float(at[1])+1452]
  game.hybrid.player=[1170,2212]
 game.ftue.cheerful_layout=VERSION
 if not starting: game.save_game()
static func restore(game) -> bool:
 var backup: Dictionary=game.ftue.get("layout_backup",{})
 if backup.is_empty(): return false
 game.layout_positions=backup.positions.duplicate(true)
 game.road_tiles=backup.roads.duplicate(true)
 if backup.has("road_inventory"): game.road_inventory=backup.road_inventory.duplicate(true)
 game.hybrid.player=backup.player.duplicate()
 game.ftue.erase("layout_backup")
 game.save_game()
 return true
static func lock_sign(view,at: Vector2,title: String,level: int) -> void:
 at=preload("res://scripts/reference_terrain.gd").safe_anchor(at,preload("res://scripts/four_seasons.gd").region(at))
 view.draw_rect(Rect2(at+Vector2(-5,-7),Vector2(10,45)),Color("8d5b2e"))
 var box=StyleBoxFlat.new();box.bg_color=Color("a36a32");box.border_color=Color("e4b36a");box.set_border_width_all(3);box.set_corner_radius_all(12)
 view.draw_style_box(box,Rect2(at-Vector2(104,80),Vector2(208,94)))
 view.draw_arc(at+Vector2(0,-98),11,PI,TAU,16,Color("fff4c8"),5,true)
 view.draw_rect(Rect2(at+Vector2(-16,-99),Vector2(32,29)),Color("f5b92c"))
 view.draw_circle(at+Vector2(0,-87),3,Color("976525"))
 var lines=title.split(" · ")
 var font=preload("res://assets/fonts/styles/fredoka_bold.tres")
 var language=preload("res://scripts/garden_language.gd")
 for i in mini(2,lines.size()):
  var text=language.text(lines[i])
  var size=18 if lines.size()==1 else 16
  var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
  view.label(lines[i],at+Vector2(-width*0.5,(-37 if lines.size()==1 else -51)+i*20),size,Color("fff8df"))
 var value="Level %d"%level
 var width=font.get_string_size(language.text(value),HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
 view.label(value,at+Vector2(-width*0.5,-9),16,Color("fff2c6"))
