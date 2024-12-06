extends Resource
class_name Combo


var move : Move
@export var triggered_move : String


func init():
	pass


func is_triggered(_input : InputPackage) -> bool:
	return false
