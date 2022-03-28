tool
extends ColorRect

func _draw() -> void:
	arc(Vector2(0, 0), 0, 90)
	arc(Vector2(0, 880), 0, -90)
	arc(Vector2(680, 0), 90, 180)
	arc(Vector2(680, 880), -90, -180)

func arc(center: Vector2, start_angle: float, end_angle: float) -> void:
	draw_arc(center, 120, deg2rad(start_angle), deg2rad(end_angle), 10, Color.white, 10)
