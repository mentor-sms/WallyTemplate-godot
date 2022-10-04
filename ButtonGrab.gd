extends WArea2D

class_name ButtonGrab

signal grab

var left_grabbing : bool = false
var right_grabbing : bool = false

func _ready():
	var wall = get_parent().get_parent().get_parent().get_parent()
	my_init(wall.takeNewId(), "ButtonGrab")
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
	self.connect("hovered", self, "_b_hovered")
# warning-ignore:return_value_discarded
	self.connect("not_hovered", self, "_b_not_hovered")
	
func _b_not_hovered(left):
	pass
	
func _b_hovered(left):
	print("hovered on grab: ", left, right_grabbing, left_grabbing, templ2D.assoc_left, templ2D.assoc_right)
	var grabbing
	if left && templ2D.assoc_left:
		right_grabbing = !right_grabbing
		emit_signal("grab", false, right_grabbing)
	elif !left && templ2D.assoc_right:
		left_grabbing = !left_grabbing
		emit_signal("grab", true, left_grabbing)
		
