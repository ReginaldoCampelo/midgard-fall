extends Area2D
class_name CollectableComponent


func _on_body_entered(body: Node2D) -> void:
	if body is BaseCharacter:
		_consume(body)

func _consume(_body: BaseCharacter) -> void:
	pass
