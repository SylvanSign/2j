extends Piece
class_name StoppablePiece

var stopped := false

func stop() -> void:
	stopped = true
	collision_layer = 0
	collision_mask = 0
	velocity.clear()

func _network_process(input: Dictionary) -> void:
	if not stopped:
		._network_process(input)

func _save_state() -> Dictionary:
	var state := ._save_state()
	state['stopped'] = stopped
	state['collision_layer'] = collision_layer
	state['collision_mask'] = collision_mask
	return state

func _load_state(state: Dictionary) -> void:
	stopped = state['stopped']
	collision_layer = state['collision_layer']
	collision_mask = state['collision_mask']
	._load_state(state)
