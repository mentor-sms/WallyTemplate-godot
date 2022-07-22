extends WArea2D

func _ready():
	grippable = false
	hoverable = false
	pointable = false
	clickable = true
	click_toggles = false
	
	self.connect("clicked", self, "_clicked")
	
func _clicked(_left):
	var parent = get_parent()
	var buttons = ["ButtonHide", "ButtonShow", "ButtonMoar", "ButtonPoint", "ButtonGrab"]
	for bname in buttons:
		var button = parent.get_node(bname)
		# sprawdź jakie zmienne potrzebują set_deferred:
		button.visible = false

