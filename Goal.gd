tool
extends SGArea2D

signal glask(player)

export(Color) var color := Color('00507a')

func _draw() -> void:
	draw_circle(Vector2.ZERO, 35, color)

func _physics_process(delta: float) -> void:
	for area in get_overlapping_areas():
		emit_signal('glask', area.name)
