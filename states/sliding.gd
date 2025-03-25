extends Node

@export var movement_speed = 0.05
@onready var cam_effects: Node3D = $"../../../cam_container/cam_effects"

var input_dir := Vector2.ZERO
var player : RigidBody3D = null
var was_player_crouched = false
var float_offset_original = 0.0
var tw : Tween = null

func enter(_player: RigidBody3D):
	print("Entered state: %s" % name)
	player = _player
	float_offset_original = player.height_offset_from_base
	#player.height_offset_from_base = -0.3
	player.is_sliding = true
	was_player_crouched = player.is_crouched
	if tw:
		tw.stop()
	tw = create_tween()
	#tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(cam_effects, "rotation_degrees:z", 10.0, 0.5)
	player.is_crouched = true
	player.is_jumping = false


func process(_delta: float) -> void:
	#print(Vector3(player.linear_velocity.x, 0.0, player.linear_velocity.z).length_squared())
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = Vector3(input_dir.x, 0.0, input_dir.y)
	player.move_input = direction.normalized() * movement_speed
	if Vector3(player.linear_velocity.x, 0.0, player.linear_velocity.z).length_squared() < 100.0 * player.current_friction:
		if !player.is_over_slipping_threshold:
			if was_player_crouched:
				player.change_state(5)
				return
			else:
				player.change_state(1)
				return

func leave():
	if tw:
		tw.stop()
	tw = create_tween()
	#tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cam_effects, "rotation_degrees:z", 0.0, 0.3)
	player.height_offset_from_base = float_offset_original
	player.is_sliding = false
	player.is_crouched = was_player_crouched
