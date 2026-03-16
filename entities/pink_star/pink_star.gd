extends BaseEnemy
class_name PinkStar

enum AttackState {
	IDLE,
	PRE_ATTACK,
	ROLL
}

@export_category("Roll Attack")
@export var _engage_distance: float = 120.0
@export var _engage_y_tolerance: float = 28.0
@export var _pre_attack_duration: float = 0.35
@export var _roll_attack_speed: float = 185.0
@export var _roll_attack_duration: float = 0.95
@export var _roll_attack_cooldown: float = 0.75
@export var _roll_hit_interval: float = 0.35
@export var _roll_hit_range_x: float = 18.0
@export var _roll_hit_range_y: float = 18.0

var _attack_state: AttackState = AttackState.IDLE
var _roll_direction_x: float = 1.0
var _pre_attack_remaining: float = 0.0
var _roll_time_remaining: float = 0.0
var _roll_cooldown_remaining: float = 0.0
var _roll_hit_cooldown_remaining: float = 0.0


func _ready() -> void:
	super._ready()
	_engage_distance = max(8.0, _engage_distance)
	_engage_y_tolerance = max(4.0, _engage_y_tolerance)
	_pre_attack_duration = max(0.1, _pre_attack_duration)
	_roll_attack_speed = max(1.0, _roll_attack_speed)
	_roll_attack_duration = max(0.1, _roll_attack_duration)
	_roll_attack_cooldown = max(0.0, _roll_attack_cooldown)
	_roll_hit_interval = max(0.0, _roll_hit_interval)
	_roll_hit_range_x = max(1.0, _roll_hit_range_x)
	_roll_hit_range_y = max(1.0, _roll_hit_range_y)


func _physics_process(delta: float) -> void:
	if _roll_cooldown_remaining > 0.0:
		_roll_cooldown_remaining = max(0.0, _roll_cooldown_remaining - delta)
	if _roll_hit_cooldown_remaining > 0.0:
		_roll_hit_cooldown_remaining = max(0.0, _roll_hit_cooldown_remaining - delta)

	match _attack_state:
		AttackState.PRE_ATTACK:
			_process_pre_attack(delta)
			return
		AttackState.ROLL:
			_process_roll_attack(delta)
			return
		_:
			super._physics_process(delta)


func _attack() -> void:
	if _attack_state != AttackState.IDLE:
		return
	if _roll_cooldown_remaining > 0.0:
		velocity.x = 0.0
		if _enemy_texture:
			_enemy_texture.force_idle()
		return
	if not is_on_floor():
		return

	var target: BaseCharacter = _get_target_player()
	if not is_instance_valid(target):
		velocity.x = 0.0
		if _enemy_texture:
			_enemy_texture.force_idle()
		return
	if not _is_target_in_engage_range(target):
		velocity.x = 0.0
		if _enemy_texture:
			_enemy_texture.force_idle()
		return

	_start_pre_attack(target)


func _start_pre_attack(target: BaseCharacter) -> void:
	_attack_state = AttackState.PRE_ATTACK
	_pre_attack_remaining = _pre_attack_duration
	_roll_cooldown_remaining = _roll_attack_cooldown
	velocity.x = 0.0
	_player_in_range = target

	_roll_direction_x = sign(target.global_position.x - global_position.x)
	if _roll_direction_x == 0.0:
		_roll_direction_x = _direction.x if _direction.x != 0.0 else 1.0
	_direction.x = _roll_direction_x

	if _enemy_texture:
		_enemy_texture.face_from_direction(_roll_direction_x)
		if _enemy_texture.has_action_animation(&"attack_anticipation"):
			_enemy_texture.action_animate(&"attack_anticipation", false)
		else:
			_enemy_texture.action_animate(&"attack", false)


func _process_pre_attack(delta: float) -> void:
	_vertical_movement(delta)
	velocity.x = 0.0
	move_and_slide()

	_pre_attack_remaining = max(0.0, _pre_attack_remaining - delta)
	if _pre_attack_remaining > 0.0:
		return

	_start_roll_attack()


func _start_roll_attack() -> void:
	_attack_state = AttackState.ROLL
	_roll_time_remaining = _roll_attack_duration
	_roll_hit_cooldown_remaining = 0.0
	velocity.x = _roll_direction_x * _roll_attack_speed

	if _enemy_texture:
		_enemy_texture.face_from_direction(_roll_direction_x)
		if _enemy_texture.animation != &"attack" or not _enemy_texture.is_playing():
			_enemy_texture.action_animate(&"attack", false)


func _process_roll_attack(delta: float) -> void:
	_vertical_movement(delta)
	_roll_time_remaining = max(0.0, _roll_time_remaining - delta)

	if _roll_time_remaining <= 0.0:
		_stop_roll_attack()
		return
	if is_on_wall():
		_stop_roll_attack()
		return
	if not _floor_detection_ray.is_colliding():
		_stop_roll_attack()
		return

	if _enemy_texture and (_enemy_texture.animation != &"attack" or not _enemy_texture.is_playing()):
		_enemy_texture.action_animate(&"attack", false)

	velocity.x = _roll_direction_x * _roll_attack_speed
	move_and_slide()
	_try_roll_contact_hit()


func _try_roll_contact_hit() -> void:
	var target: BaseCharacter = _get_target_player()
	if not is_instance_valid(target):
		return
	if target.is_dead():
		return
	if _roll_hit_cooldown_remaining > 0.0:
		return

	var delta_x: float = abs(target.global_position.x - global_position.x)
	var delta_y: float = abs(target.global_position.y - global_position.y)
	if delta_x > _roll_hit_range_x or delta_y > _roll_hit_range_y:
		return

	_roll_hit_cooldown_remaining = _roll_hit_interval
	target.receive_damage(get_skill_damage(), global_position, _knocktable)


func _stop_roll_attack() -> void:
	_attack_state = AttackState.IDLE
	velocity.x = 0.0
	if _enemy_texture:
		_enemy_texture.force_idle()


func _get_target_player() -> BaseCharacter:
	if is_instance_valid(_player_in_range) and not _player_in_range.is_dead():
		return _player_in_range

	var player: BaseCharacter = get_tree().get_first_node_in_group("player") as BaseCharacter
	if is_instance_valid(player) and not player.is_dead():
		return player
	return null


func _is_target_in_engage_range(target: BaseCharacter) -> bool:
	var dx: float = abs(target.global_position.x - global_position.x)
	var dy: float = abs(target.global_position.y - global_position.y)
	if dy > _engage_y_tolerance:
		return false
	if dx > _engage_distance:
		return false
	return _has_clear_line_of_sight(target)


func _has_clear_line_of_sight(target: BaseCharacter) -> bool:
	var state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -2),
		target.global_position + Vector2(0, -2)
	)
	query.exclude = [self]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit: Dictionary = state.intersect_ray(query)
	if hit.is_empty():
		return false
	return hit.get("collider", null) == target
