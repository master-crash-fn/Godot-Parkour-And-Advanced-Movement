extends Resource
class_name ScanPlane

@export var bot_start : Vector3
@export var bot_end : Vector3
var bot_collides : bool
var bot_normal : Vector3
var bot_point : Vector3
var bot_collision_distance : float

@export var top_start : Vector3
@export var top_end : Vector3
var top_collides : bool
var top_normal : Vector3
var top_point : Vector3
var top_collision_distance : float

#@export var confirmation_depth : float
var confirmation_depth : float
#var top_confirmation_start : Vector3
#var bot_confirmation_start : Vector3
var top_confirmation_collides : bool
#var top_confirmation_point : Vector3
#var top_confirmation_normal : Vector3
var bot_confirmation_collides : bool
#var bot_confirmation_point : Vector3
#var bot_confirmation_normal : Vector3

var shape : Shape3D
var shape_collision_point : Vector3

# not an int-int, it's a bitmask 0xFFFFFFFF, google about it and/or read collision layers docs
@export var collision_mask : int

enum ScanOutcomes {WALL, STEP, STEP_SLOPE, FENCE, CURTAIN, TUNNEL, TABLE, BEAM, EMPTY_SPACE}
var scan_outcome : ScanOutcomes

var space : PhysicsDirectSpaceState3D

var request : PhysicsRayQueryParameters3D
var results : Dictionary

var shape_request : PhysicsShapeQueryParameters3D
var shape_results : PackedFloat32Array

func is_wall() -> bool:
	if not (top_collides or top_confirmation_collides):
		return false
	if not (bot_collides or bot_confirmation_collides):
		return false
	if sin(top_normal.angle_to(Vector3.UP)) > sin(deg_to_rad(60)): # sin is like an abs() for angles < 180`
		return false
	if sin(top_normal.angle_to(Vector3.UP)) > sin(deg_to_rad(60)):
		return false
	return true



func scan(space : PhysicsDirectSpaceState3D):
	init(space)
	if area_is_empty():
		print("empty scan")
		scan_outcome = ScanOutcomes.EMPTY_SPACE
		return
	find_normals()
	define_type()


func define_type():
	if is_wall():
		scan_outcome = ScanOutcomes.WALL
		return
	scan_outcome = ScanOutcomes.EMPTY_SPACE


func area_is_empty() -> bool:
	shape_request = PhysicsShapeQueryParameters3D.new()
	var shape_origin = (top_start + bot_start) / 2
	var shape_basis_z = top_start.direction_to(top_end)
	var shape_basis_y = bot_start.direction_to(top_start)
	var shape_basis_x = shape_basis_y.cross(shape_basis_z)
	shape_request.transform = Transform3D(shape_basis_x, shape_basis_y, shape_basis_z, shape_origin)
	shape_request.motion = shape_basis_z * top_start.distance_to(top_end)
	shape_results = space.cast_motion(shape_request)
	if shape_results[0] == 1.0 and shape_results[1] == 1.0:
		return true
	return false

func find_normals():
	request = PhysicsRayQueryParameters3D.create(bot_start, bot_end, collision_mask)
	results = space.intersect_ray(request)
	if results.is_empty():
		bot_collides = false
	else:
		bot_collides = true
		bot_point = results["position"]
		bot_normal = results["normal"]
	
	request = PhysicsRayQueryParameters3D.create(top_start, top_end, collision_mask)
	results = space.intersect_ray(request)
	if results.is_empty():
		top_collides = false
	else:
		top_collides = true
		top_point = results["position"]
		top_normal = results["normal"]
	
	if not top_collides:
		request = PhysicsRayQueryParameters3D.create(top_end, top_end + Vector3(0, -confirmation_depth, 0), collision_mask)
		results = space.intersect_ray(request)
		if results.is_empty():
			top_confirmation_collides = false
		else:
			top_confirmation_collides = true
			top_point = results["position"]
			top_normal = results["normal"]
	
	if not bot_collides:
		request = PhysicsRayQueryParameters3D.create(bot_end, bot_end + Vector3(0, confirmation_depth, 0), collision_mask)
		results = space.intersect_ray(request)
		if results.is_empty():
			bot_confirmation_collides = false
		else:
			bot_confirmation_collides = true
			bot_point = results["position"]
			bot_normal = results["normal"]

func init(space : PhysicsDirectSpaceState3D):
	self.space = space
	
	if confirmation_depth == 0:
		confirmation_depth = top_start.y - bot_start.y
	
	shape = BoxShape3D.new()
	shape.size = Vector3(0.1, confirmation_depth, 0.1)
