extends Area2D
class_name ThrowableComponent

var direction: Vector2

@export_category("Variables")
@export var _move_speed: float = 128.0

func _on_body_entered(_body: Node2D) -> void:
	pass

func _physics_process(delta: float) -> void:
	translate(direction * delta * _move_speed)
