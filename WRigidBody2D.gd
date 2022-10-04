extends RigidBody2D

class_name WRigidBody2D

var templ2D : WCollisionTemplate2D = null

signal hovered(left)
signal not_hovered(left)
signal pointed(left)
signal not_pointed(left)
signal gripped(left)
signal released(left)
signal clicked(left)
signal toggled(left, is_toggled)
signal take_me(left)

func _take_me(left):
	emit_signal("take_me", left)

func _hovered(left):
	emit_signal("hovered", left)
	
func _not_hovered(left):
	emit_signal("not_hovered", left)
	
func _pointed(left):
	emit_signal("pointed", left)
	
func _not_pointed(left):
	emit_signal("not_pointed", left)
	
func _gripped(left):
	emit_signal("gripped", left)
	
func _released(left):
	emit_signal("released", left)
	
func _clicked(left):
	emit_signal("clicked", left)
	
func _toggled(left, is_toggled):
	emit_signal("toggled", left, is_toggled)

func my_init(lastId, pclass_name):
	if templ2D != null:
		return false
	templ2D = WCollisionTemplate2D.new(lastId + 1, "WRigidBody2D->" + pclass_name)
	# warning-ignore:return_value_discarded
	self.connect("body_entered", templ2D, "_on_body_entered")
	# warning-ignore:return_value_discarded
	self.connect("body_exited", templ2D, "_on_body_exited")
	# warning-ignore:return_value_discarded
	templ2D.connect("hovered", self, "_hovered")
	# warning-ignore:return_value_discarded
	templ2D.connect("not_hovered", self, "_not_hovered")
	# warning-ignore:return_value_discarded
	templ2D.connect("pointed", self, "_pointed")
	# warning-ignore:return_value_discarded
	templ2D.connect("not_pointed", self, "_not_pointed")
	# warning-ignore:return_value_discarded
	templ2D.connect("gripped", self, "_gripped")
	# warning-ignore:return_value_discarded
	templ2D.connect("released", self, "_released")
	# warning-ignore:return_value_discarded
	templ2D.connect("clicked", self, "_clicked")
	# warning-ignore:return_value_discarded
	templ2D.connect("toggled", self, "_toggled")
	# warning-ignore:return_value_discarded
	templ2D.connect("take_me", self, "_take_me")
	return true
