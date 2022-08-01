extends WArea2D

class_name ButtonMoar

func _ready():
	if templ2D.assoc_left:
		pass
	if templ2D.assoc_right:
		var other = get_parent().get_parent().get_parent().lhand.get_node("Menu/ButtonMoar")
		add_child(other.get_node("CollisionShape2D").duplicate(1))
		add_child(other.get_node("Sprite").duplicate(1))
		
	templ2D.grippable = false
	templ2D.hoverable = false
	templ2D.pointable = false
	templ2D.clickable = true
	templ2D.click_toggles = false
	
# warning-ignore:return_value_discarded
	self.connect("clicked", self, "_clicked")
	
func _clicked(_left):
	var parent = get_parent()
	var buttons = ["ButtonHide", "ButtonShow"]
	for bname in buttons:
		var button = parent.get_node(bname)
		# sprawdź jakie zmienne potrzebują set_deferred:
		button.visible = not button.visible
