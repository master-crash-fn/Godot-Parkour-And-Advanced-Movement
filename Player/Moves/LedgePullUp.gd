extends Move

@export var root_motion_donor : Animation

func update(_input : InputPackage, delta):
	move_player(delta)

# this is extremely fucked, everything about this approach is wrong, but we'll have a better system soon anyways
func move_player(delta : float):
	var track = root_motion_donor.find_track("%GeneralSkeleton:Ctrl_Master", Animation.TrackType.TYPE_POSITION_3D)
	root_motion_donor.position_track_interpolate(track, get_progress())
	var delta_pos = root_motion_donor.position_track_interpolate(track, get_progress()) - root_motion_donor.position_track_interpolate(track, clamp(get_progress() - delta, 0, 1))
	delta_pos += Vector3(0, 0.550, 0) * delta / 1.15
	print(get_progress() - delta)
	var velocity = player.get_quaternion() * delta_pos
	player.global_position -= velocity
