extends WArea2D

class_name ButtonPoint

signal point

func _ready():
	if templ2D.assoc_left:
		pass
	if templ2D.assoc_right:
		var other = get_parent().get_parent().get_parent().lhand.get_node("Menu/ButtonPoint")
		add_child(other.get_node("CollisionShape2D").duplicate(1))
		add_child(other.get_node("Sprite").duplicate(1))
		
	templ2D.grippable = false
	templ2D.hoverable = true
	templ2D.pointable = false
	templ2D.clickable = false
	templ2D.click_toggles = false
	
# warning-ignore:return_value_discarded
	self.connect("hovered", self, "_hovered")
# warning-ignore:return_value_discarded
	self.connect("not_hovered", self, "_not_hovered")
	
func _not_hovered(left):
	emit_signal("point", not left, false)
	
func _hovered(left):
	emit_signal("point", not left, true)
