extends RefCounted
const ORDER=["stone","brick","moss"]
const ITEMS={
	"stone":{"name":"Batu Pastel","price":3,"edge":Color("9988b1"),"fill":Color("d8cbe9"),"shine":Color("fff0c4")},
	"brick":{"name":"Bata Merah","price":5,"edge":Color("a55c52"),"fill":Color("ed9373"),"shine":Color("ffcca0")},
	"moss":{"name":"Batu Alam Berlumut","price":8,"edge":Color("75836b"),"fill":Color("b5bd9f"),"shine":Color("ede8d0")}
}
static func prepare(game) -> Dictionary:
	var data: Dictionary=game.road_inventory
	if not data.get("stock",{}) is Dictionary: data.stock={}
	if not data.has("stock"): data.stock={}
	if data.stock.has("wood"):
		data.stock.moss=maxi(0,int(data.stock.get("moss",0)))+maxi(0,int(data.stock.wood))
		data.stock.erase("wood")
	if str(data.get("selected",""))=="wood": data.selected="moss"
	if not ITEMS.has(str(data.get("selected",""))): data.selected="stone"
	for id in ORDER: data.stock[id]=clampi(int(data.stock.get(id,0)),0,100000)
	return data
static func style(game,key: String) -> String:
	var value=game.road_tiles.get(key,"stone")
	if value is String and value=="wood": return "moss"
	return str(value) if value is String and ITEMS.has(value) else "stone"
static func valid_key(key: String) -> bool:
	var parts=key.split(",")
	return parts.size()==2 and parts[0].is_valid_int() and parts[1].is_valid_int() and int(parts[0])>=0 and int(parts[0])<128 and int(parts[1])>=0 and int(parts[1])<128
static func buy(game,id: String,quantity: int) -> bool:
	if not game.feature_unlocked("roads"): return false
	if not ITEMS.has(id) or quantity<1 or quantity>100: return false
	var data=prepare(game)
	var cost=int(ITEMS[id].price)*quantity
	var owned=int(data.stock[id])
	for key in game.road_tiles:
		if style(game,str(key))==id: owned+=1
	if game.coins<cost or owned+quantity>100000: return false
	game.coins-=cost
	data.stock[id]=int(data.stock[id])+quantity
	data.selected=id
	game.save_game()
	return true
static func place(game,key: String) -> bool:
	if not valid_key(key): return false
	var data=prepare(game)
	var id=str(data.selected)
	if game.road_tiles.has(key) and style(game,key)==id: return false
	if int(data.stock[id])<=0: return false
	# Consume and exchange as a single in-memory transaction; the stroke saves both.
	data.stock[id]=int(data.stock[id])-1
	if game.road_tiles.has(key):
		var previous=style(game,key)
		data.stock[previous]=int(data.stock[previous])+1
	game.road_tiles[key]=id
	return true
static func erase(game,key: String) -> bool:
	if not game.road_tiles.has(key): return false
	var data=prepare(game)
	var id=style(game,key)
	data.stock[id]=int(data.stock[id])+1
	game.road_tiles.erase(key)
	return true

static func move(game,source: String,destination: String) -> bool:
	if source==destination or not valid_key(destination) or not game.road_tiles.has(source) or game.road_tiles.has(destination): return false
	game.road_tiles[destination]=game.road_tiles[source]
	game.road_tiles.erase(source)
	return true
