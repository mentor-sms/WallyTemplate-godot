extends WArea2D

func _ready():
	grippable = false
	hoverable = false
	pointable = false
	clickable = true
	click_toggles = false
	
	self.connect("clicked", self, "_clicked")
	
func _clicked(_left):
	var wplayer = get_parent().get_parent().get_parent()
	var buttons = ["ButtonMoar", "ButtonPoint", "ButtonGrab"]
	var other_menu
	if assoc_left and not assoc_right:
		other_menu = wplayer.rhand.get_node("Menu")
	elif assoc_right and not assoc_left:
		other_menu = wplayer.lhand.get_node("Menu")
	for bname in buttons:
		var button = other_menu.get_node(bname)
		# sprawdź jakie zmienne potrzebują set_deferred:
		button.visible = true
