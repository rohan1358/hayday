extends RefCounted
# Ephemeral tickets deliberately never survive a restart or replay against a new crop.
var pending: Dictionary={}
var serial=0
func start(game,index: int) -> String:
	if not pending.is_empty() or index<0 or index>=game.plots.size(): return ""
	var plot: Dictionary=game.plots[index]
	if str(plot.crop).is_empty() or game.is_ready(index): return ""
	serial+=1
	var id="crop_%d_%d" % [get_instance_id(),serial]
	pending={"id":id,"index":index,"plot":plot,"crop":str(plot.crop),"planted_at":int(plot.planted_at),"generation":int(game.hybrid.get("crop_generation",{}).get(str(index),0))}
	return id
func cancel(id: String) -> void:
	if pending.get("id","")==id: pending={}
func complete(game,id: String) -> bool:
	if id.is_empty() or pending.get("id","")!=id: return false
	var ticket=pending
	pending={}
	var i=int(ticket.index)
	if i<0 or i>=game.plots.size(): return false
	var plot: Dictionary=game.plots[i]
	if not is_same(plot,ticket.plot) or str(plot.crop)!=str(ticket.crop) or int(plot.planted_at)!=int(ticket.planted_at): return false
	if int(game.hybrid.get("crop_generation",{}).get(str(i),0))!=int(ticket.generation): return false
	if not game.is_ready(i):
		plot.ready_at=game.now()
		game.save_game()
	return true
