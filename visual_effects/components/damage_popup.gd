extends Label2D
class_name DamagePopup

@export var _rise_distance: float = 14.0
@export var _duration: float = 0.45

func setup(amount: int, color: Color = Color(1, 0.2, 0.2, 1), size: int = 12) -> void:
	text = str(amount)
	modulate = color
	scale = Vector2.ONE * max(0.5, float(size) / 12.0)


func play() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - _rise_distance, _duration)
	tween.tween_property(self, "modulate:a", 0.0, _duration)
	await tween.finished
	queue_free()
