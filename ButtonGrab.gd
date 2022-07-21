extends WArea2D

signal grab

var left_toggled = false
var right_toggled = false

func _ready():
	grippable = false
	hoverable = true
	pointable = false
	clickable = true
	click_toggles = true
	
	self.connect("hovered", self, "_hovered")
	self.connect("not_hovered", self, "_not_hovered")
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
