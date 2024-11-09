extends Move


func default_lifecycle(input) -> String:
	if not area_awareness.is_on_floor():
		return "midair"
	
	return best_input_that_can_be_paid(input)


func on_enter_state():
	player.velocity = Vector3.ZERO
