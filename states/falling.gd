extends Node

@export var movement_speed = 1.3
var input_dir := Vector2.ZERO
var player : RigidBody3D = null
var original_ray_length = 0.0
func enter(_player : RigidBody3D):
	player = _player
	original_ray_length = player.player_original_ray_length

	print("Entered state: %s" % name)

func process(_delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = Vector3(input_dir.x, 0.0, input_dir.y)
	player.move_input = direction.normalized() * movement_speed
	if player.is_grounded:
		# Deciding if player should switch to CROUCHING, WALKING, or SLIDING state
		if player.is_over_slipping_threshold:
			player.change_state(4) ## Sliding
		if player.is_crouched:
			player.change_state(5) ## Crouching
		else:
			player.change_state(1) ## Walking

func leave():
	player.floor_ray_length = original_ray_length
	player.is_jumping = false
	print("Landed from %s" % name)
