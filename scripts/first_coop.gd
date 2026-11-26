extends RefCounted
const FLOW=preload("res://scripts/first_farm.gd")
static func built(game) -> bool: return FLOW.enabled(game) and bool(game.ftue.get("coop_built",false))
static func build(game) -> bool:
 if not FLOW.enabled(game) or FLOW.active(game) or game.level<3 or built(game) or game.coins<80: return false
 game.coins-=80
 game.ftue.coop_built=true
 game.ftue.poultry_step="craft"
 game.ranch.pens.ayam.count=2
 game.ranch.production_counts.ayam=2
 game.eggs_ready_at=0
 game.save_game()
 return true
static func populate(host,list) -> void:
 var game=host.game
 host.set_meta("first_coop_controls",{})
 preload("res://scripts/ranch_presentation.gd").hero(host,list,"ayam")
 host.callout(list,"PETERNAKAN PERTAMAMU", "Gandum bukan hanya untuk dijual, lho!\nOlah gandum menjadi pakan ayam.",Color("fff1c7"))
 var card=host.row_card(list,190,Color("eaf4dd"))
 var preview=TextureRect.new()
 preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 preview.texture=game_art(host)
 preview.position=Vector2(10,8);preview.size=Vector2(170,170)
 preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 card.add_child(preview)
 host.label(card,"KANDANG AYAM · LEVEL 3",Vector2(190,22),Vector2(390,38),22,host.GREEN,true)
 host.label(card,"2 ayam pertama • Pakan dari gandum",Vector2(190,66),Vector2(390,30),17,host.INK)
 var b=host.button(card,"SUDAH DIBANGUN" if built(game) else ("BANGUN · 80 KOIN" if game.level>=3 else "TERKUNCI · LEVEL 3"),Vector2(190,112),Vector2(388,52),host.GREEN,Color.WHITE,19)
 b.disabled=game.level<3 or built(game) or game.coins<80
 b.pressed.connect(func():
  var placement=preload("res://scripts/safe_asset_placement.gd")
  var at=load("res://scripts/island_layout.gd").purchase_spot(host,"ayam")
  if at==Vector2.INF: host.show_toast("Tidak ada ruang untuk kandang ayam. Rapikan lahan dahulu.");return
  if build(game):
   placement.commit(host,"ayam",at)
   host.farm.invalidate_scenery()
   if host.farm.hybrid_controller!=null: host.farm.hybrid_controller.animals.ensure_animals()
   host.refresh_all();host.show_sheet())
 if not built(game): return
 var actions=host.row_card(list,330,Color("fff9e8"))
 actions.add_theme_stylebox_override("panel",preload("res://scripts/ranch_presentation.gd").style(Color("fff8e4"),Color("dabe85")))
 host.label(actions,"TUGAS PETERNAKAN",Vector2(20,15),Vector2(560,35),20,host.GREEN,true)
 var craft=host.button(actions,"BUAT PAKAN · 2 GANDUM · 8 DTK",Vector2(20,65),Vector2(560,50),host.GREEN,Color.WHITE,19)
 craft.disabled=not game.can_queue_feed("pakan_ayam")
 craft.pressed.connect(func(): game.queue_feed("pakan_ayam");host.refresh_all();host.show_sheet())
 var collect=host.button(actions,"AMBIL PAKAN SIAP",Vector2(20,123),Vector2(560,50),host.GREEN,Color.WHITE,19)
 collect.disabled=not game.feed_ready()
 collect.pressed.connect(func(): game.collect_ready_feed();host.refresh_all();host.show_sheet())
 var feed=host.button(actions,"BERI PAKAN AYAM",Vector2(20,181),Vector2(560,50),host.GREEN,Color.WHITE,19)
 feed.disabled=not game.can_feed_chickens()
 feed.pressed.connect(func(): game.feed_chickens();host.refresh_all();host.show_sheet())
 var eggs=host.button(actions,"AMBIL TELUR" if game.ready_eggs() else ("TELUR · %d DTK" % maxi(0,game.eggs_ready_at-game.now()) if game.eggs_ready_at>0 else "AYAM MENUNGGU PAKAN"),Vector2(20,239),Vector2(560,50),host.GREEN,Color.WHITE,19)
 eggs.disabled=not game.ready_eggs()
 eggs.pressed.connect(func(): game.collect_eggs();host.refresh_all();host.show_sheet())
 var queue_card=host.row_card(list,85,Color("e5f4e4"))
 var queue_label=host.label(queue_card,"",Vector2(20,18),Vector2(560,50),18,host.INK)
 host.set_meta("first_coop_controls",{"craft":craft,"collect":collect,"feed":feed,"eggs":eggs,"queue":queue_label,"tasks":actions.get_child(0)})
 refresh(host)
static func refresh(host) -> void:
 var controls: Dictionary=host.get_meta("first_coop_controls",{})
 if controls.is_empty() or not is_instance_valid(controls.craft): return
 var game=host.game
 controls.craft.disabled=not game.can_queue_feed("pakan_ayam")
 controls.collect.disabled=not game.feed_ready()
 controls.feed.disabled=not game.can_feed_chickens()
 controls.eggs.disabled=not game.ready_eggs()
 controls.eggs.text="AMBIL TELUR" if game.ready_eggs() else ("TELUR · %d DTK" % maxi(0,game.eggs_ready_at-game.now()) if game.eggs_ready_at>0 else "AYAM MENUNGGU PAKAN")
 var step=str(game.ftue.get("poultry_step","craft"))
 var states=[step in ["feed","eggs","done"] or not game.feed_queue.is_empty(),step in ["feed","eggs","done"],step in ["eggs","done"],step=="done"]
 var completed=0
 for done in states:
  if done: completed+=1
 controls.tasks.text="Tugas Peternakan (%d/4)"%completed
 var buttons=[controls.craft,controls.collect,controls.feed,controls.eggs]
 for i in 4:
  preload("res://scripts/ranch_presentation.gd").task(buttons[i],states[i])
 preload("res://scripts/ranch_presentation.gd").refresh(host)
 controls.queue.tooltip_text="Gandum %d · Pakan %d · Telur %d"%[int(game.inventory.gandum),int(game.inventory.get("pakan_ayam",0)),int(game.inventory.telur)]
 controls.queue.text="Belum ada antrean pakan." if game.feed_queue.is_empty() else "%d produksi · berikutnya %d detik" % [game.feed_queue.size(),maxi(0,int(game.feed_queue[0].ready_at)-game.now())]
static func game_art(host) -> Texture2D:
 var sprite: Dictionary=host.farm.farm_art.sprites.get("chicken_coop",{})
 if sprite.is_empty(): return null
 var texture=AtlasTexture.new();texture.atlas=sprite.texture;texture.region=sprite.region
 return texture
