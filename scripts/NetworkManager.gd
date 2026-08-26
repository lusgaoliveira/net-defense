extends Node
# Autoload: registre como "NetworkManager" em Project > Project Settings > Autoload

signal player_list_changed
signal connection_succeeded
signal connection_failed
signal server_disconnected

const PORT := 7777
const MAX_CLIENTS := 1 # 1v1: host + 1 cliente = 2 jogadores no total

var peer: ENetMultiplayerPeer
var connected_peers: Array[int] = []


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game() -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Falha ao criar servidor: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	connected_peers = [1] # o host sempre é o peer id 1
	player_list_changed.emit()


func join_game(ip: String) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("Falha ao conectar: %s" % err)
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer


func disconnect_game() -> void:
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = null
	connected_peers.clear()


func _on_peer_connected(id: int) -> void:
	if not connected_peers.has(id):
		connected_peers.append(id)
	player_list_changed.emit()
	# Quando os 2 jogadores estiverem conectados, o servidor inicia a partida.
	if multiplayer.is_server() and connected_peers.size() == 2:
		GameManager.server_start_game()


func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	player_list_changed.emit()


func _on_connected_ok() -> void:
	connection_succeeded.emit()


func _on_connected_fail() -> void:
	connection_failed.emit()


func _on_server_disconnected() -> void:
	server_disconnected.emit()
