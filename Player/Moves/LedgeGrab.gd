extends Move

var height : float
var distance : float

func default_lifecycle(input : InputPackage):
	return "okay"

func update(_input : InputPackage, delta : float):
	rotate_player(delta)
	move_player(delta)

func rotate_player(delta : float):
	var vertical_axis : Vector3 = player.global_position
	vertical_axis.y = area_awareness.ledge_climbing_point.y
	var climb_direction : Vector3 = vertical_axis.direction_to(area_awareness.ledge_climbing_point)
	var face_direction = player.basis.z
	var angle = face_direction.signed_angle_to(climb_direction, Vector3.UP)
	if abs(angle) > 0.01 and get_progress() < 0.9667:
		player.rotate_y(angle / 10)

func move_player(delta : float):
	#var delta_pos = get_root_position_delta(delta)
	#var velocity = player.get_quaternion() * delta_pos
	var velocity : Vector3
	
	if get_progress() <= 0.3:
		velocity.y += ((height - 1.769) / 0.3) * delta
		velocity += player.basis.z * ((distance - 0.35) / 0.3) * delta
		player.global_position += velocity
		



func on_enter_state():
	height = area_awareness.ledge_climbing_point.y - (player.global_position.y)
	var reduced_grab_point = area_awareness.ledge_climbing_point
	reduced_grab_point.y = player.global_position.y
	distance = player.global_position.distance_to(reduced_grab_point)
