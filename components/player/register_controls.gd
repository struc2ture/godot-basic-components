@tool
extends EditorScript

### FOR A LATER IDEA!!!

func add_inputs():
	# add to project settings
	var jump_event = InputEventKey.new()
	jump_event.keycode = KEY_SPACE
	InputMap.action_add_event("move_jump", jump_event)

func _run():
	add_inputs()
