class_name Inventory extends Node

@onready var PARENT: Node3D = get_parent()
@export var WORLD: Node3D = null

var items: Array[Node3D] = []

var item_to_drop = null

func _ready():
	assert(WORLD)
	
	Util.add_input_action("game_inventory", KEY_I)
	Util.add_input_action("game_drop_item", KEY_G)

func print_items():
	if not items:
		print("Empty")
	else:
		print("---")
		print("%s items:" % items.size())
		for item in items:
			print("  %s" % item.name)
		

func add_item(item: Node3D):
	items.append(item)
	
func drop_item():
	var item = items.pop_back()
	if item:
		WORLD.add_child(item)
		var head = PARENT.find_child("Head")
		if head:
			item.global_position = head.global_position - 2.0 * head.basis[2]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("game_inventory"):
			print_items()
		elif event.is_action_pressed("game_drop_item"):
			drop_item()
