extends TextureRect

const glob = preload("res://Globals.gd")

var snap_out:Dictionary
var do_snap:bool = false
signal snapping

const pts_color = Color.darkblue
const pts_text_color = Color.blue
const pts_thickness = 3
const pts_text = true
const lns_color = Color.aqua
const lns_thickness = 2

func _ready():
	pass
	
func draw_point(pos, thickness, color, draw_text, string_color = Color.transparent):
	draw_circle(pos, thickness, color)
	if not draw_text:
		return
	var string = "(" + String(int(pos.x)) + ", " + String(int(pos.y)) + ")"
	if string_color == Color.transparent:
		string_color = color
	pos.x += thickness * 2
	pos.y += thickness * 4
	draw_text(pos, string, string_color)
	
func draw_text(pos, string, color):
	for i in string.length():
		var c = string[i]
		var next_char = string[i + 1] if i + 1 < string.length() else ''
		var advance = draw_char(glob.font_small, pos, c, next_char, color)
		pos.x += advance
		
func _draw_point(pos):
	draw_point(pos, pts_thickness, pts_color, pts_text, pts_text_color)
	
func _draw_curve(inner: Vector2, mid: Vector2, outer: Vector2, color: Color, thickness: float, antialiasing: bool, step = 0.1, max_stages: int = 5, tolerance_degrees: float = 4):
		var curve = Curve2D.new()
		for p in glob.rangef(0, 1, step):
			curve.add_point(glob.quadratic_bezier(inner, mid, outer, p))
			
		var pts = curve.tessellate(max_stages, tolerance_degrees)
		draw_polyline(pts, color, thickness, antialiasing)

func _draw():
	emit_signal("snapping")
	
	if not visible:
		return
	
	var p = get_parent().get_node("WPlayer")
	
	var show_pose = get_parent().should_show_pose()
	var show_kps = get_parent().should_show_keypoints()
	
	if show_pose:
		_draw_curve(p.get_point(glob.PosePoint.LEFT_SHOULDER, false), p.get_point(glob.PosePoint.LEFT_ELBOW, false), p.get_point(glob.ExtraPosePoint.LEFT_HAND, true), lns_color, lns_thickness, glob.antialias)
		_draw_curve(p.get_point(glob.PosePoint.RIGHT_SHOULDER, false), p.get_point(glob.PosePoint.RIGHT_ELBOW, false), p.get_point(glob.ExtraPosePoint.RIGHT_HAND, true), lns_color, lns_thickness, glob.antialias)
		_draw_curve(p.get_point(glob.PosePoint.LEFT_HIP, false), p.get_point(glob.PosePoint.LEFT_KNEE, false), p.get_point(glob.ExtraPosePoint.LEFT_FOOT, true), lns_color, lns_thickness, glob.antialias)
		_draw_curve(p.get_point(glob.PosePoint.RIGHT_HIP, false), p.get_point(glob.PosePoint.RIGHT_KNEE, false), p.get_point(glob.ExtraPosePoint.RIGHT_FOOT, true), lns_color, lns_thickness, glob.antialias)
		
		draw_line(p.get_point(glob.PosePoint.RIGHT_SHOULDER, false), p.get_point(glob.PosePoint.RIGHT_HIP, false), lns_color, lns_thickness, glob.antialias)
		draw_line(p.get_point(glob.PosePoint.RIGHT_HIP, false), p.get_point(glob.PosePoint.LEFT_HIP, false), lns_color, lns_thickness, glob.antialias)
		draw_line(p.get_point(glob.PosePoint.LEFT_HIP, false), p.get_point(glob.PosePoint.LEFT_SHOULDER, false), lns_color, lns_thickness, glob.antialias)
		
		var nose = p.get_point(glob.PosePoint.NOSE, false)
		var lear = p.get_point(glob.PosePoint.LEFT_EAR, false)
		var rear = p.get_point(glob.PosePoint.RIGHT_EAR, false)
		var r = glob.distance(lear, rear)
		
		var head_color = lns_color
		if nose.y - r - 50 <= 0:
			head_color = Color.red
		
		draw_circle(p.get_point(glob.PosePoint.NOSE, false), r, head_color)
		
		nose.y += r
		
		var neck_len = glob.distance(p.get_point(glob.ExtraPosePoint.NECK, false), nose)
		nose.y += neck_len / 2
		
		_draw_curve(p.get_point(glob.PosePoint.LEFT_SHOULDER, false), nose, p.get_point(glob.PosePoint.RIGHT_SHOULDER, false), lns_color, lns_thickness, glob.antialias)
		
	if show_kps:
		for pt in [glob.PosePoint.LEFT_EYE, glob.PosePoint.RIGHT_EYE, glob.PosePoint.NOSE, 
		glob.PosePoint.LEFT_KNEE, glob.PosePoint.LEFT_SHOULDER, 
		glob.PosePoint.RIGHT_KNEE, glob.PosePoint.RIGHT_SHOULDER,
		glob.PosePoint.LEFT_ELBOW, glob.PosePoint.LEFT_HIP,
		glob.PosePoint.RIGHT_ELBOW, glob.PosePoint.RIGHT_HIP]:
			_draw_point(p.get_point(pt, false))
		
		for ept in [glob.ExtraPosePoint.LEFT_HAND, glob.ExtraPosePoint.RIGHT_HAND,
		glob.ExtraPosePoint.LEFT_FOOT, glob.ExtraPosePoint.RIGHT_FOOT, 
		glob.ExtraPosePoint.NECK, glob.ExtraPosePoint.TORSO_CENTRE, glob.ExtraPosePoint.ASS]:
			_draw_point(p.get_point(ept, true))
			
	
func _snap():
	if snap_out.empty():
		return
	elif int(snap_out["len"]) <= 0:
		return
	
	var img = Image.new()
	img.create_from_data(1920, 1080, false, Image.FORMAT_RGB8, snap_out["arr"])
	
	self.set_texture(img)
	
	update()

func _process(_delta):
	if not do_snap:
		return
	
	do_snap = false
	_snap()
