extends Node2D

const CARD_SCENE = preload("res://scenes/card.tscn")
const HELP_GUIDE = preload("res://scenes/help_guide.tscn")

@onready var hud1: ServerHUD = $server1/ServerHud
@onready var hud2: ServerHUD = $server2/ServerHud
@onready var panel = $panel_transition
@onready var panel_label = $panel_transition/label
@onready var pass_button = $pass_turn

var turn_label: Label

func _ready() -> void:
	# Cria o indicador de turno
	turn_label = Label.new()
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.size = Vector2(500, 60)
	turn_label.position = Vector2(960 - 250, 20)
	turn_label.add_theme_font_size_override("font_size", 34)
	add_child(turn_label)

	# Botão de ajuda fixo no canto superior esquerdo
	var help_btn = Button.new()
	help_btn.text = "❓ Ajuda"
	help_btn.add_theme_font_size_override("font_size", 18)
	help_btn.position = Vector2(16, 16)
	help_btn.size = Vector2(120, 44)
	help_btn.z_index = 50
	help_btn.pressed.connect(func():
		var guide = HELP_GUIDE.instantiate()
		get_tree().root.add_child(guide)
	)
	add_child(help_btn)

	# Conecta aos sinais globais do GameManager
	GameManager.card_played_on_field.connect(_on_card_played_on_field)
	GameManager.card_activated_on_field.connect(_on_card_activated_on_field)
	GameManager.card_discarded_on_field.connect(_on_card_discarded_on_field)
	GameManager.hand_updated.connect(_on_hand_updated)
	GameManager.hand_counts_updated.connect(_on_hand_counts_updated)
	GameManager.turn_started.connect(_on_turn_started)
	GameManager.game_over.connect(_on_game_over)

	$field1.owner_id = 0
	$field2.owner_id = 1

	if GameManager.network_mode:
		# Em rede, as instâncias de Player e Server já foram criadas e sincronizadas
		hud1.server = GameManager.servers[0]
		hud2.server = GameManager.servers[1]
		
		# Inicializa visual da mão e botões
		var local_index = GameManager.peer_ids.find(multiplayer.get_unique_id())
		_on_hand_updated(local_index, GameManager.players[local_index].hand)
		_on_hand_counts_updated([GameManager.players[0].hand.size(), GameManager.players[1].hand.size()])
		
		pass_button.disabled = (GameManager.current_index != local_index)
		panel.hide()
	else:
		# Modo local (hotseat)
		var p1 = Player.new(0, "Player 1")
		var p2 = Player.new(1, "Player 2")
		var s1 = Server.new()
		var s2 = Server.new()

		hud1.server = s1
		hud2.server = s2
		s1.hp = 1000
		s2.hp = 1000

		p1.build_deck()
		p2.build_deck()
		for i in 5:
			p1.draw_card()
			p2.draw_card()

		GameManager.start_local_game_with(p1, p2, s1, s2)

		var is_p1_turn = GameManager.current_index == 0
		_spawn_hand(p1, $hand1, not is_p1_turn)
		_spawn_hand(p2, $hand2, is_p1_turn)
		panel.hide()

	_update_turn_status_label()
	pass_button.pressed.connect(_on_pass_turn)
	$panel_transition/pass_ready.pressed.connect(_on_ready_pressed)


func _on_pass_turn() -> void:
	if GameManager.network_mode:
		# Em rede, o turno acaba instantaneamente e envia pro servidor
		GameManager.end_turn()
	else:
		var next_index = (GameManager.current_index + 1) % 2
		panel_label.text = "Passe o controle para\n" + GameManager.players[next_index].player_name
		panel.show()


func _on_ready_pressed() -> void:
	panel.hide()
	GameManager.end_turn()
	_rebuild_hands()


func _rebuild_hands() -> void:
	for child in $hand1.get_children():
		$hand1.remove_child(child)
		child.queue_free()
	for child in $hand2.get_children():
		$hand2.remove_child(child)
		child.queue_free()

	var p1 = GameManager.players[0]
	var p2 = GameManager.players[1]
	var is_p1_turn = GameManager.current_index == 0

	# Em modo local, reconecta cartas do field para a UI
	for card in $field1.get_children():
		if card is Card:
			card.flip(false)
	for card in $field2.get_children():
		if card is Card:
			card.flip(false)

	# Só a mão do adversário fica oculta
	if is_p1_turn:
		_spawn_hand(p1, $hand1, false)
		_spawn_hand(p2, $hand2, true)
	else:
		_spawn_hand(p1, $hand1, true)
		_spawn_hand(p2, $hand2, false)


func _spawn_hand(player: Player, hand_node: Node2D, face_down: bool = false) -> void:
	var spacing = 120
	var player_index = 0 if hand_node == $hand1 else 1
	for i in player.hand.size():
		var card = CARD_SCENE.instantiate()
		hand_node.add_child(card)
		card.setup(player.hand[i], face_down)
		card.owner_index = player_index
		card.position = Vector2(i * spacing, 0)


func _update_turn_status_label() -> void:
	if GameManager.network_mode:
		var local_index = GameManager.peer_ids.find(multiplayer.get_unique_id())
		if GameManager.current_index == local_index:
			turn_label.text = "Seu Turno!"
			turn_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		else:
			turn_label.text = "Turno do Oponente..."
			turn_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		turn_label.text = "Turno: " + GameManager.players[GameManager.current_index].player_name
		turn_label.add_theme_color_override("font_color", Color.WHITE)


# =========================
# LÓGICA DE REPLICAS DE REDE E EVENTOS GLOBAIS
# =========================

func _on_turn_started(player_index: int) -> void:
	_update_turn_status_label()
	if GameManager.network_mode:
		var local_index = GameManager.peer_ids.find(multiplayer.get_unique_id())
		pass_button.disabled = (player_index != local_index)
	else:
		pass_button.disabled = false


func _on_hand_updated(player_index: int, hand: Array[int]) -> void:
	if not GameManager.network_mode:
		var hand_node = $hand1 if player_index == 0 else $hand2
		for child in hand_node.get_children():
			hand_node.remove_child(child)
			child.queue_free()
		var player = GameManager.players[player_index]
		var is_current = (player_index == GameManager.current_index)
		_spawn_hand(player, hand_node, not is_current)
		return
		
	var local_index = GameManager.peer_ids.find(multiplayer.get_unique_id())
	if player_index == local_index:
		var hand_node = $hand1 if player_index == 0 else $hand2
		for child in hand_node.get_children():
			hand_node.remove_child(child)
			child.queue_free()
		var player = GameManager.players[player_index]
		_spawn_hand(player, hand_node, false)


func _on_hand_counts_updated(counts: Array) -> void:
	if not GameManager.network_mode:
		return
	var local_index = GameManager.peer_ids.find(multiplayer.get_unique_id())
	var opp_index = 1 - local_index
	var opp_hand_node = $hand1 if opp_index == 0 else $hand2
	for child in opp_hand_node.get_children():
		opp_hand_node.remove_child(child)
		child.queue_free()
	
	var opp_player = GameManager.players[opp_index]
	if opp_player.hand.size() != counts[opp_index]:
		opp_player.hand.resize(counts[opp_index])
	_spawn_hand(opp_player, opp_hand_node, true)


func _on_card_played_on_field(player_index: int, card_id: int, slot_index: int) -> void:
	var field = $field1 if player_index == 0 else $field2
	
	# Garante que não haja cartas duplicadas no mesmo slot visual
	var existing = _get_card_at_slot(player_index, slot_index)
	if existing:
		existing.queue_free()
		
	var card = CARD_SCENE.instantiate()
	field.add_child(card) # Roda o _ready() para instanciar subnós
	card.setup(card_id, false)
	card.in_field = true
	card.slot_index = slot_index
	card.owner_index = player_index
	
	var slot = field.slots[slot_index]
	field.occupy_slot(slot)
	card.global_position = slot.global_position
	
	# Ajusta escala e posicionamento no slot
	var target_size = Vector2(field.SLOT_WIDTH, field.SLOT_HEIGHT)
	var base_size = card.get_sprite_size()
	card.scale = Vector2(target_size.x / base_size.x, target_size.y / base_size.y)
	card.z_index = 1


func _on_card_activated_on_field(player_index: int, slot_index: int) -> void:
	var card = _get_card_at_slot(player_index, slot_index)
	if card:
		card._on_activated()


func _on_card_discarded_on_field(player_index: int, slot_index: int) -> void:
	var card = _get_card_at_slot(player_index, slot_index)
	if card:
		card.queue_free()
	
	var field = $field1 if player_index == 0 else $field2
	field.free_slot_by_index(slot_index)


func _get_card_at_slot(player_index: int, slot_index: int) -> Card:
	var field = $field1 if player_index == 0 else $field2
	for child in field.get_children():
		if child is Card and child.slot_index == slot_index:
			return child
	return null


func _on_game_over(winner_index: int) -> void:
	var end_panel = ColorRect.new()
	end_panel.color = Color(0.05, 0.05, 0.1, 0.85)
	end_panel.size = Vector2(1920, 1080)
	add_child(end_panel)

	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.text = "FIM DE JOGO!\nVENCEDOR: " + GameManager.players[winner_index].player_name
	label.position = Vector2(960 - 300, 450)
	label.size = Vector2(600, 150)
	end_panel.add_child(label)
	
	var btn = Button.new()
	btn.text = "Voltar ao Menu"
	btn.add_theme_font_size_override("font_size", 24)
	btn.position = Vector2(960 - 120, 620)
	btn.size = Vector2(240, 60)
	btn.pressed.connect(func():
		get_tree().paused = false
		NetworkManager.disconnect_game()
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	end_panel.add_child(btn)
