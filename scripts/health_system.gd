extends Node

@export var module_enabled := true
@export var health := 100
@export var fall_damage_multiplier := 0.5
@export var fall_damage_threshold_velocity := 10.0
@export var sample_for_x_frames := 5.0

var player : RigidBody3D = null
var cam_effects : Node3D = null
var taken_fall_damage := false
var player_old_state = null
var sample_counter := 0
var do_sample := false
var landing_y_position := 0.0
var fall_speed = 0.0

func init_module() -> void:
	if !module_enabled: return
	player = $"../../.."
	cam_effects = $"../../../cam_container/cam_effects"
	player.landed.connect(take_fall_damage)
	print("Health module initialized")


func update_module(_delta: float) -> void:
	if !module_enabled || !cam_effects || !player: return
	if do_sample:
		sample_counter += 1
		if sample_counter >= sample_for_x_frames:
			do_sample = false
			var difference = landing_y_position - player.ray_collision_point.y
			difference *= 3.0 * fall_damage_multiplier
			var amt = int(abs(fall_speed * fall_damage_multiplier))
			amt *= amt
			difference = clamp(difference, 0, difference)
			amt -= int(difference)
			health -= amt
			print("Taken fall damage, remaining hp: %s" % health)
			sample_counter = 0
	if health <= 0 && !player.is_dead:
		player.change_state(6)
		return

func take_fall_damage(vertical_velocity: float):
	if abs(vertical_velocity) < fall_damage_threshold_velocity: return
	landing_y_position = player.ray_collision_point.y
	fall_speed = vertical_velocity
	do_sample = true
