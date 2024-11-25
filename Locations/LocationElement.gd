extends StaticBody3D
class_name LocationElement

#var visual_mesh : MeshInstance3D
var collision_mesh : MeshInstance3D
var collision_shape : CollisionShape3D

# tuple of vectors : tuple of vectors
# first one is edge set up as two vertices
# second one is two normals to two faces of that edge
# being a dictionary also guarantees as that edges are unique
@export var edges_angles : Dictionary # {PackedVector3Array : PackedVector3Array}
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
	# init map by remembering deduplicated edges as keys
	for i in data.get_edge_count():
		var vertex_1 : Vector3 = data.get_vertex(data.get_edge_vertex(i, 0))
		var vertex_2 : Vector3 = data.get_vertex(data.get_edge_vertex(i, 1))
		var as_edge = PackedVector3Array([vertex_1, vertex_2])
		edges_angles[as_edge] = PackedVector3Array()
	
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

# TODO plane intersections can probably use a refactoring
func has_climbable_edge(normal : Vector3, plane_1 : Vector3, plane_2 : Vector3, plane_3 : Vector3) -> PackedVector3Array:
	plane_1 = global_transform.inverse() * plane_1
	plane_2 = global_transform.inverse() * plane_2
	plane_3 = global_transform.inverse() * plane_3
	var slice_plane = Plane(plane_1, plane_2, plane_3)
	
	for e in range(0, static_ledges.size(), 2):
		var intersection = slice_plane.intersects_segment(static_ledges[e], static_ledges[e+1])
		if intersection:
			dot_ver = (intersection - plane_1).dot(plane_2 - plane_1)
			dot_hor = (intersection - plane_2).dot(plane_3 - plane_2)
			# if intersection point lays inside the slice rectangle
			if 0 <= dot_ver and dot_ver <= (plane_2 - plane_1).length_squared() and 0 <= dot_hor and dot_hor <= (plane_3 - plane_2).length_squared():
				return PackedVector3Array([static_ledges[e], static_ledges[e+1], intersection])
	
	normal = (global_basis.inverse() * normal).snappedf(0.01)
	
	var edges = faces_data.get(normal)
	#print(edges.size())
	if edges:
		for e in range(0, edges.size(), 2):
			if is_climbable_edge(edges[e], edges[e+1]):
				var intersection = slice_plane.intersects_segment(edges[e], edges[e+1])
				if intersection:
					dot_ver = (intersection - plane_1).dot(plane_2 - plane_1)
					dot_hor = (intersection - plane_2).dot(plane_3 - plane_2)
					# if intersection point lays inside the slice rectangle
					if 0 <= dot_ver and dot_ver <= (plane_2 - plane_1).length_squared() and 0 <= dot_hor and dot_hor <= (plane_3 - plane_2).length_squared():
						return PackedVector3Array([edges[e], edges[e+1], intersection])
	return PackedVector3Array()


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






# sdfsdf
