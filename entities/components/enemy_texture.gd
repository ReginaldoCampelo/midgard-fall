extends AnimatedSprite2D
class_name EnemyTexture

@export_category("Objects")
@export var _enemy: BaseEnemy
@export var _attack_area_collision: CollisionShape2D

@export_category("Variables")
@export var _last_attack_frame: int

var _on_action: bool = false
var _current_action_locks_physics: bool = true

func animate(_velocity: Vector2) -> void:
	if _on_action:
		return

	if not _enemy.is_in_hit_stun():
		_apply_facing_from_x(_velocity.x)
	
	if _velocity.y && _velocity.y > 0:
		play("fall")
	if _velocity.y && _velocity.y < 0:
		play("jump")
	if _velocity.x && _velocity.x != 0:
		play("run")
	if _velocity.x == 0:
		play("idle")
	return

func action_animate(_action: StringName, lock_physics: bool = true) -> void:
	_current_action_locks_physics = lock_physics
	if lock_physics:
		_enemy.set_physics_process(false)
	_on_action = true
	if _attack_area_collision and _action != &"attack":
		_set_attack_area_disabled(true)
	play(_action)


func _on_animation_finished() -> void:
	if animation == &"attack_anticipation":
		action_animate(&"attack", _current_action_locks_physics)
		return

	if _enemy and _enemy.is_death_animation(animation):
		_enemy.on_death_animation_finished()
		return
		
	if _attack_area_collision:
		_set_attack_area_disabled(true)

	_on_action = false
	if _current_action_locks_physics:
		_enemy.set_physics_process(true)


func _on_frame_changed() -> void:
	if not _attack_area_collision:
		return

	if animation != &"attack":
		if not _attack_area_collision.disabled:
			_set_attack_area_disabled(true)
		return

	_set_attack_area_disabled(frame > _last_attack_frame)


func has_action_animation(animation_name: StringName) -> bool:
	return sprite_frames and sprite_frames.has_animation(animation_name)


func force_idle() -> void:
	_on_action = false
	_set_attack_area_disabled(true)
	play(&"idle")


func face_from_direction(direction_x: float) -> void:
	_apply_facing_from_x(direction_x)


func _set_attack_area_disabled(is_disabled: bool) -> void:
	if not _attack_area_collision:
		return

	if _attack_area_collision.disabled == is_disabled:
		return

	_attack_area_collision.set_deferred("disabled", is_disabled)


func _apply_facing_from_x(direction_x: float) -> void:
	if direction_x == 0.0:
		return

	var should_flip: bool = direction_x < 0.0
	if _enemy.is_inverted():
		should_flip = not should_flip

	flip_h = should_flip
