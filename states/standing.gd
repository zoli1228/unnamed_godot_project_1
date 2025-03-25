extends Node


var input_dir := Vector2.ZERO
var player : RigidBody3D = null
@export var jump_force := 4.0
func enter(_player: RigidBody3D):
	player = _player
	player.is_crouched = false
	print("Entered state: %s" % name)

func process(_delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = Vector3(input_dir.x, 0.0, input_dir.y)
	if Input.is_action_just_pressed("jump"):
		player.jump(jump_force)
	if Input.is_action_just_pressed("crouch"):
		player.change_state(5)
	if abs(direction.length()) > 0.0:
		player.change_state(1)

func leave():
	pass
