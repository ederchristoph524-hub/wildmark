extends SceneTree
var s: RefCounted
func _initialize() -> void:
	_go.call_deferred()
func _go() -> void:
	await physics_frame
	s = (load("res://tools/zz_dbg_steps.gd") as GDScript).new()
	s.call("run", self)
