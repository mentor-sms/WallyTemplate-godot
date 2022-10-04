extends WArea2D

class_name ButtonPoint

signal point

func _ready():
	var wall = get_parent().get_parent().get_parent().get_parent()
	my_init(wall.takeNewId(), "ButtonPoint")
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
	self.connect("hovered", self, "_b_hovered")
# warning-ignore:return_value_discarded
	self.connect("not_hovered", self, "_b_not_hovered")
	
func _b_not_hovered(left):
	print("unhovered on point")
	if templ2D.assoc_left && left:
		emit_signal("point", false, false)
	if templ2D.assoc_right && !left:
		emit_signal("point", true, false)
	
func _b_hovered(left):
	print("hovered on point")
	if templ2D.assoc_left && left:
		emit_signal("point", false, true)
	if templ2D.assoc_right && !left:
		emit_signal("point", true, true)
