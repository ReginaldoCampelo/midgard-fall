extends AnimatedSprite2D
class_name CharacterTexture

const ATTACK_AREA_X_OFFSET := 24.0
const GROUND_ATTACK_AREA_Y := 0.0
const AIR_ATTACK_AREA_Y := 16.0
const LAST_ACTIVE_ATTACK_FRAME := 1

var _is_on_action: bool = false

@export_category("Objects")
@export var _character: BaseCharacter
@export var _attack_area_collision: CollisionShape2D

func animate(_velocity: Vector2) -> void:
	_verify_direction(_velocity.x)

	if _is_on_action:
		return

	if _velocity == Vector2.ZERO:
		play(_get_animation_name("idle"))
		return

	if _velocity.y < 0:
		play(_get_animation_name("jump"))
		return

	if _velocity.y > 0:
		play(_get_animation_name("fall"))
		return

	if _velocity.x != 0:
		play(_get_animation_name("run"))


func _verify_direction(_direction: float) -> void:
	if _direction == 0:
		return

	flip_h = _direction < 0
	_attack_area_collision.position.x = -ATTACK_AREA_X_OFFSET if flip_h else ATTACK_AREA_X_OFFSET


func action_animation(_action_name: String) -> void:
	_is_on_action = true
	play(_action_name)


func is_on_action() -> bool:
	return _is_on_action


func _get_animation_name(base_name: String) -> String:
	return base_name + ("_with_sword" if _character.has_sword else "")


func _on_animation_finished() -> void:
	_attack_area_collision.disabled = true
	_attack_area_collision.position.y = GROUND_ATTACK_AREA_Y
	_character.set_physics_process(true)
	_is_on_action = false


func _on_frame_changed() -> void:
	var current_animation: StringName = animation

	if _is_attack_animation(current_animation):
		_update_attack_area_state(current_animation)
	elif not _attack_area_collision.disabled:
		_attack_area_collision.disabled = true

	if current_animation == "throw_sword" && frame == 2:
		_character.throw_attack(flip_h)
	
	if current_animation == "run" or current_animation == "run_with_sword":
		if frame == 1 or frame == 4:
			global.spawn_effect(
				"res://visual_effects/dust_particles/run/run_effect.tscn",
				Vector2(0, 2),
				global_position,
				flip_h
			)


func _is_attack_animation(current_animation: StringName) -> bool:
	return current_animation.begins_with("attack") or current_animation.begins_with("air_attack")


func _update_attack_area_state(current_animation: StringName) -> void:
	_attack_area_collision.position.y = AIR_ATTACK_AREA_Y if current_animation.begins_with("air_attack") else GROUND_ATTACK_AREA_Y
	_attack_area_collision.disabled = frame > LAST_ACTIVE_ATTACK_FRAME
