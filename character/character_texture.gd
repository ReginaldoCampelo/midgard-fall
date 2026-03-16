extends AnimatedSprite2D
class_name CharacterTexture

const ATTACK_AREA_X_OFFSET := 24.0
const GROUND_ATTACK_AREA_Y := 0.0
const AIR_ATTACK_AREA_Y := 16.0
const LAST_ACTIVE_ATTACK_FRAME := 1
const IDLE_FUN_DELAY_SECONDS := 5.0

var _is_on_action: bool = false
var _idle_inactive_time: float = 0.0

@export_category("Objects")
@export var _character: BaseCharacter
@export var _attack_area_collision: CollisionShape2D

func animate(_velocity: Vector2) -> void:
	if _is_on_action:
		return

	_update_idle_inactivity(_velocity)
	_verify_direction(_velocity.x)

	if _should_play_idle_fun(_velocity):
		var idle_fun_animation: String = _get_animation_name("idle_fun")
		if _has_animation(idle_fun_animation):
			play(idle_fun_animation)
			return

	if _character.is_dashing():
		play(_get_animation_name("dash"))
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
	_idle_inactive_time = 0.0
	play(_action_name)


func is_on_action() -> bool:
	return _is_on_action


func _get_animation_name(base_name: String) -> String:
	return base_name + ("_with_sword" if _character.has_sword else "")


func _on_animation_finished() -> void:
	_attack_area_collision.disabled = true
	_attack_area_collision.position.y = GROUND_ATTACK_AREA_Y

	if animation == "disappear":
		_character.on_disappear_finished()
		return

	if animation == "dead":
		return

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
	return (
		current_animation.begins_with("attack")
		or current_animation.begins_with("air_attack")
		or current_animation.begins_with("dash_attack")
	)


func _update_attack_area_state(current_animation: StringName) -> void:
	_attack_area_collision.position.y = AIR_ATTACK_AREA_Y if current_animation.begins_with("air_attack") else GROUND_ATTACK_AREA_Y
	_attack_area_collision.disabled = frame > LAST_ACTIVE_ATTACK_FRAME


func _update_idle_inactivity(_velocity: Vector2) -> void:
	var is_idle_on_ground: bool = _velocity == Vector2.ZERO and _character.is_on_floor()
	if is_idle_on_ground and not _has_player_input():
		_idle_inactive_time += get_physics_process_delta_time()
		return

	_idle_inactive_time = 0.0


func _should_play_idle_fun(_velocity: Vector2) -> bool:
	if _idle_inactive_time < IDLE_FUN_DELAY_SECONDS:
		return false
	return _velocity == Vector2.ZERO and _character.is_on_floor()


func _has_player_input() -> bool:
	return (
		Input.is_action_pressed("move_left")
		or Input.is_action_pressed("move_right")
		or Input.is_action_pressed("jump")
		or Input.is_action_pressed("attack")
		or Input.is_action_pressed("throw")
		or Input.is_action_pressed("dash")
	)


func _has_animation(animation_name: String) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(StringName(animation_name))
