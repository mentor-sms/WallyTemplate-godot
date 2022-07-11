extends RigidBody2D

class_name Hand

signal gripping
signal releasing
signal pointing
signal not_pointing

const glob = preload("res://Globals.gd")

var pos_wrist:Vector2 = Vector2(0, 0)
var pos_carpus:Vector2 = Vector2(0, 0)
var pos_index:Vector2 = Vector2(0, 0)
var pos_thumb:Vector2 = Vector2(0, 0)
var pos_pinky:Vector2 = Vector2(0, 0)

var use_gestures = false

var dis_thumb_out = 0
var dis_index_out = 0
var dis_pinky_out = 0
var dis_thumb_in = 0
var dis_index_in = 0
var dis_pinky_in = 0
var dis_thumb_mid = 0
var dis_index_mid = 0
var dis_pinky_mid = 0
var dis_thumb_perc = 0
var dis_index_perc = 0
var dis_pinky_perc = 0

var to_pinky = 0
var to_index = 0
var to_thumb = 0

var out_thumb:bool = false
var out_index:bool = false
var out_pinky:bool = false

var gripping = false
var pointing = false

var _not_gripping_for = 0
var _not_pointing_for = 0
const _not_gripping_limit = 2.0
const _not_pointing_limit = 2.0

var _left:bool
func is_left():
	return _left

var carpus:Sprite = Sprite.new()
var cshape:CollisionShape2D = CollisionShape2D.new()

func _init(left = true):
	var shape = CircleShape2D.new()
	cshape.set_shape(shape)
	add_child(cshape)
	
	_left = left
	if left:
		carpus.set_texture(load("res://imgs/wplayer/lhand.png"))
	else:
		carpus.set_texture(load("res://imgs/wplayer/rhand.png"))
	carpus.hframes = 3
	carpus.set_frame(0)
	carpus.scale = Vector2(0.5, 0.5)
	add_child(carpus)
	
func _ready():
	pass
	
func set_stop_gestures():
	use_gestures = false
	
func set_use_gestures(pinky_in, thumb_in, index_in, pinky_out, thumb_out, index_out):
	print("Gesture points: ", pinky_in, ", ", thumb_in, ", ", index_in, ", ", pinky_out, ", ", thumb_out, ", ", index_out)
	use_gestures = true
	dis_pinky_in = pinky_in
	dis_thumb_in = thumb_in
	dis_index_in = index_in
	dis_pinky_out = pinky_out
	dis_thumb_out = thumb_out
	dis_index_out = index_out
	dis_pinky_mid = pinky_in + (pinky_out - pinky_in) / 2
	dis_thumb_mid = thumb_in + (thumb_out - thumb_in) / 2
	dis_index_mid = index_in + (index_out - index_in) / 2
	dis_pinky_perc = pinky_in * 100.0 / pinky_out
	dis_thumb_perc = thumb_in * 100.0 / thumb_out
	dis_index_perc = index_in * 100.0 / index_out
	
	
	
func _process(delta):
	carpus.set_global_position(pos_wrist)
	
	carpus.look_at(pos_carpus)
	carpus.rotate(PI)
	
	cshape.shape.radius = glob.distance(pos_wrist, pos_carpus)
	
	if use_gestures:
		to_pinky = glob.distance(pos_wrist, pos_pinky)
		to_thumb = glob.distance(pos_wrist, pos_thumb)
		to_index = glob.distance(pos_wrist, pos_index)
		
		if out_pinky:
			if to_pinky < dis_pinky_mid:
				out_pinky = false
		else:
			if to_pinky > dis_pinky_mid:
				out_pinky = true
		if out_thumb:
			if to_thumb < dis_thumb_mid:
				out_thumb = false
		else:
			if to_thumb > dis_thumb_mid:
				out_thumb = true
		if out_index:
			if to_index < dis_index_mid:
				out_index = false
		else:
			if to_index > dis_index_mid:
				out_index = true
				
		var grip = not out_pinky and not out_index and not out_thumb
		var point = not out_pinky and not out_thumb and out_index
		
		if gripping:
			if grip:
				_not_gripping_for = 0
			else:
				_not_gripping_for += delta
				if _not_gripping_for >= _not_gripping_limit:
					gripping = false
		elif grip:
			gripping = true
			
		if pointing:
			if point:
				_not_pointing_for = 0
			else:
				_not_pointing_for += delta
				if _not_pointing_for >= _not_pointing_limit:
					pointing = false
		elif point:
			pointing = true
			
		if gripping:
			carpus.set_frame(1)
		elif pointing:
			carpus.set_frame(2)
		else:
			carpus.set_frame(0)
	else:
		carpus.set_frame(0)
