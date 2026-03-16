extends Node
class_name SaveData

const _SAVE_PATH := "user://save_data.cfg"
const _SECTION_PLAYER := "player"

var _config: ConfigFile = ConfigFile.new()
var _is_loaded: bool = false


func _ready() -> void:
	load_data()


func load_data() -> void:
	var result: int = _config.load(_SAVE_PATH)
	_is_loaded = result == OK
	if not _is_loaded:
		_config = ConfigFile.new()


func save_data() -> void:
	_config.save(_SAVE_PATH)


func get_player_stats(default_stats: Dictionary) -> Dictionary:
	var stats: Dictionary = default_stats.duplicate(true)
	if not _is_loaded:
		return stats

	stats["max_hp"] = int(_config.get_value(_SECTION_PLAYER, "max_hp", stats["max_hp"]))
	stats["defense"] = int(_config.get_value(_SECTION_PLAYER, "defense", stats["defense"]))
	stats["damage"] = int(_config.get_value(_SECTION_PLAYER, "damage", stats["damage"]))
	stats["current_hp"] = int(_config.get_value(_SECTION_PLAYER, "current_hp", stats["current_hp"]))
	stats["has_sword"] = bool(_config.get_value(_SECTION_PLAYER, "has_sword", stats["has_sword"]))
	return stats


func set_player_stats(max_hp: int, current_hp: int, defense: int, damage: int, has_sword: bool) -> void:
	_config.set_value(_SECTION_PLAYER, "max_hp", max_hp)
	_config.set_value(_SECTION_PLAYER, "current_hp", current_hp)
	_config.set_value(_SECTION_PLAYER, "defense", defense)
	_config.set_value(_SECTION_PLAYER, "damage", damage)
	_config.set_value(_SECTION_PLAYER, "has_sword", has_sword)
	save_data()
	_is_loaded = true
