extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=FarmGameState.new(false)
 g.save_path="user://orchard_expansion_test.json"
 g.backup_path="user://orchard_expansion_test_backup.json"
 g.level=30;g.coins=100000;g.storage_capacity=10000
 assert(g.orchard.size()==12)
 for i in g.orchard.size(): g.orchard[i]={"fruit":"","ready_at":0}
 var i=0
 for fruit in g.FRUITS:
  assert(g.plant_tree(i,fruit))
  assert(not g.tree_ready(i))
  assert(g.harvest_tree(i)==0)
  g.orchard[i].ready_at=g.now()-1
  assert(g.harvest_tree(i)==3)
  assert(g.inventory[fruit]==3)
  assert(not g.tree_ready(i))
  assert(not ReferenceAssets.sprite("fruit_tree_"+fruit+"_ripe").is_empty())
  assert(not ReferenceAssets.sprite("fruit_tree_"+fruit+"_bare").is_empty())
  assert(g.sell_quantity(fruit,1)>0)
  i+=1
 for id in g.PRODUCT_ORDER:
  var recipe=g.PRODUCTS[id]
  for ingredient in recipe.ingredients: g.inventory[ingredient]=100
  if id in ["jus_apel","jus_jeruk","puding_mangga","roti_pisang","selai_ceri","limun","jus_alpukat","puding_kelapa","selai_persik","pai_pir","cokelat","kopi_seduh"]:
   assert(g.queue_product(id), "Fruit recipe must queue: "+id)
   for task in g.production_queue: task.ready_at=g.now()-1
   assert(g.collect_ready_products()>0)
 g.save_game()
 var loaded=FarmGameState.new(false)
 loaded.save_path=g.save_path;loaded.backup_path=g.backup_path
 loaded.load_game()
 assert(loaded.orchard==g.orchard)
 assert(loaded.inventory==g.inventory)
 print("ORCHARD EXPANSION PASS: 12 trees, regrowth, fruit sales, recipes, save reload")
 quit()

