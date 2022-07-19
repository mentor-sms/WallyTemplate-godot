extends RigidBody2D

class_name Hand

signal gripping
signal releasing
signal pointing
signal not_pointing
signal hovering
signal not_hovering

const glob = preload("res://Globals.gd")

var pos_wrist:Vector2 = Vector2(0, 0)
var pos_carpus:Vector2 = Vector2(0, 0)

var gripping = false
var pointing = false

var _co_ge_sho:Vector2 = Vector2(0, 0)
var use_menu:bool = false

var _left:bool
func is_left():
	return _left

var carpus:Sprite = Sprite.new()

func set_menu(co_ge_sho):
	_co_ge_sho = co_ge_sho
	use_menu = true

func _init(left = true):	
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
	
func _process(delta):
	carpus.set_global_position(pos_wrist)
	
	carpus.look_at(pos_carpus)
	carpus.rotate(PI)
	
	$CollisionShape2D.shape.radius = glob.distance(pos_wrist, pos_carpus)
	
	if use_menu:
		var sho
		if _left:
			sho = get_parent().get_point(glob.PosePoint.LEFT_SHOULDER, false)
		else:
			sho = get_parent().get_point(glob.PosePoint.RIGHT_SHOULDER, false)
		sho.x += _co_ge_sho.x
		sho.y += _co_ge_sho.y
		$Menu.position = sho
		
		if gripping:
			carpus.set_frame(1)
		elif pointing:
			carpus.set_frame(2)
		else:
			carpus.set_frame(0)
