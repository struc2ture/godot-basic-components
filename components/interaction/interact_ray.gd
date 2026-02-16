extends RayCast3D

@export var PLAYER: Player = null

var hovered_interactable: Interactable = null


func _ready():
	assert(PLAYER)


func _process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider is Interactable:
			hovered_interactable = collider
	else:
		hovered_interactable = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("game_activate"):
			if hovered_interactable:
				hovered_interactable.interact(PLAYER)
