extends Move


func default_lifecycle(input : InputPackage):
	if works_longer_than(duration):
		return "ledge_grab"
	return "okay"
