extends Node

@export var toggle_crouch := false
@export var mouse_sensitivity := 1.5
@export var limit_fps := true
@export var max_fps := 60.0

func _ready() -> void:
	if limit_fps:
		Engine.max_fps = max_fps

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
