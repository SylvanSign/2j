extends Node

const DummyNetworkAdaptor = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")
const LOG_FILE_DIRECTORY = 'user://detailed_logs'

const SCORE_TO_WIN := 1

export(bool) var logging_enabled: = false

onready var timer := $NetworkTimer
onready var rng := $NetworkRandomNumberGenerator
onready var banner := $GameOverCanvas/Banner

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

var online := true
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

func setup_bot_kickoff(kickoff_side: int) -> void:
	match kickoff_side:
		LEFT:
			ball.reset($Spawns/Ball/BallBotLeft.fixed_position)
			bot_player.reset($Spawns/Players/BotPlayerLeft.fixed_position)
		RIGHT:
			ball.reset($Spawns/Ball/BallBotRight.fixed_position)
			bot_player.reset($Spawns/Players/BotPlayerRight.fixed_position)

func setup_top_kickoff(kickoff_side: int) -> void:
	match kickoff_side:
		LEFT:
			ball.reset($Spawns/Ball/BallTopLeft.fixed_position)
			top_player.reset($Spawns/Players/TopPlayerLeft.fixed_position)
		RIGHT:
			ball.reset($Spawns/Ball/BallTopRight.fixed_position)
			top_player.reset($Spawns/Players/TopPlayerRight.fixed_position)

func reset_pieces(half: int) -> void:
	left_biscuit.reset($Spawns/Biscuits/LeftBiscuit.fixed_position)
	mid_biscuit.reset($Spawns/Biscuits/MidBiscuit.fixed_position)
	right_biscuit.reset($Spawns/Biscuits/RightBiscuit.fixed_position)

	var kickoff_side: int = rng.randi_range(LEFT, RIGHT)
	if online:
		match half:
			TOP:
				top_player.reset($Spawns/Players/TopPlayerMid.fixed_position)
				setup_bot_kickoff(kickoff_side)
			BOT:
				bot_player.reset($Spawns/Players/BotPlayerMid.fixed_position)
				setup_top_kickoff(kickoff_side)
	else:
		setup_bot_kickoff(kickoff_side)
		bot_player.set_collision_mask_bit(1, false)

	top_goal.just_scored = false
	bot_goal.just_scored = false
	just_scored = null

sync func set_seed(rng_seed: int) -> void:
	rng.set_seed(rng_seed)
	top_goal.set_score(0)
	bot_goal.set_score(0)
	reset_pieces(rng.randi_range(TOP, BOT))

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
		yield(get_tree().create_timer(2.0), "timeout")
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
	online = false
	top_player.queue_free()
	rng.randomize()
	set_seed(rng.get_seed())
	center_line.visible = false
	main_menu.visible = false
	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
	SyncManager.start()

func score_effects(side: int, msg: String) -> void:
	just_scored = side
	show_banner(msg)
	timer.start()

func _on_NetworkTimer_timeout() -> void:
	if top_goal.score >= SCORE_TO_WIN:
		show_banner('BOT WINS!')
	elif bot_goal.score >= SCORE_TO_WIN:
		show_banner('TOP WINS!')
	else:
		hide_banner()
		reset_pieces(just_scored)

func _on_TopGoal_goal(piece_name: String) -> void:
	if not just_scored:
		var msg: String
		match piece_name:
			'Ball':
				msg = 'BOT GOAL!'
			_:
				msg = 'TOP TRIPPED!'
		score_effects(BOT, msg)

func _on_BotGoal_goal(piece_name: String) -> void:
	if not just_scored:
		var msg: String
		match piece_name:
			'Ball':
				msg = 'TOP GOAL!'
			_:
				msg = 'BOT TRIPPED!'
		score_effects(TOP, msg)

func _on_TopPlayer_double_biscuit(player) -> void:
	if not just_scored:
		top_goal.score()
		score_effects(BOT, 'TOP ATE BISCUITS!')

func _on_BotPlayer_double_biscuit(player) -> void:
	if not just_scored:
		bot_goal.score()
		score_effects(TOP, 'BOT ATE BISCUITS!')

func _save_state() -> Dictionary:
	return {
		banner_visible = banner.visible,
		just_scored = just_scored,
		top_score = top_goal.score,
		bot_score = bot_goal.score,
	}

func _load_state(state: Dictionary) -> void:
	banner.visible = state['banner_visible']
	just_scored = state['just_scored']
	top_goal.set_score(state['top_score'])
	bot_goal.set_score(state['bot_score'])

func show_banner(msg: String) -> void:
	banner.get_node('GameOverLabel').text = msg
	banner.visible = true

func hide_banner() -> void:
	banner.visible = false
