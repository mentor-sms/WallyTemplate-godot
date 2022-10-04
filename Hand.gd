extends KinematicBody2D

class_name Hand

signal gripping(templ)
signal releasing(templ)
signal pointing(templ)
signal not_pointing(templ)
signal hovering(templ)
signal not_hovering(templ)
signal moved(pos)

const glob = preload("res://Globals.gd")

var pos_wrist : Vector2 = Vector2(0, 0)
var pos_carpus : Vector2 = Vector2(0, 0)

var is_gripping : bool = false
var is_pointing : bool = false
var inside_uid = -1

var _co_ge_sho : Vector2 = Vector2(0, 0)
var use_menu : bool = false

var _left : bool
func is_left():
	return _left

var carpus : Sprite = Sprite.new()

func set_menu(use, co_ge_sho):
	_co_ge_sho = co_ge_sho
	use_menu = use

var butt_moar
var butt_show
var butt_hide
var butt_grab
var butt_point

var side_set = false
func set_side(left):
	print(name, " set as left: ", left)
	_left = left
	if _left:
		carpus.set_texture(load("res://imgs/wplayer/lhand.png"))
	else:
		carpus.set_texture(load("res://imgs/wplayer/rhand.png"))
	side_set = true
	
	carpus.hframes = 3
	carpus.set_frame(0)
	carpus.scale = Vector2(0.5, 0.5)
	
	butt_moar.templ2D.assoc_left = _left
	butt_moar.templ2D.assoc_right = not _left
	butt_show.templ2D.assoc_left = _left
	butt_show.templ2D.assoc_right = not _left
	butt_hide.templ2D.assoc_left = _left
	butt_hide.templ2D.assoc_right = not _left
	butt_grab.templ2D.assoc_left = _left
	butt_grab.templ2D.assoc_right = not _left
	butt_point.templ2D.assoc_left = _left
	butt_point.templ2D.assoc_right = not _left

func _ready():
	butt_moar = get_node("Menu/ButtonMoar")
	butt_show = get_node("Menu/ButtonShow")
	butt_hide = get_node("Menu/ButtonHide")
	butt_grab = get_node("Menu/ButtonGrab")
	butt_point = get_node("Menu/ButtonPoint")
	
	add_child(carpus)
	
func _grab(left, grab):
	print("in grab: ", inside_uid, left, _left, grab, is_pointing, is_gripping, grab)
	if inside_uid == -1:
		return
	print("a")
	if left != _left:
		return
	print("b")
	if grab && is_pointing:
		return
	print("c")
	if is_gripping != grab:
		print("d")
		is_gripping = grab
		if grab:
			print("hand is gripping ", inside_uid)
			emit_signal("gripping", inside_uid)
		else:
			print("hand is releasing ", inside_uid)
			emit_signal("releasing", inside_uid)
	
func _point(left, point):
	if left != _left:
		return
	if point && is_gripping:
		return
	if is_pointing != point:
		is_pointing = point
		if point:
			print("hand is pointing ", inside_uid)
			emit_signal("pointing", inside_uid)
		else:
			print("hand is not pointing ", inside_uid)
			emit_signal("not_pointing", inside_uid)
	
func _process(_delta):
	if !side_set:
		return
		
	carpus.set_global_position(pos_wrist)
	
	carpus.look_at(pos_carpus)
	#carpus.rotate(PI)
	
	var cshape = get_node("CollisionShape2D")
	cshape.shape.radius = 25
	cshape.set_global_position(pos_carpus)
		
	var menu = get_node("Menu")
	
	menu.visible = use_menu
	
	if use_menu:
		var sho
		if _left:
			sho = get_parent().get_point(glob.PosePoint.LEFT_SHOULDER, false)
		else:
			sho = get_parent().get_point(glob.PosePoint.RIGHT_SHOULDER, false)
		sho.x += _co_ge_sho.x
		sho.y += _co_ge_sho.y
		
		var sarea = get_node("Menu/SizeArea/CollisionShape2D")
		
		var tpos = sho
		if _left:
			tpos.x -= sarea.shape.extents.x * 2
			tpos.y -= sarea.shape.extents.y * 2
		else:
			tpos.y -= sarea.shape.extents.y * 2
			
		var rect = Rect2(tpos, Vector2(sarea.shape.extents.x * 2, sarea.shape.extents.y * 2))
		
		var bres = get_parent().get_parent().board_res
		
		if rect.position.x < 0:
			rect.position.x = 0
		elif rect.position.x + rect.size.x > bres.x:
			rect.position.x = bres.x - rect.size.x
			
		if rect.position.y < 0:
			rect.position.y = 0
		elif rect.position.y + rect.size.y > bres.y:
			rect.position.y = bres.y - rect.size.y
			
		var defx = tpos.x - rect.position.x
		var defy = tpos.y - rect.position.y
		
		sho.x -= defx
		sho.y -= defy
			
		menu.position = sho
		
	if is_gripping:
		carpus.set_frame(1)
	elif is_pointing:
		carpus.set_frame(2)
	else:
		carpus.set_frame(0)
	
	emit_signal("moved", pos_carpus)
