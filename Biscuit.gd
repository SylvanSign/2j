tool
extends SGKinematicBody2D

export(Color) var color := Color('eae2b7')

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10, color)
