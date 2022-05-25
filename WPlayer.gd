extends Node

enum Pose {
	HANDS_TOUCH
}
const pose_count = 1

enum PosePoint {
	NOSE = 0,
	LEFT_EYE_INNER,
	LEFT_EYE,
	LEFT_EYE_OUTER,
	RIGHT_EYE,
	RIGHT_EYE_OUTER,
	LEFT_EAR,
	RIGHT_EAR,
	MOUTH_LEFT,
	MOUTH_RIGHT,
	LEFT_SHOULDER,
	RIGHT_SHOULDER,
	LEFT_ELBOW,
	RIGHT_ELBOW,
	LEFT_WRIST,
	RIGHT_WRIST,
	LEFT_PINKY,
	RIGHT_PINKY,
	LEFT_INDEX,
	RIGHT_INDEX,
	LEFT_THUMB,
	RIGHT_THUMB,
	LEFT_HIP,
	RIGHT_HIP,
	LEFT_KNEE,
	RIGHT_KNEE,
	LEFT_ANKLE,
	RIGHT_ANKLE,
	LEFT_HEEL,
	RIGHT_HEEL,
	LEFT_FOOT_INDEX,
	RIGHT_FOOT_INDEX
}
const point_count = PosePoint.RIGHT_FOOT_INDEX + 1

enum ExtraPosePoint {
	LEFT_HAND,
	RIGHT_HAND,
	LEFT_FOOT,
	RIGHT_FOOT,
	NECK,
	TORSO_CENTRE,
	ASS
}
const extra_count = ExtraPosePoint.ASS + 1

var _points:PoolVector2Array
var _poses = []

func set_pose(pid, detected):
	_poses[pid] = detected
	
func set_point(pid, point, extra = false):
	if extra:
		pid += point_count
	_points[int(pid)] = point

func _ready():
	for _p in range(0, point_count + extra_count):
		_points.push_back(Vector2(-1, -1))
	for _p in range(0, pose_count):
		_poses.push_back(false)
