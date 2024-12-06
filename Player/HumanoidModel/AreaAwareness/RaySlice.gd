extends Resource
class_name RaySlice

@export var start : Vector3
@export var depth : Vector3
@export var width : Vector3
@export var resolution : float = 0.1
@export var collision_mask : int = 2

var _start : Vector3
var _end : Vector3
var request : PhysicsRayQueryParameters3D
var results : Dictionary

func scan(global_transform : Transform3D, space : PhysicsDirectSpaceState3D) -> Dictionary:
	for i in int(width.length() / resolution):
		_start = global_transform * (start + (width / resolution) * i)
		_end = global_transform * (start + depth)
		request = PhysicsRayQueryParameters3D.create(_start, _end, collision_mask)
		results = space.intersect_ray(request)
		if not results.is_empty():
			return results
	return {}
