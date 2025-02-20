extends Resource
class_name InputPackage

var move_names : Array[String]
var input_actions : Array[String]

var input_direction : Vector2 


func map(action : String, move : String):
	if input_actions.has(action):
		move_names.append(move)


func combine(actions : Array[String], move):
	for action in actions:
		if not input_actions.has(action):
			return
	move_names.append(move)
