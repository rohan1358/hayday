extends Sprite2D
var farm: FarmView
func _ready() -> void:
 name="HDWorldTerrain"
 show_behind_parent=true
 centered=false
 texture=load("res://assets/world_background/summer_island_v2.png")
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var detail=ShaderMaterial.new()
 detail.shader=load("res://assets/world_background/terrain_detail.gdshader")
 detail.set_shader_parameter("grass_detail",load("res://assets/cheerful/grass.png"))
 detail.set_shader_parameter("water_detail",load("res://assets/terrain_kit/materials/river_water.png"))
 material=detail
 # Independent native bridge sprites preserve plank and railing detail on zoom.
 var terrain=preload("res://scripts/reference_terrain.gd")
 terrain.bridge_game=farm.game
 for i in terrain.bridge_paths().size():
  var bridge=Sprite2D.new();bridge.name="RiverBridge%d"%i
  bridge.texture=load("res://assets/landmark_hd/wood_bridge.png")
  bridge.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  bridge.centered=false;add_child(bridge)
 _process(0)
func _process(_delta: float) -> void:
 sync_camera()
func sync_camera() -> void:
 if farm==null:return
 sync_bridges()
 var id=preload("res://scripts/four_seasons.gd").active_id
 material.set_shader_parameter("island_season",["spring","summer","autumn","winter"].find(id))
 var scaler=farm.size/farm.get_virtual_size()
 position=(farm.get_virtual_size()*0.5-farm.camera_center*farm.camera_zoom)*scaler
 scale=scaler*farm.camera_zoom*farm.WORLD_SIZE/texture.get_size()


func sync_bridges() -> void:
 var terrain=preload("res://scripts/reference_terrain.gd")
 var paths=terrain.bridge_paths()
 for i in paths.size():
  var bridge=get_node_or_null("RiverBridge%d"%i) as Sprite2D
  if bridge==null:continue
  var path=paths[i]
  var a=path[0]/terrain.SOURCE*texture.get_size();var b=path[1]/terrain.SOURCE*texture.get_size()
  var dim=Vector2(bridge.texture.get_size())
  var left=dim*Vector2(.08,.55);var right=dim*Vector2(.92,.82)
  var flip=preload("res://scripts/asset_edit.gd").flipped(farm.game,"bridge_%d"%i)
  if flip:left=dim*Vector2(.08,.82);right=dim*Vector2(.92,.55)
  bridge.flip_h=flip
  var span=a.distance_to(b)
  var factor=Vector2(span/(dim.x*.84),span*.60/dim.y)
  factor*=span/((right-left)*factor).length()
  var angle=(b-a).angle()-((right-left)*factor).angle()
  bridge.scale=factor;bridge.rotation=angle
  bridge.position=a-(left*factor).rotated(angle)
  bridge.set_meta("deck_left",left);bridge.set_meta("deck_right",right)
