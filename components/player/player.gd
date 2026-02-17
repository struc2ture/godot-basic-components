class_name Player extends CharacterBody3D


@export var WALKING_SPEED: float = 5.0
@export var SPRINT_SPEED: float = 10.0
@export var SWIMMING_SPEED: float = 3.0
@export var JUMP_VELOCITY: float = 6.0
@export var MOUSE_SENS: float = 0.22
@export var FLOOR_ACCEL: float = 8.0
@export var AIR_ACCEL: float = 2.0
@export var WATER_ACCEL: float = 5.0
@export var WATER_DECEL: float = 2.0
@export var DECEL: float = 10.0
@export var WATER_LEVEL: float = 0.0
@export var WATER_GRAVITY_MULT: float = 0.3
@export var BOB_FREQ_WALKING: float = 12.5
@export var BOB_FREQ_SPRINTING: float = 16.0
@export var BOB_AMP_WALKING: float = 0.06
@export var BOB_AMP_SPRINTING: float = 0.08
@export var FOV_MIN: float = 80.0
@export var FOV_MAX: float = 100.0
@export var UNDERWATER_GRAVITY_DISABLED: bool = false
@export var GRAVITY_OVERRIDE: float = 20.0


@onready var HEAD: Node3D = $Head
@onready var CAMERA: Camera3D = $Head/Camera3D


signal player_stepped()
signal player_jumped()
signal player_landed()
signal player_body_entered_water()
signal player_body_left_water()


enum State {ON_FLOOR, IN_AIR, UNDERWATER}


var current_state: State = State.ON_FLOOR
var prev_state_duration: float = 0.0
var state_duration: float = 0.0
var was_underwater: bool = false
var current_water_area = null
var head_submerged : bool = false
var head_submerged_changed: bool = true

var speed: float = WALKING_SPEED

var headbob_freq: float = BOB_FREQ_WALKING
var headbob_amp: float = BOB_AMP_WALKING
var headbob_time: Vector2 = Vector2.ZERO
var headbob_pos: Vector3 = Vector3.ZERO

var step_sound_debounce_timeout: float = 0.0

var pending_mouse_input : Vector2 = Vector2(0,0)
var input_pressed: bool = false

func _ready() -> void:
	Util.add_input_action("move_forward", KEY_W)
	Util.add_input_action("move_backward", KEY_S)
	Util.add_input_action("move_left", KEY_A)
	Util.add_input_action("move_right", KEY_D)
	Util.add_input_action("move_jump", KEY_SPACE)
	Util.add_input_action("move_sprint", KEY_SHIFT)
	Util.add_input_action("move_crouch", KEY_CTRL)
	
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	
	if GRAVITY_OVERRIDE > 0.0:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 20.0)

func _process(delta: float) ->void:
	#_handle_head_movement()
	pass


func _physics_process(delta: float) -> void:
	_update_state(delta)
		
	_apply_gravity(delta)
	
	_handle_head_movement()
	
	_handle_movement(delta)
	
	_apply_head_bob(delta)
	
	_emit_step_signals(delta)
	
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pending_mouse_input = event.relative

#####

func _update_state(delta: float):
	var prev_state = current_state
	
	current_water_area = _test_point_in_area(global_position)
	
	if current_water_area:
		current_state = State.UNDERWATER
	elif not is_on_floor():
		current_state = State.IN_AIR
	else:
		current_state = State.ON_FLOOR
		
	state_duration += delta
	
	if current_state != prev_state:
		prev_state_duration = state_duration
		state_duration = 0.0
		
		const debounce_time: float = 0.3

		if current_state == State.UNDERWATER:
			was_underwater = true
			if prev_state == State.IN_AIR and prev_state_duration > debounce_time:
				player_body_entered_water.emit()
		elif current_state == State.ON_FLOOR:
			if was_underwater:
				player_body_left_water.emit()
				was_underwater = false
			elif prev_state == State.IN_AIR and prev_state_duration > debounce_time:
				player_landed.emit()


func _apply_gravity(delta: float):
	if current_state == State.IN_AIR:
		velocity += get_gravity() * delta
	elif current_state == State.UNDERWATER:
		if not UNDERWATER_GRAVITY_DISABLED:
			velocity += get_gravity() * WATER_GRAVITY_MULT * delta


func _handle_movement(delta: float):
	if Global.is_game_action_just_pressed("move_jump") and current_state == State.ON_FLOOR:
		velocity.y = JUMP_VELOCITY
		player_jumped.emit()
		
	const rate_of_change: float = 10.0
	if Global.is_game_action_pressed("move_sprint") and current_state == State.ON_FLOOR:
		speed = lerp(speed, SPRINT_SPEED, rate_of_change * delta)
	else:
		speed = lerp(speed, WALKING_SPEED, rate_of_change * delta)
		
	if current_state == State.UNDERWATER and not (not head_submerged and is_on_floor()):
		speed = SWIMMING_SPEED
		
	var input_dir := Vector3(Global.get_game_input_axis("move_left", "move_right"), 0.0, Global.get_game_input_axis("move_forward", "move_backward"))
	var direction := (input_dir.rotated(Vector3.UP, HEAD.global_rotation.y)).normalized()
	input_pressed = !!direction
	
	var accel: float
	if current_state == State.IN_AIR:
		accel = AIR_ACCEL
	elif input_pressed:
		accel = FLOOR_ACCEL
	else:
		accel = DECEL
		
	var desired_vel := direction * speed
	
	if current_state == State.UNDERWATER:
		if input_pressed:
			desired_vel.y = 0.0
			accel = WATER_ACCEL 
		else:
			accel = WATER_DECEL
		
		if Global.is_game_action_pressed("move_jump"):
			desired_vel.y = speed
		elif Global.is_game_action_pressed("move_crouch"):
			desired_vel.y = -speed
			
		velocity.y = lerp(velocity.y, desired_vel.y, WATER_ACCEL * delta)
	
	velocity.x = lerp(velocity.x, desired_vel.x, accel * delta)
	velocity.z = lerp(velocity.z, desired_vel.z, accel * delta)
	
	var actual_speed = Vector3(velocity.x, 0.0, velocity.z).length()
	var fov_intensity = clampf((actual_speed - WALKING_SPEED) / (SPRINT_SPEED - WALKING_SPEED), 0.0, 1.0)
	var desired_fov = lerp(FOV_MIN, FOV_MAX, fov_intensity)
	CAMERA.fov = lerp(CAMERA.fov, desired_fov, 10.0 * delta)
		

func _handle_head_movement():
	HEAD.rotation_degrees.y -= pending_mouse_input.x * MOUSE_SENS
	HEAD.rotation_degrees.x -= pending_mouse_input.y * MOUSE_SENS
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	pending_mouse_input = Vector2(0,0)
	

func _apply_head_bob(delta: float):
	if input_pressed and current_state == State.ON_FLOOR:
		const rate_of_change: float = 10.0
		if Global.is_game_action_pressed("move_sprint"):
			headbob_freq = lerp(headbob_freq, BOB_FREQ_SPRINTING, rate_of_change * delta)
			headbob_amp = lerp(headbob_amp, BOB_AMP_SPRINTING, rate_of_change * delta)
		else:
			headbob_freq = lerp(headbob_freq, BOB_FREQ_WALKING, rate_of_change * delta)
			headbob_amp = lerp(headbob_amp, BOB_AMP_WALKING, rate_of_change * delta)
			
		headbob_time.y += delta * headbob_freq
		if headbob_time.y > 2 * PI:
			headbob_time.y -= 2 * PI

		headbob_time.x += delta * headbob_freq * 0.5
		if headbob_time.x > 2 * PI:
			headbob_time.x -= 2 * PI
			
		headbob_pos.y = sin(headbob_time.y) * headbob_amp
		headbob_pos.x = cos(headbob_time.x - PI * 0.5) * headbob_amp * 1.5
		
		CAMERA.transform.origin = headbob_pos
	else:
		headbob_amp = 0.0
		CAMERA.transform.origin = lerp(CAMERA.transform.origin, Vector3.ZERO, 5.0 * delta)
		headbob_pos = Vector3.ZERO
		headbob_time = Vector2.ZERO


func _emit_step_signals(delta: float):
	if input_pressed and current_state == State.ON_FLOOR and cos(headbob_time.y) > 0.9 and step_sound_debounce_timeout <= 0.0:
		step_sound_debounce_timeout = 0.1
		player_stepped.emit()
		
	step_sound_debounce_timeout -= delta
	
	
func _test_point_in_area(point: Vector3, col_mask: int = 2):
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = col_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results = space_state.intersect_point(query)
	
	if results.size() > 0:
		return results[0].collider
	else:
		return null
