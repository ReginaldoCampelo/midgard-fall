extends CharacterBody2D
class_name BaseCharacter

const MAX_JUMPS := 2
const GROUND_ATTACK_HITS := 3
const AIR_ATTACK_HITS := 2
const THROW_DAMAGE_MULTIPLIER := 2
const AIR_ATTACK_DAMAGE_MULTIPLIER := 2
const DASH_ATTACK_DAMAGE_MULTIPLIER := 3
const ATTACK_EFFECT_OFFSET_X := 24.0
const GROUND_ATTACK_EFFECTS: Array[String] = [
	"res://visual_effects/sword/attack_1/attack_1.tscn",
	"res://visual_effects/sword/attack_2/attack_2.tscn",
	"res://visual_effects/sword/attack_3/attack_3.tscn"
]
const AIR_ATTACK_EFFECTS: Array[String] = [
	"res://visual_effects/sword/air_attack_1/air_attack_1.tscn",
	"res://visual_effects/sword/air_attack_2/air_attak_2.tscn"
]

@export_category("Variables")
@export var _speed: float = 200.0
@export var _jump_velocity: float = -300.0
@export var _hard_fall_threshold: float = 500.0
@export var _hit_invulnerability_time: float = 0.35
@export var _max_hp: int = 20
@export var _defense: int = 1
@export var _damage: int = 1
@export var _attack_hit_cooldown: float = 0.08
@export var _knocktable: bool = true
@export var _hit_knockback_x: float = 180.0
@export var _hit_knockback_y: float = -60.0
@export var _hit_stun_time: float = 0.12
@export var _dash_speed: float = 360.0
@export var _dash_duration: float = 0.12
@export var _dash_cooldown: float = 0.35
@export var _dash_attack_combo_window: float = 0.25
@export var _max_stamina: float = 100.0
@export var _dash_stamina_cost: float = 50.0
@export var _stamina_recovery_per_second: float = 20.0

@export_category("Objects")
@export var _attack_combo: Timer
@export var _character_texture: CharacterTexture

const _THROABLE_SWORD: PackedScene = preload("res://throwables/character_sword/character_sword.tscn")

var _on_floor: bool = true
var _jump_count: int = 0
var _ground_attack_index: int = 1
var _air_attack_index: int = 1
var _air_attack_count: int = 0
var _max_fall_speed: float = 0.0
var has_sword: bool = false
var _is_invulnerable: bool = false
var _is_dead: bool = false
var _current_hp: int = 0
var _hit_stun_remaining: float = 0.0
var _current_attack_damage: int = 1
var _current_attack_is_critical: bool = false
var _last_hit_time_by_target: Dictionary = {}
var _invuln_flash_tween: Tween = null
var _dash_time_remaining: float = 0.0
var _dash_cooldown_remaining: float = 0.0
var _dash_attack_combo_remaining: float = 0.0
var _dash_direction: float = 1.0
var _current_stamina: float = 100.0


func _ready() -> void:
	add_to_group("player")
	_max_hp = max(1, _max_hp)
	_defense = max(0, _defense)
	_damage = max(1, _damage)
	_current_hp = _max_hp
	_current_attack_damage = _damage
	_max_stamina = max(1.0, _max_stamina)
	_dash_stamina_cost = clamp(_dash_stamina_cost, 1.0, _max_stamina)
	_stamina_recovery_per_second = max(0.0, _stamina_recovery_per_second)
	_dash_attack_combo_window = max(0.0, _dash_attack_combo_window)
	_current_stamina = _max_stamina
	_load_persistent_stats()
	_persist_stats()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_vertical_movement(delta)
	_update_dash_timers(delta)
	if _try_start_dash():
		# Dash started this frame.
		pass
	elif _dash_attack_combo_remaining > 0.0 and _try_start_dash_attack():
		move_and_slide()
		_character_texture.animate(velocity)
		return

	if _hit_stun_remaining > 0.0:
		_hit_stun_remaining = max(0.0, _hit_stun_remaining - delta)
		move_and_slide()
		_character_texture.animate(velocity)
		return

	if _dash_time_remaining > 0.0:
		if _try_start_dash_attack():
			move_and_slide()
			_character_texture.animate(velocity)
			return
		velocity.x = _dash_direction * _dash_speed
		velocity.y = 0.0
		move_and_slide()
		_character_texture.animate(velocity)
		return

	_horizontal_movement()
	_attack_handler()
	move_and_slide()
	_character_texture.animate(velocity)


func _vertical_movement(delta: float) -> void:
	if is_on_floor():
		_handle_landing()
		_jump_count = 0
	else:
		_handle_fall(delta)

	if Input.is_action_just_pressed("jump") and _jump_count < MAX_JUMPS:
		_jump()


func _handle_landing() -> void:
	if _on_floor:
		return

	global.spawn_effect(
		"res://visual_effects/dust_particles/fall/fall_effect.tscn",
		Vector2(0, 2),
		global_position,
		false
	)

	_character_texture.action_animation(_get_animation_name("ground"))

	if _max_fall_speed >= _hard_fall_threshold:
		set_physics_process(false)

	_on_floor = true
	_max_fall_speed = 0.0
	_air_attack_count = 0
	_air_attack_index = 1


func _handle_fall(delta: float) -> void:
	_on_floor = false
	velocity += get_gravity() * delta

	if velocity.y > 0:
		_max_fall_speed = max(_max_fall_speed, velocity.y)


func _jump() -> void:
	_jump_count += 1
	velocity.y = _jump_velocity

	if _jump_count == 1:
		global.spawn_effect(
			"res://visual_effects/dust_particles/jump/jump_effect.tscn",
			Vector2(0, 2),
			global_position,
			_character_texture.flip_h
		)


func _horizontal_movement() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * _speed
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)


func _attack_handler() -> void:
	if not has_sword:
		return
	
	if Input.is_action_just_pressed("throw"):
		_start_throw_attack()

	if not Input.is_action_just_pressed("attack"):
		return

	if _character_texture.is_on_action():
		return

	if is_on_floor():
		_start_ground_attack()
	else:
		_start_air_attack()


func _start_ground_attack() -> void:
	var attack_step: int = _ground_attack_index
	_current_attack_damage = _damage
	_current_attack_is_critical = false
	_last_hit_time_by_target.clear()
	_character_texture.action_animation("attack_" + str(attack_step))
	_spawn_attack_effect(GROUND_ATTACK_EFFECTS[attack_step - 1])
	_ground_attack_index = (_ground_attack_index % GROUND_ATTACK_HITS) + 1

	set_physics_process(false)
	_attack_combo.start()


func _start_air_attack() -> void:
	if _air_attack_count >= AIR_ATTACK_HITS:
		return

	var attack_step: int = _air_attack_index
	_current_attack_damage = _damage * AIR_ATTACK_DAMAGE_MULTIPLIER
	_current_attack_is_critical = true
	_last_hit_time_by_target.clear()
	_character_texture.action_animation("air_attack_" + str(attack_step))
	_spawn_attack_effect(AIR_ATTACK_EFFECTS[attack_step - 1])
	_air_attack_count += 1
	_air_attack_index = (_air_attack_index % AIR_ATTACK_HITS) + 1

	set_physics_process(false)
	_attack_combo.start()


func _try_start_dash_attack() -> bool:
	if not has_sword:
		return false
	if not Input.is_action_just_pressed("attack"):
		return false
	if _character_texture.is_on_action():
		return false

	_current_attack_damage = _damage * DASH_ATTACK_DAMAGE_MULTIPLIER
	_current_attack_is_critical = true
	_last_hit_time_by_target.clear()
	_dash_attack_combo_remaining = 0.0
	_dash_time_remaining = 0.0
	_character_texture.action_animation("dash_attack")
	set_physics_process(false)
	_attack_combo.start()
	return true


func _spawn_attack_effect(effect_path: String) -> void:
	var attack_offset: Vector2 = Vector2(ATTACK_EFFECT_OFFSET_X, 0)
	if _character_texture.flip_h:
		attack_offset.x *= -1

	global.spawn_effect(
		effect_path,
		attack_offset,
		global_position,
		_character_texture.flip_h
	)

func _start_throw_attack() -> void:
	_current_attack_is_critical = true
	_character_texture.action_animation("throw_sword")
	set_physics_process(false)
	has_sword = false
	_persist_stats()
	return

func throw_attack(is_flipped: bool) -> void:
	var _sword: CharacterSword = _THROABLE_SWORD.instantiate()
	get_tree().root.call_deferred("add_child", _sword)
	_sword.global_position = global_position
	_sword.set_throw_damage(_damage * THROW_DAMAGE_MULTIPLIER)
	
	if is_flipped:
		_sword.direction = Vector2(-1, 0)
		return
	_sword.direction = Vector2(1, 0)

func _get_animation_name(base_name: String) -> String:
	return base_name + ("_with_sword" if has_sword else "")


func equip_sword() -> void:
	has_sword = true
	_persist_stats()


func unequip_sword() -> void:
	has_sword = false
	_persist_stats()


func receive_damage(damage_amount: int, hit_origin: Vector2 = Vector2.ZERO, apply_knockback: bool = true) -> void:
	if _is_dead:
		return

	if _is_invulnerable:
		global.spawn_combat_popup(0, global_position + Vector2(0, -18), &"blocked")
		return

	var final_damage: int = _calculate_incoming_damage(damage_amount)
	_current_hp = max(0, _current_hp - final_damage)
	var popup_type: StringName = &"normal"
	if final_damage < damage_amount:
		popup_type = &"resisted"
	global.spawn_combat_popup(final_damage, global_position + Vector2(0, -18), popup_type)
	_start_invuln_flash()
	_persist_stats()
	if _current_hp == 0:
		_die()
		return

	if apply_knockback and _knocktable:
		_apply_hit_knockback(hit_origin)

	_is_invulnerable = true
	_character_texture.action_animation(_get_animation_name("hit"))

	await get_tree().create_timer(_hit_invulnerability_time).timeout
	_is_invulnerable = false


func _on_attack_combo_timeout() -> void:
	_ground_attack_index = 1
	_current_attack_damage = _damage
	_current_attack_is_critical = false
	_last_hit_time_by_target.clear()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not has_sword:
		return

	var enemy: BaseEnemy = body as BaseEnemy
	if not enemy:
		return

	if not _can_hit_target(enemy):
		return

	var damage_to_apply: int = _current_attack_damage
	if _character_texture.animation.begins_with("air_attack"):
		damage_to_apply = int(max(damage_to_apply, _damage * AIR_ATTACK_DAMAGE_MULTIPLIER))
	elif _character_texture.animation.begins_with("dash_attack"):
		damage_to_apply = int(max(damage_to_apply, _damage * DASH_ATTACK_DAMAGE_MULTIPLIER))

	_register_target_hit(enemy)
	enemy.receive_damage(damage_to_apply, global_position, _knocktable, _current_attack_is_critical)


func add_stats(hp_increase: int = 0, defense_increase: int = 0, damage_increase: int = 0) -> void:
	_max_hp = max(1, _max_hp + hp_increase)
	_defense = max(0, _defense + defense_increase)
	_damage = max(1, _damage + damage_increase)
	_current_hp = min(_current_hp + max(0, hp_increase), _max_hp)
	_persist_stats()


func heal(amount: int) -> void:
	_current_hp = min(_max_hp, _current_hp + max(0, amount))
	_persist_stats()


func get_current_hp() -> int:
	return _current_hp


func get_max_hp() -> int:
	return _max_hp


func get_damage() -> int:
	return _damage


func get_defense() -> int:
	return _defense


func has_sword_equipped() -> bool:
	return has_sword


func is_knocktable() -> bool:
	return _knocktable


func is_dead() -> bool:
	return _is_dead


func is_dashing() -> bool:
	return _dash_time_remaining > 0.0


func on_disappear_finished() -> void:
	queue_free()


func _calculate_incoming_damage(raw_damage: int) -> int:
	return max(1, raw_damage - _defense)


func _die() -> void:
	_is_dead = true
	_is_invulnerable = true
	set_physics_process(false)
	_character_texture.action_animation("disappear")
	_persist_stats()


func _apply_hit_knockback(hit_origin: Vector2) -> void:
	var knockback_direction: float = 0.0
	if global_position.x > hit_origin.x:
		knockback_direction = 1.0
	elif global_position.x < hit_origin.x:
		knockback_direction = -1.0

	if knockback_direction == 0.0:
		knockback_direction = -1.0 if _character_texture.flip_h else 1.0

	velocity.x = knockback_direction * _hit_knockback_x
	velocity.y = _hit_knockback_y
	_hit_stun_remaining = _hit_stun_time


func _update_dash_timers(delta: float) -> void:
	if _dash_time_remaining > 0.0:
		_dash_time_remaining = max(0.0, _dash_time_remaining - delta)
	if _dash_cooldown_remaining > 0.0:
		_dash_cooldown_remaining = max(0.0, _dash_cooldown_remaining - delta)
	if _dash_attack_combo_remaining > 0.0:
		_dash_attack_combo_remaining = max(0.0, _dash_attack_combo_remaining - delta)

	if _current_stamina < _max_stamina:
		_current_stamina = min(_max_stamina, _current_stamina + (_stamina_recovery_per_second * delta))


func _try_start_dash() -> bool:
	if not Input.is_action_just_pressed("dash"):
		return false
	if _is_dead or _is_invulnerable:
		return false
	if _character_texture.is_on_action():
		return false
	if _dash_time_remaining > 0.0 or _dash_cooldown_remaining > 0.0:
		return false
	if _current_stamina < _dash_stamina_cost:
		return false

	var input_direction: float = Input.get_axis("move_left", "move_right")
	if input_direction != 0.0:
		_dash_direction = sign(input_direction)
	else:
		_dash_direction = -1.0 if _character_texture.flip_h else 1.0

	_dash_time_remaining = _dash_duration
	_dash_cooldown_remaining = _dash_cooldown
	_dash_attack_combo_remaining = max(_dash_attack_combo_window, _dash_duration)
	_current_stamina = max(0.0, _current_stamina - _dash_stamina_cost)
	return true


func get_current_stamina() -> float:
	return _current_stamina


func get_max_stamina() -> float:
	return _max_stamina


func _can_hit_target(enemy: BaseEnemy) -> bool:
	var target_id: int = enemy.get_instance_id()
	var now: float = _get_time_seconds()
	var last_hit_time: float = -INF
	if _last_hit_time_by_target.has(target_id):
		last_hit_time = float(_last_hit_time_by_target[target_id])
	return now - last_hit_time >= _attack_hit_cooldown


func _register_target_hit(enemy: BaseEnemy) -> void:
	_last_hit_time_by_target[enemy.get_instance_id()] = _get_time_seconds()


func _get_time_seconds() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _start_invuln_flash() -> void:
	if not _character_texture:
		return

	if _invuln_flash_tween:
		_invuln_flash_tween.kill()

	_invuln_flash_tween = create_tween()
	_invuln_flash_tween.tween_property(_character_texture, "modulate:a", 0.35, 0.05)
	_invuln_flash_tween.tween_property(_character_texture, "modulate:a", 1.0, 0.05)
	_invuln_flash_tween.tween_property(_character_texture, "modulate:a", 0.35, 0.05)
	_invuln_flash_tween.tween_property(_character_texture, "modulate:a", 1.0, 0.05)


func _load_persistent_stats() -> void:
	var save: SaveData = get_node_or_null("/root/save_data") as SaveData
	if not save:
		return

	var defaults: Dictionary = {
		"max_hp": _max_hp,
		"defense": _defense,
		"damage": _damage,
		"current_hp": _current_hp,
		"has_sword": has_sword
	}
	var loaded: Dictionary = save.get_player_stats(defaults)
	_max_hp = max(1, int(loaded["max_hp"]))
	_defense = max(0, int(loaded["defense"]))
	_damage = max(1, int(loaded["damage"]))
	_current_hp = clamp(int(loaded["current_hp"]), 0, _max_hp)
	if _current_hp <= 0:
		_current_hp = _max_hp
	has_sword = bool(loaded["has_sword"])


func _persist_stats() -> void:
	var save: SaveData = get_node_or_null("/root/save_data") as SaveData
	if not save:
		return

	save.set_player_stats(_max_hp, _current_hp, _defense, _damage, has_sword)
