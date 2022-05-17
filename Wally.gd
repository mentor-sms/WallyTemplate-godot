extends Node

# SETTINGS, don't change on runtime
const cams_max_idx = 3
const sgbm = true
const ct_test_time = 10
var _poses_on = [Pose.HANDS_TOUCH]
func get_poses_on():
	return _poses_on

# !--- DON'T CHANGE: ---!

signal started
signal ended

var _wc:WallyController
var _wc_inited = false
var _camL = -1
var _camR = -1
var multi = Vector2(1, 1)
var move = Vector2(0, 0)
var pre = Vector2(0, 0)

var _1st_tick = true

var _ct_step = 0
var _ct_pairs:PoolVector2Array
var _ct_testing = false
var _ct_curr_idx = 0
var _ct_time_elapsed = 0

func start(camL, camR, use_sgbm):
	if _wc_inited:
		end()
	if _wc_inited:
		return false
	var ok = false
	if use_sgbm:
		ok = _wc.initSGBMByIdx(camL, camR)
	else:
		ok = _wc.initBMByIdx(camL, camR)
	_wc_inited = ok
	if _wc_inited:
		_1st_tick = true
		emit_signal("started")
	return ok
	
func end():
	var ok = true
	if _wc_inited:
		ok = _wc.end()
	if ok:
		_wc_inited = false
		emit_signal("ended")

func tick(poses = [Pose.HANDS_TOUCH]):
	var ticked = _wc.tick()
	
	if not ticked:
		_ct_step = 0
		return false
		
	if _1st_tick:
		_1st_tick = false
		return true
		
	if _wc.wasShapeDetected():
		var build = _wc.build2DKeypoints()
		
		if not build:
			_ct_step = 0
			return false
			
		for pid in _poses_on:
			$WPlayer.set_pose(pid, _wc.check2DPose(pid))
			
		var points = _wc.take2DKeypoints(0, multi, move, pre)
		var pidx = -1
		for p in points:
			pidx += 1
			$WPlayer.set_point(pidx, p)
		
		$WPlayer.set_point(Pose.
		
	return true

func _ready():
	_wc = WallyController.new()

func _physics_process(delta):
	pass

func _testing_process(delta):
	if _ct_step == 0:
		if _ct_pairs.empty():
			for c0 in range(0, cams_max_idx + 1):
				for c1 in range(0, cams_max_idx + 1):
					if c0 != c1:
						_ct_pairs.push_back(Vector2(c0, c1))
		_ct_curr_idx = 0
		_ct_testing = false
		if not _ct_pairs.empty():
			_ct_step = 1
	if _ct_step == 1:
		if not _ct_testing:
			_ct_testing = start(_ct_pairs[_ct_curr_idx].x, _ct_pairs[_ct_curr_idx].y, sgbm)
			if not _ct_testing:
				_ct_curr_idx += 1
				if _ct_curr_idx >= _ct_pairs.size():
					_ct_curr_idx = 0
			else:
				
			

func _process(delta):
	if _ct_step <= 2:
		_testing_process(delta)
	pass
