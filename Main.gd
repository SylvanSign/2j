extends Node

const DummyNetworkAdaptor = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")
const LOG_FILE_DIRECTORY = 'user://detailed_logs'

const SCORE_TO_WIN := 9

export(bool) var logging_enabled: = false

onready var timer := $NetworkTimer
onready var rng := $NetworkRandomNumberGenerator

onready var main_menu := $Menu/MainMenu
onready var connection_panel := $Menu/ConnectionPanel
onready var host_field := $Menu/ConnectionPanel/GridContainer/HostField
onready var port_field := $Menu/ConnectionPanel/GridContainer/PortField
onready var message_label := $Menu/CenterContainer/MessageLabel
onready var sync_lost_label := $Menu/SyncLostLabel
onready var reset_button := $Menu/ResetButton
onready var center_line := $Board/Center/CenterColor

onready var top_player := $Pieces/TopPlayer
onready var bot_player := $Pieces/BotPlayer
onready var top_goal := $Board/TopGoal
onready var bot_goal := $Board/BotGoal
onready var ball := $Pieces/Ball
onready var left_biscuit := $Pieces/LeftBiscuit
onready var mid_biscuit := $Pieces/MidBiscuit
onready var right_biscuit := $Pieces/RightBiscuit

var just_scored = null

enum { TOP = 1, BOT = 2 }
enum { LEFT, RIGHT }

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	SyncManager.connect("sync_started", self, "_on_SyncManager_sync_started")
	SyncManager.connect("sync_stopped", self, "_on_SyncManager_sync_stopped")
	SyncManager.connect("sync_lost", self, "_on_SyncManager_sync_lost")
	SyncManager.connect("sync_regained", self, "_on_SyncManager_sync_regained")
	SyncManager.connect("sync_error", self, "_on_SyncManager_sync_error")

	if OS.has_feature("editor"):
		var args: = OS.get_cmdline_args()
		if args.size() == 1:
			match args[0]:
				'listen':
					_on_ServerButton_pressed()
				'join':
					_on_ClientButton_pressed()
			init_pieces([bot_player, top_player])
		else:
			init_pieces([bot_player])
			_on_LocalButton_pressed()

func init_pieces(players: Array) -> void:
	$Pieces/LeftBiscuit.players = players
	$Pieces/MidBiscuit.players = players
	$Pieces/RightBiscuit.players = players
	bot_goal.players = players
	var top_goal_players := players.duplicate()
	top_goal_players.invert()
	top_goal.players = top_goal_players
	bot_goal.other_goal = top_goal
	top_goal.other_goal = bot_goal

func reset_pieces(side: int) -> void:
	left_biscuit.reset($Spawns/Biscuits/LeftBiscuit.fixed_position)
	mid_biscuit.reset($Spawns/Biscuits/MidBiscuit.fixed_position)
	right_biscuit.reset($Spawns/Biscuits/RightBiscuit.fixed_position)

	var kickoff_side: int = rng.randi_range(LEFT, RIGHT)
	# handle online mode
	if is_instance_valid(top_player):
		match just_scored:
			TOP:
				top_player.reset($Spawns/Players/TopPlayerMid.fixed_position)
				match kickoff_side:
					LEFT:
						ball.reset($Spawns/Ball/BallBotLeft.fixed_position)
						bot_player.reset($Spawns/Players/BotPlayerLeft.fixed_position)
					RIGHT:
						ball.reset($Spawns/Ball/BallBotRight.fixed_position)
						bot_player.reset($Spawns/Players/BotPlayerRight.fixed_position)

			BOT:
				bot_player.reset($Spawns/Players/BotPlayerMid.fixed_position)
				match kickoff_side:
					LEFT:
						ball.reset($Spawns/Ball/BallTopLeft.fixed_position)
						top_player.reset($Spawns/Players/TopPlayerLeft.fixed_position)
					RIGHT:
						ball.reset($Spawns/Ball/BallTopRight.fixed_position)
						top_player.reset($Spawns/Players/TopPlayerRight.fixed_position)
	# handle singleplayer practice mode
	else:
		match kickoff_side:
			LEFT:
				ball.reset($Spawns/Ball/BallBotLeft.fixed_position)
				bot_player.reset($Spawns/Players/BotPlayerLeft.fixed_position)
			RIGHT:
				ball.reset($Spawns/Ball/BallBotRight.fixed_position)
				bot_player.reset($Spawns/Players/BotPlayerRight.fixed_position)
		bot_player.set_collision_mask_bit(1, false)

	top_goal.just_scored = false
	bot_goal.just_scored = false
	just_scored = null

remote func set_seed(rng_seed: int) -> void:
	rng.set_seed(rng_seed)

func _on_ServerButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(port_field.text), 1)
	get_tree().network_peer = peer
	main_menu.visible = false
	connection_panel.visible = false
	message_label.text = "Listening..."

func _on_ClientButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(host_field.text, int(port_field.text))
	get_tree().network_peer = peer
	main_menu.visible = false
	connection_panel.visible = false
	message_label.text = "Connecting..."

func _on_network_peer_connected(peer_id: int):
	message_label.text = "Connected!"
	SyncManager.add_peer(peer_id)

	bot_player.set_network_master(1)
	if get_tree().is_network_server():
		top_player.set_network_master(peer_id)
	else:
		top_player.set_network_master(get_tree().get_network_unique_id())

	if get_tree().is_network_server():
		message_label.text = "Starting..."
		rng.randomize()
		rpc('set_seed', rng.get_seed())
		# Give a little time to get ping data.
#		yield(get_tree().create_timer(2.0), "timeout")
		yield(get_tree().create_timer(2.0), "timeout") # TODO should be 2.0 sec, like line above
		SyncManager.start()

func _on_network_peer_disconnected(peer_id: int):
	message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)

func _on_server_disconnected() -> void:
	_on_network_peer_disconnected(1)

func _on_ResetButton_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = get_tree().network_peer
	if peer:
		peer.close_connection()
	get_tree().reload_current_scene()

func _on_SyncManager_sync_started() -> void:
	message_label.text = "Started!"

	if logging_enabled and not SyncReplay.active:
		print(logging_enabled)
		var dir = Directory.new()
		if not dir.dir_exists(LOG_FILE_DIRECTORY):
			dir.make_dir(LOG_FILE_DIRECTORY)

		var datetime = OS.get_datetime(true)
		var log_file_name = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			get_tree().get_network_unique_id(),
		]

		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name)

func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false

	var peer = get_tree().network_peer
	if peer:
		peer.close_connection()
	SyncManager.clear_peers()

func setup_match_for_replay(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
	main_menu.visible = false
	connection_panel.visible = false
	reset_button.visible = false

func _on_OnlineButton_pressed() -> void:
	connection_panel.popup_centered()
	SyncManager.reset_network_adaptor()

func _on_LocalButton_pressed() -> void:
	rng.randomize()
	bot_player.set_collision_mask_bit(1, false)
	center_line.visible = false
	top_player.queue_free()
	main_menu.visible = false
	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
	SyncManager.start()

func score_effects(side: int) -> void:
	just_scored = side
	timer.start()

func _on_TopGoal_goal() -> void:
	if not just_scored:
		score_effects(BOT)

func _on_BotGoal_goal() -> void:
	if not just_scored:
		score_effects(TOP)

func _on_TopPlayer_double_biscuit(player) -> void:
	if not just_scored:
		top_goal.score()
		score_effects(BOT)

func _on_BotPlayer_double_biscuit(player) -> void:
	if not just_scored:
		bot_goal.score()
		score_effects(TOP)

func _save_state() -> Dictionary:
	return {
		just_scored = just_scored,
		top_score = top_goal.score,
		bot_score = bot_goal.score,
	}

func _load_state(state: Dictionary) -> void:
	just_scored = state['just_scored']
	top_goal.set_score(state['top_score'])
	bot_goal.set_score(state['bot_score'])

func _on_NetworkTimer_timeout() -> void:
	if top_goal.score >= SCORE_TO_WIN:
		show_banner('BOT WINS!')
	elif bot_goal.score >= SCORE_TO_WIN:
		show_banner('TOP WINS!')
	else:
		reset_pieces(just_scored)

func show_banner(side: String) -> void:
	$GameOverCanvas/Banner/GameOverLabel.text = side + ' WINS!'
	$GameOverCanvas/Banner.visible = true

func hide_banner() -> void:
	$GameOverCanvas/Banner.visible = false
