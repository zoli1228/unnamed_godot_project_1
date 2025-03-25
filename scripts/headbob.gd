extends Node

## This is an example of a module.
## You can add as many modules as you want with their own unique functionality.
## Each module must have an "update_module(delta)" function, and this function
## is called from the player's process().
## This module for example adds headbobbing, without placing any dependency in the player's core script.
## You can delete it or disable it without a problem.
## Might add phys_update_module aswell.

@export var module_enabled := true
var player : RigidBody3D = null
var cam_effects : Node3D = null
var counter = 0.0
var allowed_states = [1, 3, 5]
var skip_head_bob = true

func init_module() -> void:
	if !module_enabled: return
	player = $"../../.."
	cam_effects = $"../../../cam_container/cam_effects"
	print("Headbob module initialized")


func update_module(_delta: float) -> void:
	if !module_enabled: return
	if !cam_effects: return
	skip_head_bob = true
	for idx in allowed_states:
		if player.state == player.states[idx]:
			skip_head_bob = false
			break
	if skip_head_bob:
		cam_effects.position.x *= 0.90
		cam_effects.position.y *= 0.90
		return
	var horizontal_velocity = abs(Vector3(player.linear_velocity.x, 0.0, player.linear_velocity.z)).length()
	var headbob_amount = clamp(horizontal_velocity, 0.0, 15.0)

	cam_effects.position.x += sin(counter * 1.5) * (headbob_amount * 0.2) * _delta * 0.5
	cam_effects.position.y += abs(sin(counter * 1.5)) * (headbob_amount * 0.2) * _delta * 0.5
	cam_effects.position.x *= 0.90
	cam_effects.position.y *= 0.90
	counter += headbob_amount * _delta
