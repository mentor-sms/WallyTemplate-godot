extends WArea2D

class_name ButtonGrab

signal grab

var left_toggled : bool = false
var right_toggled : bool = false

func _ready():
	if templ2D.assoc_left:
		pass
	if templ2D.assoc_right:
		var other = get_parent().get_parent().get_parent().lhand.get_node("Menu/ButtonGrab")
		add_child(other.get_node("CollisionShape2D").duplicate(1))
		add_child(other.get_node("Sprite").duplicate(1))
	
	templ2D.grippable = false
	templ2D.hoverable = true
	templ2D.pointable = false
	templ2D.clickable = true
	templ2D.click_toggles = true
	
# warning-ignore:return_value_discarded
	self.connect("hovered", self, "_hovered")
# warning-ignore:return_value_discarded
	self.connect("not_hovered", self, "_not_hovered")
# warning-ignore:return_value_discarded
	self.connect("toggled", self, "_toggled")
	
func _not_hovered(left):
	if (left and left_toggled) or (not left and right_toggled):
		return
	emit_signal("grab", not left, false)
	
func _hovered(left):
	if (left and left_toggled) or (not left and right_toggled):
		return
	emit_signal("grab", not left, true)
	
func _toggled(left, toggled):
	if left:
		left_toggled = toggled
	else:
		right_toggled = toggled
