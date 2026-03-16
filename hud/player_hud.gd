extends CanvasLayer
class_name PlayerHud

@export var _target_path: NodePath
@export var _stats_label: Label

var _target: BaseCharacter = null


func _ready() -> void:
	_resolve_target()
	_update_text()


func _process(_delta: float) -> void:
	if not is_instance_valid(_target):
		_resolve_target()
	_update_text()


func _resolve_target() -> void:
	if _target_path != NodePath():
		_target = get_node_or_null(_target_path) as BaseCharacter
	if is_instance_valid(_target):
		return
	_target = get_tree().get_first_node_in_group("player") as BaseCharacter


func _update_text() -> void:
	if not _stats_label:
		return

	if not is_instance_valid(_target):
		_stats_label.text = "HP --/--  STA --/--  DMG --  DEF --"
		return

	var sword_text: String = "ON" if _target.has_sword_equipped() else "OFF"
	_stats_label.text = "HP %d/%d  STA %d/%d  DMG %d  DEF %d  SW %s" % [
		_target.get_current_hp(),
		_target.get_max_hp(),
		int(round(_target.get_current_stamina())),
		int(round(_target.get_max_stamina())),
		_target.get_damage(),
		_target.get_defense(),
		sword_text
	]