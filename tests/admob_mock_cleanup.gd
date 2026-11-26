extends RefCounted
# Desktop SDK stand-ins can be constructed before SceneTree exists.
# Explicitly dispose their orphan Nodes in headless ad tests.
static func release() -> void:
	if OS.get_name()=="Android": return
	var factory=load("res://addons/admob/internal/mock/mock_admob_factory.gd")
	for mock in factory._mocks.values():
		if is_instance_valid(mock) and mock is Node:
			if mock.is_inside_tree(): mock.queue_free()
			else: mock.free()
	factory._mocks.clear()
