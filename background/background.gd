extends ParallaxBackground
class_name Background
	
@onready var _clouds: Array = [
	$CloudT1, $CloudT2, $CloudT3, $CloudT4, $CloudT5, $CloudT6, $CloudT7, $CloudT8
]

var _speed_values: Array[float] = [
	16.0, 16.0, 4.0, 4.0, 8.0, 8.0, 12.0, 12.0
]

func _physics_process(_delta: float) -> void:
	var _i: int = 0
	for cloud in _clouds:
		cloud.motion_offset.x -= _delta * _speed_values[_i]
		_i += 1
