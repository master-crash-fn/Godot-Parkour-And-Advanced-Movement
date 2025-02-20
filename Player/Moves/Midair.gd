extends Move

@export var ledge_sensor : RaySlice

@export var DELTA_VECTOR_LENGTH = 6
var jump_direction : Vector3

var landing_height : float = 1.163


func map_custom_actions(input : InputPackage):
	if input.input_actions.has("go_up") and area_awareness.can_wall_jump():
		input.input_actions.erase("go_up")
		input.move_names.append("jump_wall")
	
	if area_awareness.search_for_climbable_edges(ledge_sensor):
		input.input_actions.erase("midair")
		input.move_names.append("ledge_grab")
	
	if input.input_actions.has("beam_walk"):
		input.input_actions.erase("midair")


func default_lifecycle(input : InputPackage):
	if area_awareness.is_on_floor():
		var xz_velocity = player.velocity
		xz_velocity.y = 0
		if xz_velocity.length_squared() >= 10:
			return "landing_sprint"
		return "landing_run"
	else:
		return best_input_that_can_be_paid(input)


func update(_input : InputPackage, delta ):
	player.velocity.y -= gravity * delta
	player.move_and_slide()


func process_input_vector(input : InputPackage, delta : float):
	var input_direction = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
	var input_delta_vector = input_direction * DELTA_VECTOR_LENGTH
	
	jump_direction = (jump_direction + input_delta_vector * delta).limit_length(clamp(player.velocity.length(), 1, 999999))
	if jump_direction:
		player.look_at(player.global_position - jump_direction)
	
	var new_velocity = (player.velocity + input_delta_vector * delta).limit_length(player.velocity.length())
	player.velocity = new_velocity


func on_enter_state(_input : InputPackage):
	if Time.get_unix_time_from_system() - area_awareness.last_ledge_grab < area_awareness.ledge_cooldown:
		jump_direction = Vector3.ZERO
	else:
		jump_direction = Vector3(player.basis.z) * clamp(player.velocity.length(), 1, 999999)
		jump_direction.y = 0
