extends Node

const glob = preload("res://Globals.gd")

var _points:PoolVector2Array
var _poses = []

func get_point(pid, extra = false):
	if extra:
		pid += glob.point_count
	return _points[int(pid)]

func set_pose(pid, detected):
	_poses[pid] = detected
	
func set_point(pid, point, extra = false):
	if extra:
		pid += glob.point_count
	_points[int(pid)] = point

func _ready():
	for _p in range(0, glob.point_count + glob.extra_count):
		_points.push_back(Vector2(-1, -1))
	for _p in range(0, glob.pose_count):
		_poses.push_back(false)
