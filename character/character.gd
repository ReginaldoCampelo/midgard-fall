extends CharacterBody2D
class_name BaseCharacter

const MAX_JUMPS := 2
const GROUND_ATTACK_HITS := 3
const AIR_ATTACK_HITS := 2
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


func _physics_process(delta: float) -> void:
	_vertical_movement(delta)
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
	var direction := Input.get_axis("move_left", "move_right")

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
	var attack_step := _ground_attack_index
	_character_texture.action_animation("attack_" + str(attack_step))
	_spawn_attack_effect(GROUND_ATTACK_EFFECTS[attack_step - 1])
	_ground_attack_index = (_ground_attack_index % GROUND_ATTACK_HITS) + 1

	set_physics_process(false)
	_attack_combo.start()


func _start_air_attack() -> void:
	if _air_attack_count >= AIR_ATTACK_HITS:
		return

	var attack_step := _air_attack_index
	_character_texture.action_animation("air_attack_" + str(attack_step))
	_spawn_attack_effect(AIR_ATTACK_EFFECTS[attack_step - 1])
	_air_attack_count += 1
	_air_attack_index = (_air_attack_index % AIR_ATTACK_HITS) + 1

	set_physics_process(false)
	_attack_combo.start()

func _spawn_attack_effect(effect_path: String) -> void:
	var attack_offset := Vector2(ATTACK_EFFECT_OFFSET_X, 0)
	if _character_texture.flip_h:
		attack_offset.x *= -1

	global.spawn_effect(
		effect_path,
		attack_offset,
		global_position,
		_character_texture.flip_h
	)

func _start_throw_attack() -> void:
	_character_texture.action_animation("throw_sword")
	set_physics_process(false)
	has_sword = false
	return

func throw_attack(is_flipped: bool) -> void:
	var _sword: CharacterSword = _THROABLE_SWORD.instantiate()
	get_tree().root.call_deferred("add_child", _sword)
	_sword.global_position = global_position
	
	if is_flipped:
		_sword.direction = Vector2(-1, 0)
		return
	_sword.direction = Vector2(1, 0)

func _get_animation_name(base_name: String) -> String:
	return base_name + ("_with_sword" if has_sword else "")


func equip_sword() -> void:
	has_sword = true


func unequip_sword() -> void:
	has_sword = false


func _on_attack_combo_timeout() -> void:
	_ground_attack_index = 1
