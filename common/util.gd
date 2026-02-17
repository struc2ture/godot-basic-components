class_name Util

static func add_input_action(action: StringName, physical_keycode: Key):
	if not InputMap.has_action(action):
		var event = InputEventKey.new()
		event.physical_keycode  = physical_keycode
		InputMap.add_action(action)
		InputMap.action_add_event(action, event)
