tool
extends ColorRect

func _draw() -> void:
	arc(Vector2(0, 0), 0, 90)
	arc(Vector2(0, 880), 0, -90)
	arc(Vector2(660, 0), 180, 90)
	arc(Vector2(660, 880), -180, -90)

func arc(center: Vector2, start_angle: float, end_angle: float) -> void:
	draw_arc(center, 120, deg2rad(start_angle), deg2rad(end_angle), 10, Color.white, 10)
