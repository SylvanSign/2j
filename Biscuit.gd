tool
extends Piece

onready var field := $Field
var players: Array

const PLAYER_SIZE                 := 65536 * 20
const MAGNETIC_FIELD_SIZE         := 65536 * 60
const MAGNETIC_FIELD_ACCELERATION := 65536 * 2

var attached_to := ''
var offset := SGFixedVector2.new()

func _ready() -> void:
	speed          = 65536 * 16
	friction       = 65536 / 4
	bounce_loss    = 65536 / 1
	hit_multiplier = 65536 * 1

func sync_to_physics_engine() -> void:
	.sync_to_physics_engine()
	field.sync_to_physics_engine()

func _network_process(input: Dictionary) -> void:
#	# TODO why doesn't this work deterministically, but the distance checking does?
#	var overlapping_bodies: Array = field.get_overlapping_bodies()
#	if overlapping_bodies.size() > 0:
#		print('foo')
#		var player := overlapping_bodies[0] as Piece
#		var direction_to := fixed_position.direction_to(player.fixed_position)
#		fixed_position.iadd(direction_to.mul(MAGNETIC_FIELD_ACCELERATION))
#		sync_to_physics_engine()

	if not attached_to:
		for player in players:
			var distance := fixed_position.distance_to(player.fixed_position)
			if distance <= PLAYER_SIZE:
				attached_to = player.get_path()
				offset = player.fixed_position.sub(fixed_position)
				collision_layer = 0
				collision_mask = 0
			elif distance <= MAGNETIC_FIELD_SIZE:
				var direction := fixed_position.direction_to(player.fixed_position)
				hit_me(direction.mul(MAGNETIC_FIELD_ACCELERATION))

		._network_process(input)
	else:
		fixed_position = (get_node(attached_to) as Piece).fixed_position.sub(offset)

func _save_state() -> Dictionary:
	var state := ._save_state()
	state['offset_x'] = offset.x
	state['offset_y'] = offset.y
	state['attached_to'] = attached_to
	state['collision_layer'] = collision_layer
	state['collision_mask'] = collision_mask
	return state

func _load_state(state: Dictionary) -> void:
	offset.x = state['offset_x']
	offset.y = state['offset_y']
	attached_to = state['attached_to']
	collision_layer = state['collision_layer']
	collision_mask = state['collision_mask']
	._load_state(state)
