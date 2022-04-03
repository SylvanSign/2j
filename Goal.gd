tool
extends SGFixedNode2D

signal goal # TODO use this somehow?

var players: Array

onready var label := $Score
onready var timer := $NetworkTimer
var score := 0
var goal_radius := 65536 * 35
var just_scored := false

export(Color) var color := Color('00507a')

func _draw() -> void:
	draw_circle(Vector2.ZERO, 35, color)

func _network_process(_input: Dictionary) -> void:
	if fixed_position.distance_to(players[0].fixed_position) <= goal_radius:
		goal()

func goal() -> void:
	if not just_scored:
		just_scored = true
		score += 1
		label.text = str(score)
		for player in players:
			player.stopped = true
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
	just_scored = false
	emit_signal('goal')
