extends Control
var host
var selected="spring"
var stage: Control
var world: Node2D
var backdrop: Sprite2D
var painter: Node2D
var heading: Label
var description: Label
var enter_button: Button
var tabs: Array[Button]=[]
var previous_modal=false
var previous_obscured=false
var restored=false
var zoom=0.12
var dragging=false
func _ready() -> void:
 name="IslandSeasonPreview"
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 z_index=120
 previous_modal=bool(host.get_meta("first_farm_modal",false))
 previous_obscured=host.farm.panel_obscured
 host.set_meta("first_farm_modal",true);host.farm.set_panel_obscured(true)
 var paper=ColorRect.new();paper.color=Color("fff6df");paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(paper)
 heading=host.label(self,"Pratinjau Pulau",Vector2(18,14),Vector2(650,48),31,host.GREEN,true)
 description=host.label(self,"",Vector2(18,65),Vector2(650,68),18,host.INK)
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 stage=Control.new();stage.name="PreviewViewport";stage.clip_contents=true;stage.mouse_filter=Control.MOUSE_FILTER_STOP;stage.gui_input.connect(input_preview);add_child(stage)
 var sky=ColorRect.new();sky.color=Color("92d9ee");sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);sky.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.add_child(sky)
 world=Node2D.new();stage.add_child(world)
 backdrop=Sprite2D.new();backdrop.centered=false;backdrop.show_behind_parent=true
 backdrop.texture=load("res://assets/world_background/summer_island_v2.png")
 backdrop.scale=host.farm.WORLD_SIZE/backdrop.texture.get_size()
 backdrop.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var detail=ShaderMaterial.new();detail.shader=load("res://assets/world_background/terrain_detail.gdshader")
 detail.set_shader_parameter("grass_detail",load("res://assets/cheerful/grass.png"))
 detail.set_shader_parameter("water_detail",load("res://assets/terrain_kit/materials/river_water.png"))
 backdrop.material=detail
 painter=preload("res://scripts/island_preview_canvas.gd").new();painter.farm=host.farm
 world.add_child(backdrop)
 var terrain=preload("res://scripts/reference_terrain.gd")
 for path in terrain.bridge_paths():
  var bridge=Sprite2D.new();bridge.texture=load("res://assets/world_background/elemen/jembatan-individual/jembatan-1.png")
  bridge.position=(path[0]+path[1])*0.5/terrain.SOURCE*host.farm.WORLD_SIZE
  var width=(path[1].x-path[0].x)/terrain.SOURCE.x*host.farm.WORLD_SIZE.x*1.9
  bridge.scale=Vector2(width,width*0.55)/bridge.texture.get_size()
  world.add_child(bridge)
 world.add_child(painter)
 for i in 4:
  var id=preload("res://scripts/island_journey.gd").ORDER[i]
  var tab=host.button(self,["Summer","Spring","Autumn","Winter"][i],Vector2.ZERO,Vector2(100,46),host.GREEN,Color.WHITE,19)
  tab.pressed.connect(show_season.bind(id));tabs.append(tab)
 var close=host.button(self,"Kembali ke Kebun",Vector2.ZERO,Vector2(300,48),host.GREEN,Color.WHITE,20);close.name="ClosePreview";close.pressed.connect(close_preview)
 enter_button=host.button(self,"Masuk Pulau",Vector2.ZERO,Vector2(300,48),host.GREEN,Color.WHITE,20);enter_button.name="EnterPreviewIsland"
 enter_button.pressed.connect(func():
  var target=selected
  restore();queue_free();preload("res://scripts/island_journey.gd").enter(host,target))
 var plus=host.button(self,"+",Vector2(18,132),Vector2(46,40),host.GREEN,Color.WHITE,23);plus.name="PreviewZoomIn";plus.pressed.connect(func():zoom_at(stage.size*0.5,zoom*1.35))
 var minus=host.button(self,"−",Vector2(72,132),Vector2(46,40),host.GREEN,Color.WHITE,23);minus.name="PreviewZoomOut";minus.pressed.connect(func():zoom_at(stage.size*0.5,zoom/1.35))
 resized.connect(arrange)
 arrange();show_season(selected)
func arrange() -> void:
 if stage==null:return
 heading.size=Vector2(size.x-36,48);description.size=Vector2(size.x-36,60)
 heading.set_meta("typography_extent",heading.size);description.set_meta("typography_extent",description.size)
 stage.position=Vector2(16,180);stage.size=Vector2(size.x-32,maxf(240,size.y-355))
 for i in tabs.size():tabs[i].position=Vector2(16+i*(size.x-32)/4,size.y-155);tabs[i].size=Vector2((size.x-44)/4,46)
 get_node("ClosePreview").position=Vector2(16,size.y-85);get_node("ClosePreview").size=Vector2((size.x-44)*0.5,50)
 enter_button.position=Vector2(size.x*0.5+6,size.y-85);enter_button.size=Vector2((size.x-44)*0.5,50)
 fit_world()
func fit_world() -> void:
 zoom=minf(stage.size.x/host.farm.WORLD_SIZE.x,stage.size.y/host.farm.WORLD_SIZE.y)
 world.scale=Vector2.ONE*zoom;world.position=(stage.size-host.farm.WORLD_SIZE*zoom)*0.5
func show_season(id: String) -> void:
 selected=id
 painter.season_id=id;painter.queue_redraw()
 backdrop.material.set_shader_parameter("island_season",["spring","summer","autumn","winter"].find(id))
 heading.text="Pratinjau · "+str(preload("res://scripts/four_seasons.gd").DATA[id].name)
 var journey=preload("res://scripts/island_journey.gd")
 var unlocked=journey.can_enter(host.game,id)
 enter_button.disabled=not unlocked
 enter_button.text="Masuk Pulau" if unlocked else "Pulau Terkunci"
 description.text="Geser dan perbesar untuk melihat pulau. Pratinjau tidak mengubah progres kebun."
 if not unlocked:
  var previous=journey.ORDER[maxi(0,journey.ORDER.find(id)-1)]
  description.text="Pratinjau saja · Buka 25/25 kawasan %s untuk masuk. Geser atau perbesar peta."%preload("res://scripts/four_seasons.gd").DATA[previous].name
 for i in tabs.size():tabs[i].modulate=Color.WHITE if journey.ORDER[i]==id else Color(0.76,0.82,0.75)
func zoom_at(at: Vector2,value: float) -> void:
 var anchor=(at-world.position)/zoom
 zoom=clampf(value,minf(stage.size.x/host.farm.WORLD_SIZE.x,stage.size.y/host.farm.WORLD_SIZE.y),0.8)
 world.scale=Vector2.ONE*zoom;world.position=at-anchor*zoom
func input_preview(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
  elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom_at(event.position,zoom*1.20)
  elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom_at(event.position,zoom/1.20)
 elif event is InputEventMouseMotion and dragging:world.position+=event.relative
 elif event is InputEventScreenDrag:world.position+=event.relative
 stage.accept_event()
func restore() -> void:
 if restored or not is_instance_valid(host):return
 restored=true
 host.set_meta("first_farm_modal",previous_modal);host.farm.set_panel_obscured(previous_obscured)
func close_preview() -> void:
 restore();queue_free()
func _exit_tree() -> void:restore()
