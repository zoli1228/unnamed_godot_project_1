extends RigidBody3D

@export_group("Basic Settings")
@export var mouse_sensitivity := 1.0
##Global multiplier for all movement speeds
@export var movement_speed_modifier := 1.0
##Setting to 90.0 is not advised, player front basis flips resulting in inverted forward/backward movement, too lazy to fix.
@export_range(0.0, 90.0) var max_look_up_degrees := 89.0
##Drag applied to player movement. Lower values cause slippery and quick movement with lower response time, while higher values result in heavier but more responsive movements.
@export var horizontal_dampening := 10.0
##The maximum degrees at 1.0 surface friction before the player switches to the sliding state. Lower surface friction reduces this threshold to a lower degree.
@export var slope_slip_threshold_deg := 45.0
##The duration of... well... crouch animation...
@export var crouch_transition_duration := 0.3

@export_group("Advanced Settings")
##Offsets the floor raycasts, leave at zero for everyday usage.
@export var height_offset_from_base := 0.00
##Force applied to keep the player at a constant height above ground.
@export var float_strength := 15.0
##This was a test to see what works best, but oh man shapecast messes up slope calculation baaadly. Do not attempt.
@export var use_shapecast_instead_of_raycast := false

@export_group("HUD Settings")
## HUD update frequency (Lower values result in more frequent updates)
@export var debug_hud_update_delay := 10.0

@onready var state_machine := $Extensions/StateMachine
@onready var camera_positioner = $camera_positioner
@onready var camera_container = $cam_container
@onready var module_container = $Extensions/Modules
@onready var floor_ray: RayCast3D = $ray_container/floor_ray
@onready var floor_shapecast: ShapeCast3D = $ray_container/floor_shapecast

@onready var player_base: Node3D = $".."
@onready var ray_container: Node3D = $ray_container
@onready var slope_aligner_helper: Node3D = $slope_aligner_helper
@onready var slope_aligner: Node3D = $slope_aligner_helper/slope_aligner
@onready var debug_arrow: MeshInstance3D = $cam_container/cam_effects/player_camera/arrow
@onready var player_collider: CollisionShape3D = $CollisionShape3D
@onready var player_mesh: MeshInstance3D = $CollisionShape3D/MeshInstance3D
@onready var modules: Node = $Extensions/Modules
@onready var unstuck_timer: Timer = $unstuck_timer
@onready var debug_box: VBoxContainer = $"../DEBUG/VBoxContainer"
@onready var rayarray = [$ray_container/floor_ray, $ray_container/ray_left, $ray_container/ray_right, $ray_container/ray_back, $ray_container/ray_forward]
var is_grounded := false
var states = []
var state = null
var move_input = Vector3.ZERO
var active_modules = []
var mouse_delta := Vector2(0.0, 0.0)
var delay_counter := 0
var collision_distance := 0.0
var floor_ray_length = -1.5
var is_jumping := false
var current_surface = null
var current_friction := 1.0
var is_over_slipping_threshold := false
var is_sliding := false
var crouch_deepness := 0.0
var is_crouched := false
var player_original_height := 0.0
var player_original_ray_length := 0.0
var global_velocity = Vector3.ZERO
var previous_position = Vector3.ZERO
var active_ray = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	floor_shapecast.add_exception(self)
	for ray in rayarray:
		ray.add_exception(self)
	if use_shapecast_instead_of_raycast:
		for ray in rayarray:
			ray.enabled = false
	else:
		floor_shapecast.enabled = false
	set_disable_scale(true)
	previous_position = global_position
	active_modules = module_container.get_children()
	states = state_machine.get_children()
	player_original_height = player_collider.shape.height
	player_original_ray_length = floor_ray_length

	for module in active_modules:
		module.init_module()

	if states.size() <= 0:
		printerr("No states found in player controller!!")
		return
	change_state(0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta.x += event.relative.x
		mouse_delta.y += event.relative.y

func change_state(new_state: int) -> void:
	if states[new_state] == state: return
	if state:
		state.leave()
	state = states[new_state]
	state.enter(self)
	handle_crouched_mode()

func _process(_delta: float) -> void:
	mouse_look()
	if delay_counter >= debug_hud_update_delay:
		delayed_update()
		delay_counter = 0
	delay_counter += 1

	# Camera smoothing / lagging behind actual player for smoothness
	var difference = (camera_container.global_position - camera_positioner.global_position)
	camera_container.global_position -= difference * 0.8

	# Modules process
	for module in active_modules:
		module.update_module(_delta)

	# Slipping on slopes
	if slope_angle_global + (1.0 - current_friction) * slope_angle_global > slope_slip_threshold_deg:
		is_over_slipping_threshold = true
		change_state(4) # SLIDING
	else:
		is_over_slipping_threshold = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# RB following camera container rotation
	global_rotation.y -= (global_rotation.y - camera_container.global_rotation.y)
	player_base.global_position = global_position

	ray_container.global_position = global_position + Vector3(0.0, height_offset_from_base + crouch_deepness, 0.0)
	for ray in rayarray:
		ray.target_position.y = floor_ray_length

	if !is_grounded:
		change_state(2) ## Falling

	handle_states(delta)
	handle_floor_ray()
	handle_slope_calculation()
	handle_friction()
	handle_moving_platforms()
	handle_global_velocity()

func delayed_update():
	handle_debug_hud()

func handle_debug_hud():
	debug_box.get_child(0).text = "fps:   %s" % Engine.get_frames_per_second()
	debug_box.get_child(1).text = "State:   %s" % state.name
	debug_box.get_child(2).text = "Grounded:   %s" % is_grounded
	debug_box.get_child(3).text = "slope_angle_directional:   %s" % snappedf(slope_angle_directional, 0.1)
	debug_box.get_child(4).text = "slope_angle_global:   %s" % snappedf(slope_angle_global, 0.1)
	debug_box.get_child(5).text = "current_friction:   %s" % snappedf(current_friction, 0.01)
	debug_box.get_child(6).text = "is_over_slipping_threshold:   %s" % is_over_slipping_threshold
	debug_box.get_child(7).text = "current_surface:   %s" % current_surface
	debug_box.get_child(8).text = "active_ray:   %s" % [active_ray.name if active_ray else "null"]

func handle_states(delta: float):
	state.process(delta)

func handle_global_velocity() -> void:
	global_velocity = global_position - previous_position
	previous_position = global_position

var aligner_old_y_pos := 0.0
var aligner_y_velocity := 0.0
var slope_angle_directional := 0.0
var slope_angle_global := 0.0

func _integrate_forces(_p_state: PhysicsDirectBodyState3D) -> void:
	# All physics movement should be handled in _integrate forces!!!

	if is_grounded:
		# Slope angle is calculated twice.
		# Once for overall slope angle, and once for directional slope angle (where the player is facing).
		# Directional can be used to limit movement speed on slopes going up and down.
		slope_angle_directional = slope_aligner.global_rotation_degrees.x
		slope_angle_global = rad_to_deg(acos(slope_aligner.global_basis.tdoty(Vector3.UP)))
		aligner_y_velocity = slope_aligner.global_position.y - aligner_old_y_pos

		if aligner_y_velocity < 0.0:
			aligner_y_velocity = 0.0
		if (debug_arrow.global_position + move_input.z * slope_aligner.global_basis.z) != debug_arrow.global_position:
			debug_arrow.look_at(debug_arrow.global_position + move_input.z * slope_aligner.global_basis.z)

		if use_shapecast_instead_of_raycast:
			collision_distance = (floor_shapecast.get_collision_point(0) - global_position).y
			slope_aligner_helper.global_position = floor_shapecast.get_collision_point(0) + Vector3(0.0, 0.01, 0.0)
		else:
			collision_distance = (active_ray.get_collision_point() - global_position).y
			slope_aligner_helper.global_position = active_ray.get_collision_point() + Vector3(0.0, 0.01, 0.0)


		# Floating RB Controller logic
		if !is_jumping && !is_sliding && !is_over_slipping_threshold:
			linear_velocity.y += (collision_distance - crouch_deepness + height_offset_from_base) * float_strength

			# Making sure that running down on slopes is possible
			#var vertical_force = -linear_velocity.y + (30.0 * mass * aligner_y_velocity * abs(deg_to_rad(slope_angle_directional)))
			var vertical_force = -linear_velocity.y + (mass * aligner_y_velocity * abs(deg_to_rad(slope_angle_directional)))
			apply_central_force(Vector3(0.0, vertical_force, 0.0) * 30.0 * mass)

		# DAMPENING
		apply_central_force((Vector3(-linear_velocity.x, 0.0, -linear_velocity.z) * horizontal_dampening) * mass * current_friction * (1.05 - float(is_sliding)))

	else:
		# While player is in the air, these values should be 0.0
		aligner_y_velocity = 0.0
		slope_angle_directional = 0.0
		slope_angle_global = 0.0
		collision_distance = 0.0
	aligner_old_y_pos = slope_aligner.global_position.y



	#Move player
	if is_sliding:
		linear_velocity += (move_input.z * global_basis.z + move_input.x * global_basis.x) * current_friction * movement_speed_modifier
	else:
		linear_velocity += (move_input.z * slope_aligner.global_basis.z + move_input.x * slope_aligner.global_basis.x) * current_friction * movement_speed_modifier
	global_rotation.z = 0.0
	global_rotation.x = 0.0
	handle_stuck_protection()

func jump(force: float):
	if !is_grounded: return
	if is_jumping: return

	is_jumping = true
	print("JUMPED")
	floor_ray_length = -1.0

	linear_velocity = Vector3.ZERO
	linear_velocity.y += force
	linear_velocity += global_velocity * 50.0

	await get_tree().create_timer(1.0).timeout
	is_jumping = false


# FLOOR RAY ARRAY TO BE IMPLEMENTED FOR INCREASED ACCURACY - SHAPECAST IS SHITE ##
# Implemented, Shapecast is still SHITE
func handle_floor_ray():
	is_grounded = false
	ray_container.global_rotation.y = global_rotation.y

	# SHAPECAST OPTIONS
	if use_shapecast_instead_of_raycast:
		if floor_shapecast.is_colliding():
			is_grounded = true
			current_surface = floor_shapecast.get_collider(0)
		else:
			current_surface = null
	# RAYCAST OPTIONS
	else:
		for ray in rayarray:
			if ray.is_colliding():
				is_grounded = true
				current_surface = ray.get_collider()
				active_ray = ray
				break
			else:
				active_ray = null
				current_surface = null


func handle_slope_calculation():
	if is_grounded:
		if use_shapecast_instead_of_raycast:
			slope_aligner_helper.look_at(floor_shapecast.get_collision_point(0) + floor_shapecast.get_collision_normal(0), global_basis.z)
		else:
			slope_aligner_helper.look_at(floor_ray.get_collision_point() + floor_ray.get_collision_normal(), global_basis.z)
	else:
		slope_aligner_helper.global_rotation_degrees = global_rotation_degrees + Vector3(90.0, 0.0, 0.0)

func handle_friction():
	current_friction = 0.05
	if !is_grounded: return
	current_friction = 1.0
	if current_surface:
		if current_surface.get_meta_list().has(&"friction"):
			current_friction = current_surface.get_meta(&"friction")

func handle_crouched_mode():
	var tw = create_tween()
	if is_crouched:
		tw.stop()
		tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(player_collider, "shape:height", player_original_height / 2.0, crouch_transition_duration)
		tw.tween_property(player_mesh, "mesh:height", player_original_height / 2.0, crouch_transition_duration)
		tw.tween_property(self, "crouch_deepness", 0.5, crouch_transition_duration)


	else:
		tw.stop()
		tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(player_collider, "shape:height", player_original_height, crouch_transition_duration)
		tw.tween_property(player_mesh, "mesh:height", player_original_height, crouch_transition_duration)
		tw.tween_property(self, "crouch_deepness", 0.0, crouch_transition_duration)

func handle_stuck_protection():
	if get_colliding_bodies().size() > 1 && linear_velocity.y < 0.5 && !is_grounded:
		if unstuck_timer.is_stopped():
			unstuck_timer.start()
	else:
		if !unstuck_timer.is_stopped():
			unstuck_timer.stop()

func mouse_look() -> void:
	camera_container.rotation_degrees.x -= mouse_delta.y * 0.1 * Settings.mouse_sensitivity
	camera_container.rotation_degrees.x = clamp(camera_container.rotation_degrees.x, -max_look_up_degrees, max_look_up_degrees)
	camera_container.rotation_degrees.y -= mouse_delta.x * 0.1 * Settings.mouse_sensitivity
	#rotate(basis.y, deg_to_rad(-mouse_delta.x * 0.1 * Settings.mouse_sensitivity))

	mouse_delta = Vector2.ZERO


var old_surface = null
func handle_moving_platforms() -> void:
	if !current_surface:
		if get_parent() != get_tree().root:
			call_deferred("reparent", get_tree().root)
			old_surface = null

	if current_surface != old_surface:
		call_deferred("reparent", current_surface)
		old_surface = current_surface
	if current_surface is RigidBody3D:
		current_surface.apply_force(Vector3.DOWN * mass, current_surface.to_local(global_position))



func _on_unstuck_timer_timeout() -> void:
	translate((get_colliding_bodies()[0].global_position - global_position).normalized())
	print("Let me help you there...")
