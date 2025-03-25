extends Node

@export var movement_speed = 0.8
@export var jump_force := 4.0
var input_dir := Vector2.ZERO
var player : RigidBody3D = null
func enter(_player: RigidBody3D):
	player = _player
	player.is_crouched = false
	player.is_jumping = false
	print("Entered state: %s" % name)

func process(_delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	#var direction = input_dir.x * player.global_basis.x + input_dir.y * player.global_basis.z
	var direction = Vector3(input_dir.x, 0.0, input_dir.y)
	player.move_input = direction.normalized() * movement_speed
	if abs(direction.length()) < 0.1:
		player.change_state(0)
		return
	if Input.is_action_just_pressed("jump"):
		player.jump(jump_force)
	if Input.is_action_pressed("sprint"):
		player.change_state(3)
		return
	if Input.is_action_just_pressed("crouch"):
		player.change_state(5)
		return

func leave():
	pass
