extends SGKinematicBody2D

var input_prefix := "player1_"

var speed := 0.0

func _get_local_input() -> Dictionary:
	var input_vector = Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down")

	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = input_vector

	return input

#func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
#	var input = previous_input.duplicate()
#	return input

func _network_process(input: Dictionary) -> void:
	var input_vector = input.get("input_vector", Vector2.ZERO)
	if input_vector != Vector2.ZERO:
		if speed < 8.0:
			speed += 0.2
		position += input_vector * speed
	else:
		speed = 0.0

func _save_state() -> Dictionary:
	return {
		position = position,
		speed = speed,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']
	speed = state['speed']
