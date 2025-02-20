extends Node

@onready var skeleton_animator = $"../DEV_SkeletonAnimator"
@onready var move_database = $"../States/MovesData/MoveDatabase"
@onready var model = $".."

func _ready():
	#DEV_create_torso_bone_mask()
	#DEV_create_legs_bone_mask()
	#DEV_pin_ledge_animations()
	#DEV_pin_root("ledge_climb_up_legs", "ledge_climb_up_params", Vector3(0, 0.894, 0.026))
	#DEV_nail_z_coordinate("beam_fall_right_legs", "beam_fall_params", -0.062)
	pass


#func DEV_create_torso_bone_mask():
	#var torso_bone_list = get_torso_bones_indeces(%GeneralSkeleton)
	#var wrapper : SkeletonMask = SkeletonMask.new()
	#wrapper.bones = torso_bone_list
	#ResourceSaver.save(wrapper, "res://Player/SkeletonModifiers/" + "torso_bones.res")
#
#func DEV_create_legs_bone_mask():
	#var legs_bone_list = get_legs_bones_indeces(%GeneralSkeleton)
	#var wrapper : SkeletonMask = SkeletonMask.new()
	#wrapper.bones = legs_bone_list
	#ResourceSaver.save(wrapper, "res://Player/SkeletonModifiers/" + "legs_bones.res")
#
#
func get_torso_bones_indeces(skeleton : Skeleton3D) -> Array:
	return get_hierarchy_indexes(skeleton, skeleton.find_bone("Spine"))


func get_legs_bones_indeces(skeleton : Skeleton3D) -> Array:
	var right_leg_indeces = get_hierarchy_indexes(skeleton, skeleton.find_bone("RightUpperLeg"))
	var left_leg_indeces = get_hierarchy_indexes(skeleton, skeleton.find_bone("LeftUpperLeg"))
	var result = [0] # Hips
	result.append_array(right_leg_indeces)
	result.append_array(left_leg_indeces)
	return result


func get_hierarchy_indexes(skeleton : Skeleton3D, root_idx : int) -> Array:
	var indeсes = []
	for child_bone in skeleton.get_bone_children(root_idx):
		indeсes.append_array(get_hierarchy_indexes(skeleton, child_bone)) 
	indeсes.append(root_idx)
	indeсes.sort()
	return indeсes


#DEVELOPMENT LEAYER FUNCTIONAL, IT DOES MODIFY ASSETS, UNCOMMENT IF YOU KNOW WHAT YOU ARE DOING
#AND DID BACKUPS
#func DEV_nail_z_coordinate(animation_name : String, into_backend_animation : String, value : float):
	#var animation = skeleton_animator.get_animation(animation_name) as Animation
	#var backend_animation = move_database.get_animation(into_backend_animation) as Animation
	#var backend_track = backend_animation.find_track("MoveDatabase:root_position", Animation.TYPE_VALUE)
	#var hips_track = animation.find_track("%GeneralSkeleton:Hips", Animation.TYPE_POSITION_3D)
	#print(animation.track_get_key_count(hips_track))
	#for i : int in animation.track_get_key_count(hips_track):
		#var position = animation.track_get_key_value(hips_track, i)
		#var time = animation.track_get_key_time(hips_track, i)
		#backend_animation.track_insert_key(backend_track, time, position)
		#print(str(position) + " at " + str(time))
		#var position_without_z = position
		#position_without_z.z = value
		#animation.track_set_key_value(hips_track, i, position_without_z)
	#ResourceSaver.save(animation, "res://Assets/Ready Animations/" + animation_name + "_Z_PROJECTED.res")
	#ResourceSaver.save(backend_animation, "res://Player/Moves/BackendAnimations/" + into_backend_animation + "_WITH_ROOT.res")


#func DEV_pin_root(animation_name : String, into_backend_animation : String, value : Vector3):
	#var animation = skeleton_animator.get_animation(animation_name) as Animation
	#var backend_animation = move_database.get_animation(into_backend_animation) as Animation
	#var backend_track = backend_animation.find_track("MoveDatabase:root_position", Animation.TYPE_VALUE)
	#var hips_track = animation.find_track("%GeneralSkeleton:Hips", Animation.TYPE_POSITION_3D)
	#for i : int in animation.track_get_key_count(hips_track):
		#var position = animation.track_get_key_value(hips_track, i)
		#var time = animation.track_get_key_time(hips_track, i)
		#backend_animation.track_insert_key(backend_track, time, position)
		#print(str(position) + " at " + str(time))
		#animation.track_set_key_value(hips_track, i, value)
	#ResourceSaver.save(animation, "res://Assets/Ready Animations/" + animation_name + "_ROOT_PINNED.res")
	#ResourceSaver.save(backend_animation, "res://Player/Moves/BackendAnimations/" + into_backend_animation + "_WITH_ROOT.res")


#func DEV_pin_ledge_animations():
	#var left_animation = skeleton_animator.get_animation("ledge_left") as Animation
	#var right_animation = skeleton_animator.get_animation("ledge_right") as Animation
	#var backend_animation = move_database.get_animation("ledge_grab_params") as Animation
	#var left_backend_track = backend_animation.find_track("../LedgeGrab:left_root_pos", Animation.TYPE_VALUE)
	#var right_backend_track = backend_animation.find_track("../LedgeGrab:right_root_pos", Animation.TYPE_VALUE)
	#var left_hips_track = left_animation.find_track("%GeneralSkeleton:Hips", Animation.TYPE_POSITION_3D)
	#var right_hips_track = left_animation.find_track("%GeneralSkeleton:Hips", Animation.TYPE_POSITION_3D)
	#for i : int in left_animation.track_get_key_count(left_hips_track):
		#var position = left_animation.track_get_key_value(left_hips_track, i)
		#var time = left_animation.track_get_key_time(left_hips_track, i)
		#backend_animation.track_insert_key(left_backend_track, time, position)
		#print(str(position) + " at " + str(time))
		#var position_without_x = position
		#position_without_x.x = -0.003
		#left_animation.track_set_key_value(left_hips_track, i, position_without_x)
	#for i : int in right_animation.track_get_key_count(right_hips_track):
		#var position = right_animation.track_get_key_value(right_hips_track, i)
		#var time = right_animation.track_get_key_time(right_hips_track, i)
		#backend_animation.track_insert_key(right_backend_track, time, position)
		#print(str(position) + " at " + str(time))
		#var position_without_x = position
		#position_without_x.x = -0.003
		#right_animation.track_set_key_value(right_hips_track, i, position_without_x)
	#ResourceSaver.save(right_animation, "res://Assets/Ready Animations/ledge_right" + "_ROOT_PINNED.res")
	#ResourceSaver.save(left_animation, "res://Assets/Ready Animations/ledge_left" + "_ROOT_PINNED.res")
	#ResourceSaver.save(backend_animation, "res://Player/Moves/BackendAnimations/ledge_grab_params" + "_WITH_ROOT.res")















# ssdfesf
