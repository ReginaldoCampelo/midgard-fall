extends Node
class_name Global

func spawn_effect(_path: String, _offset: Vector2, _initial_position: Vector2, is_flipped: bool) -> void:
	var scene := load(_path) as PackedScene
	if scene == null:
		push_error("Failed to load effect scene: " + _path)
		return

	var _effect := scene.instantiate() as BaseEffect
	if _effect == null:
		push_error("Loaded scene is not a BaseEffect: " + _path)
		return

	_effect.global_position = _initial_position + _offset
	_effect.flip_h = is_flipped
	
	get_tree().root.call_deferred("add_child", _effect)
