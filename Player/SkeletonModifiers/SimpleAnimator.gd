extends SkeletonModifier3D
class_name SimpleAnimator

@export var animator : AnimationPlayer
@onready var skeleton = get_skeleton()

@export var white_list : SkeletonMask

var current_animation : Animation
var current_animation_cycling : bool = true
var current_animation_progress : float = 0 #seconds

var previous_animation : Animation
var previous_animation_cycling : bool = true
var previous_animation_progress : float = 0    #seconds

var is_blending : bool = false
var blend_duration : float      # seconds
var blend_time_spent : float    # seconds
var blending_percentage : float # [0 ; 1]

var last_processing_time : float = 0 # seconds unix from system
var delta : float = 0                # seconds
var now : float = 0                  # seconds unix from system

var bone_list
var curr_transform : Transform3D
var previous_transform : Transform3D

var pos_track : int
var rot_track : int

func _ready():
	current_animation = animator.get_animation("idle_longsword")
	current_animation_cycling = current_animation.loop_mode == Animation.LoopMode.LOOP_LINEAR
	current_animation_progress = 0
	previous_animation = animator.get_animation("idle_longsword")
	previous_animation_cycling = previous_animation.loop_mode == Animation.LoopMode.LOOP_LINEAR
	previous_animation_progress = 0


func play(next_animation : String, over_time : float = 0):
	if over_time < 0:
		push_error("can't blend two animations over " + str(over_time) + " baka")
	last_processing_time = Time.get_unix_time_from_system()
	previous_animation = current_animation
	previous_animation_cycling = current_animation_cycling
	previous_animation_progress = current_animation_progress
	current_animation = animator.get_animation(next_animation)
	current_animation_progress = 0
	current_animation_cycling = current_animation.loop_mode == Animation.LoopMode.LOOP_LINEAR
	if over_time > 0:
		is_blending = true
		blend_duration = over_time
		blend_time_spent = 0
		blending_percentage = 0


func _process_modification():
	update_time()
	update_blend_values()
#	DEV_echo_debug()
	update_skeleton()


func update_skeleton():
	if white_list: #this actually is an awful untyped variable abuse, dirty af TODO kys
		bone_list = white_list.bones
	else:
		bone_list = skeleton.get_bone_count()
	
	for bone in bone_list:
		curr_transform = calculate_bone_pose(bone, current_animation, current_animation_progress)
		if is_blending:
			previous_transform = calculate_bone_pose(bone, previous_animation, previous_animation_progress)
			skeleton.set_bone_pose(bone, previous_transform.interpolate_with(curr_transform, blending_percentage))
		else:
			skeleton.set_bone_pose(bone, curr_transform)


func update_time():
	now = Time.get_unix_time_from_system()
	delta = now - last_processing_time
	last_processing_time = now
	current_animation_progress += delta
	previous_animation_progress += delta
	if current_animation_progress > current_animation.length and current_animation_cycling:
		current_animation_progress = fmod(current_animation_progress, current_animation.length)
	if previous_animation_progress > previous_animation.length and previous_animation_cycling:
		previous_animation_progress = fmod(previous_animation_progress, previous_animation.length)


func update_blend_values():
	if is_blending:
		blend_time_spent += delta
		blending_percentage = blend_time_spent / blend_duration
		if blending_percentage >= 1:
			blending_percentage = 1
			blending_percentage = 0
			blend_time_spent = 0
			is_blending = false


func calculate_bone_pose(bone_idx : int, animation : Animation, progress : float) -> Transform3D:
	var resulting_transform : Transform3D
	
	pos_track = animation.find_track(bone_to_track_name(bone_idx), Animation.TYPE_POSITION_3D)
	if pos_track != -1:
		resulting_transform.origin = animation.position_track_interpolate(pos_track, progress)
	else:
		resulting_transform.origin = skeleton.get_bone_pose(bone_idx).origin
	
	rot_track = animation.find_track(bone_to_track_name(bone_idx), Animation.TYPE_ROTATION_3D)
	if rot_track != -1:
		resulting_transform.basis = Basis(animation.rotation_track_interpolate(rot_track, progress))
	else:
		resulting_transform.basis = skeleton.get_bone_pose(bone_idx).basis
	
	return resulting_transform


func bone_to_track_name(bone_index : int) -> String:
	return "%GeneralSkeleton:" + skeleton.get_bone_name(bone_index)


#func DEV_echo_debug():
	#print(name + " " + str(influence))
