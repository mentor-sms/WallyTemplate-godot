extends Area2D

signal hovered
signal not_hovered
signal pointed
signal not_pointed
signal gripped
signal released
signal clicked
signal toggled

var _templ2D = WTemplate2D.new()

func _ready():
	self.connect("body_entered", _templ2D, "on_body_entered")
	self.connect("body_exited", _templ2D, "on_body_exited")
