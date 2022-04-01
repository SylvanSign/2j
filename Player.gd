tool
extends Piece

onready var center := $Center
onready var magnetic_field := $MagneticField

const ACCELERATION := 65536 * 6
var input_prefix   := "player1_"

func _ready() -> void:
	speed          = 65536 * 16
	friction       = 65536 * 2
	bouncy         = false

func sync_to_physics_engine() -> void:
	center.sync_to_physics_engine()
	magnetic_field.sync_to_physics_engine()
	.sync_to_physics_engine()

func _get_local_input() -> Dictionary:
	var input_vector := Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down").normalized()

	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = SGFixed.from_float_vector2(input_vector)

	print(input)
	return input

func _network_process(input: Dictionary) -> void:
	var vector: SGFixedVector2 = input.get("input_vector", ZERO)
	velocity.iadd(vector.mul(ACCELERATION))
	if velocity.length() > speed:
		velocity = velocity.normalized().mul(speed)

	._network_process(input)

	for body in magnetic_field.get_overlapping_bodies():
		print(body.name, ' entered magnetic field')
