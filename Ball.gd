tool
extends SGKinematicBody2D

export(Color) var color

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20, color)
