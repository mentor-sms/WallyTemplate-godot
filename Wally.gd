extends Node

class_name Wally

const _pypywally_path:String = "/home/sms/Code/WallieController/PyWallie/python_modules/pypywally/pypywally"

var wally:WallyController = null

func _open(wcnoL:int, wcnoR:int) -> bool:
	if wally == null:
		return false
	return wally.init(_pypywally_path, wcnoL, wcnoR, Vector2(1920, 1080), Vector2(640, 480))

func _ready():
	wally = WallyController.new()
	var opened:bool = _open(0, 2)
	print(opened)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
