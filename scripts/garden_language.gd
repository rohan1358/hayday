extends Node
## Presentation-only ID/EN localization. IDs, economy, save values and player names stay untouched.
signal language_changed(code)
const CONFIG="user://garden_language.cfg"
static var locale="id"
static var catalog: Dictionary={}
static var pattern: RegEx
static var cache: Dictionary={}
static var exact_index: Dictionary={}
static var id_index: Dictionary={}
static var templates: Array=[]
static var template_token:=RegEx.new()
static func escape_regex(value: String) -> String:
 var escaped=""
 for ch in value:
  if ch in "\\.^$|?*+()[]{}": escaped+="\\"
  escaped+=ch
 return escaped
static func clean(value: String) -> String:
 return value.replace("Â·","·").replace("âœ“","✓").replace("â€¢","•").replace("â€™","’").replace("â€“","–").replace("â€¦","…")
static func add_template(source: String,target: String,language: String="en"):
 var matches=template_token.search_all(source)
 if matches.is_empty() or matches.size()!=template_token.search_all(target).size(): return
 if template_token.sub(source,"",true).strip_edges().length()<3: return
 var expression="(?is)^";var cursor=0
 for found in matches:
  expression+=escape_regex(source.substr(cursor,found.get_start()-cursor).replace("%%","%"))
  var spec=found.get_string()
  expression+="(-?[0-9]+)" if spec.ends_with("d") else ("(-?[0-9]+(?:[.,][0-9]+)?)" if spec.ends_with("f") else "(.*?)")
  cursor=found.get_end()
 expression+=escape_regex(source.substr(cursor).replace("%%","%"))+"$"
 var regex=RegEx.new()
 if regex.compile(expression)==OK:
  templates.append({"regex":regex,"source":source,"target":target,"matches":matches.size(),"language":language})

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
 template_token.compile("%[0-9.]*[dsf]")
 for key in catalog.exact:
  var source=clean(str(key));var target=clean(str(catalog.exact[key]))
  exact_index[source.to_lower()]=target
  add_template(source,target)
 for key in catalog.get("id_exact",{}):
  var source=clean(str(key));var target=clean(str(catalog.id_exact[key]))
  id_index[source.to_lower()]=target
  add_template(source,target,"id")
 templates.sort_custom(func(a,b): return str(a.source).length()>str(b.source).length())
 var keys=catalog.phrases.keys();keys.sort_custom(func(a,b): return str(a).length()>str(b).length())
 var escaped=PackedStringArray()
 for key in keys: escaped.append(escape_regex(str(key)))
 pattern=RegEx.new();pattern.compile("(?i)\\b(?:"+"|".join(escaped)+")\\b|[\\p{L}]+(?:-[\\p{L}]+)?")
static func match_case(value: String,source: String) -> String:
 if source==source.to_upper(): return value.to_upper()
 if source.substr(0,1)==source.substr(0,1).to_upper(): return value.substr(0,1).to_upper()+value.substr(1)
 return value
static func text(source: String) -> String:
 if source.is_empty(): return source
 initialize()
 if cache.has(source): return cache[source]
 var normalized=clean(source)
 var lower=normalized.to_lower()
 var entries: Dictionary=catalog.exact if locale=="en" else catalog.get("id_exact",{})
 var lookup: Dictionary=exact_index if locale=="en" else id_index
 if entries.has(normalized): return remember(source,clean(str(entries[normalized])))
 if lookup.has(lower): return remember(source,match_case(str(lookup[lower]),normalized))
 for entry in templates:
  if entry.language!=locale: continue
  var found: RegExMatch=entry.regex.search(normalized)
  if found==null: continue
  var target: String=entry.target
  var result="";var cursor=0;var index=1
  for token in template_token.search_all(target):
   if index>entry.matches: break
   result+=target.substr(cursor,token.get_start()-cursor).replace("%%","%")
   var argument=found.get_string(index)
   if token.get_string().ends_with("s") and argument!=normalized and not str(entry.source).begins_with("Identitas akun kebun ini:"): argument=text(argument)
   result+=argument
   cursor=token.get_end();index+=1
  result+=target.substr(cursor).replace("%%","%")
  return remember(source,result)
 if locale=="id": return remember(source,normalized)
 var result="";var cursor=0
 for found in pattern.search_all(normalized):
  result+=normalized.substr(cursor,found.get_start()-cursor)
  var word=found.get_string();var key=word.to_lower()
  var translated=str(catalog.phrases.get(key,catalog.words.get(key,word)))
  result+=match_case(translated,word);cursor=found.get_end()
 result+=normalized.substr(cursor)
 return remember(source,result)
static func remember(source: String,translated: String) -> String:
 if cache.size()>4096: cache.clear()
 cache[source]=translated
 return translated
func set_language(code: String) -> bool:
 if code not in ["id","en"]: return false
 var previous=locale;locale=code
 var cfg=ConfigFile.new();cfg.set_value("language","locale",locale)
 if cfg.save(CONFIG)!=OK: locale=previous;return false
 cache.clear()
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
 if not (node is Control or node is Window or node is Label3D): return
 var id=node.get_instance_id()
 if nodes.has(id): return
 nodes[id]=weakref(node)
 node.tree_exiting.connect(func(): nodes.erase(id),CONNECT_ONE_SHOT)
 apply_id.call_deferred(id)
func apply_id(id: int):
 var ref=nodes.get(id)
 if ref!=null: apply(ref.get_ref())
func update_property(node,key: String):
 var source=str(node.get(key));var saved=node.get_meta("language_"+key,{})
 if saved.get("locale","")==locale and source==str(saved.get("translated","")): return
 if not saved.is_empty() and source==str(saved.get("translated","")):
  source=str(saved.get("source",source))
 var translated=text(source)
 node.set_meta("language_"+key,{"source":source,"translated":translated,"locale":locale})
 if str(node.get(key))!=translated: node.set(key,translated)
func apply(node):
 if not is_instance_valid(node) or node.is_queued_for_deletion(): return
 if node.get_meta("skip_localization",false): return
 if node is Label3D:
  update_property(node,"text")
  return
 if node is AcceptDialog:
  update_property(node,"title")
  update_property(node,"dialog_text")
  update_property(node,"ok_button_text")
  if node is ConfirmationDialog: update_property(node,"cancel_button_text")
  return
 if node is Window:
  update_property(node,"title")
  return
 if not node is Control or node.get_meta("skip_localization",false): return
 if node is Button and node.get_parent() is AcceptDialog: return
 if node is OptionButton:
  var items: Dictionary=node.get_meta("language_items",{})
  for i in node.item_count:
   var source=node.get_item_text(i);var saved=items.get(i,{})
   if saved.get("locale","")==locale and source==str(saved.get("translated","")): continue
   if source==str(saved.get("translated","")): source=str(saved.get("source",source))
   var translated=text(source);items[i]={"source":source,"translated":translated,"locale":locale}
   if node.get_item_text(i)!=translated: node.set_item_text(i,translated)
  node.set_meta("language_items",items)
 elif node is Label or node is Button or node is RichTextLabel: update_property(node,"text")
 if not node.tooltip_text.is_empty() or node.has_meta("language_tooltip_text"): update_property(node,"tooltip_text")
 if node is LineEdit: update_property(node,"placeholder_text")
func _process(_delta):
 for key in nodes.keys():
  var ref=nodes.get(key)
  var node=ref.get_ref() if ref!=null else null
  if is_instance_valid(node) and (node.visible if node is Window else node.is_visible_in_tree()): apply(node)
