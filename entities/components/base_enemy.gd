extends CharacterBody2D
class_name BaseEnemy

enum _types {
	STATIC = 0,
	CHASE = 1,
	WANDER = 2
}

@export_category("Objects")
@export var _enemy_texture: EnemyTexture
@export var _floor_detection_ray: RayCast2D
@export var _hp_bar: EnemyHpBar

@export_category("Variables")
@export var _is_inverted: bool = false
@export var _enemy_type: _types
@export var _move_speed: float = 128.0
@export var _max_hp: int = 3
@export var _defense: int = 0
@export var _contact_damage: int = 1
@export var _skill_damage: int = 1
@export var _damage: int = 1
@export var _knocktable: bool = true
@export var _keep_dead_body: bool = true
@export var _despawn_after_death_seconds: float = -1.0
@export var _dead_z_index: int = -5
@export var _hit_invulnerability_time: float = 0.08
@export var _hit_knockback_x: float = 140.0
@export var _hit_knockback_y: float = -40.0
@export var _hit_stun_time: float = 0.10
@export var _hit_animation: StringName = &"hit"
@export var _death_animation: StringName = &"dead_hit"
@export var _corpse_animation: StringName = &"dead_ground"

var _on_floor: bool = false
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _direction: Vector2 = Vector2.ZERO
var _player_in_range: BaseCharacter = null
var _is_dead: bool = false
var _is_invulnerable: bool = false
var _current_hp: int = 0
var _hit_stun_remaining: float = 0.0
var _invuln_flash_tween: Tween = null


func _ready() -> void:
	_max_hp = max(1, _max_hp)
	_defense = max(0, _defense)
	_damage = max(1, _damage)
	_contact_damage = max(1, _contact_damage)
	_skill_damage = max(1, _skill_damage)
	if _contact_damage == 1 and _damage != 1:
		_contact_damage = _damage
	if _skill_damage == 1 and _damage != 1:
		_skill_damage = _damage
	_current_hp = _max_hp
	_sync_hp_bar()
	_direction = [Vector2(-1, 0), Vector2(1, 0)].pick_random()
	_sync_floor_detection_ray()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_vertical_movement(delta)

	if _hit_stun_remaining > 0.0:
		_hit_stun_remaining = max(0.0, _hit_stun_remaining - delta)
		move_and_slide()
		_enemy_texture.animate(velocity)
		return
	
	if is_instance_valid(_player_in_range):
		if _player_in_range.is_dead():
			_player_in_range = null
			velocity.x = 0.0
			if _enemy_texture:
				_enemy_texture.force_idle()
		else:
			_attack()
			return
	
	match _enemy_type:
		_types.STATIC:
			pass
		_types.CHASE:
			pass
		_types.WANDER:
			_wandering()
	
	move_and_slide()
	
	_enemy_texture.animate(velocity)
	
	
func _vertical_movement(_delta: float) -> void:
	if is_on_floor():
		if _on_floor == false:
			_enemy_texture.action_animate(&"ground")
			_on_floor = true
	
	if not is_on_floor():
		_on_floor = false
		velocity.y += _gravity * _delta


func _wandering() -> void:
	if not _floor_detection_ray.is_colliding() or is_on_wall():
		_reverse_direction()
	
	velocity.x = _direction.x * _move_speed


func _reverse_direction() -> void:
	_direction.x = -_direction.x
	_sync_floor_detection_ray()


func _sync_floor_detection_ray() -> void:
	_floor_detection_ray.position.x = abs(_floor_detection_ray.position.x) * _direction.x


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is BaseCharacter:
		_player_in_range = body


func _on_detection_area_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body is BaseCharacter:
		_player_in_range = null

func _attack() -> void:
	pass


func receive_damage(damage: int, hit_origin: Vector2 = Vector2.ZERO, apply_knockback: bool = true, is_critical: bool = false) -> void:
	if _is_dead:
		return

	if _is_invulnerable:
		global.spawn_combat_popup(0, global_position + Vector2(0, -16), &"blocked")
		return

	var final_damage: int = _calculate_incoming_damage(damage)
	_current_hp -= final_damage
	var popup_type: StringName = &"normal"
	if is_critical:
		popup_type = &"crit"
	elif final_damage < damage:
		popup_type = &"resisted"
	global.spawn_combat_popup(final_damage, global_position + Vector2(0, -16), popup_type)
	_start_invuln_flash()
	_start_invulnerability_window()
	_sync_hp_bar()
	if _current_hp <= 0:
		_is_dead = true
		set_physics_process(false)
		_disable_combat_areas()
		_disable_body_collision()
		z_index = _dead_z_index

		if _enemy_texture and _enemy_texture.has_action_animation(_death_animation):
			_enemy_texture.action_animate(_death_animation)
		else:
			if _keep_dead_body:
				_show_corpse_pose()
			else:
				queue_free()
		return

	if apply_knockback and _knocktable:
		_apply_hit_knockback(hit_origin)

	if _enemy_texture and _enemy_texture.has_action_animation(_hit_animation):
		_enemy_texture.action_animate(_hit_animation)


func get_damage() -> int:
	return _contact_damage


func get_contact_damage() -> int:
	return _contact_damage


func get_skill_damage() -> int:
	return _skill_damage


func is_inverted() -> bool:
	return _is_inverted


func is_in_hit_stun() -> bool:
	return _hit_stun_remaining > 0.0


func is_knocktable() -> bool:
	return _knocktable


func get_current_hp() -> int:
	return _current_hp


func get_max_hp() -> int:
	return _max_hp


func _calculate_incoming_damage(raw_damage: int) -> int:
	return max(1, raw_damage - _defense)


func is_death_animation(animation_name: StringName) -> bool:
	return animation_name == _death_animation


func on_death_animation_finished() -> void:
	if not _keep_dead_body:
		queue_free()
		return

	_show_corpse_pose()
	_schedule_corpse_despawn()


func _sync_hp_bar() -> void:
	if not _hp_bar:
		return

	_hp_bar.set_values(_current_hp, _max_hp)


func _apply_hit_knockback(hit_origin: Vector2) -> void:
	var knockback_direction: float = 0.0
	if global_position.x > hit_origin.x:
		knockback_direction = 1.0
	elif global_position.x < hit_origin.x:
		knockback_direction = -1.0

	if knockback_direction == 0.0:
		knockback_direction = -_direction.x if _direction.x != 0.0 else 1.0

	velocity.x = knockback_direction * _hit_knockback_x
	velocity.y = _hit_knockback_y
	_hit_stun_remaining = _hit_stun_time


func _disable_combat_areas() -> void:
	var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D
	if attack_area:
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)

	var detection_area: Area2D = get_node_or_null("DetectionArea") as Area2D
	if detection_area:
		detection_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitorable", false)


func _disable_body_collision() -> void:
	var body_collision: CollisionShape2D = get_node_or_null("Collision") as CollisionShape2D
	if body_collision:
		body_collision.set_deferred("disabled", true)


func _show_corpse_pose() -> void:
	if _enemy_texture and _enemy_texture.has_action_animation(_corpse_animation):
		_enemy_texture.action_animate(_corpse_animation)


func _start_invulnerability_window() -> void:
	if _is_dead:
		return

	_is_invulnerable = true
	await get_tree().create_timer(_hit_invulnerability_time).timeout
	_is_invulnerable = false


func _start_invuln_flash() -> void:
	if not _enemy_texture:
		return

	if _invuln_flash_tween:
		_invuln_flash_tween.kill()

	_invuln_flash_tween = create_tween()
	_invuln_flash_tween.tween_property(_enemy_texture, "modulate:a", 0.35, 0.04)
	_invuln_flash_tween.tween_property(_enemy_texture, "modulate:a", 1.0, 0.04)
	_invuln_flash_tween.tween_property(_enemy_texture, "modulate:a", 0.35, 0.04)
	_invuln_flash_tween.tween_property(_enemy_texture, "modulate:a", 1.0, 0.04)


func _schedule_corpse_despawn() -> void:
	if _despawn_after_death_seconds <= 0.0:
		return

	await get_tree().create_timer(_despawn_after_death_seconds).timeout
	queue_free()
