extends Node
## Shared typography for scenes, deferred UI, tooltips and world-space labels.
## Set typography_role before add_child for explicit semantics; size stays layout-owned.
const THEME=preload("res://assets/fonts/garden_theme.tres")
const TITLE=preload("res://assets/fonts/styles/lilita_title.tres")
const BOLD=preload("res://assets/fonts/styles/fredoka_bold.tres")
const SEMIBOLD=preload("res://assets/fonts/styles/fredoka_semibold.tres")
const BODY=preload("res://assets/fonts/styles/nunito_semibold.tres")
const VARIATIONS={"title":"GardenTitle","heading":"GardenHeading","subtitle":"GardenSubtitle","body":"GardenBody","price":"GardenPrice","button":"GardenButton","tab":"GardenTab"}
const SIZES={"title":34,"heading":24,"subtitle":20,"body":18,"price":22,"button":20,"tab":18}
var pending: Dictionary={}
func _ready():
 get_tree().node_added.connect(added)
 visit(get_tree().root)
func visit(node):
 apply(node)
 for child in node.get_children(): visit(child)
func added(node): apply.call_deferred(node)
static func role(node: Control,id: String):
 node.set_meta("typography_role",id)
 node.theme_type_variation=VARIATIONS.get(id,"GardenBody")
static func font_for(id: String) -> Font:
 if id=="title": return TITLE
 if id in ["heading","price","button"]: return BOLD
 if id in ["subtitle","tab"]: return SEMIBOLD
 return BODY
static func infer(node: Control) -> String:
 if node is BaseButton and (str(node.name).begins_with("ShopTab") or node.has_meta("tab_id")): return "tab"
 if node is Label and node.name=="Caption" and node.get_parent()!=null and node.get_parent().has_meta("tab_id"): return "subtitle"
 if node.has_meta("typography_role"): return str(node.get_meta("typography_role"))
 if node is BaseButton:
  return "tab" if str(node.name).begins_with("ShopTab") or node.has_meta("tab_id") else "button"
 if node is Label:
  var text=node.text.strip_edges()
  var size=node.get_theme_font_size("font_size")
  if node.name in ["DynamicLevelNumber","LevelMissionReward"]: return "price"
  if size>=30 and text.length()<70 and not text.contains("\n"): return "title"
  if (text.contains("XP") or text.contains("LV ") or text.is_valid_int() or text.is_valid_float()) and text.length()<40: return "price"
  if size>=21 and text.length()<65 and not text.contains("\n"): return "heading"
  return "subtitle" if text.length()<35 and not text.contains("\n") else "body"
 return "body"
func apply(node):
 if not is_instance_valid(node) or not node is Control or node.has_meta("typography_applied"): return
 node.set_meta("typography_applied",true)
 if not (node is Label or node is BaseButton or node is LineEdit or node is TextEdit or node is RichTextLabel or node is ProgressBar): return
 # Clear obsolete font overrides; preserve colors, illustrations, hit targets and sizes.
 for key in ["font","normal_font","bold_font","italics_font","bold_italics_font","mono_font"]:
  if node.has_theme_font_override(key): node.remove_theme_font_override(key)
 if node is Label or node is Button:
  var id=infer(node)
  role(node,id)
  var current=maxi(16,node.get_theme_font_size("font_size"))
  if node.get_theme_font_size("font_size")<16: node.add_theme_font_size_override("font_size",16)
  node.set_meta("typography_base_size",current)
  if node is Button and not node.get_meta("typography_left_aligned",false): node.alignment=HORIZONTAL_ALIGNMENT_CENTER
  node.resized.connect(schedule.bind(node))
  node.minimum_size_changed.connect(schedule.bind(node))
  schedule(node)
func schedule(node):
 if not is_instance_valid(node) or node.is_queued_for_deletion() or node.get_meta("typography_fitting",false) or pending.has(node.get_instance_id()): return
 var id=node.get_instance_id()
 pending[id]=weakref(node)
 fit.call_deferred(id)
func fit(id: int):
 var ref=pending.get(id);pending.erase(id)
 var node=ref.get_ref() if ref!=null else null
 if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_inside_tree() or node.size.x<10: return
 node.set_meta("typography_fitting",true)
 fit_control(node)
 if is_instance_valid(node): node.set_meta("typography_fitting",false)
func fit_control(node):
 var role_id=str(node.get_meta("typography_role","body"))
 var base=int(node.get_meta("typography_base_size",SIZES.get(role_id,18)))
 var font: Font=font_for(role_id)
 var size=base
 if node is Button:
  if node.text.is_empty(): return
  var style=node.get_theme_stylebox("normal")
  var width=node.size.x-maxf(12,style.get_minimum_size().x)
  if node.icon!=null and node.vertical_icon_alignment==VERTICAL_ALIGNMENT_CENTER:
   width-=float(node.get_theme_constant("icon_max_width"))+node.get_theme_constant("h_separation")
  var longest=0.0
  for line in node.text.split("\n"): longest=maxf(longest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
  # Fit only within 15%; longer captions wrap instead of becoming tiny.
  var minimum=maxi(16,int(base*0.85))
  while size>minimum and longest>width:
   size-=1;longest=0
   for line in node.text.split("\n"): longest=maxf(longest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
  if longest>width+1 and node.size.x>=100 and node.size.y>=42:
   if node.autowrap_mode!=TextServer.AUTOWRAP_WORD_SMART: node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  if node.get_theme_font_size("font_size")!=size: node.add_theme_font_size_override("font_size",size)
 elif node is Label:
  if node.autowrap_mode==TextServer.AUTOWRAP_OFF and node.text.contains("\n"): return
  # Layout helpers provide the intended width before text computes its minimum.
  if node.has_meta("typography_extent"):
   var extent: Vector2=node.get_meta("typography_extent")
   var width=extent.x
   var measured=font.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
   if node.autowrap_mode==TextServer.AUTOWRAP_OFF and measured>width+1 and width>=100 and extent.y>=36:
    if node.autowrap_mode!=TextServer.AUTOWRAP_WORD_SMART: node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   if node.autowrap_mode==TextServer.AUTOWRAP_OFF and measured>width+1:
    var minimum=maxi(16,int(base*0.85))
    while size>minimum and font.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:
     size-=1
    if node.get_theme_font_size("font_size")!=size: node.add_theme_font_size_override("font_size",size)
   node.size=extent
