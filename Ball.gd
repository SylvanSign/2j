tool
extends SGKinematicBody2D

export(Color) var color

const EPSILON      := 65536 / 32
const SPEED        := 65536 * 12
const ACCELERATION := 65536 * 4
const FRICTION     := 65536 / 4

var ZERO     := SGFixedVector2.new()
var velocity := SGFixedVector2.new()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 15, color)

func _network_process(input: Dictionary) -> void:
	if velocity.length() > SPEED:
		velocity = velocity.normalized().mul(SPEED)

	if velocity.length() < EPSILON:
		velocity.clear()
	else:
		var friction_vector: SGFixedVector2 = velocity.direction_to(ZERO).mul(FRICTION)
		velocity.iadd(friction_vector)

	var collision := move_and_collide(velocity)
	if collision:
		print('I been hit!')

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
