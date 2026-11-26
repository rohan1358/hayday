extends RefCounted
const R=preload("res://scripts/ranch_state.gd")
const ICON=preload("res://scripts/colorful_icons.gd")
const RESULTS={"ayam":"Telur","sapi":"Susu","babi":"Daging Babi","kambing":"Susu Kambing"}
static func style(color: Color,border: Color,radius: int=24) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=color;s.border_color=border;s.set_border_width_all(3);s.set_corner_radius_all(radius)
 s.shadow_color=Color(0.25,0.15,0.04,0.18);s.shadow_size=4
 return s
static func art(host,parent,key: String,at: Vector2,dimensions: Vector2):
 host.farm.farm_art.ensure_reference(key)
 var sprite: Dictionary=host.farm.farm_art.sprites.get(key,{})
 if sprite.is_empty(): return ICON.add(parent,key,at,dimensions)
 var image=TextureRect.new();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 var texture=AtlasTexture.new();texture.atlas=sprite.texture;texture.region=sprite.region
 image.texture=texture;image.position=at;image.size=dimensions;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(image);return image
static func hero(host,list,species: String):
 var card=host.row_card(list,276,Color("f5e5ae"))
 card.name="RanchJourney_"+species
 card.add_theme_stylebox_override("panel",style(Color("fff3cf"),Color("e2bd78")))
 var backdrop=TextureRect.new();backdrop.texture=load("res://assets/cheerful/countryside.png")
 backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 backdrop.position=Vector2(4,4);backdrop.size=Vector2(601,162);backdrop.modulate=Color(1,1,1,0.65)
 backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(backdrop)
 var labels=["Bangun\nKandang","Buat\nPakan","Kumpulkan\n"+RESULTS[species]]
 for i in 3:
  var x=25+i*202
  var plate=Panel.new();plate.position=Vector2(x+22,13);plate.size=Vector2(112,100)
  plate.add_theme_stylebox_override("panel",style(Color("fff1ba"),Color("fffce6"),48));card.add_child(plate)
  if i==0: art(host,card,R.INFO[species].asset,Vector2(x+24,15),Vector2(108,94))
  else:
   var icon=ICON.add(card,"ranch_feed" if i==1 else ("ranch_eggs" if species=="ayam" else "susu"),Vector2(x+40,24),Vector2(78,78))
   if i==2 and species=="babi": icon.texture=load("res://assets/production_icons/bacon.svg")
  host.label(card,labels[i],Vector2(x,115),Vector2(160,80),18,Color("304d24"),true).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var check=host.label(card,"",Vector2(x+117,5),Vector2(38,35),27,Color("218b38"),true)
  check.name="Step"+str(i)
  if i<2: host.label(card,"›",Vector2(x+170,58),Vector2(32,50),45,Color("4a9d2a"),true)
 var bar=ProgressBar.new();bar.name="RanchProgress";bar.position=Vector2(30,224);bar.size=Vector2(548,32)
 bar.max_value=3;bar.show_percentage=false
 bar.add_theme_stylebox_override("background",style(Color("dfcfac"),Color("fffbea"),16))
 bar.add_theme_stylebox_override("fill",style(Color("51b82a"),Color("b7e375"),16));card.add_child(bar)
 var counter=host.label(card,"",Vector2(30,223),Vector2(548,34),21,Color("284f21"),true)
 counter.name="RanchCounter";counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var entries: Array=host.get_meta("ranch_heroes",[]);entries.append({"card":card,"species":species});host.set_meta("ranch_heroes",entries)
 refresh(host)
static func refresh(host):
 for entry in host.get_meta("ranch_heroes",[]):
  if not is_instance_valid(entry.card): continue
  var g=host.game;var species=str(entry.species)
  var owned=R.available(g,species)
  var feeding=false;var result=false
  if species=="ayam":
   var step=str(g.ftue.get("poultry_step",""))
   feeding=int(g.inventory.get("pakan_ayam",0))>0 or not g.feed_queue.is_empty() or g.eggs_ready_at>0 or step=="done"
   result=step=="done" or g.ready_eggs()
  elif species=="sapi":
   feeding=int(g.inventory.get("pakan_sapi",0))>0 or g.cow_ready_at>0
   result=g.cow_milk_ready() or int(g.inventory.get("susu",0))>0
  else:
   feeding=owned and not g.animal_hungry(species)
   result=owned and g.animal_ready(species)
  var states=[owned,owned and feeding,owned and result];var count=0
  for i in 3:
   if states[i]: count+=1
   entry.card.get_node("Step"+str(i)).text="✓" if states[i] else ""
  entry.card.get_node("RanchProgress").value=count
  entry.card.get_node("RanchCounter").text="%d / 3"%count
static func task(button: Button,done: bool):
 for state in ["normal","hover","pressed","disabled"]:
  button.add_theme_stylebox_override(state,style(Color("d4e8ad") if done else Color("fff5da"),Color("d8bd88"),17))
 button.add_theme_color_override("font_color",Color("354c25"))
 button.add_theme_color_override("font_disabled_color",Color("537343") if done else Color("897b5f"))
 var mark=button.get_node_or_null("TaskState")
 if mark==null:
  mark=Label.new();mark.name="TaskState";mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
  mark.position=Vector2(512,5);mark.size=Vector2(37,37);mark.add_theme_font_size_override("font_size",26)
  button.add_child(mark)
 mark.text="✓" if done else "›"
 mark.add_theme_color_override("font_color",Color("218631") if done else Color("9d733c"))
 button.alignment=HORIZONTAL_ALIGNMENT_LEFT
 button.add_theme_constant_override("outline_size",0)
