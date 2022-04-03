tool
extends StoppablePiece
class_name Player

onready var magnet := $Magnet

const ACCELERATION := 65536 * 6
var input_prefix   := "player1_"

func _ready() -> void:
	speed    = 65536 * 16
	friction = 65536 * 2
	bouncy   = false

func _sync_children() -> void:
	center.sync_to_physics_engine()
	magnet.sync_to_physics_engine()


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

	for biscuit in magnet.get_overlapping_bodies():
		biscuit.attach(self)

	._network_process(input)

