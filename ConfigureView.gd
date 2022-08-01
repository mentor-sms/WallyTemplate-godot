extends TextureRect

const glob = preload("res://Globals.gd")

const guide_color_idle = Color.blue
const guide_color_set = Color.green
const guide_color_bad = Color.red

var show_guides : bool = false
var show_hguides : bool = false

var lc_idle : bool = true
var lf_idle : bool = true
var rc_idle : bool = true
var rf_idle : bool = true
var lh_idle : bool = true
var rh_idle : bool = true

var lh_rect : Rect2 = Rect2(0,0,0,0)
var rh_rect : Rect2 = Rect2(0,0,0,0)

func set_ball(visible, reset):
	$Ball.visible = visible
	$BallShelf.visible = visible
	if reset:
		$Ball.position.x = 455
		$Ball.position.y = 464
	
func set_guide_idle(left, far, idle):
	if left and far:
		lf_idle = idle
	elif left and not far:
		lc_idle = idle
	elif not left and far:
		rf_idle = idle
	else:
		rc_idle = idle
		
func set_hguide_idle(left, idle):
	if left:
		lh_idle = idle
	else:
		rh_idle = idle
		
func get_hguide(left):
	if left:
		return lh_rect
	return rh_rect

func get_guide(left, far):
	var wally = get_parent()
	var r14 = wally.board_res.x / 4 + 50
	if far:
		if left:
			print("far left: ", r14 - 50)
			return r14 - 50
		else:
			print("far right: ", wally.board_res.x - r14 - 50)
			return wally.board_res.x - r14 - 50
	else:
		r14 += r14 / 2 - 50
		if left:
			print("close right: ", r14 - 50)
			return r14 - 50
		else:
			print("close left: ", wally.board_res.x - r14 - 50)
			return wally.board_res.x - r14 - 50

func _draw():
	if not visible:
		return
		
	var wally = get_parent()
	var p = wally.get_node("WPlayer")
	var poly = PoolVector2Array()
	var c = p.get_point(glob.ExtraPosePoint.TORSO_CENTRE, true)
	
	poly.append(Vector2(c.x, c.y - 10))
	poly.append(Vector2(c.x + 10, c.y))
	poly.append(Vector2(c.x, c.y + 10))
	poly.append(Vector2(c.x - 10, c.y))
	poly.append(Vector2(c.x, c.y - 10))
	draw_polyline(poly, Color.red, 2, glob.antialias)
	draw_circle(c, 2, Color.red)
	
	if not show_guides and not show_hguides:
		return
	
	var cidle = guide_color_idle
	var cset = guide_color_set
	var cbad = guide_color_bad
	cidle.a = 0.5
	cset.a = 0.5
	cbad.a = 0.5
	
	if show_hguides:
		var lsho = p.get_point(glob.PosePoint.LEFT_SHOULDER, false)
		var rsho = p.get_point(glob.PosePoint.RIGHT_SHOULDER, false)
		var y = (lsho.y + rsho.y) / 2
		
		var lh_color
		if lh_idle:
			lh_color = cidle
		else:
			lh_color = cset
		var rh_color
		if rh_idle:
			rh_color = cidle
		else:
			rh_color = cset
			
		lh_rect = Rect2(lsho.x - 100, 0, 100, y)
		rh_rect = Rect2(rsho.x, 0, 100, y)
			
		draw_rect(lh_rect, lh_color, true)
		draw_rect(rh_rect, rh_color, true)

	if show_guides:		
		draw_line(Vector2(wally.board_res.x / 2, 0), Vector2(wally.board_res.x / 2, wally.board_res.y), Color.greenyellow, 4, glob.antialias)
		draw_line(Vector2(0, wally.board_res.y / 2), Vector2(wally.board_res.x, wally.board_res.y / 2), Color.greenyellow, 4, glob.antialias)
		
		var lc_color
		if lc_idle:
			lc_color = cidle
		else:
			lc_color = cset
		var lf_color
		if lf_idle:
			lf_color = cidle
		else:
			lf_color = cset
		var rc_color
		if rc_idle:
			rc_color = cidle
		else:
			rc_color = cset
		var rf_color
		if rf_idle:
			rf_color = cidle
		else:
			rf_color = cset
		
		for close in [lc_idle, rc_idle]:
			var bad = false
			for far in [lf_idle, rf_idle]:
				if close and far:
					bad = true
					lc_color = cbad
					rc_color = cbad
					lf_color = cbad
					rf_color = cbad
					break
			if bad:
				break
		
		#close:
		draw_rect(Rect2(get_guide(false, false), 0, 100, wally.board_res.y), rc_color, true)
		draw_rect(Rect2(get_guide(true, false), 0, 100, wally.board_res.y), lc_color, true)
				
		#far
		draw_rect(Rect2(get_guide(false, true), 0, 100, wally.board_res.y), rf_color, true)
		draw_rect(Rect2(get_guide(true, true), 0, 100, wally.board_res.y), lf_color, true)

func _ready():
	pass
