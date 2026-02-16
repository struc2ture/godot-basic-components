extends Node3D

@export var WATER_AREA_COLLISION_MASK: int = 2

func _process(delta: float) -> void:
	var water_area = _test_point_in_area(global_position, WATER_AREA_COLLISION_MASK)
	
	if water_area:
		$UnderwaterEffect.show()
		if water_area.has_method("get_screen_effect_material"):
			$UnderwaterEffect/ColorRect.material = water_area.get_screen_effect_material()
	else:
		$UnderwaterEffect.hide()


func _test_point_in_area(point: Vector3, col_mask: int):
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
