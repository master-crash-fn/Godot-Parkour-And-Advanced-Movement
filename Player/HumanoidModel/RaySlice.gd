extends Resource
class_name RaySlice


@export var height : float
@export var depth : float
@export var resolution : float = 0.1
@export var collision_mask : int = 2

var start : Vector3
var end : Vector3
var request : PhysicsRayQueryParameters3D
var results : Dictionary

func scan(from_position : Vector3, in_direction : Vector3, in_space : PhysicsDirectSpaceState3D) -> Dictionary:
	for i in int(height / resolution):
		start = from_position + Vector3(0, i * resolution, 0)
		end = start + in_direction.normalized() * depth
		request = PhysicsRayQueryParameters3D.create(start, end, collision_mask)
		results = in_space.intersect_ray(request)
		if not results.is_empty():
			return results
	return {}
