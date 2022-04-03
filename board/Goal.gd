tool
extends SGArea2D

signal goal # TODO use this somehow?

var players: Array

onready var label := $RenderLayer/Score
onready var timer := $NetworkTimer
var score := 0
var goal_radius := 65536 * 35
var just_scored := false

export(Color) var color := Color('00507a')

func _draw() -> void:
	draw_circle(Vector2.ZERO, 35, color)

func _network_process(_input: Dictionary) -> void:
	var areas := get_overlapping_areas(false)
	if areas.size() > 0:
		goal(areas[0].get_parent() as StoppablePiece)

func goal(piece: StoppablePiece) -> void:
	piece.stop()
	if not just_scored and (piece is Player or piece is Ball):
		just_scored = true
		score += 1
		label.text = str(score)
		timer.start()

func _save_state() -> Dictionary:
	return {
		score = score,
		just_scored = just_scored,
	}

func _load_state(state: Dictionary) -> void:
	score = state['score']
	just_scored = state['just_scored']


func _on_NetworkTimer_timeout() -> void:
	emit_signal('goal')
