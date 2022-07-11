extends RigidBody2D

var grippable = false
var pointable = false

signal gripped
signal released

func _ready():
	self.connect("body_entered", self, "_on_WRigidBody2D_body_entered")
	self.connect("body_exited", self, "_on_WRigidBody2D_body_exited")
	
func _on_WRigidBody2D_body_entered(body):
	var hand = body as Hand
	if hand:
		if grippable and hand.gripping:
			emit_signal("gripped", hand.is_left())

