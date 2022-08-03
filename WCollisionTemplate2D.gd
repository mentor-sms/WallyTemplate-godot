class_name WCollisionTemplate2D

var assoc_left = false
var assoc_right = false

var grippable = false
var hoverable = false
var pointable = false
var clickable = false
var click_toggles = false

var use_left_hand = true
var use_right_hand = true

signal hovered(left)
signal not_hovered(left)
signal pointed(left)
signal not_pointed(left)
signal gripped(left)
signal released(left)
signal clicked(left)
signal toggled(left, is_toggled)

var _is_toggled = false

var _entered_left = false
var _entered_right = false

var _gripping_left = false
var _pointing_left = false
var _hovering_left = false
var _gripping_right = false
var _pointing_right = false
var _hovering_right = false

func _ready():
# warning-ignore:return_value_discarded
	self.connect("clicked", self, "_on_self_clicked")

func _on_self_clicked(left):
	if click_toggles:
		_is_toggled = not _is_toggled
		emit_signal("toggled", left, _is_toggled)

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

func on_body_exited(body):
	var left
	if body.name == "lhand":
		left = true
	elif body.name == "rhand":
		left = false
	else:
		return
	
	var hand = body
	
	if (left and _entered_left) or (not left and _entered_right):
		if grippable:
			hand.disconnect("gripping", self, "_hand_gripping")
			hand.disconnect("releasing", self, "_hand_releasing")
			
		if hoverable:
			hand.disconnect("hovering", self, "_hand_hovering")
			hand.disconnect("not_hovering", self, "_hand_not_hovering")
			hand.emit_signal("not_hovering")
		
		if pointable:
			hand.disconnect("pointing", self, "_hand_pointing")
			hand.disconnect("not_pointing", self, "_hand_not_pointing")
			if hand.pointing:
				hand.emit_signal("not_pointing")	

func on_body_entered(body):
	var left
	if body.name == "lhand":
		left = true
	elif body.name == "rhand":
		left = false
	else:
		return
	
	var hand = body
	
	if left:
		if not use_left_hand:
			return
	else:
		if not use_right_hand:
			return
			
	if (left and use_left_hand and not _entered_left) or (not left and use_right_hand and not _entered_right):
		if grippable:
			hand.connect("gripping", self, "_hand_gripping", [left])
			hand.connect("releasing", self, "_hand_releasing", [left])
		
		if hoverable:
			hand.connect("hovering", self, "_hand_hovering", [left])
			hand.connect("not_hovering", self, "_hand_not_hovering", [left])
			hand.emit_signal("hovering")
			
		if pointable:
			hand.connect("pointing", self, "_hand_pointing", [left])
			hand.connect("not_pointing", self, "_hand_not_pointing", [left])
			if hand.pointing:
				hand.emit_signal("pointing")
