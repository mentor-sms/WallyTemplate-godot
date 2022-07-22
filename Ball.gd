extends WRigidBody2D

func _ready():
	grippable = true
	hoverable = false
	pointable = false
	clickable = false
	click_toggles = true

func _on_Ball_body_entered(body):
	pass # Replace with function body.
