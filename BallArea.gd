extends WArea2D

signal ball_clicked(left)
signal ball_taking(left)

func _ready():
	var wall = get_parent().get_parent().get_parent()
	my_init(wall.takeNewId(), "BallArea")
	
	templ2D.grippable = false
	templ2D.hoverable = true
	templ2D.pointable = false
	templ2D.clickable = false
	templ2D.click_toggles = false
	
	# warning-ignore:return_value_discarded
	templ2D.connect("clicked", self, "_b_clicked")
	# warning-ignore:return_value_discarded
	templ2D.connect("take_me", self, "_b_take_me")

func _b_clicked(left):
	emit_signal("ball_clicked", left)
	
func _b_take_me(left):
	emit_signal("ball_taking", left)
	
