extends Move


func default_lifecycle(input : InputPackage):
	if works_longer_than(duration):
		return "ledge_grab"
	return "okay"


func on_enter_state(input : InputPackage):
	area_awareness.ledge_climbing_point = player.global_transform * Vector3(0, 1.715, 0.403)
