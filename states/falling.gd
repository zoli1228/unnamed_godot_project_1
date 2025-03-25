extends Node

@export var movement_speed = 0.3
var input_dir := Vector2.ZERO
var player : RigidBody3D = null
var original_ray_length = 0.0
var falling_velocity = 0.0
func enter(_player : RigidBody3D):
	player = _player
	original_ray_length = player.player_original_ray_length
	falling_velocity = 0.0
	print("Entered state: %s" % name)

func process(_delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = Vector3(input_dir.x, 0.0, input_dir.y)
	var speed = abs(Vector3(player.linear_velocity.x, 0.0, player.linear_velocity.z).length())
	player.move_input = direction.normalized() * movement_speed * (10.0 - speed)


	if player.is_grounded:
		# Deciding if player should switch to CROUCHING, WALKING, or SLIDING state
		if player.is_over_slipping_threshold:
			player.change_state(4) ## Sliding
			return
		if player.is_crouched:
			player.change_state(5) ## Crouching
			return
		else:
			player.change_state(1) ## Walking
			return

	if player.linear_velocity.y < falling_velocity:
		falling_velocity = player.linear_velocity.y

func leave():
	player.floor_ray_length = original_ray_length
	player.is_jumping = false
	player.landed.emit(falling_velocity)
	falling_velocity = 0.0
