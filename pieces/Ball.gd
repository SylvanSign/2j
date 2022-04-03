tool
extends StoppablePiece
class_name Ball

func _sync_children() -> void:
	center.sync_to_physics_engine()
