extends AnimatedSprite2D
class_name EnemyTexture

@export_category("Objects")
@export var _enemy: BaseEnemy

var _on_action: bool = false

func animate(_velocity: Vector2) -> void:
	if _on_action:
		return

	if _velocity.x != 0:
		var _should_flip: bool = _velocity.x < 0
		if _enemy._is_inverted:
			_should_flip = not _should_flip
		flip_h = _should_flip
	
	if _velocity.y && _velocity.y > 0:
		play("fall")
	if _velocity.y && _velocity.y < 0:
		play("jump")
	if _velocity.x && _velocity.x != 0:
		play("run")
	if _velocity.x == 0:
		play("idle")
	return

func action_animate(_action: String) -> void:
	_enemy.set_physics_process(false)
	_on_action = true
	play(_action)


func _on_animation_finished() -> void:
	_on_action = false
	_enemy.set_physics_process(true)
