tool
extends SGKinematicBody2D
class_name Piece

export(Color) var color: Color
export(int)   var radius := 65536 * 1

const NUM_SLIDES     := 4
const EPSILON        := 65536 / 1
var   ZERO           := SGFixedVector2.new() # fixed analog to Vector2.ZERO
var   speed          := 65536 * 24
var   friction       := 65536 / 8
var   bouncy         := true
var   bounce_loss    := 65536 * 1
var   hit_multiplier := 65536 * 2
var   velocity := SGFixedVector2.new()

func _draw() -> void:
	draw_circle(Vector2.ZERO, SGFixed.to_float(radius), color)

func hit_me(hit_velocity: SGFixedVector2) -> void:
	velocity.iadd(hit_velocity.mul(hit_multiplier))
	if velocity.length() > speed:
		velocity = velocity.normalized().mul(speed)

func _network_process(_input: Dictionary) -> void:
	var friction_vector: SGFixedVector2 = velocity.direction_to(ZERO).mul(friction)
	velocity.iadd(friction_vector)
	# stop if our velocity is small enough
	# this is a workaround because SGFixedVector2 doesn't have move_toward 0
	if velocity.length() < EPSILON:
		velocity.clear()

	var collision: SGKinematicCollision2D
	for _i in range(NUM_SLIDES):
		collision = move_and_collide(velocity)

		if not collision:
			break

		# possibly bounce the other object
		var hit_name: String = collision.collider.name
		if not (hit_name == 'Walls' or hit_name == 'Center'):
			collision.collider.hit_me(velocity.reflect(collision.normal.normalized()))

		if bouncy:
			# bounce self
			velocity = velocity.bounce(collision.normal)
			var bounce_loss_vector := velocity.direction_to(ZERO).mul(bounce_loss)
			velocity.iadd(bounce_loss_vector)
		else:
			velocity = collision.remainder.slide(collision.normal.normalized())

	_sync_children()

# child classes should override this if needed
func _sync_children() -> void:
	pass

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
	_sync_children()
