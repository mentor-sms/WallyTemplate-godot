extends Node

enum Step {
	NOT_WORKING = 0,
	TESTING = 1,
	WAITING = 2,
	AWAITING_KEYPOINTS = 3,
	CONFIGING = 4,
	WORKING = 5
}

enum StartStatus {
	FAILED = 0,
	SUCCEED = 1,
	WAITING = 2
}

# SETTINGS, don't change on runtime
const cams_max_idx = 3 # ilość kamer * 2 - 1
const sgbm = true
const ct_test_time = 10
var _poses_on = [0]
func get_poses_on():
	return _poses_on

# !--- DON'T CHANGE: ---!

signal started
signal ended
signal ticked
signal ct_aborted

var _wc:WallyController
var _wc_inited = false
var _camL = -1
var _camR = -1
var multi = Vector2(1, 1)
var move = Vector2(0, 0)
var pre = Vector2(0, 0)

var _1st_tick = true

var _ct_step = Step.NOT_WORKING
var _ct_pairs:PoolVector2Array
var _ct_curr_idx = 0
var _ct_time_elapsed = 0
var _ct_bad_idxs = []
var _ct_abort = false
var _ct_keypoints_exists = false

func set_step(step):
	if step == Step.NOT_WORKING:
		print("Step changed to NOT WORKIG.")
	elif step == Step.TESTING:
		print("Step changed to TESTING")
	elif step == Step.WAITING:
		print("Step changed to WAITING")
	elif step == Step.AWAITING_KEYPOINTS:
		print("Step changed to AWAITING_KEYPOINTS")
	elif step == Step.CONFIGING:
		print("Step changed to CONFIGING")
	elif step == Step.WORKING:
		print("Step changed to WORKING")
	else:
		print ("Step changed to UNKNOWN, resetting.")
		set_step(Step.NOT_WORKING)
		return
	
	_ct_step = step
	
	$WebcamTestView.visible = _ct_step <= Step.AWAITING_KEYPOINTS
	$GameBackgroundView.visible = _ct_step >= Step.WAITING
	$GameView.visible = _ct_step == Step.WORKING
	$ConfigureView.visible = _ct_step == Step.CONFIGING
	

func start(camL, camR, use_sgbm):
	print("Starting...")
	print("- left cam: ", camL)
	print("- right cam: ", camR)
	print("- using SGBM: ", use_sgbm)
	if _wc_inited:
		print("Already started, ending...")
		end()
	if _wc_inited:
		print("Ending failed.")
		return false
	var ok = false
	print("Initing...")
	if use_sgbm:
		ok = _wc.initSGBMByIdx(camL, camR)
	else:
		ok = _wc.initBMByIdx(camL, camR)
	_wc_inited = ok
	if not _wc_inited:
		end()
	if _wc_inited:
		print("Inited.")
		_1st_tick = true
		emit_signal("started")
	else:
		print("Initing failed.")
	return ok
	
func end():
	if _wc_inited:
		print("Ending...")
		_wc.closeWally()
		_1st_tick = true
		print("Ended.")
		_wc_inited = false
		emit_signal("ended")
	else:
		print("Already ended.")

func tick(poses = [$WPlayer.Pose.HANDS_TOUCH]):
	if _1st_tick:
		_wc.startTicking()
		_1st_tick = false
		print("First tick, ticked.")
		return true
		
	_wc.getTick()
		
	if _wc.wasShapeDetected():
		var build = _wc.build2DKeypoints(poses)
		
		if not build:
			print("Keyboints failed to build.")
			set_step(Step.NOT_WORKING)
			return false
			
		_ct_keypoints_exists = true
			
		for pid in _poses_on:
			$WPlayer.set_pose(pid, _wc.check2DPose(pid))
			
		var points = _wc.take2DKeypoints(0, multi, move, pre)
		var pidx = -1
		for p in points:
			pidx += 1
			$WPlayer.set_point(pidx, p)
			
		var left_hand = _wc.calc2DCentre([points[14], points[16], points[18], points[20]])
		var right_hand = _wc.calc2DCentre([points[15], points[17], points[19], points[21]])
		var left_foot = _wc.calc2DCentre([points[26], points[28], points[30]])
		var right_foot = _wc.calc2DCentre([points[27], points[29], points[31]])
		var torsop = _wc.calc2DCentre([points[10], points[11], points[22], points[23]])
		var neckp = _wc.calc2DCentre([points[10], points[11]])
		var assp = _wc.calc2DCentre([points[22], points[23]])
		
		$WPlayer.set_point(0, left_hand, true)
		$WPlayer.set_point(1, right_hand, true)
		$WPlayer.set_point(2, left_foot, true)
		$WPlayer.set_point(3, right_foot, true)
		$WPlayer.set_point(4, torsop, true)
		$WPlayer.set_point(5, neckp, true)
		$WPlayer.set_point(6, assp, true)
		emit_signal("ticked")
		return true
	else:
		return true

func _ready():
	set_step(Step.NOT_WORKING)
	print("Creating WallyController...")
	_wc = WallyController.new()
	print("WallyController created.")
	
func _bad_pair():
	print("Bad pair.")
	if not _ct_bad_idxs.has(_ct_curr_idx):
		_ct_bad_idxs.push_back(_ct_curr_idx)
	print("Bad pairs: ", _ct_bad_idxs)
	while (_ct_bad_idxs.has(_ct_curr_idx)):
		_ct_curr_idx += 1
		print("next: ", _ct_curr_idx)
		if _ct_curr_idx >= _ct_pairs.size():
			print("All pairs failed to test.")
			_ct_curr_idx = 0
			break
	if _ct_bad_idxs.size() == _ct_pairs.size():
		print("All pairs failed to start, aborting.")
		end()
		set_step(Step.NOT_WORKING)
		_ct_abort = true
		emit_signal("ct_aborted")

func _testing_process(_delta):
	if _ct_abort:
		return
		
	if _ct_step == Step.NOT_WORKING:
		if _ct_pairs.empty():
			print("Initing testing pairs...")
			for c0 in range(0, cams_max_idx + 1):
				for c1 in range(0, cams_max_idx + 1):
					if c0 != c1:
						_ct_pairs.push_back(Vector2(c0, c1))
			print("Testing pairs inited.")
		_ct_curr_idx = 0
		if not _ct_pairs.empty():
			set_step(Step.TESTING)
	elif _ct_step == Step.TESTING:
		print("Testing pair ", _ct_curr_idx, ": ", _ct_pairs[_ct_curr_idx])
		_ct_keypoints_exists = false
		var _ct_testing = start(_ct_pairs[_ct_curr_idx].x, _ct_pairs[_ct_curr_idx].y, sgbm)
		if not _ct_testing:
			print("Pair failed to init.")
			_bad_pair()
		else:
			print("Pair inited.")
			set_step(Step.WAITING)
	elif _ct_step == Step.WAITING:
		var _ct_start = _wc.checkInit()
		if _ct_start == StartStatus.WAITING:
			return
		elif _ct_start == StartStatus.SUCCEED:
			print("Pair started.")
			set_step(Step.AWAITING_KEYPOINTS)
		else:
			print("Pair failed to start.")
			_bad_pair()
			set_step(Step.TESTING)
	elif _ct_step == Step.AWAITING_KEYPOINTS:
		if _ct_keypoints_exists:
			print("Pair tested successfully.")
			set_step(Step.CONFIGING)
	else:
		return

func _process(delta):
	if _ct_step >= Step.AWAITING_KEYPOINTS:
		tick()
	if _ct_step < Step.CONFIGING:
		_testing_process(delta)
