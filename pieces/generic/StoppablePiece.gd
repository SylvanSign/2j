extends Piece
class_name StoppablePiece

onready var center := $Center

var stopped := false
var fresh_state := {}

func _ready() -> void:
	fresh_state = {
		collision_layer = collision_layer,
		collision_mask = collision_mask,
		center_collision_layer = center.collision_layer,
		center_collision_mask = center.collision_mask,
	}

func stop() -> void:
	stopped = true
	collision_layer = 0
	collision_mask = 0
	center.collision_layer = 0
	center.collision_mask = 0
	velocity.clear()

func reset(fp: SGFixedVector2) -> void:
	velocity.clear()
	fixed_position.x = fp.x
	fixed_position.y = fp.y
	stopped = false
	collision_layer = fresh_state['collision_layer']
	collision_mask = fresh_state['collision_mask']
	center.collision_layer = fresh_state['center_collision_layer']
	center.collision_mask = fresh_state['center_collision_mask']
	sync_to_physics_engine()
	_sync_children()

func yank_inside(fp: SGFixedVector2) -> void:
	var direction := fixed_position.direction_to(fp)
	fixed_position.iadd(direction.mul(radius))

func _network_process(input: Dictionary) -> void:
	if not stopped:
		._network_process(input)

func _save_state() -> Dictionary:
	var state := ._save_state()
	state['stopped'] = stopped
	state['collision_layer'] = collision_layer
	state['collision_mask'] = collision_mask
	state['center_collision_layer'] = center.collision_layer
	state['center_collision_mask'] = center.collision_mask
	return state

func _load_state(state: Dictionary) -> void:
	stopped = state['stopped']
	collision_layer = state['collision_layer']
	collision_mask = state['collision_mask']
	center.collision_layer = state['center_collision_layer']
	center.collision_mask = state['center_collision_mask']
	._load_state(state)
