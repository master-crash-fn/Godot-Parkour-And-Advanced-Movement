extends Node


var scary_target : Node3D

@export var min_distance = 4
@export var max_distance = 10
@export var min_influence = 0
@export var max_influence = 0.6

@export var pose_modifier : SkeletonModifier3D

func _physics_process(delta):
	scary_target = get_tree().get_nodes_in_group("scary_target")[0]
	
	var distance_to_target = $"..".global_position.distance_to(scary_target.global_position)
	var distance_clamped = clamp(distance_to_target, min_distance, max_distance)
	var percentage = 1 - (distance_clamped - min_distance) / (max_distance - min_distance)
	pose_modifier.influence = min_influence + (max_influence - min_influence) * percentage
	
	
	
