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
		if pid == glob.PosePoint.LEFT_WRIST:
			lhand.pos_wrist = point
		elif pid == glob.PosePoint.RIGHT_WRIST:
			rhand.pos_wrist = point

func _ready():
	lhand = $LeftHand
	lhand.set_side(true)
	rhand = $RightHand
	rhand.set_side(false)
	
	# warning-ignore:return_value_discarded
	lhand.butt_grab.connect("grab", rhand, "_grab")
	# warning-ignore:return_value_discarded
	lhand.butt_point.connect("point", rhand, "_point")
	# warning-ignore:return_value_discarded
	lhand.butt_grab.connect("grab", lhand, "_grab")
	# warning-ignore:return_value_discarded
	lhand.butt_point.connect("point", lhand, "_point")
		
	# warning-ignore:return_value_discarded
	rhand.butt_grab.connect("grab", lhand, "_grab")
	# warning-ignore:return_value_discarded
	rhand.butt_point.connect("point", lhand, "_point")
	# warning-ignore:return_value_discarded
	rhand.butt_grab.connect("grab", rhand, "_grab")
	# warning-ignore:return_value_discarded
	rhand.butt_point.connect("point", rhand, "_point")
	
	for _p in range(0, glob.point_count + glob.extra_count):
		_points.push_back(Vector2(0, 0))
	for _p in range(0, glob.pose_count):
		_poses.push_back(false)
