tool
extends StoppablePiece
class_name Ball

onready var center := $Center

func _sync_children() -> void:
	center.sync_to_physics_engine()
