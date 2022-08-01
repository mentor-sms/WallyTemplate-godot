extends WRigidBody2D

func _ready():
	templ2D.grippable = true
	templ2D.hoverable = false
	templ2D.pointable = false
	templ2D.clickable = false
	templ2D.click_toggles = true
