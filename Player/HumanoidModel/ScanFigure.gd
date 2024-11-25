extends Resource
class_name ScanFigure

@export var left_start : Vector3
@export var left_end : Vector3
@export var right_start : Vector3
@export var right_end : Vector3
@export var height : float
#@export var sample_point : Vector3

#it's not 1-32, it's a bit mask, google into that
@export var collision_mask : int

var left_collides : bool
var left_point : Vector3
var left_normal : Vector3
var left_top_exists : bool
var left_top_point : Vector3
var left_top_normal : Vector3

var right_collides : bool
var right_point : Vector3
var right_normal : Vector3
var right_top_exists : bool
var right_top_point : Vector3
var right_top_normal : Vector3


func full_wall() -> bool:
	return left_collides and right_collides

func no_wall() -> bool:
	return not (left_collides or right_collides)

func partial_wall_normal() -> Vector3:
	if not (no_wall() or full_wall()):
		if left_collides:
			return left_normal
		else:
			return right_normal
	return Vector3.ZERO # kinda garbage, but the probabability of anyone hitting zero vector here is miniscule

func full_plane() -> bool:
	return left_top_exists and right_top_exists

func no_plane() -> bool:
	return not (left_top_exists or right_top_exists)

func partial_plane_point() -> Vector3:
	if not (no_plane() or full_plane()):
		if left_top_exists:
			return left_top_point
		else:
			return right_top_point
	return Vector3.ZERO # kinda garbage, but the probabability of anyone hitting zero vector here is miniscule

func plane_is_flat() -> bool:
	if left_top_exists and left_top_normal.angle_to(Vector3.UP) > 0.34:
		return false
	if right_top_exists and right_top_normal.angle_to(Vector3.UP) > 0.34:
		return false
	return true

func get_left_query() -> PhysicsRayQueryParameters3D:
	return PhysicsRayQueryParameters3D.create(left_start, left_end, collision_mask)

func get_left_top_query() -> PhysicsRayQueryParameters3D:
	if left_collides:
		var margin : Vector3 = left_start.direction_to(left_end) * 0.01
		return PhysicsRayQueryParameters3D.create(left_point + Vector3(0, height, 0) + margin, left_point, collision_mask)
	return PhysicsRayQueryParameters3D.create(left_end + Vector3(0, height, 0), left_end, collision_mask)

func get_right_query() -> PhysicsRayQueryParameters3D:
	return PhysicsRayQueryParameters3D.create(right_start, right_end, collision_mask)

func get_right_top_query() -> PhysicsRayQueryParameters3D:
	if right_collides:
		var margin : Vector3 = right_start.direction_to(right_end) * 0.01
		return PhysicsRayQueryParameters3D.create(right_point + Vector3(0, height, 0) + margin, right_point, collision_mask)
	return PhysicsRayQueryParameters3D.create(right_end + Vector3(0, height, 0), right_end, collision_mask)

func set_left_results(results : Dictionary):
	if results.is_empty():
		left_collides = false
	else:
		left_collides = true
		left_point = results["position"]
		left_normal = results["normal"]

func set_left_top_results(results : Dictionary):
	if results.is_empty():
		left_top_exists = false
	else:
		left_top_exists = true
		left_top_point = results["position"]
		left_top_normal = results["normal"]

func set_right_results(results : Dictionary):
	if results.is_empty():
		right_collides = false
	else:
		right_collides = true
		right_point = results["position"]
		right_normal = results["normal"]

func set_right_top_results(results : Dictionary):
	if results.is_empty():
		right_top_exists = false
	else:
		right_top_exists = true
		right_top_point = results["position"]
		right_top_normal = results["normal"]





#sdfsdf
