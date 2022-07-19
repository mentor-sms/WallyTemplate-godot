extends RigidBody2D

var grippable = false
var hoverable = false
var pointable = false
var clickable = false

var use_left_hand = true
var use_right_hand = true

signal hovered
signal not_hovered
signal pointed
signal not_pointed
signal gripped
signal released
signal clicked

var _entered_left = false
var _entered_right = false

var _gripping_left = false
var _pointing_left = false
var _hovering_left = false
var _gripping_right = false
var _pointing_right = false
var _hovering_right = false

func _ready():
	self.connect("body_entered", self, "_on_WRigidBody2D_body_entered")
	self.connect("body_exited", self, "_on_WRigidBody2D_body_exited")
	
func _hand_hovering(left):
	if not hoverable:
		return
	if left:
		_hovering_left = true
	else:
		_hovering_right = true
		
	emit_signal("hovered", left)
	
func _hand_not_hovering(left):
	if left:
		_hovering_left = false
	else:
		_hovering_right = false
		
	emit_signal("not_hovered", left)
	
func _hand_gripping(left):
	if not grippable:
		return
	if left:
		_gripping_left = true
	else:
		_gripping_right = true
		
	emit_signal("gripped", left)
	
func _hand_releasing(left):
	if left:
		_gripping_left = false
	else:
		_gripping_right = false
		
	emit_signal("released", left)
	
func _hand_pointing(left):
	if not pointable:
		return
	if left:
		_pointing_left = true
	else:
		_pointing_right = true
		
	emit_signal("pointed", left)
	
func _hand_not_pointing(left, click = false):
	if left:
		_pointing_left = false
	else:
		_pointing_right = false
		
	emit_signal("not_pointed", left)
	
	if clickable and click:
		emit_signal("clicked", left)
	
func _on_WRigidBody2D_body_exited(body):
	var hand = body as Hand
	if hand and (hand.is_left() and _entered_left) or (not hand.is_left() and _entered_right):
		hand.disconnect("gripping", self, "_hand_gripping")
		hand.disconnect("releasing", self, "_hand_releasing")
		hand.disconnect("pointing", self, "_hand_pointing")
		hand.disconnect("not_pointing", self, "_hand_not_pointing")
		hand.disconnect("hovering", self, "_hand_hovering")
		hand.disconnect("not_hovering", self, "_hand_not_hovering")
		
		hand.emit_signal("not_hovering")
			
		if hand.pointing:
			hand.emit_signal("not_pointing")

func _on_WRigidBody2D_body_entered(body):
	var hand = body as Hand
	if hand.is_left():
		if not use_left_hand:
			return
	else:
		if not use_right_hand:
			return
			
	if hand and ((hand.is_left() and use_left_hand and not _entered_left) or (not hand.is_left() and use_right_hand and not _entered_right)):
		hand.connect("gripping", self, "_hand_gripping", [hand.is_left()])
		hand.connect("releasing", self, "_hand_releasing", [hand.is_left()])
		hand.connect("pointing", self, "_hand_pointing", [hand.is_left()])
		hand.connect("not_pointing", self, "_hand_not_pointing", [hand.is_left()])
		hand.connect("hovering", self, "_hand_hovering", [hand.is_left()])
		hand.connect("not_hovering", self, "_hand_not_hovering", [hand.is_left()])
		
		hand.emit_signal("hovering")
			
		if hand.pointing:
			hand.emit_signal("pointing")
