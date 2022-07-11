extends CollisionShape2D

func is_grippable():
	return get_parent().grippable
	
func is_pointable():
	return get_parent().pointable

func _ready():
	pass
