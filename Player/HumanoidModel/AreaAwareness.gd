extends Node3D
class_name AreaAwareness

var last_pushback_vector : Vector3
var last_wall_jump_normal : Vector3
var last_input_package : InputPackage

enum Area {FLOOR, AIR, WATER, SWAMP, LEDGE}

@onready var space : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

# This is the primary ray to scan the surface beneath us
# Default root position in T-pos is 1.042 meters high and 0.932 meters in current idle pose
# Due to CharacterBody3D's is_on_floor having unwanted consequences and not being customisable enough,
# I quit using it and instead with this ray I define two methods for floor detection.
# is_on_floor() and is_falling()
@onready var downcast = $Downcast as RayCast3D
var on_floor_height : float = 1

@onready var downcast_2 = $Downcast2 as RayCast3D
@onready var wallcast_1 = $WallCast1 as RayCast3D
@onready var wallcast_2 = $WallCast2 as RayCast3D

@onready var model = $".." as PlayerModel
@onready var resources = $"../Resources" as HumanoidResources
@onready var states = $"../States" as HumanoidStates

@onready var area_sensor = $AreaSensor as Area3D
@onready var area_sensor_collider = $AreaSensor/AreaSensorCollider

var current_beam : ProtoBeam
var last_beam_fall : float = 0
var beam_cooldown : float = 0.2

var current_ledge : MarkedLedge
var ledge_climbing_point : Vector3

@export var ray_slice : RaySlice
var ray_slice_start : Vector3 = Vector3(0, 0.9, 0.16)
@onready var slice_cast = $ShapeCast3D as ShapeCast3D
@onready var slice = $Area3D/Slice as CollisionShape3D
@onready var slice_plane : Plane 
var plane_1 : Vector3
var plane_2 : Vector3
var plane_3 : Vector3
var edge_1 : Vector3
var edge_2 : Vector3
#var dot_hor : float
#var dot_ver : float
var normal : Vector3
var normal_1 : Vector3
var normal_2 : Vector3


@export_group("cringe")
@export var pointers : Array[CSGSphere3D]

var benchmark_start : float
#var benchmark_sum : float = 0
#var benchmarl_frames : int = 0

# We don't have a lot of forced contexts here, but they have a shared formula,
# essentially, a forced context can be formulated as "floor is [something]".
# Currently we just push another action to movement actions,
# but I can see the future where it becomes an enum field in area awareness, just "what is the floor here".
func add_context(input : InputPackage) -> InputPackage:
	benchmark_start = Time.get_ticks_usec()
	search_for_edges_3()
	print("cost: " + str(Time.get_ticks_usec() - benchmark_start) + " microseconds")
	
	if feel_beam():
		input.movement_actions.append("beam_walk")
		current_beam = downcast_2.get_collider()
	if not is_on_floor():
		input.movement_actions.append("midair")
	last_input_package = input
	return input

func eligible_for_wall_jump() -> bool:
	wallcast_1.force_raycast_update()
	wallcast_2.force_raycast_update()
	if wallcast_1.is_colliding():
		$test_marker.global_position = wallcast_1.get_collision_point()
		last_wall_jump_normal = wallcast_1.get_collision_normal()
		return true and resources.can_be_paid(states.get_move_by_name("jump_wall"))
	if wallcast_2.is_colliding():
		$test_marker.global_position = wallcast_2.get_collision_point()
		last_wall_jump_normal = wallcast_2.get_collision_normal()
		return true and resources.can_be_paid(states.get_move_by_name("jump_wall"))
	return false

func feel_beam() -> bool:
	downcast_2.force_raycast_update()
	if downcast_2.is_colliding() and Time.get_unix_time_from_system() - last_beam_fall > beam_cooldown:
		#$test_marker.global_position = downcast_2.get_collision_point()
		return true
	return false

func is_on_floor() -> bool:
	#print(get_floor_distance())
	return get_floor_distance() <= on_floor_height

func get_floor_distance() -> float:
	downcast.force_raycast_update()
	if downcast.is_colliding():
		#$Downcast2.global_position = downcast.get_collision_point()
		return downcast.global_position.distance_to(downcast.get_collision_point())
	return 999999

# The final algo 
func search_for_edges():
	var ray_slice_res = ray_slice.scan(global_transform * ray_slice_start, global_basis.z, space)
	if not ray_slice_res.is_empty():
		var collider = ray_slice_res["collider"]
		if collider is LocationElement:
			plane_1 = global_transform * ray_slice_start
			plane_2 = global_transform * ray_slice_start + global_basis.z * ray_slice.depth
			plane_3 = global_transform * ray_slice_start + Vector3.UP * ray_slice.height
			pointers[0].global_position = plane_1
			pointers[1].global_position = plane_2
			pointers[2].global_position = plane_3
			normal = ray_slice_res["normal"]
			var edge : PackedVector3Array = collider.has_climbable_edge(normal, plane_1, plane_2, plane_3)
			if not edge.is_empty():
				$test_marker.global_position = collider.global_transform * edge[2]
			else:
				$test_marker.global_position = Vector3.ZERO

# shell of the past to use as a demonstration of shapecasts being meh
func search_for_edges_2():
	slice_cast.force_shapecast_update()
	if slice_cast.is_colliding():
		var start : Vector3 = slice_cast.global_position
		start.y = slice_cast.get_collision_point(0).y - 0.01
		var end : Vector3 = slice_cast.get_collision_point(0)
		end = start + start.direction_to(end) * 1.5
		var request : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end, 2)
		var results : Dictionary = space.intersect_ray(request)
		if not results.is_empty():
			pass

# a funny iteration that just cross-sections the mesh it coolides with and visualises it
func search_for_edges_3():
	var ray_slice_res = ray_slice.scan(global_transform * ray_slice_start, global_basis.z, space)
	if not ray_slice_res.is_empty():
		var collider = ray_slice_res["collider"]
		if collider is LocationElement:
			for marker in pointers:
				marker.global_position = Vector3.ZERO
			plane_1 = global_transform * ray_slice_start
			plane_2 = global_transform * ray_slice_start + global_basis.z * ray_slice.depth
			plane_3 = global_transform * ray_slice_start + Vector3.UP * ray_slice.height
			pointers[0].global_position = plane_1
			pointers[1].global_position = plane_2
			pointers[2].global_position = plane_3
			var plane : Plane = Plane(plane_1,plane_2,plane_3)
			var vis_i = 0
			for edge in collider.edges_angles:
				var intersection = plane.intersects_segment(collider.global_transform * edge[0],collider.global_transform * edge[1])
				if intersection:
					#print(intersection)
					if vis_i < 24:
						pointers[vis_i].global_position = intersection
					vis_i += 1

# this one highlights cringe hallutinations, to use, enable the collision shape under AreaSensor
# you can play with different areas and embrace the "usefulness" of this approach
@export var surfaces_detector : CollisionShape3D
var surfaces_result : Array
var surfaces_request : PhysicsShapeQueryParameters3D
func look_for_surfaces():
	# in case you want your zone follow the camera angle, not character's nose
	#surfaces_detector.global_basis = model.player.camera_mount.global_basis
	
	surfaces_result.clear()
	surfaces_request = PhysicsShapeQueryParameters3D.new()
	surfaces_request.shape = surfaces_detector.shape
	surfaces_request.collision_mask = 2
	surfaces_request.transform = surfaces_detector.global_transform
	
	var result = space.collide_shape(surfaces_request, 10)
	for i in result.size() / 2:
		surfaces_result.append(result[ 2*i + 1 ])
		print(result[ 2*i + 1 ])
	#print(surfaces_result)
	print("---------------")
	#var possible_edges : Array = deduplicate_array(surfaces_result.filter(func(vector): return surfaces_result.count(vector) > 1))

	#visualization
	for pointer in pointers:
		pointer.global_position = Vector3.ZERO
	for i in surfaces_result.size():
		pointers[i].global_position = surfaces_result[i]
