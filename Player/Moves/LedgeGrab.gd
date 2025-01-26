extends Move

@export var ledge_leap_sensor : RaySlice 

var grab_direction : Vector3

var next_point : int # 0 or 1
enum Substate {IDLE, TRAVERSE, ANGLE}
var current_substate : Substate = Substate.IDLE

# these variables power angle transition be it an animation or our procedural abomination
var next_ledge : PackedVector3Array
var common_point : int
var next_grab_dir : Vector3
var angle_traversal_duration : float = 1
var angle_progress : float = 0

# these are here for move_database to be able to create a track
@export var left_root_pos : Vector3
@export var right_root_pos : Vector3

func map_input_actions(input : InputPackage):
	if current_substate != Substate.ANGLE and works_longer_than(0.3):
		if input.input_actions.has("go_up"):
			var input_vector : Vector3 = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
			if input_vector:
				if input_vector.angle_to(grab_direction) < PI / 6:
					input.move_names.append("ledge_pull_up")
					return
				if area_awareness.search_for_leapable_edges(ledge_leap_sensor, towards_input_transform(input_vector)):
					input.move_names.append("ledge_leap")
					return
			input.move_names.append("jump_wall")
		if input.input_actions.has("go_down"):
			input.move_names.append("midair")
			print("down")
		if input.input_actions.has("light_attack_pressed"):
			input.move_names.append("ledge_attack_1")
		if input.input_actions.has("heavy_attack_pressed"):
			input.move_names.append("ledge_attack_2")
		

func towards_input_transform(input_vector : Vector3) -> Transform3D:
	var basis : Basis
	basis.z = input_vector
	basis.y = Vector3.UP
	basis.x = Vector3.UP.cross(input_vector)
	#$"../../AreaAwareness/test_marker".global_position = player.global_position + input_vector
	return Transform3D(basis, player.global_position)

func default_lifecycle(input : InputPackage):
	if current_substate == Substate.ANGLE:
		return "okay"
	return best_input_that_can_be_paid(input)


func update(input : InputPackage, delta : float):
	var input_vector : Vector3 = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
	choose_direction(input_vector)
	choose_substate(input_vector)
	#print(current_substate)
	choose_animation(input_vector)
	
	if works_less_than(0.3):
		correct_posture(delta)
	else:
		move_player(delta)

# TODO consider enum, but I like current tech with index to use it directly as area_awareness.current_ledge[next_point]
func choose_direction(input_vector : Vector3):
	if current_substate == Substate.ANGLE:
		return
	if not input_vector:
		next_point = -1 # nowhere
		return
	if input_vector.angle_to(area_awareness.current_ledge[0].direction_to(area_awareness.current_ledge[1])) < PI / 3:
		next_point = 1 # towards "right" point on LocationElement
		return
	if input_vector.angle_to(area_awareness.current_ledge[1].direction_to(area_awareness.current_ledge[0])) < PI / 3:
		next_point = 0  # towards "left" point on LocationElement
		return
	next_point = -1

func choose_substate(input_vector : Vector3):
	if current_substate == Substate.ANGLE:
		return # because in a real game angle traversal is probably a locking animation we exit it by a different mechanism
	if not input_vector or next_point == -1:
		current_substate = Substate.IDLE
		return
	if ledge_distance_to_chosen_vertex() > area_awareness.shoulder_width:
		current_substate = Substate.TRAVERSE
		return
	if have_next_ledge():
		current_substate = Substate.ANGLE
		next_ledge = area_awareness.current_ledge_object.get_next_climbable_neighbour(area_awareness.current_ledge_id, next_point)
		calculate_next_grab_direction()
		return
	current_substate = Substate.IDLE # we still need it in case we are trying to move into nothingness

# distance to the next point in the direction we are moving currently | THROWS if called whilst idle (-1 index)
func ledge_distance_to_chosen_vertex() -> float:
	return (player.global_transform * Vector3(0, 1.715, 0.403)).distance_to(area_awareness.current_ledge[next_point])


func calculate_next_grab_direction():
	if next_ledge[0] == area_awareness.current_ledge[next_point]:
		common_point = 0
	else:
		common_point = 1
	var current_dir = Vector3.UP.cross(area_awareness.current_ledge[next_point].direction_to(area_awareness.current_ledge[(next_point + 1) % 2])).normalized()
	if current_dir.is_equal_approx(grab_direction.normalized()):
		next_grab_dir = Vector3.UP.cross(next_ledge[(common_point + 1) % 2].direction_to(next_ledge[common_point]))
	else:
		next_grab_dir = Vector3.UP.cross(next_ledge[common_point].direction_to(next_ledge[(common_point + 1) % 2]))


func choose_animation(input_vector : Vector3):
	var target_animation : String
	if current_substate == Substate.IDLE:
		target_animation = "parkour_ledge_idle"
	elif current_substate == Substate.TRAVERSE:
		if input_vector.cross(player.basis.z).y < 0:
			target_animation = "ledge_left"
		else :
			target_animation = "ledge_right"
	else:
		# I duplicate this because I don't have such an animation, but here's when you set it if you have it
		if input_vector.cross(player.basis.z).y < 0:
			target_animation = "ledge_left" 
		else :
			target_animation = "ledge_right"
	if target_animation != animation:
		animation = target_animation
		animator.update_body_animations()

# We don't have processing for ANGLE state becasue we can't "grab" a ledge by an angle, possibly TODO add
func correct_posture(delta : float):
	# move towards climbing point
	player.global_position = player.global_position.move_toward(area_awareness.ledge_climbing_point - (player.global_basis * Vector3(0, 1.715, 0.403)), 0.05)
	# rotate to align with ledge
	var correction_angular_speed : float = 0.3
	player.rotate_y(-clamp(grab_direction.signed_angle_to(player.basis.z, Vector3.UP), -correction_angular_speed, correction_angular_speed))

# (next_point + 1) % 2 is a smartass way to turn 0 into 1 and back so we juggle vector direction in one string to flex
func move_player(delta : float):
	var velocity = Vector3(0, 0, 0)
	if current_substate == Substate.TRAVERSE:
		velocity = area_awareness.current_ledge[(next_point + 1) % 2].direction_to(area_awareness.current_ledge[next_point]) * 0.9
		player.global_position += velocity * delta
		return
	elif current_substate == Substate.ANGLE:
		var percentage = angle_progress / angle_traversal_duration
		player.global_basis.z = lerp(grab_direction, next_grab_dir, percentage).normalized()
		player.basis.x = Vector3.UP.cross(player.global_basis.z)
		
		if percentage <= 0.5:
			var end = area_awareness.current_ledge[next_point]
			var start = end + end.direction_to(area_awareness.current_ledge[(next_point + 1) % 2]) * area_awareness.shoulder_width
			player.global_position = lerp(start, end, percentage * 2) - player.global_basis * Vector3(0, 1.715, 0.403)
		else:
			var start = area_awareness.current_ledge[next_point]
			var end = start + area_awareness.current_ledge[next_point].direction_to(next_ledge[(common_point + 1) % 2]) * area_awareness.shoulder_width
			player.global_position = lerp(start, end, (percentage - 0.5) * 2) - player.global_basis * Vector3(0, 1.715, 0.403)
		
		angle_progress += delta
		if angle_progress >= angle_traversal_duration:
			current_substate = Substate.IDLE
			angle_progress = 0
			area_awareness.current_ledge = next_ledge
			area_awareness.current_ledge_id = next_ledge[2].x
			grab_direction = next_grab_dir
			area_awareness.last_wall_jump_normal = -player.basis.z


func have_next_ledge() -> bool:
	if next_point == 1:
		return area_awareness.current_ledge_object.has_climbable_right_neighbour(area_awareness.current_ledge_id)
	return area_awareness.current_ledge_object.has_climbable_left_neighbour(area_awareness.current_ledge_id)


func on_enter_state(_input : InputPackage):	
	grab_direction = Vector3.UP.cross(area_awareness.current_ledge[0].direction_to(area_awareness.current_ledge[1]))
	if grab_direction.angle_to(player.basis.z) > PI / 2:
		grab_direction *= -1
	
	area_awareness.last_wall_jump_normal = grab_direction.normalized()


func on_exit_state():
	player.velocity = Vector3.ZERO
	area_awareness.last_ledge_grab = Time.get_unix_time_from_system()
	animation = ""
