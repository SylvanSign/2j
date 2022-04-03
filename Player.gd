tool
extends Piece

onready var center := $Center

const ACCELERATION := 65536 * 6
var input_prefix   := "player1_"
var stopped        := false

func _ready() -> void:
	speed    = 65536 * 16
	friction = 65536 * 2
	bouncy   = false

func sync_to_physics_engine() -> void:
	.sync_to_physics_engine()
	center.sync_to_physics_engine()

func _get_local_input() -> Dictionary:
	if stopped:
		return {}

	var input_vector := Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down")

	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = SGFixed.from_float_vector2(input_vector)

	return input

func _network_process(input: Dictionary) -> void:
	var vector: SGFixedVector2 = input.get("input_vector", ZERO)
	velocity.iadd(vector.mul(ACCELERATION))
	if velocity.length() > speed:
		velocity = velocity.normalized().mul(speed)

	._network_process(input)

func _save_state() -> Dictionary:
	var state := ._save_state()
	state['stopped'] = stopped
	return state

func _load_state(state: Dictionary) -> void:
	stopped = state['stopped']
	._load_state(state)
