extends SceneTree
const W=preload("res://scripts/four_seasons.gd")
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var g=FarmGameState.new(false)
 g.save_path="user://season_migration_test.json";g.backup_path="user://season_migration_backup.json"
 g.coins=1234;g.inventory.gandum=17
 g.layout_positions.dapur=[980,600];g.layout_positions.region_pelabuhan=[5160,3920]
 assert(W.migrate(g))
 assert(g.coins==1234 and g.inventory.gandum==17)
 assert(Vector2(g.layout_positions.dapur[0],g.layout_positions.dapur[1])==Vector2(980,600))
 assert(g.world_regions.has("four_seasons_backup"))
 assert(not W.migrate(g))
 for pair in [[1,"spring"],[20,"summer"],[30,"autumn"],[36,"winter"]]:
  g.level=pair[0]
  assert(W.unlocked(g,W.DATA[pair[1]].center))
  if pair[0]>1:
   g.level=pair[0]-1
   assert(not W.unlocked(g,W.DATA[pair[1]].center))
 assert(W.river(Vector2(2160,2400)))
 assert(not W.river(Vector2(2160,3200)))
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://four_seasons_visual.json";host.game.backup_path="user://four_seasons_visual_backup.json"
 root.add_child(host)
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd") and child.opening!=null: child.opening.hide()
  if child.get_script()==load("res://scripts/farm_progression.gd"):
   child.set_process(false);child.pending.clear()
   if child.dialog!=null: child.dialog.hide()
 host.set_meta("first_farm_modal",false)
 host.game.ftue.started=true;host.game.ftue.step="done"
 assert(host.farm.WORLD_SIZE==W.SIZE)
 host.game.level=1
 var nav=host.farm.hybrid_controller.navigation
 nav.revision="";nav.ensure()
 assert(nav.blocked(W.DATA.winter.center))
 assert(not host.farm.can_place("dapur",W.DATA.winter.center))
 host.game.level=50;nav.revision="";nav.ensure()
 assert(not W.blocked(host.game,Vector2(3400,5800)))
 host.farm.hybrid_controller.data.follow=false
 host.toast_layer.hide()
 if DisplayServer.get_name()!="headless":
  for id in ["overview","spring","summer","central","autumn","winter"]:
   var target=W.SIZE*0.5 if id=="overview" else W.DATA[id].center
   var zoom=host.farm.minimum_camera_zoom() if id=="overview" else 0.65
   host.farm.camera_zoom=zoom;host.farm.zoom_target=zoom
   host.farm.camera_center=host.farm.clamp_camera_center(target,zoom);host.farm.camera_target=host.farm.camera_center
   host.farm.queue_redraw()
   for i in 8: await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/four-seasons-"+id+".png"))
 print("FOUR SEASONS PASS: 4320x7680, preserved migration, level gates, bridges, navigation and placement")
 host.queue_free();await process_frame;quit()
