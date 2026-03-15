extends ThrowableComponent
class_name CharacterSword

const _COLLECTABLE_SWORD: PackedScene = preload("res://collectables/sword/collectable_sword.tscn")

func _on_body_entered(body: Node2D) -> void:
	if _is_level_collision(body):
		_drop_collectable_sword()
		queue_free()

func _is_level_collision(body: Node2D) -> bool:
	return body is TileMap or body is TileMapLayer

func _drop_collectable_sword() -> void:
	var collectable_sword := _COLLECTABLE_SWORD.instantiate() as Node2D
	get_tree().root.call_deferred("add_child", collectable_sword)
	collectable_sword.global_position = global_position
	collectable_sword.rotation = direction.angle()

	var texture := collectable_sword.get_node_or_null("Texture") as AnimatedSprite2D
	if texture:
		texture.autoplay = &""
		texture.speed_scale = 0.0
		texture.call_deferred("stop")
		texture.set_deferred("frame", 0)
