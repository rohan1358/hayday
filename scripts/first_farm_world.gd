extends RefCounted
const SCENERY = [
 ["flowering_hedge",Vector2(800,630),180.0,Vector2(70,32)],
 ["flower_patch",Vector2(1570,1080),125.0,Vector2(50,25)],
 ["flowering_hedge",Vector2(1540,540),160.0,Vector2(65,30)],
 ["flower_patch",Vector2(810,850),125.0,Vector2(50,25)],
 ["flower_patch",Vector2(760,1180),125.0,Vector2(50,25)],
 ["flower_patch",Vector2(1600,790),125.0,Vector2(50,25)],
 ["flower_patch",Vector2(1320,1390),125.0,Vector2(50,25)],
 ["flower_patch",Vector2(1000,1450),125.0,Vector2(50,25)],
 ["fence_straight",Vector2(830,650),145.0,Vector2(60,20)],
 ["fence_straight",Vector2(820,730),145.0,Vector2(60,20)],
 ["fence_straight",Vector2(1370,520),145.0,Vector2(60,20)],
 ["fence_straight",Vector2(1500,580),145.0,Vector2(60,20)],
 ["fence_straight",Vector2(1400,680),145.0,Vector2(60,20)],
 ["decorative_pond",Vector2(1510,1210),300.0,Vector2(118,65)],
 ["lg_blossom_tree",Vector2(1570,930),205.0,Vector2(60,38)],
 ["flower_patch",Vector2(780,1260),100.0,Vector2(40,22)],
 ["flower_patch",Vector2(1580,1380),135.0,Vector2(54,28)]
]
static func seasonal_asset(asset: String,id: String="") -> String:
 if id=="":id=preload("res://scripts/four_seasons.gd").active_id
 if asset=="lg_blossom_tree":return {"spring":"lg_blossom_tree","summer":"colorful_oak","autumn":"autumn_maple","winter":"snow_pine"}.get(id,"colorful_oak")
 return asset
static func paint_landscaping(view) -> void:
 for i in SCENERY.size():
  var item=SCENERY[i]
  var at: Vector2=view.object_position("starter_%d" % i)
  if item[0]=="flower_patch" and not view.edit_mode: at.x+=sin(view.shimmer+i)*1.5
  view.farm_art.paint(view,seasonal_asset(item[0]),at,item[2])
static func paint(view) -> void:
 view.set_world_transform()
 preload("res://scripts/colorful_environment.gd").ground(view,view.WORLD_SIZE)

 preload("res://scripts/four_seasons.gd").paint(view)
 # Stable wild-tree IDs are shared with the main farm, including saved stumps.
 for index in view.WILD_TREES.size():
  var at: Vector2=view.wild_tree_position(index)
  if view.visible_world_rect(170).has_point(at) and not not view.wild_tree_active(index):
   view.paint_wild_tree(index,at)
 # The house and garden use the same movable anchors as the full farm.
 paint_landscaping(view)
 view.paint_roads()
 if preload("res://scripts/first_farm.gd").feature(view.game,"orders"):
  view.paint_delivery_depot()
 view.farm_art.paint(view,"market_cart",view.object_position("pasar"),240)
 var house: Vector2=view.object_position("dapur")
 view.ellipse(house+Vector2(0,8),125,30,Color("346e512f"))
 view.farm_art.paint(view,"kitchen_cottage",house,300)
 for index in view.game.orchard.size():
  if not str(view.game.orchard[index].fruit).is_empty(): OrchardPainter.paint(view,view.game,index,view.orchard_center(index))
 view.paint_owned_decorations()
 view.paint_spacious_constructions()
 preload("res://scripts/world_regions_painter.gd").paint(view)
 view.farm_art.paint(view,"village_barn",view.object_position("gudang"),260)
 if view.placement_decoration_key!="":
  var item=view.game.decoration_by_key(view.placement_decoration_key)
  var kind=str(item.get("kind",""))
  if view.game.DECORATIONS.has(kind):
   view.farm_art.paint(view,kind,view.placement_preview,float(view.game.DECORATIONS[kind].width))
   var half: Vector2=view.object_half_size(view.placement_decoration_key)
   view.draw_rect(Rect2(view.placement_preview-half,half*2),Color("72edac") if view.can_place(view.placement_decoration_key,view.placement_preview) else Color("ff7669"),false,4)
 if preload("res://scripts/first_coop.gd").built(view.game):
  var coop: Vector2=view.object_position("ayam")
  view.farm_art.paint(view,"chicken_coop",coop,260)
  # Live chickens are rendered by RanchAnimator: random goals, pauses and pecking.
  # Do not draw a second decorative pair on a circular sine/cosine path.
 if bool(view.game.ftue.get("cow_built",false)):
  var cow_at=view.object_position("sapi")
  view.farm_art.paint(view,"cow_pen",cow_at,300)

 # Unpurchased buildings live in the shop. Their old translucent previews
 # overlapped the cow pen and looked like buildings already on the farm.
 for i in view.game.plots.size():
  if view.game.plots[i].unlocked: view.paint_plot(i,view.plot_center(i))
 if view.game.feature_unlocked("expansion"):
  # Available land is shown only after the first mission, never sixteen beds.
  var next=-1
  for i in view.game.plots.size():
   if not view.game.plots[i].unlocked: next=i;break
  if next >= 0:
   var at: Vector2 = view.plot_center(next)
   view.paint_plot(next, at)
   view.bubble("BELI LAHAN", at - Vector2(0, 62), Color("ffe5a0"), Color("75451d"))
 if view.game.ftue.get("step","")=="welcome":
  var target=view.guide_plot_index
  for i in 3:
   view.guide_plot_index=i
   view.paint_tutorial_plot(view.visible_world_rect(100))
  view.guide_plot_index=target
 else: view.paint_tutorial_plot(view.visible_world_rect(100))
 view.paint_ujang()
 preload("res://scripts/asset_projection.gd").paint_foreground(view)
 view.set_world_transform()
 if not view.game.visitor_request.is_empty(): view.paint_visitor()
 view.set_world_transform()
 if preload("res://scripts/first_farm.gd").feature(view.game,"orders"):
  view.paint_delivery_truck()
 paint_ready_badges(view)
 view.paint_visual_feedback()
 if view.edit_mode and view.drag_key!="":
  preload("res://scripts/road_mover.gd").preview(view)
  var at: Vector2=view.drag_preview
  var half: Vector2=view.object_half_size(view.drag_key)
  view.draw_rect(Rect2(at-half,half*2),Color("72edac") if view.can_place(view.drag_key,at) else Color("ff7669"),false,4)
 view.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

static func paint_ready_badges(view) -> void:
 var game = view.game
 var industry = preload("res://scripts/industry_jobs.gd")
 var regions = preload("res://scripts/world_regions.gd")
 var jobs = industry.jobs(game)
 var ready: Array[String] = []
 for id in ["tambang", "penggilingan"]:
  if regions.purchased(game, id) and jobs.has(id) and industry.remaining(game, id) == 0:
   ready.append("region_" + id)
 if regions.purchased(game, "pemancingan") and regions.wait_seconds(game, "pemancingan") == 0 and game.storage_used() < game.storage_capacity:
  ready.append("region_pemancingan")
 if game.feed_ready():
  ready.append("pakan" if game.has_construction("pabrik_pakan") else "ayam")
 if game.production_ready():
  var product = str(game.production_queue[0].product)
  if product in ["roti", "roti_manis", "kue", "roti_pisang", "pai_pir"] and game.has_construction("toko_roti"):
   ready.append("roti")
  elif product in ["keju", "mentega", "yogurt_kambing"] and game.has_construction("pabrik_susu"):
   ready.append("susu")
  else:
   ready.append("dapur")
 for key in ready:
  var at: Vector2 = view.object_position(key)
  if not view.visible_world_rect(360).has_point(at):
   continue
  var art = preload("res://scripts/asset_projection.gd").info(view, key, at)
  if not art.is_empty():
   view.bubble("SIAP!", Vector2(at.x, art.bounds.position.y - 24), Color("fff3c7"), Color("267c48"))
