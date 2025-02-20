extends Node
class_name Move

var player : CharacterBody3D
#var base_animator : AnimationPlayer
#var animator : SplitBodyAnimator # or BodyPartsBlender
var animation_settings : AnimationPlayer
var skeleton : Skeleton3D
var resources : HumanoidResources
var combat : HumanoidCombat
var moves_data_repo : MovesDataRepository
var container : HumanoidStates
var area_awareness : AreaAwareness
var legs : Legs

var full_body_animator : SimpleAnimator
var legs_animator : SimpleAnimator
var torso_animator : SimpleAnimator

@export var move_name : String
@export var priority : int
@export var backend_animation : String
@export var tracking_angular_speed : float = 10
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# I can tolerate up to two _costs, 
# the moment I need a third one, I'll create a small ResourceCost class to pay them.
@export var stamina_cost : float = 0

@export_group("animation")
@export var animation : String
@export var anim_settings : String = "animator"
@export var settings_switch_time : float = 0.2
@export var animation_blend_time : float = 0.2

@export_group("input mapping")
@export var combos : Array[Combo]
@export var simple_mapping : Dictionary = {
	"idle" : "idle",
	"stop" : "idle",
	"move" : "run",
	"move_fast" : "sprint",
	"go_up" : "jump_run",
	"midair" : "midair",
	"beam" : "beam_walk"
}

var enter_state_time : float
var initial_position : Vector3
var frame_length = 0.016

var has_queued_move : bool = false
var queued_move : String = "nonexistent queued move, drop error please"

var has_forced_move : bool = false
var forced_move : String = "nonexistent forced move, drop error please"

var duration : float

#region Transition Logic
func check_relevance(input : InputPackage) -> String:
	if has_queued_move and transitions_to_queued():
		try_force_move(queued_move)
		has_queued_move = false
	
	if has_forced_move:
		has_forced_move = false
		return forced_move
	
	_map_input_actions(input)
	return default_lifecycle(input)


func best_input_that_can_be_paid(input : InputPackage) -> String:
	input.move_names.sort_custom(container.moves_priority_sort)
	for action in input.move_names:
		if resources.can_be_paid(container.moves[action]):
			if container.moves[action] == self:
				return "okay"
			else:
				return action
	return "throwing because for some reason input.actions doesn't contain even idle"  

# "default-default", works for animations that just linger
func default_lifecycle(input : InputPackage):
	if works_longer_than(duration):
		return best_input_that_can_be_paid(input)
	return "okay"


func _on_enter_state(input : InputPackage):
	initial_position = player.global_position
	resources.pay_resource_cost(self)
	mark_enter_state()
	on_enter_state(input)
	#if animation != "":
		#animator.update_body_animations()
	animate()


func animate():
	if anim_settings and animation:
		if animation_settings.current_animation == anim_settings:
			full_body_animator.play(animation, animation_blend_time)
		else:
			full_body_animator.play(animation, 0)
		animation_settings.play(anim_settings, settings_switch_time)


func on_enter_state(input : InputPackage):
	pass

func _on_exit_state():
	on_exit_state()

func on_exit_state():
	pass

func queue_move(new_queued_move : String):
	queued_move = new_queued_move
	has_queued_move = true

func try_queue_move(new_queued_move : String):
	if not has_queued_move:
		queued_move = new_queued_move
		has_queued_move = true
	elif container.moves[new_queued_move].priority > container.moves[queued_move].priority:
		queued_move = new_queued_move

func try_force_move(new_forced_move : String):
	if not has_forced_move:
		has_forced_move = true
		forced_move = new_forced_move
	elif container.moves[new_forced_move].priority > container.moves[forced_move].priority:
		forced_move = new_forced_move

func _map_input_actions(input : InputPackage):
	map_by_combos(input)
	map_custom_actions(input)
	map_simple_actions(input)
	#print(input.move_names)
	return input

func map_by_combos(input : InputPackage):
	for combo in combos:
		combo.map(input)

func map_simple_actions(input : InputPackage):
	for action in simple_mapping.keys():
		if input.input_actions.has(action):
			input.move_names.append(simple_mapping[action])
	#input.map("idle", "idle")
	#input.map("stop", "idle")
	#input.map("move", "run")
	#input.map("move_fast", "sprint")
	#input.map("go_up", "jump_run")
	#input.map("midair", "midair")
	#input.map("beam", "beam_walk")

func map_custom_actions(input : InputPackage):
	pass

#endregion

#region Update Logic
func _update(input : InputPackage, delta : float):
	if tracks_input_vector():
		process_input_vector(input, delta)
	update(input, delta)

func update(_input : InputPackage, _delta : float):
	pass

func process_input_vector(input : InputPackage, delta : float):
	var input_direction = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
	var face_direction = player.basis.z
	var angle = face_direction.signed_angle_to(input_direction, Vector3.UP)
	var new_z = player.basis.z.rotated(Vector3.UP, clamp(angle, -tracking_angular_speed * delta, tracking_angular_speed * delta))
	var new_x = -new_z.cross(Vector3.UP)
	player.basis = Basis(new_x, Vector3.UP, new_z).orthonormalized()
	#player.rotate_y(clamp(angle, -tracking_angular_speed * delta, tracking_angular_speed * delta))

func update_resources(delta : float):
	resources.update(delta)
#endregion

#region Time Measurement

func mark_enter_state():
	enter_state_time = Time.get_unix_time_from_system()

func get_progress() -> float:
	var now = Time.get_unix_time_from_system()
	return now - enter_state_time


func works_longer_than(time : float) -> bool:
	if get_progress() >= time:
		return true
	return false

func works_less_than(time : float) -> bool:
	if get_progress() < time: 
		return true
	return false

func works_between(start : float, finish : float) -> bool:
	var progress = get_progress()
	if progress >= start and progress <= finish:
		return true
	return false
#endregion

#region Backend Animation Getters
func transitions_to_queued() -> bool:
	return moves_data_repo.get_transitions_to_queued(backend_animation, get_progress())

#func accepts_queueing() -> bool:
	#return moves_data_repo.get_accepts_queueing(backend_animation, get_progress())

func tracks_input_vector() -> bool:
	return moves_data_repo.tracks_input_vector(backend_animation, get_progress())

func time_til_unlocking() -> float:
	if tracks_input_vector():
		return 0
	return moves_data_repo.time_til_next_controllable_frame(backend_animation, get_progress())

func is_vulnerable() -> bool:
	return moves_data_repo.get_vulnerable(backend_animation, get_progress())

func is_interruptable() -> bool:
	return moves_data_repo.get_interruptable(backend_animation, get_progress())

func is_parryable() -> bool:
	return moves_data_repo.get_parryable(backend_animation, get_progress())

func get_root_position_delta(delta_time : float) -> Vector3:
	return moves_data_repo.get_root_delta_pos(backend_animation, get_progress(), delta_time)

func right_weapon_hurts() -> bool:
	return moves_data_repo.get_right_weapon_hurts(backend_animation, get_progress())

func get_movement_mode():
	return moves_data_repo.get_movement_mode(backend_animation, get_progress())
#endregion

func form_hit_data(_weapon : Weapon) -> HitData:
	print("someone tries to get hit by default Move")
	return HitData.blank()


func react_on_hit(hit : HitData):
	if not is_vulnerable():
		print("hit is here, but still the roll")
	if is_vulnerable():
		resources.lose_health(hit.damage)
	if is_interruptable():
		# TODO rewrite for better effects processing, this scales badly
		if hit.effects.has("pushback") and hit.effects["pushback"]:
			area_awareness.last_pushback_vector = hit.effects["pushback_direction"]
			try_force_move("pushback")
		else:
			try_force_move("staggered")


func react_on_parry(_hit : HitData):
	try_force_move("parried")


func _init_move():
	for combo in combos:
		combo.parent_move = self
	init_move()

# here you are supposed to do "@ready but after tree is loaded" stuff
func init_move():
	pass
