@tool
extends EditorScenePostImport


func _post_import(scene):
	var new_location_element : LocationElement = LocationElement.new()
	scene.replace_by(new_location_element)
	#print(new_location_element.get_children())
	var collider_mesh = new_location_element.find_child("*-colmesh") as MeshInstance3D
	collider_mesh.name = collider_mesh.name.replace("-colmesh", "")
	new_location_element.collision_mesh = collider_mesh
	collider_mesh.visible = false
	
	var collider : CollisionShape3D = CollisionShape3D.new()
	collider.shape = collider_mesh.mesh.create_trimesh_shape()
	collider.name = "collider"
	new_location_element.add_child(collider)
	collider.set_owner(new_location_element)
	new_location_element.collision_shape = collider
	
	var collision_mesh_data : MeshDataTool = MeshDataTool.new()
	collision_mesh_data.create_from_surface(collider_mesh.mesh, 0)
	new_location_element.bake_edge_data(collision_mesh_data)
	new_location_element.bake_faces_data(collision_mesh_data)
	new_location_element.bake_neighbour_climbable_edges()
	
	new_location_element.collision_layer = 3 # i.e. 1 and 2 as 2^0+2^1, it's a bitmask, not an int
	
	var marked_ledges : Array[Node] = new_location_element.find_children("*-ledge", "MeshInstance3D")
	if not marked_ledges.is_empty():
		new_location_element.static_ledges = PackedVector3Array()
		for ledge in marked_ledges:
			# this dark magic works only because we have the guarantee that this ledge is a line
			# the returned array are points without repeats, so we parse edges as 0-1;1-2;2-3...
			# we are forced into this bullshit because MeshDataTool refuses to work with face-less meshes,
			# but we want specifically a faceless mesh because we export a series of edges
			var line : Array = ledge.mesh.surface_get_arrays(0)[0]
			for e in line.size() - 1:
				new_location_element.static_ledges.append(line[e])
				new_location_element.static_ledges.append(line[e+1])
			print("static marked ledge:" + str(new_location_element.static_ledges))
			new_location_element.remove_child(ledge)
		print("have some static ledges")
	
	return new_location_element 
