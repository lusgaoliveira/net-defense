extends Control

@onready var main_buttons: VBoxContainer = $buttons
@onready var lobby_container: VBoxContainer = $lobby
@onready var status_label: Label = $lobby/status_label
@onready var ip_input: LineEdit = $lobby/ip_container/ip_input

func _ready() -> void:
	# Conecta os botões da tela inicial
	$buttons/boot_game.pressed.connect(_on_boot_game_pressed)
	$buttons/multiplayer_game.pressed.connect(_on_multiplayer_pressed)
	
	# Conecta os botões do lobby multiplayer
	$lobby/host_button.pressed.connect(_on_host_pressed)
	$lobby/join_button.pressed.connect(_on_join_pressed)
	$lobby/back_button.pressed.connect(_on_back_pressed)
	
	# Conecta aos sinais do NetworkManager
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	NetworkManager.player_list_changed.connect(_on_player_list_changed)

func _on_boot_game_pressed() -> void:
	# Inicia jogo local e muda para a cena de gameplay
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_multiplayer_pressed() -> void:
	main_buttons.hide()
	lobby_container.show()
	status_label.text = "Pronto para conectar"

func _on_host_pressed() -> void:
	status_label.text = "Iniciando servidor na porta %d..." % NetworkManager.PORT
	NetworkManager.host_game()
	status_label.text = "Servidor ativo! Aguardando o outro jogador..."

func _on_join_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	status_label.text = "Conectando a %s:%d..." % [ip, NetworkManager.PORT]
	NetworkManager.join_game(ip)

func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	lobby_container.hide()
	main_buttons.show()

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

# =========================
# EVENTOS DE CONEXÃO
# =========================
func _on_connection_failed() -> void:
	status_label.text = "Falha ao conectar!"

func _on_connection_succeeded() -> void:
	status_label.text = "Conectado! Aguardando início..."

func _on_server_disconnected() -> void:
	status_label.text = "Servidor desconectado!"

func _on_player_list_changed() -> void:
	var count = NetworkManager.connected_peers.size()
	if count > 0:
		status_label.text = "Jogadores conectados: %d/2" % count
