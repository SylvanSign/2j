tool
extends SGArea2D
class_name Goal

signal goal # TODO use this somehow?

var players: Array
var other_goal: Goal

onready var label := $RenderLayer/Score
const radius := 65536 * 35
var score := 0 setget set_score
var just_scored := false

export(Color) var color := Color('00507a')

func _draw() -> void:
	draw_circle(Vector2.ZERO, SGFixed.to_float(radius), color)

func _process(delta: float) -> void:
	if Engine.editor_hint:
		update()

func _network_process(_input: Dictionary) -> void:
	var areas := get_overlapping_areas(false)
	if areas.size() > 0:
		goal(areas[0].get_parent() as StoppablePiece)

func set_score(new_score: int) -> void:
	score = new_score
	label.text = str(score)

func goal(piece: StoppablePiece) -> void:
	piece.yank_inside(fixed_position)
	piece.stop()
	if not just_scored and not other_goal.just_scored and (piece is Player or piece is Ball):
		score()
		emit_signal('goal')

func score() -> void:
	if not other_goal.just_scored:
		just_scored = true
		score += 1
		label.text = str(score)

func _save_state() -> Dictionary:
	return {
		score = score,
		just_scored = just_scored,
	}

func _load_state(state: Dictionary) -> void:
	set_score(state['score'])
	just_scored = state['just_scored']
