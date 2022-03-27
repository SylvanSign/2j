tool
extends SGKinematicBody2D

const ONE          := 65536 * 1
const SPEED        := 65536 * 10
const ACCELERATION := 65536 * 3
const FRICTION     := 65536 / 8

var ZERO     := SGFixedVector2.new()
var velocity := SGFixedVector2.new()

var input_prefix := "player1_"
export(Color) var color

var speed := 0.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20, color)

func _get_local_input() -> Dictionary:
	var input_vector := Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down").normalized()

	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = SGFixed.from_float_vector2(input_vector)

	return input

#func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
#	var input = previous_input.duplicate()
#	return input

func _network_process(input: Dictionary) -> void:
	var vector: SGFixedVector2 = input.get("input_vector", ZERO)

	velocity.iadd(vector.mul(ACCELERATION))
	if velocity.length() > SPEED:
		velocity = velocity.normalized().mul(SPEED)

	if velocity.length() < ONE:
		velocity.clear()
	else:
		var friction_vector: SGFixedVector2 = velocity.direction_to(ZERO).mul(FRICTION)
		velocity.iadd(friction_vector)

	velocity = move_and_slide(velocity)

func _save_state() -> Dictionary:
	return {
		pos_x = fixed_position.x,
		pos_y = fixed_position.y,
		vel_x = velocity.x,
		vel_y = velocity.y,
	}

func _load_state(state: Dictionary) -> void:
	fixed_position.x = state['pos_x']
	fixed_position.y = state['pos_y']
	velocity.x = state['vel_x']
	velocity.y = state['vel_y']
	sync_to_physics_engine()
