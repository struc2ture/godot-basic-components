extends Node


var overlay_active: bool = false

var _current_scene = null

func _ready() -> void:
	Util.add_input_action("debug_toggle_mouse", KEY_QUOTELEFT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var root = get_tree().root
	_current_scene = root.get_child(-1)


func _process(delta: float) -> void:
	#print(Engine.get_frames_per_second())
	if Input.is_action_just_pressed("debug_toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	#if Input.is_action_just_pressed("exit"):
		#get_tree().quit()
	

func set_overlay(active: bool) -> void:
	if active:
		_set_overlay_active(active)
	else:
		get_tree().create_timer(0.1).timeout.connect(_on_deactivate_timer)
	

func _set_overlay_active(active: bool):
	overlay_active = active
	SignalBus.overlay_active.emit(overlay_active)



func is_game_action_just_pressed(action: StringName) -> bool:
	if not overlay_active:
		return Input.is_action_just_pressed(action)
	else:
		return false

func is_game_action_pressed(action: StringName) -> bool:
	if not overlay_active:
		return Input.is_action_pressed(action)
	else:
		return false

func get_game_input_axis(negative_action: StringName, positive_action: StringName) -> float:
	if not overlay_active:
		return Input.get_axis(negative_action, positive_action)
	else:
		return 0.0


func goto_scene(path):
	set_overlay(false) # reset overlay in case it's open
	_deferred_goto_scene.call_deferred(path)
	

func _deferred_goto_scene(path):
	_current_scene.free()
	var s = ResourceLoader.load(path)
	_current_scene = s.instantiate()
	get_tree().root.add_child(_current_scene)
	get_tree().current_scene = _current_scene


func _on_deactivate_timer():
	_set_overlay_active(false)
	pass
