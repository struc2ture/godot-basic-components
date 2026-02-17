extends Interactable

func interact(player: Player):
	var inventory = player.find_child("Inventory")
	if inventory:
		var parent = get_parent()
		inventory.add_item(parent)
		if parent is RigidBody3D:
			parent.linear_velocity = Vector3.ZERO
			parent.angular_velocity = Vector3.ZERO
		parent.global_position = Vector3.ZERO
		parent.global_rotation = Vector3.ZERO
		parent.get_parent().remove_child(parent)
