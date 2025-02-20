extends Combo
class_name PlainMap

@export var action : String
@export var move : String

@export var start : float = 0

func map(input : InputPackage):
	if input.input_actions.has(action) and parent_move.works_longer_than(start):
		input.move_names.append(move)
