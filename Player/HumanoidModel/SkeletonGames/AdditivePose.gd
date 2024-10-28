extends SkeletonModifier3D
class_name AdditivePose


@export var pose : Animation


func _process_modification():
	var skeleton : Skeleton3D = get_skeleton()
	
	for track in pose.get_track_count():
		if pose.track_get_type(track) == Animation.TrackType.TYPE_ROTATION_3D:
			var bone_name : String = pose.track_get_path(track)
			bone_name = bone_name.replace("%GeneralSkeleton:", "")
			#print(bone_name)
			var bone = skeleton.find_bone(bone_name)
			var pose_rotation_q : Quaternion = pose.rotation_track_interpolate(track, 0)
			var bone_transform : Transform3D = skeleton.get_bone_global_pose(bone)
			skeleton.set_bone_pose_rotation(bone, pose_rotation_q)
