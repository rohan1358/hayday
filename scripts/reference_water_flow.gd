extends Node2D

const TERRAIN=preload("res://scripts/reference_terrain.gd")
var farm: FarmView
var elapsed := 0.0
var refresh := 0.0

func _process(delta: float) -> void:
	if farm==null: return
	elapsed+=delta
	refresh+=delta
	var scaler=farm.size/farm.get_virtual_size()
	position=(farm.get_virtual_size()*0.5-farm.camera_center*farm.camera_zoom)*scaler
	scale=scaler*farm.camera_zoom
	if refresh>=0.08: refresh=0.0;queue_redraw()

func _draw() -> void:
	pass
