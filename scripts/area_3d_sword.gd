extends Move

# redefine your new Move fields in the editor, set up 

func default_lifecycle(input : InputPackage):
	pass


func update(input : InputPackage, delta : float):
	pass


func on_enter_state():
	pass

func on_exit_state():
	pass



func _on_body_entered(body: Node3D) -> void:
	print("sword hit", body)
	pass # Replace with function body.
