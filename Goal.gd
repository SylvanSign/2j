tool
extends SGArea2D

export(Color) var color := Color('00507a')

func _draw() -> void:
	draw_circle(Vector2.ZERO, 35, color)
