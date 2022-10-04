extends RigidBody2D

class_name Ball

var _lhand = null
var _rhand = null
var ball_was_clicked = false

signal ball_clicked

func _take_me(left):
	if left && _lhand:
		position = _lhand.pos_carpus
	elif !left && _rhand:
		position = _rhand.pos_carpus

func _ready():
	set_ball_as_button(position)
	
	# warning-ignore:return_value_discarded
	$BallArea.connect("ball_clicked", self, "_ball_clicked")
	# warning-ignore:return_value_discarded
	$BallArea.connect("ball_taking", self, "_take_me")
	
func _ball_clicked(_left):
	ball_was_clicked = true
	emit_signal("ball_clicked")

func set_ball_as_button(pos):
	ball_was_clicked = false
	$BallArea.templ2D.grippable = false
	$BallArea.templ2D.clickable = true
	mode = MODE_KINEMATIC
	position = pos
	
func set_ball_as_movable(lhand : Hand, rhand : Hand, pos):
	mode = MODE_RIGID
	ball_was_clicked = false
	$BallArea.templ2D.grippable = true
	$BallArea.templ2D.clickable = false
	_lhand = lhand
	_rhand = rhand
	position = pos
