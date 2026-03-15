extends CollectableComponent
class_name CollectableSword

func _consume(_body: BaseCharacter) -> void:
	_body.equip_sword()
	queue_free()
