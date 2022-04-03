extends Node2D

const DummyNetworkAdaptor = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

export(bool) var logging_enabled: = false

onready var main_menu = $Menu/MainMenu
onready var connection_panel = $Menu/ConnectionPanel
onready var host_field = $Menu/ConnectionPanel/GridContainer/HostField
onready var port_field = $Menu/ConnectionPanel/GridContainer/PortField
onready var message_label = $Menu/CenterContainer/MessageLabel
onready var sync_lost_label = $Menu/SyncLostLabel
onready var reset_button = $Menu/ResetButton
onready var center_line = $Arena/Center/CenterColor

const LOG_FILE_DIRECTORY = 'user://detailed_logs'

const score = {
	'top': 0,
	'bot': 0,
}

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
			init_pieces([$BotPlayer, $TopPlayer])
		else:
			init_pieces([$BotPlayer])
			_on_LocalButton_pressed()

func init_pieces(players: Array) -> void:
	$LeftBiscuit.players = players
	$MidBiscuit.players = players
	$RightBiscuit.players = players
	$BotGoal.players = players
	var top_goal_players := players.duplicate()
	top_goal_players.invert()
	$TopGoal.players = top_goal_players

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

	$BotPlayer.set_network_master(1)
	if get_tree().is_network_server():
		$TopPlayer.set_network_master(peer_id)
	else:
		$TopPlayer.set_network_master(get_tree().get_network_unique_id())

	if get_tree().is_network_server():
		message_label.text = "Starting..."
		# Give a little time to get ping data.
#		yield(get_tree().create_timer(2.0), "timeout")
		yield(get_tree().create_timer(0.2), "timeout") # TODO should be 2.0 sec, like line above
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
	$BotPlayer.set_collision_mask_bit(1, false)
	center_line.visible = false
	$TopPlayer.queue_free()
	main_menu.visible = false
	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
	SyncManager.start()


func _on_TopGoal_goal() -> void:
	print('top goal!')


func _on_BotGoal_goal() -> void:
	print('bot goal!')
