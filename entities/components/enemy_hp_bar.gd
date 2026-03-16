extends Node2D
class_name EnemyHpBar

@export var _width: float = 30.0
@export var _height: float = 2.0
@export var _bg_color: Color = Color(0.12, 0.12, 0.12, 1)
@export var _fill_color: Color = Color(0.95, 0.15, 0.12, 1)

var _max_hp: int = 1
var _current_hp: int = 1


func set_values(current_hp: int, max_hp: int) -> void:
	_max_hp = max(1, max_hp)
	_current_hp = clamp(current_hp, 0, _max_hp)
	queue_redraw()


func _draw() -> void:
	# Draw centered, so the node position is the bar center.
	var base_rect := Rect2(Vector2(-_width * 0.5, 0), Vector2(_width, _height))
	draw_rect(base_rect, _bg_color, true)

	var fill_ratio := float(_current_hp) / float(_max_hp)
	var fill_width := _width * fill_ratio
	var fill_rect := Rect2(Vector2(-_width * 0.5, 0), Vector2(fill_width, _height))
	draw_rect(fill_rect, _fill_color, true)
