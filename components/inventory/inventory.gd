class_name Inventory extends Node

var items: Array[String] = []

func print_items():
	if not items:
		print("Empty")
	else:
		print("---")
		print("%s items:" % items.size())
		for item in items:
			print("  %s" % item)
		
func add_item(item: String):
	items.append(item)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("game_inventory"):
			print_items()
