extends Move

@export var SPEED = 3.0
@export var VERTICAL_SPEED_ADDED : float = 2.5

const TRANSITION_TIMING = 0.44  
const JUMP_TIMING = 0.1

var jumped : bool = false


func default_lifecycle(_input : InputPackage):
	if works_longer_than(TRANSITION_TIMING):
		jumped = false
		return "midair"
	else: 
		return "okay"


func update(_input : InputPackage, _delta ):
	process_jump()
	player.move_and_slide()


func process_jump():
	if works_longer_than(JUMP_TIMING):
		if not jumped:
			player.velocity = player.basis.z * SPEED 
			player.velocity.y += VERTICAL_SPEED_ADDED
			jumped = true


func on_enter_state():
	# Prevent jumping if not on floor (e.g., when walking up ramps)
	# This is a safety check - the main prevention is in Move.best_input_that_can_be_paid()
	if not area_awareness.is_on_floor():
		# Don't set velocity, which will cause issues, but the state switch already happened
		# The best_input_that_can_be_paid() fix should prevent this from being reached
		return
	player.velocity = player.velocity.normalized() * SPEED 
