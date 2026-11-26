extends RefCounted
static func guide(host):
 for node in host.get_children():
  if node.get_script()==load("res://scripts/first_farm_ui.gd"): return node
 return null
static func action(host,list,title: String,callback: Callable,enabled: bool=true) -> Button:
 var card=host.row_card(list,78,Color("fff3d0"))
 var b=host.button(card,title,Vector2(14,10),Vector2(575,56),host.GREEN,Color.WHITE,19)
 b.disabled=not enabled;b.pressed.connect(callback)
 return b
static func beginner(host,list) -> void:
 preload("res://scripts/reward_menu.gd").populate(host,list)
static func collection(host,list) -> void:
 preload("res://scripts/collection_hub.gd").populate(host,list)
static func owned_assets(host,list) -> void:
 host.callout(list,"ASET MILIKMU","Semua pembelian dekorasi tersimpan di sini, termasuk yang belum dipasang.",Color("fff0cd"))
 for item in host.game.decorations:
  var kind=str(item.get("kind",""))
  var stored=(item.get("position",[]) as Array).is_empty()
  var row=host.row_card(list,100,Color("e7efdb"))
  var sprite: Dictionary=host.farm.farm_art.sprites.get(kind,{})
  if not sprite.is_empty():
   var texture=AtlasTexture.new();texture.atlas=sprite.texture;texture.region=sprite.region
   var image=TextureRect.new();image.texture=texture;image.position=Vector2(12,8);image.size=Vector2(84,84)
   image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   row.add_child(image)
  host.label(row,str(host.game.DECORATIONS.get(kind,{}).get("name",kind))+(" · TERSIMPAN" if stored else " · TERPASANG"),Vector2(110,6),Vector2(475,40),18,host.GREEN,true)
  var b=host.button(row,"PASANG" if stored else "LIHAT DI KEBUN",Vector2(110,50),Vector2(475,40),host.GREEN,Color.WHITE,17)
  var key=str(item.key)
  b.pressed.connect(func():
   if stored: host.begin_decoration_from_inventory(key)
   else:
    host.switch_tab("kebun");host.farm.hybrid_controller.data.follow=false
    host.farm.camera_target=host.farm.object_position(key);host.farm.clamp_camera_target())
 for id in host.game.constructions:
  if int(host.game.constructions[id])<=0: continue
  var info=host.game.CONSTRUCTIONS.get(id,{})
  var row=host.row_card(list,65,Color("fff0cd"))
  host.label(row,str(info.get("name",id))+" · DIMILIKI ×"+str(host.game.constructions[id]),Vector2(14,10),Vector2(570,42),18,host.GREEN,true)
static func settings(host,list) -> void:
 preload("res://scripts/settings_ui.gd").populate(host,list)
static func reload_layout(host) -> void:
 host.game.save_game()
 if host.get_tree().current_scene==host: host.get_tree().call_deferred("reload_current_scene")
 else:
  host.farm.ujang_position=Vector2(host.game.hybrid.player[0],host.game.hybrid.player[1])
  host.farm.reset_camera();host.farm.invalidate_scenery();host.switch_tab("kebun")
