extends Node

const glob = preload("res://Globals.gd")

# SETTINGS, don't change on runtime
const cams_distance = 22
const cams_res = Vector2(960, 540)
const board_res = Vector2(1920, 1080)
const default_cams = Vector2(-1, -1)
const cams_max_idx = 5 # ilość kamer * 2 - 1
const sgbm = true
const ct_test_time = 10
const ct_kp_wait_time = 10
const co_match_wait_time = 10
const draw_webcam_background = false
const draw_keypoints = true
const draw_pose = true
var _poses_on = [0]
func get_poses_on():
	return _poses_on

# configuration
var multi = Vector2(board_res.x / cams_res.x, board_res.y / cams_res.y)
var move = Vector2(0, 0)
var pre = Vector2(0, 0)

var _show_webcam_background = false
func set_show_webcam_background(show):
	if draw_webcam_background:
		_show_webcam_background = show
		if show and not $GameBackgroundView.do_snap:
			snapping()
		
var _show_keypoints = false
func set_show_keypoints(show):
	if draw_keypoints:
		_show_keypoints = show
func should_show_keypoints():
	return _show_keypoints
		
var _show_pose = false
func set_show_pose(show):
	if draw_pose:
		_show_pose = show
func should_show_pose():
	return _show_pose

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

# !--- DON'T CHANGE: ---!

signal started
signal ended
signal ticked
signal ct_aborted

var _wc:WallyController
var _wc_inited = false
var _camL = -1
var _camR = -1

var _1st_tick = true

var _ct_step = Step.NOT_WORKING
var _ct_pairs:PoolVector2Array
var _ct_curr_idx = 0
var _ct_time_elapsed = 0
var _ct_bad_idxs = []
var _ct_abort = false
var _ct_keypoints_exists = false
var _ct_kp_waiting = 0

var _co_match_waiting = 0
var _co_step = 0

const config_fname = "user://config.json"

func set_label(string: String):
	$Background/TaskLabel.text = string
	$Background/TaskLabel.visible = not string.empty()

func set_step(step):
	if step == Step.NOT_WORKING:
		print("Step changed to NOT WORKIG.")
		set_label("Mentor Wally")
	elif step == Step.TESTING:
		print("Step changed to TESTING")
		set_label("Szukam kamer...")
	elif step == Step.WAITING:
		print("Step changed to WAITING")
		set_label("Testuję kamery...")
	elif step == Step.AWAITING_KEYPOINTS:
		print("Step changed to AWAITING_KEYPOINTS")
		set_label("Szukam sylwetki gracza...")
	elif step == Step.CONFIGING:
		print("Step changed to CONFIGING")
		_co_step = 0
		set_label("Konfiguracja")
	elif step == Step.WORKING:
		print("Step changed to WORKING")
		set_label("")
	else:
		print ("Step changed to UNKNOWN, resetting.")
		set_label("")
		set_step(Step.NOT_WORKING)
		return
	
	_ct_step = step
	
	$WebcamTestView.visible = _ct_step <= Step.AWAITING_KEYPOINTS
	$WebcamTestView/TimeoutLabel.visible = false
	$GameBackgroundView.visible = _ct_step >= Step.AWAITING_KEYPOINTS	
	$GameView.visible = _ct_step == Step.WORKING
	$ConfigureView.visible = _ct_step == Step.CONFIGING
	$ConfigureView/TimeoutLabel.visible = false
	$Background.visible = _ct_step != Step.WORKING
	
	set_show_webcam_background(_ct_step >= Step.AWAITING_KEYPOINTS)
	set_show_keypoints(_ct_step == Step.CONFIGING)
	set_show_pose(_ct_step > Step.AWAITING_KEYPOINTS)
	
	$WebcamTestView.update()
	$GameBackgroundView.update()
	$ConfigureView.update()
	$GameView.update()

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
		
func snapping():
	if _show_webcam_background:
		if _ct_step >= Step.AWAITING_KEYPOINTS:
			$GameBackgroundView.snap_out = _wc.snap()
		$GameBackgroundView.do_snap = true

func tick(poses = [glob.Pose.HANDS_TOUCH]):
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
			
		var left_hand = _wc.calc2DCentre([points[glob.PosePoint.LEFT_INDEX], points[glob.PosePoint.LEFT_THUMB], points[glob.PosePoint.LEFT_PINKY], points[glob.PosePoint.LEFT_WRIST]])
		var right_hand = _wc.calc2DCentre([points[glob.PosePoint.RIGHT_INDEX], points[glob.PosePoint.RIGHT_THUMB], points[glob.PosePoint.RIGHT_PINKY], points[glob.PosePoint.RIGHT_WRIST]])
		var left_foot = _wc.calc2DCentre([points[glob.PosePoint.LEFT_FOOT_INDEX], points[glob.PosePoint.LEFT_HEEL], points[glob.PosePoint.LEFT_ANKLE]])
		var right_foot = _wc.calc2DCentre([points[glob.PosePoint.RIGHT_FOOT_INDEX], points[glob.PosePoint.RIGHT_HEEL], points[glob.PosePoint.RIGHT_ANKLE]])
		var neckp = _wc.calc2DCentre([points[glob.PosePoint.LEFT_SHOULDER], points[glob.PosePoint.RIGHT_SHOULDER]])
		var assp = _wc.calc2DCentre([points[glob.PosePoint.LEFT_HIP], points[glob.PosePoint.RIGHT_HIP]])
		var torsop = _wc.calc2DCentre([neckp, assp])
		
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
	$GameBackgroundView.connect("snapping", self, "snapping")
	self.connect("ticked", $GameBackgroundView, "update")
	self.connect("ticked", $ConfigureView, "update")
	
func _bad_pair(blacklist):
	print("Bad pair.")
	var curr_bad = _ct_curr_idx
	if not _ct_bad_idxs.has(_ct_curr_idx) and blacklist:
		_ct_bad_idxs.push_back(_ct_curr_idx)
	print("Bad pairs: ", _ct_bad_idxs)
	while (_ct_bad_idxs.has(_ct_curr_idx) or (_ct_curr_idx == curr_bad and _ct_bad_idxs.size() + 1 != _ct_pairs.size())):
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

func _testing_process(delta):
	if _ct_abort:
		return
		
	if _ct_step == Step.NOT_WORKING:
		if _ct_pairs.empty():
			print("Initing testing pairs...")
			if default_cams.x >= 0 and default_cams.y >= 0 and default_cams.x != default_cams.y:
				print("Testing pairs forced to single pair.")
				_ct_pairs.push_back(default_cams)
			else:
				var file = File.new()
				var def = Vector2(-1, -1)
				if file.file_exists(config_fname):
					file.open(config_fname, File.READ)
					var data = parse_json(file.get_as_text())
					file.close()
					if typeof(data) == TYPE_DICTIONARY:
						def.x = data["camL"]
						def.y = data["camR"]
				if def.x >= 0 and def.y >= 0 and def.x <= cams_max_idx and def.y <= cams_max_idx and def.x != def.y:
					_ct_pairs.push_back(def)
					print("Default pair loaded.")
				for c0 in range(0, cams_max_idx + 1):
					for c1 in range(0, cams_max_idx + 1):
						var vec = Vector2(c0, c1)
						if c0 != c1 and (_ct_pairs.size() == 0 or (_ct_pairs.size() > 0 and _ct_pairs[0] != vec)):
							_ct_pairs.push_back(vec)
				print("Testing pairs inited.")
			_ct_curr_idx = 0
			
		if not _ct_pairs.empty() and not _ct_bad_idxs.size() == _ct_pairs.size():
			set_step(Step.TESTING)
	elif _ct_step == Step.TESTING:
		print("Testing pair ", _ct_curr_idx, ": ", _ct_pairs[_ct_curr_idx])
		$Background/TaskLabel.text = "Testuję kamery... (" + String(_ct_pairs[_ct_curr_idx].x) + ", " + String(_ct_pairs[_ct_curr_idx].y) + ")"
		_ct_keypoints_exists = false
		var _ct_testing = start(_ct_pairs[_ct_curr_idx].x, _ct_pairs[_ct_curr_idx].y, sgbm)
		if not _ct_testing:
			print("Pair failed to init.")
			_bad_pair(true)
		else:
			print("Pair inited.")
			set_step(Step.WAITING)
	elif _ct_step == Step.WAITING:
		var _ct_start = _wc.checkInit()
		if _ct_start == StartStatus.WAITING:
			return
		elif _ct_start == StartStatus.SUCCEED:
			print("Pair started.")
			_ct_kp_waiting = 0
			set_step(Step.AWAITING_KEYPOINTS)
		else:
			print("Pair failed to start.")
			set_step(Step.TESTING)
			_bad_pair(true)
	elif _ct_step == Step.AWAITING_KEYPOINTS:
		if _ct_keypoints_exists:
			print("Pair tested successfully.")
			
			var config = {
				"camL": _ct_pairs[_ct_curr_idx].x,
				"camR": _ct_pairs[_ct_curr_idx].y
			}
			var file = File.new()
			file.open(config_fname, File.WRITE)
			file.store_string(to_json(config))
			file.close()
			
			set_step(Step.CONFIGING)
		else:
			_ct_kp_waiting += delta
			var left = int(ct_kp_wait_time - _ct_kp_waiting)
			if left < 0:
				left = 0
			$WebcamTestView/TimeoutLabel.set_text(String(left))
			$WebcamTestView/TimeoutLabel.visible = true
			if left == 0:
				print("Didn't find keypoints.")
				set_step(Step.TESTING)
				_bad_pair(false)
	else:
		return

func _re_count():
	_co_match_waiting = 0
	$ConfigureView/TimeoutLabel.visible = false

func _config_count(delta):
		_co_match_waiting += delta
		var left = int(co_match_wait_time - _co_match_waiting)
		if left < 0:
			left = 0
		$ConfigureView/TimeoutLabel.set_text(String(left))
		$ConfigureView/TimeoutLabel.visible = true
		
		return left == 0
		
func _config_center():
	var pcen = $WPlayer.get_point(glob.ExtraPosePoint.TORSO_CENTRE, true)
	var bcen = board_res / 2
	var mvy = move.y
	if pcen.y > bcen.y:
		mvy -= pcen.y - bcen.y
	elif bcen.y > pcen.y:
		mvy += bcen.y - pcen.y
	var mvx = move.x
	if pcen.x > bcen.x:
		mvx -= pcen.x - bcen.x
	elif bcen.x > pcen.x:
		mvx += bcen.x - pcen.x
	
	move = Vector2(mvx, mvy)

func _configure_process(delta):
	if _co_step == 0:
		$ConfigureView/InfoLabel.text = "Ustaw się horyzontalnie w centrum pola gry tak, by twoja twarz była widoczna."
		
		var nose = $WPlayer.get_point(glob.PosePoint.NOSE, false)
		var r = glob.distance($WPlayer.get_point(glob.PosePoint.LEFT_EAR, false), $WPlayer.get_point(glob.PosePoint.RIGHT_EAR, false))
		if nose.y - r - 50 > 0 and r > 0:
			if _config_count(delta):
				_co_step = 1
		else:
			_re_count()
			
		_config_center()
	elif _co_step == 1:
		$ConfigureView/InfoLabel.text = "Przyjmij pozycję litery T i ustaw się w takiej odległości, by dłonie znajdowały się w obszarze prowadnic."
		
		
		
		_config_center()
	elif _co_step == 2:
		$ConfigureView/InfoLabel.text = "Nie ruszając się z miejsca, wysuń ręce na wprost ciała, a następnie zegnij łokcie prostopadle to ramion i otwórz dłoń skierowaną w stronę kamer."
	else:
		_co_step = 0

func _process(delta):
	if _ct_step < Step.CONFIGING:
		_testing_process(delta)
	if _ct_step == Step.CONFIGING:
		_configure_process(delta)
	if _ct_step >= Step.AWAITING_KEYPOINTS:
		tick()
