extends Combo
class_name Combine

@export var actions : Array[String] = ["action1", "action2"]
@export var move : String

@export var start : float = 0

func map(input : InputPackage):
	if parent_move.works_longer_than(start):
		for action in actions:
			if not input.input_actions.has(action):
				return
		input.move_names.append(move)
