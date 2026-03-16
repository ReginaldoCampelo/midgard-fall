extends ThrowableComponent
class_name CharacterSword

const _COLLECTABLE_SWORD: PackedScene = preload("res://collectables/sword/collectable_sword.tscn")
const _RICOCHET_Y_SPEED: float = -220.0
const _RICOCHET_X_MULTIPLIER: float = 0.7

@export var _gravity: float = 900.0

var _velocity: Vector2 = Vector2.ZERO
var _throw_damage: int = 2
var _is_ricochet: bool = false
var _has_hit_enemy: bool = false
var _last_hit_time_by_target: Dictionary = {}
var _hit_cooldown: float = 0.08


func _ready() -> void:
	_velocity = direction.normalized() * _move_speed


func set_throw_damage(damage_amount: int) -> void:
	_throw_damage = max(1, damage_amount)


func _on_body_entered(body: Node2D) -> void:
	var enemy: BaseEnemy = body as BaseEnemy
	if enemy and not _has_hit_enemy and _can_hit_target(enemy):
		_register_target_hit(enemy)
		enemy.receive_damage(_throw_damage, global_position, true, true)
		_start_ricochet()
		return

	if _is_level_collision(body):
		_drop_collectable_sword(_velocity.angle())
		queue_free()


func _physics_process(delta: float) -> void:
	if _velocity == Vector2.ZERO:
		_velocity = direction.normalized() * _move_speed

	if _is_ricochet:
		_velocity.y += _gravity * delta

	global_position += _velocity * delta

func _is_level_collision(body: Node2D) -> bool:
	return body is TileMap or body is TileMapLayer


func _start_ricochet() -> void:
	_has_hit_enemy = true
	_is_ricochet = true
	_velocity.x = -_velocity.x * _RICOCHET_X_MULTIPLIER
	_velocity.y = _RICOCHET_Y_SPEED


func _can_hit_target(enemy: BaseEnemy) -> bool:
	var target_id: int = enemy.get_instance_id()
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var last_hit_time: float = -INF
	if _last_hit_time_by_target.has(target_id):
		last_hit_time = float(_last_hit_time_by_target[target_id])
	return now - last_hit_time >= _hit_cooldown


func _register_target_hit(enemy: BaseEnemy) -> void:
	_last_hit_time_by_target[enemy.get_instance_id()] = float(Time.get_ticks_msec()) / 1000.0


func _drop_collectable_sword(hit_angle: float) -> void:
	var collectable_sword: Node2D = _COLLECTABLE_SWORD.instantiate() as Node2D
	get_tree().root.call_deferred("add_child", collectable_sword)
	collectable_sword.global_position = global_position
	collectable_sword.rotation = hit_angle

	var texture: AnimatedSprite2D = collectable_sword.get_node_or_null("Texture") as AnimatedSprite2D
	if texture:
		texture.autoplay = &""
		texture.speed_scale = 0.0
		texture.call_deferred("stop")
		texture.set_deferred("frame", 0)
