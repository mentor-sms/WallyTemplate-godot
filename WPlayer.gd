extends Node

const glob = preload("res://Globals.gd")
var lhand
var rhand

var _points:PoolVector2Array
var _poses = []

var has_points = false

func get_point(pid, extra = false):
	if extra:
		pid += glob.point_count
	return _points[int(pid)]

func set_pose(pid, detected):
	_poses[pid] = detected
	
func set_visibility(visible):
	lhand.carpus.visible = visible
	rhand.carpus.visible = visible
	
func set_point(pid, point, extra = false):
	if extra:
		var rpid = pid + glob.point_count
		_points[int(rpid)] = point
	else:
		_points[int(pid)] = point
	if extra:
		if pid == glob.ExtraPosePoint.LEFT_HAND:
			lhand.pos_carpus = point
		elif pid == glob.ExtraPosePoint.RIGHT_HAND:
			rhand.pos_carpus = point
	else:
		if pid == glob.PosePoint.LEFT_INDEX:
			lhand.pos_index = point
		elif pid == glob.PosePoint.LEFT_THUMB:
			lhand.pos_thumb = point
		elif pid == glob.PosePoint.LEFT_PINKY:
			lhand.pos_pinky = point
		elif pid == glob.PosePoint.RIGHT_INDEX:
			rhand.pos_index = point
		elif pid == glob.PosePoint.RIGHT_THUMB:
			rhand.pos_thumb = point
		elif pid == glob.PosePoint.RIGHT_PINKY:
			rhand.pos_pinky = point
		elif pid == glob.PosePoint.LEFT_WRIST:
			lhand.pos_wrist = point
		elif pid == glob.PosePoint.RIGHT_WRIST:
			rhand.pos_wrist = point
		elif pid == glob.PosePoint.LEFT_EAR or pid == glob.PosePoint.RIGHT_EAR:
			var lear = get_point(glob.PosePoint.LEFT_EAR, false)
			var rear = get_point(glob.PosePoint.RIGHT_EAR, false)

func _ready():
	lhand = $Hand
	rhand = load("res://Hand.gd").new(false)
	add_child(rhand)
	
	for _p in range(0, glob.point_count + glob.extra_count):
		_points.push_back(Vector2(-1, -1))
	for _p in range(0, glob.pose_count):
		_poses.push_back(false)
