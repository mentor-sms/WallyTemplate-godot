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
signal take_me(left)

var _con_grip = false
var _con_hover = false
var _con_point = false

var _is_toggled = false

var _entered_left = false
var _entered_right = false

var _gripping_left = false
var _pointing_left = false
var _hovering_left = false
var _gripping_right = false
var _pointing_right = false
var _hovering_right = false

var _uid
func _init(id, pclass_name):
	_uid = id
	print("templ2D inited for ", pclass_name, " as ", _uid)

func _on_self_clicked(left):
	if click_toggles:
		_is_toggled = not _is_toggled
		emit_signal("toggled", left, _is_toggled)

func _hand_hovering(templ, left):
	if !hoverable || templ != _uid:
		return
	if left:
		_hovering_left = true
	else:
		_hovering_right = true
		
	emit_signal("hovered", left)

func _hand_not_hovering(templ, left):
	if templ != _uid:
		return
	if left:
		_hovering_left = false
	else:
		_hovering_right = false
		
	emit_signal("not_hovered", left)

func _hand_gripping(templ, left):
	if !grippable || templ != _uid:
		return
	if left:
		_gripping_left = true
	else:
		_gripping_right = true
		
	emit_signal("gripped", left)

func _hand_releasing(templ, left):
	if templ != _uid:
		return
	if left:
		_gripping_left = false
	else:
		_gripping_right = false
		
	emit_signal("released", left)
	
func _process(_delta):
	if _gripping_left == _gripping_right:
		return
		
	if _gripping_left:
		emit_signal("take_me", true)
	elif _gripping_right:
		emit_signal("take_me", false)
		

var _to_click = false

func _hand_pointing(templ, left):
	if (!pointable && !clickable) || templ != _uid:
		return
	if pointable:
		if left:
			_pointing_left = true
		else:
			_pointing_right = true
		emit_signal("pointed", left)
		
	if clickable:
		_to_click = true

func _hand_not_pointing(templ, left):
	if templ != _uid:
		return
	if left:
		_pointing_left = false
	else:
		_pointing_right = false
		
	emit_signal("not_pointed", left)
	
	
	if clickable && _to_click:
		emit_signal("clicked", left)
		_to_click = false

func _on_body_exited(body):
	_to_click = false
	
	var left
	if body is Hand:
		left = body._left
	else:
		return
	
	var hand = body
	
	if (left && _entered_left) || (!left && _entered_right):
		if hoverable:
			hand.emit_signal("not_hovering", _uid)
		
		if pointable || clickable:
			hand.emit_signal("not_pointing", _uid)
			
	if left:
		_entered_left = false
	else:
		_entered_right = false
		
	hand.inside_uid = -1

func _ready():
# warning-ignore:return_value_discarded
	self.connect("clicked", self, "_on_self_clicked")

func _on_body_entered(body):
	print(body, " entered ", _uid)
	var left
	if body is Hand:
		left = body._left
	else:
		return
	print(body, " was left: ", left)
	
	var hand = body
	if hand.inside_uid != -1:
		return
	hand.inside_uid = _uid
	
	if left:
		if !use_left_hand:
			hand.inside_uid = -1
			return
	else:
		if !use_right_hand:
			hand.inside_uid = -1
			return
			
	if (left && use_left_hand && !_entered_left) || (!left && use_right_hand && !_entered_right):
		if grippable && !_con_grip:
			hand.connect("gripping", self, "_hand_gripping", [left])
			hand.connect("releasing", self, "_hand_releasing", [left])
			_con_grip = true
		
		if hoverable:
			if !_con_hover:
				hand.connect("hovering", self, "_hand_hovering", [left])
				hand.connect("not_hovering", self, "_hand_not_hovering", [left])
				_con_hover = true
			hand.emit_signal("hovering", _uid)
		
		if pointable || clickable:
			if !_con_point:
				hand.connect("pointing", self, "_hand_pointing", [left])
				hand.connect("not_pointing", self, "_hand_not_pointing", [left])
				_con_point = true
			if (pointable || clickable) && hand.is_pointing:
				hand.emit_signal("pointing", _uid)
				
	if left:
		_entered_left = true
	else:
		_entered_right = true
