tool
extends StoppablePiece

onready var field := $Field
var players: Array

const MAGNETIC_FIELD_ACCELERATION := 65536 * 4

var attached_to := ''
var offset := SGFixedVector2.new()

func _ready() -> void:
	speed          = 65536 * 16
	friction       = 65536 / 4
	bounce_loss    = 65536 / 1
	hit_multiplier = 65536 * 2

func _sync_children() -> void:
	field.sync_to_physics_engine()
	center.sync_to_physics_engine()

func _network_process(input: Dictionary) -> void:
	if not attached_to:
		for player in field.get_overlapping_bodies():
			var direction := fixed_position.direction_to(player.fixed_position)
			hit_me(direction.mul(MAGNETIC_FIELD_ACCELERATION))

		._network_process(input)

func _network_postprocess(input: Dictionary) -> void:
	if attached_to:
		fixed_position = get_node(attached_to).fixed_position.sub(offset)
		# no need to sync to physics engine here, as the biscuit is only visual at this point

func attach(body: Piece) -> void:
	attached_to = body.get_path()
	offset = body.fixed_position.sub(fixed_position)
	stop()
	stopped = false # to allow following player piece

func _save_state() -> Dictionary:
	var state := ._save_state()
	state['offset_x'] = offset.x
	state['offset_y'] = offset.y
	state['attached_to'] = attached_to
	return state

func _load_state(state: Dictionary) -> void:
	offset.x = state['offset_x']
	offset.y = state['offset_y']
	attached_to = state['attached_to']
	._load_state(state)
