extends WArea2D

signal point

func _ready():
	grippable = false
	hoverable = true
	pointable = false
	clickable = false
	click_toggles = false
	
	self.connect("hovered", self, "_hovered")
	self.connect("not_hovered", self, "_not_hovered")
	
func _not_hovered(left):
	emit_signal("point", not left, false)
	
func _hovered(left):
	emit_signal("point", not left, true)
