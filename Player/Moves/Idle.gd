extends Move

@export var ledge_sensor : RaySlice

func map_input_actions(input : InputPackage):
	if input.input_actions.has("go_up"):
		if area_awareness.search_for_climbable_edges(ledge_sensor):
			input.move_names.append("ledge_climb_up")
		else:
			input.move_names.append("jump_run")


func default_lifecycle(input) -> String:
	return best_input_that_can_be_paid(input)


func update(_input : InputPackage, delta : float):
	var y_speed = player.velocity.y
	if area_awareness.get_floor_distance() > 0.8:
		y_speed -= gravity * delta
	player.velocity.y = y_speed


func on_enter_state(_input : InputPackage):
	player.velocity = Vector3.ZERO
