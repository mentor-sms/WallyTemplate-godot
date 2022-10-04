extends Node

const glob = preload("res://Globals.gd")

# SETTINGS, don't change on runtime
const cams_distance = 22
const cams_res = Vector2(640, 480)
const board_res = Vector2(1920, 1080)
const default_cams = Vector2(-1, -1)
const cams_max_idx = 3 # ilość kamer * 2 - 1
const sgbm = false # true nie działa
const ct_test_time = 5 # zmienić na 10
const ct_kp_wait_time = 5 # zmienić na 10
const co_match_wait_time = 5 # zmienić na 10
const draw_keypoints = true
const draw_pose = true
const skip_pose_config = true

# configuration
var move = Vector2(0, 0)

const _pypywally_path:String = "/home/sms/Code/WallieController/PyWallie/python_modules/pypywally/pypywally"

# !--- DON'T CHANGE: ---!

var lastTemplId = -1
func takeNewId():
	lastTemplId += 1
	return lastTemplId

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
	FRESH = -3,
	IDLE = -2,
	ERRORS = -1,
	STARTED = 0,
	RETERR1 = 1,
	RETERR2 = 2,
	TICKING = 3,
	BUSY = 4
}

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
var _ct_kp_waiting_inited = false

var _co_match_waiting = 0
var _co_step = 0
var _co_mode = 0

var _co_ge_lhand = Vector2(0, 0)
var _co_ge_rhand = Vector2(0, 0)

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
		print("Step changed to UNKNOWN, resetting.")
		set_label("")
		set_step(Step.NOT_WORKING)
		return
	
	_ct_step = step
	
	$WPlayer.set_visibility(_ct_step >= Step.CONFIGING)
	$WebcamTestView.visible = _ct_step <= Step.AWAITING_KEYPOINTS
	$WebcamTestView/TimeoutLabel.visible = false
	$GameBackgroundView.visible = _ct_step >= Step.AWAITING_KEYPOINTS	
	$GameView.visible = _ct_step == Step.WORKING
	$ConfigureView.visible = _ct_step == Step.CONFIGING
	$ConfigureView/TimeoutLabel.visible = false
	$Background.visible = _ct_step != Step.WORKING
	
	set_show_keypoints(_ct_step == Step.CONFIGING)
	
	set_menu(_ct_step == Step.WORKING || (_ct_step == Step.CONFIGING && _co_step >= 3), 100, 50)
	
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
	print("Initing...")
	var ok = false
	if not use_sgbm:
		ok = _wc.init(_pypywally_path, camL, camR, board_res, cams_res)
	else:
		print("SGBM not implemented!")
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
		

func tick(_poses = [glob.Pose.HANDS_TOUCH]):
	$WPlayer.has_points = false
	
	if _1st_tick:
		_1st_tick = false
		print("First tick, ticked.")
	elif _wc.loadTick():
		#start counting latency
		var kpoints = _wc.takeKeypoints()
		
		var pidx = 0
		var idx = -1
		var pout = Vector2()
		
		var points = PoolVector2Array()
		for p in kpoints:
			idx += 1
			if idx == 0:
				pout.x = p + move.x
			elif idx == 1:
				pout.y = p + move.y
			elif idx == 3:
				$WPlayer.set_point(pidx, pout)
				points.append(pout)
				pidx += 1
				idx = -1
				
		_ct_keypoints_exists = true
			
		var left_hand = _wc.calc2DCentre([points[glob.PosePoint.LEFT_INDEX], points[glob.PosePoint.LEFT_THUMB], points[glob.PosePoint.LEFT_PINKY], points[glob.PosePoint.LEFT_WRIST]])
		var right_hand = _wc.calc2DCentre([points[glob.PosePoint.RIGHT_INDEX], points[glob.PosePoint.RIGHT_THUMB], points[glob.PosePoint.RIGHT_PINKY], points[glob.PosePoint.RIGHT_WRIST]])
		var left_foot = _wc.calc2DCentre([points[glob.PosePoint.LEFT_FOOT_INDEX], points[glob.PosePoint.LEFT_HEEL], points[glob.PosePoint.LEFT_ANKLE]])
		var right_foot = _wc.calc2DCentre([points[glob.PosePoint.RIGHT_FOOT_INDEX], points[glob.PosePoint.RIGHT_HEEL], points[glob.PosePoint.RIGHT_ANKLE]])
		var neckp = _wc.calc2DCentre([points[glob.PosePoint.LEFT_SHOULDER], points[glob.PosePoint.RIGHT_SHOULDER]])
		var assp = _wc.calc2DCentre([points[glob.PosePoint.LEFT_HIP], points[glob.PosePoint.RIGHT_HIP]])
		var torsop = _wc.calc2DCentre([neckp, assp])
		
		$WPlayer.set_point(glob.ExtraPosePoint.LEFT_HAND, left_hand, true)
		$WPlayer.set_point(glob.ExtraPosePoint.RIGHT_HAND, right_hand, true)
		$WPlayer.set_point(glob.ExtraPosePoint.LEFT_FOOT, left_foot, true)
		$WPlayer.set_point(glob.ExtraPosePoint.RIGHT_FOOT, right_foot, true)
		$WPlayer.set_point(glob.ExtraPosePoint.TORSO_CENTRE, torsop, true)
		$WPlayer.set_point(glob.ExtraPosePoint.NECK, neckp, true)
		$WPlayer.set_point(glob.ExtraPosePoint.ASS, assp, true)
		$WPlayer.has_points = true
		emit_signal("ticked")
		
	var ok = _wc.tick()
	if !ok:
		print("Keyboints failed to build.")
		set_step(Step.NOT_WORKING)
	return ok

func _ready():
	set_step(Step.NOT_WORKING)
	print("Creating WallyController...")
	_wc = WallyController.new()
	var b = self.connect("ticked", $GameBackgroundView, "update")
	var c = self.connect("ticked", $ConfigureView, "update")
	if b and c:
		print("WallyController created.")
	else:
		print("WallyController failed to connect.")
	
func _bad_pair(blacklist):
	var curr_bad = _ct_curr_idx
	print("Bad pair: ", curr_bad, " ", blacklist)
	if !_ct_bad_idxs.has(_ct_curr_idx) && blacklist:
		_ct_bad_idxs.push_back(_ct_curr_idx)
	print("Blacklisted pairs: ", _ct_bad_idxs)
	while (_ct_bad_idxs.has(_ct_curr_idx) || (_ct_curr_idx == curr_bad && _ct_bad_idxs.size() + 1 != _ct_pairs.size())):
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
		
func _save_config_json(filename, json):
	filename = "user://" + filename + ".json"
	
	var file = File.new()
	file.open(filename, File.WRITE)
	file.store_string(to_json(json))
	file.close()
	
func _load_config_json(filename, key, default):
	filename = "user://" + filename + ".json"
	
	var file = File.new()
	
	if file.file_exists(filename):
		var err = file.open(filename, File.READ)
		if err == OK:
			var content = file.get_as_text()
			var data = parse_json(content)
			file.close()
			if typeof(data) == TYPE_DICTIONARY:
				return data[key]
			else:
				print("Bad file syntax: ", filename)
		else:
			print("Can't open file: ", filename, " (error: ", err, ")")
	else:
		print("File doesn't exist: ", filename)
	return default

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
				var def = Vector2(-1, -1)
				def.x = _load_config_json("cams", "camL", -1)
				def.y = _load_config_json("cams", "camR", -1)
				
				print("DEFS LOADED: ", def)
				
				if def.x >= 0 || def.y >= 0 || def.x <= cams_max_idx || def.y <= cams_max_idx || def.x != def.y:
					_ct_pairs.push_back(def)
					_ct_pairs.push_back(Vector2(def.y, def.x))
					print("Default pair loaded.")
				for c0 in range(0, cams_max_idx + 1):
					for c1 in range(0, cams_max_idx + 1):
						var vec = Vector2(c0, c1)
						if c0 != c1 && (_ct_pairs.size() == 0 
						|| (_ct_pairs.size() > 1 && _ct_pairs[0] != vec && _ct_pairs[1] != vec)):
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
		if _ct_start == StartStatus.FRESH || _ct_start == StartStatus.IDLE || _ct_start == StartStatus.BUSY:
			return
		elif _ct_start == StartStatus.STARTED || _ct_start == StartStatus.TICKING:
			print("Pair started.")
			_ct_kp_waiting = 0
			_ct_kp_waiting_inited = false
			set_step(Step.AWAITING_KEYPOINTS)
		else:
			print("Pair failed to start: ", _ct_start, ".")
			set_step(Step.TESTING)
			_bad_pair(true)
	elif _ct_step == Step.AWAITING_KEYPOINTS:
		if _ct_keypoints_exists:
			print("Pair tested successfully.")
			var json = {
				"camL": _ct_pairs[_ct_curr_idx].x,
				"camR": _ct_pairs[_ct_curr_idx].y
			}
			_save_config_json("cams", json)
			var def = Vector2(-1, -1)
			def.x = _load_config_json("cams", "camL", -1)
			def.y = _load_config_json("cams", "camR", -1)
			print("DEFS SAVED: ", def)
			
			set_step(Step.CONFIGING)
		else:
			if _ct_kp_waiting_inited:
				_ct_kp_waiting += delta
			else:
				_ct_kp_waiting_inited = true
				_ct_kp_waiting = 0
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
	
	$ConfigureView.update()

func _set_menu(set, distance, hand, left):
	if !set:
		hand.set_menu(set, Vector2(0, 0))
	var carea = hand.get_node("Menu/SizeArea/CollisionShape2D")
	var vec = distance
	
	vec.y = -vec.y
	if left:
		vec.x = -vec.x
	
	hand.set_menu(set, vec)

func set_menu(set, awayx, awayy):
	var distance = Vector2(awayx, awayy)
	_set_menu(set, distance, $WPlayer.lhand, true)
	_set_menu(set, distance, $WPlayer.rhand, false)

func _configure_process(delta):
	$ConfigureView.show_guides = _co_step == 1
	$ConfigureView.show_hguides = _co_step == 2
	
	set_menu(_co_step >= 3, -50, 0)

	if _co_step == 0:
		$ConfigureView/InfoLabel.text = "Ustaw się horyzontalnie w centrum pola gry tak, by twoja twarz była widoczna. Przyjmij pozycję naturalną."
		
		if not $WPlayer.has_points:
			_re_count()
			return
		
		var nose = $WPlayer.get_point(glob.PosePoint.NOSE, false)
		var r = glob.distance($WPlayer.get_point(glob.PosePoint.LEFT_EAR, false), $WPlayer.get_point(glob.PosePoint.RIGHT_EAR, false))
		
		var cen = $WPlayer.get_point(glob.ExtraPosePoint.TORSO_CENTRE, true)
		var lhand = $WPlayer.get_point(glob.ExtraPosePoint.LEFT_HAND, true)
		var rhand = $WPlayer.get_point(glob.ExtraPosePoint.RIGHT_HAND, true)
		var lleg = $WPlayer.get_point(glob.ExtraPosePoint.LEFT_FOOT, true)
		var rleg = $WPlayer.get_point(glob.ExtraPosePoint.RIGHT_FOOT, true)
		
		if nose.y - r - 50 > 0 and r > 0 and lhand.x < cen.x and lleg.x < cen.x and rhand.x > cen.x and rleg.x > cen.x and lleg.y > cen.y and rleg.y > cen.y and lhand.y < lleg.y and rhand.y < rleg.y:
			if _config_count(delta):
				_co_step = 1
				_re_count()
		else:
			_re_count()
			
		_config_center()
			
	elif _co_step == 1:
		$ConfigureView/InfoLabel.text = "Przyjmij pozycję litery T i ustaw się w takiej odległości, by dłonie znajdowały się w obszarze prowadnic."
		
		if not $WPlayer.has_points:
			_re_count()
			return
		
		var cl = false
		var cr = false
		var fl = false
		var fr = false
		
		for left in [true, false]:
			var hand
			if left:
				hand = $WPlayer.get_point(glob.ExtraPosePoint.LEFT_HAND, true)
			else:
				hand = $WPlayer.get_point(glob.ExtraPosePoint.RIGHT_HAND, true)
			for far in [true, false]:
				var guide = $ConfigureView.get_guide(left, far)
				var inside = hand.x > guide and hand.x < guide + 100
				$ConfigureView.set_guide_idle(left, far, not inside)
				if left:
					if far:
						fl = inside
					else:
						cl = inside
				else:
					if far:
						fr = inside
					else:
						cr = inside
		
		var changed = false
		if cl and cr and not fl and not fr:
			if _co_mode != 1:
				changed = true
			_co_mode = 1
		elif fl and fr and not cl and not cr:
			if _co_mode != 2:
				changed = true
			_co_mode = 2
		else:
			_co_mode = 0
			
		if _co_mode == 0 or changed:
			_re_count()
		elif _config_count(delta):
			_config_center()
			_save_config_json("center", {"movex": move.x, "movey": move.y, "comode": _co_mode})
			if skip_pose_config:
				_co_step = 3
				$ConfigureView/Ball.set_ball_as_button(Vector2(456, 464))
			else:
				_co_step = 2
			_re_count()
			return
				
		_config_center()
				
	elif _co_step == 2:
		$ConfigureView/InfoLabel.text = "Nie ruszając się z miejsca, wysuń ręce na wprost ciała, a następnie zegnij łokcie prostopadle do ramion."
		
		if not $WPlayer.has_points:
			_re_count()
			return
		
		var lhand = $WPlayer.get_point(glob.ExtraPosePoint.LEFT_HAND, true)
		var rhand = $WPlayer.get_point(glob.ExtraPosePoint.RIGHT_HAND, true)
		
		var lg = $ConfigureView.get_hguide(true)
		var rg = $ConfigureView.get_hguide(false)
		
		var lin = lg.has_point(lhand)
		var rin = rg.has_point(rhand)
		
		$ConfigureView.set_hguide_idle(true, not lin)
		$ConfigureView.set_hguide_idle(false, not rin)
		
		if lin and rin:
			if _config_count(delta):
				_co_step = 3
				$ConfigureView/Ball.set_ball_as_button(Vector2(456, 464))
				var _co_ge_lsho = $WPlayer.get_point(glob.PosePoint.LEFT_SHOULDER, false)
				var _co_ge_rsho = $WPlayer.get_point(glob.PosePoint.RIGHT_SHOULDER, false)
				_co_ge_lhand = Vector2(_co_ge_lsho.x - lhand.x, _co_ge_lsho.y - lhand.y)
				_co_ge_rhand = Vector2(_co_ge_rsho.x - rhand.x, _co_ge_rsho.y - rhand.y)
				# where load this:
				_save_config_json("shoulder_menu", {"lmovex": _co_ge_lhand.x, "lmovey": _co_ge_lhand.y, "rmovex": _co_ge_rhand.x, "rmovey": _co_ge_rhand.y})
				_re_count()
		else:
			_re_count()
	elif _co_step == 3:
		$ConfigureView/InfoLabel.text = "Kliknij sygnet Mentora."
		
		if not $WPlayer.has_points:
			_re_count()
			return
			
		var lhand = $WPlayer.get_point(glob.ExtraPosePoint.LEFT_HAND, true)
		var rhand = $WPlayer.get_point(glob.ExtraPosePoint.RIGHT_HAND, true)
		
		if $ConfigureView/Ball.ball_was_clicked:
			_co_step = 4
			$ConfigureView/Ball.set_ball_as_movable($WPlayer.lhand, $WPlayer.rhand, Vector2(456, 464))
		
	elif _co_step == 4:
		$ConfigureView/InfoLabel.text = "Przesuń sygnet Mentora w wyznaczone miejsce."
		
		if not $WPlayer.has_points:
			_re_count()
			return
	elif _co_step == 5:
		$ConfigureView/InfoLabel.text = ""
	else:
		_co_step = 0
	

func _process(delta):
	if _ct_step < Step.CONFIGING:
		_testing_process(delta)
	if _ct_step == Step.CONFIGING:
		_configure_process(delta)
	if _ct_step >= Step.AWAITING_KEYPOINTS:
		tick()

var _ball_left = false
func _on_BallTarget_body_entered(body):
	if _ball_left && body == $ConfigureView/Ball:
		_co_step = 5
		$ConfigureView/Ball.set_ball_as_button(Vector2(456, 464))

func _on_BallTarget_body_exited(body):
	if body == $ConfigureView/Ball:
		_ball_left = true

func _on_Ball_ball_clicked():
	if _co_step == 5:
		var nball : Ball = $ConfigureView/Ball.duplicate(DUPLICATE_SCRIPTS)
		nball.set_ball_as_movable($WPlayer/LeftHand, $WPlayer/RightHand, Vector2(board_res.x / 2, -100))
