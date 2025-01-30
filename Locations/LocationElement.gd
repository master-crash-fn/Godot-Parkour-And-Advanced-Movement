extends StaticBody3D
class_name LocationElement

#var visual_mesh : MeshInstance3D
@export var collision_mesh : MeshInstance3D
@export var collision_shape : CollisionShape3D

# This is a cringe step of returning back to integer ids we had to take,
# because to "ask" an element we need to ask it by an edge, probably.
# But player knows global transform of a ledge, and element operates in local.
# And the /= transform operation has float precision errors, making element 
# not recognising (1, 2, 0.999999) vector as (1, 2, 1),
# and a simple rounding up as with normals won't work here for complex figures.
# TIHI
# throws on interaction with ledges predefined in the model "by hands" TODO critical
@export var id_by_edge : Dictionary # {PackedVector3Array : int}
@export var edge_by_id : Dictionary
# tuple of vectors : tuple of vectors
# first one is edge set up as two vertices
# second one is two normals to two faces of that edge
# being a dictionary also guarantees as that edges are unique
@export var edges_angles : Dictionary # {PackedVector3Array : PackedVector3Array}
# "left" are neighbours by the [0] vertex, and "right" are by [1] one
@export var left_neighbours : Dictionary # {PackedVector3Array : PackedVector3Array}
@export var right_neighbours : Dictionary # {PackedVector3Array : PackedVector3Array}
@export var static_ledges : PackedVector3Array 
# face's normal : array of points for edges, starts are i = 2*k, ends are i = 2*k+1
@export var faces_data : Dictionary# {Vector3 : PackedVector3Array}

# idea for overoptimisation, on ready we can go even further and bake the edges that are currently climbable,
# by recalculating it in advance adjusting to the current transform.
# but it will take more of loading times I believe, than it will add benefits, so meh
#@export var currently_climbable_edges : Dictionary # {Vector3 : PackedVector3Array} 

var dot_hor : float
var dot_ver : float

#func _ready():
	#bake_currently_climbable_edges()
	#pass


func bake_edge_data(data : MeshDataTool):
	var edge_id = 1
	# init map by remembering deduplicated edges as keys
	for i in data.get_edge_count():
		var vertex_1 : Vector3 = data.get_vertex(data.get_edge_vertex(i, 0))
		var vertex_2 : Vector3 = data.get_vertex(data.get_edge_vertex(i, 1))
		var as_edge = PackedVector3Array([vertex_1, vertex_2])
		edges_angles[as_edge] = PackedVector3Array()
		id_by_edge[as_edge] = edge_id
		edge_by_id[edge_id] = as_edge
		edge_id += 1
	
	# search for those edges again, but this time setting useful calues
	for edge in edges_angles.keys():
		for i in data.get_edge_count():
			var vertex_1 : Vector3 = data.get_vertex(data.get_edge_vertex(i, 0))
			var vertex_2 : Vector3 = data.get_vertex(data.get_edge_vertex(i, 1))
			if edge == PackedVector3Array([vertex_1, vertex_2]):
				for n in data.get_edge_faces(i):
					edges_angles[edge].append(data.get_face_normal(n))
	
	# print the resulting data
	#print("------- " + name + " edges:faces")
	#for edge in edges_angles:
		#print(str(edge) + " : " + str(edges_angles[edge]))


func bake_faces_data(data : MeshDataTool):
	for f in data.get_face_count():
		var normal : Vector3 = data.get_face_normal(f).snappedf(0.01)
		if not faces_data.has(normal):
			faces_data[normal] = PackedVector3Array()
		for e in 3:
			var vertex_1 : Vector3 = data.get_vertex(data.get_edge_vertex(data.get_face_edge(f, e), 0))
			var vertex_2 : Vector3 = data.get_vertex(data.get_edge_vertex(data.get_face_edge(f, e), 1))
			
			# if this edge's two faces have one normal, ie this is the edge that triangulates one face
			var edge = PackedVector3Array([vertex_1, vertex_2])
			var triangulation_edge : bool = edges_angles[edge].size() > 1 and edges_angles[edge][0] == edges_angles[edge][1]
			
			if not triangulation_edge:
				faces_data[normal].append(vertex_1)
				faces_data[normal].append(vertex_2)
	#
	#print("------- " + name + " faces:edges")
	#for n in faces_data:
		#print(str(n) + " : " + str(faces_data[n].size() / 2) )# + " : "  + str(faces_data[normal]))


#func bake_currently_climbable_edges():
	#pass

func bake_neighbour_climbable_edges():
	for edge in edges_angles.keys():
		if is_triangulation_edge(edge[0], edge[1]):
			continue
			
		# search for "left" neighbours
		if not left_neighbours.has(edge):
			left_neighbours[edge] = PackedVector3Array()
		var neighbours : PackedVector3Array = PackedVector3Array()
		for other_edge in edges_angles:
			# we have one vertex, but not the other one, i.e. we are "neighbours" by that vertex
			if other_edge.has(edge[0]) and not other_edge == edge and not is_triangulation_edge(other_edge[0], other_edge[1]):
				neighbours.append_array(other_edge)
		print(str(edge) + " left neighbours " + str(neighbours))
		left_neighbours[edge].append_array(neighbours)
		
		# search for "right" neighbours
		if not right_neighbours.has(edge):
			right_neighbours[edge] = PackedVector3Array()
		neighbours.clear()
		for other_edge in edges_angles:
			# we have one vertex, but not the other one, i.e. we are "neighbours" by that vertex
			if other_edge.has(edge[1]) and not other_edge == edge and not is_triangulation_edge(other_edge[0], other_edge[1]):
				neighbours.append_array(other_edge)
		print(str(edge) + " right neighbours " + str(neighbours))
		right_neighbours[edge].append_array(neighbours)
		print("------------------------------------")
	pass


func has_climbable_edge(normal : Vector3, plane_1 : Vector3, plane_2 : Vector3, plane_3 : Vector3) -> PackedVector3Array:
	plane_1 = global_transform.inverse() * plane_1
	plane_2 = global_transform.inverse() * plane_2
	plane_3 = global_transform.inverse() * plane_3
	
	for e in range(0, static_ledges.size(), 2):
		var intersection = edge_intersects_rectangle(plane_1, plane_2, plane_3, static_ledges[e], static_ledges[e+1])
		if not intersection == Vector3(-21515351, -21515351, -21515351):
			return PackedVector3Array([global_transform * static_ledges[e], global_transform * static_ledges[e+1], global_transform * intersection])
	
	normal = (global_basis.inverse() * normal).snappedf(0.01)
	
	var edges = faces_data.get(normal)
	#print(edges.size())
	if edges:
		for e in range(0, edges.size(), 2):
			if is_climbable_edge(edges[e], edges[e+1]):
				var intersection = edge_intersects_rectangle(plane_1, plane_2, plane_3, edges[e], edges[e+1])
				if not intersection == Vector3(-21515351, -21515351, -21515351):
					# Demonstration of fuck you by transforms  TODO delete
					var edge_temp = edges[e]
					prints("local to global edge: ", edge_temp, " > ", global_transform * edge_temp)
					edge_temp = global_transform * edge_temp
					edge_temp = global_transform.inverse() * edge_temp
					prints("global back to local: ", global_transform * edge_temp, " > ", edge_temp)
					
					return PackedVector3Array([ global_transform * edges[e], global_transform * edges[e+1], global_transform * intersection, Vector3(id_by_edge[PackedVector3Array([edges[e], edges[e+1]])], 0, 0) ])
	
	return PackedVector3Array()


func is_triangulation_edge(v_1 : Vector3, v_2 : Vector3) -> bool:
	var normals =  edges_angles.get(PackedVector3Array([v_1, v_2]))
	if normals.size() > 1:
		var normal_1 = normals[0]
		var normal_2 = normals[1]
		#print(str(normal_1) + " " + str(normal_2))
		return normal_1.is_equal_approx(normal_2)
	return false

func is_climbable_edge(v_1 : Vector3, v_2 : Vector3) -> bool:
	var normals =  edges_angles.get(PackedVector3Array([v_1, v_2]))
	if normals.size() > 1:
		var normal_1 = global_basis * normals[0]
		var normal_2 = global_basis * normals[1]
		#print(str(normal_1) + " " + str(normal_2))
		return is_step_pattern(normal_1, normal_2)
	return false

# we search for the case when one normal is almost vertical up,
# and other normal is almost horizontal
func is_step_pattern(normal_1 : Vector3, normal_2 : Vector3) -> bool:
	return (normal_1.angle_to(Vector3.UP) < 0.3 and sin(normal_2.angle_to(Vector3.UP)) > sqrt(3)/2) or (normal_2.angle_to(Vector3.UP) < 0.3 and sin(normal_1.angle_to(Vector3.UP)) > sqrt(3)/2)


func has_thin_edge(normal : Vector3, plane_1 : Vector3, plane_2 : Vector3, plane_3 : Vector3) -> PackedVector3Array:
	plane_1 = global_transform.inverse() * plane_1
	plane_2 = global_transform.inverse() * plane_2
	plane_3 = global_transform.inverse() * plane_3
	
	#for e in range(0, static_ledges.size(), 2):
		#var intersection = edge_intersects_rectangle(plane_1, plane_2, plane_3, static_ledges[e], static_ledges[e+1])
		#if not intersection == Vector3(-21515351, -21515351, -21515351):
			#return PackedVector3Array([global_transform * static_ledges[e], global_transform * static_ledges[e+1], global_transform * intersection])
	
	normal = (global_basis.inverse() * normal).snappedf(0.01)
	
	var edges = faces_data.get(normal)
	#print(edges.size())
	if edges:
		for e in range(0, edges.size(), 2):
			if is_thin_walkable_edge(edges[e], edges[e+1]):
				var intersection = edge_intersects_rectangle(plane_1, plane_2, plane_3, edges[e], edges[e+1])
				if not intersection == Vector3(-21515351, -21515351, -21515351):
					return PackedVector3Array([global_transform * edges[e], global_transform * edges[e+1], global_transform * intersection])
	
	return PackedVector3Array()

func is_thin_walkable_edge(v_1 : Vector3, v_2 : Vector3) -> bool:
	var normals =  edges_angles.get(PackedVector3Array([v_1, v_2]))
	if normals.size() > 1:
		var normal_1 : Vector3 = global_basis * normals[0]
		var normal_2 : Vector3 = global_basis * normals[1]
		#print(str(normal_1) + " " + str(normal_2))
		return (normal_1 + normal_2).angle_to(Vector3.UP) < 0.2 and normal_1.angle_to(normal_2) > PI/2
	return false

func edge_intersects_rectangle(plane_1 : Vector3, plane_2 : Vector3, plane_3 : Vector3, edge_1 : Vector3, edge_2 : Vector3) -> Vector3:
	var slice_plane = Plane(plane_1, plane_2, plane_3)
	var intersection = slice_plane.intersects_segment(edge_1, edge_2)
	if intersection:
		dot_ver = (intersection - plane_1).dot(plane_2 - plane_1)
		dot_hor = (intersection - plane_2).dot(plane_3 - plane_2)
		# if intersection point lays inside the slice rectangle
		if 0 <= dot_ver and dot_ver <= (plane_2 - plane_1).length_squared() and 0 <= dot_hor and dot_hor <= (plane_3 - plane_2).length_squared():
			return intersection
	return Vector3(-21515351, -21515351, -21515351) # cringe but wcyd

func has_climbable_left_neighbour(id : int) -> bool:
	var edge = edge_by_id[id]
	var neighbours = left_neighbours[edge]
	for n in range(0, neighbours.size(), 2):
		if is_climbable_edge(neighbours[n], neighbours[n+1]):
			return true
	return false

func has_climbable_right_neighbour(id : int) -> bool:
	var edge = edge_by_id[id]
	var neighbours = right_neighbours[edge]
	for n in range(0, neighbours.size(), 2):
		if is_climbable_edge(neighbours[n], neighbours[n+1]):
			return true
	return false

func get_next_climbable_neighbour(id : int, side : int) -> PackedVector3Array:
	var edge = edge_by_id[id]
	var neighbours
	if side == 0:
		neighbours = left_neighbours[edge]
		for n in range(0, neighbours.size(), 2):
			if is_climbable_edge(neighbours[n], neighbours[n+1]):
				return PackedVector3Array([global_transform * neighbours[n], global_transform * neighbours[n+1], Vector3(id_by_edge[PackedVector3Array([neighbours[n], neighbours[n+1]])], 0, 0)])
	elif side == 1:
		neighbours = right_neighbours[edge]
		for n in range(0, neighbours.size(), 2):
			if is_climbable_edge(neighbours[n], neighbours[n+1]):
				return PackedVector3Array([global_transform * neighbours[n], global_transform * neighbours[n+1], Vector3(id_by_edge[PackedVector3Array([neighbours[n], neighbours[n+1]])], 0, 0)])
	return PackedVector3Array()





# sdfsdf
