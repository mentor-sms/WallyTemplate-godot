extends Node

const font_default = preload("res://dejavu-fonts-ttf-2.37/dejavu.tres")
const font_small = preload("res://dejavu-fonts-ttf-2.37/dejavu_small.tres")
const antialias = true

var lastId = -1

static func distance(p0, p1):
	var a = Vector2(p0 - p1)
	return sqrt((a.x * a.x) + (a.y * a.y))
	
static func rangef(start: float, end: float, step: float):
	var res = Array()
	var i = start
	while i < end:
		res.push_back(i)
		i += step
	return res
	
static func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

enum Pose {
	HANDS_TOUCH
}
const pose_count = 1

enum PosePoint {
	NOSE = 0,
	RIGHT_EYE_INNER,
	RIGHT_EYE,
	RIGHT_EYE_OUTER,
	LEFT_EYE_INNER,
	LEFT_EYE,
	LEFT_EYE_OUTER,
	RIGHT_EAR,
	LEFT_EAR,
	MOUTH_RIGHT,
	MOUTH_LEFT,
	RIGHT_SHOULDER,
	LEFT_SHOULDER,
	RIGHT_ELBOW,
	LEFT_ELBOW,
	RIGHT_WRIST,
	LEFT_WRIST,
	RIGHT_PINKY,
	LEFT_PINKY,
	RIGHT_INDEX,
	LEFT_INDEX,
	RIGHT_THUMB,
	LEFT_THUMB,
	RIGHT_HIP,
	LEFT_HIP,
	RIGHT_KNEE,
	LEFT_KNEE,
	RIGHT_ANKLE,
	LEFT_ANKLE,
	RIGHT_HEEL,
	LEFT_HEEL,
	RIGHT_FOOT_INDEX,
	LEFT_FOOT_INDEX
}
const point_count = PosePoint.RIGHT_FOOT_INDEX + 1

enum ExtraPosePoint {
	LEFT_HAND = 0,
	RIGHT_HAND,
	LEFT_FOOT,
	RIGHT_FOOT,
	NECK,
	TORSO_CENTRE,
	ASS
}
const extra_count = ExtraPosePoint.ASS + 1
