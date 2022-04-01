tool
extends Piece

func _ready() -> void:
	speed          = 65536 * 16
	friction       = 65536 / 4
	bounce_loss    = 0
	hit_multiplier = 65536 * 8
