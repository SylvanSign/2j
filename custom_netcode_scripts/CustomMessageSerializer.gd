extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

const input_path_mapping := {
	'/root/Main/Pieces/BotPlayer': 1,
	'/root/Main/Pieces/TopPlayer': 2,
}

enum HeaderFlags {
	HAS_INPUT_VECTOR = 1 << 0, # Bit 0
}

var input_path_mapping_reverse := {}

func _init() -> void:
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key

func serialize_input(all_input: Dictionary) -> PoolByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(16)

	buffer.put_u32(all_input['$'])
	buffer.put_u8(all_input.size() - 1)
	for path in all_input:
		if path == '$':
			continue
		buffer.put_u8(input_path_mapping[path])

		var header := 0

		var input = all_input[path]
		if input.has('input_vector'):
			header |= HeaderFlags.HAS_INPUT_VECTOR

		buffer.put_u8(header)

		if input.has('input_vector'):
			var input_vector: SGFixedVector2 = input['input_vector']
			buffer.put_64(input_vector.x)
			buffer.put_64(input_vector.y)

	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PoolByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)

	var all_input := {}

	all_input['$'] = buffer.get_u32()

	var input_count = buffer.get_u8()
	for i in input_count:
		var path: String = input_path_mapping_reverse[buffer.get_u8()]
		var input: = {}

		var header = buffer.get_u8()
		if header & HeaderFlags.HAS_INPUT_VECTOR:
			input["input_vector"] = SGFixed.vector2(buffer.get_64(), buffer.get_64())

		all_input[path] = input

	return all_input
