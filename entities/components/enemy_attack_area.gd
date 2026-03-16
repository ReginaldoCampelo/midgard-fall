extends Area2D
class_name EnemyAttackArea

@export_category("Variables")
@export var _attack_damage: int = 0
@export var _apply_knockback: bool = true
@export var _use_skill_damage: bool = false

func _on_body_entered(body: Node2D) -> void:
	var character: BaseCharacter = body as BaseCharacter
	if not character:
		return

	var should_apply_knockback: bool = _apply_knockback
	var enemy: BaseEnemy = _resolve_enemy()
	if enemy and not enemy.is_knocktable():
		should_apply_knockback = false

	character.receive_damage(_resolve_damage(), global_position, should_apply_knockback)


func _resolve_damage() -> int:
	if _attack_damage > 0:
		return _attack_damage

	var enemy: BaseEnemy = _resolve_enemy()
	if enemy:
		if _use_skill_damage:
			return enemy.get_skill_damage()
		return enemy.get_contact_damage()

	return 1


func _resolve_enemy() -> BaseEnemy:
	return get_parent() as BaseEnemy
