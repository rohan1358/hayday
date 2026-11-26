extends RefCounted
const FLOW=preload("res://scripts/first_farm.gd")
static func tap(system,at: Vector2) -> void:
 if system.controls_blocked(): return
 var farm=system.farm
 var game=system.host.game
 if preload("res://scripts/four_seasons.gd").handle_tap(system.host,at): return
 var district=preload("res://scripts/world_regions_painter.gd").hit(farm,at)
 if district!="":
  if district in ["penggilingan","tambang"] and preload("res://scripts/world_regions.gd").purchased(game,district):system.host.open_industry(district);return
  if district=="taman_bermain" and preload("res://scripts/world_regions.gd").purchased(game,district):system.host.open_playground();return
  var data=preload("res://scripts/world_regions.gd").DATA[district]
  var city=preload("res://scripts/island_journey.gd").city_level(game)
  if city<int(data.level):system.host.show_toast("%s terbuka di Level %d."%[data.name,data.level])
  else:
   system.host.set_meta("selected_region",district);system.host.switch_tab("kawasan")
  return
 var tree=farm.wild_tree_at(at)
 if tree>=0:
  system.enqueue({"action":"chop","target":"tree","index":tree},not system.append_jobs)
  return
 if not FLOW.active(game):
  var upgrades=preload("res://scripts/building_upgrades.gd")
  var boulder=upgrades.boulder_at(farm,at)
  if boulder>=0:
   system.enqueue(upgrades.node_job(game,boulder),not system.append_jobs)
   return
 # Only objects actually present in the small farm receive interactions.
 for i in game.plots.size():
  if not game.plots[i].unlocked and (not game.feature_unlocked("expansion") or i!=next_land(game)): continue
  var diff: Vector2=(at-farm.plot_center(i)).abs()
  var purchase_marker = Rect2(farm.plot_center(i) - Vector2(64, 103), Vector2(128, 56))
  if diff.x/90+diff.y/55>1 and (game.plots[i].unlocked or not purchase_marker.has_point(at)): continue
  if not game.plots[i].unlocked:
   system.host.on_plot_pressed(i)
   return
  FLOW.selected(game,i)
  if game.is_ready(i):
   system.enqueue(system.actions.plot_job("harvest",i),not system.append_jobs)
  elif game.plots[i].crop=="":
   if not FLOW.active(game) or game.ftue.step=="plant": system.ui.open_seed_picker(i)
  elif FLOW.active(game): system.host.show_toast("Leher gandum mulai tumbuh. Tunggu tanda SIAP untuk memanen.")
  else: system.enqueue(system.actions.plot_job("water",i),not system.append_jobs)
  return
 if not game.visitor_request.is_empty() and Rect2(farm.visitor_world_position()-Vector2(65,120),Vector2(130,150)).has_point(at):
  system.enqueue({"action":"open","target":"position","key":"pengunjung","position":[farm.visitor_world_position().x,farm.visitor_world_position().y]},not system.append_jobs)
  return
 # All visible core buildings have a full illustrated hit area, including empty pens.
 for pair in [["dapur","rumah"],["pasar","pasar"],["gudang","gudang"],["ayam","ayam"],["sapi","sapi"],["babi","babi"],["kambing","kambing"],["roti","roti"],["susu","susu"],["pakan","pakan"]]:
  var key=str(pair[0])
  if key not in ["dapur","gudang","pasar","ayam","sapi","babi","kambing","pakan"] and key not in farm.editable_keys():continue
  var art=preload("res://scripts/asset_projection.gd").info(farm,key,farm.object_position(key))
  if not art.is_empty() and art.bounds.grow(8).has_point(at):
   system.host.switch_tab(str(pair[1]));return
 if not FLOW.active(game):
  for index in game.orchard.size():
   if str(game.orchard[index].fruit).is_empty(): continue
   var center: Vector2 = farm.orchard_center(index)
   if Rect2(center-Vector2(80,160),Vector2(160,185)).has_point(at):
    system.host.switch_tab("kebun_buah")
    return
 system.enqueue({"action":"move","target":"position","position":[at.x,at.y]},not system.append_jobs)
static func next_land(game) -> int:
 for i in game.plots.size():
  if not game.plots[i].unlocked: return i
 return -1
