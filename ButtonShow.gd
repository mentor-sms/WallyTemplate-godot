extends WArea2D

class_name ButtonShow

func _ready():
	if templ2D.assoc_left:
		pass
	if templ2D.assoc_right:
		var other = get_parent().get_parent().get_parent().lhand.get_node("Menu/ButtonShow")
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
	var wplayer = get_parent().get_parent().get_parent()
	var buttons = ["ButtonMoar", "ButtonPoint", "ButtonGrab"]
	var other_menu
	if templ2D.assoc_left and not templ2D.assoc_right:
		other_menu = wplayer.rhand.get_node("Menu")
	elif templ2D.assoc_right and not templ2D.assoc_left:
		other_menu = wplayer.lhand.get_node("Menu")
	for bname in buttons:
		var button = other_menu.get_node(bname)
		# sprawdź jakie zmienne potrzebują set_deferred:
		button.visible = true
