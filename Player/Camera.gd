extends Node3D

@onready var player = $".."
@onready var player_camera = $PlayerCamera
var mouse_is_captured = true
@export var  MOUSE_SENSITIVITY = 0.001
@export var VERTICAL_ROTATION_LIMIT_UP = deg_to_rad(80)
@export var VERTICAL_ROTATION_LIMIT_DOWN = deg_to_rad(-80)


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	top_level = true


func _physics_process(delta: float) -> void:
	global_position = player.global_position


func _input(event):
	if event.is_action_released("mouse_mode_switch"):
		switch_mouse()
	
	if event is InputEventMouseMotion and mouse_is_captured:
		pass
		#var d_hor = event.relative.x
		#rotate_y(- d_hor / 1000)

	## ESC of 'ui_cancel' → cursor loslaten
	if event.is_action_released("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_is_captured = false

	## Linkermuisklik → cursor vastzetten
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !mouse_is_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	## Muisbeweging → alleen als cursor vast is
	if event is InputEventMouseMotion and mouse_is_captured:
		var delta_x = event.relative.x
		var delta_y = event.relative.y

		# Horizontale rotatie
		rotate_y(-delta_x * MOUSE_SENSITIVITY)

		# Verticale rotatie met beperking
		var new_x_rot = rotation.x - delta_y * MOUSE_SENSITIVITY
		new_x_rot = clamp(new_x_rot, VERTICAL_ROTATION_LIMIT_DOWN, VERTICAL_ROTATION_LIMIT_UP)
		rotation.x = new_x_rot

func switch_mouse():
	if mouse_is_captured:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_is_captured = not mouse_is_captured
