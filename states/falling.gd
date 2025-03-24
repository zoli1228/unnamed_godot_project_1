extends Node

@export var movement_speed = 1.3
var input_dir := Vector2.ZERO
var player : RigidBody3D = null

func enter(_player : RigidBody3D):
	player = _player
	print("Entered state: %s" % name)

func process(_delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = Vector3(input_dir.x, 0.0, input_dir.y)
	player.move_input = direction.normalized() * movement_speed
	if player.is_grounded:
		# Deciding if player should switch to CROUCHING state or WALKING
		if player.is_crouched:
			player.change_state(5)
		else:
			player.change_state(1)

func leave():
	print("Landed from %s" % name)
