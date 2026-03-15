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

@export_category("Variables")
@export var _is_inverted: bool = false
@export var _enemy_type: _types
@export var _move_speed: float = 128.0

var _on_floor: bool = false
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	_direction = [Vector2(-1, 0), Vector2(1, 0)].pick_random()
	_sync_floor_detection_ray()


func _physics_process(delta: float) -> void:
	_vertical_movement(delta)
	
	match _enemy_type:
		_types.STATIC:
			print("STATIC")
		_types.CHASE:
			print("CHASE")
		_types.WANDER:
			_wandering()
	
	move_and_slide()
	
	_enemy_texture.animate(velocity)
	
	
func _vertical_movement(_delta: float) -> void:
	if is_on_floor():
		if _on_floor == false:
			_enemy_texture.action_animate("ground")
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
