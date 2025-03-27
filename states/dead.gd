extends Node

var player : RigidBody3D = null

func enter(_player: RigidBody3D):
	player = _player
	player.is_crouched = false
	player.is_jumping = false
	player.is_dead = true
	player.axis_lock_angular_x = false
	player.axis_lock_angular_y = false
	player.axis_lock_angular_z = false
	player.angular_velocity.x += 0.1
	player.physics_material_override.friction = 0.5
	player.linear_damp = 0.0
	player.angular_damp = 5.0
	print("Entered state: %s" % name)

func process(_delta: float) -> void:
	pass

func leave():
	pass
