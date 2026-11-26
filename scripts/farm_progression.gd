extends Node
const JOURNEY=preload("res://scripts/level_journey.gd")
var host
var seen=1
var pending: Array=[]
var dialog: Control
var dialog_layer: CanvasLayer
var cooldown=0.0
func _ready():
	host=get_parent();seen=host.game.level
	JOURNEY.prepare(host.game)
func _process(dt):
	while seen<host.game.level:
		seen+=1;JOURNEY.reached(host.game,seen)
	pending=host.game.level_journey.queue
	cooldown=maxf(0,cooldown-dt)
	if dialog!=null and is_instance_valid(dialog): return
	if pending.is_empty() or cooldown>0 or bool(host.get_meta("first_farm_modal",false)): return
	if preload("res://scripts/first_farm.gd").active(host.game): return
	if not host.game.ftue.is_empty() and not bool(host.game.ftue.get("started",false)): return
	var next=int(pending[0])
	dialog=preload("res://scripts/level_up_popup.gd").new()
	dialog.host=host;dialog.reached_level=next
	host.set_meta("first_farm_modal",true)
	dialog.dismissed.connect(func(missions):
		host.game.level_journey.queue.erase(next)
		host.game.save_game();host.set_meta("first_farm_modal",false)
		cooldown=0.35
		if missions:
			host.set_meta("journey_selected",next);host.switch_tab("misi")
		dialog=null)
	dialog_layer=CanvasLayer.new()
	dialog_layer.name="LevelUpModalLayer"
	dialog_layer.layer=150
	host.add_child(dialog_layer)
	dialog.tree_exited.connect(func():
		if is_instance_valid(dialog_layer): dialog_layer.queue_free())
	dialog_layer.add_child(dialog)
static func cow_shop(ui,parent,game):
	preload("res://scripts/animal_store.gd").populate(ui,parent,game)
