extends Node
# Autoload: registre como "GameManager".
#
# DOIS MODOS:
# - LOCAL (network_mode = false): sem NetworkManager, sem RPC. Tudo roda
#   direto no mesmo processo (hotseat 2 jogadores, ou 1 jogador vs bot local).
# - REDE (network_mode = true): só o SERVIDOR executa a lógica de verdade.
#   Clientes chamam a API pública (end_turn, play_card, ...) e ela decide
#   sozinha se manda RPC pro servidor ou roda direto (se for o próprio host).
#
# Informação oculta (mão de cada jogador):
# - em rede: só vai por rpc_id() (unicast) pro dono; os outros só recebem a contagem.
# - local: não existe "outro peer", então a mão fica só em memória mesmo.

signal turn_started(player_index: int)
signal phase_changed(phase: Phase)
signal packets_generated(player_index: int, packets: Array[Packet])
signal server_state_updated(server_index: int)
signal hand_updated(player_index: int, hand: Array[int]) # só dispara no dono da mão
signal hand_counts_updated(counts: Array) # dispara em todo mundo
signal game_over(winner_index: int)

# Sinais para sincronização do campo
signal card_played_on_field(player_index: int, card_id: int, slot_index: int)
signal card_activated_on_field(player_index: int, slot_index: int)
signal card_discarded_on_field(player_index: int, slot_index: int)

enum Phase { PACKET, MAIN, END }

const PACKETS_PER_TURN := 4
const STARTING_HAND_SIZE := 5 # ajuste conforme a regra real do seu jogo
const STATE_SYNC_INTERVAL := 0.1

var network_mode := false

var players: Array[Player] = []
var servers: Array[Server] = []
var peer_ids: Array[int] = [] # só usado em rede: peer_ids[i] = dono de players[i]/servers[i]
var fields: Array[Array] = [[null, null, null, null], [null, null, null, null]]

var current_index := 0
var current_phase := Phase.PACKET
var turn := 1

var _sync_accum := 0.0
var _game_over := false


func _process(delta: float) -> void:
	if network_mode and not multiplayer.is_server():
		return
	if current_phase != Phase.MAIN or _game_over:
		return

	current_server().update_processing(delta)

	if network_mode:
		_sync_accum += delta
		if _sync_accum >= STATE_SYNC_INTERVAL:
			_sync_accum = 0.0
			_broadcast_all_server_states()

	_check_game_over()


func _sender_is_current_player() -> bool:
	if not network_mode:
		return true
	var sender := multiplayer.get_remote_sender_id()
	return peer_ids.size() == 2 and peer_ids[current_index] == sender


func is_my_turn() -> bool:
	if not network_mode:
		return true # hotseat: a tela é compartilhada, quem manda é a UI
	return current_index == peer_ids.find(multiplayer.get_unique_id())


# ---------------------------------------------------------------------------
# INÍCIO DE PARTIDA
# ---------------------------------------------------------------------------

## Modo local: sem rede, hotseat ou 1 jogador vs bot.
func start_local_game(p1_name := "Jogador 1", p2_name := "Jogador 2", starting_hp := 1000) -> void:
	network_mode = false
	peer_ids = []
	fields = [[null, null, null, null], [null, null, null, null]]

	var p1 := Player.new(1, p1_name)
	var p2 := Player.new(2, p2_name)
	p1.build_deck()
	p2.build_deck()
	for i in STARTING_HAND_SIZE:
		p1.draw_card()
		p2.draw_card()

	players = [p1, p2]
	servers = [Server.new(), Server.new()]
	servers[0].hp = starting_hp
	servers[1].hp = starting_hp

	current_index = randi() % 2
	turn = 1
	_game_over = false

	get_tree().change_scene_to_file("res://scenes/game.tscn")
	_start_turn()


## Modo local, mas com Player/Server já criados por fora (ex: a cena precisa
## manter a MESMA instância pra vincular HUD, campo de cartas, etc).
## Não mexe em deck/mão/hp — isso já deve estar pronto nos objetos recebidos.
func start_local_game_with(p1: Player, p2: Player, s1: Server, s2: Server) -> void:
	network_mode = false
	peer_ids = []
	fields = [[null, null, null, null], [null, null, null, null]]

	players = [p1, p2]
	servers = [s1, s2]

	current_index = randi() % 2
	turn = 1
	_game_over = false

	_start_turn()


## Modo rede: só o servidor chama, disparado pelo NetworkManager quando os
## 2 peers conectam.
func server_start_game() -> void:
	if not multiplayer.is_server():
		return

	network_mode = true
	fields = [[null, null, null, null], [null, null, null, null]]

	var ids := NetworkManager.connected_peers.duplicate()
	ids.erase(1)
	var client_peer: int = ids[0]
	peer_ids = [1, client_peer]

	var p1 := Player.new(1, "Host")
	var p2 := Player.new(client_peer, "Cliente")
	p1.build_deck()
	p2.build_deck()
	for i in STARTING_HAND_SIZE:
		p1.draw_card()
		p2.draw_card()

	players = [p1, p2]
	servers = [Server.new(), Server.new()]

	current_index = randi() % 2
	turn = 1
	_game_over = false

	_rpc_init_game.rpc_id(client_peer, peer_ids, current_index)

	_sync_hand_private(0)
	_sync_hand_private(1)
	_broadcast_hand_counts()
	_broadcast_all_server_states()

	get_tree().change_scene_to_file("res://scenes/game.tscn")
	_start_turn()


@rpc("authority", "call_remote", "reliable")
func _rpc_init_game(p_peer_ids: Array, start_index: int) -> void:
	network_mode = true
	fields = [[null, null, null, null], [null, null, null, null]]
	peer_ids = []
	for id in p_peer_ids:
		peer_ids.append(int(id))
	players = [Player.new(peer_ids[0]), Player.new(peer_ids[1])]
	servers = [Server.new(), Server.new()]
	current_index = start_index
	turn = 1
	_game_over = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ---------------------------------------------------------------------------
# FLUXO DE TURNO (só quem tem autoridade executa: local sempre, em rede só o host)
# ---------------------------------------------------------------------------

func _start_turn() -> void:
	var player := current_player()
	player.start_turn()
	if network_mode:
		_rpc_turn_started.rpc(current_index, turn)
	else:
		_rpc_turn_started(current_index, turn)
	_packet_phase()


@rpc("authority", "call_local", "reliable")
func _rpc_turn_started(player_index: int, turn_number: int) -> void:
	current_index = player_index
	turn = turn_number
	turn_started.emit(player_index)


func _packet_phase() -> void:
	current_phase = Phase.PACKET
	if network_mode:
		_rpc_phase_changed.rpc(current_phase)
	else:
		_rpc_phase_changed(current_phase)

	var packets := _generate_packets()
	var server := current_server()
	for packet in packets:
		server.add_packet(packet)

	var packet_data: Array = []
	for p in packets:
		packet_data.append(p.to_dict())

	if network_mode:
		_rpc_packets_generated.rpc(current_index, packet_data)
		_broadcast_all_server_states()
	else:
		_rpc_packets_generated(current_index, packet_data)

	_main_phase()


func _main_phase() -> void:
	current_phase = Phase.MAIN
	if network_mode:
		_rpc_phase_changed.rpc(current_phase)
	else:
		_rpc_phase_changed(current_phase)


@rpc("authority", "call_local", "reliable")
func _rpc_phase_changed(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(phase)


@rpc("authority", "call_local", "reliable")
func _rpc_packets_generated(player_index: int, packet_data: Array) -> void:
	var packets: Array[Packet] = []
	for d in packet_data:
		var p := Packet.new()
		p.from_dict(d)
		packets.append(p)
	packets_generated.emit(player_index, packets)


# ---------------------------------------------------------------------------
# AÇÕES DO JOGADOR — API PÚBLICA (chamada pela UI/game.gd nos dois modos)
# ---------------------------------------------------------------------------

func end_turn() -> void:
	if network_mode and not multiplayer.is_server():
		request_end_turn.rpc_id(1)
		return
	_perform_end_turn()


func play_card(card_id: int, slot_index: int) -> void:
	if network_mode and not multiplayer.is_server():
		request_play_card.rpc_id(1, card_id, slot_index)
		return
	_perform_play_card(current_index, card_id, slot_index)


func activate_card(slot_index: int) -> void:
	if network_mode and not multiplayer.is_server():
		request_activate_card.rpc_id(1, slot_index)
		return
	_perform_activate_card(current_index, slot_index)


func discard_card(slot_index: int) -> void:
	if network_mode and not multiplayer.is_server():
		request_discard_card.rpc_id(1, slot_index)
		return
	_perform_discard_card(current_index, slot_index)


# ---------------------------------------------------------------------------
# ENTRADAS RPC (só o servidor aceita, chamadas pelo cliente via rpc_id(1, ...))
# ---------------------------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func request_end_turn() -> void:
	if not multiplayer.is_server() or not _sender_is_current_player():
		return
	_perform_end_turn()


@rpc("any_peer", "call_remote", "reliable")
func request_play_card(card_id: int, slot_index: int) -> void:
	if not multiplayer.is_server() or not _sender_is_current_player():
		return
	_perform_play_card(current_index, card_id, slot_index)


@rpc("any_peer", "call_remote", "reliable")
func request_activate_card(slot_index: int) -> void:
	if not multiplayer.is_server() or not _sender_is_current_player():
		return
	_perform_activate_card(current_index, slot_index)


@rpc("any_peer", "call_remote", "reliable")
func request_discard_card(slot_index: int) -> void:
	if not multiplayer.is_server() or not _sender_is_current_player():
		return
	_perform_discard_card(current_index, slot_index)


# ---------------------------------------------------------------------------
# LÓGICA DE VERDADE (roda só em quem tem autoridade: local sempre, em rede só o host)
# ---------------------------------------------------------------------------

func _perform_end_turn() -> void:
	if current_phase != Phase.MAIN:
		return

	current_phase = Phase.END
	if network_mode:
		_rpc_phase_changed.rpc(current_phase)
	else:
		_rpc_phase_changed(current_phase)
	current_player().end_turn()

	current_index = (current_index + 1) % players.size()
	if current_index == 0:
		turn += 1

	_start_turn()


func _perform_play_card(player_index: int, card_id: int, slot_index: int) -> void:
	var player := players[player_index]
	var server := servers[player_index]
	var card = CardDatabase.get_card(card_id)
	var success := false
	if not card.is_empty() and player.has_card(card_id) and fields[player_index][slot_index] == null:
		var cost = card.get("cost", 0)
		if server.can_afford(cost):
			server.processing_power -= cost
			player.remove_card(card_id)
			fields[player_index][slot_index] = card_id
			success = true

	if success:
		if network_mode:
			_rpc_card_played.rpc(player_index, card_id, slot_index)
		else:
			_rpc_card_played(player_index, card_id, slot_index)
		_sync_hand_private(player_index)
		if network_mode:
			_broadcast_hand_counts()
			_broadcast_all_server_states()
	else:
		if network_mode:
			_rpc_card_result.rpc_id(peer_ids[player_index], "play", player_index, card_id, false)
		else:
			_rpc_card_result("play", player_index, card_id, false)


func _perform_activate_card(player_index: int, slot_index: int) -> void:
	var card_id = fields[player_index][slot_index]
	if card_id == null:
		return
	var card = CardDatabase.get_card(card_id)
	var player := players[player_index]
	var server := servers[player_index]
	var success := false
	if not card.is_empty():
		var activate_cost = card.get("activate_cost", 0)
		if server.can_afford(activate_cost):
			server.processing_power -= activate_cost
			var enemy_server := servers[1 - player_index]
			CardDatabase.apply_effect(card_id, player, server, enemy_server)
			success = true

	if success:
		if network_mode:
			_rpc_card_activated.rpc(player_index, slot_index)
		else:
			_rpc_card_activated(player_index, slot_index)
		
		# Sincroniza estado e mãos caso haja efeitos de compra/descarte
		_sync_hand_private(0)
		_sync_hand_private(1)
		if network_mode:
			_broadcast_hand_counts()
			_broadcast_all_server_states()
	else:
		if network_mode:
			_rpc_card_result.rpc_id(peer_ids[player_index], "activate", player_index, card_id, false)
		else:
			_rpc_card_result("activate", player_index, card_id, false)


func _perform_discard_card(player_index: int, slot_index: int) -> void:
	var card_id = fields[player_index][slot_index]
	if card_id == null:
		return
	fields[player_index][slot_index] = null
	
	if network_mode:
		_rpc_card_discarded.rpc(player_index, slot_index)
	else:
		_rpc_card_discarded(player_index, slot_index)
		
	_sync_hand_private(player_index)
	if network_mode:
		_broadcast_hand_counts()


@rpc("authority", "call_local", "reliable")
func _rpc_card_played(player_index: int, card_id: int, slot_index: int) -> void:
	fields[player_index][slot_index] = card_id
	card_played_on_field.emit(player_index, card_id, slot_index)


@rpc("authority", "call_local", "reliable")
func _rpc_card_activated(player_index: int, slot_index: int) -> void:
	card_activated_on_field.emit(player_index, slot_index)


@rpc("authority", "call_local", "reliable")
func _rpc_card_discarded(player_index: int, slot_index: int) -> void:
	fields[player_index][slot_index] = null
	card_discarded_on_field.emit(player_index, slot_index)


@rpc("authority", "call_local", "reliable")
func _rpc_card_result(_action: String, _player_index: int, _card_id: int, _success: bool) -> void:
	# gancho pra UI dar feedback ("jogada", "sem PP suficiente", etc.)
	pass


# ---------------------------------------------------------------------------
# MÃO (PRIVADA EM REDE) E CONTAGEM (PÚBLICA)
# ---------------------------------------------------------------------------

func _sync_hand_private(index: int) -> void:
	if not network_mode:
		hand_updated.emit(index, players[index].hand)
		return

	var target_peer := peer_ids[index]
	if target_peer == multiplayer.get_unique_id():
		hand_updated.emit(index, players[index].hand)
		return
	_rpc_hand_update.rpc_id(target_peer, index, players[index].hand.duplicate())


@rpc("authority", "call_remote", "reliable")
func _rpc_hand_update(player_index: int, hand: Array) -> void:
	var typed_hand: Array[int] = []
	for c in hand:
		typed_hand.append(int(c))
	if player_index < players.size():
		players[player_index].hand = typed_hand
	hand_updated.emit(player_index, typed_hand)


func _broadcast_hand_counts() -> void:
	var counts := [players[0].hand.size(), players[1].hand.size()]
	_rpc_hand_counts.rpc(counts)


@rpc("authority", "call_local", "reliable")
func _rpc_hand_counts(counts: Array) -> void:
	hand_counts_updated.emit(counts)


# ---------------------------------------------------------------------------
# ESTADO PÚBLICO DOS SERVIDORES (só existe sincronia explícita em rede;
# em modo local a UI lê servers[i] direto, já que é tudo o mesmo processo)
# ---------------------------------------------------------------------------

func _broadcast_all_server_states() -> void:
	for i in servers.size():
		_rpc_server_state.rpc(i, servers[i].get_full_state())


@rpc("authority", "call_local", "unreliable_ordered")
func _rpc_server_state(server_index: int, state: Dictionary) -> void:
	if server_index < servers.size():
		servers[server_index].apply_full_state(state)
	server_state_updated.emit(server_index)


# ---------------------------------------------------------------------------
# FIM DE JOGO
# ---------------------------------------------------------------------------

func _check_game_over() -> void:
	for i in servers.size():
		if servers[i].hp <= 0:
			_game_over = true
			if network_mode:
				_rpc_game_over.rpc(1 - i)
			else:
				_rpc_game_over(1 - i)
			return


@rpc("authority", "call_local", "reliable")
func _rpc_game_over(winner_index: int) -> void:
	_game_over = true
	game_over.emit(winner_index)
	get_tree().paused = true


func current_player() -> Player:
	return players[current_index]


func current_server() -> Server:
	return servers[current_index]


func _generate_packets() -> Array[Packet]:
	var result: Array[Packet] = []
	for i in PACKETS_PER_TURN:
		var packet := Packet.new()
		var roll := randf()
		if roll < 0.15:
			packet.setup(Packet.PacketType.DDOS, 0, 20, 8.0, true)
		elif roll < 0.30:
			packet.setup(Packet.PacketType.MALWARE, 0, 10, 4.0, true)
		elif roll < 0.60:
			packet.setup(Packet.PacketType.DATA, 1, 0, 1.0, false)
		elif roll < 0.85:
			packet.setup(Packet.PacketType.VIDEO, 3, 0, 3.0, false)
		else:
			packet.setup(Packet.PacketType.VOICE, 2, 0, 2.0, false)
		result.append(packet)
	return result
