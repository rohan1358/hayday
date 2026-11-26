extends SceneTree
const T=preload("res://scripts/reference_terrain.gd")
const W=preload("res://scripts/four_seasons.gd")
const J=preload("res://scripts/island_journey.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://preview_ambience_test.json";host.game.backup_path="user://preview_ambience_backup.json"
 DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
 root.add_child(host)
 var navigation
 for child in host.get_children():
  if child.get_script()==load("res://scripts/first_farm_ui.gd"):child.start_adventure()
  if child.get_script()==load("res://scripts/farm_progression.gd"):child.set_process(false)
  if child.get_script()==load("res://scripts/four_seasons_ui.gd"):navigation=child
 host.farm.hybrid_controller.set_process(false)
 assert(not J.can_enter(host.game,"spring"))
 var before=JSON.stringify(host.game.world_regions)
 var coins=host.game.coins
 navigation.open_preview("spring")
 var preview=host.get_node("IslandSeasonPreview")
 for id in ["spring","autumn","winter"]:
  preview.show_season(id)
  assert(preview.enter_button.disabled,"Locked islands must remain unplayable in preview")
  assert(W.active_id=="summer" and J.prepare(host.game).active=="summer")
  assert(preview.painter.season_id==id)
  var value=preview.backdrop.material.get_shader_parameter("island_season")
  assert(value==["spring","summer","autumn","winter"].find(id))
  if DisplayServer.get_name()!="headless":
   for i in 10:await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/preview-"+id+".png"))
 preview.zoom_at(preview.stage.size*0.5,0.35)
 assert(preview.zoom>=0.34)
 preview.close_preview()
 await process_frame
 assert(not bool(host.get_meta("first_farm_modal",false)) and not host.farm.panel_obscured)
 assert(host.game.coins==coins and JSON.stringify(host.game.world_regions)==before,"Preview must not unlock, spend, or change saved world state")
 assert(preload("res://scripts/first_farm_world.gd").seasonal_asset("lg_blossom_tree","summer")=="colorful_oak")
 assert(preload("res://scripts/first_farm_world.gd").seasonal_asset("lg_blossom_tree","spring")=="lg_blossom_tree")
 assert(T.tree_width(0)>=280 and T.tree_bounds(Vector2.ZERO,0).size.y>140)
 var tree=host.farm.wild_tree_position(0)
 assert(host.farm.wild_tree_at(tree+Vector2(0,-140))>=0,"Enlarged tree canopy must remain tappable for chopping")
 if DisplayServer.get_name()!="headless":
  host.farm.reset_camera();host.farm.hybrid_controller.data.follow=false
  for i in 15:await process_frame
  await RenderingServer.frame_post_draw
  var life=host.farm.get_node("IslandAmbience")
  assert(not life.last_butterflies.is_empty(),"Butterflies must animate near starting beds")
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/summer-trees-butterflies.png"))
  host.farm.camera_target=Vector2(3672,1506);host.farm.camera_center=host.farm.camera_target
  host.farm.zoom_target=0.6;host.farm.camera_zoom=0.6;host.farm.queue_redraw()
  for i in 8:await process_frame
  await RenderingServer.frame_post_draw
  var first=root.get_texture().get_image()
  for i in 20:await process_frame
  await RenderingServer.frame_post_draw
  var second=root.get_texture().get_image()
  var changed=0
  var backdrop=host.farm.get_node("HDWorldTerrain")
  for y in range(1080,1390,20):
   for x in range(3500,3800,20):
    var world=Vector2(x,y)
    var pixel=Vector2i(backdrop.get_global_transform()*(world/host.farm.WORLD_SIZE*backdrop.texture.get_size()))
    if pixel.x<0 or pixel.y<150 or pixel.x>=first.get_width() or pixel.y>=first.get_height()-160:continue
    var a=first.get_pixelv(pixel);var b=second.get_pixelv(pixel)
    if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.03:changed+=1
  assert(changed>8,"Rendered waterfall must change visibly over time")
  second.save_png(ProjectSettings.globalize_path("res://../outputs/waterfall-flow.png"))
 print("PREVIEW AND AMBIENCE PASS: 3 locked season previews without save changes, season-specific starter tree, 2x wild trees/canopy hits, butterflies and animated waterfall pixels")
 host.queue_free();await process_frame;quit()
