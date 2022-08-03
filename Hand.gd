extends RigidBody2D

class_name Hand

signal gripping
signal releasing
signal pointing
signal not_pointing
signal hovering
signal not_hovering

const glob = preload("res://Globals.gd")

var pos_wrist : Vector2 = Vector2(0, 0)
var pos_carpus : Vector2 = Vector2(0, 0)

var gripping : bool = false
var pointing : bool = false

var _co_ge_sho : Vector2 = Vector2(0, 0)
var use_menu : bool = false

var _left : bool
func is_left():
	return _left

var carpus : Sprite = Sprite.new()

func set_menu(co_ge_sho):
	_co_ge_sho = co_ge_sho
	use_menu = true

func _init(left = true):
	_left = left
	if left:
		name = "lhand"
		carpus.set_texture(load("res://imgs/wplayer/lhand.png"))
	else:
		name = "rhand"
		carpus.set_texture(load("res://imgs/wplayer/rhand.png"))
	carpus.hframes = 3
	carpus.set_frame(0)
	carpus.scale = Vector2(0.5, 0.5)
	
func _ready():
	if not _left:
		var other = get_parent().lhand
		var menu = Node2D.new()
		menu.name = "Menu"
		var cshape = CollisionShape2D.new()
		cshape.name = "CollisionShape2D"
		cshape.shape = other.get_node("CollisionShape2D").shape
		add_child(cshape, true)
		add_child(menu, true)
		menu.add_child(ButtonMoar.new(), true)
		menu.add_child(ButtonShow.new(), true)
		menu.add_child(ButtonHide.new(), true)
		menu.add_child(ButtonGrab.new(), true)
		menu.add_child(ButtonPoint.new(), true)
		
	add_child(carpus)
		
	get_node("Menu/ButtonMoar").templ2D.assoc_left = _left
	get_node("Menu/ButtonMoar").templ2D.assoc_right = not _left
	get_node("Menu/ButtonShow").templ2D.assoc_left = _left
	get_node("Menu/ButtonShow").templ2D.assoc_right = not _left
	get_node("Menu/ButtonHide").templ2D.assoc_left = _left
	get_node("Menu/ButtonHide").templ2D.assoc_right = not _left
	get_node("Menu/ButtonGrab").templ2D.assoc_left = _left
	get_node("Menu/ButtonGrab").templ2D.assoc_right = not _left
	get_node("Menu/ButtonPoint").templ2D.assoc_left = _left
	get_node("Menu/ButtonPoint").templ2D.assoc_right = not _left
	
	var other_hand
	if not _left:
		other_hand = get_parent().lhand
		
		# warning-ignore:return_value_discarded
		get_node("Menu/ButtonGrab").connect("grab", other_hand, "_grab")
		# warning-ignore:return_value_discarded
		get_node("Menu/ButtonPoint").connect("point", other_hand, "_point")
		# warning-ignore:return_value_discarded
		get_node("Menu/ButtonGrab").connect("grab", self, "_grab")
		# warning-ignore:return_value_discarded
		get_node("Menu/ButtonPoint").connect("point", self, "_point")
		
		# warning-ignore:return_value_discarded
		other_hand.get_node("Menu/ButtonGrab").connect("grab", self, "_grab")
		# warning-ignore:return_value_discarded
		other_hand.get_node("Menu/ButtonPoint").connect("point", self, "_point")
		# warning-ignore:return_value_discarded
		other_hand.get_node("Menu/ButtonGrab").connect("grab", other_hand, "_grab")
		# warning-ignore:return_value_discarded
		other_hand.get_node("Menu/ButtonPoint").connect("point", other_hand, "_point")
	
func _grab(left, grab):
	if left != _left:
		return
	if gripping != grab:
		if grab:
			emit_signal("gripping", left)
		else:
			emit_signal("releasing", left)
	gripping = grab
	
func _point(left, point):
	if left != _left:
		return
	if pointing != point:
		if point:
			emit_signal("pointing", left)
		else:
			emit_signal("not_pointing", left)
	pointing = point
	
func _process(_delta):
	carpus.set_global_position(pos_wrist)
	
	carpus.look_at(pos_carpus)
	carpus.rotate(PI)
	
	var cshape = get_node("CollisionShape2D")
	
	if not cshape:
		return
	
	cshape.shape.radius = glob.distance(pos_wrist, pos_carpus)
	
	if use_menu:
		get_node("Menu").visible = true
		
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
	else:
		get_node("Menu").visible = false
