extends Node2D
var farm: FarmView
var season_id="summer"
var elapsed=0.0
var clock=0.0
func _process(delta: float) -> void:
 elapsed+=delta;clock+=delta
 if clock>=0.033:clock=0;queue_redraw()
func _draw() -> void:
 if farm==null:return
 var terrain=preload("res://scripts/reference_terrain.gd")
 for i in farm.WILD_TREES.size():
  var at=farm.wild_tree_position(i)
  if not terrain.bounds_clear(terrain.tree_bounds(at,i,season_id)):continue
  draw_set_transform(at,0,Vector2.ONE)
  terrain.paint_tree(self,season_id,i)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for key in ["dapur","gudang"]:
  var asset="kitchen_cottage" if key=="dapur" else "village_barn"
  farm.farm_art.paint(self,asset,farm.object_position(key),300 if key=="dapur" else 260)
 var special=preload("res://scripts/first_farm_world.gd")
 farm.farm_art.paint(self,special.seasonal_asset("lg_blossom_tree",season_id),farm.object_position("starter_14"),205)
 # Explicit preview-local animation never changes FourSeasons.active_id.
 for i in 65:
  var at=Vector2(350+fposmod(i*397.0+sin(elapsed+i)*40,3600),1300+fposmod(i*557.0+elapsed*45,5700))
  if not terrain.ground_surface(at):continue
  if season_id=="winter":
   draw_circle(at,6,Color(0.96,0.99,1,0.8))
  elif season_id=="spring":
   draw_set_transform(at,elapsed+i,Vector2(1,0.6));draw_circle(Vector2.ZERO,9,Color("ffb2d4aa"));draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  elif season_id=="autumn":
   draw_set_transform(at,elapsed+i,Vector2.ONE);draw_colored_polygon(PackedVector2Array([Vector2(-9,0),Vector2(0,-5),Vector2(9,0),Vector2(0,5)]),Color("ed9d32cc"));draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if season_id in ["summer","spring"]:
  for i in 12:
   var at=Vector2(700+(i%4)*800,1900+floori(i/4.0)*1500)+Vector2(sin(elapsed+i)*70,cos(elapsed*0.8+i)*35)
   preload("res://scripts/island_ambience.gd").butterfly(self,at,elapsed+i)
