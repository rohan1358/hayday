extends Node
## Presentation-only ID/EN localization. IDs, economy, save values and player names stay untouched.
signal language_changed(code)
const CONFIG="user://garden_language.cfg"
static var locale="id"
static var catalog: Dictionary={}
static var pattern: RegEx
static var cache: Dictionary={}
var nodes: Dictionary={}
func _ready():
 process_priority=1000
 var cfg=ConfigFile.new()
 if cfg.load(CONFIG)==OK: locale=str(cfg.get_value("language","locale","id"))
 if locale not in ["id","en"]: locale="id"
 TranslationServer.set_locale(locale)
 initialize()
 get_tree().node_added.connect(track)
 visit(get_tree().root)
static func initialize():
 if not catalog.is_empty(): return
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/locales/en.json"))
 catalog=data if data is Dictionary else {"exact":{},"phrases":{},"words":{}}
 var keys=catalog.phrases.keys();keys.sort_custom(func(a,b): return str(a).length()>str(b).length())
 pattern=RegEx.new();pattern.compile("(?i)\\b(?:"+"|".join(keys)+")\\b|[\\p{L}]+(?:-[\\p{L}]+)?")
static func match_case(value: String,source: String) -> String:
 if source==source.to_upper(): return value.to_upper()
 if source.substr(0,1)==source.substr(0,1).to_upper(): return value.substr(0,1).to_upper()+value.substr(1)
 return value
static func text(source: String) -> String:
 if locale!="en" or source.is_empty(): return source
 if cache.has(source): return cache[source]
 initialize()
 var normalized=source.to_lower()
 for key in catalog.exact:
  if str(key).to_lower()==normalized:
   var translated=match_case(str(catalog.exact[key]),source);cache[source]=translated;return translated
 var result="";var cursor=0
 for found in pattern.search_all(source):
  result+=source.substr(cursor,found.get_start()-cursor)
  var word=found.get_string();var lower=word.to_lower()
  var translated=str(catalog.phrases.get(lower,catalog.words.get(lower,word)))
  result+=match_case(translated,word);cursor=found.get_end()
 result+=source.substr(cursor)
 if cache.size()>4096: cache.clear()
 cache[source]=result
 return result
func set_language(code: String) -> bool:
 if code not in ["id","en"]: return false
 var previous=locale;locale=code
 var cfg=ConfigFile.new();cfg.set_value("language","locale",locale)
 if cfg.save(CONFIG)!=OK: locale=previous;return false
 TranslationServer.set_locale(locale)
 for key in nodes.keys():
  var ref=nodes.get(key)
  if ref!=null: apply(ref.get_ref())
 language_changed.emit(code)
 return true
func visit(node):
 track(node)
 for child in node.get_children(): visit(child)
func track(node):
 if not node is Control: return
 var id=node.get_instance_id();nodes[id]=weakref(node)
 node.tree_exiting.connect(func(): nodes.erase(id),CONNECT_ONE_SHOT)
 apply_id.call_deferred(id)
func apply_id(id: int):
 var ref=nodes.get(id)
 if ref!=null: apply(ref.get_ref())
func update_property(node,key: String):
 var source=str(node.get(key));var saved=node.get_meta("language_"+key,{})
 if locale=="id":
  if not saved.is_empty() and source==str(saved.get("translated","")) and source!=str(saved.get("source",source)):
   node.set(key,str(saved.source));node.set_meta("language_"+key,{"source":saved.source,"translated":saved.source})
  return
 if source==str(saved.get("translated","")): return
 if saved is Dictionary and source==str(saved.get("translated","")): source=str(saved.get("source",source))
 var translated=text(source)
 node.set_meta("language_"+key,{"source":source,"translated":translated})
 if node.get(key)!=translated: node.set(key,translated)
func apply(node):
 if not is_instance_valid(node) or not node is Control or node.is_queued_for_deletion(): return
 if node is OptionButton:
  var items: Dictionary=node.get_meta("language_items",{})
  for i in node.item_count:
   var source=node.get_item_text(i);var saved=items.get(i,{})
   if source==str(saved.get("translated","")): source=str(saved.get("source",source))
   var translated=text(source);items[i]={"source":source,"translated":translated}
   if node.get_item_text(i)!=translated: node.set_item_text(i,translated)
  node.set_meta("language_items",items)
 elif node is Label or node is Button or node is RichTextLabel: update_property(node,"text")
 if not node.tooltip_text.is_empty() or node.has_meta("language_tooltip_text"): update_property(node,"tooltip_text")
 if node is LineEdit: update_property(node,"placeholder_text")
func _process(_delta):
 for key in nodes.keys():
  var ref=nodes.get(key)
  var node=ref.get_ref() if ref!=null else null
  if is_instance_valid(node) and node.is_visible_in_tree(): apply(node)
