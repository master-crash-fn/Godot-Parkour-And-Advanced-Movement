extends Move

@export var ledge_sensor : RaySlice

@export var SPEED = 3.0
@export var TURN_SPEED = 2
 

func map_custom_actions(input : InputPackage):
	if input.input_actions.has("go_up"):
		if area_awareness.search_for_climbable_edges(ledge_sensor):
			input.move_names.append("ledge_climb_up")
		else:
			input.move_names.append("jump_run")


func default_lifecycle(input : InputPackage):
	return best_input_that_can_be_paid(input)


func update(_input : InputPackage, _delta : float):
	player.move_and_slide()


func process_input_vector(input : InputPackage, delta : float):
	var y_speed = player.velocity.y
	var input_direction = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
	var face_direction = player.basis.z
	var angle = face_direction.signed_angle_to(input_direction, Vector3.UP)
	var new_z = player.basis.z.rotated(Vector3.UP, clamp(angle, -tracking_angular_speed * delta, tracking_angular_speed * delta))
	var new_x = -new_z.cross(Vector3.UP)
	player.basis = Basis(new_x, Vector3.UP, new_z).orthonormalized()
	if abs(angle) >= tracking_angular_speed * delta:
		player.velocity = player.basis.z * TURN_SPEED
	else:
		player.velocity = player.basis.z * SPEED
	if area_awareness.get_floor_distance() > 0.8:
		y_speed -= gravity * delta
	player.velocity.y = y_speed



#func on_exit_state():
	#animator.set_speed_scale(1)
