extends Move

var start_position : Vector3
var end_position : Vector3
var start_basis_dir : Vector3
var grab_direction : Vector3

@export var h : float = 1


func default_lifecycle(input : InputPackage):
	if works_longer_than(duration):
		return "ledge_grab"
	return "okay"


func update(_input : InputPackage, delta):
	move_player(delta)


func move_player(delta):
	if get_progress() > 0.35 and get_progress() < 1.15:
		#player.global_position = lerp(start_position, end_position, (get_progress() - 0.35) / (0.96-0.35))
		#player.basis.z = lerp(start_basis_dir, grab_direction, get_progress() / (0.96-0.35)).normalized()
		#player.basis.x = Vector3.UP.cross(player.basis.z)
		var target_point_2d : Vector2 = calculate_trajectory((get_progress() - 0.35) / (1.15-0.35))
		var target_point_3d : Vector3 = (end_position - start_position)
		target_point_3d.y = 0
		target_point_3d = target_point_3d.normalized() * target_point_2d.x
		target_point_3d.y = start_position.y + target_point_2d.y
		player.global_position = start_position + target_point_3d
		prints((get_progress() - 0.35) / (0.96-0.35), calculate_trajectory((get_progress() - 0.35) / (1.15-0.35)).y, end_position.y - start_position.y)
		#prints(player.global_position, end_position)
		player.basis.z = lerp(start_basis_dir, grab_direction, (get_progress() - 0.35) / (1.15-0.35)).normalized()
		player.basis.x = Vector3.UP.cross(player.basis.z)
		


func calculate_trajectory(percentage : float) -> Vector2:
	var delta = (end_position - start_position)
	var yl = delta.y
	#prints("yl", yl)
	delta.y = 0
	var xl = delta.length()
	#prints("xl", xl)
	var A = -pow(xl, 4)
	var B = -2*pow(xl,2)*(yl+2*h)
	var C = -pow(yl, 2)
	var D = pow(B, 2) - 4 * A * C
	var a = (-B+sqrt(D)) / (2 * A)
	var b = (yl - pow(xl,2)*a) / xl
	if not (-b / (2*a) <= xl and -b / (2*a) >= 0) : # ie if we took the wrong root of the equation
		a = (-B-sqrt(D)) / (2 * A)
	var xh = -b / 2*a
	var yh = a * pow(xh, 2) + b * xh
	#prints(xh, yh)
	#prints(a,b)
	#$"../../AreaAwareness/test_marker".global_position = end_position
	var x = xl * percentage
	return Vector2(x, a * pow(x, 2) + b * x)
	


func on_enter_state(input : InputPackage):
	#start_point = player.global_transform * Vector3(0, 1.715, 0.403)
	start_position = player.global_position
	start_basis_dir = player.basis.z
	var leap_direction = start_position.direction_to(area_awareness.ledge_climbing_point)
	leap_direction.y = 0
	grab_direction = Vector3.UP.cross(area_awareness.current_ledge[0].direction_to(area_awareness.current_ledge[1]))
	if grab_direction.angle_to(leap_direction) > PI / 2:
		grab_direction *= -1
	
	end_position = area_awareness.ledge_climbing_point - grab_direction * 0.403 + Vector3(0, -1.715, 0)
	
	area_awareness.last_wall_jump_normal = grab_direction.normalized()
