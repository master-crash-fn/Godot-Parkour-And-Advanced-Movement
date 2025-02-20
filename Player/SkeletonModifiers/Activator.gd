extends SkeletonModifier3D
class_name SkeletonModifierMeta


# because we manage our modifiers via influence manipulations, we often have active ones with 0 influence
# to not waste our computation power on them, the first "meta modifier" deactivates 0-influenced ones
# and activates non-zero modifiers.
# This works because if this modifier is the first before all, it triggers first, 
# but also triggers after "purple" nodes, ie after we set all influences for the frame.
func _process_modification():
	for child in get_skeleton().get_children():
		if child is SkeletonModifier3D:
			if child.influence == 0:
				child.active = false
			else:
				child.active = true
