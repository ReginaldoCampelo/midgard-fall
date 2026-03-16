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


func spawn_damage_popup(amount: int, world_position: Vector2, color: Color = Color(1, 0.2, 0.2, 1), size: int = 12, scale_multiplier: float = 1.0) -> void:
	var popup: Label = Label.new()
	popup.global_position = world_position
	popup.text = str(amount)
	popup.modulate = color
	popup.scale = Vector2.ONE * max(0.5, float(size) / 12.0) * max(0.5, scale_multiplier)
	popup.z_index = 100

	get_tree().root.add_child(popup)

	var tween: Tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 14.0, 0.45)
	tween.tween_property(popup, "modulate:a", 0.0, 0.45)
	tween.finished.connect(popup.queue_free)


func spawn_combat_popup(amount: int, world_position: Vector2, popup_type: StringName = &"normal") -> void:
	match popup_type:
		&"crit":
			spawn_damage_popup(amount, world_position, Color(1, 0.88, 0.3, 1), 13, 1.2)
		&"resisted":
			spawn_damage_popup(amount, world_position, Color(0.63, 0.88, 1, 1), 11, 0.95)
		&"blocked":
			_spawn_text_popup("BLOCK", world_position, Color(0.78, 0.82, 0.9, 1), 10, 0.9)
		_:
			spawn_damage_popup(amount, world_position, Color(1, 0.22, 0.22, 1), 10, 1.0)


func _spawn_text_popup(text: String, world_position: Vector2, color: Color, size: int, scale_multiplier: float) -> void:
	var popup: Label = Label.new()
	popup.global_position = world_position
	popup.text = text
	popup.modulate = color
	popup.scale = Vector2.ONE * max(0.5, float(size) / 12.0) * max(0.5, scale_multiplier)
	popup.z_index = 100

	get_tree().root.add_child(popup)

	var tween: Tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 14.0, 0.45)
	tween.tween_property(popup, "modulate:a", 0.0, 0.45)
	tween.finished.connect(popup.queue_free)
