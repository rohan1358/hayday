extends Node

# Opt-in Android debug experiment. Compare each layer against the same scene
# before and after it is hidden, across three repeated cycles.
# Never changes gameplay state, player save, or camera.
const PHASE_SECONDS := 5.0
const SETTLE_SECONDS := 8.0
const WARMUP_SECONDS := 1.0
const CYCLES := 3
const TARGETS := ["livestock", "ready", "worker", "truck"]

var nodes: Dictionary = {}
var initial_visible: Dictionary = {}
var phases: Array[Dictionary] = []
var phase_index := 0
var phase_elapsed := 0.0
var fps_samples: Array[float] = []
var frame_ms_samples: Array[float] = []
var call_samples: Array[float] = []
var process_samples: Array[float] = []


func _ready() -> void:
	var farm: FarmView = get_parent().farm
	if not is_instance_valid(farm):
		push_warning("KEBUN_ABA could not find FarmView")
		queue_free()
		return
	nodes = {
		"livestock": farm.mobile_livestock_overlay,
		"ready": farm.mobile_ready_markers_layer,
		"worker": farm.mobile_ujang_layer,
		"truck": farm.mobile_truck_layer,
	}
	for key in nodes:
		var canvas: CanvasItem = nodes[key]
		if not is_instance_valid(canvas):
			push_warning("KEBUN_ABA missing layer: " + String(key))
			queue_free()
			return
		initial_visible[key] = canvas.visible
	# The first settle period is deliberately excluded from observations.
	phases.append({"layer": "settle", "cycle": 0, "state": "settle", "hidden": []})
	for layer in TARGETS:
		for cycle in range(1, CYCLES + 1):
			phases.append({"layer": layer, "cycle": cycle, "state": "A_before", "hidden": []})
			phases.append({"layer": layer, "cycle": cycle, "state": "B", "hidden": [layer]})
			phases.append({"layer": layer, "cycle": cycle, "state": "A_after", "hidden": []})
	apply_phase()


func _process(delta: float) -> void:
	var phase: Dictionary = phases[phase_index]
	# Other scripts can update an actor's visibility: keep B hidden.
	for key in phase["hidden"]:
		var canvas: CanvasItem = nodes[key]
		if canvas.visible:
			canvas.hide()
	phase_elapsed += delta
	if String(phase["state"]) != "settle" and phase_elapsed >= WARMUP_SECONDS:
		fps_samples.append(float(Engine.get_frames_per_second()))
		frame_ms_samples.append(delta * 1000.0)
		call_samples.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		process_samples.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
	var duration := SETTLE_SECONDS if String(phase["state"]) == "settle" else PHASE_SECONDS
	if phase_elapsed < duration:
		return
	if String(phase["state"]) != "settle":
		print("KEBUN_ABA layer=%s cycle=%d phase=%s median_fps=%.1f p10_fps=%.1f median_frame_ms=%.1f p90_frame_ms=%.1f median_calls=%.1f median_process_ms=%.1f samples=%d" % [
			String(phase["layer"]), int(phase["cycle"]), String(phase["state"]),
			percentile(fps_samples, 0.5), percentile(fps_samples, 0.1),
			percentile(frame_ms_samples, 0.5), percentile(frame_ms_samples, 0.9),
			percentile(call_samples, 0.5), percentile(process_samples, 0.5), fps_samples.size(),
		])
	phase_index += 1
	if phase_index >= phases.size():
		restore_layers()
		print("KEBUN_ABA finished: all layer visibility restored")
		queue_free()
		return
	phase_elapsed = 0.0
	fps_samples.clear()
	frame_ms_samples.clear()
	call_samples.clear()
	process_samples.clear()
	apply_phase()


func percentile(values: Array[float], fraction: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values := values.duplicate()
	sorted_values.sort()
	return sorted_values[clampi(roundi(float(sorted_values.size() - 1) * fraction), 0, sorted_values.size() - 1)]


func restore_layers() -> void:
	for key in initial_visible:
		var canvas: CanvasItem = nodes[key]
		if is_instance_valid(canvas):
			canvas.visible = bool(initial_visible[key])


func apply_phase() -> void:
	restore_layers()
	var phase: Dictionary = phases[phase_index]
	for key in phase["hidden"]:
		var canvas: CanvasItem = nodes[key]
		canvas.hide()
	print("KEBUN_ABA starting layer=%s cycle=%d phase=%s" % [
		String(phase["layer"]), int(phase["cycle"]), String(phase["state"]),
	])


func _exit_tree() -> void:
	restore_layers()

